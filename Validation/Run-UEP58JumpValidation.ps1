#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,
      [Parameter(Mandatory=$true)][string]$AssetAuthoringDirectory,[switch]$WidgetLifecycle,[switch]$Network,[switch]$Quickslot,[switch]$Death,[switch]$ThreadedLoading,[switch]$Cosmetics,[switch]$AutoReload,[switch]$HeroHeal,[switch]$ADS,[switch]$DropWeapon,[switch]$ReloadMagazine,
      [switch]$WeaponInstance,[switch]$SpawnEffect,[switch]$DeviceColor,[switch]$Emote,[switch]$WidgetHeld,[switch]$WidgetPressed,[switch]$AutoRespawnHelpers,[switch]$AutoRespawnListeners,[switch]$AutoRespawnEvents,[switch]$AutoRespawnActivation,[switch]$AutoRespawnLifecycle,[switch]$EquipmentGC,[switch]$EquipmentDeath,[switch]$EquipmentIntegration,[switch]$EquipmentBlueprintFallback,[string]$EquipmentAuthoringDirectory,
      [string]$AbilityWidgetFamilyRevisionDirectory,[switch]$AutoRespawnReset,[string]$ResetProbeAssetDirectory,
      [switch]$CharacterInventory,[switch]$CharacterAudio,[switch]$CharacterQuickbar,[switch]$CharacterLoadout,[switch]$CharacterLoadoutNatural,[switch]$CharacterOutline,[switch]$CharacterTeam,[switch]$CharacterStencil,[switch]$CharacterLifecycle,[switch]$CharacterParts,[switch]$CharacterHealth,[switch]$CharacterInput,[switch]$CharacterObserver,[switch]$CharacterListener,[switch]$CharacterLegacy,[switch]$CharacterReady,[switch]$CharacterWait,[switch]$CharacterPossessed,[switch]$CharacterVisibility,[switch]$CharacterBeginPlay,[switch]$CharacterEquipmentHide,[switch]$CharacterRagdoll,[switch]$CharacterDeathStarted,[string]$CharacterAuthoringDirectory,
      [switch]$CharacterDeathReplication,
      [switch]$DashSelector,[string]$DashSelectorAuthoringDirectory,
      [switch]$DashRPCInput,[string]$DashRPCInputAuthoringDirectory,
      [switch]$DashLocalDirection,[string]$DashLocalDirectionAuthoringDirectory,
      [ValidateSet('tdm','cp')][string]$WidgetHeldMode='tdm',
      [ValidateRange(1024,65535)][int]$ServerPort=7794,
      [ValidateSet('pistol','rifle','shotgun','netshooter')][string]$ReloadWeapon='pistol')
# Only existing binaries and already authored disposable assets. No build/cook.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($DashLocalDirection){
    if(!$DashLocalDirectionAuthoringDirectory -or !$DashRPCInputAuthoringDirectory){throw 'Local direction requires the complete authored Dash revision chain'}
    $DashSelector=$true
    if($Network){$DashRPCInput=$true}
}
if($DashLocalDirectionAuthoringDirectory -and (!$DashSelector -or !$DashRPCInputAuthoringDirectory)){throw 'Local direction revision requires selector/RPC provenance'}
if($DashRPCInput){
    if(!$Network -or !$DashRPCInputAuthoringDirectory){throw 'Dash RPC ingress requires its authored revision and two-client native network lane'}
    $DashSelector=$true
}
if($DashRPCInputAuthoringDirectory -and !$DashSelector){throw 'Dash RPC revision requires the original selector proof'}
if($DashSelector){
    if(!$DashSelectorAuthoringDirectory -or $CharacterAuthoringDirectory -or $AutoRespawnReset -or $AutoRespawnLifecycle){throw 'Dash selector requires its own helper lane and authored proof'}
    $AutoRespawnActivation=$true
}
if($CharacterDeathReplication -and (!$Network -or !$CharacterDeathStarted)){throw 'Real replicated Character death requires Network, CharacterDeathStarted and its existing asset proof'}
if($CharacterDeathStarted){
    if($CharacterRagdoll -or $CharacterEquipmentHide -or $CharacterBeginPlay -or $CharacterVisibility -or $CharacterPossessed -or $CharacterWait -or $CharacterReady -or $CharacterLegacy -or $CharacterListener -or $CharacterObserver){throw 'Choose one Character death-started/Ragdoll lane'}
    $CharacterRagdoll=$true
}
if($CharacterRagdoll){
    if($CharacterEquipmentHide -or $CharacterBeginPlay -or $CharacterVisibility -or $CharacterPossessed -or $CharacterWait -or $CharacterReady -or $CharacterLegacy -or $CharacterListener -or $CharacterObserver){throw 'Choose one Character Ragdoll/equipment-hide lane'}
    $CharacterEquipmentHide=$true
}
if($CharacterEquipmentHide){
    if($CharacterBeginPlay -or $CharacterVisibility -or $CharacterPossessed -or $CharacterWait -or $CharacterReady -or $CharacterLegacy -or $CharacterListener -or $CharacterObserver){throw 'Choose one Character equipment-hide/BeginPlay lane'}
    $CharacterBeginPlay=$true
}
if($CharacterBeginPlay){
    if($CharacterVisibility -or $CharacterPossessed -or $CharacterWait -or $CharacterReady -or $CharacterLegacy -or $CharacterListener -or $CharacterObserver){throw 'Choose one Character BeginPlay/visibility/possession lane'}
    $CharacterVisibility=$true
}
if($CharacterVisibility){
    if($CharacterPossessed -or $CharacterWait -or $CharacterReady -or $CharacterLegacy -or $CharacterListener -or $CharacterObserver){throw 'Choose one Character visibility/possession/wait lane'}
    $CharacterPossessed=$true
}
if($CharacterPossessed){
    if($CharacterWait -or $CharacterReady -or $CharacterLegacy -or $CharacterListener -or $CharacterObserver){throw 'Choose one Character possession/wait/readiness lane'}
    $CharacterWait=$true
}
if($CharacterWait){
    if($CharacterReady -or $CharacterLegacy -or $CharacterListener -or $CharacterObserver){throw 'Choose one Character wait/readiness/legacy/listener/observer lane'}
    $CharacterReady=$true
}
if($CharacterReady){
    if($CharacterLegacy -or $CharacterListener -or $CharacterObserver){throw 'Choose one Character readiness/legacy/listener/observer lane'}
    $CharacterLegacy=$true
}
if($CharacterLegacy){
    if($CharacterListener -or $CharacterObserver){throw 'Choose one Character legacy/listener/observer lane'}
    $CharacterListener=$true
}
if($CharacterListener){
    if($CharacterObserver){throw 'Choose one Character observer/listener lane'}
    $CharacterObserver=$true
}
if($CharacterAudio -and ($CharacterInventory -or $AutoRespawnReset -or $AutoRespawnLifecycle -or !$CharacterAuthoringDirectory)){throw 'Character audio requires its Interface lane and asset proof'}
if($CharacterAudio){$AutoRespawnActivation=$true}
if($CharacterQuickbar -and ($CharacterAudio -or $CharacterInventory -or $AutoRespawnReset -or $AutoRespawnLifecycle -or !$CharacterAuthoringDirectory)){throw 'Character slot input requires its own BP-call lane and asset proof'}
if($CharacterQuickbar){$AutoRespawnActivation=$true}
if($CharacterLoadoutNatural -and $Network){throw 'Character loadout natural death/Avatar regression is its own standalone lane'}
if($CharacterLoadoutNatural){$CharacterLoadout=$true}
if($CharacterLoadout -and ($CharacterQuickbar -or $CharacterAudio -or $CharacterInventory -or $AutoRespawnReset -or $AutoRespawnLifecycle -or !$CharacterAuthoringDirectory)){throw 'Character loadout requires its own native grant lane and asset proof'}
if($CharacterLoadout){$AutoRespawnActivation=$true}
if($CharacterOutline -and ($CharacterLoadout -or $CharacterQuickbar -or $CharacterAudio -or $CharacterInventory -or $AutoRespawnReset -or $AutoRespawnLifecycle -or !$CharacterAuthoringDirectory)){throw 'Character outline requires its own BP/material Interface lane and asset proof'}
if($CharacterOutline){$AutoRespawnActivation=$true}
if($CharacterTeam -and ($CharacterOutline -or $CharacterLoadout -or $CharacterQuickbar -or $CharacterAudio -or $CharacterInventory -or $AutoRespawnReset -or $AutoRespawnLifecycle -or !$CharacterAuthoringDirectory)){throw 'Character team requires its own native orchestration lane and asset proof'}
if($CharacterTeam){$AutoRespawnActivation=$true}
if($CharacterStencil -and ($CharacterTeam -or $CharacterOutline -or $CharacterLoadout -or $CharacterQuickbar -or $CharacterAudio -or $CharacterInventory -or $AutoRespawnReset -or $AutoRespawnLifecycle -or !$CharacterAuthoringDirectory)){throw 'Character inherited stencil requires its own native parent/BP-call/GC lane and asset proof'}
if($CharacterStencil){$AutoRespawnActivation=$true}
if($CharacterLifecycle -and ($CharacterStencil -or $CharacterTeam -or $CharacterOutline -or $CharacterLoadout -or $CharacterQuickbar -or $CharacterAudio -or $CharacterInventory -or $AutoRespawnLifecycle -or ($Network -and $AutoRespawnReset) -or !$CharacterAuthoringDirectory)){throw 'Character native death/Reset events require their own natural/network or standalone Reset lane and asset proof'}
if($CharacterLifecycle){$AutoRespawnActivation=$true}
if($CharacterParts -and ($CharacterLifecycle -or $CharacterStencil -or $CharacterTeam -or $CharacterOutline -or $CharacterLoadout -or $CharacterQuickbar -or $CharacterAudio -or $CharacterInventory -or $AutoRespawnLifecycle -or $AutoRespawnReset -or !$CharacterAuthoringDirectory)){throw 'Character parts callback requires its own native part producer/replication lane and asset proof'}
if($CharacterParts){$AutoRespawnActivation=$true}
if($CharacterHealth -and ($CharacterParts -or $CharacterLifecycle -or $CharacterStencil -or $CharacterTeam -or $CharacterOutline -or $CharacterLoadout -or $CharacterQuickbar -or $CharacterAudio -or $CharacterInventory -or $AutoRespawnLifecycle -or $AutoRespawnReset -or !$CharacterAuthoringDirectory)){throw 'Character health receiver requires its own native GAS/AI perception lane and asset proof'}
if($CharacterHealth){$AutoRespawnActivation=$true}
if($CharacterInput -and ($CharacterHealth -or $CharacterParts -or $CharacterLifecycle -or $CharacterStencil -or $CharacterTeam -or $CharacterOutline -or $CharacterLoadout -or $CharacterQuickbar -or $CharacterAudio -or $CharacterInventory -or $AutoRespawnLifecycle -or $AutoRespawnReset -or !$CharacterAuthoringDirectory)){throw 'Character EnhancedInput requires its own native input/owner RPC lane and asset proof'}
if($CharacterInput){$AutoRespawnActivation=$true}
if($CharacterObserver -and ($CharacterInput -or $CharacterHealth -or $CharacterParts -or $CharacterLifecycle -or $CharacterStencil -or $CharacterTeam -or $CharacterOutline -or $CharacterLoadout -or $CharacterQuickbar -or $CharacterAudio -or $CharacterInventory -or $AutoRespawnLifecycle -or $AutoRespawnReset -or !$CharacterAuthoringDirectory)){throw 'Character team observer requires its own real native factory/cancellation lane and asset proof'}
if($CharacterObserver){$AutoRespawnActivation=$true}
if($CharacterInventory -and ($AutoRespawnLifecycle -or ($Network -and $AutoRespawnReset) -or !$CharacterAuthoringDirectory)){throw 'Character inventory helper requires natural/network or standalone Reset and Character asset proof'}
if($CharacterInventory){$AutoRespawnActivation=$true}
if($AutoRespawnLifecycle -and $Network){throw 'Test-owned native Clear/Give lifecycle is a separate standalone lane'}
if($AutoRespawnReset -and ($AutoRespawnLifecycle -or !$ResetProbeAssetDirectory)){throw 'Native Reset requires its separate lane and stage-only typed probe proof'}
if($AutoRespawnReset){$AutoRespawnActivation=$true}
if($AutoRespawnLifecycle){$AutoRespawnActivation=$true}
if($AutoRespawnActivation){$AutoRespawnEvents=$true}
if($AutoRespawnEvents){$AutoRespawnListeners=$true}
if($AutoRespawnListeners){$AutoRespawnHelpers=$true}
if($Network -and $WidgetLifecycle){throw 'Select either two-owner Jump or standalone UI lifecycle'}
if($Quickslot -and $WidgetLifecycle){throw 'Quickslot and standalone UI lifecycle are separate lanes'}
if($Death -and ($Quickslot -or $WidgetLifecycle)){throw 'Death and other ability fixtures are separate lanes'}
if($Cosmetics -and ($Quickslot -or $Death -or $WidgetLifecycle)){throw 'Cosmetic and ability fixtures are separate lanes'}
if($AutoReload -and ($Quickslot -or $Death -or $WidgetLifecycle -or $Cosmetics)){throw 'AutoReload and other ability fixtures are separate lanes'}
if($HeroHeal -and ($Quickslot -or $Death -or $WidgetLifecycle -or $Cosmetics -or $AutoReload)){throw 'Hero Heal and other ability fixtures are separate lanes'}
if($ADS -and ($Quickslot -or $Death -or $Cosmetics -or $AutoReload -or $HeroHeal)){throw 'ADS and other ability fixtures are separate lanes'}
if($DropWeapon -and ($Quickslot -or $Death -or $Cosmetics -or $AutoReload -or $HeroHeal -or $ADS -or $WidgetLifecycle)){throw 'DropWeapon and other ability fixtures are separate lanes'}
if($ReloadMagazine -and ($Quickslot -or $Death -or $Cosmetics -or $AutoReload -or $HeroHeal -or $ADS -or $DropWeapon -or $WidgetLifecycle)){throw 'ReloadMagazine and other fixtures are separate lanes'}
if($ReloadWeapon -ne 'pistol' -and !$ReloadMagazine){throw 'Non-pistol reload requires its native weapon fixture lane'}
if($WeaponInstance -and ($Network -or $Quickslot -or $Death -or $Cosmetics -or $AutoReload -or $HeroHeal -or $ADS -or $DropWeapon -or $WidgetLifecycle -or $ReloadMagazine)){throw 'Equipment-instance standalone is a separate native lane'}
if($SpawnEffect -and ($WeaponInstance -or $Quickslot -or $Death -or $Cosmetics -or $AutoReload -or $HeroHeal -or $ADS -or $DropWeapon -or $WidgetLifecycle -or $ReloadMagazine)){throw 'SpawnEffect is a separate native lane'}
if($DeviceColor -and ($Network -or $SpawnEffect -or $WeaponInstance -or $Quickslot -or $Death -or $Cosmetics -or $AutoReload -or $HeroHeal -or $ADS -or $DropWeapon -or $WidgetLifecycle -or $ReloadMagazine)){throw 'Device color is a standalone software lane'}
if($Emote -and ($DeviceColor -or $SpawnEffect -or $WeaponInstance -or $Quickslot -or $Death -or $Cosmetics -or $AutoReload -or $HeroHeal -or $ADS -or $DropWeapon -or $WidgetLifecycle -or $ReloadMagazine)){throw 'Emote is a separate native lane'}
if($WidgetHeld -and ($Emote -or $DeviceColor -or $SpawnEffect -or $WeaponInstance -or $Quickslot -or $Death -or $Cosmetics -or $AutoReload -or $HeroHeal -or $ADS -or $DropWeapon -or $WidgetLifecycle -or $ReloadMagazine)){throw 'Held-widget is a separate native lane'}
if($WidgetHeldMode -ne 'tdm' -and (!$WidgetHeld -or $Network)){throw 'ControlPoint held-widget has its own standalone Experience lane'}
if($WidgetPressed -and ($WidgetHeld -or $Emote -or $DeviceColor -or $SpawnEffect -or $WeaponInstance -or $Quickslot -or $Death -or $Cosmetics -or $AutoReload -or $HeroHeal -or $ADS -or $DropWeapon -or $WidgetLifecycle -or $ReloadMagazine)){throw 'Pressed-widget is a separate native lane'}
if($AutoRespawnHelpers -and ($WidgetPressed -or $WidgetHeld -or $Emote -or $DeviceColor -or $SpawnEffect -or $WeaponInstance -or $Quickslot -or $Death -or $Cosmetics -or $AutoReload -or $HeroHeal -or $ADS -or $DropWeapon -or $WidgetLifecycle -or $ReloadMagazine)){throw 'AutoRespawn helpers are a separate native lane'}
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
if($AbilityWidgetFamilyRevisionDirectory -and !$WidgetLifecycle){throw 'Family revision chain currently applies to standalone shared-Widget lifecycle'}
if($EquipmentGC -and !$WeaponInstance){throw 'Equipment GC requires its standalone equipment lane'}
if($EquipmentDeath -and (!$Death -or $Network -or !$EquipmentAuthoringDirectory)){throw 'Dead equipment requires standalone native Death and both asset proofs'}
if($EquipmentIntegration -and (!$ReloadMagazine -or !$Network -or $ReloadWeapon -eq 'pistol' -or !$EquipmentAuthoringDirectory)){throw 'Equipment integration requires its actual temporary-weapon reload network lane and authoring proof'}
if($EquipmentBlueprintFallback -and !$EquipmentIntegration){throw 'Equipment BP baseline requires its native integration lane'}
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked disposable stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Fresh native Jump evidence directory required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'A native lane is already active'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';bounded_runtime_acceptance=$false;full_acceptance=$false
    network_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;assets_saved=$false
    hashes=@();process=$null;external_gate=$null;error=$null;threaded_loading_requested=[bool]$ThreadedLoading}
