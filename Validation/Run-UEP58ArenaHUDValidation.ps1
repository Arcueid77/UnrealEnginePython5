#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$ProbeDirectory,
    [ValidateSet('Baseline','Python','BlueprintFallback')][string]$Mode='Baseline',[string]$AuthoringDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(($Mode -ne 'Baseline') -ne [bool]$AuthoringDirectory){throw 'Migrated tile requires accepted authoring proof'}
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh workspace output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
$probeRoot=[IO.Path]::GetFullPath($ProbeDirectory)
if(!$probeRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Workspace observer proof required'}
$probe=Get-Content -LiteralPath "$probeRoot/probe.json" -Raw|ConvertFrom-Json;$probeProcess=Get-Content -LiteralPath "$probeRoot/process.json" -Raw|ConvertFrom-Json
if($probe.status -ne 'passed' -or !$probe.stage_only -or $probe.gameplay_business -or !$probe.typed_virtual_calls -or $probeProcess.exit_code -ne 0 -or (Get-FileHash -LiteralPath $probe.asset).Hash -ne $probe.sha256){throw 'Native tile caller proof incomplete'}
Assert-UEPFocusedLog (Get-Content -LiteralPath "$probeRoot/probe.log" -Raw) 'UEP_ARENA_HUD_PROBE_PASSED'
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';mode=$Mode;full_acceptance=$false;network_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;external_gate=$null;error=$null}
function Add-UIHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $engineModule=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules';$build=(Get-Content -LiteralPath $engineModule -Raw|ConvertFrom-Json).BuildId;Add-UIHash $engineModule
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){$file=Join-Path $stage $relative;if((Get-Content -LiteralPath $file -Raw|ConvertFrom-Json).BuildId -ne $build){throw 'Native BuildId mismatch'};Add-UIHash $file}
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},@{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){$copy=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName));if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Native source differs'};Add-UIHash $file.FullName;Add-UIHash $copy}
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($file in Get-ChildItem -LiteralPath "$overlay/Content/Scripts" -Recurse -File -Filter '*.py'){$copy=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName));New-Item -ItemType Directory -Path (Split-Path $copy -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $copy -Force;Add-UIHash $file.FullName;Add-UIHash $copy}
    $marker=Get-Content -LiteralPath "$stage/.uep-lyra-full-stage.json" -Raw|ConvertFrom-Json;$official=Split-Path $marker.source -Parent;$tile='Plugins/GameFeatures/TopDownArena/Content/UserInterface/W_TopDownPlayers.uasset'
    if($Mode -eq 'Baseline'){
        if((Get-FileHash -LiteralPath (Join-Path $stage $tile)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $official $tile)).Hash){throw 'Original Arena tile required for baseline'};Add-UIHash (Join-Path $official $tile);Add-UIHash (Join-Path $stage $tile)
        $timer='Plugins/GameFeatures/TopDownArena/Content/UserInterface/W_RoundTimer.uasset';if((Get-FileHash -LiteralPath (Join-Path $stage $timer)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $official $timer)).Hash){throw 'Original Arena round timer required'};Add-UIHash (Join-Path $official $timer);Add-UIHash (Join-Path $stage $timer)
    }else{
        $authorRoot=[IO.Path]::GetFullPath($AuthoringDirectory);if(!$authorRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Workspace tile proof required'}
        $author=Get-Content -LiteralPath "$authorRoot/summary.json" -Raw|ConvertFrom-Json -Depth 100;$proof=Get-Content -LiteralPath "$authorRoot/assets.json" -Raw|ConvertFrom-Json -Depth 100
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $proof.kind -ne 'arenahud' -or !$proof.original_cdo_abis_guids_trees_graph_partitions_preserved -or !$proof.original_ftext_namespace_key_format_rounding_and_digits_preserved -or $proof.widgets.list.method_counts.Python -ne 2 -or $proof.widgets.list.method_counts.BlueprintFallback -ne 2 -or $proof.widgets.timer.method_counts.Python -ne 3 -or $proof.widgets.timer.method_counts.BlueprintFallback -ne 3 -or @($author.assets).Count -ne 4){throw 'Exact tile lifecycle authoring proof required'}
        foreach($asset in $author.assets){foreach($file in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $file).Hash -ne $asset.sha256){throw 'Tile output changed'};Add-UIHash $file}};Add-UIHash "$authorRoot/summary.json";Add-UIHash "$authorRoot/assets.json"
    }
    foreach($relative in @('Source/LyraGame/GameModes/AsyncAction_ExperienceReady.cpp','Plugins/UIExtension/Source/Private/Widgets/UIExtensionPointWidget.cpp','Plugins/GameFeatures/TopDownArena/Content/UserInterface/Player/W_PlayerTile.uasset','Plugins/GameFeatures/TopDownArena/Content/UserInterface/Player/W_Powerup_Stat.uasset','Plugins/GameFeatures/TopDownArena/Content/UserInterface/Player/B_PlayerUIComponent.uasset','Plugins/GameFeatures/TopDownArena/Content/Game/Modes/B_TopDownArena_GameComponent_Base.uasset')){Add-UIHash (Join-Path $stage $relative)}
    foreach($relative in @('Engine/Source/Runtime/Engine/Private/KismetMathLibrary.cpp','Engine/Source/Runtime/Engine/Private/KismetTextLibrary.cpp','Engine/Source/Runtime/UMG/Private/UserWidget.cpp')){Add-UIHash (Join-Path $EngineRoot $relative)}
    foreach($file in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'),(Join-Path $stage 'Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll'),$probe.asset,"$probeRoot/probe.json","$probeRoot/process.json",(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_arena_hud_probe.py'))){Add-UIHash $file}
    $arguments=@($project,'/TopDownArena/Maps/L_TopDown_LocalMultiplayer','-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360','-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup','-ExecCmds=t.MaxFPS 60',"-UEPArenaHUDMode=$Mode","-UEPArenaHUDResult=$output/hud.json","-abslog=$output/hud.log","-UserDir=$output/user/")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe') $arguments $stage (Join-Path $output 'hud') 'Actual Arena HUD Configure and native team callbacks' 240
    $report=Get-Content -LiteralPath "$output/hud.json" -Raw|ConvertFrom-Json -Depth 90;if($report.status -ne 'passed'){throw 'Arena tile native observation failed'}
    $log=Get-Content -LiteralPath "$output/hud.log" -Raw;Assert-UEPFocusedLog $log 'UEP_ARENA_HUD_DIFFERENTIAL_PASSED';Assert-UEPFocusedLog $log 'UEP_ARENA_HUD_SHUTDOWN_PASSED' -RequirePythonExit
    $summary.external_gate=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe') @('-B','-m','uep_lyra_hud.arena_hud_contract','--report',"$output/hud.json") (Join-Path $overlay 'Content/Scripts') (Join-Path $output 'report-gate') 'Arena tile independent registry report gate' 30
    foreach($frozen in $summary.hashes){if((Get-FileHash -LiteralPath $frozen.path).Hash -ne $frozen.sha256){throw 'Arena tile frozen input changed'}};$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Native Arena HUD ${Mode}: $($summary.status); $output"
