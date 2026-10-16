#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$Target,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [string[]]$Modules=@(),
    [switch]$UsePrecompiledEngine
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject)
$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   (!(Test-Path -LiteralPath (Join-Path $stage '.uep-validation-stage')) -and !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json')))){
    throw 'Marked workspace stage/output required'
}
if(Test-Path -LiteralPath $output){throw 'Use a fresh plan evidence directory'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*')}).Count){throw 'Matching stage is already running'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';cpp_compile_executed=$false;cook_package_executed=$false
    build_executed=$false;runtime_acceptance=$false;engine_before=@();engine_after=@();backup=@();process=$null;error=$null}
$engineFiles=@('Engine\Build\Build.version','Engine\Binaries\Win64\UnrealEditor.version','Engine\Binaries\Win64\UnrealEditor.modules',
    'Engine\Binaries\Win64\UnrealEditor.exe','Engine\Binaries\Win64\UnrealEditor-Core.dll',
    'Engine\Binaries\Win64\UnrealEditor-Engine.dll','Engine\Binaries\Win64\UnrealEditor-NetCore.dll')
try {
    foreach($relative in $engineFiles){$path=Join-Path $EngineRoot $relative;$summary.engine_before+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    $binaryRoots=@(Join-Path $stage 'Binaries\Win64')
    $binaryRoots+=@(Get-ChildItem -LiteralPath (Join-Path $stage 'Plugins') -Recurse -File -Filter UnrealEditor.modules|ForEach-Object {$_.DirectoryName})
    foreach($root in $binaryRoots|Sort-Object -Unique){
        foreach($file in Get-ChildItem -LiteralPath $root -File|Where-Object {$_.Extension -in '.dll','.pdb','.modules','.target','.version'}){
            $relative=[IO.Path]::GetRelativePath($stage,$file.FullName)
            $destination=Join-Path (Join-Path $output 'PreviousBinary') $relative
            if(!$destination.StartsWith($output+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Backup escaped evidence directory'}
            New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force|Out-Null
            if($file.Extension -in '.dll','.pdb'){
                # UBT's plan export can unlink outdated project outputs before
                # exporting. Keep their existing bytes through another NTFS link.
                New-Item -ItemType HardLink -Path $destination -Target $file.FullName|Out-Null
            }else{Copy-Item -LiteralPath $file.FullName -Destination $destination}
            $summary.backup+=@{source=$file.FullName;backup=$destination;length=$file.Length}
        }
    }
    $dotnet=Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\DotNet\10.0\win-x64\dotnet.exe'
    $ubt=Join-Path $EngineRoot 'Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll'
    $arguments=@($ubt,$Target,'Win64','Development',"-Project=$project",'-NoEngineChanges','-IgnoreJunk',
        '-SkipPreBuildTargets','-SkipRulesCompile','-WaitMutex','-NoHotReload','-NoUBA','-MaxParallelActions=2','-UTF8Output',
        "-WriteOutdatedActions=$output\actions.json","-Log=$output\plan.log")
    if($Modules.Count){$arguments+=('-Module='+($Modules -join '+'))}
    if($UsePrecompiledEngine){$arguments+='-UsePrecompiled'}
    # Do not fake a recursive -Session: UE5.8's UBA executor requires the real
    # parent trace and rejects an artificial session even for plan export.
    $summary.process=Invoke-UEPValidationProcess $dotnet $arguments $stage (Join-Path $output 'plan') 'Project-only module refresh plan (no compilation)' 180
    if(!(Test-Path -LiteralPath (Join-Path $output 'actions.json'))){throw 'UBT produced no action plan'}
    $summary.status='plan_exported_requires_review'
}
catch{$summary.error=$_.ToString();throw}
finally{
    foreach($relative in $engineFiles){$path=Join-Path $EngineRoot $relative;$summary.engine_after+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    $summary.checked_engine_files_unchanged=(@($summary.engine_before|Where-Object {
        $before=$_;!@($summary.engine_after|Where-Object {$_.path -eq $before.path -and $_.sha256 -eq $before.sha256}).Count
    }).Count -eq 0)
    $summary|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8
}
Write-Host "Refresh plan: $($summary.status); $output"
