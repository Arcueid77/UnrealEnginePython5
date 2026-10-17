#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,
      [Parameter(Mandatory=$true)][ValidateSet('meleehitmontage','dashselector','quickslot','death','autoreload','heroheal','dropweapon','reloadmagazine','weaponinstance','spawneffect','devicecolor','widgetheld','widgetpressed','autorespawnhelpers','autorespawnlisteners','autorespawnevents','autorespawnactivation','characterinventory','characteraudio','characterquickbar','characterloadout','characteroutline','characterteam','characterstencil','characterlifecycle','characterparts','characterhealth','characterinput','characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')][string]$Kind,
      [ValidateSet('Python','BlueprintFallback')][string]$AutoRespawnDefaultProfile='Python')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($AutoRespawnDefaultProfile -ne 'Python' -and $Kind -ne 'autorespawnactivation'){throw 'Startup Profile variant is scoped to full AutoRespawn lifecycle validation'}
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked disposable stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Fresh hero ability authoring directory required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path "$output/PreviousAssets"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';kind=$Kind;runtime_acceptance=$false;full_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();assets=@();process=$null;error=$null}
function Add-HeroHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $id=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $relative
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Hero ability native BuildId mismatch'}
        Add-HeroHash $path
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Hero ability native source mismatch'}
            Add-HeroHash $source.FullName;Add-HeroHash $target
        }
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-HeroHash $source.FullName;Add-HeroHash $target
    }
    $relative=if($Kind -eq 'reloadmagazine'){'Content/Weapons/GA_Weapon_ReloadMagazine.uasset'}elseif($Kind -eq 'dropweapon'){'Plugins/GameFeatures/ShooterCore/Content/Input/Abilities/GA_DropWeapon.uasset'}elseif($Kind -eq 'heroheal'){'Content/Characters/Heroes/Abilities/GA_Hero_Heal.uasset'}elseif($Kind -eq 'autoreload'){'Content/Weapons/GA_Weapon_AutoReload.uasset'}elseif($Kind -eq 'quickslot'){'Plugins/GameFeatures/ShooterCore/Content/Game/GA_QuickbarSlots.uasset'}else{'Content/Characters/Heroes/Abilities/GA_Hero_Death.uasset'}
    if($Kind -eq 'weaponinstance'){$relative='Plugins/GameFeatures/ShooterCore/Content/Weapons/B_WeaponInstance_Base.uasset'}
    if($Kind -eq 'spawneffect'){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/Respawn/GA_SpawnEffect.uasset'}
    if($Kind -eq 'dashselector'){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/Dash/GA_Hero_Dash.uasset'}
    if($Kind -eq 'meleehitmontage'){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/Melee/GA_Melee.uasset'}
    if($Kind -eq 'devicecolor'){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/B_TeamColor_DeviceProperty.uasset'}
    if($Kind -eq 'widgetheld'){$relative='Plugins/GameFeatures/ShooterCore/Content/Input/Abilities/GAB_ShowWidget_WhileInputHeld.uasset'}
    if($Kind -eq 'widgetpressed'){$relative='Plugins/GameFeatures/ShooterCore/Content/Input/Abilities/GAB_ShowWidget_WhenInputPressed.uasset'}
    if($Kind -in @('characterinventory','characteraudio','characterquickbar','characterloadout','characteroutline','characterteam','characterstencil','characterlifecycle','characterparts','characterhealth','characterinput','characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/B_Hero_ShooterMannequin.uasset'}
    if($Kind -in @('autorespawnhelpers','autorespawnlisteners','autorespawnevents','autorespawnactivation')){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/Respawn/GA_AutoRespawn.uasset'}
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    $original=Join-Path (Split-Path $marker.source -Parent) $relative;$copy=Join-Path $stage $relative
    if((Get-FileHash -LiteralPath $original).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Fresh original hero ability stage asset required'}
    if(Test-Path -LiteralPath (Join-Path $overlay $relative)){throw 'Do not overwrite an existing Overlay ability asset'}
    Copy-Item -LiteralPath $copy -Destination "$output/PreviousAssets/before.uasset"
    Add-HeroHash $original;Add-HeroHash "$output/PreviousAssets/before.uasset"
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_hero_ability_mixin_assets.py'
    foreach($path in @($PSCommandPath,$script,(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),
        (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/mixin_graph_gates.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/message_payload_graphs.py'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){Add-HeroHash $path}
    if($Kind -eq 'weaponinstance'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_instance_assets.py')}
    if($Kind -eq 'meleehitmontage'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_melee_hit_montage_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'devicecolor'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_device_color_assets.py')}
    if($Kind -eq 'dashselector'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_mixin_inheritance_probe.py')
    }
    if($Kind -eq 'widgetheld'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_widget_held_assets.py')}
    if($Kind -eq 'widgetpressed'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_widget_pressed_assets.py')}
    if($Kind -eq 'autorespawnhelpers'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_auto_respawn_helper_assets.py')}
    if($Kind -in @('autorespawnlisteners','autorespawnevents','autorespawnactivation')){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_auto_respawn_helper_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_auto_respawn_listener_assets.py')
    }
    if($Kind -in @('autorespawnevents','autorespawnactivation')){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_auto_respawn_event_assets.py')}
    if($Kind -eq 'autorespawnactivation'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_auto_respawn_activation_assets.py')}
    if($Kind -in @('characterinventory','characteraudio','characterquickbar','characterloadout','characteroutline','characterteam','characterstencil','characterlifecycle','characterparts','characterhealth','characterinput','characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_inventory_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_auto_respawn_helper_assets.py')
    }
    if($Kind -eq 'characteraudio'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_audio_probe.py')}
    if($Kind -eq 'characterquickbar'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_quickbar_probe.py')}
    if($Kind -eq 'characterloadout'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_loadout_probe.py')}
    if($Kind -eq 'characteroutline'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_outline_probe.py')}
    if($Kind -eq 'characterteam'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_team_probe.py')}
    if($Kind -in @('characterstencil','characterlifecycle','characterparts','characterhealth','characterinput','characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_stencil_probe.py')
        Add-HeroHash (Join-Path $stage 'Content/UEPValidation/BP_CharacterTeamCallProbe.uasset')
        Add-HeroHash (Join-Path $stage 'Content/Characters/Heroes/B_Hero_Default.uasset')
        Add-HeroHash (Join-Path (Split-Path $marker.source -Parent) 'Content/Characters/Heroes/B_Hero_Default.uasset')
    }
    if($Kind -in @('characterlifecycle','characterparts','characterhealth','characterinput','characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $stage 'Content/UEPValidation/BP_CharacterStencilCallProbe.uasset')}
    if($Kind -in @('characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_team_listener_probe.py')}
    if($Kind -in @('characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_team_listener_transport.py')}
    if($Kind -in @('characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_legacy_player_info_probe.py')}
    if($Kind -in @('characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_inventory_ready_probe.py')}
    if($Kind -in @('characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_inventory_wait_stub.py')}
    if($Kind -in @('characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $EngineRoot 'Engine/Content/EditorBlueprintResources/ActorMacros.uasset')}
    if($Kind -in @('charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_visibility_transport.py')}
    if($Kind -in @('characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_begin_play_parent.py')}
    if($Kind -in @('characterequipmenthide','characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_equipment_hide_probe.py')}
    if($Kind -in @('characterragdoll','characterdeathstarted')){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_ragdoll_probe.py')}
    if($Kind -eq 'characterdeathstarted'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_death_transport.py')}
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',
        "-UEPHeroAbilityStageRoot=$stage","-UEPHeroAbilityKind=$Kind","-UEPHeroAbilityAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    if($Kind -eq 'autorespawnactivation'){$arguments+=@("-UEPAutoRespawnDefaultProfile=$AutoRespawnDefaultProfile")}
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Retained hero ability Interface authoring' 240
    $report=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 80
    $expectedEndNodes=if($Kind -eq 'widgetpressed'){3}elseif($Kind -in @('weaponinstance','devicecolor','autorespawnhelpers','autorespawnlisteners','autorespawnevents','autorespawnactivation','characterinventory','characteraudio','characterquickbar','characterloadout','characteroutline','characterteam','characterstencil','characterlifecycle','characterparts','characterhealth','characterinput','characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){0}else{4}
    if($Kind -in @('dashselector','meleehitmontage')){$expectedEndNodes=0}
    if($report.status -ne 'passed' -or !$report.original_class_defaults_signature_graphs_preserved -or $report.native_end_adapter_nodes -ne $expectedEndNodes -or
       @($report.assets).Count -ne 2 -or $report.runtime_acceptance -or $report.kind -ne $Kind){throw 'Hero ability authoring proof incomplete'}
    if($Kind -eq 'meleehitmontage' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or !$report.native_register_restore_passed -or
        $report.new_business_nodes -ne 0 -or $report.whole_melee_activation_trace_damage_migrated -or $report.original_selector.nodes -ne 24 -or
        $report.original_selector.min -ne -.5 -or $report.original_selector.max -ne .5 -or !$report.original_selector.inclusive_min -or !$report.original_selector.inclusive_max -or
        $report.actual_registered_profile_method_counts.Python -ne 1 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or
        !$report.caller_probe.stage_only -or $report.caller_probe.gameplay_business -or $report.caller_probe.nodes -ne 3 -or
        !$report.caller_probe.typed_ability_and_actor_references -or !$report.caller_probe.virtual_bp_function_call -or
        ($report.caller_probe.outputs -join ',') -ne 'HitMontage' -or (Get-FileHash -LiteralPath $report.caller_probe.asset).Hash -ne $report.caller_probe.sha256)){
        throw 'Melee helper original class/graph/named-output/native caller proof incomplete'
    }
    if($Kind -eq 'dashselector' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or !$report.native_register_restore_passed -or
        $report.new_business_nodes -ne 0 -or $report.original_selector.nodes -ne 26 -or !$report.original_selector.native_math_retained -or
        $report.original_selector.forward_abs_yaw_less_than -ne 45 -or $report.original_selector.backward_abs_yaw_greater_than -ne 135 -or
        $report.actual_registered_profile_method_counts.Python -ne 1 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or
        !$report.caller_probe.stage_only -or $report.caller_probe.gameplay_business -or $report.caller_probe.nodes -ne 3 -or
        !$report.caller_probe.typed_ability_reference -or !$report.caller_probe.virtual_bp_function_call -or
        ($report.caller_probe.outputs -join ',') -ne 'DirectionalMontage,BiasForwardMovement' -or
        (Get-FileHash -LiteralPath $report.caller_probe.asset).Hash -ne $report.caller_probe.sha256)){
        throw 'Dash selector original graph/native named-output caller proof incomplete'
    }
    if($Kind -eq 'dashselector'){
        $probe=$report.inherited_declaration_probe
        if(!$probe.stage_only -or $probe.gameplay_business -or !$probe.parent_and_explicit_child_registered -or
            !$probe.ordinary_inherited_sibling_rejected -or !$probe.ancestor_original_through_child_router -or
            !$probe.owned_shared_function_verified -or !$probe.inherited_original_unwrapped -or !$probe.lexical_init_teardown_verified -or
            ($probe.reverse_order_values -join ',') -ne '117,211,3097,3069' -or ($probe.unregister_order_values -join ',') -ne '1023,2097,2069' -or
            $probe.child_direct_interfaces -ne 0 -or !$probe.child_owned_provider -or !$probe.restored -or @($probe.assets).Count -ne 6){throw 'Native inherited declaration/original-call control incomplete'}
        foreach($asset in $probe.assets){if((Get-FileHash -LiteralPath $asset.path).Hash -ne $asset.sha256){throw 'Native inheritance control asset changed'}}
    }
    if($Kind -eq 'characterinventory' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 1 -or $report.implemented_methods[0] -ne 'ClearInventory')){
        throw 'Character helper-only identity/default/signature/graph proof incomplete'
    }
    if($Kind -eq 'characteraudio' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 3 -or !$report.caller_probe.stage_only -or $report.caller_probe.gameplay_business -or
        !$report.caller_probe.original_animation_notify_unchanged -or @($report.caller_probe.functions).Count -ne 2 -or
        (Get-FileHash -LiteralPath $report.caller_probe.asset).Hash -ne $report.caller_probe.sha256)){
        throw 'Character audio original Interface/typed caller proof incomplete'
    }
    if($Kind -eq 'characterquickbar' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 4 -or !$report.caller_probe.stage_only -or $report.caller_probe.gameplay_business -or
        !$report.caller_probe.typed_actor_reference -or !$report.caller_probe.virtual_bp_function_call -or $report.caller_probe.nodes -ne 3 -or
        (Get-FileHash -LiteralPath $report.caller_probe.asset).Hash -ne $report.caller_probe.sha256)){
        throw 'Character slot original function/typed second BP caller proof incomplete'
    }
    if($Kind -eq 'characterloadout' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 5 -or !$report.caller_probe.stage_only -or $report.caller_probe.gameplay_business -or
        !$report.caller_probe.typed_actor_reference -or !$report.caller_probe.virtual_bp_function_call -or $report.caller_probe.nodes -ne 3 -or
        $report.caller_probe.target -ne 'AddInitialInventory' -or (Get-FileHash -LiteralPath $report.caller_probe.asset).Hash -ne $report.caller_probe.sha256)){
        throw 'Character loadout original function/typed second BP caller proof incomplete'
    }
    if($Kind -eq 'characteroutline' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 6 -or !$report.caller_probe.stage_only -or $report.caller_probe.gameplay_business -or
        !$report.caller_probe.typed_actor_reference -or !$report.caller_probe.virtual_bp_function_call -or $report.caller_probe.nodes -ne 3 -or
        $report.caller_probe.target -ne 'CreateOrUpdateOutlineIfNeeded' -or !$report.native_camera_interface_signature -or
        (Get-FileHash -LiteralPath $report.caller_probe.asset).Hash -ne $report.caller_probe.sha256)){
        throw 'Character outline original function/typed BP/native camera Interface proof incomplete'
    }
    if($Kind -eq 'characterteam' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 7 -or !$report.caller_probe.stage_only -or $report.caller_probe.gameplay_business -or
        !$report.caller_probe.typed_actor_reference -or !$report.caller_probe.virtual_bp_function_call -or $report.caller_probe.nodes -ne 3 -or
        $report.caller_probe.target -ne 'OnTeamOrCosmeticsChanged' -or @($report.caller_probe.original_parameters).Count -ne 2 -or
        @($report.native_team_signatures.PSObject.Properties).Count -ne 3 -or
        (Get-FileHash -LiteralPath $report.caller_probe.asset).Hash -ne $report.caller_probe.sha256)){
        throw 'Character team original parameter/typed BP/native orchestration proof incomplete'
    }
    if($Kind -eq 'characterstencil' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 8 -or !$report.caller_probe.stage_only -or $report.caller_probe.gameplay_business -or
        !$report.caller_probe.typed_actor_reference -or !$report.caller_probe.virtual_bp_function_call -or $report.caller_probe.nodes -ne 3 -or
        $report.caller_probe.target -ne 'UpdateCustomStencilFromTeamID' -or !$report.inherited_parent_asset_unmodified -or
        (Get-FileHash -LiteralPath $report.caller_probe.asset).Hash -ne $report.caller_probe.sha256 -or
        (Get-FileHash -LiteralPath $report.team_caller_probe.asset).Hash -ne $report.team_caller_probe.sha256)){
        throw 'Character inherited stencil original parent/caller proof incomplete'
    }
    if($Kind -eq 'characterlifecycle' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 10 -or 'K2_OnDeathFinished' -notin $report.implemented_methods -or 'K2_OnReset' -notin $report.implemented_methods -or
        !$report.inherited_parent_asset_unmodified -or !$report.caller_probe.reused_existing_stage_probe -or
        (Get-FileHash -LiteralPath $report.caller_probe.asset).Hash -ne $report.caller_probe.sha256)){
        throw 'Character lifecycle original native-event/signature/graph proof incomplete'
    }
    if($Kind -eq 'characterparts' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 11 -or !$report.native_component_receiver_register_restore_passed -or
        @($report.extra_signatures.PSObject.Properties).Count -ne 13 -or
        @($report.actual_native_registered_profile_method_counts.PSObject.Properties).Count -ne 2 -or
        $report.actual_native_registered_profile_method_counts.Python -ne 11 -or $report.actual_native_registered_profile_method_counts.BlueprintFallback -ne 11)){
        throw 'Character component receiver actual native registration/original graph proof incomplete'
    }
    if($Kind -eq 'characterhealth' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 12 -or !$report.native_component_receiver_register_restore_passed -or
        @($report.extra_signatures.PSObject.Properties).Count -ne 14 -or @($report.native_health_signatures.PSObject.Properties).Count -ne 3 -or
        $report.actual_native_registered_profile_method_counts.Python -ne 12 -or $report.actual_native_registered_profile_method_counts.BlueprintFallback -ne 12)){
        throw 'Character health receiver actual native registration/original graph proof incomplete'
    }
    if($Kind -eq 'characterinput' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne 17 -or !$report.native_component_receiver_register_restore_passed -or
        @($report.extra_signatures.PSObject.Properties).Count -ne 19 -or !$report.original_enhanced_input_binding_semantics_preserved -or !$report.compiler_receiver_names_resolved_dynamically -or
        @($report.enhanced_input_bindings).Count -ne 5 -or @($report.native_input_signatures.PSObject.Properties).Count -ne 2 -or
        !$report.automatic_native_original_input_fallback -or $report.actual_native_registered_profile_method_counts.Python -ne 17 -or $report.actual_native_registered_profile_method_counts.BlueprintFallback -ne 12)){
        throw 'Character EnhancedInput actual native registration/binding table/original graph proof incomplete'
    }
    if($Kind -in @('characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted') -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        @($report.implemented_methods).Count -ne $(if($Kind -eq 'characterdeathstarted'){30}elseif($Kind -eq 'characterragdoll'){28}elseif($Kind -eq 'characterequipmenthide'){27}elseif($Kind -eq 'characterbeginplay'){26}elseif($Kind -eq 'charactervisibility'){25}elseif($Kind -eq 'characterpossessed'){23}elseif($Kind -eq 'characterwait'){22}elseif($Kind -eq 'characterready'){21}elseif($Kind -eq 'characterlegacy'){20}elseif($Kind -eq 'characterlistener'){19}else{18}) -or !$report.native_component_receiver_register_restore_passed -or
        @($report.extra_signatures.PSObject.Properties).Count -ne $(if($Kind -eq 'characterdeathstarted'){28}elseif($Kind -eq 'characterragdoll'){26}elseif($Kind -eq 'characterequipmenthide'){25}elseif($Kind -in @('charactervisibility','characterbeginplay')){24}elseif($Kind -in @('characterready','characterwait','characterpossessed')){23}elseif($Kind -eq 'characterlegacy'){22}else{21}) -or !$report.original_enhanced_input_binding_semantics_preserved -or
        $report.original_listener_factory_orchestration_remains_bp -ne ($Kind -eq 'characterobserver') -or @($report.native_team_observer_signatures.PSObject.Properties).Count -ne 3 -or
        $report.actual_native_registered_profile_method_counts.Python -ne $(if($Kind -eq 'characterdeathstarted'){30}elseif($Kind -eq 'characterragdoll'){28}elseif($Kind -eq 'characterequipmenthide'){27}elseif($Kind -eq 'characterbeginplay'){26}elseif($Kind -eq 'charactervisibility'){25}elseif($Kind -eq 'characterpossessed'){23}elseif($Kind -eq 'characterwait'){22}elseif($Kind -eq 'characterready'){21}elseif($Kind -eq 'characterlegacy'){20}elseif($Kind -eq 'characterlistener'){19}else{18}) -or $report.actual_native_registered_profile_method_counts.BlueprintFallback -ne $(if($Kind -eq 'characterdeathstarted'){25}elseif($Kind -eq 'characterragdoll'){23}elseif($Kind -eq 'characterequipmenthide'){22}elseif($Kind -eq 'characterbeginplay'){21}elseif($Kind -eq 'charactervisibility'){20}elseif($Kind -eq 'characterpossessed'){18}elseif($Kind -eq 'characterwait'){17}elseif($Kind -eq 'characterready'){16}elseif($Kind -eq 'characterlegacy'){15}elseif($Kind -eq 'characterlistener'){14}else{13}) -or
        !$report.team_listener_probe.stage_only -or $report.team_listener_probe.gameplay_business -or $report.team_listener_probe.nodes -ne 3 -or
        (Get-FileHash -LiteralPath $report.team_listener_probe.asset).Hash -ne $report.team_listener_probe.sha256)){
        throw 'Character native team observer receiver/probe/original graph proof incomplete'
    }
    if($Kind -in @('characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted') -and ($report.native_team_listener_transport.nodes -ne 4 -or $report.native_team_listener_transport.gameplay_business -or
        $report.native_team_listener_transport.python_callback_retained -or $report.native_team_listener_transport.operation -ne 'add_unique' -or
        $report.native_team_listener_transport.delegate -ne 'OnTeamChanged' -or $report.native_team_listener_transport.callback -ne $report.team_observer_callback)){
        throw 'Character exact named native listener delegate transport proof incomplete'
    }
    if($Kind -in @('characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted') -and ($report.legacy_player_info_literal_defaults.team_id -ne 0 -or $null -ne $report.legacy_player_info_literal_defaults.display_asset -or
        !$report.legacy_player_info_probe.stage_only -or $report.legacy_player_info_probe.gameplay_business -or $report.legacy_player_info_probe.nodes -ne 3 -or
        $report.legacy_player_info_probe.real_repnotify_ingress -or $report.legacy_player_info_probe.target -ne 'OnRep_PlayerInfo' -or
        (Get-FileHash -LiteralPath $report.legacy_player_info_probe.asset).Hash -ne $report.legacy_player_info_probe.sha256)){
        throw 'Character legacy literal defaults/typed caller proof incomplete'
    }
    if($Kind -in @('characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted') -and (!$report.inventory_ready_immediate_branch_migrated -or $report.inventory_ready_pending_wait_migrated -ne ($Kind -in @('characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')) -or
        !$report.original_inventory_readiness_macro_retained -or !$report.inventory_ready_probe.stage_only -or $report.inventory_ready_probe.gameplay_business -or
        $report.inventory_ready_probe.nodes -ne 5 -or !$report.inventory_ready_probe.actual_native_experience_factory -or $report.inventory_ready_probe.callback_directly_invoked -or
        $report.native_inventory_ready_transport.nodes -ne 4 -or $report.native_inventory_ready_transport.callback -ne $report.inventory_ready_receiver -or $report.native_inventory_ready_transport.gameplay_business -or
        $report.inventory_ready_probe.target -ne $report.inventory_ready_receiver -or
        (Get-FileHash -LiteralPath $report.inventory_ready_probe.asset).Hash -ne $report.inventory_ready_probe.sha256)){
        throw 'Character immediate readiness/original deferred macro/typed caller proof incomplete'
    }
    if($Kind -in @('characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted') -and ($report.native_inventory_wait_stub.nodes -ne 2 -or $report.native_inventory_wait_stub.gameplay_business -or
        $report.native_inventory_wait_stub.parameter_type -ne 'int32' -or @($report.native_inventory_wait_resume_signature.parameters).Count -ne 1 -or
        $report.native_inventory_wait_resume_signature.parameters[0].name -ne 'Linkage' -or @($report.native_inventory_wait_signatures.PSObject.Properties).Count -ne 2)){
        throw 'Character native int-linkage wait declaration/signatures proof incomplete'
    }
    if($Kind -in @('characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted') -and (!$report.experience_ready_factory_migrated -or
        !$report.original_possession_semantics.remote_branch_noop -or !$report.original_possession_semantics.controller_parameter_unused -or
        !$report.original_possession_semantics.implicit_self_world_context -or $report.original_possession_semantics.parent_event_called -or
        $report.original_possession_semantics.factory -ne 'WaitForExperienceReady' -or @($report.native_possession_factory_signatures.PSObject.Properties).Count -ne 3)){
        throw 'Character original possession authority/factory semantics proof incomplete'
    }
    if($Kind -in @('charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted') -and (!$report.visibility_callback_business_migrated -or !$report.original_visibility_semantics.payload_ignored -or
        $report.original_visibility_semantics.scheduler -ne 'DelayUntilNextTick' -or $report.original_visibility_semantics.hidden_after_resume -or
        $report.original_visibility_semantics.whole_begin_play_migrated -or $report.native_visibility_resume_stub.nodes -ne 2 -or
        $report.native_visibility_resume_stub.gameplay_business -or $report.native_visibility_registration_transport.nodes -ne 4 -or
        $report.native_visibility_registration_transport.gameplay_business -or $report.native_visibility_registration_transport.python_callback_retained -or
        @($report.native_visibility_signatures.PSObject.Properties).Count -ne 2 -or @($report.native_visibility_resume_signature.parameters).Count -ne 1 -or
        $report.native_visibility_resume_signature.parameters[0].name -ne 'Linkage' -or $report.native_visibility_resume_signature.parameters[0].type -ne 'int32')){
        throw 'Character native InitState/visibility transport/resume proof incomplete'
    }
    if($Kind -in @('characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted') -and (!$report.begin_play_business_migrated -or $report.native_begin_play_parent_transport.nodes -ne 2 -or
        $report.native_begin_play_parent_transport.gameplay_business -or $report.native_begin_play_parent_transport.replay_current_actor_begin_play -or
        ($report.original_begin_play_semantics.order -join ',') -ne 'parent,listen,hide,register' -or !$report.original_begin_play_semantics.call_immediately -or
        $report.original_begin_play_semantics.component -ne 'PawnExtComponent' -or $report.original_begin_play_semantics.tag -ne 'InitState.GameplayReady')){
        throw 'Character original native BeginPlay order/parent transport proof incomplete'
    }
    if($Kind -in @('characterequipmenthide','characterragdoll','characterdeathstarted') -and (!$report.inherited_equipment_hide_migrated -or $report.inherited_equipment_hide_owner -ne '/Game/Characters/Heroes/B_Hero_Default.B_Hero_Default_C' -or
        !$report.equipment_hide_probe.stage_only -or $report.equipment_hide_probe.gameplay_business -or $report.equipment_hide_probe.nodes -ne 3 -or
        !$report.equipment_hide_probe.typed_actor_reference -or !$report.equipment_hide_probe.virtual_bp_function_call -or
        @($report.native_equipment_hide_signatures.PSObject.Properties).Count -ne 3 -or
        (Get-FileHash -LiteralPath $report.equipment_hide_probe.asset).Hash -ne $report.equipment_hide_probe.sha256)){
        throw 'Character inherited equipment-hide actual owner/probe/native signature proof incomplete'
    }
    if($Kind -in @('characterragdoll','characterdeathstarted') -and (!$report.ragdoll_orchestration_migrated -or $report.native_physics_or_animation_implementation_changed -or
        $report.ragdoll_original_owner -ne '/Game/Characters/Heroes/B_Hero_Default.B_Hero_Default_C' -or
        $report.original_ragdoll_semantics.nodes -ne 14 -or ($report.original_ragdoll_semantics.order -join ',') -ne 'collision,simulation,impulse' -or
        !$report.ragdoll_probe.stage_only -or $report.ragdoll_probe.gameplay_business -or $report.ragdoll_probe.nodes -ne 3 -or
        !$report.ragdoll_probe.typed_actor_reference -or !$report.ragdoll_probe.virtual_bp_function_call -or
        @($report.native_ragdoll_signatures.PSObject.Properties).Count -ne 7 -or
        !$report.ragdoll_physics_fixture.stage_only -or $report.ragdoll_physics_fixture.gameplay_business -or !$report.ragdoll_physics_fixture.original_assets_unmodified -or
        !$report.ragdoll_physics_fixture.fixture_owned_body -or $report.ragdoll_physics_fixture.bodies -ne 1 -or $report.ragdoll_physics_fixture.constraints -ne 0 -or
        (Get-FileHash -LiteralPath $report.ragdoll_physics_fixture.asset).Hash -ne $report.ragdoll_physics_fixture.sha256 -or
        (Get-FileHash -LiteralPath $report.ragdoll_probe.asset).Hash -ne $report.ragdoll_probe.sha256)){
        throw 'Character inherited Ragdoll original graph/native probe proof incomplete'
    }
    if($Kind -eq 'characterdeathstarted' -and (!$report.death_started_business_migrated -or
        $report.death_started_original_owner -ne '/Game/Characters/Heroes/B_Hero_Default.B_Hero_Default_C' -or
        $report.original_death_started_semantics.reachable_nodes -ne 14 -or !$report.original_death_started_semantics.payload_ignored -or
        !$report.original_death_started_semantics.empty_death_endpoint_retained -or $report.original_death_started_semantics.native_backend -ne 'Delay' -or
        ($report.original_death_started_semantics.order -join ',') -ne 'montage,sight,delay,ragdoll,hide,death' -or
        $report.native_death_resume_stub.nodes -ne 2 -or $report.native_death_resume_stub.gameplay_business -or
        !$report.native_death_resume_stub.native_latent_resume_target -or $report.native_death_resume_stub.parameter_type -ne 'int32' -or
        @($report.native_death_started_signatures.PSObject.Properties).Count -ne 5)){
        throw 'Inherited native death receiver/order/empty continuation proof incomplete'
    }
    if($Kind -eq 'widgetheld' -and (!$report.original_full_cdo_preserved -or !$report.native_children_unchanged -or $report.soft_class_path_transport_nodes -ne 4 -or $report.native_state_teardown_guard_nodes -ne 4)){
        throw 'Held-widget original CDO/children/typed soft-class transport proof incomplete'
    }
    if($Kind -eq 'widgetpressed' -and (!$report.original_full_cdo_preserved -or !$report.native_children_unchanged -or $report.soft_class_path_transport_nodes -ne 4 -or
        $report.original_delegate_cleanup_nodes -ne 4 -or $report.original_pending_widget_capture_nodes -ne 3)){
        throw 'Pressed-widget original CDO/children/typed transport/cleanup proof incomplete'
    }
    if($Kind -eq 'autorespawnhelpers' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        $report.original_entry_transport_nodes -ne 0 -or $report.named_query_output -ne 'IsDeadOrDying' -or
        @($report.implemented_methods).Count -ne 3 -or $report.death_listener_timer_restart_business_migrated)){
        throw 'AutoRespawn helper-only original graph/default scope proof incomplete'
    }
    if($Kind -eq 'autorespawnlisteners' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        !$report.death_listener_orchestration_migrated -or $report.typed_listener_transport_nodes -ne 16 -or
        @($report.typed_listener_transports).Count -ne 4 -or @($report.implemented_methods).Count -ne 5 -or
        $report.death_listener_timer_restart_business_migrated)){
        throw 'AutoRespawn listener exact-delegate/default/graph proof incomplete'
    }
    if($Kind -eq 'autorespawnevents' -and (!$report.original_full_cdo_preserved -or !$report.original_business_graphs_preserved_with_dispatch -or
        $report.original_graphs_unmodified -or !$report.death_listener_timer_restart_business_migrated -or
        $report.typed_listener_transport_nodes -ne 16 -or @($report.implemented_methods).Count -ne 9 -or
        $report.event_transport.native_delay_nodes_reused -ne 2 -or $report.event_transport.native_entry_nodes -ne 2 -or
        $report.event_transport.continuation_dispatch_nodes -ne 4 -or $report.event_transport.gate_function_nodes -ne 4 -or
        @($report.event_transport.dispatch_transport_endpoints).Count -ne 4)){
        throw 'AutoRespawn event original latent/default/business/dispatch proof incomplete'
    }
    if($Kind -eq 'autorespawnactivation' -and (!$report.original_full_cdo_preserved -or !$report.original_business_graphs_preserved_with_dispatch -or
        $report.original_graphs_unmodified -or !$report.activation_reset_ui_removal_business_migrated -or
        $report.default_profile -ne $AutoRespawnDefaultProfile -or @($report.implemented_methods).Count -ne 16 -or
        $report.event_transport.native_delay_nodes_reused -ne 2 -or $report.typed_listener_transport_nodes -ne 16 -or
        !$report.activation_transport.native_listener_node_reused -or !$report.activation_transport.exact_match -or
        !$report.activation_transport.native_parent_end_forwarding_preserved -or
        $report.activation_transport.additional_entry_nodes -ne 1 -or $report.activation_transport.proxy_capture_nodes -ne 1 -or
        $report.activation_transport.additional_dispatch_nodes -ne 6 -or $report.activation_transport.additional_gate_body_nodes -ne 6 -or
        @($report.activation_transport.dispatch_transport_endpoints).Count -ne 10)){
        throw 'AutoRespawn activation/reset/native-parent/lifecycle authoring proof incomplete'
    }
    $log=Get-Content -LiteralPath "$output/assets.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_HERO_ABILITY_ASSETS_PASSED'
    if($log -notmatch '(?s)UEP_HERO_ABILITY_ASSETS_PASSED.*Goodbye Python.*Log file closed'){throw 'Hero asset commandlet exit ordering incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Hero ability frozen input changed'}}
    foreach($relative in $report.assets){
        $source=Join-Path $stage $relative;$target=Join-Path $overlay $relative
        if(Test-Path -LiteralPath $target){throw 'Do not overwrite existing Overlay ability output'}
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source -Destination $target
        $hash=(Get-FileHash -LiteralPath $source).Hash
        if((Get-FileHash -LiteralPath $target).Hash -ne $hash){throw 'Hero ability output copy differs'}
        $summary.assets+=@{stage=$source;overlay=$target;sha256=$hash}
    }
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Retained $Kind ability authoring: $($summary.status); $output"