$handles=@{};$summary.processes=@{}
function Add-JumpInput([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $id=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $relative
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Native BuildId mismatch'}
        Add-JumpInput $path
    }
    $summary.engine_build_id=$id
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName))
            if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source parity mismatch'}
            Add-JumpInput $file.FullName;Add-JumpInput $target
        }
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        Add-JumpInput $file.FullName;Add-JumpInput $target
    }
    $authorPath=Join-Path $AssetAuthoringDirectory 'summary.json'
    $author=Get-Content -LiteralPath $authorPath -Raw|ConvertFrom-Json -Depth 80
    $expectedAssets=if($ADS){3}elseif($Cosmetics){4}elseif($Quickslot -or $Death -or $AutoReload -or $HeroHeal -or $DropWeapon -or $ReloadMagazine){2}else{4}
    if($WeaponInstance){$expectedAssets=2}
    if($SpawnEffect){$expectedAssets=2}
    if($DeviceColor){$expectedAssets=2}
    if($WidgetHeld){$expectedAssets=2}
    if($WidgetPressed){$expectedAssets=2}
    if($AutoRespawnHelpers){$expectedAssets=2}
    if($Emote -or ($ADS -and $author.kind -eq 'emoteparent')){$expectedAssets=4}
    if($author.status -ne 'passed' -or $author.runtime_acceptance -or @($author.assets).Count -ne $expectedAssets){throw 'Accepted native ability asset authoring required'}
    $currentAuthorAssets=@($author.assets)
    if($AbilityWidgetFamilyRevisionDirectory){
        . (Join-Path $PSScriptRoot 'UEPAbilityWidgetProvenance.ps1')
        $family=Get-UEPAbilityWidgetFamilyProvenance $AssetAuthoringDirectory $AbilityWidgetFamilyRevisionDirectory
        $currentAuthorAssets=@($family.assets)
        foreach($proof in $family.evidence){Add-JumpInput $proof}
        Add-JumpInput (Join-Path $PSScriptRoot 'UEPAbilityWidgetProvenance.ps1')
    }
    foreach($asset in $currentAuthorAssets){foreach($path in @($asset.stage,$asset.overlay)){
        if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Authored Jump asset changed'}
        Add-JumpInput $path
    }}
    Add-JumpInput $authorPath
    $assetReport=Join-Path $AssetAuthoringDirectory 'assets.json'
    $authored=Get-Content -LiteralPath $assetReport -Raw|ConvertFrom-Json -Depth 90
    if(!$WeaponInstance -and !$SpawnEffect -and !$DeviceColor -and !$Emote -and !$WidgetHeld -and !$WidgetPressed -and !$AutoRespawnHelpers){
    $preserved=if($Cosmetics){$authored.original_classes_defaults_signatures_graphs_preserved}elseif($Quickslot -or $Death -or $AutoReload -or $HeroHeal -or $ADS -or $DropWeapon -or $ReloadMagazine){$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq $(if($ReloadMagazine){'reloadmagazine'}elseif($DropWeapon){'dropweapon'}elseif($ADS){'adsparent'}elseif($HeroHeal){'heroheal'}elseif($AutoReload){'autoreload'}elseif($Death){'death'}else{'quickslot'})}else{$authored.original_class_defaults_signatures_and_graphs_preserved}
    }
    if($WeaponInstance){$preserved=$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq 'weaponinstance'}
    if($Emote -or ($ADS -and $author.kind -eq 'emoteparent')){
        $preserved=$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq 'emoteparent' -and
            $authored.single_parent_router -and $authored.original_full_cdo_preserved -and $authored.existing_ads_profiles_defaults_graphs_preserved
    }
    if($SpawnEffect){$preserved=$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq 'spawneffect' -and $authored.full_spawn_cdo_preserved}
    if($DeviceColor){$preserved=$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq 'devicecolor' -and $authored.full_device_cdo_preserved -and $authored.native_parent_wiring_preserved}
    if($WidgetHeld){$preserved=$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq 'widgetheld' -and $authored.original_full_cdo_preserved -and $authored.native_children_unchanged -and $authored.soft_class_path_transport_nodes -eq 4 -and $authored.native_state_teardown_guard_nodes -eq 4}
    if($WidgetPressed){$preserved=$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq 'widgetpressed' -and $authored.original_full_cdo_preserved -and
        $authored.native_children_unchanged -and $authored.native_end_adapter_nodes -eq 3 -and $authored.soft_class_path_transport_nodes -eq 4 -and $authored.original_delegate_cleanup_nodes -eq 4 -and $authored.original_pending_widget_capture_nodes -eq 3}
    if($AutoRespawnHelpers -and !$AutoRespawnListeners){$preserved=$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq 'autorespawnhelpers' -and
        $authored.original_full_cdo_preserved -and $authored.original_graphs_unmodified -and $authored.original_entry_transport_nodes -eq 0 -and
        $authored.named_query_output -eq 'IsDeadOrDying' -and @($authored.implemented_methods).Count -eq 3 -and !$authored.death_listener_timer_restart_business_migrated}
    if($AutoRespawnListeners -and !$AutoRespawnEvents){$preserved=$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq 'autorespawnlisteners' -and
        $authored.original_full_cdo_preserved -and $authored.original_graphs_unmodified -and $authored.original_entry_transport_nodes -eq 0 -and
        $authored.named_query_output -eq 'IsDeadOrDying' -and @($authored.implemented_methods).Count -eq 5 -and
        $authored.death_listener_orchestration_migrated -and $authored.typed_listener_transport_nodes -eq 16 -and
        @($authored.typed_listener_transports).Count -eq 4 -and !$authored.death_listener_timer_restart_business_migrated}
    if($AutoRespawnEvents -and !$AutoRespawnActivation){$preserved=$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq 'autorespawnevents' -and
        $authored.original_full_cdo_preserved -and !$authored.original_graphs_unmodified -and $authored.original_business_graphs_preserved_with_dispatch -and
        @($authored.implemented_methods).Count -eq 9 -and $authored.death_listener_timer_restart_business_migrated -and
        $authored.event_transport.native_delay_nodes_reused -eq 2 -and $authored.event_transport.continuation_dispatch_nodes -eq 4 -and
        $authored.event_transport.native_entry_nodes -eq 2 -and $authored.event_transport.gate_function_nodes -eq 4 -and
        @($authored.event_transport.dispatch_transport_endpoints).Count -eq 4 -and $authored.typed_listener_transport_nodes -eq 16}
    if($AutoRespawnActivation){$preserved=$authored.original_class_defaults_signature_graphs_preserved -and $authored.kind -eq 'autorespawnactivation' -and
        $authored.original_full_cdo_preserved -and $authored.original_business_graphs_preserved_with_dispatch -and
        @($authored.implemented_methods).Count -eq 16 -and $authored.activation_reset_ui_removal_business_migrated -and
        $authored.activation_transport.native_listener_node_reused -and $authored.activation_transport.native_parent_end_forwarding_preserved -and
        @($authored.activation_transport.dispatch_transport_endpoints).Count -eq 10 -and $authored.event_transport.native_delay_nodes_reused -eq 2}
    if(!$preserved){throw 'Original native ability signature/default/graph proof missing'}
    foreach($entry in $authored.reference_hashes.PSObject.Properties){
        if((Get-FileHash -LiteralPath $entry.Name).Hash -ne $entry.Value){throw 'Official reference changed'}
        Add-JumpInput $entry.Name
    }
    Add-JumpInput $assetReport
    if($DashSelector){
        $dashRoot=[IO.Path]::GetFullPath($DashSelectorAuthoringDirectory)
        if(!$dashRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Dash proof must be workspace-owned'}
        $dashSummary=Join-Path $dashRoot 'summary.json';$dashReport=Join-Path $dashRoot 'assets.json'
        $dashAuthor=Get-Content -LiteralPath $dashSummary -Raw|ConvertFrom-Json -Depth 80
        $dashProof=Get-Content -LiteralPath $dashReport -Raw|ConvertFrom-Json -Depth 80
        if($dashAuthor.status -ne 'passed' -or $dashProof.status -ne 'passed' -or $dashProof.kind -ne 'dashselector' -or
            !$dashProof.original_full_cdo_preserved -or !$dashProof.original_graphs_unmodified -or !$dashProof.native_register_restore_passed -or
            $dashProof.new_business_nodes -ne 0 -or $dashProof.actual_registered_profile_method_counts.Python -ne 1 -or
            $dashProof.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or @($dashAuthor.assets).Count -ne 2 -or
            !$dashProof.inherited_declaration_probe.restored -or !$dashProof.inherited_declaration_probe.ordinary_inherited_sibling_rejected -or
            !$dashProof.inherited_declaration_probe.owned_shared_function_verified -or !$dashProof.inherited_declaration_probe.inherited_original_unwrapped -or
            !$dashProof.inherited_declaration_probe.lexical_init_teardown_verified){throw 'Dash declaration/original inheritance proof incomplete'}
        $currentDashAssets=@($dashAuthor.assets)
        if($DashRPCInputAuthoringDirectory){
            $revisionRoot=[IO.Path]::GetFullPath($DashRPCInputAuthoringDirectory)
            if(!$revisionRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Dash revision must be workspace-owned'}
            . (Join-Path $PSScriptRoot 'UEPDashAssetProvenance.ps1')
            if($DashLocalDirectionAuthoringDirectory){
                $localRoot=[IO.Path]::GetFullPath($DashLocalDirectionAuthoringDirectory)
                if(!$localRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Local direction proof must be workspace-owned'}
                $revision=Get-UEPDashLocalDirectionRevision $dashRoot $revisionRoot $localRoot
            }else{$revision=Get-UEPDashRPCInputRevision $dashRoot $revisionRoot}
            $currentDashAssets=@($revision.assets)
            foreach($file in $revision.evidence){Add-JumpInput $file}
            Add-JumpInput (Join-Path $PSScriptRoot 'UEPDashAssetProvenance.ps1')
        }
        foreach($asset in $currentDashAssets){
            if((Get-FileHash -LiteralPath $asset.stage).Hash -ne $asset.sha256 -or (Get-FileHash -LiteralPath $asset.overlay).Hash -ne $asset.sha256){throw 'Dash authored asset changed'}
            Add-JumpInput $asset.stage;Add-JumpInput $asset.overlay
        }
        $private=@($dashProof.caller_probe)+@($dashProof.inherited_declaration_probe.assets)
        foreach($item in $private){$path=if($item.PSObject.Properties['asset']){$item.asset}else{$item.path};if((Get-FileHash -LiteralPath $path).Hash -ne $item.sha256){throw 'Dash private probe changed'};Add-JumpInput $path}
        foreach($entry in $dashProof.reference_hashes.PSObject.Properties){if((Get-FileHash -LiteralPath $entry.Name).Hash -ne $entry.Value){throw 'Official Dash changed'};Add-JumpInput $entry.Name}
        Add-JumpInput $dashSummary;Add-JumpInput $dashReport
    }
    if($CharacterInventory -or $CharacterAudio -or $CharacterQuickbar -or $CharacterLoadout -or $CharacterOutline -or $CharacterTeam -or $CharacterStencil -or $CharacterLifecycle -or $CharacterParts -or $CharacterHealth -or $CharacterInput -or $CharacterObserver){
        $characterRoot=[IO.Path]::GetFullPath($CharacterAuthoringDirectory)
        if(!$characterRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Character evidence must stay in workspace build directory'}
        $characterSummary=Join-Path $characterRoot 'summary.json';$characterReport=Join-Path $characterRoot 'assets.json'
        $proof=Get-Content -LiteralPath $characterReport -Raw|ConvertFrom-Json -Depth 90
        $other=Get-Content -LiteralPath $characterSummary -Raw|ConvertFrom-Json -Depth 90
        $expectedCharacterKind=if($CharacterDeathStarted){'characterdeathstarted'}elseif($CharacterRagdoll){'characterragdoll'}elseif($CharacterEquipmentHide){'characterequipmenthide'}elseif($CharacterBeginPlay){'characterbeginplay'}elseif($CharacterVisibility){'charactervisibility'}elseif($CharacterPossessed){'characterpossessed'}elseif($CharacterWait){'characterwait'}elseif($CharacterReady){'characterready'}elseif($CharacterLegacy){'characterlegacy'}elseif($CharacterListener){'characterlistener'}elseif($CharacterObserver){'characterobserver'}elseif($CharacterInput){'characterinput'}elseif($CharacterHealth){'characterhealth'}elseif($CharacterParts){'characterparts'}elseif($CharacterLifecycle){'characterlifecycle'}elseif($CharacterStencil){'characterstencil'}elseif($CharacterTeam){'characterteam'}elseif($CharacterOutline){'characteroutline'}elseif($CharacterLoadout){'characterloadout'}elseif($CharacterQuickbar){'characterquickbar'}elseif($CharacterAudio){'characteraudio'}else{'characterinventory'}
        $expectedCharacterMethods=if($CharacterDeathStarted){30}elseif($CharacterRagdoll){28}elseif($CharacterEquipmentHide){27}elseif($CharacterBeginPlay){26}elseif($CharacterVisibility){25}elseif($CharacterPossessed){23}elseif($CharacterWait){22}elseif($CharacterReady){21}elseif($CharacterLegacy){20}elseif($CharacterListener){19}elseif($CharacterObserver){18}elseif($CharacterInput){17}elseif($CharacterHealth){12}elseif($CharacterParts){11}elseif($CharacterLifecycle){10}elseif($CharacterStencil){8}elseif($CharacterTeam){7}elseif($CharacterOutline){6}elseif($CharacterLoadout){5}elseif($CharacterQuickbar){4}elseif($CharacterAudio){3}else{1}
        if($other.status -ne 'passed' -or $proof.status -ne 'passed' -or $proof.kind -ne $expectedCharacterKind -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or @($other.assets).Count -ne 2 -or
            @($proof.implemented_methods).Count -ne $expectedCharacterMethods -or $proof.implemented_methods[0] -ne 'ClearInventory'){throw 'Character helper authoring proof incomplete'}
        foreach($asset in $other.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Character authored asset changed'}
            Add-JumpInput $path
        }}
        foreach($path in @($characterSummary,$characterReport,'F:/LyraStarterGame/Source/LyraGame/Character/LyraCharacter.cpp',
            'F:/LyraStarterGame/Source/LyraGame/Equipment/LyraQuickBarComponent.cpp','F:/LyraStarterGame/Source/LyraGame/Inventory/LyraInventoryManagerComponent.cpp',
            (Join-Path $EngineRoot 'Engine/Source/Runtime/Engine/Classes/GameFramework/Actor.h'))){Add-JumpInput $path}
        if($CharacterParts -or $CharacterHealth -or $CharacterInput -or $CharacterObserver){
            if(!$proof.native_component_receiver_register_restore_passed -or @($proof.extra_signatures.PSObject.Properties).Count -ne $(if($CharacterDeathStarted){28}elseif($CharacterRagdoll){26}elseif($CharacterEquipmentHide){25}elseif($CharacterVisibility){24}elseif($CharacterWait){23}else{($expectedCharacterMethods+$(if($CharacterListener){2}elseif($CharacterObserver){3}else{2}))}) -or
                $proof.actual_native_registered_profile_method_counts.Python -ne $expectedCharacterMethods -or
                $proof.actual_native_registered_profile_method_counts.BlueprintFallback -ne $(if($CharacterDeathStarted){25}elseif($CharacterRagdoll){23}elseif($CharacterEquipmentHide){22}elseif($CharacterBeginPlay){21}elseif($CharacterVisibility){20}elseif($CharacterPossessed){18}elseif($CharacterWait){17}elseif($CharacterReady){16}elseif($CharacterLegacy){15}elseif($CharacterListener){14}elseif($CharacterObserver){13}elseif($CharacterInput){12}else{$expectedCharacterMethods}) -or
                @($proof.native_parts_signatures.PSObject.Properties).Count -ne 3){throw 'Character component-bound receiver actual native registration proof incomplete'}
            foreach($file in @('F:/LyraStarterGame/Source/LyraGame/Cosmetics/LyraPawnComponent_CharacterParts.cpp',
                'F:/LyraStarterGame/Source/LyraGame/Cosmetics/LyraPawnComponent_CharacterParts.h',
                'F:/LyraStarterGame/Source/LyraGame/Cosmetics/LyraCharacterPartTypes.h')){Add-JumpInput $file}
        }
        if($CharacterHealth -or $CharacterInput -or $CharacterObserver){
            if(@($proof.native_health_signatures.PSObject.Properties).Count -ne 3){throw 'Character health native perception signature proof incomplete'}
            foreach($file in @('F:/LyraStarterGame/Source/LyraGame/Character/LyraHealthComponent.cpp',
                'F:/LyraStarterGame/Source/LyraGame/Character/LyraHealthComponent.h',
                'F:/LyraStarterGame/Source/LyraGame/AbilitySystem/Attributes/LyraHealthSet.cpp',
                (Join-Path $EngineRoot 'Engine/Source/Runtime/AIModule/Private/Perception/AISense_Damage.cpp'),
                (Join-Path $EngineRoot 'Engine/Source/Runtime/AIModule/Private/Perception/AIPerceptionComponent.cpp'))){Add-JumpInput $file}
        }
        if($CharacterInput -or $CharacterObserver){
            if(!$proof.original_enhanced_input_binding_semantics_preserved -or !$proof.compiler_receiver_names_resolved_dynamically -or !$proof.automatic_native_original_input_fallback -or @($proof.enhanced_input_bindings).Count -ne 5 -or
                @($proof.native_input_signatures.PSObject.Properties).Count -ne 2){throw 'Character original native input binding table proof incomplete'}
            foreach($binding in $proof.enhanced_input_bindings){
                $name=($binding.action -split '\.')[-1]
                foreach($base in @($stage,'F:/LyraStarterGame')){Add-JumpInput (Join-Path $base "Plugins/GameFeatures/ShooterCore/Content/Input/Actions/$name.uasset")}
            }
            foreach($relative in @('Engine/Plugins/EnhancedInput/Source/EnhancedInput/Private/EnhancedInputSubsystemInterface.cpp',
                'Engine/Plugins/EnhancedInput/Source/EnhancedInput/Private/EnhancedInputActionDelegateBinding.cpp')){Add-JumpInput (Join-Path $EngineRoot $relative)}
        }
        if($CharacterObserver){
            $probe=$proof.team_listener_probe
            if($proof.original_listener_factory_orchestration_remains_bp -ne (!$CharacterListener) -or @($proof.native_team_observer_signatures.PSObject.Properties).Count -ne 3 -or
                !$probe.stage_only -or $probe.gameplay_business -or !$probe.typed_actor_reference -or !$probe.virtual_bp_function_call -or $probe.nodes -ne 3 -or
                $probe.target -ne 'ListenForTeam' -or [IO.Path]::GetFullPath($probe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterTeamListenProbe.uasset') -or
                (Get-FileHash -LiteralPath $probe.asset).Hash -ne $probe.sha256){throw 'Character original native observer factory/typed BP caller proof incomplete'}
            Add-JumpInput $probe.asset
            if($CharacterLegacy){
                $legacyProbe=$proof.legacy_player_info_probe
                if(!$legacyProbe.stage_only -or $legacyProbe.gameplay_business -or !$legacyProbe.typed_actor_reference -or !$legacyProbe.virtual_bp_function_call -or
                    $legacyProbe.nodes -ne 3 -or $legacyProbe.target -ne 'OnRep_PlayerInfo' -or $legacyProbe.real_repnotify_ingress -or
                    [IO.Path]::GetFullPath($legacyProbe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterLegacyPlayerInfoProbe.uasset') -or
                    (Get-FileHash -LiteralPath $legacyProbe.asset).Hash -ne $legacyProbe.sha256 -or $proof.legacy_player_info_literal_defaults.team_id -ne 0 -or
                    $null -ne $proof.legacy_player_info_literal_defaults.display_asset){throw 'Character legacy typed caller/literal defaults proof incomplete'}
                Add-JumpInput $legacyProbe.asset
            }
            if($CharacterReady){
                $readyProbe=$proof.inventory_ready_probe
                if(!$proof.inventory_ready_immediate_branch_migrated -or $proof.inventory_ready_pending_wait_migrated -ne [bool]$CharacterWait -or !$proof.original_inventory_readiness_macro_retained -or
                    !$readyProbe.stage_only -or $readyProbe.gameplay_business -or !$readyProbe.typed_actor_reference -or !$readyProbe.virtual_bp_function_call -or $readyProbe.nodes -ne 5 -or
                    !$readyProbe.actual_native_experience_factory -or $readyProbe.callback_directly_invoked -or $proof.native_inventory_ready_transport.nodes -ne 4 -or $proof.native_inventory_ready_transport.gameplay_business -or
                    $proof.native_inventory_ready_transport.callback -ne $proof.inventory_ready_receiver -or
                    $readyProbe.target -ne $proof.inventory_ready_receiver -or [IO.Path]::GetFullPath($readyProbe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterInventoryReadyProbe.uasset') -or
                    (Get-FileHash -LiteralPath $readyProbe.asset).Hash -ne $readyProbe.sha256){throw 'Character immediate readiness/deferred original/typed caller proof incomplete'}
                Add-JumpInput $readyProbe.asset
                foreach($file in @('F:/LyraStarterGame/Source/LyraGame/GameModes/AsyncAction_ExperienceReady.cpp','F:/LyraStarterGame/Source/LyraGame/GameModes/AsyncAction_ExperienceReady.h')){Add-JumpInput $file}
                if($CharacterWait){
                    $stub=$proof.native_inventory_wait_stub;$signature=$proof.native_inventory_wait_resume_signature
                    if($stub.nodes -ne 2 -or $stub.gameplay_business -or !$stub.native_latent_resume_target -or $stub.parameter_type -ne 'int32' -or
                        @($signature.parameters).Count -ne 1 -or $signature.parameters[0].name -ne 'Linkage' -or $signature.parameters[0].type -ne 'int32' -or
                        $signature.parameters[0].output -or @($proof.native_inventory_wait_signatures.PSObject.Properties).Count -ne 2){throw 'Character native int-linkage resumption proof incomplete'}
                    foreach($relative in @('Engine/Source/Runtime/Engine/Classes/Engine/LatentActionManager.h','Engine/Source/Runtime/Engine/Public/DelayAction.h',
                        'Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Private/GameplayCueNotify_Actor.cpp',
                        'Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Public/GameplayCueNotify_Actor.h')){Add-JumpInput (Join-Path $EngineRoot $relative)}
                    $cueRelative='Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_Spawning.uasset'
                    $cueOriginal=Join-Path 'F:/LyraStarterGame' $cueRelative;$cueStaged=Join-Path $stage $cueRelative
                    if((Get-FileHash -LiteralPath $cueOriginal).Hash -ne (Get-FileHash -LiteralPath $cueStaged).Hash){throw 'Retained original spawning Cue changed'}
                    Add-JumpInput $cueOriginal;Add-JumpInput $cueStaged
                }
                if($CharacterPossessed){
                    Add-JumpInput (Join-Path $EngineRoot 'Engine/Content/EditorBlueprintResources/ActorMacros.uasset')
                    if(!$proof.experience_ready_factory_migrated -or !$proof.original_possession_semantics.remote_branch_noop -or
                        !$proof.original_possession_semantics.controller_parameter_unused -or !$proof.original_possession_semantics.implicit_self_world_context -or
                        $proof.original_possession_semantics.parent_event_called -or @($proof.native_possession_factory_signatures.PSObject.Properties).Count -ne 3){throw 'Character native possession factory/authority proof incomplete'}
                    foreach($relative in @('Engine/Source/Runtime/Engine/Private/Controller.cpp','Engine/Source/Runtime/Engine/Private/Pawn.cpp',
                        'Engine/Source/Runtime/Engine/Private/GameModeBase.cpp')){Add-JumpInput (Join-Path $EngineRoot $relative)}
                    foreach($path in @('F:/LyraStarterGame/Source/LyraGame/GameModes/LyraGameMode.cpp','F:/LyraStarterGame/Source/LyraGame/Player/LyraPlayerBotController.cpp',
                        'F:/LyraStarterGame/Source/LyraGame/GameModes/LyraBotCreationComponent.cpp')){Add-JumpInput $path}
                }
                if($CharacterVisibility){
                    if(!$proof.visibility_callback_business_migrated -or !$proof.original_visibility_semantics.payload_ignored -or
                        $proof.original_visibility_semantics.hidden_after_resume -or $proof.original_visibility_semantics.whole_begin_play_migrated -or
                        $proof.native_visibility_resume_stub.nodes -ne 2 -or $proof.native_visibility_resume_stub.gameplay_business -or
                        $proof.native_visibility_registration_transport.nodes -ne 4 -or $proof.native_visibility_registration_transport.gameplay_business -or
                        $proof.native_visibility_registration_transport.python_callback_retained -or @($proof.native_visibility_signatures.PSObject.Properties).Count -ne 2 -or
                        @($proof.native_visibility_resume_signature.parameters).Count -ne 1 -or $proof.native_visibility_resume_signature.parameters[0].type -ne 'int32'){
                        throw 'Character native InitState/visibility proof incomplete'
                    }
                    foreach($relative in @('Engine/Plugins/Runtime/ModularGameplay/Source/ModularGameplay/Private/Components/GameFrameworkInitStateInterface.cpp',
                        'Engine/Plugins/Runtime/ModularGameplay/Source/ModularGameplay/Private/Components/GameFrameworkComponentManager.cpp',
                        'Engine/Plugins/Runtime/ModularGameplay/Source/ModularGameplay/Public/Components/GameFrameworkComponentDelegates.h',
                        'Engine/Plugins/Runtime/ModularGameplay/Source/ModularGameplay/Public/Components/GameFrameworkInitStateInterface.h')){Add-JumpInput (Join-Path $EngineRoot $relative)}
                    Add-JumpInput 'F:/LyraStarterGame/Source/LyraGame/Character/LyraPawnExtensionComponent.cpp'
                }
                if($CharacterBeginPlay){
                    if(!$proof.begin_play_business_migrated -or $proof.native_begin_play_parent_transport.nodes -ne 2 -or
                        $proof.native_begin_play_parent_transport.gameplay_business -or $proof.native_begin_play_parent_transport.replay_current_actor_begin_play -or
                        ($proof.original_begin_play_semantics.order -join ',') -ne 'parent,listen,hide,register' -or !$proof.original_begin_play_semantics.call_immediately){
                        throw 'Character natural BeginPlay ordered parent/listener/registration proof incomplete'
                    }
                    foreach($relative in @('Engine/Source/Editor/BlueprintGraph/Private/K2Node_CallParentFunction.cpp',
                        'Engine/Source/Runtime/Engine/Private/Actor.cpp')){Add-JumpInput (Join-Path $EngineRoot $relative)}
                    Add-JumpInput 'F:/LyraStarterGame/Content/Characters/Character_Default.uasset'
                    Add-JumpInput (Join-Path $stage 'Content/Characters/Character_Default.uasset')
                }
                if($CharacterEquipmentHide){
                    $hideProbe=$proof.equipment_hide_probe
                    if(!$proof.inherited_equipment_hide_migrated -or $proof.inherited_equipment_hide_owner -ne '/Game/Characters/Heroes/B_Hero_Default.B_Hero_Default_C' -or
                        !$hideProbe.stage_only -or $hideProbe.gameplay_business -or $hideProbe.nodes -ne 3 -or !$hideProbe.typed_actor_reference -or !$hideProbe.virtual_bp_function_call -or
                        @($proof.native_equipment_hide_signatures.PSObject.Properties).Count -ne 3 -or
                        [IO.Path]::GetFullPath($hideProbe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterEquipmentHideProbe.uasset') -or
                        (Get-FileHash -LiteralPath $hideProbe.asset).Hash -ne $hideProbe.sha256){throw 'Character inherited equipment-hide actual owner/native caller proof incomplete'}
                    Add-JumpInput $hideProbe.asset
                    foreach($file in @('F:/LyraStarterGame/Source/LyraGame/Equipment/LyraEquipmentInstance.cpp',
                        'F:/LyraStarterGame/Source/LyraGame/Equipment/LyraEquipmentManagerComponent.cpp')){Add-JumpInput $file}
                }
                if($CharacterRagdoll){
                    $ragdollProbe=$proof.ragdoll_probe
                    if(!$proof.ragdoll_orchestration_migrated -or $proof.native_physics_or_animation_implementation_changed -or
                        $proof.ragdoll_original_owner -ne '/Game/Characters/Heroes/B_Hero_Default.B_Hero_Default_C' -or
                        $proof.original_ragdoll_semantics.nodes -ne 14 -or ($proof.original_ragdoll_semantics.order -join ',') -ne 'collision,simulation,impulse' -or
                        !$ragdollProbe.stage_only -or $ragdollProbe.gameplay_business -or $ragdollProbe.nodes -ne 3 -or !$ragdollProbe.typed_actor_reference -or !$ragdollProbe.virtual_bp_function_call -or
                        @($proof.native_ragdoll_signatures.PSObject.Properties).Count -ne 7 -or
                        [IO.Path]::GetFullPath($ragdollProbe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterRagdollProbe.uasset') -or
                        (Get-FileHash -LiteralPath $ragdollProbe.asset).Hash -ne $ragdollProbe.sha256){throw 'Character inherited Ragdoll native caller/graph proof incomplete'}
                    Add-JumpInput $ragdollProbe.asset
                    $physicsFixture=$proof.ragdoll_physics_fixture
                    if(!$physicsFixture.stage_only -or $physicsFixture.gameplay_business -or !$physicsFixture.original_assets_unmodified -or !$physicsFixture.fixture_owned_body -or
                        $physicsFixture.bodies -ne 1 -or $physicsFixture.constraints -ne 0 -or
                        [IO.Path]::GetFullPath($physicsFixture.asset) -ne (Join-Path $stage 'Content/UEPValidation/PA_CharacterRagdollProbe.uasset') -or
                        (Get-FileHash -LiteralPath $physicsFixture.asset).Hash -ne $physicsFixture.sha256){throw 'Quantitative Ragdoll physics control is not the immutable owned single-body fixture'}
                    Add-JumpInput $physicsFixture.asset
                    foreach($entry in $physicsFixture.source_hashes.PSObject.Properties){
                        if((Get-FileHash -LiteralPath $entry.Name).Hash -ne $entry.Value){throw 'Original native physics asset changed'}
                        Add-JumpInput $entry.Name
                    }
                    Add-JumpInput (Join-Path $EngineRoot 'Engine/Source/Runtime/PhysicsCore/Private/ChaosEngineInterface.cpp')
                    foreach($relative in @('Engine/Source/Runtime/Engine/Private/PrimitiveComponentPhysics.cpp','Engine/Source/Runtime/Engine/Private/SkeletalMeshComponentPhysics.cpp',
                        'Engine/Source/Runtime/Engine/Private/PhysicsEngine/BodyInstance.cpp','Engine/Source/Runtime/Engine/Classes/Components/PrimitiveComponent.h',
                        'Engine/Source/Runtime/Engine/Classes/Components/SkeletalMeshComponent.h')){Add-JumpInput (Join-Path $EngineRoot $relative)}
                }
                if($CharacterDeathStarted){
                    if(!$proof.death_started_business_migrated -or $proof.death_started_original_owner -ne '/Game/Characters/Heroes/B_Hero_Default.B_Hero_Default_C' -or
                        $proof.original_death_started_semantics.reachable_nodes -ne 14 -or !$proof.original_death_started_semantics.payload_ignored -or
                        !$proof.original_death_started_semantics.empty_death_endpoint_retained -or $proof.original_death_started_semantics.native_backend -ne 'Delay' -or
                        ($proof.original_death_started_semantics.order -join ',') -ne 'montage,sight,delay,ragdoll,hide,death' -or
                        $proof.native_death_resume_stub.nodes -ne 2 -or $proof.native_death_resume_stub.gameplay_business -or
                        !$proof.native_death_resume_stub.native_latent_resume_target -or $proof.native_death_resume_stub.parameter_type -ne 'int32' -or
                        @($proof.native_death_started_signatures.PSObject.Properties).Count -ne 5){throw 'Inherited Character death-started native receiver/continuation proof incomplete'}
                    foreach($relative in @('Engine/Source/Runtime/AIModule/Private/Perception/AIPerceptionStimuliSourceComponent.cpp',
                        'Engine/Source/Runtime/Core/Public/UObject/ScriptDelegates.h',
                        'Engine/Source/Runtime/Engine/Public/DelayAction.h')){Add-JumpInput (Join-Path $EngineRoot $relative)}
                    Add-JumpInput 'F:/LyraStarterGame/Source/LyraGame/Character/LyraHealthComponent.cpp'
                }
                foreach($relative in @('Engine/Source/Runtime/Engine/Private/LatentActionManager.cpp','Engine/Source/Runtime/Engine/Private/KismetSystemLibrary.cpp')){Add-JumpInput (Join-Path $EngineRoot $relative)}
            }
            if($CharacterListener -and ($proof.native_team_listener_transport.nodes -ne 4 -or $proof.native_team_listener_transport.gameplay_business -or
                $proof.native_team_listener_transport.python_callback_retained -or $proof.native_team_listener_transport.operation -ne 'add_unique' -or
                $proof.native_team_listener_transport.callback -ne $proof.team_observer_callback)){throw 'Character named native listener transport proof incomplete'}
            foreach($path in @('F:/LyraStarterGame/Source/LyraGame/Teams/AsyncAction_ObserveTeamColors.cpp',
                'F:/LyraStarterGame/Source/LyraGame/Teams/AsyncAction_ObserveTeamColors.h',
                (Join-Path $EngineRoot 'Engine/Source/Runtime/Engine/Private/Engine/CancellableAsyncAction.cpp'))){Add-JumpInput $path}
        }
        if($CharacterTeam -or $CharacterStencil -or $CharacterLifecycle -or $CharacterParts -or $CharacterHealth -or $CharacterInput -or $CharacterObserver){
            $probe=$proof.caller_probe
            if($CharacterStencil -or $CharacterLifecycle -or $CharacterParts -or $CharacterHealth -or $CharacterInput -or $CharacterObserver){
                if(!$probe.stage_only -or $probe.gameplay_business -or !$probe.typed_actor_reference -or !$probe.virtual_bp_function_call -or
                    $probe.nodes -ne 3 -or $probe.target -ne 'UpdateCustomStencilFromTeamID' -or !$proof.inherited_parent_asset_unmodified -or
                    [IO.Path]::GetFullPath($probe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterStencilCallProbe.uasset') -or
                    (Get-FileHash -LiteralPath $probe.asset).Hash -ne $probe.sha256 -or
                    [IO.Path]::GetFullPath($proof.team_caller_probe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterTeamCallProbe.uasset') -or
                    (Get-FileHash -LiteralPath $proof.team_caller_probe.asset).Hash -ne $proof.team_caller_probe.sha256){throw 'Inherited stencil parent/typed caller proof incomplete'}
                Add-JumpInput $proof.team_caller_probe.asset
                foreach($file in @('F:/LyraStarterGame/Source/LyraGame/System/LyraSystemStatics.cpp',
                    (Join-Path $EngineRoot 'Engine/Source/Runtime/Engine/Private/Components/PrimitiveComponent.cpp'),
                    (Join-Path $EngineRoot 'Engine/Source/Runtime/Engine/Private/GameFramework/InputDevicePropertyHandle.cpp'),
                    (Join-Path $EngineRoot 'Engine/Source/Runtime/Engine/Classes/GameFramework/InputDevicePropertyHandle.h'),
                    (Join-Path $EngineRoot 'Engine/Source/Runtime/Engine/Private/GameFramework/InputDeviceProperties.cpp'))){Add-JumpInput $file}
            }elseif(!$probe.stage_only -or $probe.gameplay_business -or !$probe.typed_actor_reference -or !$probe.virtual_bp_function_call -or
                $probe.nodes -ne 3 -or $probe.target -ne 'OnTeamOrCosmeticsChanged' -or @($probe.original_parameters).Count -ne 2 -or
                @($proof.native_team_signatures.PSObject.Properties).Count -ne 3 -or
                [IO.Path]::GetFullPath($probe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterTeamCallProbe.uasset') -or
                (Get-FileHash -LiteralPath $probe.asset).Hash -ne $probe.sha256){throw 'Character team original typed parameters/native APIs proof incomplete'}
            Add-JumpInput $probe.asset
            foreach($file in @('F:/LyraStarterGame/Source/LyraGame/Teams/LyraTeamDisplayAsset.cpp',
                'F:/LyraStarterGame/Source/LyraGame/Teams/LyraTeamStatics.cpp',
                (Join-Path $EngineRoot 'Engine/Source/Runtime/Engine/Private/GameFramework/InputDeviceSubsystem.cpp'),
                (Join-Path $EngineRoot 'Engine/Source/Runtime/Engine/Classes/GameFramework/InputDeviceSubsystem.h'))){Add-JumpInput $file}
            $stencilOriginal='F:/LyraStarterGame/Content/Characters/Heroes/B_Hero_Default.uasset'
            $stencilStaged=Join-Path $stage 'Content/Characters/Heroes/B_Hero_Default.uasset'
            if((Get-FileHash -LiteralPath $stencilOriginal).Hash -ne (Get-FileHash -LiteralPath $stencilStaged).Hash){throw 'Original inherited stencil parent changed'}
            Add-JumpInput $stencilOriginal;Add-JumpInput $stencilStaged
        }
        if($CharacterOutline){
            $probe=$proof.caller_probe
            if(!$probe.stage_only -or $probe.gameplay_business -or !$probe.typed_actor_reference -or !$probe.virtual_bp_function_call -or
                $probe.nodes -ne 3 -or $probe.target -ne 'CreateOrUpdateOutlineIfNeeded' -or !$proof.native_camera_interface_signature -or
                [IO.Path]::GetFullPath($probe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterOutlineCallProbe.uasset') -or
                (Get-FileHash -LiteralPath $probe.asset).Hash -ne $probe.sha256){throw 'Character outline native BP/camera Interface proof incomplete'}
            Add-JumpInput $probe.asset
            $outlineMaterial='Content/Effects/Materials/PostProcess/MPP_Outline_Inst.uasset'
            $outlineOriginal=Join-Path 'F:/LyraStarterGame' $outlineMaterial
            $outlineStaged=Join-Path $stage $outlineMaterial
            if((Get-FileHash -LiteralPath $outlineOriginal).Hash -ne (Get-FileHash -LiteralPath $outlineStaged).Hash){throw 'Original outline parent material changed'}
            Add-JumpInput $outlineOriginal;Add-JumpInput $outlineStaged
        }
        if($CharacterLoadout){
            $probe=$proof.caller_probe
            if(!$probe.stage_only -or $probe.gameplay_business -or !$probe.typed_actor_reference -or !$probe.virtual_bp_function_call -or
                $probe.nodes -ne 3 -or $probe.target -ne 'AddInitialInventory' -or
                [IO.Path]::GetFullPath($probe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterLoadoutCallProbe.uasset') -or
                (Get-FileHash -LiteralPath $probe.asset).Hash -ne $probe.sha256){throw 'Character loadout second BP caller proof incomplete'}
            Add-JumpInput $probe.asset
        }
        if($CharacterQuickbar){
            $probe=$proof.caller_probe
            if(!$probe.stage_only -or $probe.gameplay_business -or !$probe.typed_actor_reference -or !$probe.virtual_bp_function_call -or
                $probe.nodes -ne 3 -or $probe.target -ne 'ChangeQuickbarSlot' -or
                [IO.Path]::GetFullPath($probe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterQuickbarCallProbe.uasset') -or
                (Get-FileHash -LiteralPath $probe.asset).Hash -ne $probe.sha256){throw 'Character slot second BP caller proof incomplete'}
            Add-JumpInput $probe.asset
        }
        if($CharacterAudio){
            $probe=$proof.caller_probe
            if(!$probe.stage_only -or $probe.gameplay_business -or !$probe.original_animation_notify_unchanged -or @($probe.functions).Count -ne 2 -or
                [IO.Path]::GetFullPath($probe.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_CharacterAudioInterfaceProbe.uasset') -or
                (Get-FileHash -LiteralPath $probe.asset).Hash -ne $probe.sha256){throw 'Native Character BP Interface caller proof incomplete'}
            foreach($entry in $probe.reference_hashes.PSObject.Properties){
                if((Get-FileHash -LiteralPath $entry.Name).Hash -ne $entry.Value){throw 'Retained animation notify changed'}
                Add-JumpInput $entry.Name
            }
            Add-JumpInput $probe.asset
        }
    }
    if($AutoRespawnReset){
        $probeRoot=[IO.Path]::GetFullPath($ResetProbeAssetDirectory)
        if(!$probeRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Reset probe evidence must stay in workspace build directory'}
        $probeSummary=Join-Path $probeRoot 'summary.json';$probeReport=Join-Path $probeRoot 'assets.json'
        $proof=Get-Content -LiteralPath $probeReport -Raw|ConvertFrom-Json
        if((Get-Content -LiteralPath $probeSummary -Raw|ConvertFrom-Json).status -ne 'passed' -or $proof.status -ne 'passed' -or !$proof.stage_only -or
            !$proof.typed_vm_reader -or $proof.function -ne 'ReadReset' -or $proof.nodes -ne 4 -or $proof.gameplay_logic -or $proof.broadcast_graphs -ne 0 -or
            [IO.Path]::GetFullPath($proof.asset) -ne (Join-Path $stage 'Content/UEPValidation/BP_AutoRespawnResetProbe.uasset') -or
            (Get-FileHash -LiteralPath $proof.asset).Hash -ne $proof.sha256){throw 'Native typed Reset observer proof mismatch'}
        foreach($path in @($probeSummary,$probeReport,$proof.asset,'F:/LyraStarterGame/Source/LyraGame/AbilitySystem/Abilities/LyraGameplayAbility_Reset.cpp')){Add-JumpInput $path}
    }
    if($EquipmentIntegration -or $EquipmentDeath){
        $equipmentSummary=Join-Path $EquipmentAuthoringDirectory 'summary.json'
        $equipmentReport=Join-Path $EquipmentAuthoringDirectory 'assets.json'
        $other=Get-Content $equipmentSummary -Raw|ConvertFrom-Json -Depth 90
        $proof=Get-Content $equipmentReport -Raw|ConvertFrom-Json -Depth 90
        if($other.status -ne 'passed' -or $proof.kind -ne 'weaponinstance' -or !$proof.original_class_defaults_signature_graphs_preserved -or @($other.assets).Count -ne 2){throw 'Equipment Interface/CDO proof incomplete'}
        foreach($asset in $other.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Authored equipment asset changed'}
            Add-JumpInput $path
        }}
        Add-JumpInput $equipmentSummary;Add-JumpInput $equipmentReport
    }
    if($ReloadMagazine){
        foreach($relative in @('Content/Weapons/Pistol/GA_Weapon_Reload_Pistol.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/Weapons/Rifle/GA_Weapon_Reload_Rifle.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/Weapons/Shotgun/GA_Weapon_Reload_Shotgun.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/Weapons/Shotgun/GA_Weapon_Reload_NetShooter.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/Weapons/Pistol/ID_Pistol.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/Weapons/Rifle/ID_Rifle.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/Weapons/Shotgun/ID_Shotgun.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/Weapons/NetShooter_PROTO/ID_NetShooter.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/Weapons/NetShooter_PROTO/AbilitySet_ShooterNetShooter.uasset')){
            $original=Join-Path 'F:\LyraStarterGame' $relative;$staged=Join-Path $stage $relative
            if((Get-FileHash -LiteralPath $original).Hash -ne (Get-FileHash -LiteralPath $staged).Hash){throw 'Original weapon child asset changed'}
            Add-JumpInput $original;Add-JumpInput $staged
        }
    }
    if($Death){
        $damage='Content/GameplayEffects/Damage/GE_Damage_Basic_SetByCaller.uasset'
        $official=Join-Path 'F:\LyraStarterGame' $damage;$staged=Join-Path $stage $damage
        if((Get-FileHash -LiteralPath $official).Hash -ne (Get-FileHash -LiteralPath $staged).Hash){throw 'Native lethal GE differs from official reference'}
        Add-JumpInput $official;Add-JumpInput $staged
        if($Network){Add-JumpInput (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/validate_death_network_reports.py')}
    }
    if($SpawnEffect){
        Add-JumpInput (Join-Path $EngineRoot 'Engine/Plugins/Runtime/GameplayAbilities/Source/GameplayAbilities/Private/Abilities/GameplayAbility.cpp')
        $relative='Plugins/GameFeatures/ShooterCore/Content/Game/Respawn/GE_SpawnIn.uasset'
        $original=Join-Path 'F:/LyraStarterGame' $relative;$staged=Join-Path $stage $relative
        if((Get-FileHash -LiteralPath $original).Hash -ne (Get-FileHash -LiteralPath $staged).Hash){throw 'Original SpawnIn GE changed'}
        Add-JumpInput $original;Add-JumpInput $staged
    }
    if($WidgetHeld){
        Add-JumpInput (Join-Path $EngineRoot 'Engine/Plugins/EnhancedInput/Source/EnhancedInput/Private/EnhancedPlayerInput.cpp')
        Add-JumpInput 'F:/LyraStarterGame/Source/LyraGame/AbilitySystem/LyraAbilitySystemComponent.cpp'
    }
    # Freeze all existing Overlay assets, not just this batch's two BP classes.
    foreach($file in Get-ChildItem -LiteralPath $overlay -Recurse -File -Filter '*.uasset'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        if((Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){throw 'Overlay/stage asset parity mismatch'}
        Add-JumpInput $file.FullName;Add-JumpInput $target
    }
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),
        (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe'),(Join-Path $stage 'Binaries/Win64/UnrealEditor-LyraGame.dll'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'),
        (Join-Path $stage 'Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll'))){Add-JumpInput $path}
    $flag=if($ReloadMagazine){'-UEPReloadMagazineResult'}elseif($DropWeapon){'-UEPDropWeaponResult'}elseif($WidgetLifecycle){'-UEPAbilityWidgetResult'}elseif($ADS){'-UEPADSResult'}elseif($HeroHeal){'-UEPHeroHealResult'}elseif($AutoReload){'-UEPAutoReloadResult'}elseif($Cosmetics){'-UEPCosmeticResult'}elseif($Death){'-UEPDeathAbilityResult'}elseif($Quickslot){'-UEPQuickslotResult'}else{'-UEPJumpAbilityResult'}
    $marker=if($ReloadMagazine){'UEP_RELOAD_MAGAZINE'}elseif($DropWeapon){'UEP_DROP_WEAPON'}elseif($WidgetLifecycle){'UEP_ABILITY_WIDGET'}elseif($ADS){'UEP_ADS'}elseif($HeroHeal){'UEP_HERO_HEAL'}elseif($AutoReload){'UEP_AUTORELOAD'}elseif($Cosmetics){'UEP_COSMETIC'}elseif($Death){'UEP_DEATH_ABILITY'}elseif($Quickslot){'UEP_QUICKSLOT'}else{'UEP_JUMP_ABILITY'}
    if($WeaponInstance){$flag='-UEPWeaponInstanceResult';$marker='UEP_WEAPON_INSTANCE'}
    if($EquipmentDeath){$flag='-UEPWeaponInstanceDeathResult'}
    if($SpawnEffect){$flag='-UEPSpawnEffectResult';$marker='UEP_SPAWN_EFFECT'}
    if($DeviceColor){$flag='-UEPDeviceColorResult';$marker='UEP_DEVICE_COLOR'}
    if($Emote){$flag='-UEPEmoteResult';$marker='UEP_EMOTE'}
    if($WidgetHeld){$flag='-UEPWidgetHeldResult';$marker='UEP_WIDGET_HELD'}
    if($WidgetPressed){$flag='-UEPWidgetPressedResult';$marker='UEP_WIDGET_PRESSED'}
    if($AutoRespawnHelpers){$flag='-UEPAutoRespawnHelpersResult';$marker='UEP_AUTO_RESPAWN_HELPERS'}
    if($AutoRespawnLifecycle){$flag='-UEPAutoRespawnLifecycleResult';$marker='UEP_AUTO_RESPAWN_LIFECYCLE'}
    if($AutoRespawnReset){$flag='-UEPAutoRespawnResetResult';$marker='UEP_AUTO_RESPAWN_RESET'}
    if($CharacterAudio){$flag='-UEPCharacterAudioResult';$marker='UEP_CHARACTER_AUDIO'}
    if($CharacterQuickbar){$flag='-UEPCharacterQuickbarResult';$marker='UEP_CHARACTER_QUICKBAR'}
    if($CharacterLoadout){$flag='-UEPCharacterLoadoutResult';$marker='UEP_CHARACTER_LOADOUT'}
    if($CharacterOutline){$flag='-UEPCharacterOutlineResult';$marker='UEP_CHARACTER_OUTLINE'}
    if($CharacterTeam){$flag='-UEPCharacterTeamResult';$marker='UEP_CHARACTER_TEAM'}
    if($CharacterStencil){$flag='-UEPCharacterStencilResult';$marker='UEP_CHARACTER_STENCIL'}
    if($CharacterLifecycle){$flag=if($AutoRespawnReset){'-UEPCharacterLifecycleResetResult'}else{'-UEPCharacterLifecycleResult'}}
    if($CharacterParts){$flag='-UEPCharacterPartsResult';$marker='UEP_CHARACTER_PARTS'}
    if($CharacterHealth){$flag='-UEPCharacterHealthResult';$marker='UEP_CHARACTER_HEALTH'}
    if($CharacterInput){$flag='-UEPCharacterInputResult';$marker='UEP_CHARACTER_INPUT'}
    if($CharacterObserver){$flag='-UEPCharacterObserverResult';$marker='UEP_CHARACTER_OBSERVER'}
    if($CharacterListener){$flag='-UEPCharacterListenerResult';$marker='UEP_CHARACTER_LISTENER'}
    if($CharacterLegacy){$flag='-UEPCharacterLegacyResult';$marker='UEP_CHARACTER_LEGACY'}
    if($CharacterReady){$flag='-UEPCharacterReadyResult';$marker='UEP_CHARACTER_READY'}
    if($CharacterWait){$flag='-UEPCharacterWaitResult';$marker='UEP_CHARACTER_WAIT'}
    if($CharacterPossessed){$flag='-UEPCharacterPossessedResult';$marker='UEP_CHARACTER_POSSESSED'}
    if($CharacterVisibility){$flag='-UEPCharacterVisibilityResult';$marker='UEP_CHARACTER_VISIBILITY'}
    if($CharacterBeginPlay){$flag='-UEPCharacterBeginPlayResult';$marker='UEP_CHARACTER_BEGIN_PLAY'}
    if($CharacterEquipmentHide){$flag='-UEPCharacterEquipmentHideResult';$marker='UEP_CHARACTER_EQUIPMENT_HIDE'}
    if($CharacterRagdoll){$flag='-UEPCharacterRagdollResult';$marker='UEP_CHARACTER_RAGDOLL'}
    if($CharacterDeathStarted){$flag='-UEPCharacterDeathStartedResult';$marker='UEP_CHARACTER_DEATH_STARTED'}
    if($DashSelector){$flag='-UEPDashSelectorResult';$marker='UEP_DASH_SELECTOR'}
    if($DashLocalDirection){$flag='-UEPDashLocalDirectionResult';$marker='UEP_DASH_LOCAL_DIRECTION'}
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360',
        '-NoLoadingScreen','-ExecCmds=t.MaxFPS 60','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython','-NoDDCCleanup',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        "$flag=$output/jump.json","-abslog=$output/jump.log")
    if($ThreadedLoading){$arguments+=@('-AsyncLoadingThread')}
    if($AutoRespawnListeners){$arguments+=@('-UEPAutoRespawnListeners')}
    if($AutoRespawnEvents){$arguments+=@('-UEPAutoRespawnEvents')}
    if($AutoRespawnActivation){$arguments+=@('-UEPAutoRespawnActivation')}
    if($CharacterInventory){$arguments+=@('-UEPCharacterInventory')}
    if($CharacterLoadoutNatural){$arguments+=@('-UEPCharacterLoadoutNatural')}
    if($WidgetHeld){
        $arguments+=@("-UEPWidgetHeldTarget=$WidgetHeldMode")
        if($WidgetHeldMode -eq 'cp'){$arguments[1]='/ShooterMaps/Maps/L_Convolution_Blockout?Experience=B_LyraShooterGame_ControlPoints?NumBots=3'}
    }
    if($WidgetPressed){$arguments[1]='/ShooterExplorer/Maps/L_InventoryTestMap?Experience=B_TestInventoryExperience?NumBots=0'}
    if($EquipmentGC){$arguments+=@('-UEPWeaponInstanceGC')}
    if($EquipmentIntegration){$arguments+=@('-UEPWeaponInstanceIntegration')}
    if($EquipmentBlueprintFallback){$arguments+=@('-UEPEquipmentProfile=BlueprintFallback')}
    if($ReloadMagazine){$arguments+=@("-UEPReloadWeapon=$ReloadWeapon")}
    if($Network){
        $run=[guid]::NewGuid().ToString()
        foreach($peer in @('server','A','B0')){
            $peerArguments=@($arguments|Where-Object {$_ -ne '-game' -and $_ -notlike '-UEPSpawnEffectResult=*' -and $_ -notlike '-UEPReloadMagazineResult=*' -and $_ -notlike '-UEPDropWeaponResult=*' -and $_ -notlike '-UEPADSResult=*' -and $_ -notlike '-UEPHeroHealResult=*' -and $_ -notlike '-UEPAutoReloadResult=*' -and $_ -notlike '-UEPCosmeticResult=*' -and $_ -notlike '-UEPDeathAbilityResult=*' -and $_ -notlike '-UEPJumpAbilityResult=*' -and $_ -notlike '-UEPQuickslotResult=*' -and $_ -notlike '-abslog=*'})
            if($Emote){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPEmoteResult=*'})}
            if($WidgetHeld){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPWidgetHeldResult=*'})}
            if($WidgetPressed){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPWidgetPressedResult=*'})}
            if($AutoRespawnHelpers){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPAutoRespawnHelpersResult=*'})}
            if($AutoRespawnReset){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPAutoRespawnResetResult=*'})}
            if($CharacterAudio){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterAudioResult=*'})}
            if($CharacterQuickbar){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterQuickbarResult=*'})}
            if($CharacterLoadout){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterLoadoutResult=*'})}
            if($CharacterOutline){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterOutlineResult=*'})}
            if($CharacterTeam){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterTeamResult=*'})}
            if($CharacterStencil){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterStencilResult=*'})}
            if($CharacterLifecycle){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterLifecycleResult=*'})}
            if($CharacterParts){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterPartsResult=*'})}
            if($CharacterHealth){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterHealthResult=*'})}
            if($CharacterInput){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterInputResult=*'})}
            if($CharacterObserver){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterObserverResult=*'})}
            if($CharacterListener){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterListenerResult=*'})}
            if($CharacterLegacy){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterLegacyResult=*'})}
            if($CharacterReady){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterReadyResult=*'})}
            if($CharacterWait){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterWaitResult=*'})}
            if($CharacterPossessed){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterPossessedResult=*'})}
            if($CharacterVisibility){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterVisibilityResult=*'})}
            if($CharacterBeginPlay){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterBeginPlayResult=*'})}
            if($CharacterEquipmentHide){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterEquipmentHideResult=*'})}
            if($CharacterRagdoll){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterRagdollResult=*'})}
            if($CharacterDeathStarted){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPCharacterDeathStartedResult=*'})}
            if($DashSelector){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPDashSelectorResult=*'})}
            if($DashLocalDirection){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPDashLocalDirectionResult=*'})}
            if($peer -eq 'server'){
                $peerArguments=@($peerArguments|Where-Object {$_ -ne '-RenderOffscreen'})+@('-server','-NullRHI',"-port=$ServerPort",'-multihome=127.0.0.1')
            }else{
                $peerArguments[1]="127.0.0.1:$ServerPort"
                $peerArguments=@($peerArguments|Where-Object {$_ -notlike '-ExecCmds=*'})+@('-game',
                    '-ExecCmds=t.MaxFPS 30,sg.ShadowQuality 0,sg.GlobalIlluminationQuality 0,sg.ReflectionQuality 0,r.Streaming.PoolSize 256')
            }
            $resultFlag=if($ReloadMagazine){'-UEPReloadMagazineNetworkResult'}elseif($DropWeapon){'-UEPDropWeaponNetworkResult'}elseif($ADS){'-UEPADSNetworkResult'}elseif($HeroHeal){'-UEPHeroHealNetworkResult'}elseif($AutoReload){'-UEPAutoReloadNetworkResult'}elseif($Cosmetics){'-UEPCosmeticNetworkResult'}elseif($Death){'-UEPDeathNetworkResult'}elseif($Quickslot){'-UEPQuickslotNetworkResult'}else{'-UEPJumpNetworkResult'}
            if($SpawnEffect){$resultFlag='-UEPSpawnEffectNetworkResult'}
            if($Emote){$resultFlag='-UEPEmoteNetworkResult'}
            if($WidgetHeld){$resultFlag='-UEPWidgetHeldNetworkResult'}
            if($WidgetPressed){$resultFlag='-UEPWidgetPressedNetworkResult'}
            if($AutoRespawnHelpers){$resultFlag='-UEPAutoRespawnHelpersNetworkResult'}
            if($AutoRespawnReset){$resultFlag='-UEPAutoRespawnResetNetworkResult'}
            if($CharacterAudio){$resultFlag='-UEPCharacterAudioNetworkResult'}
            if($CharacterQuickbar){$resultFlag='-UEPCharacterQuickbarNetworkResult'}
            if($CharacterLoadout){$resultFlag='-UEPCharacterLoadoutNetworkResult'}
            if($CharacterOutline){$resultFlag='-UEPCharacterOutlineNetworkResult'}
            if($CharacterTeam){$resultFlag='-UEPCharacterTeamNetworkResult'}
            if($CharacterStencil){$resultFlag='-UEPCharacterStencilNetworkResult'}
            if($CharacterLifecycle){$resultFlag='-UEPCharacterLifecycleNetworkResult'}
            if($CharacterParts){$resultFlag='-UEPCharacterPartsNetworkResult'}
            if($CharacterHealth){$resultFlag='-UEPCharacterHealthNetworkResult'}
            if($CharacterInput){$resultFlag='-UEPCharacterInputNetworkResult'}
            if($CharacterObserver){$resultFlag='-UEPCharacterObserverNetworkResult'}
            if($CharacterListener){$resultFlag='-UEPCharacterListenerNetworkResult'}
            if($CharacterLegacy){$resultFlag='-UEPCharacterLegacyNetworkResult'}
            if($CharacterReady){$resultFlag='-UEPCharacterReadyNetworkResult'}
            if($CharacterWait){$resultFlag='-UEPCharacterWaitNetworkResult'}
            if($CharacterPossessed){$resultFlag='-UEPCharacterPossessedNetworkResult'}
            if($CharacterVisibility){$resultFlag='-UEPCharacterVisibilityNetworkResult'}
            if($CharacterBeginPlay){$resultFlag='-UEPCharacterBeginPlayNetworkResult'}
            if($CharacterEquipmentHide){$resultFlag='-UEPCharacterEquipmentHideNetworkResult'}
            if($CharacterRagdoll){$resultFlag='-UEPCharacterRagdollNetworkResult'}
            if($CharacterDeathStarted){$resultFlag='-UEPCharacterDeathStartedNetworkResult'}
            if($CharacterDeathReplication){$resultFlag='-UEPCharacterDeathReplicationNetworkResult'}
            if($DashSelector){$resultFlag='-UEPDashSelectorNetworkResult'}
            if($DashRPCInput){$resultFlag='-UEPDashRPCInputNetworkResult'}
            if($DashLocalDirection){$resultFlag='-UEPDashLocalDirectionNetworkResult'}
            $peerArguments+=@("-UEPJumpPeer=$peer","-UEPJumpRun=$run","$resultFlag=$output/$peer.json","-abslog=$output/$peer.log")
            $exe=Join-Path $EngineRoot $(if($peer -eq 'server'){'Engine/Binaries/Win64/UnrealEditor-Cmd.exe'}else{'Engine/Binaries/Win64/UnrealEditor.exe'})
            $handles[$peer]=Start-UEPValidationProcess $exe $peerArguments $stage (Join-Path $output $peer) "Native Jump $peer"
            if($peer -eq 'server'){
                $watch=[Diagnostics.Stopwatch]::StartNew()
                while($true){
                    if($handles[$peer].process.HasExited){throw 'Native Jump server exited before listen'}
                    if((Test-Path "$output/server.log") -and (Get-Content "$output/server.log" -Raw) -match "listening on port $ServerPort"){break}
                    if($watch.Elapsed.TotalSeconds -gt 90){throw 'Native Jump server listen timeout'}
                    Start-Sleep -Milliseconds 250
                }
            }
        }
        $watch=[Diagnostics.Stopwatch]::StartNew()
        while(@($handles.Values|Where-Object {!$_.process.HasExited}).Count){
            if($watch.Elapsed.TotalSeconds -gt 520){throw 'Native Jump network total timeout'}
            foreach($peer in @('server','A','B0')){
                if($handles[$peer].process.HasExited -and $null -eq $handles[$peer].result){
                    $summary.processes[$peer]=Complete-UEPValidationProcess $handles[$peer]
                    if($summary.processes[$peer].exit_code -ne 0){throw "Native Jump $peer process failed"}
                    if($peer -ne 'server'){
                        @{peer=$peer;run_id=$run;exit_code=0}|ConvertTo-Json|Set-Content -LiteralPath "$output/$peer-exited.json" -Encoding utf8
                    }
                }
                if(Test-Path -LiteralPath "$output/$peer.json"){
                    try{
                        $stream=[IO.File]::Open("$output/$peer.json",[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
                        $reader=[IO.StreamReader]::new($stream)
                        try{$live=$reader.ReadToEnd()|ConvertFrom-Json -Depth 90}finally{$reader.Dispose()}
                    }catch{continue}
                    if($live.status -eq 'failed'){throw "Native Jump $peer report failed"}
                }
            }
            Start-Sleep -Milliseconds 250
        }
        foreach($peer in @('server','A','B0')){
            $summary.processes[$peer]=Complete-UEPValidationProcess $handles[$peer]
            if($summary.processes[$peer].exit_code -ne 0){throw 'Native Jump network process failed'}
            $log=Get-Content -LiteralPath "$output/$peer.log" -Raw
            $pass=if($ReloadMagazine){if($peer -eq 'server'){'UEP_RELOAD_MAGAZINE_NETWORK_PASSED'}else{'UEP_RELOAD_MAGAZINE_SHUTDOWN_PASSED'}}elseif($DropWeapon){if($peer -eq 'server'){'UEP_DROP_WEAPON_NETWORK_PASSED'}else{'UEP_DROP_WEAPON_SHUTDOWN_PASSED'}}elseif($ADS){if($peer -eq 'server'){'UEP_ADS_NETWORK_PASSED'}else{'UEP_ADS_SHUTDOWN_PASSED'}}elseif($HeroHeal){if($peer -eq 'server'){'UEP_HERO_HEAL_NETWORK_PASSED'}else{'UEP_HERO_HEAL_SHUTDOWN_PASSED'}}elseif($AutoReload){if($peer -eq 'server'){'UEP_AUTORELOAD_NETWORK_PASSED'}else{'UEP_AUTORELOAD_SHUTDOWN_PASSED'}}elseif($Cosmetics){'UEP_COSMETIC_NETWORK_PASSED'}elseif($Death){'UEP_DEATH_NETWORK_PASSED'}elseif($Quickslot){if($peer -eq 'server'){'UEP_QUICKSLOT_NETWORK_PASSED'}else{'UEP_QUICKSLOT_SHUTDOWN_PASSED'}}elseif($peer -eq 'server'){'UEP_JUMP_NETWORK_PASSED'}else{'UEP_JUMP_ABILITY_SHUTDOWN_PASSED'}
            if($SpawnEffect){$pass=if($peer -eq 'server'){'UEP_SPAWN_EFFECT_NETWORK_PASSED'}else{'UEP_SPAWN_EFFECT_SHUTDOWN_PASSED'}}
            if($Emote){$pass=if($peer -eq 'server'){'UEP_EMOTE_NETWORK_PASSED'}else{'UEP_EMOTE_SHUTDOWN_PASSED'}}
            if($WidgetHeld){$pass=if($peer -eq 'server'){'UEP_WIDGET_HELD_NETWORK_PASSED'}else{'UEP_WIDGET_HELD_SHUTDOWN_PASSED'}}
            if($WidgetPressed){$pass=if($peer -eq 'server'){'UEP_WIDGET_PRESSED_NETWORK_PASSED'}else{'UEP_WIDGET_PRESSED_SHUTDOWN_PASSED'}}
            if($AutoRespawnHelpers){$pass=if($peer -eq 'server'){'UEP_AUTO_RESPAWN_HELPERS_NETWORK_PASSED'}else{'UEP_AUTO_RESPAWN_HELPERS_SHUTDOWN_PASSED'}}
            if($AutoRespawnReset){$pass=if($peer -eq 'server'){'UEP_AUTO_RESPAWN_RESET_NETWORK_PASSED'}else{'UEP_AUTO_RESPAWN_RESET_SHUTDOWN_PASSED'}}
            if($CharacterAudio){$pass=if($peer -eq 'server'){'UEP_CHARACTER_AUDIO_NETWORK_PASSED'}else{'UEP_CHARACTER_AUDIO_SHUTDOWN_PASSED'}}
            if($CharacterQuickbar){$pass=if($peer -eq 'server'){'UEP_CHARACTER_QUICKBAR_NETWORK_PASSED'}else{'UEP_CHARACTER_QUICKBAR_SHUTDOWN_PASSED'}}
            if($CharacterLoadout){$pass=if($peer -eq 'server'){'UEP_CHARACTER_LOADOUT_NETWORK_PASSED'}else{'UEP_CHARACTER_LOADOUT_SHUTDOWN_PASSED'}}
            if($CharacterOutline){$pass=if($peer -eq 'server'){'UEP_CHARACTER_OUTLINE_NETWORK_PASSED'}else{'UEP_CHARACTER_OUTLINE_SHUTDOWN_PASSED'}}
            if($CharacterTeam){$pass=if($peer -eq 'server'){'UEP_CHARACTER_TEAM_NETWORK_PASSED'}else{'UEP_CHARACTER_TEAM_SHUTDOWN_PASSED'}}
            if($CharacterStencil){$pass=if($peer -eq 'server'){'UEP_CHARACTER_STENCIL_NETWORK_PASSED'}else{'UEP_CHARACTER_STENCIL_SHUTDOWN_PASSED'}}
            if($CharacterParts){$pass=if($peer -eq 'server'){'UEP_CHARACTER_PARTS_NETWORK_PASSED'}else{'UEP_CHARACTER_PARTS_SHUTDOWN_PASSED'}}
            if($CharacterHealth){$pass=if($peer -eq 'server'){'UEP_CHARACTER_HEALTH_NETWORK_PASSED'}else{'UEP_CHARACTER_HEALTH_SHUTDOWN_PASSED'}}
            if($CharacterInput){$pass=if($peer -eq 'server'){'UEP_CHARACTER_INPUT_NETWORK_PASSED'}else{'UEP_CHARACTER_INPUT_SHUTDOWN_PASSED'}}
            if($CharacterObserver){$pass=if($peer -eq 'server'){'UEP_CHARACTER_OBSERVER_NETWORK_PASSED'}else{'UEP_CHARACTER_OBSERVER_SHUTDOWN_PASSED'}}
            if($CharacterListener){$pass=if($peer -eq 'server'){'UEP_CHARACTER_LISTENER_NETWORK_PASSED'}else{'UEP_CHARACTER_LISTENER_SHUTDOWN_PASSED'}}
            if($CharacterLegacy){$pass=if($peer -eq 'server'){'UEP_CHARACTER_LEGACY_NETWORK_PASSED'}else{'UEP_CHARACTER_LEGACY_SHUTDOWN_PASSED'}}
            if($CharacterReady){$pass=if($peer -eq 'server'){'UEP_CHARACTER_READY_NETWORK_PASSED'}else{'UEP_CHARACTER_READY_SHUTDOWN_PASSED'}}
            if($CharacterWait){$pass=if($peer -eq 'server'){'UEP_CHARACTER_WAIT_NETWORK_PASSED'}else{'UEP_CHARACTER_WAIT_SHUTDOWN_PASSED'}}
            if($CharacterPossessed){$pass=if($peer -eq 'server'){'UEP_CHARACTER_POSSESSED_NETWORK_PASSED'}else{'UEP_CHARACTER_POSSESSED_SHUTDOWN_PASSED'}}
            if($CharacterVisibility){$pass=if($peer -eq 'server'){'UEP_CHARACTER_VISIBILITY_NETWORK_PASSED'}else{'UEP_CHARACTER_VISIBILITY_SHUTDOWN_PASSED'}}
            if($CharacterBeginPlay){$pass=if($peer -eq 'server'){'UEP_CHARACTER_BEGIN_PLAY_NETWORK_PASSED'}else{'UEP_CHARACTER_BEGIN_PLAY_SHUTDOWN_PASSED'}}
            if($CharacterEquipmentHide){$pass=if($peer -eq 'server'){'UEP_CHARACTER_EQUIPMENT_HIDE_NETWORK_PASSED'}else{'UEP_CHARACTER_EQUIPMENT_HIDE_SHUTDOWN_PASSED'}}
            if($CharacterRagdoll){$pass=if($peer -eq 'server'){'UEP_CHARACTER_RAGDOLL_NETWORK_PASSED'}else{'UEP_CHARACTER_RAGDOLL_SHUTDOWN_PASSED'}}
            if($CharacterDeathStarted){$pass=if($peer -eq 'server'){'UEP_CHARACTER_DEATH_STARTED_NETWORK_PASSED'}else{'UEP_CHARACTER_DEATH_STARTED_SHUTDOWN_PASSED'}}
            if($CharacterDeathReplication){$pass=if($peer -eq 'server'){'UEP_CHARACTER_DEATH_REPLICATION_NETWORK_PASSED'}else{'UEP_CHARACTER_DEATH_REPLICATION_SHUTDOWN_PASSED'}}
            if($DashSelector){$pass=if($peer -eq 'server'){'UEP_DASH_SELECTOR_NETWORK_PASSED'}else{'UEP_DASH_SELECTOR_SHUTDOWN_PASSED'}}
            if($DashRPCInput){$pass=if($peer -eq 'server'){'UEP_DASH_RPC_INPUT_NETWORK_PASSED'}else{'UEP_DASH_RPC_INPUT_SHUTDOWN_PASSED'}}
            if($DashLocalDirection){$pass=if($peer -eq 'server'){'UEP_DASH_LOCAL_DIRECTION_NETWORK_PASSED'}else{'UEP_DASH_LOCAL_DIRECTION_SHUTDOWN_PASSED'}}
            Assert-UEPFocusedLog $log $pass -RequirePythonExit
            if(($WidgetHeld -or $WidgetPressed) -and $log -match '(?im)Accessed None|Accessed array.*out of bounds'){throw 'Widget native BP runtime warning indicates invalid UI context'}
            if($log -notmatch ('(?s)Goodbye Python.*'+$pass+'.*Log file closed')){throw 'Native Jump network shutdown ordering failed'}
        }
        $module=if($ReloadMagazine){'uep_lyra_abilities.reload_magazine_network_contract'}elseif($DropWeapon){'uep_lyra_abilities.drop_weapon_network_contract'}elseif($ADS){'uep_lyra_abilities.ads_network_contract'}elseif($HeroHeal){'uep_lyra_abilities.hero_heal_network_contract'}elseif($AutoReload){'uep_lyra_abilities.autoreload_network_contract'}elseif($Cosmetics){'uep_lyra_characters.cosmetic_network_contract'}elseif($Quickslot){'uep_lyra_abilities.quickslot_network_contract'}else{'uep_lyra_abilities.jump_network_contract'}
        if($EquipmentIntegration){$module='uep_lyra_weapons.weapon_instance_network_contract'}
        if($SpawnEffect){$module='uep_lyra_abilities.spawn_effect_network_contract'}
        if($Emote){$module='uep_lyra_abilities.emote_network_contract'}
        if($WidgetHeld){$module='uep_lyra_abilities.widget_held_network_contract'}
        if($WidgetPressed){$module='uep_lyra_abilities.widget_pressed_network_contract'}
        if($AutoRespawnHelpers){$module='uep_lyra_abilities.auto_respawn_helpers_network_contract'}
        if($AutoRespawnListeners){$module='uep_lyra_abilities.auto_respawn_listeners_contract'}
        if($AutoRespawnEvents){$module='uep_lyra_abilities.auto_respawn_events_contract'}
        if($AutoRespawnActivation){$module='uep_lyra_abilities.auto_respawn_activation_contract'}
        if($AutoRespawnReset){$module='uep_lyra_abilities.auto_respawn_reset_network_contract'}
        if($CharacterInventory){$module='uep_lyra_characters.inventory_clear_network_contract'}
        if($CharacterAudio){$module='uep_lyra_characters.emote_audio_network_contract'}
        if($CharacterQuickbar){$module='uep_lyra_characters.quickbar_input_network_contract'}
        if($CharacterLoadout){$module='uep_lyra_characters.initial_inventory_network_contract'}
        if($CharacterOutline){$module='uep_lyra_characters.outline_network_contract'}
        if($CharacterTeam){$module='uep_lyra_characters.team_cosmetics_network_contract'}
        if($CharacterStencil){$module='uep_lyra_characters.stencil_network_contract'}
        if($CharacterLifecycle){$module='uep_lyra_characters.lifecycle_contract'}
        if($CharacterParts){$module='uep_lyra_characters.parts_changed_network_contract'}
        if($CharacterHealth){$module='uep_lyra_characters.health_changed_network_contract'}
        if($CharacterInput){$module='uep_lyra_characters.enhanced_input_network_contract'}
        if($CharacterObserver){$module='uep_lyra_characters.team_observer_network_contract'}
        if($CharacterListener){$module='uep_lyra_characters.team_listener_network_contract'}
        if($CharacterLegacy){$module='uep_lyra_characters.legacy_player_info_network_contract'}
        if($CharacterReady){$module='uep_lyra_characters.inventory_ready_network_contract'}
        if($CharacterWait){$module='uep_lyra_characters.inventory_wait_network_contract'}
        if($CharacterPossessed){$module='uep_lyra_characters.possessed_network_contract'}
        if($CharacterVisibility){$module='uep_lyra_characters.visibility_network_contract'}
        if($CharacterBeginPlay){$module='uep_lyra_characters.begin_play_network_contract'}
        if($CharacterEquipmentHide){$module='uep_lyra_characters.equipment_hide_network_contract'}
        if($CharacterRagdoll){$module='uep_lyra_characters.ragdoll_network_contract'}
        if($CharacterDeathStarted){$module='uep_lyra_characters.death_started_network_contract'}
        if($CharacterDeathReplication){$module='uep_lyra_characters.death_replication_contract'}
        if($DashSelector){$module='uep_lyra_abilities.dash_selector_contract'}
        if($DashRPCInput){$module='uep_lyra_abilities.dash_rpc_input_contract'}
        if($DashLocalDirection){$module='uep_lyra_abilities.dash_local_direction_contract'}
        $gateArgs=@('--directory',$output)
    }else{
        $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe') $arguments $stage (Join-Path $output 'jump') 'Native input Jump BP/Python differential' 300
        $report=Get-Content -LiteralPath "$output/jump.json" -Raw|ConvertFrom-Json -Depth 90
        if($report.status -ne 'passed'){throw 'Native ability report failed'}
        if($WidgetHeld -and (@($report.targets).Count -ne 1 -or $report.targets[0] -ne $WidgetHeldMode)){throw 'Held-widget native Experience target differs'}
        $module=if($ReloadMagazine){'uep_lyra_abilities.reload_magazine_contract'}elseif($DropWeapon){'uep_lyra_abilities.drop_weapon_contract'}elseif($WidgetLifecycle){'uep_lyra_abilities.widget_contract'}elseif($ADS){'uep_lyra_abilities.ads_contract'}elseif($HeroHeal){'uep_lyra_abilities.hero_heal_contract'}elseif($AutoReload){'uep_lyra_abilities.autoreload_contract'}elseif($Cosmetics){'uep_lyra_characters.cosmetic_contract'}elseif($Death){'uep_lyra_abilities.death_contract'}elseif($Quickslot){'uep_lyra_abilities.quickslot_contract'}else{'uep_lyra_abilities.jump_contract'}
        if($WeaponInstance){$module='uep_lyra_weapons.weapon_instance_contract'}
        if($EquipmentDeath){$module='uep_lyra_weapons.weapon_instance_death_contract'}
        if($SpawnEffect){$module='uep_lyra_abilities.spawn_effect_contract'}
        if($DeviceColor){$module='uep_lyra_devices.team_color_contract'}
        if($Emote){$module='uep_lyra_abilities.emote_contract'}
        if($WidgetHeld){$module='uep_lyra_abilities.widget_held_contract'}
        if($WidgetPressed){$module='uep_lyra_abilities.widget_pressed_contract'}
        if($AutoRespawnHelpers){$module='uep_lyra_abilities.auto_respawn_helpers_contract'}
        if($AutoRespawnListeners){$module='uep_lyra_abilities.auto_respawn_listeners_contract'}
        if($AutoRespawnEvents){$module='uep_lyra_abilities.auto_respawn_events_contract'}
        if($AutoRespawnActivation){$module='uep_lyra_abilities.auto_respawn_activation_contract'}
        if($AutoRespawnLifecycle){$module='uep_lyra_abilities.auto_respawn_lifecycle_contract'}
        if($AutoRespawnReset){$module='uep_lyra_abilities.auto_respawn_reset_contract'}
        if($CharacterInventory){$module='uep_lyra_characters.inventory_clear_contract'}
        if($CharacterAudio){$module='uep_lyra_characters.emote_audio_contract'}
        if($CharacterQuickbar){$module='uep_lyra_characters.quickbar_input_contract'}
        if($CharacterLoadout){$module=if($CharacterLoadoutNatural){'uep_lyra_characters.initial_inventory_natural_contract'}else{'uep_lyra_characters.initial_inventory_contract'}}
        if($CharacterOutline){$module='uep_lyra_characters.outline_contract'}
        if($CharacterTeam){$module='uep_lyra_characters.team_cosmetics_contract'}
        if($CharacterStencil){$module='uep_lyra_characters.stencil_contract'}
        if($CharacterLifecycle){$module='uep_lyra_characters.lifecycle_contract'}
        if($CharacterParts){$module='uep_lyra_characters.parts_changed_contract'}
        if($CharacterHealth){$module='uep_lyra_characters.health_changed_contract'}
        if($CharacterInput){$module='uep_lyra_characters.enhanced_input_contract'}
        if($CharacterObserver){$module='uep_lyra_characters.team_observer_contract'}
        if($CharacterListener){$module='uep_lyra_characters.team_listener_contract'}
        if($CharacterLegacy){$module='uep_lyra_characters.legacy_player_info_contract'}
        if($CharacterReady){$module='uep_lyra_characters.inventory_ready_contract'}
        if($CharacterWait){$module='uep_lyra_characters.inventory_wait_contract'}
        if($CharacterPossessed){$module='uep_lyra_characters.possessed_contract'}
        if($CharacterVisibility){$module='uep_lyra_characters.visibility_contract'}
        if($CharacterBeginPlay){$module='uep_lyra_characters.begin_play_contract'}
        if($CharacterEquipmentHide){$module='uep_lyra_characters.equipment_hide_contract'}
        if($CharacterRagdoll){$module='uep_lyra_characters.ragdoll_contract'}
        if($CharacterDeathStarted){$module='uep_lyra_characters.death_started_contract'}
        if($DashSelector){$module='uep_lyra_abilities.dash_selector_contract'}
        if($DashLocalDirection){$module='uep_lyra_abilities.dash_local_direction_contract'}
        $gateArgs=@('--report',"$output/jump.json")
        if($CharacterInventory -and $AutoRespawnReset){$gateArgs+=@('--reset')}
        if($CharacterLifecycle -and $AutoRespawnReset){$gateArgs+=@('--reset')}
        $log=Get-Content -LiteralPath "$output/jump.log" -Raw
        Assert-UEPFocusedLog $log ($marker+'_SHUTDOWN_PASSED') -RequirePythonExit
        if(($WidgetHeld -or $WidgetPressed) -and $log -match '(?im)Accessed None|Accessed array.*out of bounds'){throw 'Widget native BP runtime warning indicates invalid UI context'}
        if($log -notmatch ('(?s)'+$marker+'_DIFFERENTIAL_PASSED.*Goodbye Python.*'+$marker+'_SHUTDOWN_PASSED.*Log file closed')){throw 'Ability shutdown ordering incomplete'}
    }
    $python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
    $gateCommand=if($Death -and $Network){@('-B',(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/validate_death_network_reports.py'))+$gateArgs}else{@('-B','-m',$module)+$gateArgs}
    $summary.external_gate=Invoke-UEPValidationProcess $python $gateCommand (Join-Path $overlay 'Content/Scripts') (Join-Path $output 'report-gate') 'Native ability independent report gate' 30
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Frozen Jump input/reference changed'}}
    $summary.bounded_runtime_acceptance=$true;$summary.network_acceptance=[bool]$Network;$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{
    foreach($handle in $handles.Values){Stop-UEPValidationProcess $handle;$handle.process.Dispose()}
    $summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8
}
Write-Host "Native ability differential: $($summary.status); $output"
