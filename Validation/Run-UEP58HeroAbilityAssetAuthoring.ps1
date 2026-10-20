#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,
      [Parameter(Mandatory=$true)][ValidateSet('explorerstyle','explorercharacters','explorerstate','editorexperiences','lobbybackground','replayruntime','replaybrowser','sessionentry','sessionbrowser','sessionbutton','hostsession','experiencescreen','experiencelist','startuplogin','frontendmenu','menulayers','creditswidgets','diagnosticwidgets','settingsscreens','settingseditors','foundationwidgets','boundaction','experiencetile','menubuttons','foundationbuttons','macroclosure','shootereqs','shooterai','gamephases','eliminationscore','controlpointwidgets','scoreboardstyle','scoreboardlist','scoreboardrows','eliminationwidgets','accoladewidgets','accoladerelay','eliminationfeedrelay','controlpointfeedback','controlpointstate','controlpointhelpers','cpscoring','tdmscoring','scoringbase','physicsfields','smallburstcues','spawningcue','traversalcues','heroburstcues','characterdamage','messagewidgets','cuewidgets','footstep','generalaudio','windsystem','musiccontrols','weaponaudiomath','weaponfirecues','netshooterability','netshooteractor','weaponabilityfire','weaponimpacts','weapondecals','weaponfirefx','weaponactorhelpers','grenadevfx','grenadewidget','meleehitmontage','dashselector','quickslot','death','autoreload','heroheal','dropweapon','reloadmagazine','weaponinstance','spawneffect','devicecolor','widgetheld','widgetpressed','autorespawnhelpers','autorespawnlisteners','autorespawnevents','autorespawnactivation','characterinventory','characteraudio','characterquickbar','characterloadout','characteroutline','characterteam','characterstencil','characterlifecycle','characterparts','characterhealth','characterinput','characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')][string]$Kind,
      [string]$ControlPointHelpersBaseline,[string]$ExplorerCharacterBaseline,
      [ValidateSet('Python','BlueprintFallback')][string]$AutoRespawnDefaultProfile='Python')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(($Kind -in @('controlpointstate','controlpointfeedback')) -ne [bool]$ControlPointHelpersBaseline){throw 'Control point state authoring requires its explicit accepted helper parent revision'}
