#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$PlanDirectory,[Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidatePattern('^[A-Za-z0-9_]+\.cpp$')][string[]]$ExpectedCompileFiles=@('UEPyMixin.cpp'))
# This deliberately accepts only the explicitly reviewed UEP Mixin refresh.
# It is not an Engine/project-wide build or a native-runtime acceptance gate.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$planRoot=[IO.Path]::GetFullPath($PlanDirectory);$output=[IO.Path]::GetFullPath($OutputDirectory)
foreach($path in @($stage,$planRoot,$output)){if(!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Workspace-owned stage/plan/output required'}}
if(!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json')) -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool,cl,link -ErrorAction SilentlyContinue).Count){throw 'Another native/build lane is active'}
$plan=Get-Content -LiteralPath (Join-Path $planRoot 'actions.json') -Raw|ConvertFrom-Json -Depth 80
$prior=Get-Content -LiteralPath (Join-Path $planRoot 'summary.json') -Raw|ConvertFrom-Json -Depth 30
if($prior.status -ne 'plan_exported_requires_review' -or !$prior.checked_engine_files_unchanged -or @($plan.Actions).Count -ne ($ExpectedCompileFiles.Count+2)){throw 'Reviewed exact compile/link action plan with unchanged Engine required'}
$descriptions=@($plan.Actions.StatusDescription|Sort-Object)
$expected=@($ExpectedCompileFiles)+@('UnrealEditor-UnrealEnginePython.dll','UnrealEditor-UnrealEnginePython.lib')
if(($descriptions -join ',') -ne (($expected|Sort-Object) -join ',')){throw 'Unexpected compile/link actions'}
$plugin=[IO.Path]::GetFullPath((Join-Path $stage 'Plugins/UnrealEnginePython'))+[IO.Path]::DirectorySeparatorChar
foreach($action in $plan.Actions){foreach($item in @($action.ProducedItems)+@($action.DeleteItems)){
    if($item -and ![IO.Path]::GetFullPath($item).StartsWith($plugin,[StringComparison]::OrdinalIgnoreCase)){throw 'Reviewed action writes outside the staged UEP plugin'}
}}
$source=Join-Path $repo ('Source/UnrealEnginePython/Private/'+$ExpectedCompileFiles[0])
$staged=Join-Path $plugin ('Source/UnrealEnginePython/Private/'+$ExpectedCompileFiles[0])
if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $staged).Hash){throw 'Staged Mixin source differs'}
$sourceHashes=@()
foreach($name in @(@('UEPyMixin.cpp','UEPyMixin.h','PythonFunction.cpp')+@($ExpectedCompileFiles)|Select-Object -Unique)){
    $corePath=Join-Path $repo ('Source/UnrealEnginePython/Private/'+$name)
    $stagePath=Join-Path $plugin ('Source/UnrealEnginePython/Private/'+$name)
    $hash=(Get-FileHash -LiteralPath $corePath).Hash
    if((Get-FileHash -LiteralPath $stagePath).Hash -ne $hash){throw 'Staged invocation source differs'}
    $sourceHashes+=@{path=$corePath;stage=$stagePath;sha256=$hash}
}
New-Item -ItemType Directory -Path (Join-Path $output 'PreviousBinaries')|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';cpp_compile_executed=$false;engine_full_compile_executed=$false;cook_package_executed=$false
    runtime_acceptance=$false;reviewed_actions=$descriptions;engine_before=@();engine_after=@();binary_before=@();binary_after=@();process=$null;error=$null}
try{
    foreach($relative in @('Engine/Build/Build.version','Engine/Binaries/Win64/UnrealEditor.exe','Engine/Binaries/Win64/UnrealEditor-Core.dll','Engine/Binaries/Win64/UnrealEditor-Engine.dll','Engine/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $EngineRoot $relative;$summary.engine_before+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    foreach($name in @('UnrealEditor-UnrealEnginePython.dll','UnrealEditor-UnrealEnginePython.pdb','UnrealEditor.modules')){
        $path=Join-Path $plugin ('Binaries/Win64/'+$name)
        if(Test-Path -LiteralPath $path){
            # Independent copies: linker writes cannot mutate recovery bytes.
            $backup=Join-Path $output ('PreviousBinaries/'+$name);Copy-Item -LiteralPath $path -Destination $backup
            $summary.binary_before+=@{path=$path;backup=$backup;sha256=(Get-FileHash -LiteralPath $path).Hash}
        }
    }
    $summary.source_sha256=(Get-FileHash -LiteralPath $source).Hash
    $summary.source_hashes=$sourceHashes
    $summary.reviewed_plan_sha256=(Get-FileHash -LiteralPath (Join-Path $planRoot 'actions.json')).Hash
    $dotnet=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/DotNet/10.0/win-x64/dotnet.exe'
    $args=@((Join-Path $EngineRoot 'Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.dll'),'LyraEditor','Win64','Development',
        "-Project=$project",'-Module=UnrealEnginePython','-NoEngineChanges','-IgnoreJunk','-SkipPreBuildTargets','-SkipRulesCompile',
        '-WaitMutex','-NoHotReload','-NoUBA','-MaxParallelActions=2','-UTF8Output',"-Log=$output/build.log")
    $summary.cpp_compile_executed=$true
    $summary.process=Invoke-UEPValidationProcess $dotnet $args $stage (Join-Path $output 'build') 'Reviewed single-source UEP Mixin module refresh' 180
    if((Get-FileHash -LiteralPath $source).Hash -ne $summary.source_sha256 -or (Get-FileHash -LiteralPath $staged).Hash -ne $summary.source_sha256){throw 'Source changed during compilation'}
    foreach($row in $sourceHashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256 -or (Get-FileHash -LiteralPath $row.stage).Hash -ne $row.sha256){throw 'Invocation source changed during compilation'}}
    foreach($row in $summary.binary_before){
        if((Get-FileHash -LiteralPath $row.backup).Hash -ne $row.sha256){throw 'Recoverable previous binary changed'}
        $summary.binary_after+=@{path=$row.path;sha256=(Get-FileHash -LiteralPath $row.path).Hash}
    }
    $id=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        if((Get-Content -LiteralPath (Join-Path $stage $relative) -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Post-refresh BuildId differs'}
    }
    $summary.engine_build_id=$id;$summary.status='built_requires_native_acceptance'
}catch{$summary.error=$_.ToString();throw}
finally{
    foreach($row in $summary.engine_before){$summary.engine_after+=@{path=$row.path;sha256=(Get-FileHash -LiteralPath $row.path).Hash}}
    $summary.checked_engine_files_unchanged=(@($summary.engine_before|Where-Object {$before=$_;!@($summary.engine_after|Where-Object {$_.path -eq $before.path -and $_.sha256 -eq $before.sha256}).Count}).Count -eq 0)
    if(!$summary.checked_engine_files_unchanged){$summary.status='failed';$summary.error='Engine binary/reference changed during reviewed module refresh'}
    $summary|ConvertTo-Json -Depth 15|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8
}
if($summary.status -ne 'built_requires_native_acceptance'){throw $summary.error}
Write-Host 'Reviewed UEP Mixin module built; native acceptance still required'
