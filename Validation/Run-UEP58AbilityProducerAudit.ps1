#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,[switch]$Coverage,[switch]$SparseMap,[switch]$Interaction,[switch]$ReloadFamily,[switch]$SpawnEffect,[switch]$DeviceColor,[switch]$Emote,[switch]$WidgetInput,[switch]$WidgetPressedContext,[switch]$AutoRespawnHelpers,[switch]$ExplorerShells,[switch]$HeroDefault,[switch]$HeroDefaultMotion,[string]$HeroDefaultBaseline,[switch]$ArenaRuntime)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if([bool]$HeroDefaultMotion -ne [bool]$HeroDefaultBaseline){throw 'Motion audit requires its explicit accepted parent baseline'}
if(@(@([bool]$Coverage,[bool]$SparseMap,[bool]$Interaction,[bool]$ReloadFamily,[bool]$SpawnEffect,[bool]$DeviceColor,[bool]$Emote,[bool]$WidgetInput,[bool]$WidgetPressedContext,[bool]$AutoRespawnHelpers,[bool]$ExplorerShells,[bool]$HeroDefault,[bool]$HeroDefaultMotion,[bool]$ArenaRuntime)|Where-Object {$_}).Count -gt 1){throw 'Choose one native audit mode'}
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject)
$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked workspace stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Fresh evidence directory required'}
if(@(Get-Process -Name 'UnrealEditor','UnrealEditor-Cmd','UnrealBuildTool' -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';mode='read-only-native-ability-defaults';runtime_acceptance=$false
    native_failure_producer_tested=$false;assets_modified=$false;cpp_compile_executed=$false;cook_package_executed=$false
    hashes=@();process=$null;error=$null}
function Add-ProducerHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $module=Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules'
    $engineId=(Get-Content -Raw -LiteralPath $module|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries\Win64\UnrealEditor.modules','Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules',
                           'Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor.modules')){
        $file=Join-Path $stage $relative
        if((Get-Content -Raw -LiteralPath $file|ConvertFrom-Json).BuildId -ne $engineId){throw 'Matching UE 5.8.1 binaries required'}
        Add-ProducerHash $file
    }
    $summary.editor_build_id=$engineId
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source differs'}
        Add-ProducerHash $source.FullName;Add-ProducerHash $target
    }
    $script=Join-Path $repo $(if($ReloadFamily){'Demos\UEPLyraIntegration\Tools\audit_reload_family.py'}elseif($Interaction){'Demos\UEPLyraIntegration\Tools\audit_interaction_producers.py'}elseif($SparseMap){'Demos\UEPLyraIntegration\Tools\validate_sparse_map_conversion.py'}elseif($Coverage){'Demos\UEPLyraIntegration\Tools\audit_runtime_mixin_coverage.py'}else{'Demos\UEPLyraIntegration\Tools\audit_native_ability_producers.py'})
    if($SpawnEffect){$script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_spawn_effect.py'}
    if($DeviceColor){$script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_device_color.py'}
    if($Emote){$script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_emote.py'}
    if($WidgetInput){$script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_widget_input_abilities.py'}
    if($WidgetPressedContext){$script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_widget_pressed_context.py'}
    if($HeroDefault){$script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_hero_default.py'}
    if($ArenaRuntime){$script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_arena_runtime.py';Add-ProducerHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/mixin_graph_gates.py')}
    if($HeroDefaultMotion){$script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_hero_default_motion.py';Add-ProducerHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/mixin_graph_gates.py')}
    if($ExplorerShells){$script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_explorer_shells.py'}
    if($AutoRespawnHelpers){$script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_auto_respawn_helpers.py'}
    foreach($file in @($PSCommandPath,$module,$script,(Join-Path (Split-Path $script -Parent) 'stage_safety.py'),
        (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),
        (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))){Add-ProducerHash $file}
    if($ExplorerShells){Add-ProducerHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/explorer_shell_review.py')}
    $stageFlag=if($ReloadFamily){'-UEPReloadFamilyStageRoot'}elseif($Interaction){'-UEPInteractionStageRoot'}elseif($SparseMap){'-UEPSparseMapStageRoot'}elseif($Coverage){'-UEPCoverageStageRoot'}else{'-UEPAbilityProducerStageRoot'}
    $resultFlag=if($ReloadFamily){'-UEPReloadFamilyAuditResult'}elseif($Interaction){'-UEPInteractionAuditResult'}elseif($SparseMap){'-UEPSparseMapResult'}elseif($Coverage){'-UEPCoverageAuditResult'}else{'-UEPAbilityProducerAuditResult'}
    $marker=if($ReloadFamily){'UEP_RELOAD_FAMILY_AUDIT_PASSED'}elseif($Interaction){'UEP_INTERACTION_PRODUCER_AUDIT_PASSED'}elseif($SparseMap){'UEP_SPARSE_MAP_CONVERSION_PASSED'}elseif($Coverage){'UEP_RUNTIME_COVERAGE_AUDIT_PASSED'}else{'UEP_ABILITY_PRODUCER_AUDIT_PASSED'}
    if($SpawnEffect){$stageFlag='-UEPSpawnEffectStageRoot';$resultFlag='-UEPSpawnEffectAuditResult';$marker='UEP_SPAWN_EFFECT_AUDIT_PASSED'}
    if($DeviceColor){$stageFlag='-UEPDeviceColorStageRoot';$resultFlag='-UEPDeviceColorAuditResult';$marker='UEP_DEVICE_COLOR_AUDIT_PASSED'}
    if($Emote){$stageFlag='-UEPEmoteStageRoot';$resultFlag='-UEPEmoteAuditResult';$marker='UEP_EMOTE_AUDIT_PASSED'}
    if($WidgetInput){$stageFlag='-UEPWidgetInputStageRoot';$resultFlag='-UEPWidgetInputAuditResult';$marker='UEP_WIDGET_INPUT_AUDIT_PASSED'}
    if($WidgetPressedContext){$stageFlag='-UEPWidgetPressedStageRoot';$resultFlag='-UEPWidgetPressedAuditResult';$marker='UEP_WIDGET_PRESSED_CONTEXT_AUDIT_PASSED'}
    if($HeroDefault){$stageFlag='-UEPHeroDefaultStage';$resultFlag='-UEPHeroDefaultResult';$marker='UEP_HERO_DEFAULT_AUDIT_PASSED'}
    if($ArenaRuntime){$stageFlag='-UEPArenaStage';$resultFlag='-UEPArenaResult';$marker='UEP_ARENA_RUNTIME_AUDIT_PASSED'}
    if($HeroDefaultMotion){$stageFlag='-UEPHeroDefaultStage';$resultFlag='-UEPHeroDefaultResult';$marker='UEP_HERO_DEFAULT_MOTION_AUDIT_PASSED'}
    if($ExplorerShells){$stageFlag='-UEPExplorerShellStage';$resultFlag='-UEPExplorerShellResult';$marker='UEP_EXPLORER_SHELL_AUDIT_PASSED'}
    if($AutoRespawnHelpers){$stageFlag='-UEPAutoRespawnHelpersStageRoot';$resultFlag='-UEPAutoRespawnHelpersAuditResult';$marker='UEP_AUTO_RESPAWN_HELPERS_AUDIT_PASSED'}
    $arguments=@($project,'-run=Py',$script,'-NullRHI',"$stageFlag=$stage","$resultFlag=$output\audit.json",
        '-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',"-abslog=$output\audit.log")
    if($HeroDefaultMotion){$arguments+=@('-UEPHeroDefaultBaseline='+[IO.Path]::GetFullPath($HeroDefaultBaseline))}
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'audit') 'Native ability producer read-only audit' 180
    $report=Get-Content -Raw -LiteralPath (Join-Path $output 'audit.json')|ConvertFrom-Json -Depth 90
    if($report.status -ne 'passed' -or $report.runtime_acceptance){throw 'Native read-only audit incomplete'}
    if($ArenaRuntime){
        if($report.assets_modified -or $report.assets_saved_or_compiled -or !$report.original_candidate_paths_retained -or $report.remaining_arena_business_migrated -or @($report.assets.PSObject.Properties).Count -ne 20){throw 'Exact original20 Arena graph/CDO/ABI audit required'}
        $summary.mode='read-only-original-arena-runtime-candidates';$summary.assets=20
    }elseif($HeroDefault -or $HeroDefaultMotion){
        if($report.assets_modified -or $report.assets_saved_or_compiled -or $report.asset.package -ne '/Game/Characters/Heroes/B_Hero_Default.B_Hero_Default'){throw 'Original parent character source proof required'}
        $summary.mode='read-only-original-hero-default-parent';$summary.assets=1
    }elseif($ExplorerShells){
        if($report.assets_modified -or $report.assets_saved_or_compiled -or !$report.original_candidate_paths_retained -or $report.inherited_parent_business_migrated -or @($report.assets.PSObject.Properties).Count -ne 5){throw 'Original shell/prompt source disposition proof required'}
        $summary.mode='read-only-original-explorer-shells-and-prompt';$summary.assets=5
    }elseif($AutoRespawnHelpers){
        if($report.assets_modified -or @($report.assets).Count -ne 1 -or @($report.helper_scope).Count -ne 3 -or $report.death_listener_timer_restart_business_migrated){throw 'Original AutoRespawn helper audit incomplete'}
        $summary.mode='read-only-native-auto-respawn-helpers';$summary.assets=1
    }elseif($WidgetPressedContext){
        if($report.assets_modified -or @($report.assets).Count -ne 10 -or $report.runtime_input_or_ui_tested -or $report.editor_or_test_tools_migrated){throw 'Pressed-widget context audit incomplete'}
        $summary.mode='read-only-native-widget-pressed-context';$summary.assets=10
    }elseif($WidgetInput){
        if($report.assets_modified -or @($report.assets).Count -ne 6 -or $report.ui_input_suspension_runtime_tested){throw 'Original widget-input family audit incomplete'}
        $summary.mode='read-only-native-widget-input';$summary.assets=6
    }elseif($Emote){
        if($report.assets_modified -or @($report.assets).Count -ne 1){throw 'Original Emote audit incomplete'}
        $summary.mode='read-only-native-emote';$summary.assets=1
    }elseif($DeviceColor){
        if($report.assets_modified -or @($report.assets).Count -ne 1 -or $report.hardware_output_tested){throw 'Original device color audit incomplete'}
        $summary.mode='read-only-native-device-color';$summary.assets=1
    }elseif($SpawnEffect){
        if($report.assets_modified -or @($report.assets).Count -ne 2){throw 'Original SpawnEffect audit incomplete'}
        $summary.mode='read-only-native-spawn-effect';$summary.assets=2
    }elseif($ReloadFamily){
        if($report.assets_modified -or @($report.assets).Count -ne 5 -or !$report.synchronous_asset_registry_scan -or $report.prototype_unused_claimed){throw 'Original reload family audit incomplete'}
        $summary.mode='read-only-native-reload-family';$summary.assets=5
    }elseif($Interaction){
        if($report.assets_modified -or !$report.original_assets_unchanged -or $report.native_interaction_producer_tested -or @($report.assets).Count -ne 5){throw 'Original interaction producer audit incomplete'}
        $summary.mode='read-only-native-interaction-producer-defaults';$summary.assets=5
    }elseif($SparseMap){
        if($report.assets_modified -or @($report.cases).Count -ne 6 -or @($report.cases|Where-Object {!$_.passed -or !$_.native_bp_remove -or !$_.native_export_matches_expected}).Count){throw 'Sparse native TMap conversion differs'}
        $summary.mode='native-sparse-map-conversion';$summary.cases=6
    }elseif($Coverage){
        if($report.full_acceptance -or $report.assets_saved_or_compiled -or !$report.coverage_is_registration_not_gameplay -or
           @($report.assets).Count -ne 37){throw 'Read-only coverage inventory incomplete'}
        $summary.mode='read-only-native-router-coverage';$summary.assets=37
        $summary.unrouted_business_assets=@($report.unrouted_business_assets)
        $summary.partial_profile_assets=@($report.partial_profile_assets)
    }elseif($report.assets_modified -or @($report.abilities).Count -ne 8){throw 'Native producer audit incomplete'}
    foreach($pair in $report.reference_hashes.PSObject.Properties){
        if((Get-FileHash -LiteralPath $pair.Name).Hash -ne $pair.Value){throw 'Original ability changed during read-only audit'}
        Add-ProducerHash $pair.Name
    }
    $log=Get-Content -Raw -LiteralPath (Join-Path $output 'audit.log')
    Assert-UEPFocusedLog $log $marker
    if($log -notmatch ('(?s)'+[regex]::Escape($marker)+'.*Goodbye Python.*Log file closed')){
        throw 'Read-only commandlet completion/exit ordering incomplete'
    }
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Native producer audit input changed'}}
    $summary.status='passed'
    if(!$Coverage -and !$SparseMap -and !$Interaction -and !$ReloadFamily -and !$SpawnEffect -and !$DeviceColor -and !$Emote -and !$WidgetInput -and !$WidgetPressedContext -and !$AutoRespawnHelpers -and !$ExplorerShells -and !$HeroDefault -and !$HeroDefaultMotion -and !$ArenaRuntime){$summary.abilities=8}
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Native ability defaults audit: $($summary.status); $output"