if(($Kind -eq 'explorerstyle') -ne [bool]$ExplorerCharacterBaseline){throw 'Explorer style requires its explicit accepted helper baseline'}
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
    if($Kind -eq 'grenadewidget'){$relative='Plugins/GameFeatures/ShooterCore/Content/Input/Abilities/GA_Grenade.uasset'}
    if($Kind -in @('controlpointstate','controlpointfeedback')){$relative='Plugins/GameFeatures/ShooterCore/Content/Blueprint/B_ControlPointVolume.uasset'}
    if($Kind -in @('explorercharacters','explorerstyle')){$relative='Plugins/GameFeatures/ShooterExplorer/Content/Blueprint/B_Hero_Explorer.uasset'}
    if($Kind -eq 'explorerstate'){$relative='Plugins/GameFeatures/ShooterExplorer/Content/AI/StateTrees/Evaluators/EV_PlayerPosition.uasset'}
    if($Kind -eq 'editorexperiences'){$relative='Content/System/DefaultEditorMap/B_ExperienceList3D.uasset'}
    if($Kind -eq 'lobbybackground'){$relative='Content/Environments/B_LoadRandomLobbyBackground.uasset'}
    if($Kind -eq 'replayruntime'){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/B_HandleShooterReplays.uasset'}
    if($Kind -eq 'replaybrowser'){$relative='Content/UI/Menu/Replays/W_ReplayBrowserScreen.uasset'}
    if($Kind -eq 'sessionentry'){$relative='Content/UI/Menu/Experiences/W_SessionBrowserEntry.uasset'}
    if($Kind -eq 'sessionbrowser'){$relative='Content/UI/Menu/Experiences/W_SessionBrowserScreen.uasset'}
    if($Kind -eq 'sessionbutton'){$relative='Content/UI/Menu/Experiences/W_LyraSessionButton.uasset'}
    if($Kind -eq 'hostsession'){$relative='Content/UI/Menu/Experiences/W_HostSessionScreen.uasset'}
    if($Kind -eq 'experiencescreen'){$relative='Content/UI/Menu/Experiences/W_ExperienceSelectionScreen.uasset'}
    if($Kind -eq 'experiencelist'){$relative='Content/UI/Menu/Experiences/W_ExperienceTile.uasset'}
    if($Kind -eq 'startuplogin'){$relative='Content/UI/Menu/W_LyraStartup.uasset'}
    if($Kind -eq 'frontendmenu'){$relative='Content/UI/Menu/W_LyraFrontEnd.uasset'}
    if($Kind -eq 'menulayers'){$relative='Content/UI/W_OverallUILayout.uasset'}
    if($Kind -eq 'creditswidgets'){$relative='Content/UI/Credits/W_Credits.uasset'}
    if($Kind -eq 'diagnosticwidgets'){$relative='Content/UI/PerfStats/W_SingleGraphStat.uasset'}
    if($Kind -eq 'settingsscreens'){$relative='Content/UI/Settings/Screens/Gamma/W_GammaEditor.uasset'}
    if($Kind -eq 'settingseditors'){$relative='Content/UI/Settings/Editors/W_SettingEntryBackground.uasset'}
    if($Kind -eq 'foundationwidgets'){$relative='Content/UI/Foundation/Dialogs/W_ConfirmationDialog.uasset'}
    if($Kind -eq 'boundaction'){$relative='Content/UI/Foundation/Widgets/BottomBar/W_BoundActionButton.uasset'}
    if($Kind -eq 'experiencetile'){$relative='Content/UI/Menu/W_LyraExperienceTileButton.uasset'}
    if($Kind -eq 'menubuttons'){$relative='Content/UI/Menu/W_LyraMenuButton.uasset'}
    if($Kind -eq 'foundationbuttons'){$relative='Content/UI/Foundation/Buttons/W_LyraButton.uasset'}
    if($Kind -eq 'macroclosure'){$relative='Content/Audio/Blueprints/WeaponAudioMacros.uasset'}
    if($Kind -eq 'shootereqs'){$relative='Plugins/GameFeatures/ShooterCore/Content/Bot/EQS/Context/EQS_Context_ControlPoints.uasset'}
    if($Kind -eq 'shooterai'){$relative='Plugins/GameFeatures/ShooterCore/Content/Bot/B_AI_Controller_LyraShooter.uasset'}
    if($Kind -eq 'gamephases'){$relative='Plugins/GameFeatures/ShooterCore/Content/Experiences/Phases/Phase_Warmup.uasset'}
    if($Kind -eq 'eliminationscore'){$relative='Plugins/GameFeatures/ShooterCore/Content/Elimination/UI/W_ScoreWidget_Elimination.uasset'}
    if($Kind -eq 'controlpointwidgets'){$relative='Plugins/GameFeatures/ShooterCore/Content/ControlPoint/UI/W_CPScoreWidget.uasset'}
    if($Kind -eq 'scoreboardstyle'){$relative='Plugins/GameFeatures/ShooterCore/Content/UserInterface/ScoreBoard/W_SB_TeamStat.uasset'}
    if($Kind -eq 'scoreboardlist'){$relative='Plugins/GameFeatures/ShooterCore/Content/UserInterface/ScoreBoard/W_SB_PlayerList.uasset'}
    if($Kind -eq 'scoreboardrows'){$relative='Plugins/GameFeatures/ShooterCore/Content/UserInterface/ScoreBoard/PlayerRow/W_BasePlayerRow.uasset'}
    if($Kind -eq 'eliminationwidgets'){$relative='Plugins/GameFeatures/ShooterCore/Content/UserInterface/Notifications/EliminationFeed/W_EliminationFeed.uasset'}
    if($Kind -eq 'accoladewidgets'){$relative='Plugins/GameFeatures/ShooterCore/Content/UserInterface/Notifications/Accolades/W_AccoladeHostWidget.uasset'}
    if($Kind -eq 'accoladerelay'){$relative='Plugins/GameFeatures/ShooterCore/Content/Accolades/B_AccoladeRelay.uasset'}
    if($Kind -eq 'eliminationfeedrelay'){$relative='Plugins/GameFeatures/ShooterCore/Content/Accolades/B_EliminationFeedRelay.uasset'}
    if($Kind -eq 'controlpointhelpers'){$relative='Plugins/GameFeatures/ShooterCore/Content/Blueprint/B_ControlPointVolume.uasset'}
    if($Kind -eq 'cpscoring'){$relative='Plugins/GameFeatures/ShooterCore/Content/ControlPoint/B_ControlPointScoring.uasset'}
    if($Kind -eq 'tdmscoring'){$relative='Plugins/GameFeatures/ShooterCore/Content/Elimination/B_TeamDeathMatchScoring.uasset'}
    if($Kind -eq 'scoringbase'){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/B_ShooterGameScoring_Base.uasset'}
    if($Kind -eq 'physicsfields'){$relative='Content/Effects/Physics/B_ExamplePhysicsField.uasset'}
    if($Kind -eq 'smallburstcues'){$relative='Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCN_InteractPickUp.uasset'}
    if($Kind -eq 'spawningcue'){$relative='Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_Spawning.uasset'}
    if($Kind -eq 'traversalcues'){$relative='Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_Launcher_Activate.uasset'}
    if($Kind -eq 'heroburstcues'){$relative='Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_Dash.uasset'}
    if($Kind -eq 'characterdamage'){$relative='Content/GameplayCueNotifies/GCNL_Character_DamageTaken.uasset'}
    if($Kind -eq 'messagewidgets'){$relative='Plugins/GameFeatures/ShooterCore/Content/GameplayCues/W_MatchDecided_Message.uasset'}
    if($Kind -eq 'cuewidgets'){$relative='Content/GameplayCueNotifies/GCNL_Widget_Base.uasset'}
    if($Kind -eq 'footstep'){$relative='Content/Effects/Blueprints/B_FootStep.uasset'}
    if($Kind -eq 'generalaudio'){$relative='Content/Audio/Blueprints/GeneralAudioFunctions.uasset'}
    if($Kind -eq 'windsystem'){$relative='Content/Audio/Blueprints/B_WindSystem.uasset'}
    if($Kind -eq 'musiccontrols'){$relative='Content/Audio/Blueprints/B_MusicManagerComponent_Base.uasset'}
    if($Kind -eq 'weaponaudiomath'){$relative='Plugins/GameFeatures/ShooterCore/Content/System/Audio/WeaponAudioFunctions.uasset'}
    if($Kind -eq 'weaponfirecues'){$relative='Plugins/GameFeatures/ShooterCore/Content/Weapons/Pistol/GCN_Weapon_Pistol_Fire.uasset'}
    if($Kind -eq 'netshooterability'){$relative='Plugins/GameFeatures/ShooterCore/Content/Weapons/NetShooter_PROTO/GA_WeaponNetShooter.uasset'}
    if($Kind -eq 'netshooteractor'){$relative='Plugins/GameFeatures/ShooterCore/Content/Weapons/NetShooter_PROTO/B_NetShooter.uasset'}
    if($Kind -eq 'weaponabilityfire'){$relative='Content/Weapons/GA_Weapon_Fire.uasset'}
    if($Kind -eq 'weaponimpacts'){$relative='Content/Effects/Blueprints/B_WeaponImpacts.uasset'}
    if($Kind -eq 'weapondecals'){$relative='Content/Effects/Blueprints/B_WeaponDecals.uasset'}
    if($Kind -eq 'weaponfirefx'){$relative='Content/Effects/Blueprints/B_WeaponFire.uasset'}
    if($Kind -eq 'weaponactorhelpers'){$relative='Content/Weapons/B_Weapon.uasset'}
    if($Kind -eq 'grenadevfx'){$relative='Plugins/GameFeatures/ShooterCore/Content/Weapon/Grenade/B_Grenade.uasset'}
    if($Kind -eq 'devicecolor'){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/B_TeamColor_DeviceProperty.uasset'}
    if($Kind -eq 'widgetheld'){$relative='Plugins/GameFeatures/ShooterCore/Content/Input/Abilities/GAB_ShowWidget_WhileInputHeld.uasset'}
    if($Kind -eq 'widgetpressed'){$relative='Plugins/GameFeatures/ShooterCore/Content/Input/Abilities/GAB_ShowWidget_WhenInputPressed.uasset'}
    if($Kind -in @('characterinventory','characteraudio','characterquickbar','characterloadout','characteroutline','characterteam','characterstencil','characterlifecycle','characterparts','characterhealth','characterinput','characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/B_Hero_ShooterMannequin.uasset'}
    if($Kind -in @('autorespawnhelpers','autorespawnlisteners','autorespawnevents','autorespawnactivation')){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/Respawn/GA_AutoRespawn.uasset'}
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    $original=Join-Path (Split-Path $marker.source -Parent) $relative;$copy=Join-Path $stage $relative
    if($Kind -in @('controlpointstate','controlpointfeedback')){
        $parentRoot=[IO.Path]::GetFullPath($ControlPointHelpersBaseline)
        if(!$parentRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned helper parent revision required'}
        $parentSummaryPath=Join-Path $parentRoot 'summary.json';$parentProofPath=Join-Path $parentRoot 'assets.json'
        $parentSummary=Get-Content -LiteralPath $parentSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $parentProof=Get-Content -LiteralPath $parentProofPath -Raw|ConvertFrom-Json -Depth 80
        if($parentSummary.status -ne 'passed' -or $parentSummary.kind -ne $(if($Kind -eq 'controlpointfeedback'){'controlpointstate'}else{'controlpointhelpers'}) -or $parentProof.status -ne 'passed' -or $parentProof.kind -ne $(if($Kind -eq 'controlpointfeedback'){'controlpointstate'}else{'controlpointhelpers'}) -or @($parentSummary.assets).Count -ne 2){throw 'Accepted helper parent proof required'}
        foreach($asset in $parentSummary.assets){
            foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Helper parent revision changed'}}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($asset.stage));Copy-Item -LiteralPath $asset.stage -Destination $backup;Add-HeroHash $backup
        }
        Add-HeroHash $parentSummaryPath;Add-HeroHash $parentProofPath
    }elseif($Kind -eq 'explorerstyle'){
        $parentRoot=[IO.Path]::GetFullPath($ExplorerCharacterBaseline)
        if(!$parentRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned Explorer helper baseline required'}
        $parentSummaryPath=Join-Path $parentRoot 'summary.json';$parentProofPath=Join-Path $parentRoot 'assets.json';$parentSummary=Get-Content -LiteralPath $parentSummaryPath -Raw|ConvertFrom-Json -Depth 100;$parentProof=Get-Content -LiteralPath $parentProofPath -Raw|ConvertFrom-Json -Depth 100
        if($parentSummary.status -ne 'passed' -or $parentSummary.kind -ne 'explorercharacters' -or $parentProof.status -ne 'passed' -or @($parentSummary.assets).Count -ne 4){throw 'Accepted Explorer helper family required'}
        foreach($asset in $parentSummary.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Explorer parent asset changed'}};$backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($asset.stage));Copy-Item -LiteralPath $asset.stage -Destination $backup;Add-HeroHash $backup}
        Add-HeroHash $parentSummaryPath;Add-HeroHash $parentProofPath
        foreach($tool in @('generate_explorer_style_assets.py','generate_explorer_character_assets.py','explorer_character_cdo.py','generate_character_inventory_assets.py','generate_dash_selector_assets.py','mixin_graph_gates.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }else{
        if((Get-FileHash -LiteralPath $original).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Fresh original hero ability stage asset required'}
        if(Test-Path -LiteralPath (Join-Path $overlay $relative)){throw 'Do not overwrite an existing Overlay ability asset'}
    }
    Copy-Item -LiteralPath $copy -Destination "$output/PreviousAssets/before.uasset"
    Add-HeroHash $original;Add-HeroHash "$output/PreviousAssets/before.uasset"
    if($Kind -in @('controlpointstate','controlpointfeedback')){
        foreach($tool in @('generate_control_point_feedback_assets.py','generate_control_point_state_assets.py','generate_control_point_helpers_assets.py','generate_small_burst_cue_assets.py','generate_hero_burst_cue_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $stage 'Plugins/GameFeatures/ShooterCore/Content/ControlPoint/B_ControlPointScoring.uasset')
    }
    if($Kind -eq 'explorercharacters'){
        $secondary='Plugins/GameFeatures/ShooterExplorer/Content/Blueprint/B_Pawn_Explorer.uasset'
        $characterSourceFile=Join-Path (Split-Path $marker.source -Parent) $secondary;$characterStageFile=Join-Path $stage $secondary
        if((Get-FileHash -LiteralPath $characterSourceFile).Hash -ne (Get-FileHash -LiteralPath $characterStageFile).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original Explorer Pawn required'}
        $backup=Join-Path "$output/PreviousAssets" 'B_Pawn_Explorer.uasset';Copy-Item -LiteralPath $characterStageFile -Destination $backup;Add-HeroHash $characterSourceFile;Add-HeroHash $backup
        foreach($tool in @('generate_explorer_character_assets.py','explorer_character_cdo.py','generate_message_widget_assets.py','generate_character_inventory_assets.py','message_payload_graphs.py','mixin_graph_gates.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'explorerstate'){
        foreach($task in @('STT_GetPlayerLocation','STT_Follow','STT_GoTo','STT_SimpleDebugDelays')){
            $secondary="Plugins/GameFeatures/ShooterExplorer/Content/AI/StateTrees/Tasks/$task.uasset";$source=Join-Path (Split-Path $marker.source -Parent) $secondary;$copy=Join-Path $stage $secondary
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original Explorer StateTree task required'}
            $backup=Join-Path "$output/PreviousAssets" "$task.uasset";Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        }
        foreach($tool in @('generate_explorer_state_assets.py','generate_message_widget_assets.py','generate_dash_selector_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'editorexperiences'){
        $secondary='Content/System/DefaultEditorMap/B_TeleportToUserFacingExperience.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $secondary;$copy=Join-Path $stage $secondary
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original experience portal required'}
        $backup=Join-Path "$output/PreviousAssets" 'B_TeleportToUserFacingExperience.uasset';Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        foreach($tool in @('generate_editor_experience_assets.py','generate_message_widget_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'lobbybackground'){foreach($tool in @('generate_lobby_background_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','generate_hero_burst_cue_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}}
    if($Kind -eq 'replayruntime'){
        foreach($secondary in @('Plugins/GameFeatures/ShooterCore/Content/UserInterface/Replays/W_ShooterReplayHUD.uasset','Plugins/GameFeatures/ShooterCore/Content/UserInterface/Replays/W_Replay_ScrubBar.uasset')){
            $source=Join-Path (Split-Path $marker.source -Parent) $secondary;$copy=Join-Path $stage $secondary
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original replay runtime widgets required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($copy));Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        }
        foreach($tool in @('generate_replay_runtime_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'replaybrowser'){
        $secondary='Content/UI/Menu/Replays/W_ReplayListEntry.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $secondary;$copy=Join-Path $stage $secondary
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original replay list entry required'}
        $backup=Join-Path "$output/PreviousAssets" 'W_ReplayListEntry.uasset';Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        foreach($tool in @('generate_replay_browser_assets.py','generate_message_widget_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'sessionentry'){
        foreach($tool in @('generate_session_entry_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        foreach($dependency in @('Content/UI/Menu/Experiences/W_LyraSessionButton.uasset','Content/UI/Menu/Experiences/UIExperienceMacros.uasset')){Add-HeroHash (Join-Path $stage $dependency)}
    }
    if($Kind -eq 'sessionbrowser'){
        foreach($tool in @('generate_session_browser_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $stage 'Content/UI/Menu/Experiences/W_SessionBrowserEntry.uasset')
    }
    if($Kind -eq 'sessionbutton'){
        foreach($tool in @('generate_session_button_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $stage 'Plugins/GameFeatures/ShooterCore/Content/UserInterface/ScoreBoard/W_SB_TeamStat.uasset')
    }
    if($Kind -eq 'hostsession'){
        foreach($tool in @('generate_host_session_assets.py','generate_message_widget_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $stage 'Content/UI/Menu/Experiences/UIExperienceMacros.uasset')
    }
    if($Kind -eq 'experiencescreen'){
        foreach($tool in @('generate_experience_screen_assets.py','generate_message_widget_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $stage 'Content/UI/Menu/Experiences/UIExperienceMacros.uasset')
    }
    if($Kind -eq 'experiencelist'){
        $secondary='Content/UI/Menu/Experiences/W_ExperienceList.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $secondary;$copy=Join-Path $stage $secondary
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original experience list required'}
        $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($copy));Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        foreach($tool in @('generate_experience_list_assets.py','generate_message_widget_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'startuplogin'){
        $secondary='Content/UI/Menu/W_UserLoginButton.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $secondary;$copy=Join-Path $stage $secondary
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original user-login button required'}
        $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($copy));Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        foreach($tool in @('generate_startup_login_assets.py','generate_message_widget_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','message_payload_graphs.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'frontendmenu'){
        foreach($tool in @('generate_frontend_menu_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'menulayers'){
        foreach($secondary in @('Hud/W_LyraGameMenu','Menu/W_TouchCloseButton','Menu/Experiences/W_NonInteractiveSpinner')){
            $relativeSecondary='Content/UI/'+$secondary+'.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$copy=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original menu/layer widgets required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($copy));Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        }
        foreach($tool in @('generate_menu_layer_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'creditswidgets'){
        $secondary='Content/UI/Credits/W_TapToggleActionBar.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $secondary;$copy=Join-Path $stage $secondary
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original credits action bar required'}
        $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($copy));Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        foreach($tool in @('generate_credits_widget_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','generate_message_widget_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'diagnosticwidgets'){
        foreach($secondary in @('PerfStats/W_SingleTextStat','Menu/W_BuildConfiguration','Menu/W_UserWatermark')){
            $relativeSecondary='Content/UI/'+$secondary+'.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$copy=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original diagnostic widgets required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($copy));Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        }
        foreach($tool in @('generate_diagnostic_widget_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','generate_message_widget_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'settingsscreens'){
        foreach($secondary in @('Screens/HDRCalibration/W_HDRCalibrationEditor','W_LyraSettingScreen','W_SettingsPanel')){
            $relativeSecondary='Content/UI/Settings/'+$secondary+'.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$copy=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original settings screen family required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($copy));Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        }
        foreach($tool in @('generate_settings_screen_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','generate_message_widget_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'settingseditors'){
        foreach($secondary in @('Editors/W_SettingsListEntry_Action','Editors/W_SettingsListEntry_Discrete','Editors/W_SettingsListEntry_KBMBinding','Editors/W_SettingsListEntry_Missing','Editors/W_SettingsListEntry_Scalar','Editors/W_SettingsListEntry_SubCollection','Editors/W_SettingsRotator','Extensions/Enum/W_EnumOptionDetailsEntry','Extensions/Enum/W_EnumOptionExtension')){
            $relativeSecondary='Content/UI/Settings/'+$secondary+'.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$copy=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original settings editor family required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($copy));Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        }
        foreach($tool in @('generate_settings_editor_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $stage 'Plugins/GameFeatures/ShooterCore/Content/UserInterface/ScoreBoard/W_SB_TeamStat.uasset')
    }
    if($Kind -eq 'foundationwidgets'){
        foreach($secondary in @('LoadingScreen/W_LoadingScreenReasonDebugText','LoadingScreen/W_LoadingScreen_Host','Widgets/W_AspectImageWithBlur','Widgets/W_ProgressSpinner')){
            $relativeSecondary='Content/UI/Foundation/'+$secondary+'.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$copy=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original foundation widget family required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($copy));Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $source;Add-HeroHash $backup
        }
        foreach($tool in @('generate_foundation_widget_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py','generate_message_widget_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'boundaction'){
        foreach($tool in @('generate_bound_action_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $stage 'Source/LyraGame/UI/Common/LyraBoundActionButton.cpp')
    }
    if($Kind -eq 'experiencetile'){
        foreach($tool in @('generate_experience_tile_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $stage 'Plugins/GameFeatures/ShooterCore/Content/UserInterface/ScoreBoard/W_SB_TeamStat.uasset')
    }
    if($Kind -eq 'menubuttons'){
        foreach($name in @('W_LyraTileButton','W_LyraMenuButton_Modal','W_LyraArrowButton')){
            $secondary='Content/UI/Menu/'+$name+'.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $secondary;$copy=Join-Path $stage $secondary
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh menu/tile and inherited child assets required'}
            Add-HeroHash $source
            if($name -eq 'W_LyraTileButton'){$backup=Join-Path "$output/PreviousAssets" ($name+'.uasset');Copy-Item -LiteralPath $copy -Destination $backup;Add-HeroHash $backup}else{Add-HeroHash $copy}
        }
        foreach($tool in @('generate_menu_button_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        foreach($dependency in @('Content/UEPValidation/BP_FoundationButtonsProbe.uasset','Plugins/GameFeatures/ShooterCore/Content/UserInterface/ScoreBoard/W_SB_TeamStat.uasset')){Add-HeroHash (Join-Path $stage $dependency)}
    }
    if($Kind -eq 'foundationbuttons'){
        foreach($secondary in @('UI/Foundation/Buttons/W_LyraButtonTab','UI/Foundation/TabbedView/W_HorizontalTabList')){
            $relativeSecondary='Content/'+$secondary+'.uasset';$originalSecondary=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$stageSecondary=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $originalSecondary).Hash -ne (Get-FileHash -LiteralPath $stageSecondary).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original foundation button/tab family required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($stageSecondary));Copy-Item -LiteralPath $stageSecondary -Destination $backup;Add-HeroHash $originalSecondary;Add-HeroHash $backup
        }
        foreach($tool in @('generate_foundation_button_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'macroclosure'){
        $secondary='Plugins/GameFeatures/ShooterCore/Content/Blueprint/Macros/BPML_VFXMacros.uasset';$originalSecondary=Join-Path (Split-Path $marker.source -Parent) $secondary;$stageSecondary=Join-Path $stage $secondary
        if((Get-FileHash -LiteralPath $originalSecondary).Hash -ne (Get-FileHash -LiteralPath $stageSecondary).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Original VFX macro definition required'}
        Add-HeroHash $originalSecondary;Add-HeroHash $stageSecondary
        foreach($tool in @('generate_macro_closure_probe.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $repo '.build/LyraValidation/BlueprintPython/20261012-audit/blueprints.json')
    }
    if($Kind -eq 'shootereqs'){
        foreach($secondary in @('Context/EQS_Context_TargetEnemy','Context/EQS_Context_WeaponCheck','Generator/EQS_GetAllEnemy')){
            $relativeSecondary='Plugins/GameFeatures/ShooterCore/Content/Bot/EQS/'+$secondary+'.uasset';$originalSecondary=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$stageSecondary=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $originalSecondary).Hash -ne (Get-FileHash -LiteralPath $stageSecondary).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original shooter EQS family required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($stageSecondary));Copy-Item -LiteralPath $stageSecondary -Destination $backup;Add-HeroHash $originalSecondary;Add-HeroHash $backup
        }
        foreach($tool in @('generate_shooter_eqs_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'shooterai'){
        foreach($secondary in @('Bot/BT/BTDecorator_AllowedToFire','Bot/Services/BTS_CheckAmmo','Bot/Services/BTS_ReloadWeapon','Bot/Services/BTS_SetFocus','Bot/Services/BTS_Shoot')){
            $relativeSecondary='Plugins/GameFeatures/ShooterCore/Content/'+$secondary+'.uasset';$originalSecondary=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$stageSecondary=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $originalSecondary).Hash -ne (Get-FileHash -LiteralPath $stageSecondary).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original shooter AI service/decorator family required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($stageSecondary));Copy-Item -LiteralPath $stageSecondary -Destination $backup;Add-HeroHash $originalSecondary;Add-HeroHash $backup
        }
        foreach($tool in @('generate_shooter_ai_assets.py','generate_accolade_widget_assets.py','generate_small_burst_cue_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        foreach($relativeChild in @('Plugins/GameFeatures/ShooterCore/Content/Bot/B_AI_Controller_LyraShooter_Passive.uasset','Plugins/GameFeatures/ShooterCore/Content/ControlPoint/AI/B_AI_Controller_LyraShooter_ControlPoint.uasset')){Add-HeroHash (Join-Path $stage $relativeChild)}
    }
    if($Kind -eq 'gamephases'){
        foreach($secondary in @('Phase_Playing','Phase_PostGame')){
            $relativeSecondary='Plugins/GameFeatures/ShooterCore/Content/Experiences/Phases/'+$secondary+'.uasset';$originalSecondary=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$stageSecondary=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $originalSecondary).Hash -ne (Get-FileHash -LiteralPath $stageSecondary).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original phase family required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($stageSecondary));Copy-Item -LiteralPath $stageSecondary -Destination $backup;Add-HeroHash $originalSecondary;Add-HeroHash $backup
        }
        foreach($tool in @('generate_game_phase_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'eliminationscore'){
        foreach($tool in @('generate_elimination_score_assets.py','generate_accolade_widget_assets.py','generate_message_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'controlpointwidgets'){
        foreach($secondary in @('W_ControlPointMarker','W_ControlPointStatusWidget')){
            $relativeSecondary='Plugins/GameFeatures/ShooterCore/Content/ControlPoint/UI/'+$secondary+'.uasset';$originalSecondary=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$stageSecondary=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $originalSecondary).Hash -ne (Get-FileHash -LiteralPath $stageSecondary).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original CP widget family required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($stageSecondary));Copy-Item -LiteralPath $stageSecondary -Destination $backup;Add-HeroHash $originalSecondary;Add-HeroHash $backup
        }
        foreach($tool in @('generate_control_point_widget_assets.py','generate_accolade_widget_assets.py','generate_scoreboard_style_assets.py','generate_message_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'scoreboardstyle'){
        foreach($secondary in @('ControlPoint/UI/W_ScoreBoard_HeaderRow_CP','Elimination/UI/W_ScoreBoard_HeaderRow_EliminationMode','ControlPoint/UI/W_MatchScoreBoard_CP','Elimination/UI/W_MatchScoreBoard_Elimination')){
            $relativeSecondary='Plugins/GameFeatures/ShooterCore/Content/'+$secondary+'.uasset';$originalSecondary=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$stageSecondary=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $originalSecondary).Hash -ne (Get-FileHash -LiteralPath $stageSecondary).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original scoreboard style/board family required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($stageSecondary));Copy-Item -LiteralPath $stageSecondary -Destination $backup;Add-HeroHash $originalSecondary;Add-HeroHash $backup
        }
        foreach($tool in @('generate_scoreboard_style_assets.py','generate_accolade_widget_assets.py','generate_message_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'scoreboardlist'){
        $secondary='Plugins/GameFeatures/ShooterCore/Content/UserInterface/ScoreBoard/W_UserConnectionStatus.uasset';$originalSecondary=Join-Path (Split-Path $marker.source -Parent) $secondary;$stageSecondary=Join-Path $stage $secondary
        if((Get-FileHash -LiteralPath $originalSecondary).Hash -ne (Get-FileHash -LiteralPath $stageSecondary).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original scoreboard connection/absent Overlay required'}
        Copy-Item -LiteralPath $stageSecondary -Destination "$output/PreviousAssets/connection-before.uasset";Add-HeroHash $originalSecondary;Add-HeroHash "$output/PreviousAssets/connection-before.uasset"
        foreach($tool in @('generate_scoreboard_list_assets.py','generate_accolade_widget_assets.py','generate_message_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'scoreboardrows'){
        foreach($secondary in @('UserInterface/ScoreBoard/PlayerRow/W_SB_PlayerName','UserInterface/ScoreBoard/PlayerRow/W_SB_PlayerIcon','UserInterface/ScoreBoard/PlayerRow/W_SB_PlayerStat','ControlPoint/UI/W_SB_PlayerRow_CP','Elimination/UI/W_SB_PlayerRow_TDM')){
            $relativeSecondary='Plugins/GameFeatures/ShooterCore/Content/'+$secondary+'.uasset';$originalSecondary=Join-Path (Split-Path $marker.source -Parent) $relativeSecondary;$stageSecondary=Join-Path $stage $relativeSecondary
            if((Get-FileHash -LiteralPath $originalSecondary).Hash -ne (Get-FileHash -LiteralPath $stageSecondary).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $relativeSecondary))){throw 'Fresh original scoreboard family/absent Overlay required'}
            $backup=Join-Path "$output/PreviousAssets" ([IO.Path]::GetFileName($stageSecondary));Copy-Item -LiteralPath $stageSecondary -Destination $backup;Add-HeroHash $originalSecondary;Add-HeroHash $backup
        }
        foreach($tool in @('generate_scoreboard_row_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'eliminationwidgets'){
        $entry='Plugins/GameFeatures/ShooterCore/Content/UserInterface/Notifications/EliminationFeed/W_EliminationFeedEntryWidget.uasset';$originalEntry=Join-Path (Split-Path $marker.source -Parent) $entry;$stageEntry=Join-Path $stage $entry
        if((Get-FileHash -LiteralPath $originalEntry).Hash -ne (Get-FileHash -LiteralPath $stageEntry).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $entry))){throw 'Fresh original elimination entry and absent Overlay required'}
        Copy-Item -LiteralPath $stageEntry -Destination "$output/PreviousAssets/entry-before.uasset";Add-HeroHash $originalEntry;Add-HeroHash "$output/PreviousAssets/entry-before.uasset"
        foreach($tool in @('generate_elimination_widget_assets.py','generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        foreach($relativeDependency in @('Plugins/GameFeatures/ShooterCore/Content/UserInterface/Notifications/EliminationFeed/ElimFeedEntry.uasset','Plugins/GameFeatures/ShooterCore/Content/UserInterface/Notifications/EliminationFeed/EliminationFeedMessage.uasset')){Add-HeroHash (Join-Path $stage $relativeDependency)}
    }
    if($Kind -eq 'accoladewidgets'){
        $toast='Plugins/GameFeatures/ShooterCore/Content/UserInterface/Notifications/Accolades/W_AccoladeToast.uasset';$originalToast=Join-Path (Split-Path $marker.source -Parent) $toast;$stageToast=Join-Path $stage $toast
        if((Get-FileHash -LiteralPath $originalToast).Hash -ne (Get-FileHash -LiteralPath $stageToast).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $toast))){throw 'Fresh original toast and absent Overlay required'}
        Copy-Item -LiteralPath $stageToast -Destination "$output/PreviousAssets/toast-before.uasset";Add-HeroHash $originalToast;Add-HeroHash "$output/PreviousAssets/toast-before.uasset"
        foreach($tool in @('generate_accolade_widget_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        foreach($file in Get-ChildItem -LiteralPath "$stage/Plugins/GameFeatures/ShooterCore/Source/ShooterCoreRuntime" -Recurse -File|Where-Object {$_.Name -like '*Accolade*'}){Add-HeroHash $file.FullName}
        foreach($relativeDependency in @('Plugins/GameFeatures/ShooterCore/Content/Accolades/DT_BasicShooterAccolades.uasset','Plugins/GameFeatures/ShooterCore/Content/Accolades/AccoladeDataRegistry.uasset','Plugins/GameFeatures/ShooterCore/Binaries/Win64/UnrealEditor-ShooterCoreRuntime.dll')){Add-HeroHash (Join-Path $stage $relativeDependency)}
    }
    if($Kind -eq 'accoladerelay'){
        foreach($tool in @('generate_accolade_relay_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        foreach($relativeMacro in @('StandardMacros.uasset','ActorComponentMacros.uasset')){Add-HeroHash (Join-Path $EngineRoot "Engine/Content/EditorBlueprintResources/$relativeMacro")}
    }
    if($Kind -eq 'eliminationfeedrelay'){
        foreach($tool in @('generate_elimination_feed_relay_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        foreach($relativeMacro in @('StandardMacros.uasset','ActorComponentMacros.uasset')){Add-HeroHash (Join-Path $EngineRoot "Engine/Content/EditorBlueprintResources/$relativeMacro")}
    }
    if($Kind -eq 'controlpointhelpers'){
        foreach($tool in @('generate_control_point_helpers_assets.py','generate_small_burst_cue_assets.py','generate_hero_burst_cue_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $stage 'Plugins/GameFeatures/ShooterCore/Content/ControlPoint/B_ControlPointScoring.uasset')
    }
    if($Kind -eq 'cpscoring'){
        foreach($tool in @('generate_cp_scoring_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        foreach($dependency in @('Plugins/GameFeatures/ShooterCore/Content/Game/B_ShooterGameScoring_Base.uasset','Plugins/GameFeatures/ShooterCore/Content/Elimination/B_TeamDeathMatchScoring.uasset')){Add-HeroHash (Join-Path $stage $dependency)}
    }
    if($Kind -eq 'tdmscoring'){
        foreach($tool in @('generate_tdm_scoring_assets.py','generate_footstep_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        foreach($dependency in @('Plugins/GameFeatures/ShooterCore/Content/Game/B_ShooterGameScoring_Base.uasset','Plugins/GameFeatures/ShooterCore/Content/ControlPoint/B_ControlPointScoring.uasset')){Add-HeroHash (Join-Path $stage $dependency)}
    }
    if($Kind -eq 'scoringbase'){
        foreach($tool in @('generate_scoring_base_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        foreach($child in @('Plugins/GameFeatures/ShooterCore/Content/Elimination/B_TeamDeathMatchScoring.uasset','Plugins/GameFeatures/ShooterCore/Content/ControlPoint/B_ControlPointScoring.uasset')){
            $childSource=Join-Path (Split-Path $marker.source -Parent) $child;$childStage=Join-Path $stage $child
            if((Get-FileHash -LiteralPath $childSource).Hash -ne (Get-FileHash -LiteralPath $childStage).Hash){throw 'Original scoring child bytes required'}
            Add-HeroHash $childSource;Add-HeroHash $childStage
        }
    }
    if($Kind -eq 'physicsfields'){
        $secondary='Content/Effects/Physics/B_ShatterSphere.uasset';$source=Join-Path (Split-Path $marker.source -Parent) $secondary;$copy=Join-Path $stage $secondary
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $copy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original shatter sphere/absent Overlay required'}
        Copy-Item -LiteralPath $copy -Destination "$output/PreviousAssets/sphere-before.uasset";Add-HeroHash $source;Add-HeroHash "$output/PreviousAssets/sphere-before.uasset"
        foreach($tool in @('generate_physics_field_assets.py','generate_small_burst_cue_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        Add-HeroHash (Join-Path $EngineRoot 'Engine/Content/EditorResources/FieldNodes/FS_MasterField.uasset')
        foreach($dependency in @('Content/Effects/Physics/ShatterSphere_GeometryCollection.uasset','Content/Effects/Physics/M_GlowyPink.uasset')){Add-HeroHash (Join-Path $stage $dependency);Add-HeroHash (Join-Path (Split-Path $marker.source -Parent) $dependency)}
    }
    if($Kind -eq 'smallburstcues'){
        foreach($secondary in @('Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCN_Weapon_Melee.uasset','Content/GameplayCueNotifies/GCN_Character_Heal.uasset','Plugins/GameFeatures/ShooterCore/Content/Weapons/Grenade/GCN_Grenade_Detonate.uasset')){
            $secondarySource=Join-Path (Split-Path $marker.source -Parent) $secondary;$secondaryCopy=Join-Path $stage $secondary
            if((Get-FileHash -LiteralPath $secondarySource).Hash -ne (Get-FileHash -LiteralPath $secondaryCopy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original small Burst Cues/absent Overlay required'}
            $backup=Join-Path "$output/PreviousAssets" (([IO.Path]::GetFileNameWithoutExtension($secondary))+'-before.uasset')
            Copy-Item -LiteralPath $secondaryCopy -Destination $backup;Add-HeroHash $secondarySource;Add-HeroHash $backup
        }
        foreach($tool in @('generate_small_burst_cue_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'spawningcue'){
        foreach($tool in @('generate_spawning_cue_assets.py','generate_hero_burst_cue_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
        $macroRelative='Plugins/GameFeatures/ShooterCore/Content/Blueprint/Macros/BPML_VFXMacros.uasset'
        Add-HeroHash (Join-Path (Split-Path $marker.source -Parent) $macroRelative);Add-HeroHash (Join-Path $stage $macroRelative)
    }
    if($Kind -eq 'traversalcues'){
        $secondary='Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_Teleporter_Activate.uasset';$secondarySource=Join-Path (Split-Path $marker.source -Parent) $secondary;$secondaryCopy=Join-Path $stage $secondary
        if((Get-FileHash -LiteralPath $secondarySource).Hash -ne (Get-FileHash -LiteralPath $secondaryCopy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $secondary))){throw 'Fresh original teleporter Cue/absent Overlay required'}
        Copy-Item -LiteralPath $secondaryCopy -Destination "$output/PreviousAssets/teleporter-before.uasset";Add-HeroHash $secondarySource;Add-HeroHash "$output/PreviousAssets/teleporter-before.uasset"
        foreach($tool in @('generate_traversal_cue_assets.py','generate_hero_burst_cue_assets.py','generate_dash_selector_assets.py')){Add-HeroHash (Join-Path $repo "Demos/UEPLyraIntegration/Tools/$tool")}
    }
    if($Kind -eq 'heroburstcues'){
        $deathRelative='Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_Death.uasset';$deathSource=Join-Path (Split-Path $marker.source -Parent) $deathRelative;$deathCopy=Join-Path $stage $deathRelative
        if((Get-FileHash -LiteralPath $deathSource).Hash -ne (Get-FileHash -LiteralPath $deathCopy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $deathRelative))){throw 'Fresh original death Cue/absent Overlay required'}
        Copy-Item -LiteralPath $deathCopy -Destination "$output/PreviousAssets/death-before.uasset";Add-HeroHash $deathSource;Add-HeroHash "$output/PreviousAssets/death-before.uasset"
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_hero_burst_cue_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
        $macroRelative='Plugins/GameFeatures/ShooterCore/Content/Blueprint/Macros/BPML_VFXMacros.uasset'
        Add-HeroHash (Join-Path (Split-Path $marker.source -Parent) $macroRelative);Add-HeroHash (Join-Path $stage $macroRelative)
    }
    if($Kind -eq 'characterdamage'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_character_damage_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_message_widget_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'messagewidgets'){
        $waitingRelative='Plugins/GameFeatures/ShooterCore/Content/GameplayCues/W_WaitingForPlayers_Message.uasset'
        $waitingSource=Join-Path (Split-Path $marker.source -Parent) $waitingRelative;$waitingCopy=Join-Path $stage $waitingRelative
        if((Get-FileHash -LiteralPath $waitingSource).Hash -ne (Get-FileHash -LiteralPath $waitingCopy).Hash -or (Test-Path -LiteralPath (Join-Path $overlay $waitingRelative))){throw 'Fresh original waiting widget/absent Overlay required'}
        Copy-Item -LiteralPath $waitingCopy -Destination "$output/PreviousAssets/waiting-before.uasset"
        Add-HeroHash $waitingSource;Add-HeroHash "$output/PreviousAssets/waiting-before.uasset"
    }
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_hero_ability_mixin_assets.py'
    foreach($path in @($PSCommandPath,$script,(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),
        (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/mixin_graph_gates.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/message_payload_graphs.py'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){Add-HeroHash $path}
    if($Kind -eq 'weaponinstance'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_instance_assets.py')}
    if($Kind -eq 'grenadewidget'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_grenade_widget_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'messagewidgets'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_message_widget_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'cuewidgets'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_cue_widget_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
        foreach($relativeDependency in @('Content/GameplayCueNotifies/I_GameplayCueWidget.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_MatchDecided.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_WaitingForPlayers.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/GameplayCues/W_MatchDecided_Message.uasset',
            'Plugins/GameFeatures/ShooterCore/Content/GameplayCues/W_WaitingForPlayers_Message.uasset')){
            $source=Join-Path (Split-Path $marker.source -Parent) $relativeDependency;$target=Join-Path $stage $relativeDependency
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Original Cue family dependency required'}
            Add-HeroHash $source;Add-HeroHash $target
        }
    }
    if($Kind -eq 'footstep'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_footstep_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'weaponfirefx'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_fire_fx_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'weapondecals'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_decals_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'weaponimpacts'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_impacts_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'weaponabilityfire'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_ability_fire_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'generalaudio'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_general_audio_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_audio_math_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'windsystem'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_wind_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'musiccontrols'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_music_manager_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_audio_math_assets.py')
    }
    if($Kind -eq 'weaponaudiomath'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_audio_math_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'weaponfirecues'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_fire_cue_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
        foreach($weapon in @('Pistol','Rifle','Shotgun')){Add-HeroHash (Join-Path (Split-Path $marker.source -Parent) "Plugins/GameFeatures/ShooterCore/Content/Weapons/$weapon/GCN_Weapon_${weapon}_Fire.uasset")}
    }
    if($Kind -eq 'netshooterability'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_netshooter_ability_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
        Add-HeroHash (Join-Path $stage 'Content/Weapons/GA_Weapon_Fire.uasset')
    }
    if($Kind -eq 'netshooteractor'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_netshooter_actor_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'weaponactorhelpers'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_weapon_actor_helpers_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
    if($Kind -eq 'grenadevfx'){
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_grenade_vfx_assets.py')
        Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py')
    }
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
    if($Kind -eq 'explorerstyle'){$arguments+=@('-UEPExplorerCharacterBaseline='+[IO.Path]::GetFullPath($ExplorerCharacterBaseline))}
    if($Kind -in @('controlpointstate','controlpointfeedback')){$arguments+=@('-UEPControlPointHelpersBaseline='+[IO.Path]::GetFullPath($ControlPointHelpersBaseline))}
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Retained hero ability Interface authoring' 240
    $report=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 80
    $expectedEndNodes=if($Kind -eq 'widgetpressed'){3}elseif($Kind -in @('weaponinstance','devicecolor','autorespawnhelpers','autorespawnlisteners','autorespawnevents','autorespawnactivation','characterinventory','characteraudio','characterquickbar','characterloadout','characteroutline','characterteam','characterstencil','characterlifecycle','characterparts','characterhealth','characterinput','characterobserver','characterlistener','characterlegacy','characterready','characterwait','characterpossessed','charactervisibility','characterbeginplay','characterequipmenthide','characterragdoll','characterdeathstarted')){0}else{4}
    if($Kind -in @('explorerstyle','explorercharacters','explorerstate','editorexperiences','lobbybackground','replayruntime','replaybrowser','sessionentry','sessionbrowser','sessionbutton','hostsession','experiencescreen','experiencelist','startuplogin','frontendmenu','menulayers','creditswidgets','diagnosticwidgets','settingsscreens','settingseditors','foundationwidgets','boundaction','experiencetile','menubuttons','foundationbuttons','macroclosure','shootereqs','shooterai','gamephases','eliminationscore','controlpointwidgets','scoreboardstyle','scoreboardlist','scoreboardrows','eliminationwidgets','accoladewidgets','accoladerelay','eliminationfeedrelay','controlpointfeedback','controlpointstate','controlpointhelpers','cpscoring','tdmscoring','scoringbase','physicsfields','smallburstcues','spawningcue','traversalcues','heroburstcues','characterdamage','messagewidgets','cuewidgets','footstep','generalaudio','windsystem','musiccontrols','dashselector','meleehitmontage','grenadewidget','grenadevfx','weaponactorhelpers','weaponfirefx','weapondecals','weaponimpacts','weaponabilityfire','netshooteractor','netshooterability','weaponfirecues','weaponaudiomath')){$expectedEndNodes=0}
    if($report.status -ne 'passed' -or !$report.original_class_defaults_signature_graphs_preserved -or $report.native_end_adapter_nodes -ne $expectedEndNodes -or
       @($report.assets).Count -ne $(if($Kind -eq 'macroclosure'){0}elseif($Kind -eq 'settingseditors'){20}elseif($Kind -in @('replayruntime','foundationbuttons','gamephases','controlpointwidgets')){6}elseif($Kind -in @('explorerstate','foundationwidgets','scoreboardstyle')){10}elseif($Kind -in @('shooterai','scoreboardrows')){12}elseif($Kind -in @('menulayers','diagnosticwidgets','settingsscreens','shootereqs','smallburstcues')){8}elseif($Kind -in @('explorerstyle','explorercharacters','editorexperiences','replaybrowser','experiencelist','startuplogin','creditswidgets','menubuttons','scoreboardlist','eliminationwidgets','accoladewidgets','physicsfields','weaponfirecues','messagewidgets','heroburstcues','traversalcues')){4}elseif($Kind -in @('weaponaudiomath','generalaudio')){3}else{2}) -or $report.runtime_acceptance -or $report.kind -ne $Kind){throw 'Hero ability authoring proof incomplete'}
    if($Kind -eq 'grenadewidget' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or !$report.native_register_restore_passed -or
        $report.new_business_nodes -ne 0 -or $report.whole_grenade_activation_projectile_damage_migrated -or
        ($report.implemented_methods -join ',') -ne 'K2_OnPawnAvatarSet,K2_OnAbilityRemoved' -or
        $report.actual_registered_profile_method_counts.Python -ne 2 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 2 -or
        $report.original_ui_policy.context -ne 'GetOwningActorFromActorInfo' -or $report.original_ui_policy.priority -ne -1 -or
        $report.original_ui_policy.tag -ne 'HUD.Slot.ExtraEquipment' -or !$report.original_ui_policy.removal_unconditional)){
        throw 'Grenade UI original graph/default/native event registration proof incomplete'
    }
    if($Kind -in @('footstep','weaponfirefx','weapondecals') -and (!$report.original_full_cdo_preserved -or !$report.original_business_graphs_preserved_with_dispatch -or
        !$report.native_register_restore_passed -or !$report.original_retriggerable_delay_node_reused -or !$report.native_delay_uuid_preserved -or
        !$report.cleanup_tests_validity_not_active -or $report.native_delay_seconds -ne 3 -or $report.transport_nodes -ne 3 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 2 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 2)){throw 'Weapon fire FX original latent/dispatch proof incomplete'}
    if($Kind -eq 'explorerstyle'){
        if(!$report.original_all_graphs_and_native_unarmed_payload_unchanged -or !$report.only_mixin_profile_data_assets_changed -or $report.whole_characters_migrated -or @($report.fixtures).Count -ne 2){throw 'Original Explorer style graphs/native typed caller proof required'}
        foreach($key in @('hero','pawn')){if($report.characters.$key.method_counts.Python -ne 8 -or $report.characters.$key.method_counts.BlueprintFallback -ne 8){throw 'Complete eight-method Explorer family required'}}
    }
    if($Kind -eq 'explorercharacters'){
        if(!$report.original_five_helper_signatures_and_all_graphs_cdos_guids_preserved -or !$report.original_native_empty_loadout_unarmed_layer_payload_preserved -or $report.whole_characters_migrated -or @($report.fixtures).Count -ne 2){throw 'Original Explorer helper graph and typed native callers required'}
        foreach($key in @('hero','pawn')){if($report.characters.$key.original_nodes -ne @{hero=193;pawn=212}[$key] -or $report.characters.$key.transport_nodes -ne 3 -or $report.characters.$key.interface_nodes -ne 5 -or $report.characters.$key.method_counts.Python -ne 5 -or $report.characters.$key.method_counts.BlueprintFallback -ne 5){throw 'Exact five-helper Explorer Profile families required'}}
    }
    if($Kind -eq 'explorerstate'){if(!$report.original_native_statetree_event_transition_abi_preserved -or !$report.original_native_ai_move_options_and_result_callback_order_preserved -or !$report.original_native_two_delay_nodes_and_completion_flags_preserved -or !$report.original_get_player_index_zero_and_null_location_diagnostic_preserved -or @($report.nodes.PSObject.Properties).Count -ne 5){throw 'Complete original Explorer StateTree native API/payload and Profile proof required'}}
    if($Kind -eq 'editorexperiences'){if(!$report.original_native_empty_bundle_primary_async_and_expose_before_beginplay_spawn_preserved -or !$report.original_additional_prepend_hidden_showall_and_accumulating_portal_cache_semantics_preserved -or !$report.original_native_widget_delay_color_spinner_and_offline_request_payload_preserved -or !$report.original_local_player_overlap_and_current_experience_afterpush_preserved -or $report.widgets.list.original_nodes -ne 42 -or $report.widgets.list.transport_nodes -ne 12 -or $report.widgets.list.method_counts.Python -ne 2 -or $report.widgets.portal.original_nodes -ne 38 -or $report.widgets.portal.transport_nodes -ne 26 -or $report.widgets.portal.method_counts.Python -ne 5){throw 'Complete original default-editor list/portal/native payload and Profile proof required'}}
    if($Kind -eq 'lobbybackground'){if(!$report.original_cdo_scs_templates_public_signatures_guids_graphs_preserved -or !$report.original_native_primary_async_soft_level_transform_and_weak_delegates_preserved -or !$report.original_native_half_second_delay_then_current_task_unregister_preserved -or !$report.original_loaded_shown_failure_messages_and_loading_reason_preserved -or $report.original_graph_nodes -ne 42 -or $report.transport_nodes -ne 46 -or $report.interface_nodes -ne 5 -or $report.method_counts.Python -ne 10 -or $report.method_counts.BlueprintFallback -ne 10){throw 'Complete original lobby streaming/task/native-delay and Profile proof required'}}
    if($Kind -eq 'replayruntime'){
        if(!$report.original_native_component_beginplay_and_widget_creation_payload_preserved -or !$report.original_native_umg_tick_and_current_length_getter_order_preserved -or !$report.original_mouse_geometry_pointer_and_handled_reply_entirely_native -or !$report.original_unclamped_ratio_and_native_zero_divide_diagnostic_preserved -or $report.widgets.handler.original_nodes -ne 14 -or $report.widgets.handler.transport_nodes -ne 5 -or $report.widgets.handler.method_counts.Python -ne 1 -or $report.widgets.hud.original_nodes -ne 2 -or $report.widgets.hud.transport_nodes -ne 4 -or $report.widgets.hud.method_counts.Python -ne 1 -or $report.widgets.scrub.original_nodes -ne 19 -or $report.widgets.scrub.transport_nodes -ne 8 -or $report.widgets.scrub.method_counts.Python -ne 2){throw 'Complete replay runtime native lifecycle/opaque pointer/reply and Profile proof required'}
    }
    if($Kind -eq 'replaybrowser'){
        if(!$report.original_native_do_once_query_and_result_identity_order_preserved -or !$report.original_native_localized_duration_text_and_confirmation_payloads_preserved -or !$report.original_confirmed_only_play_uses_current_entry_after_dialog -or $report.widgets.browser.original_nodes -ne 21 -or $report.widgets.browser.transport_nodes -ne 27 -or $report.widgets.browser.method_counts.Python -ne 6 -or $report.widgets.browser.method_counts.BlueprintFallback -ne 6 -or $report.widgets.entry.original_nodes -ne 16 -or $report.widgets.entry.transport_nodes -ne 16 -or $report.widgets.entry.method_counts.Python -ne 3 -or $report.widgets.entry.method_counts.BlueprintFallback -ne 3){throw 'Complete original replay query/text/confirmation and Profile proof required'}
    }
    if($Kind -eq 'sessionentry'){
        if(!$report.original_cdo_tree_animations_public_signatures_guids_and_graphs_preserved -or !$report.original_native_five_text_payload_and_unwired_mapname_string_preserved -or !$report.original_primary_load_and_spinner_loading_macro_order_preserved -or !$report.original_join_binding_and_unbind_then_pop_before_bool_gate_preserved -or !$report.original_failure_ftext_system_message_preserved -or !$report.shared_macro_definition_unchanged -or $report.original_graph_nodes -ne 62 -or $report.transport_nodes -ne 38 -or $report.interface_nodes -ne 5 -or $report.method_counts.Python -ne 8 -or $report.method_counts.BlueprintFallback -ne 8 -or $report.new_business_nodes -ne 0){throw 'Original session entry native FText/async/join teardown and complete Profiles required'}
    }
    if($Kind -eq 'sessionbrowser'){
        if(!$report.original_cdo_tree_animations_public_signatures_guids_and_graphs_preserved -or !$report.original_native_do_once_lock_shared_across_profiles_and_reset_preserved -or !$report.original_create_store_bind_find_order_and_weak_completion_delegate_preserved -or !$report.original_failed_search_ftext_system_message_before_results_gate_preserved -or !$report.original_empty_results_visibility_list_focus_unlock_order_preserved -or $report.original_graph_nodes -ne 62 -or $report.transport_nodes -ne 27 -or $report.interface_nodes -ne 5 -or $report.method_counts.Python -ne 6 -or $report.method_counts.BlueprintFallback -ne 6 -or $report.new_business_nodes -ne 0){throw 'Original browser lock/search/FText order and complete Profiles required'}
    }
    if($Kind -eq 'sessionbutton'){
        if(!$report.original_cdo_tree_animations_public_signatures_guids_and_graphs_preserved -or !$report.original_five_ftext_setter_graph_entirely_native_and_unmixed -or !$report.original_native_latent_click_clock_start_time_then_sound_and_finished_preserved -or !$report.original_six_target_material_reset_and_unused_label_getter_order_preserved -or !$report.original_only_border_disabled_and_null_texture_ignored_semantics_preserved -or $report.original_graph_nodes -ne 89 -or $report.transport_nodes -ne 53 -or $report.interface_nodes -ne 5 -or $report.method_counts.Python -ne 13 -or $report.method_counts.BlueprintFallback -ne 13 -or $report.new_business_nodes -ne 0){throw 'Original session button FText/native clock/material semantics and complete Profile proof required'}
    }
    if($Kind -eq 'hostsession'){
        if(!$report.original_cdo_tree_animations_public_signatures_guids_and_graph_partitions_preserved -or !$report.original_native_localized_mode_and_bot_texts_preserved -or !$report.original_native_login_spinner_loading_macro_and_submit_binding_payloads_preserved -or !$report.original_completion_unbind_before_bool_gate_and_opaque_error_message_preserved -or !$report.original_request_modes_bot_zero_override_and_null_result_preserved -or !$report.shared_macro_definition_unchanged -or $report.original_graph_nodes -ne 75 -or $report.transport_nodes -ne 66 -or $report.interface_nodes -ne 5 -or $report.method_counts.Python -ne 12 -or $report.method_counts.BlueprintFallback -ne 12 -or $report.new_business_nodes -ne 0){throw 'Original host text/native async binding/order and complete Profile family required'}
    }
    if($Kind -eq 'experiencescreen'){
        if(!$report.original_cdo_tree_animations_public_signatures_guids_and_graphs_preserved -or !$report.original_native_login_push_factories_and_payloads_preserved -or !$report.original_async_preparation_macro_completed_before_request_and_submit_preserved -or !$report.original_browse_both_results_push_browser_quick_success_only_and_hidden_spinner_preserved -or !$report.original_native_typed_request_payload_builder_preserved -or !$report.shared_macro_definition_unchanged -or $report.original_graph_nodes -ne 42 -or $report.transport_nodes -ne 49 -or $report.interface_nodes -ne 5 -or $report.method_counts.Python -ne 10 -or $report.method_counts.BlueprintFallback -ne 10 -or $report.new_business_nodes -ne 0){throw 'Original selection native async ordering/payloads and complete Profile family required'}
    }
    if($Kind -eq 'experiencelist'){
        if(!$report.original_cdos_trees_public_signatures_guids_and_graph_partitions_preserved -or !$report.original_native_text_focus_reply_delegates_and_async_load_payloads_preserved -or !$report.original_default_prepend_filter_and_accumulating_widget_cache_semantics_preserved -or !$report.retained_unwired_tile_preconstruct_and_dispatcher_signature_graphs -or $report.new_business_nodes -ne 0 -or @($report.widgets.PSObject.Properties).Count -ne 2){throw 'Original experience list/entry opaque native IO and cache semantics required'}
        foreach($name in @('tile','list')){if($report.widgets.($name).original_graph_nodes -ne @{tile=23;list=68}[$name] -or $report.widgets.($name).transport_nodes -ne @{tile=23;list=42}[$name] -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne @{tile=3;list=6}[$name] -or $report.widgets.($name).method_counts.BlueprintFallback -ne @{tile=3;list=6}[$name]){throw 'Complete experience list/entry Profile family required'}}
    }
    if($Kind -eq 'startuplogin'){
        if(!$report.original_cdos_trees_public_signatures_guids_and_graph_partitions_preserved -or !$report.original_native_key_arrays_local_defaults_and_delegate_payloads_preserved -or !$report.original_localized_login_text_and_callback_binding_name_guid_preserved -or !$report.only_internal_listener_or_refresh_frame_hasdefaults_may_move -or $report.new_business_nodes -ne 0 -or @($report.widgets.PSObject.Properties).Count -ne 2){throw 'Complete startup/login native opaque IO and original signature proof required'}
        foreach($name in @('startup','login')){if($report.widgets.($name).original_graph_nodes -ne @{startup=35;login=58}[$name] -or $report.widgets.($name).transport_nodes -ne @{startup=39;login=45}[$name] -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne 7 -or $report.widgets.($name).method_counts.BlueprintFallback -ne 7){throw 'Original complete startup/login Profile family required'}}
    }
    if($Kind -eq 'frontendmenu'){
        if(!$report.original_cdo_tree_animations_public_signatures_const_focus_guids_and_graphs_preserved -or !$report.original_four_async_menu_classes_layer_tags_input_suspension_and_native_prompts_preserved -or !$report.original_confirmed_quit_and_identity_logout_success_order_payloads_preserved -or !$report.original_unused_destroy_player_true_logout_node_retained_unconnected -or $report.original_graph_nodes -ne 34 -or $report.transport_nodes -ne 53 -or $report.interface_nodes -ne 5 -or $report.method_counts.Python -ne 11 -or $report.method_counts.BlueprintFallback -ne 11 -or $report.new_business_nodes -ne 0){throw 'Original frontend async prompt/session/quit and complete Profile family required'}
    }
    if($Kind -eq 'menulayers'){
        if(!$report.original_cdos_widget_trees_public_signatures_const_focus_node_guids_and_graphs_preserved -or !$report.original_layer_tag_stack_order_and_names_preserved -or !$report.original_async_settings_beforepush_deactivation_and_confirmation_localized_prompt_preserved -or !$report.original_confirmed_frontend_map_asset_experience_name_and_absolute_travel_payload_preserved -or !$report.original_quit_input_reset_preference_and_platform_restrictions_preserved -or $report.new_business_nodes -ne 0 -or @($report.widgets.PSObject.Properties).Count -ne 4){throw 'Original menu/layer/native modal/confirmation/terminal proof required'}
        foreach($name in @('layout','menu','close','spinner')){if($report.widgets.($name).original_graph_nodes -ne @{layout=10;menu=26;close=5;spinner=3}[$name] -or $report.widgets.($name).transport_nodes -ne @{layout=4;menu=28;close=4;spinner=5}[$name] -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne @{layout=1;menu=6;close=1;spinner=1}[$name] -or $report.widgets.($name).method_counts.BlueprintFallback -ne @{layout=1;menu=6;close=1;spinner=1}[$name]){throw 'Complete menu/layer Profile family required'}}
    }
    if($Kind -eq 'creditswidgets'){
        if(!$report.original_cdos_widget_trees_animations_public_signatures_node_guids_and_partitions_preserved -or !$report.original_one_second_delay_and_point01_looping_timer_delegate_handle_clear_nodes_retained -or !$report.original_timer_max_once_per_frame_false -or !$report.original_rich_string_templates_and_native_string_to_text_setter_preserved -or !$report.original_no_deactivation_or_destruct_timer_cleanup_added -or !$report.source_visibility_compares_only_collapsed_and_const_null_focus_preserved -or !$report.only_compiler_internal_timer_frame_hasdefaults_flag_may_move -or $report.new_business_nodes -ne 0 -or @($report.widgets.PSObject.Properties).Count -ne 2){throw 'Original credits native delay/timer/rich-text/public-signature proof required'}
        foreach($name in @('credits','bar')){if($report.widgets.($name).original_graph_nodes -ne @{credits=54;bar=13}[$name] -or $report.widgets.($name).transport_nodes -ne @{credits=39;bar=13}[$name] -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne @{credits=7;bar=3}[$name] -or $report.widgets.($name).method_counts.BlueprintFallback -ne @{credits=7;bar=3}[$name]){throw 'Complete credits Profile family required'}}
    }
    if($Kind -eq 'diagnosticwidgets'){
        if(!$report.original_cdos_widget_trees_signatures_node_guids_and_native_format_node_partitions_preserved -or !$report.original_numeric_grouping_rounding_fractional_digits_and_ftext_formats_preserved -or !$report.original_missing_user_localized_status_and_name_format_preserved -or !$report.performance_graph_native_update_before_fetch_and_numeric_scale_preserved -or !$report.native_user_subsystem_getters_context_game_and_int32_player_display_number_preserved -or $report.new_business_nodes -ne 0 -or @($report.widgets.PSObject.Properties).Count -ne 4){throw 'Original diagnostic widget/native formatting/sampling/user proof required'}
        foreach($name in @('graph','text','build','watermark')){if($report.widgets.($name).original_graph_nodes -ne @{graph=22;text=23;build=6;watermark=24}[$name] -or $report.widgets.($name).transport_nodes -ne @{graph=14;text=14;build=7;watermark=14}[$name] -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne @{graph=2;text=2;build=1;watermark=1}[$name] -or $report.widgets.($name).method_counts.BlueprintFallback -ne @{graph=2;text=2;build=1;watermark=1}[$name]){throw 'Complete diagnostic widget Profile family required'}}
    }
    if($Kind -eq 'settingsscreens'){
        if(!$report.original_cdos_widget_trees_animations_signatures_guids_and_graphs_preserved -or !$report.original_async_soft_class_input_suspension_afterpush_and_interface_payload_paths_retained -or !$report.original_native_tab_descriptor_display_name_icon_brush_and_button_class_preserved -or !$report.original_const_gamma_focus_signature_preserved -or !$report.settings_apply_save_reset_and_native_calibration_cpp_unchanged -or $report.new_business_nodes -ne 0 -or @($report.widgets.PSObject.Properties).Count -ne 4){throw 'Original settings screen/native async/localization/calibration proof required'}
        foreach($name in @('gamma','hdr','screen','panel')){if($report.widgets.($name).original_graph_nodes -ne @{gamma=3;hdr=7;screen=37;panel=3}[$name] -or $report.widgets.($name).transport_nodes -ne @{gamma=5;hdr=8;screen=26;panel=4}[$name] -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne @{gamma=1;hdr=2;screen=5;panel=1}[$name] -or $report.widgets.($name).method_counts.BlueprintFallback -ne @{gamma=1;hdr=2;screen=5;panel=1}[$name]){throw 'Complete settings screen Profile family required'}}
    }
    if($Kind -eq 'settingseditors'){
        if(!$report.original_cdos_widget_trees_animations_signatures_guids_and_graphs_preserved -or !$report.native_action_collection_labels_and_details_text_before_boolean_gate_preserved -or !$report.native_enum_count_index_and_localized_text_factory_adapters -or !$report.original_empty_background_delegate_body_retained -or !$report.rotator_count_remains_invocation_local -or !$report.settings_value_read_write_cpp_unchanged -or !$report.fixture.stage_only -or (Get-FileHash -LiteralPath $report.fixture.asset).Hash -ne $report.fixture.sha256 -or $report.new_business_nodes -ne 0 -or @($report.widgets.PSObject.Properties).Count -ne 10){throw 'Original settings editor/native localization/model proof required'}
        foreach($name in @('background','action','discrete','keyboard','missing','scalar','collection','rotator','details','extension')){if($report.widgets.($name).original_graph_nodes -ne @{background=12;action=20;discrete=14;keyboard=14;missing=8;scalar=24;collection=17;rotator=37;details=13;extension=15}[$name] -or $report.widgets.($name).transport_nodes -ne @{background=10;action=13;discrete=19;keyboard=13;missing=8;scalar=21;collection=13;rotator=12;details=4;extension=15}[$name] -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne @{background=2;action=3;discrete=4;keyboard=3;missing=2;scalar=5;collection=3;rotator=3;details=1;extension=1}[$name] -or $report.widgets.($name).method_counts.BlueprintFallback -ne @{background=2;action=3;discrete=4;keyboard=3;missing=2;scalar=5;collection=3;rotator=3;details=1;extension=1}[$name]){throw 'Complete settings editor Profile family required'}}
    }
    if($Kind -eq 'foundationwidgets'){
        if(!$report.original_cdos_widget_trees_animations_signatures_guids_and_graphs_preserved -or !$report.native_localized_reason_format_and_setter_preserved_without_ftext_marshalling -or !$report.loading_construct_factory_delegate_and_original_absence_of_destruct_unbind_preserved -or $report.new_business_nodes -ne 0 -or @($report.widgets.PSObject.Properties).Count -ne 5){throw 'Original foundation widget/native reason/loading lifetime proof required'}
        foreach($name in @('dialog','reason','loading','aspect','spinner')){if($report.widgets.($name).original_graph_nodes -ne @{dialog=3;reason=8;loading=15;aspect=8;spinner=4}[$name] -or $report.widgets.($name).transport_nodes -ne @{dialog=4;reason=9;loading=4;aspect=6;spinner=4}[$name] -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne 1 -or $report.widgets.($name).method_counts.BlueprintFallback -ne 1){throw 'Complete foundation widget Profile family required'}}
    }
    if($Kind -eq 'boundaction'){
        if(!$report.original_cdos_widget_trees_animations_signatures_guids_and_graphs_preserved -or !$report.native_construct_destruct_parent_calls_input_subsystem_factories_and_add_remove_delegates_retained -or !$report.native_latent_play_time_range_and_finished_retained -or !$report.source_break_make_brush_omitted_fields_reset_to_defaults -or $report.original_graph_nodes -ne 82 -or $report.transport_nodes -ne 45 -or $report.interface_nodes -ne 5 -or $report.method_counts.Python -ne 11 -or $report.method_counts.BlueprintFallback -ne 11 -or $report.new_business_nodes -ne 0){throw 'Original bound-action CommonInput/brush/latent/parent proof required'}
    }
    if($Kind -eq 'experiencetile'){
        if(!$report.three_ftext_setter_graph_remains_entirely_native -or !$report.original_cdos_widget_trees_animations_signatures_guids_and_graphs_preserved -or !$report.native_ftext_transport_preserved -or !$report.native_latent_play_time_range_and_finished_retained -or !$report.source_click_sound_return_unwired_and_game_instance_clear_preserved -or !$report.only_border_disable_parameter_preserved -or $report.original_graph_nodes -ne 78 -or $report.transport_nodes -ne 58 -or $report.interface_nodes -ne 5 -or $report.method_counts.Python -ne 14 -or $report.method_counts.BlueprintFallback -ne 14 -or !$report.fixture.stage_only -or (Get-FileHash -LiteralPath $report.fixture.asset).Hash -ne $report.fixture.sha256 -or $report.new_business_nodes -ne 0){throw 'Original experience tile/text/latent/source-asymmetry proof required'}
    }
    if($Kind -eq 'menubuttons'){
        if(!$report.original_cdos_widget_trees_animations_signatures_guids_and_graphs_preserved -or !$report.native_ftext_transport_preserved -or !$report.native_latent_play_time_range_and_finished_retained -or !$report.empty_menu_construct_stays_unconnected -or @($report.inherited_modal_arrow_asset_bytes_unchanged.PSObject.Properties).Count -ne 2 -or !$report.fixture.stage_only -or (Get-FileHash -LiteralPath $report.fixture.asset).Hash -ne $report.fixture.sha256 -or $report.new_business_nodes -ne 0){throw 'Original menu/tile/native latent/text proof required'}
        foreach($name in @('menu','tile')){if($report.widgets.($name).original_graph_nodes -ne @{menu=130;tile=75}[$name] -or $report.widgets.($name).transport_nodes -ne 62 -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne 15 -or $report.widgets.($name).method_counts.BlueprintFallback -ne 15){throw 'Complete menu/tile Profile family required'}}
    }
    if($Kind -eq 'foundationbuttons'){
        if(!$report.original_cdos_widget_trees_animations_ftext_parent_calls_delegates_and_graphs_preserved -or !$report.native_text_forwarders_preserve_ftext_without_python_marshalling -or !$report.empty_action_complete_stays_unconnected -or $report.new_business_nodes -ne 0){throw 'Original foundation button/tab/tree/parent/text proof required'}
        foreach($name in @('base','tab','tabs')){if($report.widgets.($name).original_graph_nodes -ne @{base=65;tab=30;tabs=70}[$name] -or $report.widgets.($name).transport_nodes -ne @{base=45;tab=20;tabs=17}[$name] -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne @{base=11;tab=5;tabs=4}[$name] -or $report.widgets.($name).method_counts.BlueprintFallback -ne @{base=11;tab=5;tabs=4}[$name]){throw 'Complete foundation button/tab Profile family required'}}
    }
    if($Kind -eq 'macroclosure' -and (!$report.original_macro_definition_assets_and_graphs_unchanged -or !$report.original_macro_callsite_census_matches -or !$report.original_unused_specific_mesh_macro_has_no_live_callsite -or $report.original_audio_macro_graph_nodes -ne 32 -or $report.original_vfx_macro_graph_nodes -ne 9 -or @($report.callsites).Count -ne 9 -or @($report.current_consumers.PSObject.Properties).Count -ne 9 -or !$report.fixture.stage_only -or (Get-FileHash -LiteralPath $report.fixture.asset).Hash -ne $report.fixture.sha256 -or $report.new_business_nodes -ne 0)){throw 'Exact macro definition/consumer closure/probe proof required'}
    if($Kind -eq 'shootereqs'){
        if(!$report.original_cdos_return_types_local_scopes_node_guids_world_queries_team_and_native_generator_graphs_preserved -or !$report.absent_target_leaves_location_out_parameter_unwritten -or $report.native_eqs_scheduler_replaced -or $report.new_business_nodes -ne 0 -or @($report.fixtures).Count -ne 4){throw 'Original EQS context/generator proof required'}
        foreach($name in @('points','enemy','weapon','enemies')){if($report.contexts.($name).original_graph_nodes -ne @{points=16;enemy=8;weapon=35;enemies=17}[$name] -or $report.contexts.($name).transport_nodes -ne $(if($name -eq 'enemies'){4}elseif($name -eq 'enemy'){6}else{5}) -or $report.contexts.($name).interface_nodes -ne 5 -or $report.contexts.($name).method_counts.Python -ne 1 -or $report.contexts.($name).method_counts.BlueprintFallback -ne 1){throw 'Complete EQS Profile family required'}}
        foreach($fixture in $report.fixtures){if(!$fixture.stage_only -or (Get-FileHash -LiteralPath $fixture.asset).Hash -ne $fixture.sha256){throw 'Current stage-only EQS query required'}}
    }
    if($Kind -eq 'shooterai'){
        if(!$report.original_cdos_templates_scoped_variables_node_guids_bt_schedules_async_factories_health_delegates_parent_calls_and_graphs_preserved -or !$report.passive_empty_overrides_and_cp_parent_forwarder_retained -or $report.new_business_nodes -ne 0 -or @($report.fixtures).Count -ne 2){throw 'Original AI tree/async/parent/inheritance proof required'}
        foreach($name in @('controller','allowed','ammo','reload','focus','shoot')){if($report.nodes.($name).original_graph_nodes -ne @{controller=33;allowed=3;ammo=14;reload=2;focus=11;shoot=62}[$name] -or $report.nodes.($name).transport_nodes -ne @{controller=18;allowed=5;ammo=4;reload=4;focus=4;shoot=9}[$name] -or $report.nodes.($name).interface_nodes -ne 5 -or $report.nodes.($name).method_counts.Python -ne @{controller=4;allowed=1;ammo=1;reload=1;focus=1;shoot=2}[$name] -or $report.nodes.($name).method_counts.BlueprintFallback -ne @{controller=4;allowed=1;ammo=1;reload=1;focus=1;shoot=2}[$name]){throw 'Complete shooter AI Profile family required'}}
        foreach($fixture in $report.fixtures){if(!$fixture.stage_only -or (Get-FileHash -LiteralPath $fixture.asset).Hash -ne $fixture.sha256){throw 'Current stage-only AI fixture required'}}
    }
    if($Kind -eq 'gamephases'){
        if(!$report.original_cdos_gas_parent_tags_latent_uuids_multicast_cosmetic_and_custom_thunk_message_graphs_preserved -or !$report.original_default_durations_preserved -or !$report.unconnected_postgame_end_remains_unconnected -or $report.new_business_nodes -ne 0 -or !$report.fixture.stage_only -or (Get-FileHash -LiteralPath $report.fixture.asset).Hash -ne $report.fixture.sha256){throw 'Original phase/GAS/latent/message fixture proof required'}
        foreach($name in @('warmup','playing','postgame')){if($report.phases.($name).original_graph_nodes -ne @{warmup=66;playing=4;postgame=10}[$name] -or $report.phases.($name).transport_nodes -ne @{warmup=23;playing=8;postgame=14}[$name] -or $report.phases.($name).interface_nodes -ne 5 -or $report.phases.($name).method_counts.Python -ne @{warmup=5;playing=2;postgame=3}[$name] -or $report.phases.($name).method_counts.BlueprintFallback -ne @{warmup=5;playing=2;postgame=3}[$name]){throw 'Complete phase Profile family required'}}
    }
    if($Kind -eq 'eliminationscore' -and (!$report.original_trees_animations_async_delegate_bindings_delay_and_graphs_preserved -or !$report.original_localized_clock_nodes_moved_intact -or $report.localized_text_roundtripped -or $report.original_graph_nodes -ne 230 -or $report.transport_nodes -ne 35 -or $report.interface_nodes -ne 5 -or $report.method_counts.Python -ne 8 -or $report.method_counts.BlueprintFallback -ne 8 -or $report.new_business_nodes -ne 0)){throw 'Original TDM HUD native delegate/clock/transport proof required'}
    if($Kind -eq 'controlpointwidgets'){
        if(!$report.original_trees_animations_async_factories_delay_and_graphs_preserved -or !$report.original_empty_tick_stays_unconnected -or !$report.source_index_two_and_later_reuses_marker_c -or $report.new_business_nodes -ne 0){throw 'Original CP widget/async/Delay/empty-hook proof required'}
        foreach($name in @('score','marker','status')){if($report.widgets.($name).original_graph_nodes -ne @{score=118;marker=113;status=32}[$name] -or $report.widgets.($name).transport_nodes -ne @{score=20;marker=26;status=8}[$name] -or $report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne @{score=5;marker=6;status=2}[$name] -or $report.widgets.($name).method_counts.BlueprintFallback -ne @{score=5;marker=6;status=2}[$name]){throw 'Complete CP widget Profile family required'}}
    }
    if($Kind -eq 'scoreboardstyle'){
        if(!$report.original_trees_animations_native_timer_literal_team_names_and_graphs_preserved -or $report.localized_text_roundtripped -or $report.native_timer_seconds -ne 1 -or !$report.construct_target_score_only -or $report.new_business_nodes -ne 0){throw 'Current native literal/style/timer/board proof incomplete'}
        foreach($name in @('team','headercp','headertdm','boardcp','boardtdm')){if($report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne $(if($name -eq 'team'){3}else{1}) -or $report.widgets.($name).method_counts.BlueprintFallback -ne $(if($name -eq 'team'){3}else{1})){throw 'Complete scoreboard style/board Profiles required'}}
    }
    if($Kind -eq 'scoreboardlist' -and (!$report.original_visuals_native_timer_delegates_localized_format_and_remaining_graphs_preserved -or $report.localized_text_roundtripped -or $report.native_timer_seconds -ne 1 -or !$report.native_looping -or !$report.list_timer_only_when_filter_not_minus_one -or $report.new_native_cleanup_added -or $report.new_business_nodes -ne 0 -or
        $report.widgets.list.original_graph_nodes -ne 102 -or $report.widgets.connection.original_graph_nodes -ne 20 -or $report.widgets.list.transport_nodes -ne 18 -or $report.widgets.connection.transport_nodes -ne 12 -or
        $report.widgets.list.interface_nodes -ne 5 -or $report.widgets.connection.interface_nodes -ne 5 -or $report.widgets.list.method_counts.Python -ne 4 -or $report.widgets.list.method_counts.BlueprintFallback -ne 4 -or $report.widgets.connection.method_counts.Python -ne 2 -or $report.widgets.connection.method_counts.BlueprintFallback -ne 2)){throw 'Current player-list/native timer/localized format proof incomplete'}
    if($Kind -eq 'scoreboardrows'){
        if(!$report.original_widget_trees_signatures_interface_parent_calls_empty_hooks_and_business_graphs_preserved -or $report.native_stat_timer_seconds -ne 1 -or !$report.native_stat_timer_looping -or !$report.no_native_timer_or_destruct_cleanup_added -or $report.new_business_nodes -ne 0){throw 'Current scoreboard native timer/base-parent/interface/visual proof incomplete'}
        foreach($name in @('base','name','icon','stat','cp','tdm')){if($report.widgets.($name).interface_nodes -ne 5 -or $report.widgets.($name).method_counts.Python -ne @{base=1;name=2;icon=1;stat=4;cp=5;tdm=5}[$name] -or $report.widgets.($name).method_counts.BlueprintFallback -ne @{base=1;name=2;icon=1;stat=4;cp=5;tdm=5}[$name]){throw 'Complete scoreboard composite Profile family required'}}
    }
    if($Kind -eq 'eliminationwidgets' -and (!$report.original_widget_trees_animations_exact_listener_list_binding_timer_delegate_and_graphs_preserved -or $report.native_expiry_seconds -ne 6 -or !$report.expiry_uses_current_list_item -or !$report.unconnected_construct_set_colors_stays_unreachable -or !$report.source_split_screen_filter_todo_unchanged -or $report.new_business_nodes -ne 0 -or
        $report.widgets.feed.original_graph_nodes -ne 23 -or $report.widgets.entry.original_graph_nodes -ne 85 -or $report.widgets.feed.transport_nodes -ne 12 -or $report.widgets.entry.transport_nodes -ne 19 -or
        $report.widgets.feed.interface_nodes -ne 5 -or $report.widgets.entry.interface_nodes -ne 5 -or $report.widgets.feed.method_counts.Python -ne 3 -or $report.widgets.feed.method_counts.BlueprintFallback -ne 3 -or
        $report.widgets.entry.method_counts.Python -ne 4 -or $report.widgets.entry.method_counts.BlueprintFallback -ne 4)){throw 'Current elimination widget/list/native timer/delegate proof incomplete'}
    if($Kind -eq 'accoladewidgets' -and (!$report.original_widget_trees_animations_native_queue_parent_and_business_graphs_preserved -or $report.localized_text_roundtripped -or !$report.unconnected_toast_stop_branch_remains_unreachable -or $report.new_business_nodes -ne 0 -or
        $report.widgets.host.original_graph_nodes -ne 25 -or $report.widgets.toast.original_graph_nodes -ne 11 -or $report.widgets.host.transport_nodes -ne 13 -or $report.widgets.toast.transport_nodes -ne 4 -or
        $report.widgets.host.interface_nodes -ne 5 -or $report.widgets.toast.interface_nodes -ne 5 -or $report.widgets.host.method_counts.Python -ne 3 -or $report.widgets.host.method_counts.BlueprintFallback -ne 3 -or
        $report.widgets.toast.method_counts.Python -ne 1 -or $report.widgets.toast.method_counts.BlueprintFallback -ne 1)){throw 'Current accolade widget/native queue/animation/typed return proof incomplete'}
    if($Kind -eq 'accoladerelay' -and (!$report.original_full_cdo_partial_async_factory_sequence_authority_cosmetic_rpc_and_business_graphs_preserved -or !$report.native_notification_struct_and_broadcast_custom_thunk -or
        $report.original_graph_nodes -ne 15 -or $report.transport_nodes -ne 7 -or $report.interface_nodes -ne 5 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 1 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or !$report.fixture.stage_only)){throw 'Current elimination relay subscription/RPC/typed message proof incomplete'}
    if($Kind -eq 'eliminationfeedrelay' -and (!$report.original_full_cdo_exact_async_factory_authority_cosmetic_rpc_and_business_graphs_preserved -or !$report.native_user_defined_feed_struct_and_broadcast_custom_thunk -or
        $report.original_graph_nodes -ne 30 -or $report.transport_nodes -ne 8 -or $report.interface_nodes -ne 5 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 1 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or !$report.fixture.stage_only)){throw 'Current elimination relay subscription/RPC/typed message proof incomplete'}
    if($Kind -eq 'controlpointfeedback' -and (!$report.accepted_parent_cdo_components_timeline_rpc_and_all_remaining_graphs_preserved -or !$report.native_capture_message_custom_thunk_preserved -or
        $report.parent_revision_graph_nodes -ne 308 -or $report.new_transport_nodes_this_revision -ne 37 -or $report.cumulative_transport_nodes -ne 69 -or $report.interface_nodes -ne 5 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 17 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 17 -or !$report.timeline_update_finish_rpc_vfx_audio_business_migrated)){throw 'Current point feedback/Timeline/RPC/message proof incomplete'}
    if($Kind -eq 'controlpointstate' -and (!$report.accepted_helper_cdo_components_timeline_rpc_and_all_remaining_graphs_preserved -or !$report.native_experience_factory_component_overlap_binding_authority_switches_and_rpc_preserved -or
        $report.parent_revision_graph_nodes -ne 292 -or $report.new_transport_nodes_this_revision -ne 16 -or $report.cumulative_transport_nodes -ne 32 -or $report.interface_nodes -ne 5 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 8 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 8 -or $report.timeline_update_finish_rpc_vfx_audio_business_migrated)){throw 'Accepted volume state/authority/remaining-business proof incomplete'}
    if($Kind -eq 'controlpointhelpers' -and (!$report.original_full_cdo_components_timeline_curves_guids_rpc_signatures_and_other_business_preserved -or
        $report.original_graph_nodes -ne 271 -or $report.transport_nodes -ne 16 -or $report.interface_nodes -ne 5 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 4 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 4 -or $report.volume_arbitration_overlap_timeline_rpc_audio_business_migrated)){throw 'Original volume helper/Timeline/RPC/remaining-business proof incomplete'}
    if($Kind -eq 'cpscoring' -and (!$report.original_cdo_signatures_graphs_authority_phase_timer_repnotify_and_shared_base_preserved -or !$report.typed_gates_preserve_array_inputs_and_public_multi_output_abi -or
        $report.original_graph_nodes -ne 145 -or $report.transport_nodes -ne 67 -or $report.interface_nodes -ne 5 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 18 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 18)){throw 'Original CP authority/phase/timer/array/shared-base proof incomplete'}
    if($Kind -eq 'tdmscoring' -and (!$report.original_cdo_signatures_graphs_native_repnotify_timer_phase_and_shared_base_preserved -or !$report.base_owned_business_gates_cover_static_callers -or
        $report.original_graph_nodes -ne 123 -or $report.transport_nodes -ne 57 -or $report.interface_nodes -ne 5 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 16 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 16)){throw 'Original TDM timer/RepNotify/phase/shared-base proof incomplete'}
    if($Kind -eq 'scoringbase' -and (!$report.original_full_cdo_signatures_business_graphs_children_and_hook_preserved -or !$report.original_authority_switch_exact_async_factories_and_listener_lifetime_preserved -or
        !$report.base_owned_gates_cover_child_static_parent_and_public_calls -or $report.original_graph_nodes -ne 61 -or $report.transport_nodes -ne 21 -or $report.interface_nodes -ne 5 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 5 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 5 -or !$report.fixture.stage_only)){throw 'Original shared scoring base/authority/listener/child proof incomplete'}
    if($Kind -eq 'physicsfields'){
        if(!$report.original_full_cdos_signatures_business_graphs_and_component_templates_preserved -or !$report.original_engine_field_parent_and_geometry_collection_dependency_retained -or !$report.original_chaos_delegate_identity_and_disconnected_shatter_tick_preserved -or $report.new_business_nodes -ne 0){throw 'Original physics parents/Chaos/templates/disconnected graph proof incomplete'}
        foreach($label in @('example','sphere')){
            $actor=$report.actors.$label;$expectedNodes=@{example=7;sphere=20}[$label];$expectedTransport=@{example=6;sphere=5}[$label]
            if($actor.original_graph_nodes -ne $expectedNodes -or $actor.transport_nodes -ne $expectedTransport -or $actor.interface_nodes -ne 5 -or $actor.actual_registered_profile_method_counts.Python -ne 3 -or $actor.actual_registered_profile_method_counts.BlueprintFallback -ne 3){throw 'Complete physics Profile family required'}
        }
    }
    if($Kind -eq 'smallburstcues'){
        if(!$report.original_full_cdos_signatures_graphs_and_construction_templates_preserved -or !$report.original_static_parent_effects_and_latent_heal_parent_lifetime_preserved -or $report.new_business_nodes -ne 0){throw 'Original small Burst CDO/graphs/templates/parent proof incomplete'}
        foreach($label in @('pickup','melee','heal','grenade')){
            $cue=$report.cues.$label;$expectedNodes=@{pickup=10;melee=3;heal=4;grenade=9}[$label]
            if($cue.original_graph_nodes -ne $expectedNodes -or $cue.transport_nodes -ne 0 -or $cue.interface_nodes -ne 5 -or $cue.actual_registered_profile_method_counts.Python -ne 1 -or $cue.actual_registered_profile_method_counts.BlueprintFallback -ne 1){throw 'Complete small Burst Cue Profile family required'}
        }
    }
    if($Kind -eq 'spawningcue' -and (!$report.original_full_cdos_signatures_and_business_graphs_preserved -or !$report.original_native_timeline_templates_curves_guids_and_bindings_preserved -or
        !$report.original_async_factory_proxy_assignment_callbacks_latent_uuid_and_delegate_identity_preserved -or !$report.original_native_parent_effects_and_lifetime_preserved -or
        $report.original_graph_nodes -ne 118 -or $report.transport_nodes -ne 7 -or $report.interface_nodes -ne 5 -or $report.new_business_nodes -ne 0 -or $report.python_timeline_clock_added -or
        $report.actual_registered_profile_method_counts.Python -ne 8 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 8)){throw 'Original spawning Timeline/async/delegate/Profile proof incomplete'}
    if($Kind -eq 'traversalcues' -and (!$report.original_full_cdos_signatures_and_business_graphs_preserved -or !$report.original_native_parent_effects_and_timer_preserved -or
        !$report.original_native_launcher_timeline_templates_curves_guids_and_bindings_preserved -or !$report.original_teleporter_increment_macro_graph_retained -or $report.python_timeline_clock_added -or $report.new_business_nodes -ne 0 -or
        $report.cues.launcher.original_graph_nodes -ne 98 -or $report.cues.teleporter.original_graph_nodes -ne 92 -or $report.cues.launcher.transport_nodes -ne 4 -or $report.cues.teleporter.transport_nodes -ne 0 -or
        $report.cues.launcher.actual_registered_profile_method_counts.Python -ne 3 -or $report.cues.launcher.actual_registered_profile_method_counts.BlueprintFallback -ne 3 -or
        $report.cues.teleporter.actual_registered_profile_method_counts.Python -ne 1 -or $report.cues.teleporter.actual_registered_profile_method_counts.BlueprintFallback -ne 1)){throw 'Traversal Cue native Timeline/macro/Profile proof incomplete'}
    if($Kind -eq 'heroburstcues' -and (!$report.original_full_cdos_signatures_and_business_graphs_preserved -or !$report.original_native_parent_effects_and_five_second_minimum_timer_preserved -or
        !$report.native_timeline_tick_update_and_finish_retained -or $report.python_timeline_clock_added -or $report.new_business_nodes -ne 0 -or
        $report.cues.dash.original_graph_nodes -ne 63 -or $report.cues.death.original_graph_nodes -ne 91 -or $report.cues.dash.transport_nodes -ne 8 -or $report.cues.death.transport_nodes -ne 8 -or
        !$report.cues.dash.original_native_timeline_templates_curves_guids_and_event_bindings_preserved -or !$report.cues.death.original_native_timeline_templates_curves_guids_and_event_bindings_preserved -or
        $report.cues.dash.actual_registered_profile_method_counts.Python -ne 3 -or $report.cues.dash.actual_registered_profile_method_counts.BlueprintFallback -ne 3 -or
        $report.cues.death.actual_registered_profile_method_counts.Python -ne 3 -or $report.cues.death.actual_registered_profile_method_counts.BlueprintFallback -ne 3)){throw 'Hero burst original timeline/curve/Profile proof incomplete'}
    if($Kind -eq 'characterdamage' -and (!$report.original_full_cdo_event_signatures_business_and_rpc_preserved -or !$report.native_parent_burst_effects_and_lifetime_timer_preserved -or
        !$report.original_unreliable_multicast_shell_preserved -or $report.rpc_function_overridden -or !$report.original_native_rng_nodes_ranges_and_select_topology_retained -or !$report.typed_native_message_thunk_adapter -or
        $report.original_graph_nodes -ne 160 -or $report.transport_nodes -ne 25 -or !$report.generic_native_interface_array_count_and_object_accessors -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 7 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 7)){throw 'Character damage native parent/RPC/RNG/typed message proof incomplete'}
    if($Kind -eq 'messagewidgets' -and (!$report.original_full_cdos_widget_trees_event_signatures_and_business_preserved -or !$report.original_localized_text_pins_retained -or
        $report.localized_text_roundtripped_through_python -or !$report.localized_literal_setter_and_formatter_adapters -or !$report.original_native_listener_node_and_exact_channel_reused -or
        !$report.no_python_subscription_roots -or $report.original_graph_nodes.match -ne 70 -or $report.original_graph_nodes.waiting -ne 18 -or
        $report.transport_nodes.match -ne 11 -or $report.transport_nodes.waiting -ne 8 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.match.Python -ne 3 -or $report.actual_registered_profile_method_counts.match.BlueprintFallback -ne 3 -or
        $report.actual_registered_profile_method_counts.waiting.Python -ne 2 -or $report.actual_registered_profile_method_counts.waiting.BlueprintFallback -ne 2)){throw 'Message widget localized data/native listener/Profile proof incomplete'}
    if($Kind -eq 'cuewidgets' -and (!$report.original_full_cdo_preserved -or !$report.original_business_graphs_preserved_with_dispatch -or
        !$report.original_native_parent_start_call_preserved -or !$report.child_defaults_event_signatures_and_asset_bytes_preserved -or !$report.base_owned_gates -or !$report.production_abstract_base_preserved -or
        $report.original_graph_nodes -ne 40 -or $report.transport_nodes -ne 8 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 2 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 2)){throw 'Cue widget base/child/native parent/gate proof incomplete'}
    if($Kind -eq 'footstep' -and (!$report.interface_signature_preserved -or $report.original_graph_nodes -ne 93)){throw 'Footstep original interface/graph proof incomplete'}
    if($Kind -eq 'generalaudio' -and (!$report.original_full_cdo_preserved -or !$report.original_static_signature_flags_preserved -or !$report.original_business_graph_preserved_with_dispatch -or
        $report.static_functions_registered_as_mixins -or $report.original_graph_nodes -ne 8 -or $report.transport_nodes -ne 5 -or
        $report.actual_registered_profile_method_counts.Python -ne 1 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 1)){throw 'GeneralAudio static ABI/original body/typed Object proof incomplete'}
    if($Kind -eq 'windsystem' -and (!$report.original_full_cdo_preserved -or !$report.original_business_graphs_preserved_with_dispatch -or
        !$report.native_multigate_state_reused -or !$report.native_array_set_and_no_resize_preserved -or $report.original_graph_nodes -ne 62 -or $report.transport_nodes -ne 18 -or
        $report.actual_registered_profile_method_counts.Python -ne 3 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 3)){throw 'Wind native scheduler/array/graph proof incomplete'}
    if($Kind -eq 'musiccontrols' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or !$report.original_begin_play_listeners_preserved -or
        !$report.child_cdos_signatures_and_asset_bytes_preserved -or $report.original_graph_nodes -ne 99 -or $report.transport_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 5 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 5)){throw 'Music control graph/default/inheritance/listener proof incomplete'}
    if($Kind -eq 'weaponaudiomath' -and (!$report.original_full_cdo_preserved -or !$report.original_static_signatures_flags_preserved -or
        !$report.original_business_graphs_preserved_with_dispatch -or !$report.original_local_defaults_preserved -or !$report.native_register_restore_passed -or
        $report.static_functions_registered_as_mixins -or $report.original_graph_nodes -ne 348 -or $report.transport_nodes -ne 10 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 2 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 2)){throw 'Static audio ABI/typed Object router/original graph proof incomplete'}
    if($Kind -eq 'weaponfirecues' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        !$report.native_register_restore_passed -or !$report.original_native_burst_effects_preserved -or $report.static_audio_library_business_migrated -or
        $report.original_graph_nodes -ne 76 -or $report.transport_nodes -ne 0 -or $report.new_business_nodes -ne 0 -or @($report.records).Count -ne 3 -or
        @($report.actual_registered_profile_method_counts.PSObject.Properties|Where-Object {$_.Value.Python -ne 1 -or $_.Value.BlueprintFallback -ne 1}).Count)){throw 'Original three-weapon firing Cue graph/CDO/OnBurst proof incomplete'}
    if($Kind -eq 'netshooterability' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or
        !$report.native_register_restore_passed -or !$report.native_weak_named_task_binding -or !$report.original_empty_target_data_override_preserved -or
        $report.inherited_selector_redeclared -or !$report.inherited_parent_namespace_preserved -or $report.python_callback_roots_or_scopes_added -or
        $report.original_graph_nodes -ne 48 -or $report.transport_nodes -ne 8 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 5 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 5)){throw 'Original NetShooter ability/empty target/montage/inherited namespace proof incomplete'}
    if($Kind -eq 'netshooteractor' -and (!$report.original_full_cdo_preserved -or !$report.original_business_graphs_preserved_with_dispatch -or
        !$report.native_register_restore_passed -or !$report.original_rpc_flags_and_entry_preserved -or $report.rpc_function_overridden -or
        !$report.original_native_authority_do_once_preserved -or !$report.original_native_delay_node_uuid_preserved -or !$report.native_overlap_weak_named_delegate_preserved -or
        !$report.original_component_template_reused -or $report.original_graph_nodes -ne 47 -or $report.transport_nodes -ne 11 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 4 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 4)){throw 'Original NetShooter Actor/RPC/DoOnce/Delay/overlap proof incomplete'}
    if($Kind -eq 'weaponabilityfire' -and (!$report.original_full_cdo_preserved -or !$report.original_business_graphs_preserved_with_dispatch -or
        !$report.native_register_restore_passed -or !$report.native_weak_named_task_binding -or !$report.native_function_name_timers -or
        !$report.original_native_message_factory_and_exact_payload_preserved -or $report.python_callback_roots_or_scopes_added -or
        $report.original_graph_nodes -ne 106 -or $report.transport_nodes -ne 11 -or $report.new_business_nodes -ne 0 -or
        $report.actual_registered_profile_method_counts.Python -ne 10 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 10 -or
        @($report.inherited_children).Count -ne 3 -or !$report.caller_probe.stage_only -or $report.caller_probe.gameplay_business -or
        (Get-FileHash -LiteralPath $report.caller_probe.asset).Hash -ne $report.caller_probe.sha256)){throw 'Shared fire original graph/named callback/inherited/typed message proof incomplete'}
    if($Kind -eq 'weaponimpacts' -and (!$report.original_full_cdo_preserved -or !$report.original_business_graphs_preserved_with_dispatch -or
        !$report.native_register_restore_passed -or !$report.original_retriggerable_delay_node_reused -or !$report.native_delay_uuid_preserved -or
        !$report.cleanup_tests_validity_not_active -or $report.native_delay_seconds -ne 3 -or $report.transport_nodes -ne 3 -or $report.new_business_nodes -ne 0 -or
        !$report.original_greater_distance_reuse_rule_preserved -or !$report.original_typed_array_and_legacy_channel_apis_preserved -or
        $report.actual_registered_profile_method_counts.Python -ne 6 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 6 -or @($report.implemented_methods).Count -ne 6)){throw 'Original impact five-method/latent/typed-data policy proof incomplete'}
    if($Kind -eq 'weapondecals' -and (!$report.original_position_array_type_preserved -or !$report.original_surface_array_tail_preserved)){throw 'Original decal Position array and retained surface tail proof required'}
    if($Kind -eq 'weaponactorhelpers' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or !$report.native_register_restore_passed -or
        $report.new_business_nodes -ne 0 -or $report.actual_registered_profile_method_counts.Python -ne 4 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 4 -or
        @($report.inherited_children).Count -ne 3 -or $report.fire_and_begin_play_migrated -or !$report.original_helper_policy.stencil_local_control_only)){
        throw 'Weapon parent original helper and three-child inheritance proof incomplete'
    }
    if($Kind -eq 'grenadevfx' -and (!$report.original_full_cdo_preserved -or !$report.original_graphs_unmodified -or !$report.native_register_restore_passed -or
        $report.new_business_nodes -ne 0 -or $report.actual_registered_profile_method_counts.Python -ne 1 -or
        $report.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or $report.original_vfx_policy.nodes -ne 19 -or
        $report.original_vfx_policy.red_team_id -ne 1 -or $report.actor_collision_fuse_explosion_damage_migrated)){
        throw 'Grenade Actor retained native VFX helper proof incomplete'
    }
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
        if(Test-Path -LiteralPath $target){
            if($Kind -notin @('controlpointstate','controlpointfeedback','explorerstyle')){throw 'Do not overwrite existing Overlay ability output'}
            $expectedParent=@($parentSummary.assets|Where-Object {[IO.Path]::GetFullPath($_.overlay) -eq [IO.Path]::GetFullPath($target)})
            if($expectedParent.Count -ne 1 -or (Get-FileHash -LiteralPath $target).Hash -ne $expectedParent[0].sha256){throw 'Do not overwrite changed or undeclared helper Overlay output'}
        }
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
