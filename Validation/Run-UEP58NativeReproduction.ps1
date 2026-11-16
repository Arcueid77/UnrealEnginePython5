#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:/UnrealEngine',
    [string]$ReferenceProject='F:/LyraStarterGame',
    [string]$StageRoot='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/Reproduction/Lyra',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [string]$PreparedStageReport,
    [string]$ResumeBuildFrom,
    [switch]$UsePrecompiledEngine,
    [switch]$PrepareOnly,
    [ValidateRange(1,8)][int]$MaxParallelActions=3
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=[IO.Path]::GetFullPath($StageRoot);$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Owned reproduction stage and fresh output required'}
if(!$PrepareOnly -and @(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path $output|Out-Null
$python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe';$tool=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/prepare_native_reproduction.py'
$summary=[ordered]@{schema_version=1;status='failed';scope='fresh-current-native-migration-reproduction';cpp_compile_executed=$false;engine_full_compile_executed=$false;cook_package_executed=$false;old_stage_or_compiler_outputs_reused=$false;hashes=@();engine_inputs=@();products=@();process=$null;error=$null}
function Pin-ReproductionInput([string]$Path){return @{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    if($PreparedStageReport){$prepare=Get-Content -LiteralPath $PreparedStageReport -Raw|ConvertFrom-Json -Depth 20;if($prepare.status -ne 'prepared_requires_fresh_build' -or [IO.Path]::GetFullPath($prepare.stage) -ne $stage){throw 'Prepared independent stage differs'};$summary.preparation=$PreparedStageReport}
    else{& $python -B -X utf8 $tool --reference $ReferenceProject --stage $stage --result "$output/prepare.json";if($LASTEXITCODE -ne 0){throw 'Reproduction preparation failed'};$summary.preparation="$output/prepare.json";$prepare=Get-Content -LiteralPath $summary.preparation -Raw|ConvertFrom-Json -Depth 20}
    foreach($row in @($prepare.reference_inputs)+@($prepare.versioned_inputs)){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Prepared reproduction source changed'}}
    & $python -B -X utf8 $tool --verify-report $summary.preparation
    if($LASTEXITCODE -ne 0){throw 'Current versioned recipe and fresh preparation differ'}
    if($PrepareOnly){$summary.status='prepared_requires_fresh_build';return}
    if($ResumeBuildFrom){
        $priorPath=[IO.Path]::GetFullPath($ResumeBuildFrom)
        if(!$priorPath.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned prior reproduction summary required'}
        $prior=Get-Content -LiteralPath $priorPath -Raw|ConvertFrom-Json -Depth 30
        $configurationOnly=$false
        if($prior.preparation -ne $summary.preparation -and $prepare.PSObject.Properties.Name -contains 'configuration_only_parent'){
            $configurationOnly=([IO.Path]::GetFullPath($prepare.configuration_only_parent.path) -eq [IO.Path]::GetFullPath($prior.preparation) -and (Get-FileHash -LiteralPath $prior.preparation).Hash -eq $prepare.configuration_only_parent.sha256 -and !$prepare.production_test_plugin_update.cpp_sources_changed -and ($prepare.production_test_plugin_update.disabled -join ',') -eq 'RuntimeTests,ShooterTests')
        }
        if($prior.scope -ne $summary.scope -or $prior.status -eq 'passed' -or ($prior.preparation -ne $summary.preparation -and !$configurationOnly) -or $prior.old_stage_or_compiler_outputs_reused){throw 'Only the same unfinished fresh-stage attempt can resume incrementally'}
        foreach($row in @($prior.hashes)+@($prior.engine_inputs)){
            if($row.path.StartsWith($stage+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or @($prior.engine_inputs.path) -contains $row.path){
                $changed=(Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256
                $allowedConfiguration=$configurationOnly -and [IO.Path]::GetFullPath($row.path) -eq [IO.Path]::GetFullPath($prepare.production_test_plugin_update.project) -and $row.sha256 -eq $prepare.production_test_plugin_update.before_sha256 -and (Get-FileHash -LiteralPath $row.path).Hash -eq $prepare.production_test_plugin_update.after_sha256
                if($changed -and !$allowedConfiguration){throw 'Previously compiled stage source or protected Engine input changed'}
            }
        }
        $summary.incremental_resume_of_same_fresh_stage=Pin-ReproductionInput $priorPath
    }elseif(@(Get-ChildItem -LiteralPath $stage -Recurse -Directory|Where-Object {$_.Name -in @('Binaries','Intermediate')}).Count){throw 'Fresh build stage contains reused compiler/binary outputs; an owned failed-attempt summary is required for incremental resume'}
    foreach($row in $prepare.production_sources){if((Get-FileHash -LiteralPath (Join-Path $stage $row.relative)).Hash -ne $row.sha256){throw 'Composed production source changed'}}
    foreach($file in Get-ChildItem -LiteralPath $stage -Recurse -File|Where-Object {$_.Extension -in @('.h','.cpp','.cs','.ini','.uplugin','.uproject','.py','.uasset','.umap')}){$summary.hashes+=Pin-ReproductionInput $file.FullName}
    $finalizer=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/finalize_native_editor_modules.py'
    foreach($path in @($PSCommandPath,$tool,$finalizer,$summary.preparation,(Join-Path $PSScriptRoot 'Inspect-UEP58ModuleRefresh.ps1'))){$summary.hashes+=Pin-ReproductionInput $path}
    foreach($relative in @('Engine/Build/Build.version','Engine/Binaries/Win64/UnrealEditor.modules','Engine/Binaries/Win64/UnrealEditor-Core.dll','Engine/Binaries/Win64/UnrealEditor-Engine.dll')){$summary.engine_inputs+=Pin-ReproductionInput (Join-Path $EngineRoot $relative)}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    $dotnet=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/DotNet/10.0/win-x64/dotnet.exe';$ubt=Join-Path $EngineRoot 'Engine/Binaries/DOTNET/UnrealBuildTool/UnrealBuildTool.dll';$project=Join-Path $stage 'LyraStarterGame.uproject'
    $descriptors=@($project)+@(Get-ChildItem -LiteralPath "$stage/Plugins" -Recurse -File -Filter '*.uplugin'|ForEach-Object {$_.FullName})
    $disabledPlugins=@((Get-Content -LiteralPath $project -Raw|ConvertFrom-Json).Plugins|Where-Object {!$_.Enabled}|ForEach-Object {$_.Name})
    $moduleNames=@($descriptors|Where-Object {$_ -eq $project -or [IO.Path]::GetFileNameWithoutExtension($_) -notin $disabledPlugins}|ForEach-Object {$descriptorData=Get-Content -LiteralPath $_ -Raw|ConvertFrom-Json;if($descriptorData.PSObject.Properties.Name -contains 'Modules'){$descriptorData.Modules|ForEach-Object {$_.Name}}}|Sort-Object -Unique)
    if(!$moduleNames.Count -or @($moduleNames|Where-Object {$_ -notmatch '^[A-Za-z0-9_]+$'}).Count){throw 'Explicit project module names required'}
    New-Item -ItemType Directory -Path "$stage/Binaries/Win64" -Force|Out-Null
    & (Join-Path $PSScriptRoot 'Inspect-UEP58ModuleRefresh.ps1') -EngineRoot $EngineRoot -StageProject $project -Target LyraEditor -Modules $moduleNames -OutputDirectory "$output/ProjectPlan" -RefreshRules -UsePrecompiledEngine:$UsePrecompiledEngine
    $actions=(Get-Content -LiteralPath "$output/ProjectPlan/actions.json" -Raw|ConvertFrom-Json -Depth 80).Actions
    foreach($action in $actions){foreach($item in @($action.ProducedItems)+@($action.DeleteItems)){
        if($item -and ![IO.Path]::GetFullPath($item).StartsWith($stage+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Project action would write outside the fresh stage'}
    }}
    $summary.project_modules=$moduleNames;$summary.reviewed_project_actions=$actions.Count
    $summary.cpp_compile_executed=$true
    $arguments=@($ubt,'LyraEditor','Win64','Development',"-Project=$project",('-Module='+($moduleNames -join '+')),'-SkipRulesCompile','-SkipPreBuildTargets','-IgnoreJunk','-WaitMutex','-NoHotReload','-NoEngineChanges','-NoUBA',"-MaxParallelActions=$MaxParallelActions","-Log=$output/build.log")
    if($UsePrecompiledEngine){$arguments+='-UsePrecompiled'}
    $summary.process=Invoke-UEPValidationProcess $dotnet $arguments (Join-Path $EngineRoot 'Engine/Source') "$output/build" 'Fresh current migration Editor build' 7200 $environment
    $log=Get-Content -LiteralPath "$output/build.log" -Raw;if($log -notmatch 'Result: Succeeded' -or $log -match '(?im)(error (C\d+|LNK\d+)|warning (C\d+|LNK\d+))'){throw 'Fresh Editor build diagnostics failed'}
    & $python -B -X utf8 $finalizer --stage $stage --engine $EngineRoot --result "$output/editor-modules.json"
    if($LASTEXITCODE -ne 0){throw 'Fresh project module manifest assembly failed'}
    $moduleReport=Get-Content -LiteralPath "$output/editor-modules.json" -Raw|ConvertFrom-Json -Depth 12
    $summary.products=@($moduleReport.products)+@($moduleReport.manifests)
    foreach($row in @($summary.hashes)+@($summary.engine_inputs)){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Fresh build mutated frozen source or protected Engine input'}}
    $summary.status='built_requires_native_acceptance'
    $summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8
    & (Join-Path $PSScriptRoot 'Run-UEP58NativeHardening.ps1') -EngineRoot $EngineRoot -StageProject $project -OutputDirectory "$output/ActualExceptions" -Mode Exceptions
    $summary.runtime_acceptance=$true;$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
