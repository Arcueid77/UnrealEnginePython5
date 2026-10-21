#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,[ValidateSet('Baseline','Python','BlueprintFallback')][string]$Mode='Baseline',
    [string]$AuthoringDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(($Mode -ne 'Baseline') -ne [bool]$AuthoringDirectory){throw 'Migrated Arena widget profiles require their accepted authoring proof'}
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh workspace-owned output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';mode=$Mode;full_acceptance=$false;network_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;external_gate=$null;error=$null}
function Add-ReadyHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $engineModule=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules';$build=(Get-Content -LiteralPath $engineModule -Raw|ConvertFrom-Json).BuildId;Add-ReadyHash $engineModule
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){$file=Join-Path $stage $relative;if((Get-Content -LiteralPath $file -Raw|ConvertFrom-Json).BuildId -ne $build){throw 'Native BuildId mismatch'};Add-ReadyHash $file}
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},@{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){$copy=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName));if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Native source differs'};Add-ReadyHash $file.FullName;Add-ReadyHash $copy}
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($file in Get-ChildItem -LiteralPath "$overlay/Content/Scripts" -Recurse -File -Filter '*.py'){$copy=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName));New-Item -ItemType Directory -Path (Split-Path $copy -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $copy -Force;Add-ReadyHash $file.FullName;Add-ReadyHash $copy}
    $marker=Get-Content -LiteralPath "$stage/.uep-lyra-full-stage.json" -Raw|ConvertFrom-Json;$official=Split-Path $marker.source -Parent;$widget='Plugins/GameFeatures/TopDownArena/Content/GameplayCues/W_GetReady.uasset';$cue='Plugins/GameFeatures/TopDownArena/Content/GameplayCues/GCN_GetReady.uasset'
    foreach($relative in @($cue,'Plugins/GameFeatures/TopDownArena/Content/Game/Modes/Phase_Warmup.uasset','Plugins/GameFeatures/TopDownArena/Content/Game/Modes/Phase_Playing.uasset')){if((Get-FileHash -LiteralPath (Join-Path $stage $relative)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $official $relative)).Hash){throw 'Original Arena Cue/phase changed'};Add-ReadyHash (Join-Path $stage $relative);Add-ReadyHash (Join-Path $official $relative)}
    if($Mode -eq 'Baseline'){
        if((Get-FileHash -LiteralPath (Join-Path $stage $widget)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $official $widget)).Hash){throw 'Original Arena widget required for baseline'};Add-ReadyHash (Join-Path $official $widget);Add-ReadyHash (Join-Path $stage $widget)
    }else{
        $authorRoot=[IO.Path]::GetFullPath($AuthoringDirectory);if(!$authorRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Workspace-owned Arena widget proof required'}
        $author=Get-Content -LiteralPath "$authorRoot/summary.json" -Raw|ConvertFrom-Json -Depth 100;$proof=Get-Content -LiteralPath "$authorRoot/assets.json" -Raw|ConvertFrom-Json -Depth 100
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $proof.kind -ne 'arenaready' -or !$proof.original_cdo_abis_graphs_guids_widget_tree_and_animation_preserved -or !$proof.cue_child_bytes_and_static_parent_forwarders_preserved -or $proof.method_counts.Python -ne 1 -or $proof.method_counts.BlueprintFallback -ne 1 -or @($author.assets).Count -ne 2){throw 'Exact Arena Construct-only widget proof required'}
        foreach($asset in $author.assets){foreach($file in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $file).Hash -ne $asset.sha256){throw 'Arena widget output changed'};Add-ReadyHash $file}};Add-ReadyHash "$authorRoot/summary.json";Add-ReadyHash "$authorRoot/assets.json"
    }
    foreach($relative in @('Content/GameplayCueNotifies/GCNL_Widget_Base.uasset','Content/UEPMixins/DA_CueWidgetMixin.uasset')){foreach($root in @($stage,$overlay)){Add-ReadyHash (Join-Path $root $relative)}}
    foreach($file in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'),(Join-Path $stage 'Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll'),(Join-Path $EngineRoot 'Engine/Source/Runtime/UMG/Private/UserWidget.cpp'))){Add-ReadyHash $file}
    $arguments=@($project,'/TopDownArena/Maps/L_TopDown_LocalMultiplayer','-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360','-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup','-ExecCmds=t.MaxFPS 60',"-UEPArenaReadyMode=$Mode","-UEPArenaReadyResult=$output/ready.json","-abslog=$output/ready.log","-UserDir=$output/user/")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe') $arguments $stage (Join-Path $output 'ready') 'Actual Arena GetReady widget observation' 240
    $report=Get-Content -LiteralPath "$output/ready.json" -Raw|ConvertFrom-Json -Depth 90;if($report.status -ne 'passed'){throw 'Arena ready native observation failed'}
    $log=Get-Content -LiteralPath "$output/ready.log" -Raw;Assert-UEPFocusedLog $log 'UEP_ARENA_READY_DIFFERENTIAL_PASSED';Assert-UEPFocusedLog $log 'UEP_ARENA_READY_SHUTDOWN_PASSED' -RequirePythonExit
    $summary.external_gate=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe') @('-B','-m','uep_lyra_hud.arena_ready_contract','--report',"$output/ready.json") (Join-Path $overlay 'Content/Scripts') (Join-Path $output 'report-gate') 'Arena ready independent native report gate' 30
    foreach($frozen in $summary.hashes){if((Get-FileHash -LiteralPath $frozen.path).Hash -ne $frozen.sha256){throw 'Arena ready frozen input changed'}};$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Native Arena ready $Mode observation: $($summary.status); $output"
