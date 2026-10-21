#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,[ValidateRange(1,8)][int]$MaxParallelActions=2,
    [ValidateRange(60,14400)][int]$TimeoutSeconds=7200)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh game-build evidence required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|UnrealBuildTool|AutomationTool|LyraGame)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path "$output/PreviousGame"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='current-Development-LyraGame-build-only';cpp_compile_executed=$false;cook_package_executed=$false;runtime_acceptance=$false;full_acceptance=$false;no_engine_changes_requested=$true;timeout_seconds=$TimeoutSeconds;timed_out=$false;max_parallel_actions=$MaxParallelActions;hashes=@();engine_inputs=@();previous_products=@();products=@();process=$null;error=$null}
function Add-GameHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},@{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){$copy=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName));if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Native game plugin source differs from current checkout'};Add-GameHash $file.FullName;Add-GameHash $copy}
    }
    foreach($file in Get-ChildItem -LiteralPath "$stage/Source" -Recurse -File){Add-GameHash $file.FullName}
    foreach($file in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),$project,"$stage/Plugins/UnrealEnginePython/UnrealEnginePython.uplugin","$stage/Plugins/UEPLyraBridge/UEPLyraBridge.uplugin")){Add-GameHash $file}
    foreach($relative in @('Engine/Build/Build.version','Engine/Binaries/Win64/UnrealEditor.version','Engine/Binaries/Win64/UnrealEditor.modules','Engine/Binaries/Win64/UnrealEditor-Engine.dll','Engine/Binaries/Win64/UnrealGame.exe','Engine/Binaries/Win64/UnrealGame.target')){
        $file=Join-Path $EngineRoot $relative;if(Test-Path -LiteralPath $file){$summary.engine_inputs+=@{path=$file;sha256=(Get-FileHash -LiteralPath $file).Hash}}
    }
    foreach($name in @('LyraGame.exe','LyraGame.target')){
        $file=Join-Path "$stage/Binaries/Win64" $name
        if(Test-Path -LiteralPath $file){$copy=Join-Path "$output/PreviousGame" $name;Copy-Item -LiteralPath $file -Destination $copy;$summary.previous_products+=@{path=$copy;sha256=(Get-FileHash -LiteralPath $copy).Hash}}
    }
    $dotnet=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/DotNet/10.0/win-x64/dotnet.exe'
    $ubt=Join-Path $EngineRoot 'Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.dll'
    $arguments=@($ubt,'LyraGame','Win64','Development',"-Project=$project",'-NoEngineChanges','-WaitMutex','-NoHotReload','-NoUBA',"-MaxParallelActions=$MaxParallelActions","-Log=$output/build.log")
    $summary.cpp_compile_executed=$true
    $handle=Start-UEPValidationProcess $dotnet $arguments $stage (Join-Path $output 'game-build') 'Protected current LyraGame Development build'
    try{
        if(!$handle.process.WaitForExit($TimeoutSeconds*1000)){$summary.timed_out=$true;throw 'Protected current LyraGame Development build timed out'}
        $summary.process=Complete-UEPValidationProcess $handle
        if($summary.process.exit_code -ne 0){throw "Protected current LyraGame build exited $($summary.process.exit_code)"}
    }finally{
        Stop-UEPValidationProcess $handle
        $summary.process=Complete-UEPValidationProcess $handle
        $handle.process.Dispose()
    }
    $log=Get-Content -LiteralPath "$output/build.log" -Raw
    if($log -notmatch 'Result: Succeeded' -or $log -match '(?im)(error (C\d+|LNK\d+)|warning (C\d+|LNK\d+))'){throw 'Current game build did not pass diagnostics gate'}
    foreach($name in @('LyraGame.exe','LyraGame.target')){$file=Join-Path "$stage/Binaries/Win64" $name;if(!(Test-Path -LiteralPath $file)){throw 'Expected game product missing'};$summary.products+=@{path=$file;sha256=(Get-FileHash -LiteralPath $file).Hash}}
    foreach($input in @($summary.hashes)+@($summary.engine_inputs)){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw "Frozen game-build input or protected Engine output changed: $($input.path)"}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Current protected Game build: $($summary.status); $output"
