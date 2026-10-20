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
      [switch]$MeleeHitMontage,[string]$MeleeAuthoringDirectory,
      [switch]$GrenadeWidget,[switch]$GrenadeActivation,[switch]$GrenadeActivationNetwork,[string]$GrenadeAuthoringDirectory,
      [switch]$GrenadeVFX,[string]$GrenadeVFXAuthoringDirectory,
      [switch]$GrenadeCleanup,[string]$GrenadeCleanupAuthoringDirectory,
      [switch]$GrenadeActions,[string]$GrenadeActionsAuthoringDirectory,
      [switch]$GrenadeBegin,[string]$GrenadeBeginAuthoringDirectory,
      [switch]$GrenadeHeadless,
      [switch]$GrenadeHit,[string]$GrenadeHitAuthoringDirectory,
      [switch]$GrenadeDetonate,[switch]$GrenadeDetonateNetwork,[string]$GrenadeDetonateAuthoringDirectory,
      [switch]$GrenadeFlightNetwork,[string]$GrenadeFlightAbilityAuthoringDirectory,
      [switch]$NetShooterActor,[string]$NetShooterActorAuthoringDirectory,
      [switch]$NetShooterAbility,[string]$NetShooterAbilityAuthoringDirectory,
      [switch]$NetShooterNetwork,
      [switch]$NetShooterImpactNetwork,
      [switch]$WeaponActorHelpers,[string]$WeaponActorHelpersAuthoringDirectory,
      [switch]$WeaponActorFire,[string]$WeaponActorFireAuthoringDirectory,
      [switch]$WeaponActorBegin,[string]$WeaponActorBeginAuthoringDirectory,
      [switch]$WeaponFireFX,[string]$WeaponFireFXAuthoringDirectory,
      [switch]$WeaponFireCues,[string]$WeaponFireCueAuthoringDirectory,
      [switch]$WeaponAudioMath,[string]$WeaponAudioMathAuthoringDirectory,
      [switch]$WeaponAudioDispatch,[string]$WeaponAudioDispatchAuthoringDirectory,
      [switch]$WeaponAudioWhiz,[string]$WeaponAudioWhizAuthoringDirectory,[switch]$WeaponAudioWhizNoSound,
      [switch]$WeaponAudioEarly,[string]$WeaponAudioEarlyAuthoringDirectory,[switch]$WeaponAudioEarlyOpenGeometry,
      [switch]$WeaponAudioCold,[string]$WeaponAudioColdAuthoringDirectory,[ValidateSet('pistol','rifle','shotgun')][string]$WeaponAudioColdWeapon='pistol',
      [switch]$WeaponAudioEffect,
      [switch]$WeaponAudioNetwork,[string]$WeaponAudioNetworkAuthoringDirectory,
      [switch]$MusicControls,[string]$MusicControlsAuthoringDirectory,
      [switch]$MusicLifecycle,[string]$MusicLifecycleAuthoringDirectory,
      [switch]$MusicFamily,[string]$MusicFamilyAuthoringDirectory,
      [switch]$WindSystem,[string]$WindSystemAuthoringDirectory,
      [switch]$GeneralAudio,[string]$GeneralAudioAuthoringDirectory,
      [switch]$Footstep,[string]$FootstepAuthoringDirectory,
      [switch]$CueWidgets,[string]$CueWidgetAuthoringDirectory,
      [switch]$MessageWidgets,[string]$MessageWidgetAuthoringDirectory,
      [switch]$CharacterDamage,[string]$CharacterDamageAuthoringDirectory,
      [switch]$HeroBurstCues,[string]$HeroBurstCueAuthoringDirectory,
      [switch]$TraversalCues,[string]$TraversalCueAuthoringDirectory,
      [switch]$SpawningCue,[string]$SpawningCueAuthoringDirectory,
      [switch]$SmallBurstCues,[string]$SmallBurstCueAuthoringDirectory,
      [switch]$PhysicsFields,[string]$PhysicsFieldAuthoringDirectory,
      [switch]$ScoringBase,[string]$ScoringBaseAuthoringDirectory,
      [switch]$TDMScoring,[string]$TDMScoringAuthoringDirectory,
      [switch]$CPScoring,[string]$CPScoringAuthoringDirectory,
      [switch]$ControlPointHelpers,[string]$ControlPointHelpersAuthoringDirectory,
      [switch]$MacroClosure,[string]$MacroClosureAuthoringDirectory,
      [switch]$ShooterEQS,[string]$ShooterEQSAuthoringDirectory,[ValidateSet('Python','BlueprintFallback')][string]$ShooterEQSProfile='Python',[ValidateSet('tdm','cp')][string]$ShooterEQSMode='tdm',
      [switch]$ShooterAI,[string]$ShooterAIAuthoringDirectory,[ValidateSet('Python','BlueprintFallback')][string]$ShooterAIProfile='Python',[ValidateSet('tdm','cp')][string]$ShooterAIMode='tdm',
      [switch]$GamePhases,[string]$GamePhasesAuthoringDirectory,[ValidateSet('Python','BlueprintFallback')][string]$GamePhasesProfile='Python',
      [switch]$EliminationScore,[string]$EliminationScoreAuthoringDirectory,
      [switch]$ControlPointWidgets,[string]$ControlPointWidgetsAuthoringDirectory,
      [switch]$ScoreboardStyle,[string]$ScoreboardStyleAuthoringDirectory,[ValidateSet('tdm','cp')][string]$ScoreboardStyleMode='tdm',
      [switch]$ScoreboardList,[string]$ScoreboardListAuthoringDirectory,
      [switch]$ScoreboardRows,[string]$ScoreboardRowsAuthoringDirectory,
      [switch]$EliminationWidgets,[string]$EliminationWidgetsAuthoringDirectory,[string]$EliminationWidgetsRelayAuthoringDirectory,
      [switch]$AccoladeWidgets,[string]$AccoladeWidgetsAuthoringDirectory,[string]$AccoladeWidgetsRelayAuthoringDirectory,
      [switch]$NotificationRelaysNetwork,[string]$RelayEliminationAuthoringDirectory,[string]$RelayAccoladeAuthoringDirectory,
      [switch]$AccoladeRelay,[string]$AccoladeRelayAuthoringDirectory,
      [switch]$EliminationFeedRelay,[string]$EliminationFeedRelayAuthoringDirectory,
      [switch]$ControlPointFeedback,[string]$ControlPointFeedbackAuthoringDirectory,
      [switch]$ControlPointState,[string]$ControlPointStateAuthoringDirectory,
      [switch]$WeaponFireCueNetwork,
      [switch]$WeaponDecals,[string]$WeaponDecalsAuthoringDirectory,
      [switch]$WeaponImpacts,[string]$WeaponImpactsAuthoringDirectory,
      [switch]$WeaponAbilityFire,[string]$WeaponAbilityFireAuthoringDirectory,
      [switch]$WeaponAbilityFireNetwork,[ValidateSet('pistol','rifle','shotgun')][string]$WeaponFireNetworkWeapon='pistol',
      [switch]$PawnWireIdentity,[string]$IdentityBuildDirectory,
      [switch]$LazyPawnLifecycle,
      [switch]$JoinResetStress,
      [switch]$MeleeActivation,[string]$MeleeActivationAuthoringDirectory,
      [switch]$MeleeTrace,[string]$MeleeTraceAuthoringDirectory,
      [string]$MeleeNetworkFixtureAuthoringDirectory,
      [ValidateSet('Python','BlueprintFallback')][string]$MeleeCharacterStartupProfile,
      [switch]$MeleeCharacterOriginalBeginPlay,
      [switch]$MeleeWarmupJoin,
      [ValidateSet('first-half','second-half','refresh-python','clone-python','inventory','possession','team','possession_factory','experience','experience_entry','experience_resume')][string]$MeleeCharacterOriginalSubset,
      [switch]$DashRPCInput,[string]$DashRPCInputAuthoringDirectory,
      [switch]$DashLocalDirection,[string]$DashLocalDirectionAuthoringDirectory,
      [switch]$DashActivation,[string]$DashActivationAuthoringDirectory,
      [switch]$DashTasks,[string]$DashTasksAuthoringDirectory,
      [switch]$DashTasksLifecycle,
      [switch]$DashTasksNetworkLifecycle,
      [ValidateSet('tdm','cp')][string]$WidgetHeldMode='tdm',
      [ValidateRange(1024,65535)][int]$ServerPort=7794,
      [ValidateSet('pistol','rifle','shotgun','netshooter')][string]$ReloadWeapon='pistol')
# Only existing binaries and already authored disposable assets. No build/cook.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($MacroClosure){
    $macroAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','MacroClosure','MacroClosureAuthoringDirectory','ThreadedLoading')
    if(!$MacroClosureAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $macroAllowed}).Count){throw 'Macro closure requires its standalone exact-macro probe lane and current closure proof'}
    $AutoRespawnActivation=$true
}
if($MacroClosureAuthoringDirectory -and !$MacroClosure){throw 'Macro closure proof requires its explicit native fixture'}

if($ShooterEQS){
    $eqsAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','ShooterEQS','ShooterEQSAuthoringDirectory','ShooterEQSProfile','ShooterEQSMode','ThreadedLoading')
    if(!$ShooterEQSAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $eqsAllowed}).Count){throw 'Shooter EQS requires its standalone live-query lane and current family proof'}
    $AutoRespawnActivation=$true
}
if(($ShooterEQSAuthoringDirectory -or $PSBoundParameters.ContainsKey('ShooterEQSProfile') -or $PSBoundParameters.ContainsKey('ShooterEQSMode')) -and !$ShooterEQS){throw 'EQS proof/Profile/mode requires its explicit native fixture'}

if($ShooterAI){
    $aiAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','ShooterAI','ShooterAIAuthoringDirectory','ShooterAIProfile','ShooterAIMode','ThreadedLoading')
    if(!$ShooterAIAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $aiAllowed}).Count){throw 'Shooter AI requires its standalone native BT/GAS/controller lane and current family proof'}
    $AutoRespawnActivation=$true
}
if(($ShooterAIAuthoringDirectory -or $PSBoundParameters.ContainsKey('ShooterAIProfile') -or $PSBoundParameters.ContainsKey('ShooterAIMode')) -and !$ShooterAI){throw 'AI proof/Profile requires its explicit native fixture'}

if($GamePhases){
    $phaseAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','GamePhases','GamePhasesAuthoringDirectory','GamePhasesProfile','ThreadedLoading')
    if(!$GamePhasesAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $phaseAllowed}).Count){throw 'Game phases require their standalone native GAS/latent/travel lane and current family proof'}
    $AutoRespawnActivation=$true
}
if(($GamePhasesAuthoringDirectory -or $PSBoundParameters.ContainsKey('GamePhasesProfile')) -and !$GamePhases){throw 'Phase proof/Profile requires its explicit native fixture'}

if($EliminationScore){
    $tdmHudAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','EliminationScore','EliminationScoreAuthoringDirectory','ThreadedLoading')
    if(!$EliminationScoreAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $tdmHudAllowed}).Count){throw 'TDM score widget requires its standalone native UMG/delegate/audio lane and current proof'}
    $AutoRespawnActivation=$true
}
if($EliminationScoreAuthoringDirectory -and !$EliminationScore){throw 'TDM HUD proof requires its explicit native fixture'}

if($ControlPointWidgets){
    $cpWidgetsAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','ControlPointWidgets','ControlPointWidgetsAuthoringDirectory','ThreadedLoading')
    if(!$ControlPointWidgetsAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $cpWidgetsAllowed}).Count){throw 'CP widgets require their standalone native UMG/material/audio lane and current proof'}
    $AutoRespawnActivation=$true
}
if($ControlPointWidgetsAuthoringDirectory -and !$ControlPointWidgets){throw 'CP widget proof requires its explicit native fixture'}

if($ScoreboardStyle){
    $styleAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','ScoreboardStyle','ScoreboardStyleAuthoringDirectory','ScoreboardStyleMode','ThreadedLoading')
    if(!$ScoreboardStyleAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $styleAllowed}).Count){throw 'Scoreboard styling requires its standalone current-mode UMG/native timer lane and current proof'}
    $AutoRespawnActivation=$true
}
if($ScoreboardStyleAuthoringDirectory -and !$ScoreboardStyle){throw 'Scoreboard style proof requires its explicit native fixture'}
if($PSBoundParameters.ContainsKey('ScoreboardStyleMode') -and !$ScoreboardStyle){throw 'Scoreboard style mode requires its explicit native fixture'}
if($ScoreboardList){
    $scoreboardListAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','ScoreboardList','ScoreboardListAuthoringDirectory','ThreadedLoading')
    if(!$ScoreboardListAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $scoreboardListAllowed}).Count){throw 'Scoreboard list require their standalone native parent/interface/stat-timer lane and current family proof'}
    $AutoRespawnActivation=$true
}
if($ScoreboardListAuthoringDirectory -and !$ScoreboardList){throw 'Scoreboard list proof requires its explicit native fixture'}
if($ScoreboardRows){
    $scoreboardAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','ScoreboardRows','ScoreboardRowsAuthoringDirectory','ThreadedLoading')
    if(!$ScoreboardRowsAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $scoreboardAllowed}).Count){throw 'Scoreboard rows require their standalone native parent/interface/stat-timer lane and current family proof'}
    $AutoRespawnActivation=$true
}
if($ScoreboardRowsAuthoringDirectory -and !$ScoreboardRows){throw 'Scoreboard row proof requires its explicit native fixture'}
if($EliminationWidgets){
    $eliminationWidgetAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','EliminationWidgets','EliminationWidgetsAuthoringDirectory','EliminationWidgetsRelayAuthoringDirectory','ThreadedLoading')
    if(!$EliminationWidgetsAuthoringDirectory -or !$EliminationWidgetsRelayAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $eliminationWidgetAllowed}).Count){throw 'Elimination widgets require their standalone native list/UMG/native-expiry lane and current widget/relay proofs'}
    $AutoRespawnActivation=$true
}
if(($EliminationWidgetsAuthoringDirectory -or $EliminationWidgetsRelayAuthoringDirectory) -and !$EliminationWidgets){throw 'Elimination widget proofs require their explicit native fixture'}
if($AccoladeWidgets){
    $accoladeWidgetAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','AccoladeWidgets','AccoladeWidgetsAuthoringDirectory','AccoladeWidgetsRelayAuthoringDirectory','ThreadedLoading')
    if(!$AccoladeWidgetsAuthoringDirectory -or !$AccoladeWidgetsRelayAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $accoladeWidgetAllowed}).Count){throw 'Accolade widgets require their standalone native registry/queue/UMG/offline-audio lane and current widget/relay proofs'}
    $AutoRespawnActivation=$true
}
if(($AccoladeWidgetsAuthoringDirectory -or $AccoladeWidgetsRelayAuthoringDirectory) -and !$AccoladeWidgets){throw 'Accolade widget proofs require their explicit native fixture'}
if($NotificationRelaysNetwork){
    $relayNetworkAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','NotificationRelaysNetwork','RelayEliminationAuthoringDirectory','RelayAccoladeAuthoringDirectory','Network','PawnWireIdentity','IdentityBuildDirectory','ServerPort','ThreadedLoading')
    if(!$Network -or !$PawnWireIdentity -or !$IdentityBuildDirectory -or !$RelayEliminationAuthoringDirectory -or !$RelayAccoladeAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $relayNetworkAllowed}).Count){throw 'Notification relays require their dedicated two-client network lane and both current asset/identity proofs'}
    $AutoRespawnActivation=$true
}
if(($RelayEliminationAuthoringDirectory -or $RelayAccoladeAuthoringDirectory) -and !$NotificationRelaysNetwork){throw 'Relay network proofs require their explicit network fixture'}
if($AccoladeRelay){
    $relayAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','AccoladeRelay','AccoladeRelayAuthoringDirectory','ThreadedLoading')
    if(!$AccoladeRelayAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $relayAllowed}).Count){throw 'Accolade relay requires its standalone exact-message/typed-payload/lifetime lane and current proof'}
    $AutoRespawnActivation=$true
}
if($AccoladeRelayAuthoringDirectory -and !$AccoladeRelay){throw 'Accolade relay proof requires its explicit native fixture'}
if($EliminationFeedRelay){
    $relayAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','EliminationFeedRelay','EliminationFeedRelayAuthoringDirectory','ThreadedLoading')
    if(!$EliminationFeedRelayAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $relayAllowed}).Count){throw 'Elimination feed relay requires its standalone exact-message/typed-payload/lifetime lane and current proof'}
    $AutoRespawnActivation=$true
}
if($EliminationFeedRelayAuthoringDirectory -and !$EliminationFeedRelay){throw 'Elimination relay proof requires its explicit native fixture'}
if($ControlPointFeedback){
    $pointFeedbackAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','ControlPointFeedback','ControlPointFeedbackAuthoringDirectory','ThreadedLoading')
    if(!$ControlPointFeedbackAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $pointFeedbackAllowed}).Count){throw 'Control point feedback requires its standalone CP-map physical-overlap lane and current proof'}
    $AutoRespawnActivation=$true
}
if($ControlPointFeedbackAuthoringDirectory -and !$ControlPointFeedback){throw 'Control point feedback proof requires its explicit native fixture'}
if($ControlPointState){
    $pointStateAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','ControlPointState','ControlPointStateAuthoringDirectory','ThreadedLoading')
    if(!$ControlPointStateAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $pointStateAllowed}).Count){throw 'Control point state requires its standalone CP-map physical-overlap lane and current proof'}
    $AutoRespawnActivation=$true
}
if($ControlPointStateAuthoringDirectory -and !$ControlPointState){throw 'Control point state proof requires its explicit native fixture'}
if($ControlPointHelpers){
    $pointHelpersAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','ControlPointHelpers','ControlPointHelpersAuthoringDirectory','ThreadedLoading')
    if(!$ControlPointHelpersAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $pointHelpersAllowed}).Count){throw 'Control point helpers require their standalone CP-map construction/native-helper lane and current proof'}
    $AutoRespawnActivation=$true
}
if($ControlPointHelpersAuthoringDirectory -and !$ControlPointHelpers){throw 'Control point helper proof requires its explicit native fixture'}
if($CPScoring){
    $cpAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','CPScoring','CPScoringAuthoringDirectory','ThreadedLoading')
    if(!$CPScoringAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $cpAllowed}).Count){throw 'CP scoring requires its standalone native control-point/map/timer lane and current proof'}
    $AutoRespawnActivation=$true
}
if($CPScoringAuthoringDirectory -and !$CPScoring){throw 'CP scoring proof requires its explicit native fixture'}
if($TDMScoring){
    $tdmAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','TDMScoring','TDMScoringAuthoringDirectory','ThreadedLoading')
    if(!$TDMScoringAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $tdmAllowed}).Count){throw 'TDM scoring requires its standalone native timer/notify/phase lane and current proof'}
    $AutoRespawnActivation=$true
}
if($TDMScoringAuthoringDirectory -and !$TDMScoring){throw 'TDM scoring proof requires its explicit native fixture'}
if($ScoringBase){
    $scoringAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','ScoringBase','ScoringBaseAuthoringDirectory','ThreadedLoading')
    if(!$ScoringBaseAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $scoringAllowed}).Count){throw 'Shared scoring requires its standalone native message/reset/warmup lane and current proof'}
    $AutoRespawnActivation=$true
}
if($ScoringBaseAuthoringDirectory -and !$ScoringBase){throw 'Shared scoring proof requires its explicit native fixture'}
if($PhysicsFields){
    $physicsAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','PhysicsFields','PhysicsFieldAuthoringDirectory','ThreadedLoading')
    if(!$PhysicsFieldAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $physicsAllowed}).Count){throw 'Physics fields require their standalone native parent/Chaos/material lane and current proof'}
    $AutoRespawnActivation=$true
}
if($PhysicsFieldAuthoringDirectory -and !$PhysicsFields){throw 'Physics field proof requires its explicit native fixture'}
if($SmallBurstCues){
    $smallBurstAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','SmallBurstCues','SmallBurstCueAuthoringDirectory','ThreadedLoading')
    if(!$SmallBurstCueAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $smallBurstAllowed}).Count){throw 'Small Burst Cues require their standalone native parent/Niagara/offline-audio lane and current proof'}
    $AutoRespawnActivation=$true
}
if($SmallBurstCueAuthoringDirectory -and !$SmallBurstCues){throw 'Small Burst Cue proof requires its explicit native fixture'}
if($SpawningCue){
    $spawningAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','SpawningCue','SpawningCueAuthoringDirectory','ThreadedLoading')
    if(!$SpawningCueAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $spawningAllowed}).Count){throw 'Spawning Cue requires its standalone native Timeline/team/parts lane and current proof'}
    $AutoRespawnActivation=$true
}
if($SpawningCueAuthoringDirectory -and !$SpawningCue){throw 'Spawning Cue proof requires its explicit native fixture'}
if($TraversalCues){
    $traversalAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','TraversalCues','TraversalCueAuthoringDirectory','ThreadedLoading')
    if(!$TraversalCueAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $traversalAllowed}).Count){throw 'Traversal Cues require their standalone native device/Timeline/Niagara lane and current proof'}
    $AutoRespawnActivation=$true
}
if($TraversalCueAuthoringDirectory -and !$TraversalCues){throw 'Traversal Cue proof requires its explicit native fixture'}
if($HeroBurstCues){
    $heroBurstAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','HeroBurstCues','HeroBurstCueAuthoringDirectory','ThreadedLoading')
    if(!$HeroBurstCueAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $heroBurstAllowed}).Count){throw 'Hero burst Cues require their standalone native Timeline/material/Niagara lane and current proof'}
    $AutoRespawnActivation=$true
}
if($HeroBurstCueAuthoringDirectory -and !$HeroBurstCues){throw 'Hero burst Cue proof requires its explicit native fixture'}
if($CharacterDamage){
    $damageAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','CharacterDamage','CharacterDamageAuthoringDirectory','ThreadedLoading')
    if(!$CharacterDamageAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $damageAllowed}).Count){throw 'Character damage requires its standalone native parent/RPC/popup/effects lane and current proof'}
    $AutoRespawnActivation=$true
}
if($CharacterDamageAuthoringDirectory -and !$CharacterDamage){throw 'Character damage proof requires its explicit native fixture'}
if($MessageWidgets){
    $messageAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','MessageWidgets','MessageWidgetAuthoringDirectory','CueWidgetAuthoringDirectory','ThreadedLoading')
    if(!$MessageWidgetAuthoringDirectory -or !$CueWidgetAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $messageAllowed}).Count){throw 'Message widgets require their native style/message/Cue lane and both current proofs'}
    $AutoRespawnActivation=$true
}
if($MessageWidgetAuthoringDirectory -and !$MessageWidgets){throw 'Message widget proof requires its explicit native fixture'}
if($CueWidgets){
    $cueWidgetAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','CueWidgets','CueWidgetAuthoringDirectory','ThreadedLoading')
    if(!$CueWidgetAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $cueWidgetAllowed}).Count){throw 'Cue widgets require their standalone native UI/manager lane and current proof'}
    $AutoRespawnActivation=$true
}
if($CueWidgetAuthoringDirectory -and !$CueWidgets -and !$MessageWidgets){throw 'Cue widget proof requires its explicit native fixture'}
if($Footstep){
    $footstepAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','Footstep','FootstepAuthoringDirectory','ThreadedLoading')
    if(!$FootstepAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $footstepAllowed}).Count){throw 'Footstep requires its standalone native Niagara/latent lane and current proof'}
    $AutoRespawnActivation=$true
}
if($FootstepAuthoringDirectory -and !$Footstep){throw 'Footstep proof requires its explicit native fixture'}
if($GeneralAudio){
    $generalAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','GeneralAudio','GeneralAudioAuthoringDirectory','ThreadedLoading')
    if(!$GeneralAudioAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $generalAllowed}).Count){throw 'GeneralAudio requires standalone static/BP/native music receiver and current proof'}
    $AutoRespawnActivation=$true
}
if($GeneralAudioAuthoringDirectory -and !$GeneralAudio){throw 'GeneralAudio proof requires its explicit native fixture'}
if($WindSystem){
    $windAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WindSystem','WindSystemAuthoringDirectory','ThreadedLoading')
    if(!$WindSystemAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $windAllowed}).Count){throw 'Wind system requires its standalone native scheduler/physics/parameter lane and current proof'}
    $AutoRespawnActivation=$true
}
if($WindSystemAuthoringDirectory -and !$WindSystem){throw 'Wind proof requires its explicit native fixture'}
if($MusicFamily){
    $familyAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','MusicFamily','MusicFamilyAuthoringDirectory','ThreadedLoading')
    if(!$MusicFamilyAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $familyAllowed}).Count){throw 'Music family requires its standalone native parent/Delay/team-message lane and current proof'}
    $AutoRespawnActivation=$true
}
if($MusicFamilyAuthoringDirectory -and !$MusicFamily){throw 'Music family proof requires its explicit native fixture'}
if($MusicLifecycle){
    $musicLifeAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','MusicLifecycle','MusicLifecycleAuthoringDirectory','ThreadedLoading')
    if(!$MusicLifecycleAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $musicLifeAllowed}).Count){throw 'Music lifecycle requires its standalone native BeginPlay/GMS/ownership lane and current proof'}
    $AutoRespawnActivation=$true
}
if($MusicLifecycleAuthoringDirectory -and !$MusicLifecycle){throw 'Music lifecycle proof requires its explicit native fixture'}
if($MusicControls){
    $musicAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','MusicControls','MusicControlsAuthoringDirectory','ThreadedLoading')
    if(!$MusicControlsAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $musicAllowed}).Count){throw 'Music controls require standalone inherited component/native audio state and current proof'}
    $AutoRespawnActivation=$true
}
if($MusicControlsAuthoringDirectory -and !$MusicControls){throw 'Music controls proof requires its explicit native fixture'}
if($WeaponAudioEffect){$WeaponAudioCold=$true}
if($WeaponAudioNetwork){
    if(!$Network -or !$PawnWireIdentity -or !$IdentityBuildDirectory -or !$WeaponAudioNetworkAuthoringDirectory -or !$WeaponFireCueAuthoringDirectory){throw 'Network audio requires actual two-owner transport and current audio/Cue/native identity proof'}
    $WeaponFireCueNetwork=$true
}
if($WeaponAudioNetworkAuthoringDirectory -and !$WeaponAudioNetwork){throw 'Network audio proof requires its explicit predicted/remote fixture'}
if($WeaponAudioCold){
    $coldAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponAudioCold','WeaponAudioColdAuthoringDirectory','WeaponAudioColdWeapon','WeaponFireCueAuthoringDirectory','WeaponAudioEffect','ThreadedLoading')
    if(!$WeaponAudioColdAuthoringDirectory -or !$WeaponFireCueAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $coldAllowed}).Count){throw 'Cold audio requires its standalone natural-input/default-registration lane and current audio/Cue proof'}
    $AutoRespawnActivation=$true
}
if(($WeaponAudioColdAuthoringDirectory -or $PSBoundParameters.ContainsKey('WeaponAudioColdWeapon')) -and !$WeaponAudioCold){throw 'Cold audio proof/weapon requires its explicit native fixture'}
if($WeaponAudioEarly){
    $earlyAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponAudioEarly','WeaponAudioEarlyAuthoringDirectory','WeaponAudioEarlyOpenGeometry','ThreadedLoading')
    if(!$WeaponAudioEarlyAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $earlyAllowed}).Count){throw 'EarlyReflections requires its standalone native collision/Tap/static caller lane and current proof'}
    $AutoRespawnActivation=$true
}
if(($WeaponAudioEarlyAuthoringDirectory -or $WeaponAudioEarlyOpenGeometry) -and !$WeaponAudioEarly){throw 'EarlyReflections proof/geometry requires its explicit native fixture'}
if($WeaponAudioWhiz){
    $whizAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponAudioWhiz','WeaponAudioWhizAuthoringDirectory','WeaponAudioWhizNoSound','ThreadedLoading')
    if(!$WeaponAudioWhizAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $whizAllowed}).Count){throw 'WhizBy requires its standalone native audio component/static caller lane and current proof'}
    $AutoRespawnActivation=$true
}
if(($WeaponAudioWhizAuthoringDirectory -or $WeaponAudioWhizNoSound) -and !$WeaponAudioWhiz){throw 'WhizBy proof/backend requires its explicit native fixture'}
if($WeaponAudioDispatch){
    $audioDispatchAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponAudioDispatch','WeaponAudioDispatchAuthoringDirectory','ThreadedLoading')
    if(!$WeaponAudioDispatchAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $audioDispatchAllowed}).Count){throw 'Static audio dispatch requires its standalone native state/caller lane and current proof'}
    $AutoRespawnActivation=$true
}
if($WeaponAudioDispatchAuthoringDirectory -and !$WeaponAudioDispatch){throw 'Static audio dispatch proof requires its explicit native fixture'}
if($WeaponAudioMath){
    $audioMathAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponAudioMath','WeaponAudioMathAuthoringDirectory','ThreadedLoading')
    if(!$WeaponAudioMathAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $audioMathAllowed}).Count){throw 'Static weapon audio math requires its typed Object/static Blueprint caller lane and current proof'}
    $AutoRespawnActivation=$true
}
if($WeaponAudioMathAuthoringDirectory -and !$WeaponAudioMath){throw 'Static audio math proof requires its explicit native fixture'}
if($WeaponFireCueNetwork){
    if(!$Network -or !$PawnWireIdentity -or !$IdentityBuildDirectory -or !$WeaponFireCueAuthoringDirectory){throw 'Network firing Cues require actual two-owner prediction and current Cue/identity proof'}
    $WeaponAbilityFireNetwork=$true
}
if($WeaponFireCues){
    $cueAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponFireCues','WeaponFireCueAuthoringDirectory','ThreadedLoading')
    if(!$WeaponFireCueAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $cueAllowed}).Count){throw 'Weapon firing Cues require their standalone native input/GAS/typed payload lane and current proof'}
    $AutoRespawnActivation=$true
}
if($WeaponFireCueAuthoringDirectory -and !$WeaponFireCues -and !$WeaponFireCueNetwork -and !$WeaponAudioCold){throw 'Firing Cue proof requires its explicit native fixture'}
if($NetShooterImpactNetwork){$NetShooterNetwork=$true}
if($NetShooterNetwork){
    if(!$Network -or !$PawnWireIdentity -or !$IdentityBuildDirectory -or !$NetShooterActorAuthoringDirectory){throw 'NetShooter network requires two actual clients and current native ability/Actor/identity proof'}
    $NetShooterAbility=$true
}
if($NetShooterAbility){
    $netAbilityAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','NetShooterAbility','NetShooterAbilityAuthoringDirectory','ThreadedLoading','NetShooterNetwork','NetShooterImpactNetwork','Network','PawnWireIdentity','IdentityBuildDirectory','NetShooterActorAuthoringDirectory','ServerPort')
    if(!$NetShooterAbilityAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $netAbilityAllowed}).Count){throw 'NetShooter ability requires its own native equipment/input/Cue/montage lane and current proof'}
    if([bool]$Network -ne [bool]$NetShooterNetwork){throw 'NetShooter network must select its actual predicted two-owner fixture'}
    $AutoRespawnActivation=$true
}
if($NetShooterAbilityAuthoringDirectory -and !$NetShooterAbility){throw 'NetShooter ability proof requires its explicit native fixture'}
if($NetShooterActor){
    $netActorAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','NetShooterActor','NetShooterActorAuthoringDirectory','ThreadedLoading')
    if(!$NetShooterActorAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $netActorAllowed}).Count){throw 'NetShooter Actor requires its native ray/overlap/physics lane and current proof'}
    $AutoRespawnActivation=$true
}
if($NetShooterActorAuthoringDirectory -and !$NetShooterActor -and !$NetShooterNetwork){throw 'NetShooter Actor proof requires its explicit native fixture'}
if($WeaponAbilityFireNetwork){
    if(!$Network -or !$PawnWireIdentity -or !$IdentityBuildDirectory){throw 'Network Weapon Fire requires actual two-owner transport and current native identity proof'}
    $WeaponAbilityFire=$true
}
if($PSBoundParameters.ContainsKey('WeaponFireNetworkWeapon') -and !$WeaponAbilityFireNetwork){throw 'Network weapon choice requires the explicit predicted firing lane'}
if($WeaponAbilityFire){
    $abilityFireAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponAbilityFire','WeaponAbilityFireAuthoringDirectory','WeaponActorFireAuthoringDirectory','WeaponActorBeginAuthoringDirectory','WeaponFireFXAuthoringDirectory','WeaponDecalsAuthoringDirectory','WeaponImpactsAuthoringDirectory','ThreadedLoading','WeaponAbilityFireNetwork','WeaponFireNetworkWeapon','Network','PawnWireIdentity','IdentityBuildDirectory','ServerPort','WeaponFireCueNetwork','WeaponFireCueAuthoringDirectory','WeaponAudioNetwork','WeaponAudioNetworkAuthoringDirectory')
    if(!$WeaponAbilityFireAuthoringDirectory -or !$WeaponActorFireAuthoringDirectory -or !$WeaponActorBeginAuthoringDirectory -or !$WeaponFireFXAuthoringDirectory -or !$WeaponDecalsAuthoringDirectory -or !$WeaponImpactsAuthoringDirectory -or
        @($PSBoundParameters.Keys|Where-Object {$_ -notin $abilityFireAllowed}).Count){throw 'Shared Weapon Fire requires its native input lane and current ability/Actor/FX proof chain'}
    if([bool]$Network -ne [bool]$WeaponAbilityFireNetwork){throw 'Weapon Fire Network must select its actual predicted firing fixture'}
    $AutoRespawnActivation=$true
}
if($WeaponAbilityFireAuthoringDirectory -and !$WeaponAbilityFire){throw 'Shared Weapon Fire proof requires its explicit native input fixture'}
if($WeaponImpacts){
    $weaponImpactsAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponImpacts','WeaponImpactsAuthoringDirectory','ThreadedLoading')
    if(!$WeaponImpactsAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $weaponImpactsAllowed}).Count){throw 'Weapon Impacts requires its native Niagara/channel/latent lane and current proof'}
    $AutoRespawnActivation=$true
}
if($WeaponImpactsAuthoringDirectory -and !$WeaponImpacts -and !$WeaponActorFire -and !$WeaponAbilityFire){throw 'Weapon Impacts proof requires its explicit fixture or parent integration'}
if($WeaponDecals){
    $weaponDecalsAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponDecals','WeaponDecalsAuthoringDirectory','ThreadedLoading')
    if(!$WeaponDecalsAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $weaponDecalsAllowed}).Count){throw 'Weapon Decals requires its native Niagara/latent lane and current proof'}
    $AutoRespawnActivation=$true
}
if($WeaponDecalsAuthoringDirectory -and !$WeaponDecals -and !$WeaponActorFire -and !$WeaponAbilityFire){throw 'Weapon Decals proof requires its explicit fixture or parent integration'}
if($WeaponFireFX){
    $weaponFXAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponFireFX','WeaponFireFXAuthoringDirectory','ThreadedLoading')
    if(!$WeaponFireFXAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $weaponFXAllowed}).Count){throw 'Weapon Fire FX requires its native Niagara/latent lane and current proof'}
    $AutoRespawnActivation=$true
}
if($WeaponFireFXAuthoringDirectory -and !$WeaponFireFX -and !$WeaponActorFire -and !$WeaponAbilityFire){throw 'Weapon Fire FX proof requires its explicit fixture or parent integration'}
if($WeaponActorBegin){
    $weaponBeginAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponActorBegin','WeaponActorBeginAuthoringDirectory','ThreadedLoading')
    if(!$WeaponActorBeginAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $weaponBeginAllowed}).Count){throw 'Weapon BeginPlay requires its isolated native team-lifetime lane and current proof'}
    $AutoRespawnActivation=$true
}
if($WeaponActorBeginAuthoringDirectory -and !$WeaponActorBegin -and !$WeaponActorFire -and !$WeaponActorHelpers -and !$WeaponAbilityFire){throw 'Weapon BeginPlay proof requires its explicit fixture or same-family regression'}
if($WeaponActorFire){
    $weaponFireAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponActorFire','WeaponActorFireAuthoringDirectory','WeaponActorBeginAuthoringDirectory','WeaponFireFXAuthoringDirectory','WeaponDecalsAuthoringDirectory','WeaponImpactsAuthoringDirectory','ThreadedLoading')
    if(!$WeaponActorFireAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $weaponFireAllowed}).Count){throw 'Weapon Fire requires its isolated original-FX lane and current proof'}
    $AutoRespawnActivation=$true
}
if($WeaponActorFireAuthoringDirectory -and !$WeaponActorFire -and !$WeaponActorHelpers -and !$WeaponAbilityFire){throw 'Weapon Fire proof requires its explicit fixture or helper-family regression'}
if($WeaponActorHelpers){
    $weaponHelperAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','WeaponActorHelpers','WeaponActorHelpersAuthoringDirectory','WeaponActorFireAuthoringDirectory','WeaponActorBeginAuthoringDirectory','ThreadedLoading')
    if(!$WeaponActorHelpersAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $weaponHelperAllowed}).Count){throw 'Weapon Actor helpers require their isolated native child-instance lane and current proof'}
    $AutoRespawnActivation=$true
}
if($WeaponActorHelpersAuthoringDirectory -and !$WeaponActorHelpers){throw 'Weapon helper proof requires its explicit fixture'}
if($GrenadeFlightNetwork){
    if(!$Network -or !$PawnWireIdentity -or !$IdentityBuildDirectory -or !$GrenadeFlightAbilityAuthoringDirectory){throw 'Natural Grenade flight requires actual predicted network and current ability/identity proof'}
    $GrenadeDetonateNetwork=$true
}
if($GrenadeFlightAbilityAuthoringDirectory -and !$GrenadeFlightNetwork){throw 'Natural Grenade ability proof requires its explicit flight lane'}
if($GrenadeDetonateNetwork){
    if(!$Network -or !$PawnWireIdentity -or !$IdentityBuildDirectory){throw 'Network explosion requires two native clients and current read-only wire identity proof'}
    $GrenadeDetonate=$true
}
if($GrenadeDetonate){
    $detonateAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','GrenadeDetonate','GrenadeDetonateAuthoringDirectory','ThreadedLoading','GrenadeDetonateNetwork','Network','PawnWireIdentity','IdentityBuildDirectory','ServerPort','GrenadeFlightNetwork','GrenadeFlightAbilityAuthoringDirectory')
    if(!$GrenadeDetonateAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $detonateAllowed}).Count){throw 'Grenade explosion requires its isolated native RPC/fuse/GAS lane and current proof'}
    if([bool]$Network -ne [bool]$GrenadeDetonateNetwork){throw 'Network explosion must explicitly select its actual replicated Actor lane'}
    $AutoRespawnActivation=$true
}
if($GrenadeDetonateAuthoringDirectory -and !$GrenadeDetonate){throw 'Explosion revision requires its explicit differential lane'}
if($GrenadeHit){
    $hitAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','GrenadeHit','GrenadeHitAuthoringDirectory','ThreadedLoading')
    if(!$GrenadeHitAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $hitAllowed}).Count){throw 'Grenade Hit requires separate actual blocking-contact lane and current proof'}
    $AutoRespawnActivation=$true
}
if($GrenadeHitAuthoringDirectory -and !$GrenadeHit -and !$GrenadeBegin -and !$GrenadeActions -and !$GrenadeCleanup -and !$GrenadeVFX){throw 'Grenade Hit proof requires its explicit fixture or current family regression'}
if($GrenadeHeadless -and (!$GrenadeBegin -or $Network)){throw 'Headless Grenade requires its dedicated native server-only BeginPlay lane'}
if($GrenadeBegin){
    $beginAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','GrenadeBegin','GrenadeBeginAuthoringDirectory','GrenadeHitAuthoringDirectory','GrenadeHeadless','ThreadedLoading')
    if(!$GrenadeBeginAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $beginAllowed}).Count){throw 'Grenade BeginPlay requires separate native Actor-owned timer lane and current proof'}
    $AutoRespawnActivation=$true
}
if($GrenadeBeginAuthoringDirectory -and !$GrenadeBegin -and !$GrenadeActions -and !$GrenadeCleanup -and !$GrenadeVFX){throw 'Grenade BeginPlay revision requires its explicit fixture or current family regression'}
if($GrenadeActions){
    $actionAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','GrenadeActions','GrenadeActionsAuthoringDirectory','GrenadeBeginAuthoringDirectory','GrenadeHitAuthoringDirectory','ThreadedLoading')
    if(!$GrenadeActionsAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $actionAllowed}).Count){throw 'Grenade actions require separate native ordinary-entry lane and current Actor proof'}
    $AutoRespawnActivation=$true
}
if($GrenadeActionsAuthoringDirectory -and !$GrenadeActions -and !$GrenadeCleanup -and !$GrenadeVFX){throw 'Grenade action revision requires its dedicated fixture or current family regression'}
if($GrenadeCleanup){
    $cleanupAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','GrenadeCleanup','GrenadeCleanupAuthoringDirectory','GrenadeActionsAuthoringDirectory','GrenadeBeginAuthoringDirectory','GrenadeHitAuthoringDirectory','ThreadedLoading')
    if(!$GrenadeCleanupAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $cleanupAllowed}).Count){throw 'Grenade cleanup requires a separate original native timer Actor lane and current revision'}
    $AutoRespawnActivation=$true
}
if($GrenadeCleanupAuthoringDirectory -and !$GrenadeCleanup -and !$GrenadeVFX){throw 'Grenade cleanup revision requires its dedicated fixture or VFX regression'}
if($GrenadeVFX){
    $vfxAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','GrenadeVFX','GrenadeVFXAuthoringDirectory','GrenadeCleanupAuthoringDirectory','GrenadeActionsAuthoringDirectory','GrenadeBeginAuthoringDirectory','GrenadeHitAuthoringDirectory','ThreadedLoading')
    if(!$GrenadeVFXAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $vfxAllowed}).Count){throw 'Grenade VFX requires its separate standalone Actor lane and current proof'}
    $AutoRespawnActivation=$true
}
if($GrenadeVFXAuthoringDirectory -and !$GrenadeVFX){throw 'Grenade VFX proof requires its dedicated fixture'}
if($GrenadeActivationNetwork){
    if(!$Network -or !$PawnWireIdentity){throw 'Grenade predicted activation requires the real two-owner Network lane and native wire identity'}
    $GrenadeActivation=$true
}
if($GrenadeActivation){
    $grenadeAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','GrenadeActivation','GrenadeActivationNetwork','GrenadeAuthoringDirectory','ThreadedLoading','Network','ServerPort','PawnWireIdentity','IdentityBuildDirectory')
    if(!$GrenadeAuthoringDirectory -or @($PSBoundParameters.Keys|Where-Object {$_ -notin $grenadeAllowed}).Count){throw 'Grenade activation requires a separate standalone lane and current revision proof'}
    if([bool]$Network -ne [bool]$GrenadeActivationNetwork){throw 'Network Grenade activation must explicitly request its predicted two-owner fixture'}
    $AutoRespawnActivation=$true
}
if($GrenadeWidget){
    if(!$GrenadeAuthoringDirectory -or $MeleeTrace -or $MeleeHitMontage -or $DashSelector -or $CharacterAuthoringDirectory){throw 'Grenade UI native grant/avatar/removal requires its separate lane and current asset proof'}
    $grenadeAllowed=@('EngineRoot','StageProject','OutputDirectory','AssetAuthoringDirectory','GrenadeWidget','GrenadeAuthoringDirectory','ThreadedLoading','Network','ServerPort','MeleeCharacterStartupProfile','PawnWireIdentity','IdentityBuildDirectory','LazyPawnLifecycle','JoinResetStress')
    if(@($PSBoundParameters.Keys|Where-Object {$_ -notin $grenadeAllowed}).Count){throw 'Do not combine Grenade UI with another native fixture'}
    $AutoRespawnActivation=$true
}
if($GrenadeAuthoringDirectory -and !$GrenadeWidget -and !$GrenadeActivation){throw 'Grenade asset proof requires its dedicated fixture flag'}
if($PawnWireIdentity -and ((!$NotificationRelaysNetwork -and !$GrenadeWidget -and !$GrenadeActivationNetwork -and !$GrenadeDetonateNetwork -and !$WeaponAbilityFireNetwork -and !$NetShooterNetwork) -or !$Network -or !$IdentityBuildDirectory)){throw 'Native wire identity requires a two-owner gameplay lane and reviewed build proof'}
if($IdentityBuildDirectory -and !$PawnWireIdentity){throw 'Identity build proof requires explicit wire-identity acceptance'}
if($LazyPawnLifecycle -and (!$PawnWireIdentity -or $MeleeCharacterStartupProfile)){throw 'Lazy lifecycle requires native wire proof and no preloaded Character treatment'}
if($JoinResetStress -and !$LazyPawnLifecycle){throw 'Native join Reset stress requires lazy lifecycle plus wire proof'}
if($MeleeTrace){
    if(!$MeleeTraceAuthoringDirectory -or ($Network -and !$MeleeNetworkFixtureAuthoringDirectory)){throw 'Melee trace requires its revision proof and a replicated native floor for Network'}
    $MeleeHitMontage=$true
}
if($MeleeNetworkFixtureAuthoringDirectory -and (!$MeleeTrace -or !$Network)){throw 'Replicated Melee floor proof belongs only to the native trace Network lane'}
if($MeleeCharacterStartupProfile -and ((!$MeleeTrace -and !$GrenadeWidget) -or !$Network)){throw 'Character startup profile is an explicit replica diagnosis Network variant'}
if($MeleeCharacterOriginalBeginPlay -and $MeleeCharacterStartupProfile -ne 'Python'){throw 'Original BeginPlay isolation requires matched Python startup variant'}
if($MeleeWarmupJoin -and $MeleeCharacterStartupProfile -ne 'Python'){throw 'Controlled warmup join requires explicit Python Melee Network diagnosis'}
if($MeleeCharacterOriginalSubset -and ($MeleeCharacterStartupProfile -ne 'Python' -or $MeleeCharacterOriginalBeginPlay)){throw 'Method subset isolation requires matched Python startup and no other treatment'}
if($MeleeTraceAuthoringDirectory -and !$MeleeActivationAuthoringDirectory){throw 'Melee trace requires complete guarded activation provenance'}
if($MeleeActivation){
    if(!$MeleeActivationAuthoringDirectory){throw 'Melee activation requires its native task lane and revision proof'}
    $MeleeHitMontage=$true
}
if($MeleeActivationAuthoringDirectory -and !$MeleeAuthoringDirectory){throw 'Melee activation revision requires original helper provenance'}
if($MeleeHitMontage){
    if(!$MeleeAuthoringDirectory -or $DashSelector -or $CharacterAuthoringDirectory){throw 'Melee helper requires its own typed caller and authored proof'}
    $AutoRespawnActivation=$true
}
if($DashTasksNetworkLifecycle){
    if(!$Network -or $DashTasksLifecycle){throw 'Two-owner task lifecycle requires its separate native Network lane'}
    $DashTasks=$true
}
if($DashTasksLifecycle){
    if($Network){throw 'Standalone native task lifecycle matrix is separate from two-owner lifecycle regression'}
    $DashTasks=$true
}
if($DashTasks){
    if(!$DashTasksAuthoringDirectory){throw 'Dash task business requires its accepted Delay/dispatch revision'}
    $DashActivation=$true
}
if($DashTasksAuthoringDirectory -and !$DashActivationAuthoringDirectory){throw 'Task revision requires complete activation provenance'}
if($DashActivation){
    if(!$DashActivationAuthoringDirectory){throw 'Actual Dash activation requires its accepted task-entry revision'}
    $DashLocalDirection=$true
}
if($DashActivationAuthoringDirectory -and !$DashLocalDirectionAuthoringDirectory){throw 'Activation revision requires complete local direction provenance'}
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
function Get-JumpCurrentActorAssets($FallbackAuthor){
    if($GrenadeHitAuthoringDirectory -and !$GrenadeHit){
        if(!$GrenadeBeginAuthoringDirectory){throw 'Current Hit family regression requires preceding BeginPlay proof'}
        $currentRoot=[IO.Path]::GetFullPath($GrenadeHitAuthoringDirectory);$parentRoot=[IO.Path]::GetFullPath($GrenadeBeginAuthoringDirectory)
        if(!$currentRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$parentRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned current Hit family required'}
        $currentSummary=Join-Path $currentRoot 'summary.json';$currentReport=Join-Path $currentRoot 'assets.json';$parentSummary=Join-Path $parentRoot 'summary.json'
        $author=Get-Content -LiteralPath $currentSummary -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $currentReport -Raw|ConvertFrom-Json -Depth 80
        $parentHash=(Get-FileHash -LiteralPath $parentSummary).Hash
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne 'grenadehit' -or $proof.kind -ne 'grenadehit' -or
            $author.previous_dash_directory -ne $parentRoot -or !@($author.hashes|Where-Object {$_.path -eq $parentSummary -and $_.sha256 -eq $parentHash}).Count -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_server_rpc_flags_preserved -or !$proof.native_register_restore_passed -or
            $proof.actual_registered_profile_method_counts.Python -ne 6 -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 6 -or
            !$proof.original_hit_policy.all_reflected_inputs_preserved -or $proof.actor_detonate_damage_business_migrated -or @($author.assets).Count -ne 2){throw 'Current Hit family native revision chain proof incomplete'}
        Add-JumpInput $currentSummary;Add-JumpInput $currentReport
        return @($author.assets)
    }
    if(!$GrenadeBeginAuthoringDirectory -or $GrenadeBegin){return @($FallbackAuthor.assets)}
    if(!$GrenadeActionsAuthoringDirectory){throw 'Current BeginPlay family regression requires preceding action proof'}
    $currentRoot=[IO.Path]::GetFullPath($GrenadeBeginAuthoringDirectory);$parentRoot=[IO.Path]::GetFullPath($GrenadeActionsAuthoringDirectory)
    if(!$currentRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$parentRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned current BeginPlay family required'}
    $currentSummary=Join-Path $currentRoot 'summary.json';$currentReport=Join-Path $currentRoot 'assets.json';$parentSummary=Join-Path $parentRoot 'summary.json'
    $author=Get-Content -LiteralPath $currentSummary -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $currentReport -Raw|ConvertFrom-Json -Depth 80
    $parentHash=(Get-FileHash -LiteralPath $parentSummary).Hash
    if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne 'grenadebegin' -or $proof.kind -ne 'grenadebegin' -or
        $author.previous_dash_directory -ne $parentRoot -or !@($author.hashes|Where-Object {$_.path -eq $parentSummary -and $_.sha256 -eq $parentHash}).Count -or
        !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_server_rpc_flags_preserved -or !$proof.native_register_restore_passed -or
        $proof.actual_registered_profile_method_counts.Python -ne 5 -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 5 -or
        $proof.original_begin_policy.native_function_name_api -ne 'K2_SetTimer' -or $proof.original_begin_policy.new_native_adapters -ne 0 -or
        $proof.actor_detonate_damage_business_migrated -or @($author.assets).Count -ne 2){throw 'Current BeginPlay family native revision chain proof incomplete'}
    Add-JumpInput $currentSummary;Add-JumpInput $currentReport
    return @($author.assets)
}
function Write-UEPJumpExitToken {
    param([string]$Path,[hashtable]$Token,[string]$OutputRoot)
    $target=[IO.Path]::GetFullPath($Path);$parent=[IO.Path]::GetFullPath($OutputRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if([IO.Path]::GetDirectoryName($target) -ne $parent -or $Token.peer -notin @('A','B0') -or
        [IO.Path]::GetFileName($target) -ne ($Token.peer+'-exited.json') -or $Token.exit_code -ne 0 -or !$Token.run_id){throw 'Invalid owned native exit token'}
    if([IO.File]::Exists($target)){throw 'Do not overwrite a previously published native exit token'}
    $temporary=Join-Path $parent ('.'+[IO.Path]::GetFileName($target)+'.'+[guid]::NewGuid().ToString('N')+'.tmp')
    try{
        [IO.File]::WriteAllText($temporary,($Token|ConvertTo-Json -Compress),[Text.UTF8Encoding]::new($false))
        # First creation: rename only after the complete JSON stream is closed.
        [IO.File]::Move($temporary,$target)
    }finally{if([IO.File]::Exists($temporary)){Remove-Item -LiteralPath $temporary -Force}}
}
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
                if($DashActivationAuthoringDirectory){
                    $activationRoot=[IO.Path]::GetFullPath($DashActivationAuthoringDirectory)
                    if(!$activationRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Activation proof must be workspace-owned'}
                    if($DashTasksAuthoringDirectory){
                        $tasksRoot=[IO.Path]::GetFullPath($DashTasksAuthoringDirectory)
                        if(!$tasksRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Tasks proof must be workspace-owned'}
                        $revision=Get-UEPDashTasksRevision $dashRoot $revisionRoot $localRoot $activationRoot $tasksRoot
                    }else{$revision=Get-UEPDashActivationRevision $dashRoot $revisionRoot $localRoot $activationRoot}
                }else{$revision=Get-UEPDashLocalDirectionRevision $dashRoot $revisionRoot $localRoot}
            }else{$revision=Get-UEPDashRPCInputRevision $dashRoot $revisionRoot}
            $currentDashAssets=@($revision.assets)
            foreach($file in $revision.evidence){Add-JumpInput $file}
            Add-JumpInput (Join-Path $PSScriptRoot 'UEPDashAssetProvenance.ps1')
        }
        foreach($asset in $currentDashAssets){
            if((Get-FileHash -LiteralPath $asset.stage).Hash -ne $asset.sha256 -or (Get-FileHash -LiteralPath $asset.overlay).Hash -ne $asset.sha256){throw 'Dash authored asset changed'}
            Add-JumpInput $asset.stage;Add-JumpInput $asset.overlay
        }
        if($DashTasks){
            $sourceProject=(Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json).source
            $cueRelative='Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_Dash.uasset'
            $stageCue=Join-Path $stage $cueRelative;$sourceCue=Join-Path (Split-Path $sourceProject -Parent) $cueRelative
            if((Get-FileHash -LiteralPath $stageCue).Hash -ne (Get-FileHash -LiteralPath $sourceCue).Hash){throw 'Native Dash Cue observer requires unchanged official Cue bytes'}
            Add-JumpInput $stageCue;Add-JumpInput $sourceCue
            $typedRelative='Content/UEPInterop/BP_UEPGameplayMessages.uasset'
            $typedStage=Join-Path $stage $typedRelative;$typedOverlay=Join-Path $repo "Demos/UEPLyraIntegration/Overlay/$typedRelative"
            if((Get-FileHash -LiteralPath $typedStage).Hash -ne (Get-FileHash -LiteralPath $typedOverlay).Hash){throw 'Typed producer reader/broadcaster bytes differ'}
            Add-JumpInput $typedStage;Add-JumpInput $typedOverlay
        }
        $private=@($dashProof.caller_probe)+@($dashProof.inherited_declaration_probe.assets)
        foreach($item in $private){$path=if($item.PSObject.Properties['asset']){$item.asset}else{$item.path};if((Get-FileHash -LiteralPath $path).Hash -ne $item.sha256){throw 'Dash private probe changed'};Add-JumpInput $path}
        foreach($entry in $dashProof.reference_hashes.PSObject.Properties){if((Get-FileHash -LiteralPath $entry.Name).Hash -ne $entry.Value){throw 'Official Dash changed'};Add-JumpInput $entry.Name}
        Add-JumpInput $dashSummary;Add-JumpInput $dashReport
    }
    if($PawnWireIdentity){
        $identityRoot=[IO.Path]::GetFullPath($IdentityBuildDirectory)
        if(!$identityRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned identity build proof required'}
        $identityBuildPath=Join-Path $identityRoot 'summary.json';$identityBuild=Get-Content -LiteralPath $identityBuildPath -Raw|ConvertFrom-Json -Depth 80
        $identityDll=Join-Path $stage 'Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPNetworkIdentity.dll'
        if($identityBuild.status -ne 'built_requires_native_acceptance' -or !$identityBuild.checked_engine_and_existing_binaries_unchanged -or
            $identityBuild.engine_full_compile_executed -or $identityBuild.lyra_cpp_compile_executed -or $identityBuild.identity_dll.path -ne $identityDll -or
            (Get-FileHash -LiteralPath $identityDll).Hash -ne $identityBuild.identity_dll.sha256){throw 'Current reviewed read-only identity DLL required'}
        foreach($row in $identityBuild.source_hashes){foreach($path in @($row.path,$row.stage)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $row.sha256){throw 'Identity build source changed'};Add-JumpInput $path
        }}
        Add-JumpInput $identityBuildPath;Add-JumpInput $identityDll
    }
    if($GeneralAudio){
        $generalRoot=[IO.Path]::GetFullPath($GeneralAudioAuthoringDirectory)
        if(!$generalRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned GeneralAudio revision required'}
        $generalSummary=Join-Path $generalRoot 'summary.json';$generalProofPath=Join-Path $generalRoot 'assets.json'
        $generalAuthor=Get-Content -LiteralPath $generalSummary -Raw|ConvertFrom-Json -Depth 100;$generalProof=Get-Content -LiteralPath $generalProofPath -Raw|ConvertFrom-Json -Depth 100
        if($generalAuthor.status -ne 'passed' -or $generalProof.status -ne 'passed' -or $generalAuthor.kind -ne 'generalaudio' -or !$generalProof.original_full_cdo_preserved -or
           !$generalProof.original_static_signature_flags_preserved -or !$generalProof.original_business_graph_preserved_with_dispatch -or $generalProof.static_functions_registered_as_mixins -or
           $generalProof.original_graph_nodes -ne 8 -or $generalProof.transport_nodes -ne 5 -or @($generalAuthor.assets).Count -ne 3 -or
           $generalProof.actual_registered_profile_method_counts.Python -ne 1 -or $generalProof.actual_registered_profile_method_counts.BlueprintFallback -ne 1){throw 'Current GeneralAudio static/ordinary Object proof incomplete'}
        foreach($asset in $generalAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash $path).Hash -ne $asset.sha256){throw 'GeneralAudio asset changed'};Add-JumpInput $path}}
        if((Get-FileHash $generalProof.caller_probe.asset).Hash -ne $generalProof.caller_probe.sha256){throw 'GeneralAudio BP caller changed'}
        Add-JumpInput $generalProof.caller_probe.asset;Add-JumpInput $generalSummary;Add-JumpInput $generalProofPath
        foreach($p in @('Content/Audio/Blueprints/B_MusicManagerComponent_Base.uasset','Content/UEPMixins/DA_MusicManagerMixin.uasset')){Add-JumpInput (Join-Path $stage $p)}
        Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')
    }
    if($WindSystem){
        $windRoot=[IO.Path]::GetFullPath($WindSystemAuthoringDirectory)
        if(!$windRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned wind revision required'}
        $windSummary=Join-Path $windRoot 'summary.json';$windProofPath=Join-Path $windRoot 'assets.json'
        $windAuthor=Get-Content -LiteralPath $windSummary -Raw|ConvertFrom-Json -Depth 100;$windProof=Get-Content -LiteralPath $windProofPath -Raw|ConvertFrom-Json -Depth 100
        if($windAuthor.status -ne 'passed' -or $windProof.status -ne 'passed' -or $windAuthor.kind -ne 'windsystem' -or !$windProof.original_full_cdo_preserved -or
           !$windProof.original_business_graphs_preserved_with_dispatch -or !$windProof.native_multigate_state_reused -or !$windProof.native_array_set_and_no_resize_preserved -or
           $windProof.original_graph_nodes -ne 62 -or $windProof.transport_nodes -ne 18 -or @($windAuthor.assets).Count -ne 2 -or
           $windProof.actual_registered_profile_method_counts.Python -ne 3 -or $windProof.actual_registered_profile_method_counts.BlueprintFallback -ne 3){throw 'Current wind scheduler/array/source graph proof incomplete'}
        foreach($asset in $windAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash $path).Hash -ne $asset.sha256){throw 'Wind asset changed'};Add-JumpInput $path}}
        Add-JumpInput $windSummary;Add-JumpInput $windProofPath
    }
    if($MusicFamily){
        $familyRoot=[IO.Path]::GetFullPath($MusicFamilyAuthoringDirectory)
        if(!$familyRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned music family revision required'}
        $familySummary=Join-Path $familyRoot 'summary.json';$familyProofPath=Join-Path $familyRoot 'assets.json'
        $familyAuthor=Get-Content -LiteralPath $familySummary -Raw|ConvertFrom-Json -Depth 100;$familyProof=Get-Content -LiteralPath $familyProofPath -Raw|ConvertFrom-Json -Depth 100
        if($familyAuthor.status -ne 'passed' -or $familyProof.status -ne 'passed' -or $familyAuthor.kind -ne 'musicfamily' -or !$familyProof.original_full_cdos_and_signatures_preserved -or
           !$familyProof.original_business_graphs_preserved_with_dispatch -or !$familyProof.base_graphs_unchanged -or !$familyProof.base_owned_mixin_only -or !$familyProof.native_cp_listener_reused -or
           $familyProof.native_parent_calls_preserved -ne 3 -or $familyProof.native_delay_nodes_reused -ne 3 -or $familyProof.transport_nodes -ne 24 -or @($familyAuthor.assets).Count -ne 5 -or
           $familyProof.actual_registered_profile_method_counts.Python -ne 11 -or $familyProof.actual_registered_profile_method_counts.BlueprintFallback -ne 11){throw 'Current music parent/latent/listener family proof incomplete'}
        foreach($asset in $familyAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash $path).Hash -ne $asset.sha256){throw 'Music family asset changed'};Add-JumpInput $path}}
        if((Get-FileHash $familyProof.caller_probe.asset).Hash -ne $familyProof.caller_probe.sha256){throw 'Music CP message probe changed'}
        Add-JumpInput $familyProof.caller_probe.asset;Add-JumpInput $familySummary;Add-JumpInput $familyProofPath
        Add-JumpInput (Join-Path $stage 'Content/UEPValidation/BP_MusicListenerProbe.uasset');Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')
    }
    if($MusicLifecycle){
        $lifeRoot=[IO.Path]::GetFullPath($MusicLifecycleAuthoringDirectory)
        if(!$lifeRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned music lifecycle revision required'}
        $lifeSummary=Join-Path $lifeRoot 'summary.json';$lifeProofPath=Join-Path $lifeRoot 'assets.json'
        $lifeAuthor=Get-Content -LiteralPath $lifeSummary -Raw|ConvertFrom-Json -Depth 100;$lifeProof=Get-Content -LiteralPath $lifeProofPath -Raw|ConvertFrom-Json -Depth 100
        if($lifeAuthor.status -ne 'passed' -or $lifeProof.status -ne 'passed' -or $lifeAuthor.kind -ne 'musiclifecycle' -or !$lifeProof.original_full_cdo_and_signatures_preserved -or
           !$lifeProof.original_business_graphs_preserved_with_dispatch -or !$lifeProof.no_python_subscription_roots -or !$lifeProof.native_listener_lifetime_unchanged -or
           $lifeProof.native_listener_nodes_reused -ne 2 -or $lifeProof.transport_nodes -ne 9 -or @($lifeAuthor.assets).Count -ne 2 -or
           $lifeProof.actual_registered_profile_method_counts.Python -ne 8 -or $lifeProof.actual_registered_profile_method_counts.BlueprintFallback -ne 8){throw 'Current native music listener/base-profile proof incomplete'}
        foreach($asset in $lifeAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Music lifecycle asset changed'};Add-JumpInput $path}}
        foreach($property in $lifeProof.child_asset_hashes.PSObject.Properties){$path=Join-Path $stage $property.Name;if((Get-FileHash $path).Hash -ne $property.Value){throw 'Music descendant changed'};Add-JumpInput $path}
        if((Get-FileHash $lifeProof.caller_probe.asset).Hash -ne $lifeProof.caller_probe.sha256){throw 'Music native GMS probe changed'}
        Add-JumpInput $lifeProof.caller_probe.asset;Add-JumpInput $lifeSummary;Add-JumpInput $lifeProofPath;Add-JumpInput (Join-Path $stage 'Content/B_LyraGameInstance.uasset')
        Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')
    }
    if($MusicControls){
        $musicRoot=[IO.Path]::GetFullPath($MusicControlsAuthoringDirectory)
        if(!$musicRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned music controls revision required'}
        $musicSummary=Join-Path $musicRoot 'summary.json';$musicProofPath=Join-Path $musicRoot 'assets.json'
        $musicAuthor=Get-Content -LiteralPath $musicSummary -Raw|ConvertFrom-Json -Depth 100;$musicProof=Get-Content -LiteralPath $musicProofPath -Raw|ConvertFrom-Json -Depth 100
        if($musicAuthor.status -ne 'passed' -or $musicProof.status -ne 'passed' -or $musicAuthor.kind -ne 'musiccontrols' -or !$musicProof.original_full_cdo_preserved -or
            !$musicProof.original_graphs_unmodified -or !$musicProof.original_begin_play_listeners_preserved -or !$musicProof.child_cdos_signatures_and_asset_bytes_preserved -or
            $musicProof.original_graph_nodes -ne 99 -or $musicProof.transport_nodes -ne 0 -or @($musicAuthor.assets).Count -ne 2 -or
            $musicProof.actual_registered_profile_method_counts.Python -ne 5 -or $musicProof.actual_registered_profile_method_counts.BlueprintFallback -ne 5){throw 'Current music base/CDO/inheritance/listener proof incomplete'}
        foreach($asset in $musicAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Music control asset changed'};Add-JumpInput $path}}
        foreach($property in $musicProof.child_asset_hashes.PSObject.Properties){$path=Join-Path $stage $property.Name;if((Get-FileHash -LiteralPath $path).Hash -ne $property.Value){throw 'Music descendant asset changed'};Add-JumpInput $path}
        if((Get-FileHash -LiteralPath $musicProof.caller_probe.asset).Hash -ne $musicProof.caller_probe.sha256){throw 'Music Blueprint caller changed'}
        Add-JumpInput $musicProof.caller_probe.asset;Add-JumpInput $musicSummary;Add-JumpInput $musicProofPath
        Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')
    }
    if($WeaponAudioEarly -or $WeaponAudioCold -or $WeaponAudioNetwork){
        $earlyRoot=[IO.Path]::GetFullPath($(if($WeaponAudioCold){$WeaponAudioColdAuthoringDirectory}elseif($WeaponAudioNetwork){$WeaponAudioNetworkAuthoringDirectory}else{$WeaponAudioEarlyAuthoringDirectory}))
        if(!$earlyRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned static EarlyReflections revision required'}
        $earlySummary=Join-Path $earlyRoot 'summary.json';$earlyProofPath=Join-Path $earlyRoot 'assets.json'
        $earlyAuthor=Get-Content -LiteralPath $earlySummary -Raw|ConvertFrom-Json -Depth 100;$earlyProof=Get-Content -LiteralPath $earlyProofPath -Raw|ConvertFrom-Json -Depth 100
        if($earlyAuthor.status -ne 'passed' -or $earlyProof.status -ne 'passed' -or $earlyAuthor.kind -ne 'weaponaudioearly' -or
           !$earlyProof.original_full_cdo_preserved -or !$earlyProof.original_static_signatures_flags_preserved -or !$earlyProof.original_local_defaults_preserved -or
           !$earlyProof.original_business_graphs_preserved_with_dispatch -or !$earlyProof.existing_math_transport_preserved -or !$earlyProof.existing_dispatch_transport_preserved -or !$earlyProof.existing_whiz_transport_preserved -or
           $earlyProof.static_functions_registered_as_mixins -or $earlyProof.transport_nodes -ne 5 -or @($earlyAuthor.assets).Count -ne 3 -or
           $earlyProof.actual_registered_profile_method_counts.Python -ne 1 -or $earlyProof.actual_registered_profile_method_counts.BlueprintFallback -ne 1){throw 'Current static EarlyReflections dispatch proof incomplete'}
        foreach($asset in $earlyAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Static EarlyReflections asset changed'};Add-JumpInput $path}}
        if((Get-FileHash -LiteralPath $earlyProof.caller_probe.asset).Hash -ne $earlyProof.caller_probe.sha256){throw 'Static EarlyReflections Blueprint caller changed'}
        Add-JumpInput $earlyProof.caller_probe.asset;Add-JumpInput $earlySummary;Add-JumpInput $earlyProofPath
        foreach($path in @('Content/UEPMixins/BP_WeaponAudioMathRouter.uasset','Content/UEPMixins/DA_WeaponAudioMathMixin.uasset','Content/UEPValidation/BP_WeaponAudioMathCaller.uasset',
            'Content/UEPMixins/BP_WeaponAudioDispatchRouter.uasset','Content/UEPMixins/DA_WeaponAudioDispatchMixin.uasset','Content/UEPValidation/BP_WeaponAudioDispatchCaller.uasset',
            'Content/UEPMixins/BP_WeaponAudioWhizRouter.uasset','Content/UEPMixins/DA_WeaponAudioWhizMixin.uasset','Content/UEPValidation/BP_WeaponAudioWhizCaller.uasset','Content/Audio/Effects/SubmixEffects/TAP_EarlyReflections.uasset')){Add-JumpInput (Join-Path $stage $path)}
        if($WeaponAudioCold){foreach($path in @('Content/UEPValidation/BP_WeaponAbilityFireProbe.uasset','Content/Weapons/GA_Weapon_Fire.uasset','Content/Weapons/B_Weapon.uasset')){Add-JumpInput (Join-Path $stage $path)}}
        if($WeaponAudioEffect){Add-JumpInput (Join-Path $stage 'Content/Audio/Submixes/EarlyReflectionsSubmix.uasset');Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')}
    }
    if($WeaponAudioWhiz){
        $whizRoot=[IO.Path]::GetFullPath($WeaponAudioWhizAuthoringDirectory)
        if(!$whizRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned static WhizBy revision required'}
        $whizSummary=Join-Path $whizRoot 'summary.json';$whizProofPath=Join-Path $whizRoot 'assets.json'
        $whizAuthor=Get-Content -LiteralPath $whizSummary -Raw|ConvertFrom-Json -Depth 100;$whizProof=Get-Content -LiteralPath $whizProofPath -Raw|ConvertFrom-Json -Depth 100
        if($whizAuthor.status -ne 'passed' -or $whizProof.status -ne 'passed' -or $whizAuthor.kind -ne 'weaponaudiowhiz' -or
           !$whizProof.original_full_cdo_preserved -or !$whizProof.original_static_signatures_flags_preserved -or !$whizProof.original_local_defaults_preserved -or
           !$whizProof.original_business_graphs_preserved_with_dispatch -or !$whizProof.existing_math_transport_preserved -or !$whizProof.existing_dispatch_transport_preserved -or
           $whizProof.static_functions_registered_as_mixins -or $whizProof.transport_nodes -ne 5 -or @($whizAuthor.assets).Count -ne 3 -or
           $whizProof.actual_registered_profile_method_counts.Python -ne 1 -or $whizProof.actual_registered_profile_method_counts.BlueprintFallback -ne 1){throw 'Current static WhizBy dispatch proof incomplete'}
        foreach($asset in $whizAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Static WhizBy asset changed'};Add-JumpInput $path}}
        if((Get-FileHash -LiteralPath $whizProof.caller_probe.asset).Hash -ne $whizProof.caller_probe.sha256){throw 'Static WhizBy Blueprint caller changed'}
        Add-JumpInput $whizProof.caller_probe.asset;Add-JumpInput $whizSummary;Add-JumpInput $whizProofPath
        foreach($path in @('Content/UEPMixins/BP_WeaponAudioMathRouter.uasset','Content/UEPMixins/DA_WeaponAudioMathMixin.uasset','Content/UEPValidation/BP_WeaponAudioMathCaller.uasset',
            'Content/UEPMixins/BP_WeaponAudioDispatchRouter.uasset','Content/UEPMixins/DA_WeaponAudioDispatchMixin.uasset','Content/UEPValidation/BP_WeaponAudioDispatchCaller.uasset','Content/Audio/Effects/SubmixEffects/TAP_EarlyReflections.uasset')){Add-JumpInput (Join-Path $stage $path)}
        Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')
    }
    if($WeaponAudioDispatch){
        $dispatchRoot=[IO.Path]::GetFullPath($WeaponAudioDispatchAuthoringDirectory)
        if(!$dispatchRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned static audio dispatch revision required'}
        $dispatchSummary=Join-Path $dispatchRoot 'summary.json';$dispatchProofPath=Join-Path $dispatchRoot 'assets.json'
        $dispatchAuthor=Get-Content -LiteralPath $dispatchSummary -Raw|ConvertFrom-Json -Depth 100;$dispatchProof=Get-Content -LiteralPath $dispatchProofPath -Raw|ConvertFrom-Json -Depth 100
        if($dispatchAuthor.status -ne 'passed' -or $dispatchProof.status -ne 'passed' -or $dispatchAuthor.kind -ne 'weaponaudiodispatch' -or
           !$dispatchProof.original_full_cdo_preserved -or !$dispatchProof.original_static_signatures_flags_preserved -or !$dispatchProof.original_local_defaults_preserved -or
           !$dispatchProof.original_business_graphs_preserved_with_dispatch -or !$dispatchProof.existing_math_transport_preserved -or
           $dispatchProof.static_functions_registered_as_mixins -or $dispatchProof.transport_nodes -ne 20 -or @($dispatchAuthor.assets).Count -ne 3 -or
           $dispatchProof.actual_registered_profile_method_counts.Python -ne 4 -or $dispatchProof.actual_registered_profile_method_counts.BlueprintFallback -ne 4){throw 'Current four-function static audio dispatch proof incomplete'}
        foreach($asset in $dispatchAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Static audio dispatch asset changed'};Add-JumpInput $path}}
        if((Get-FileHash -LiteralPath $dispatchProof.caller_probe.asset).Hash -ne $dispatchProof.caller_probe.sha256){throw 'Static audio dispatch Blueprint caller changed'}
        Add-JumpInput $dispatchProof.caller_probe.asset;Add-JumpInput $dispatchSummary;Add-JumpInput $dispatchProofPath
        foreach($path in @('Content/UEPMixins/BP_WeaponAudioMathRouter.uasset','Content/UEPMixins/DA_WeaponAudioMathMixin.uasset','Content/UEPValidation/BP_WeaponAudioMathCaller.uasset','Content/Audio/Effects/SubmixEffects/TAP_EarlyReflections.uasset')){Add-JumpInput (Join-Path $stage $path)}
    }
    if($WeaponAudioMath){
        $mathRoot=[IO.Path]::GetFullPath($WeaponAudioMathAuthoringDirectory)
        if(!$mathRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned static audio math revision required'}
        $mathSummary=Join-Path $mathRoot 'summary.json';$mathProofPath=Join-Path $mathRoot 'assets.json'
        $mathAuthor=Get-Content -LiteralPath $mathSummary -Raw|ConvertFrom-Json -Depth 100;$mathProof=Get-Content -LiteralPath $mathProofPath -Raw|ConvertFrom-Json -Depth 100
        if($mathAuthor.status -ne 'passed' -or $mathProof.status -ne 'passed' -or $mathAuthor.kind -ne 'weaponaudiomath' -or
            !$mathProof.original_full_cdo_preserved -or !$mathProof.original_static_signatures_flags_preserved -or !$mathProof.original_local_defaults_preserved -or
            !$mathProof.original_business_graphs_preserved_with_dispatch -or $mathProof.static_functions_registered_as_mixins -or
            $mathProof.original_graph_nodes -ne 348 -or $mathProof.transport_nodes -ne 10 -or @($mathAuthor.assets).Count -ne 3 -or
            $mathProof.actual_registered_profile_method_counts.Python -ne 2 -or $mathProof.actual_registered_profile_method_counts.BlueprintFallback -ne 2){throw 'Current static ABI/typed audio math router proof incomplete'}
        foreach($asset in $mathAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Static audio math asset changed'};Add-JumpInput $path}}
        if((Get-FileHash -LiteralPath $mathProof.caller_probe.asset).Hash -ne $mathProof.caller_probe.sha256){throw 'Static Blueprint caller changed'}
        Add-JumpInput $mathProof.caller_probe.asset;Add-JumpInput $mathSummary;Add-JumpInput $mathProofPath
    }
    if($WeaponFireCues -or $WeaponFireCueNetwork -or $WeaponAudioCold){
        $cueRoot=[IO.Path]::GetFullPath($WeaponFireCueAuthoringDirectory)
        if(!$cueRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned firing Cue asset revision required'}
        $cueSummary=Join-Path $cueRoot 'summary.json';$cueProofPath=Join-Path $cueRoot 'assets.json'
        $cueAuthor=Get-Content -LiteralPath $cueSummary -Raw|ConvertFrom-Json -Depth 100
        $cueProof=Get-Content -LiteralPath $cueProofPath -Raw|ConvertFrom-Json -Depth 100
        if($cueAuthor.status -ne 'passed' -or $cueProof.status -ne 'passed' -or $cueAuthor.kind -ne 'weaponfirecues' -or
            !$cueProof.original_full_cdo_preserved -or !$cueProof.original_graphs_unmodified -or !$cueProof.native_register_restore_passed -or
            !$cueProof.original_native_burst_effects_preserved -or $cueProof.original_graph_nodes -ne 76 -or @($cueAuthor.assets).Count -ne 4 -or
            @($cueProof.actual_registered_profile_method_counts.PSObject.Properties|Where-Object {$_.Value.Python -ne 1 -or $_.Value.BlueprintFallback -ne 1}).Count){throw 'Current native firing Cue graph/CDO/OnBurst proof incomplete'}
        foreach($asset in $cueAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Firing Cue asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $cueSummary;Add-JumpInput $cueProofPath;Add-JumpInput (Join-Path $stage 'Content/UEPValidation/BP_WeaponAbilityFireProbe.uasset')
    }
    if($NetShooterAbility){
        $netAbilityRoot=[IO.Path]::GetFullPath($NetShooterAbilityAuthoringDirectory)
        if(!$netAbilityRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned NetShooter ability asset revision required'}
        $netAbilitySummary=Join-Path $netAbilityRoot 'summary.json';$netAbilityProofPath=Join-Path $netAbilityRoot 'assets.json'
        $netAbilityAuthor=Get-Content -LiteralPath $netAbilitySummary -Raw|ConvertFrom-Json -Depth 80
        $netAbilityProof=Get-Content -LiteralPath $netAbilityProofPath -Raw|ConvertFrom-Json -Depth 80
        if($netAbilityAuthor.status -ne 'passed' -or $netAbilityProof.status -ne 'passed' -or $netAbilityAuthor.kind -ne 'netshooterability' -or
            !$netAbilityProof.original_full_cdo_preserved -or !$netAbilityProof.original_graphs_unmodified -or !$netAbilityProof.original_empty_target_data_override_preserved -or
            !$netAbilityProof.native_weak_named_task_binding -or !$netAbilityProof.inherited_parent_namespace_preserved -or $netAbilityProof.inherited_selector_redeclared -or
            $netAbilityProof.transport_nodes -ne 8 -or $netAbilityProof.actual_registered_profile_method_counts.Python -ne 5 -or
            $netAbilityProof.actual_registered_profile_method_counts.BlueprintFallback -ne 5 -or @($netAbilityAuthor.assets).Count -ne 2){throw 'Current native NetShooter ability proof incomplete'}
        foreach($asset in $netAbilityAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'NetShooter ability asset changed'};Add-JumpInput $path
        }}
        $netParent=Join-Path $stage 'Content/Weapons/GA_Weapon_Fire.uasset'
        if((Get-FileHash -LiteralPath $netParent).Hash -ne $netAbilityProof.parent_asset_sha256){throw 'NetShooter shared fire parent changed'}
        Add-JumpInput $netAbilitySummary;Add-JumpInput $netAbilityProofPath;Add-JumpInput $netParent
    }
    if($NetShooterActor -or $NetShooterNetwork){
        $netActorRoot=[IO.Path]::GetFullPath($NetShooterActorAuthoringDirectory)
        if(!$netActorRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned NetShooter Actor asset revision required'}
        $netActorSummary=Join-Path $netActorRoot 'summary.json';$netActorProofPath=Join-Path $netActorRoot 'assets.json'
        $netActorAuthor=Get-Content -LiteralPath $netActorSummary -Raw|ConvertFrom-Json -Depth 80
        $netActorProof=Get-Content -LiteralPath $netActorProofPath -Raw|ConvertFrom-Json -Depth 80
        if($netActorAuthor.status -ne 'passed' -or $netActorProof.status -ne 'passed' -or $netActorAuthor.kind -ne 'netshooteractor' -or
            !$netActorProof.original_full_cdo_preserved -or !$netActorProof.original_rpc_flags_and_entry_preserved -or $netActorProof.rpc_function_overridden -or
            !$netActorProof.original_native_authority_do_once_preserved -or !$netActorProof.original_native_delay_node_uuid_preserved -or
            !$netActorProof.native_overlap_weak_named_delegate_preserved -or $netActorProof.transport_nodes -ne 11 -or
            $netActorProof.actual_registered_profile_method_counts.Python -ne 4 -or $netActorProof.actual_registered_profile_method_counts.BlueprintFallback -ne 4 -or
            @($netActorAuthor.assets).Count -ne 2){throw 'Current native NetShooter Actor transport proof incomplete'}
        foreach($asset in $netActorAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'NetShooter Actor asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $netActorSummary;Add-JumpInput $netActorProofPath
    }
    if($WeaponAbilityFire){
        $abilityFireRoot=[IO.Path]::GetFullPath($WeaponAbilityFireAuthoringDirectory)
        if(!$abilityFireRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned shared fire asset revision required'}
        $abilityFireSummary=Join-Path $abilityFireRoot 'summary.json';$abilityFireProofPath=Join-Path $abilityFireRoot 'assets.json'
        $abilityFireAuthor=Get-Content -LiteralPath $abilityFireSummary -Raw|ConvertFrom-Json -Depth 80
        $abilityFireProof=Get-Content -LiteralPath $abilityFireProofPath -Raw|ConvertFrom-Json -Depth 80
        if($abilityFireAuthor.status -ne 'passed' -or $abilityFireAuthor.kind -ne 'weaponabilityfire' -or $abilityFireProof.status -ne 'passed' -or
            !$abilityFireProof.original_full_cdo_preserved -or !$abilityFireProof.original_business_graphs_preserved_with_dispatch -or
            !$abilityFireProof.native_weak_named_task_binding -or !$abilityFireProof.native_function_name_timers -or $abilityFireProof.transport_nodes -ne 11 -or
            $abilityFireProof.actual_registered_profile_method_counts.Python -ne 10 -or $abilityFireProof.actual_registered_profile_method_counts.BlueprintFallback -ne 10 -or
            !$abilityFireProof.caller_probe.stage_only -or @($abilityFireAuthor.assets).Count -ne 2){throw 'Current ten-method native shared fire proof incomplete'}
        foreach($asset in $abilityFireAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Shared fire asset changed'};Add-JumpInput $path
        }}
        foreach($child in $abilityFireProof.inherited_children){foreach($path in @($child.stage,$child.original)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $child.sha256){throw 'Shared fire original child changed'};Add-JumpInput $path
        }}
        if((Get-FileHash -LiteralPath $abilityFireProof.caller_probe.asset).Hash -ne $abilityFireProof.caller_probe.sha256){throw 'Typed native fire probe changed'}
        Add-JumpInput $abilityFireProof.caller_probe.asset;Add-JumpInput $abilityFireSummary;Add-JumpInput $abilityFireProofPath
    }
    if($WeaponImpacts -or (($WeaponActorFire -or $WeaponAbilityFire) -and $WeaponImpactsAuthoringDirectory)){
        $impactRoot=[IO.Path]::GetFullPath($WeaponImpactsAuthoringDirectory)
        if(!$impactRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned weapon impact revision required'}
        $impactSummaryPath=Join-Path $impactRoot 'summary.json';$impactProofPath=Join-Path $impactRoot 'assets.json'
        $impactAuthor=Get-Content -LiteralPath $impactSummaryPath -Raw|ConvertFrom-Json -Depth 80;$impactProof=Get-Content -LiteralPath $impactProofPath -Raw|ConvertFrom-Json -Depth 80
        if($impactAuthor.status -ne 'passed' -or $impactProof.status -ne 'passed' -or $impactAuthor.kind -ne 'weaponimpacts' -or $impactProof.kind -ne 'weaponimpacts' -or
            !$impactProof.original_full_cdo_preserved -or !$impactProof.original_business_graphs_preserved_with_dispatch -or !$impactProof.original_retriggerable_delay_node_reused -or
            !$impactProof.native_delay_uuid_preserved -or !$impactProof.cleanup_tests_validity_not_active -or $impactProof.native_delay_seconds -ne 3 -or $impactProof.transport_nodes -ne 3 -or
            $impactProof.new_business_nodes -ne 0 -or !$impactProof.original_greater_distance_reuse_rule_preserved -or !$impactProof.original_typed_array_and_legacy_channel_apis_preserved -or $impactProof.actual_registered_profile_method_counts.Python -ne 6 -or $impactProof.actual_registered_profile_method_counts.BlueprintFallback -ne 6 -or @($impactAuthor.assets).Count -ne 2){throw 'Current native weapon impact delay/dispatch proof incomplete'}
        foreach($asset in $impactAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Weapon fire FX asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $impactSummaryPath;Add-JumpInput $impactProofPath
    }
    if($WeaponDecals -or (($WeaponActorFire -or $WeaponAbilityFire) -and $WeaponDecalsAuthoringDirectory)){
        $decalRoot=[IO.Path]::GetFullPath($WeaponDecalsAuthoringDirectory)
        if(!$decalRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned weapon decal revision required'}
        $decalSummaryPath=Join-Path $decalRoot 'summary.json';$decalProofPath=Join-Path $decalRoot 'assets.json'
        $decalAuthor=Get-Content -LiteralPath $decalSummaryPath -Raw|ConvertFrom-Json -Depth 80;$decalProof=Get-Content -LiteralPath $decalProofPath -Raw|ConvertFrom-Json -Depth 80
        if($decalAuthor.status -ne 'passed' -or $decalProof.status -ne 'passed' -or $decalAuthor.kind -ne 'weapondecals' -or $decalProof.kind -ne 'weapondecals' -or
            !$decalProof.original_full_cdo_preserved -or !$decalProof.original_business_graphs_preserved_with_dispatch -or !$decalProof.original_retriggerable_delay_node_reused -or
            !$decalProof.native_delay_uuid_preserved -or !$decalProof.cleanup_tests_validity_not_active -or $decalProof.native_delay_seconds -ne 3 -or $decalProof.transport_nodes -ne 3 -or
            $decalProof.new_business_nodes -ne 0 -or !$decalProof.original_position_array_type_preserved -or !$decalProof.original_surface_array_tail_preserved -or $decalProof.actual_registered_profile_method_counts.Python -ne 2 -or $decalProof.actual_registered_profile_method_counts.BlueprintFallback -ne 2 -or @($decalAuthor.assets).Count -ne 2){throw 'Current native weapon decal delay/dispatch proof incomplete'}
        foreach($asset in $decalAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Weapon fire FX asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $decalSummaryPath;Add-JumpInput $decalProofPath
    }
    if($MacroClosure){
        $macroRoot=[IO.Path]::GetFullPath($MacroClosureAuthoringDirectory)
        if(!$macroRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned macro closure revision required'}
        $macroSummary=Join-Path $macroRoot 'summary.json';$macroProofPath=Join-Path $macroRoot 'assets.json';$macroAuthor=Get-Content -LiteralPath $macroSummary -Raw|ConvertFrom-Json -Depth 80;$macroProof=Get-Content -LiteralPath $macroProofPath -Raw|ConvertFrom-Json -Depth 80
        if($macroAuthor.status -ne 'passed' -or $macroProof.status -ne 'passed' -or $macroAuthor.kind -ne 'macroclosure' -or $macroProof.kind -ne 'macroclosure' -or !$macroProof.original_macro_definition_assets_and_graphs_unchanged -or !$macroProof.original_macro_callsite_census_matches -or @($macroProof.callsites).Count -ne 9 -or @($macroAuthor.assets).Count -ne 0){throw 'Current macro definition/caller closure proof required'}
        foreach($library in $macroProof.libraries.PSObject.Properties){$file=Join-Path $stage $library.Value.relative;if((Get-FileHash -LiteralPath $file).Hash -ne $library.Value.sha256){throw 'Original macro definition changed'};Add-JumpInput $file}
        foreach($consumer in $macroProof.current_consumers.PSObject.Properties){$file=Join-Path $stage $consumer.Value.relative;$overlayFile=Join-Path $repo ('Demos/UEPLyraIntegration/Overlay/'+$consumer.Value.relative);foreach($path in @($file,$overlayFile)){if((Get-FileHash -LiteralPath $path).Hash -ne $consumer.Value.sha256){throw 'Macro caller revision changed'};Add-JumpInput $path}}
        if((Get-FileHash -LiteralPath $macroProof.fixture.asset).Hash -ne $macroProof.fixture.sha256){throw 'Native macro expansion probe changed'}
        Add-JumpInput $macroProof.fixture.asset;Add-JumpInput $macroSummary;Add-JumpInput $macroProofPath
    }

    if($ShooterEQS){
        $eqsRoot=[IO.Path]::GetFullPath($ShooterEQSAuthoringDirectory)
        if(!$eqsRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned shooter EQS revision required'}
        $eqsSummary=Join-Path $eqsRoot 'summary.json';$eqsProofPath=Join-Path $eqsRoot 'assets.json';$eqsAuthor=Get-Content -LiteralPath $eqsSummary -Raw|ConvertFrom-Json -Depth 80;$eqsProof=Get-Content -LiteralPath $eqsProofPath -Raw|ConvertFrom-Json -Depth 80
        if($eqsAuthor.status -ne 'passed' -or $eqsProof.status -ne 'passed' -or $eqsAuthor.kind -ne 'shootereqs' -or $eqsProof.kind -ne 'shootereqs' -or !$eqsProof.original_cdos_return_types_local_scopes_node_guids_world_queries_team_and_native_generator_graphs_preserved -or !$eqsProof.absent_target_leaves_location_out_parameter_unwritten -or $eqsProof.native_eqs_scheduler_replaced -or @($eqsAuthor.assets).Count -ne 8){throw 'Current shooter EQS context/return/native-generator proof required'}
        foreach($asset in $eqsAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'EQS asset changed'};Add-JumpInput $path}}
        foreach($fixture in $eqsProof.fixtures){if((Get-FileHash -LiteralPath $fixture.asset).Hash -ne $fixture.sha256){throw 'EQS query fixture changed'};Add-JumpInput $fixture.asset}
        Add-JumpInput $eqsSummary;Add-JumpInput $eqsProofPath
        foreach($relative in @('Bot/BT/BT_Lyra_Shooter_Bot','ControlPoint/AI/BT_Lyra_Shooter_ControlPoint_Bot','Blueprint/B_WeaponSpawner','Blueprint/B_AbilitySpawner','Blueprint/B_ControlPointVolume')){Add-JumpInput (Join-Path $stage ('Plugins/GameFeatures/ShooterCore/Content/'+$relative+'.uasset'))}
        foreach($relative in @('Engine/Source/Runtime/AIModule/Private/EnvironmentQuery/Generators/EnvQueryGenerator_BlueprintBase.cpp','Engine/Source/Runtime/AIModule/Private/EnvironmentQuery/Contexts/EnvQueryContext_BlueprintBase.cpp','Engine/Source/Runtime/AIModule/Private/EnvironmentQuery/EnvQueryManager.cpp')){Add-JumpInput (Join-Path $EngineRoot $relative)}
    }

    if($ShooterAI){
        $aiRoot=[IO.Path]::GetFullPath($ShooterAIAuthoringDirectory)
        if(!$aiRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned shooter AI revision required'}
        $aiSummary=Join-Path $aiRoot 'summary.json';$aiProofPath=Join-Path $aiRoot 'assets.json';$aiAuthor=Get-Content -LiteralPath $aiSummary -Raw|ConvertFrom-Json -Depth 80;$aiProof=Get-Content -LiteralPath $aiProofPath -Raw|ConvertFrom-Json -Depth 80
        if($aiAuthor.status -ne 'passed' -or $aiProof.status -ne 'passed' -or $aiAuthor.kind -ne 'shooterai' -or $aiProof.kind -ne 'shooterai' -or !$aiProof.original_cdos_templates_scoped_variables_node_guids_bt_schedules_async_factories_health_delegates_parent_calls_and_graphs_preserved -or !$aiProof.passive_empty_overrides_and_cp_parent_forwarder_retained -or @($aiAuthor.assets).Count -ne 12){throw 'Current shooter AI controller/service/inheritance proof required'}
        foreach($asset in $aiAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'AI asset changed'};Add-JumpInput $path}}
        foreach($fixture in $aiProof.fixtures){if((Get-FileHash -LiteralPath $fixture.asset).Hash -ne $fixture.sha256){throw 'AI fixture changed'};Add-JumpInput $fixture.asset}
        foreach($child in $aiProof.children.PSObject.Properties){$path=Join-Path $stage $child.Value.relative;if((Get-FileHash -LiteralPath $path).Hash -ne $child.Value.sha256){throw 'AI child config changed'};Add-JumpInput $path}
        Add-JumpInput $aiSummary;Add-JumpInput $aiProofPath
        foreach($relative in @('Player/LyraPlayerBotController.cpp','Player/LyraPlayerBotController.h')){Add-JumpInput (Join-Path $stage "Source/LyraGame/$relative")}
        foreach($relative in @('Engine/Source/Runtime/AIModule/Private/BehaviorTree/BTFunctionLibrary.cpp','Engine/Source/Runtime/AIModule/Private/BehaviorTree/Services/BTService_BlueprintBase.cpp','Engine/Source/Runtime/AIModule/Private/BehaviorTree/BehaviorTreeComponent.cpp')){Add-JumpInput (Join-Path $EngineRoot $relative)}
    }

    if($GamePhases){
        $phaseRoot=[IO.Path]::GetFullPath($GamePhasesAuthoringDirectory)
        if(!$phaseRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned game phase revision required'}
        $phaseSummary=Join-Path $phaseRoot 'summary.json';$phaseProofPath=Join-Path $phaseRoot 'assets.json';$phaseAuthor=Get-Content -LiteralPath $phaseSummary -Raw|ConvertFrom-Json -Depth 80;$phaseProof=Get-Content -LiteralPath $phaseProofPath -Raw|ConvertFrom-Json -Depth 80
        if($phaseAuthor.status -ne 'passed' -or $phaseProof.status -ne 'passed' -or $phaseAuthor.kind -ne 'gamephases' -or $phaseProof.kind -ne 'gamephases' -or !$phaseProof.original_cdos_gas_parent_tags_latent_uuids_multicast_cosmetic_and_custom_thunk_message_graphs_preserved -or !$phaseProof.original_default_durations_preserved -or $phaseProof.new_business_nodes -ne 0 -or @($phaseAuthor.assets).Count -ne 6){throw 'Current native phase/GAS/latent/message proof required'}
        foreach($asset in $phaseAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Phase asset changed'};Add-JumpInput $path}}
        Add-JumpInput $phaseSummary;Add-JumpInput $phaseProofPath;Add-JumpInput $phaseProof.fixture.asset
        foreach($dependency in @('Plugins/GameFeatures/ShooterCore/Content/Experiences/Phases/GE_PregameLobby.uasset','Plugins/GameFeatures/ShooterCore/Content/Experiences/Phases/GE_DamageImmunity_FromGameMode.uasset','Content/GameplayEffects/GE_BlockAbilityInput.uasset')){Add-JumpInput (Join-Path $stage $dependency)}
        foreach($relative in @('AbilitySystem/Phases/LyraGamePhaseAbility.cpp','AbilitySystem/Phases/LyraGamePhaseAbility.h','AbilitySystem/Phases/LyraGamePhaseSubsystem.cpp','AbilitySystem/Phases/LyraGamePhaseSubsystem.h','AbilitySystem/LyraGlobalAbilitySystem.cpp','System/LyraSystemStatics.cpp','System/LyraDevelopmentStatics.cpp')){Add-JumpInput (Join-Path $stage "Source/LyraGame/$relative")}
    }

    if($EliminationScore){
        $tdmHudRoot=[IO.Path]::GetFullPath($EliminationScoreAuthoringDirectory)
        if(!$tdmHudRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned TDM HUD revision required'}
        $tdmHudSummary=Join-Path $tdmHudRoot 'summary.json';$tdmHudProofPath=Join-Path $tdmHudRoot 'assets.json';$tdmHudAuthor=Get-Content -LiteralPath $tdmHudSummary -Raw|ConvertFrom-Json -Depth 80;$tdmHudProof=Get-Content -LiteralPath $tdmHudProofPath -Raw|ConvertFrom-Json -Depth 80
        if($tdmHudAuthor.status -ne 'passed' -or $tdmHudProof.status -ne 'passed' -or $tdmHudAuthor.kind -ne 'eliminationscore' -or $tdmHudProof.kind -ne 'eliminationscore' -or !$tdmHudProof.original_trees_animations_async_delegate_bindings_delay_and_graphs_preserved -or !$tdmHudProof.original_localized_clock_nodes_moved_intact -or $tdmHudProof.localized_text_roundtripped -or $tdmHudProof.method_counts.Python -ne 8 -or $tdmHudProof.method_counts.BlueprintFallback -ne 8 -or $tdmHudProof.new_business_nodes -ne 0 -or @($tdmHudAuthor.assets).Count -ne 2){throw 'Current native TDM HUD/clock/delegate proof incomplete'}
        foreach($asset in $tdmHudAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'TDM HUD asset changed'};Add-JumpInput $path}}
        Add-JumpInput $tdmHudSummary;Add-JumpInput $tdmHudProofPath;Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')
        foreach($dependency in @('Plugins/GameFeatures/ShooterCore/Content/Elimination/B_TeamDeathMatchScoring.uasset','Content/Audio/MetaSounds/sfx_EndOfRound-LowScore_nl_meta.uasset','Content/Audio/MetaSounds/sfx_EndOfRound-Tick_nl_meta.uasset')){Add-JumpInput (Join-Path $stage $dependency)}
    }

    if($ControlPointWidgets){
        $cpWidgetRoot=[IO.Path]::GetFullPath($ControlPointWidgetsAuthoringDirectory)
        if(!$cpWidgetRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned CP widget revision required'}
        $cpWidgetSummary=Join-Path $cpWidgetRoot 'summary.json';$cpWidgetProofPath=Join-Path $cpWidgetRoot 'assets.json';$cpWidgetAuthor=Get-Content -LiteralPath $cpWidgetSummary -Raw|ConvertFrom-Json -Depth 80;$cpWidgetProof=Get-Content -LiteralPath $cpWidgetProofPath -Raw|ConvertFrom-Json -Depth 80
        if($cpWidgetAuthor.status -ne 'passed' -or $cpWidgetProof.status -ne 'passed' -or $cpWidgetAuthor.kind -ne 'controlpointwidgets' -or $cpWidgetProof.kind -ne 'controlpointwidgets' -or !$cpWidgetProof.original_trees_animations_async_factories_delay_and_graphs_preserved -or !$cpWidgetProof.original_empty_tick_stays_unconnected -or $cpWidgetProof.new_business_nodes -ne 0 -or @($cpWidgetAuthor.assets).Count -ne 6){throw 'Current CP widget/native async/material/audio proof incomplete'}
        foreach($asset in $cpWidgetAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'CP widget asset changed'};Add-JumpInput $path}}
        Add-JumpInput $cpWidgetSummary;Add-JumpInput $cpWidgetProofPath;Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')
        foreach($dependency in @('Plugins/GameFeatures/ShooterCore/Content/ControlPoint/B_ControlPointScoring.uasset','Plugins/GameFeatures/ShooterCore/Content/Blueprint/B_ControlPointVolume.uasset','Content/Audio/MetaSounds/sfx_EndOfRound-LowScore_nl_meta.uasset')){Add-JumpInput (Join-Path $stage $dependency)}
    }

    if($ScoreboardStyle){
        $styleRoot=[IO.Path]::GetFullPath($ScoreboardStyleAuthoringDirectory)
        if(!$styleRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned scoreboard style revision required'}
        $styleSummary=Join-Path $styleRoot 'summary.json';$styleProofPath=Join-Path $styleRoot 'assets.json';$styleAuthor=Get-Content -LiteralPath $styleSummary -Raw|ConvertFrom-Json -Depth 80;$styleProof=Get-Content -LiteralPath $styleProofPath -Raw|ConvertFrom-Json -Depth 80
        if($styleAuthor.status -ne 'passed' -or $styleProof.status -ne 'passed' -or $styleAuthor.kind -ne 'scoreboardstyle' -or $styleProof.kind -ne 'scoreboardstyle' -or !$styleProof.original_trees_animations_native_timer_literal_team_names_and_graphs_preserved -or $styleProof.localized_text_roundtripped -or $styleProof.native_timer_seconds -ne 1 -or !$styleProof.construct_target_score_only -or $styleProof.new_business_nodes -ne 0 -or @($styleAuthor.assets).Count -ne 10){throw 'Current localized team/style/timer/board proof incomplete'}
        foreach($asset in $styleAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Scoreboard style asset changed'};Add-JumpInput $path}}
        Add-JumpInput $styleSummary;Add-JumpInput $styleProofPath
    }
    if($ScoreboardList){
        $rowRoot=[IO.Path]::GetFullPath($ScoreboardListAuthoringDirectory)
        if(!$rowRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned scoreboard row proof required'}
        $rowSummary=Join-Path $rowRoot 'summary.json';$rowProofPath=Join-Path $rowRoot 'assets.json';$rowAuthor=Get-Content -LiteralPath $rowSummary -Raw|ConvertFrom-Json -Depth 80;$rowProof=Get-Content -LiteralPath $rowProofPath -Raw|ConvertFrom-Json -Depth 80
        if($rowAuthor.status -ne 'passed' -or $rowProof.status -ne 'passed' -or $rowAuthor.kind -ne 'scoreboardlist' -or $rowProof.kind -ne 'scoreboardlist' -or !$rowProof.original_visuals_native_timer_delegates_localized_format_and_remaining_graphs_preserved -or $rowProof.native_timer_seconds -ne 1 -or !$rowProof.native_looping -or $rowProof.new_native_cleanup_added -or $rowProof.new_business_nodes -ne 0 -or @($rowAuthor.assets).Count -ne 4){throw 'Current scoreboard native timer/parent/visual proof incomplete'}
        if($rowProof.localized_text_roundtripped -or !$rowProof.list_timer_only_when_filter_not_minus_one -or $rowProof.widgets.list.method_counts.Python -ne 4 -or $rowProof.widgets.list.method_counts.BlueprintFallback -ne 4 -or $rowProof.widgets.connection.method_counts.Python -ne 2 -or $rowProof.widgets.connection.method_counts.BlueprintFallback -ne 2 -or $rowProof.widgets.list.transport_nodes -ne 18 -or $rowProof.widgets.connection.transport_nodes -ne 12){throw 'Complete list/connection/localized formatter proof required'}
        foreach($asset in $rowAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Scoreboard row asset changed'};Add-JumpInput $path}}
        Add-JumpInput $rowSummary;Add-JumpInput $rowProofPath
    }
    if($ScoreboardRows){
        $rowRoot=[IO.Path]::GetFullPath($ScoreboardRowsAuthoringDirectory)
        if(!$rowRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned scoreboard row proof required'}
        $rowSummary=Join-Path $rowRoot 'summary.json';$rowProofPath=Join-Path $rowRoot 'assets.json';$rowAuthor=Get-Content -LiteralPath $rowSummary -Raw|ConvertFrom-Json -Depth 80;$rowProof=Get-Content -LiteralPath $rowProofPath -Raw|ConvertFrom-Json -Depth 80
        if($rowAuthor.status -ne 'passed' -or $rowProof.status -ne 'passed' -or $rowAuthor.kind -ne 'scoreboardrows' -or $rowProof.kind -ne 'scoreboardrows' -or !$rowProof.original_widget_trees_signatures_interface_parent_calls_empty_hooks_and_business_graphs_preserved -or $rowProof.native_stat_timer_seconds -ne 1 -or !$rowProof.native_stat_timer_looping -or !$rowProof.no_native_timer_or_destruct_cleanup_added -or $rowProof.new_business_nodes -ne 0 -or @($rowAuthor.assets).Count -ne 12){throw 'Current scoreboard native timer/parent/visual proof incomplete'}
        foreach($name in @('base','name','icon','stat','cp','tdm')){if($rowProof.widgets.($name).interface_nodes -ne 5 -or $rowProof.widgets.($name).method_counts.Python -ne @{base=1;name=2;icon=1;stat=4;cp=5;tdm=5}[$name] -or $rowProof.widgets.($name).method_counts.BlueprintFallback -ne @{base=1;name=2;icon=1;stat=4;cp=5;tdm=5}[$name]){throw 'Complete scoreboard Profile family required'}}
        foreach($asset in $rowAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Scoreboard row asset changed'};Add-JumpInput $path}}
        Add-JumpInput $rowSummary;Add-JumpInput $rowProofPath
    }
    if($EliminationWidgets){
        $widgetRoot=[IO.Path]::GetFullPath($EliminationWidgetsAuthoringDirectory);$messageRoot=[IO.Path]::GetFullPath($EliminationWidgetsRelayAuthoringDirectory)
        if(!$widgetRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$messageRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned accolade widget/relay revisions required'}
        $widgetSummary=Join-Path $widgetRoot 'summary.json';$widgetProofPath=Join-Path $widgetRoot 'assets.json';$widgetAuthor=Get-Content -LiteralPath $widgetSummary -Raw|ConvertFrom-Json -Depth 80;$widgetProof=Get-Content -LiteralPath $widgetProofPath -Raw|ConvertFrom-Json -Depth 80
        if($widgetAuthor.status -ne 'passed' -or $widgetProof.status -ne 'passed' -or $widgetAuthor.kind -ne 'eliminationwidgets' -or $widgetProof.kind -ne 'eliminationwidgets' -or !$widgetProof.original_widget_trees_animations_exact_listener_list_binding_timer_delegate_and_graphs_preserved -or $widgetProof.native_expiry_seconds -ne 6 -or !$widgetProof.expiry_uses_current_list_item -or !$widgetProof.unconnected_construct_set_colors_stays_unreachable -or $widgetProof.new_business_nodes -ne 0 -or @($widgetAuthor.assets).Count -ne 4 -or $widgetProof.widgets.feed.method_counts.Python -ne 3 -or $widgetProof.widgets.feed.method_counts.BlueprintFallback -ne 3 -or $widgetProof.widgets.entry.method_counts.Python -ne 4 -or $widgetProof.widgets.entry.method_counts.BlueprintFallback -ne 4 -or $widgetProof.widgets.feed.transport_nodes -ne 12 -or $widgetProof.widgets.entry.transport_nodes -ne 19){throw 'Current typed widget-return/native tree/animation/queue proof incomplete'}
        foreach($asset in $widgetAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Accolade widget asset changed'};Add-JumpInput $path}}
        foreach($dependency in $widgetProof.dependency_hashes.PSObject.Properties){$path=Join-Path $stage $dependency.Name;if((Get-FileHash -LiteralPath $path).Hash -ne $dependency.Value){throw 'Native accolade queue/data dependency changed'};Add-JumpInput $path}
        $messageSummary=Join-Path $messageRoot 'summary.json';$messageProofPath=Join-Path $messageRoot 'assets.json';$messageAuthor=Get-Content -LiteralPath $messageSummary -Raw|ConvertFrom-Json -Depth 80;$messageProof=Get-Content -LiteralPath $messageProofPath -Raw|ConvertFrom-Json -Depth 80
        if($messageAuthor.status -ne 'passed' -or $messageProof.status -ne 'passed' -or $messageAuthor.kind -ne 'eliminationfeedrelay' -or $messageProof.kind -ne 'eliminationfeedrelay' -or !$messageProof.fixture.stage_only){throw 'Current native accolade message producer proof required'}
        foreach($asset in $messageAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Accolade message producer asset changed'};Add-JumpInput $path}}
        if((Get-FileHash -LiteralPath $messageProof.fixture.asset).Hash -ne $messageProof.fixture.sha256){throw 'Native accolade message probe changed'}
        Add-JumpInput $messageProof.fixture.asset;Add-JumpInput $widgetSummary;Add-JumpInput $widgetProofPath;Add-JumpInput $messageSummary;Add-JumpInput $messageProofPath
    }
    if($AccoladeWidgets){
        $widgetRoot=[IO.Path]::GetFullPath($AccoladeWidgetsAuthoringDirectory);$messageRoot=[IO.Path]::GetFullPath($AccoladeWidgetsRelayAuthoringDirectory)
        if(!$widgetRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$messageRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned accolade widget/relay revisions required'}
        $widgetSummary=Join-Path $widgetRoot 'summary.json';$widgetProofPath=Join-Path $widgetRoot 'assets.json';$widgetAuthor=Get-Content -LiteralPath $widgetSummary -Raw|ConvertFrom-Json -Depth 80;$widgetProof=Get-Content -LiteralPath $widgetProofPath -Raw|ConvertFrom-Json -Depth 80
        if($widgetAuthor.status -ne 'passed' -or $widgetProof.status -ne 'passed' -or $widgetAuthor.kind -ne 'accoladewidgets' -or $widgetProof.kind -ne 'accoladewidgets' -or !$widgetProof.original_widget_trees_animations_native_queue_parent_and_business_graphs_preserved -or $widgetProof.localized_text_roundtripped -or !$widgetProof.unconnected_toast_stop_branch_remains_unreachable -or $widgetProof.new_business_nodes -ne 0 -or @($widgetAuthor.assets).Count -ne 4 -or $widgetProof.widgets.host.method_counts.Python -ne 3 -or $widgetProof.widgets.host.method_counts.BlueprintFallback -ne 3 -or $widgetProof.widgets.toast.method_counts.Python -ne 1 -or $widgetProof.widgets.toast.method_counts.BlueprintFallback -ne 1 -or $widgetProof.widgets.host.transport_nodes -ne 13 -or $widgetProof.widgets.toast.transport_nodes -ne 4){throw 'Current typed widget-return/native tree/animation/queue proof incomplete'}
        foreach($asset in $widgetAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Accolade widget asset changed'};Add-JumpInput $path}}
        foreach($dependency in $widgetProof.dependency_hashes.PSObject.Properties){$path=Join-Path $stage $dependency.Name;if((Get-FileHash -LiteralPath $path).Hash -ne $dependency.Value){throw 'Native accolade queue/data dependency changed'};Add-JumpInput $path}
        foreach($file in Get-ChildItem -LiteralPath "$stage/Plugins/GameFeatures/ShooterCore/Source/ShooterCoreRuntime" -Recurse -File|Where-Object {$_.Name -like '*Accolade*'}){Add-JumpInput $file.FullName}
        $messageSummary=Join-Path $messageRoot 'summary.json';$messageProofPath=Join-Path $messageRoot 'assets.json';$messageAuthor=Get-Content -LiteralPath $messageSummary -Raw|ConvertFrom-Json -Depth 80;$messageProof=Get-Content -LiteralPath $messageProofPath -Raw|ConvertFrom-Json -Depth 80
        if($messageAuthor.status -ne 'passed' -or $messageProof.status -ne 'passed' -or $messageAuthor.kind -ne 'accoladerelay' -or $messageProof.kind -ne 'accoladerelay' -or !$messageProof.fixture.stage_only){throw 'Current native accolade message producer proof required'}
        foreach($asset in $messageAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Accolade message producer asset changed'};Add-JumpInput $path}}
        if((Get-FileHash -LiteralPath $messageProof.fixture.asset).Hash -ne $messageProof.fixture.sha256){throw 'Native accolade message probe changed'}
        Add-JumpInput $messageProof.fixture.asset;Add-JumpInput $widgetSummary;Add-JumpInput $widgetProofPath;Add-JumpInput $messageSummary;Add-JumpInput $messageProofPath;Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')
    }
    if($NotificationRelaysNetwork){
        foreach($spec in @(@{root=$RelayEliminationAuthoringDirectory;kind='eliminationfeedrelay';nodes=30;transport=8;preserved='original_full_cdo_exact_async_factory_authority_cosmetic_rpc_and_business_graphs_preserved'},@{root=$RelayAccoladeAuthoringDirectory;kind='accoladerelay';nodes=15;transport=7;preserved='original_full_cdo_partial_async_factory_sequence_authority_cosmetic_rpc_and_business_graphs_preserved'})){
            $relayRoot=[IO.Path]::GetFullPath($spec.root)
            if(!$relayRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned network relay authoring proof required'}
            $summaryPath=Join-Path $relayRoot 'summary.json';$proofPath=Join-Path $relayRoot 'assets.json';$author=Get-Content -LiteralPath $summaryPath -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $proofPath -Raw|ConvertFrom-Json -Depth 80
            if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne $spec.kind -or $proof.kind -ne $spec.kind -or !$proof.($spec.preserved) -or $proof.original_graph_nodes -ne $spec.nodes -or $proof.transport_nodes -ne $spec.transport -or $proof.interface_nodes -ne 5 -or $proof.new_business_nodes -ne 0 -or $proof.actual_registered_profile_method_counts.Python -ne 1 -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or @($author.assets).Count -ne 2 -or !$proof.fixture.stage_only){throw 'Current native relay listener/RPC/typed transport proof incomplete'}
            foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Network relay asset changed'};Add-JumpInput $path}}
            if((Get-FileHash -LiteralPath $proof.fixture.asset).Hash -ne $proof.fixture.sha256){throw 'Network relay typed observer fixture changed'}
            Add-JumpInput $proof.fixture.asset;Add-JumpInput $summaryPath;Add-JumpInput $proofPath
        }
    }
    if($AccoladeRelay){
        $relayRoot=[IO.Path]::GetFullPath($AccoladeRelayAuthoringDirectory)
        if(!$relayRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned elimination feed relay revision required'}
        $relaySummaryPath=Join-Path $relayRoot 'summary.json';$relayProofPath=Join-Path $relayRoot 'assets.json'
        $relayAuthor=Get-Content -LiteralPath $relaySummaryPath -Raw|ConvertFrom-Json -Depth 80;$relayProof=Get-Content -LiteralPath $relayProofPath -Raw|ConvertFrom-Json -Depth 80
        if($relayAuthor.status -ne 'passed' -or $relayProof.status -ne 'passed' -or $relayAuthor.kind -ne 'accoladerelay' -or $relayProof.kind -ne 'accoladerelay' -or
            !$relayProof.original_full_cdo_partial_async_factory_sequence_authority_cosmetic_rpc_and_business_graphs_preserved -or !$relayProof.native_notification_struct_and_broadcast_custom_thunk -or
            $relayProof.original_graph_nodes -ne 15 -or $relayProof.transport_nodes -ne 7 -or $relayProof.interface_nodes -ne 5 -or $relayProof.new_business_nodes -ne 0 -or
            $relayProof.actual_registered_profile_method_counts.Python -ne 1 -or $relayProof.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or @($relayAuthor.assets).Count -ne 2 -or !$relayProof.fixture.stage_only){throw 'Current relay exact subscription/native RPC/typed payload proof incomplete'}
        foreach($asset in $relayAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Accolade relay asset changed'};Add-JumpInput $path}}
        if((Get-FileHash -LiteralPath $relayProof.fixture.asset).Hash -ne $relayProof.fixture.sha256){throw 'Typed native feed observer fixture changed'}
        foreach($dependency in $relayProof.dependency_hashes.PSObject.Properties){$path=Join-Path $stage $dependency.Name;if((Get-FileHash -LiteralPath $path).Hash -ne $dependency.Value){throw 'Accepted elimination relay dependency changed'};Add-JumpInput $path}
        Add-JumpInput $relayProof.fixture.asset;Add-JumpInput $relaySummaryPath;Add-JumpInput $relayProofPath
    }
    if($EliminationFeedRelay){
        $relayRoot=[IO.Path]::GetFullPath($EliminationFeedRelayAuthoringDirectory)
        if(!$relayRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned elimination feed relay revision required'}
        $relaySummaryPath=Join-Path $relayRoot 'summary.json';$relayProofPath=Join-Path $relayRoot 'assets.json'
        $relayAuthor=Get-Content -LiteralPath $relaySummaryPath -Raw|ConvertFrom-Json -Depth 80;$relayProof=Get-Content -LiteralPath $relayProofPath -Raw|ConvertFrom-Json -Depth 80
        if($relayAuthor.status -ne 'passed' -or $relayProof.status -ne 'passed' -or $relayAuthor.kind -ne 'eliminationfeedrelay' -or $relayProof.kind -ne 'eliminationfeedrelay' -or
            !$relayProof.original_full_cdo_exact_async_factory_authority_cosmetic_rpc_and_business_graphs_preserved -or !$relayProof.native_user_defined_feed_struct_and_broadcast_custom_thunk -or
            $relayProof.original_graph_nodes -ne 30 -or $relayProof.transport_nodes -ne 8 -or $relayProof.interface_nodes -ne 5 -or $relayProof.new_business_nodes -ne 0 -or
            $relayProof.actual_registered_profile_method_counts.Python -ne 1 -or $relayProof.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or @($relayAuthor.assets).Count -ne 2 -or !$relayProof.fixture.stage_only){throw 'Current relay exact subscription/native RPC/typed payload proof incomplete'}
        foreach($asset in $relayAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Elimination relay asset changed'};Add-JumpInput $path}}
        if((Get-FileHash -LiteralPath $relayProof.fixture.asset).Hash -ne $relayProof.fixture.sha256){throw 'Typed native feed observer fixture changed'}
        Add-JumpInput $relayProof.fixture.asset;Add-JumpInput $relaySummaryPath;Add-JumpInput $relayProofPath
    }
    if($ControlPointFeedback){
        $pointFeedbackRoot=[IO.Path]::GetFullPath($ControlPointFeedbackAuthoringDirectory)
        if(!$pointFeedbackRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned control point feedback revision required'}
        $pointFeedbackSummaryPath=Join-Path $pointFeedbackRoot 'summary.json';$pointFeedbackProofPath=Join-Path $pointFeedbackRoot 'assets.json'
        $pointFeedbackAuthor=Get-Content -LiteralPath $pointFeedbackSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $pointFeedbackProof=Get-Content -LiteralPath $pointFeedbackProofPath -Raw|ConvertFrom-Json -Depth 80
        if($pointFeedbackAuthor.status -ne 'passed' -or $pointFeedbackProof.status -ne 'passed' -or $pointFeedbackAuthor.kind -ne 'controlpointfeedback' -or $pointFeedbackProof.kind -ne 'controlpointfeedback' -or
            !$pointFeedbackProof.accepted_parent_cdo_components_timeline_rpc_and_all_remaining_graphs_preserved -or !$pointFeedbackProof.native_capture_message_custom_thunk_preserved -or
            $pointFeedbackProof.parent_revision_graph_nodes -ne 308 -or $pointFeedbackProof.new_transport_nodes_this_revision -ne 37 -or $pointFeedbackProof.cumulative_transport_nodes -ne 69 -or $pointFeedbackProof.interface_nodes -ne 5 -or $pointFeedbackProof.new_business_nodes -ne 0 -or
            $pointFeedbackProof.actual_registered_profile_method_counts.Python -ne 17 -or $pointFeedbackProof.actual_registered_profile_method_counts.BlueprintFallback -ne 17 -or @($pointFeedbackAuthor.assets).Count -ne 2 -or !$pointFeedbackProof.timeline_update_finish_rpc_vfx_audio_business_migrated){throw 'Current point feedback authority/overlap/remaining-business proof incomplete'}
        foreach($asset in $pointFeedbackAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Control point feedback asset changed'};Add-JumpInput $path
        }}
        foreach($dependency in $pointFeedbackProof.dependency_hashes.PSObject.Properties){$path=Join-Path $stage $dependency.Name;if((Get-FileHash -LiteralPath $path).Hash -ne $dependency.Value){throw 'Control point CP dependency changed'};Add-JumpInput $path}
        Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')
        Add-JumpInput $pointFeedbackSummaryPath;Add-JumpInput $pointFeedbackProofPath;Add-JumpInput (Join-Path $stage 'Plugins/GameFeatures/ShooterMaps/Content/Maps/L_Convolution_Blockout.umap')
    }
    if($ControlPointState){
        $pointStateRoot=[IO.Path]::GetFullPath($ControlPointStateAuthoringDirectory)
        if(!$pointStateRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned control point state revision required'}
        $pointStateSummaryPath=Join-Path $pointStateRoot 'summary.json';$pointStateProofPath=Join-Path $pointStateRoot 'assets.json'
        $pointStateAuthor=Get-Content -LiteralPath $pointStateSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $pointStateProof=Get-Content -LiteralPath $pointStateProofPath -Raw|ConvertFrom-Json -Depth 80
        if($pointStateAuthor.status -ne 'passed' -or $pointStateProof.status -ne 'passed' -or $pointStateAuthor.kind -ne 'controlpointstate' -or $pointStateProof.kind -ne 'controlpointstate' -or
            !$pointStateProof.accepted_helper_cdo_components_timeline_rpc_and_all_remaining_graphs_preserved -or !$pointStateProof.native_experience_factory_component_overlap_binding_authority_switches_and_rpc_preserved -or
            $pointStateProof.parent_revision_graph_nodes -ne 292 -or $pointStateProof.new_transport_nodes_this_revision -ne 16 -or $pointStateProof.cumulative_transport_nodes -ne 32 -or $pointStateProof.interface_nodes -ne 5 -or $pointStateProof.new_business_nodes -ne 0 -or
            $pointStateProof.actual_registered_profile_method_counts.Python -ne 8 -or $pointStateProof.actual_registered_profile_method_counts.BlueprintFallback -ne 8 -or @($pointStateAuthor.assets).Count -ne 2 -or $pointStateProof.timeline_update_finish_rpc_vfx_audio_business_migrated){throw 'Current point state authority/overlap/remaining-business proof incomplete'}
        foreach($asset in $pointStateAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Control point state asset changed'};Add-JumpInput $path
        }}
        foreach($dependency in $pointStateProof.dependency_hashes.PSObject.Properties){$path=Join-Path $stage $dependency.Name;if((Get-FileHash -LiteralPath $path).Hash -ne $dependency.Value){throw 'Control point CP dependency changed'};Add-JumpInput $path}
        Add-JumpInput $pointStateSummaryPath;Add-JumpInput $pointStateProofPath;Add-JumpInput (Join-Path $stage 'Plugins/GameFeatures/ShooterMaps/Content/Maps/L_Convolution_Blockout.umap')
    }
    if($ControlPointHelpers){
        $pointHelpersRoot=[IO.Path]::GetFullPath($ControlPointHelpersAuthoringDirectory)
        if(!$pointHelpersRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned control point helper revision required'}
        $pointHelpersSummaryPath=Join-Path $pointHelpersRoot 'summary.json';$pointHelpersProofPath=Join-Path $pointHelpersRoot 'assets.json'
        $pointHelpersAuthor=Get-Content -LiteralPath $pointHelpersSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $pointHelpersProof=Get-Content -LiteralPath $pointHelpersProofPath -Raw|ConvertFrom-Json -Depth 80
        if($pointHelpersAuthor.status -ne 'passed' -or $pointHelpersProof.status -ne 'passed' -or $pointHelpersAuthor.kind -ne 'controlpointhelpers' -or $pointHelpersProof.kind -ne 'controlpointhelpers' -or
            !$pointHelpersProof.original_full_cdo_components_timeline_curves_guids_rpc_signatures_and_other_business_preserved -or $pointHelpersProof.original_graph_nodes -ne 271 -or $pointHelpersProof.transport_nodes -ne 16 -or $pointHelpersProof.interface_nodes -ne 5 -or
            $pointHelpersProof.new_business_nodes -ne 0 -or $pointHelpersProof.actual_registered_profile_method_counts.Python -ne 4 -or $pointHelpersProof.actual_registered_profile_method_counts.BlueprintFallback -ne 4 -or @($pointHelpersAuthor.assets).Count -ne 2 -or $pointHelpersProof.volume_arbitration_overlap_timeline_rpc_audio_business_migrated){throw 'Current volume helper/Timeline/RPC/remaining-business proof incomplete'}
        foreach($asset in $pointHelpersAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Control point helper asset changed'};Add-JumpInput $path
        }}
        foreach($dependency in $pointHelpersProof.dependency_hashes.PSObject.Properties){$path=Join-Path $stage $dependency.Name;if((Get-FileHash -LiteralPath $path).Hash -ne $dependency.Value){throw 'Control point CP dependency changed'};Add-JumpInput $path}
        Add-JumpInput $pointHelpersSummaryPath;Add-JumpInput $pointHelpersProofPath;Add-JumpInput (Join-Path $stage 'Plugins/GameFeatures/ShooterMaps/Content/Maps/L_Convolution_Blockout.umap')
    }
    if($CPScoring){
        $cpRoot=[IO.Path]::GetFullPath($CPScoringAuthoringDirectory)
        if(!$cpRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned CP scoring revision required'}
        $cpSummaryPath=Join-Path $cpRoot 'summary.json';$cpProofPath=Join-Path $cpRoot 'assets.json'
        $cpAuthor=Get-Content -LiteralPath $cpSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $cpProof=Get-Content -LiteralPath $cpProofPath -Raw|ConvertFrom-Json -Depth 80
        if($cpAuthor.status -ne 'passed' -or $cpProof.status -ne 'passed' -or $cpAuthor.kind -ne 'cpscoring' -or $cpProof.kind -ne 'cpscoring' -or
            !$cpProof.original_cdo_signatures_graphs_authority_phase_timer_repnotify_and_shared_base_preserved -or !$cpProof.typed_gates_preserve_array_inputs_and_public_multi_output_abi -or
            $cpProof.original_graph_nodes -ne 145 -or $cpProof.transport_nodes -ne 67 -or $cpProof.interface_nodes -ne 5 -or $cpProof.new_business_nodes -ne 0 -or
            $cpProof.actual_registered_profile_method_counts.Python -ne 18 -or $cpProof.actual_registered_profile_method_counts.BlueprintFallback -ne 18 -or @($cpAuthor.assets).Count -ne 2){throw 'Current CP timer/phase/authority/array/base proof incomplete'}
        foreach($asset in $cpAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'CP scoring asset changed'};Add-JumpInput $path
        }}
        foreach($dependency in $cpProof.dependency_hashes.PSObject.Properties){$path=Join-Path $stage $dependency.Name;if((Get-FileHash -LiteralPath $path).Hash -ne $dependency.Value){throw 'CP base/TDM dependency changed'};Add-JumpInput $path}
        Add-JumpInput $cpSummaryPath;Add-JumpInput $cpProofPath
        foreach($fixture in @('Plugins/GameFeatures/ShooterCore/Content/Blueprint/B_ControlPointVolume.uasset','Plugins/GameFeatures/ShooterMaps/Content/Maps/L_Convolution_Blockout.umap','Plugins/GameFeatures/ShooterCore/Content/Experiences/Phases/Phase_Warmup.uasset','Plugins/GameFeatures/ShooterCore/Content/Experiences/Phases/Phase_PostGame.uasset')){Add-JumpInput (Join-Path $stage $fixture)}
    }
    if($TDMScoring){
        $tdmRoot=[IO.Path]::GetFullPath($TDMScoringAuthoringDirectory)
        if(!$tdmRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned TDM scoring revision required'}
        $tdmSummaryPath=Join-Path $tdmRoot 'summary.json';$tdmProofPath=Join-Path $tdmRoot 'assets.json'
        $tdmAuthor=Get-Content -LiteralPath $tdmSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $tdmProof=Get-Content -LiteralPath $tdmProofPath -Raw|ConvertFrom-Json -Depth 80
        if($tdmAuthor.status -ne 'passed' -or $tdmProof.status -ne 'passed' -or $tdmAuthor.kind -ne 'tdmscoring' -or $tdmProof.kind -ne 'tdmscoring' -or
            !$tdmProof.original_cdo_signatures_graphs_native_repnotify_timer_phase_and_shared_base_preserved -or !$tdmProof.base_owned_business_gates_cover_static_callers -or
            $tdmProof.original_graph_nodes -ne 123 -or $tdmProof.transport_nodes -ne 57 -or $tdmProof.interface_nodes -ne 5 -or $tdmProof.new_business_nodes -ne 0 -or
            $tdmProof.actual_registered_profile_method_counts.Python -ne 16 -or $tdmProof.actual_registered_profile_method_counts.BlueprintFallback -ne 16 -or @($tdmAuthor.assets).Count -ne 2){throw 'Current TDM timer/phase/RepNotify/base proof incomplete'}
        foreach($asset in $tdmAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'TDM scoring asset changed'};Add-JumpInput $path
        }}
        foreach($dependency in $tdmProof.dependency_hashes.PSObject.Properties){$path=Join-Path $stage $dependency.Name;if((Get-FileHash -LiteralPath $path).Hash -ne $dependency.Value){throw 'TDM base/CP dependency changed'};Add-JumpInput $path}
        Add-JumpInput $tdmSummaryPath;Add-JumpInput $tdmProofPath
        foreach($fixture in @('Content/UEPValidation/BP_MusicListenerProbe.uasset','Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_WaitingForPlayers.uasset','Plugins/GameFeatures/ShooterCore/Content/GameplayCues/GCNL_MatchDecided.uasset','Plugins/GameFeatures/ShooterCore/Content/Experiences/Phases/Phase_Warmup.uasset','Plugins/GameFeatures/ShooterCore/Content/Experiences/Phases/Phase_PostGame.uasset','Plugins/GameFeatures/ShooterCore/Content/Experiences/Phases/GE_DamageImmunity_FromGameMode.uasset')){Add-JumpInput (Join-Path $stage $fixture)}
    }
    if($ScoringBase){
        $scoringRoot=[IO.Path]::GetFullPath($ScoringBaseAuthoringDirectory)
        if(!$scoringRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned scoring revision required'}
        $scoringSummaryPath=Join-Path $scoringRoot 'summary.json';$scoringProofPath=Join-Path $scoringRoot 'assets.json'
        $scoringAuthor=Get-Content -LiteralPath $scoringSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $scoringProof=Get-Content -LiteralPath $scoringProofPath -Raw|ConvertFrom-Json -Depth 80
        if($scoringAuthor.status -ne 'passed' -or $scoringProof.status -ne 'passed' -or $scoringAuthor.kind -ne 'scoringbase' -or $scoringProof.kind -ne 'scoringbase' -or
            !$scoringProof.original_full_cdo_signatures_business_graphs_children_and_hook_preserved -or !$scoringProof.original_authority_switch_exact_async_factories_and_listener_lifetime_preserved -or
            !$scoringProof.base_owned_gates_cover_child_static_parent_and_public_calls -or $scoringProof.original_graph_nodes -ne 61 -or $scoringProof.transport_nodes -ne 21 -or $scoringProof.interface_nodes -ne 5 -or $scoringProof.new_business_nodes -ne 0 -or
            $scoringProof.actual_registered_profile_method_counts.Python -ne 5 -or $scoringProof.actual_registered_profile_method_counts.BlueprintFallback -ne 5 -or @($scoringAuthor.assets).Count -ne 2 -or !$scoringProof.fixture.stage_only){throw 'Current shared scoring authority/listener/child proof incomplete'}
        foreach($asset in $scoringAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Scoring asset changed'};Add-JumpInput $path
        }}
        foreach($child in $scoringProof.child_asset_hashes.PSObject.Properties){
            $childPath=Join-Path $stage $child.Value.relative
            if((Get-FileHash -LiteralPath $childPath).Hash -ne $child.Value.sha256){throw 'Original scoring child changed'};Add-JumpInput $childPath
        }
        $scoringFixture=[IO.Path]::GetFullPath($scoringProof.fixture.asset)
        if(!$scoringFixture.StartsWith(([IO.Path]::GetFullPath($stage)+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase) -or (Get-FileHash -LiteralPath $scoringFixture).Hash -ne $scoringProof.fixture.sha256){throw 'Owned concrete scoring fixture required'}
        Add-JumpInput $scoringFixture;Add-JumpInput $scoringSummaryPath;Add-JumpInput $scoringProofPath
        foreach($fixture in @('Content/UEPValidation/BP_MusicListenerProbe.uasset','Plugins/GameFeatures/ShooterCore/Content/Blueprint/B_WeaponSpawner.uasset','Plugins/GameFeatures/ShooterCore/Content/Weapon/Grenade/B_Grenade.uasset','Plugins/GameFeatures/ShooterCore/Content/Weapons/Rifle/WeaponPickupData_Rifle.uasset')){Add-JumpInput (Join-Path $stage $fixture)}
    }
    if($PhysicsFields){
        $physicsRoot=[IO.Path]::GetFullPath($PhysicsFieldAuthoringDirectory)
        if(!$physicsRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned physics field revision required'}
        $physicsSummaryPath=Join-Path $physicsRoot 'summary.json';$physicsProofPath=Join-Path $physicsRoot 'assets.json'
        $physicsAuthor=Get-Content -LiteralPath $physicsSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $physicsProof=Get-Content -LiteralPath $physicsProofPath -Raw|ConvertFrom-Json -Depth 80
        if($physicsAuthor.status -ne 'passed' -or $physicsProof.status -ne 'passed' -or $physicsAuthor.kind -ne 'physicsfields' -or $physicsProof.kind -ne 'physicsfields' -or
            !$physicsProof.original_full_cdos_signatures_business_graphs_and_component_templates_preserved -or !$physicsProof.original_engine_field_parent_and_geometry_collection_dependency_retained -or
            !$physicsProof.original_chaos_delegate_identity_and_disconnected_shatter_tick_preserved -or $physicsProof.new_business_nodes -ne 0 -or @($physicsAuthor.assets).Count -ne 4){throw 'Current physics field parent/Chaos/Profile proof incomplete'}
        foreach($label in @('example','sphere')){
            $actor=$physicsProof.actors.$label;$expectedNodes=@{example=7;sphere=20}[$label];$expectedTransport=@{example=6;sphere=5}[$label]
            if($actor.original_graph_nodes -ne $expectedNodes -or $actor.transport_nodes -ne $expectedTransport -or $actor.interface_nodes -ne 5 -or $actor.actual_registered_profile_method_counts.Python -ne 3 -or $actor.actual_registered_profile_method_counts.BlueprintFallback -ne 3){throw 'Current physics complete Profile families required'}
        }
        foreach($asset in $physicsAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Physics field asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $physicsSummaryPath;Add-JumpInput $physicsProofPath;Add-JumpInput (Join-Path $EngineRoot 'Engine/Content/EditorResources/FieldNodes/FS_MasterField.uasset')
        foreach($dependency in @('Content/Effects/Physics/ShatterSphere_GeometryCollection.uasset','Content/Effects/Physics/M_GlowyPink.uasset')){Add-JumpInput (Join-Path $stage $dependency)}
    }
    if($SmallBurstCues){
        $smallBurstRoot=[IO.Path]::GetFullPath($SmallBurstCueAuthoringDirectory)
        if(!$smallBurstRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned small Burst Cue revision required'}
        $smallBurstSummaryPath=Join-Path $smallBurstRoot 'summary.json';$smallBurstProofPath=Join-Path $smallBurstRoot 'assets.json'
        $smallBurstAuthor=Get-Content -LiteralPath $smallBurstSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $smallBurstProof=Get-Content -LiteralPath $smallBurstProofPath -Raw|ConvertFrom-Json -Depth 80
        if($smallBurstAuthor.status -ne 'passed' -or $smallBurstProof.status -ne 'passed' -or $smallBurstAuthor.kind -ne 'smallburstcues' -or $smallBurstProof.kind -ne 'smallburstcues' -or
            !$smallBurstProof.original_full_cdos_signatures_graphs_and_construction_templates_preserved -or !$smallBurstProof.original_static_parent_effects_and_latent_heal_parent_lifetime_preserved -or
            $smallBurstProof.new_business_nodes -ne 0 -or @($smallBurstAuthor.assets).Count -ne 8){throw 'Current small Burst Cue parent/Profile proof incomplete'}
        foreach($label in @('pickup','melee','heal','grenade')){
            $cue=$smallBurstProof.cues.$label;$expectedNodes=@{pickup=10;melee=3;heal=4;grenade=9}[$label]
            if($cue.original_graph_nodes -ne $expectedNodes -or $cue.transport_nodes -ne 0 -or $cue.interface_nodes -ne 5 -or $cue.actual_registered_profile_method_counts.Python -ne 1 -or $cue.actual_registered_profile_method_counts.BlueprintFallback -ne 1){throw 'Current small Burst Cue complete Profile family required'}
        }
        foreach($asset in $smallBurstAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Small Burst Cue asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $smallBurstSummaryPath;Add-JumpInput $smallBurstProofPath;Add-JumpInput (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-NonRealtimeAudioRenderer.dll')
        foreach($fixtureAsset in @('Plugins/GameFeatures/ShooterCore/Content/Blueprint/B_WeaponSpawner.uasset','Plugins/GameFeatures/ShooterCore/Content/Weapon/Grenade/B_Grenade.uasset','Plugins/GameFeatures/ShooterCore/Content/Weapons/Rifle/WeaponPickupData_Rifle.uasset')){Add-JumpInput (Join-Path $stage $fixtureAsset)}
    }
    if($SpawningCue){
        $spawningRoot=[IO.Path]::GetFullPath($SpawningCueAuthoringDirectory)
        if(!$spawningRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned spawning Cue revision required'}
        $spawningSummaryPath=Join-Path $spawningRoot 'summary.json';$spawningProofPath=Join-Path $spawningRoot 'assets.json'
        $spawningAuthor=Get-Content -LiteralPath $spawningSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $spawningProof=Get-Content -LiteralPath $spawningProofPath -Raw|ConvertFrom-Json -Depth 80
        if($spawningAuthor.status -ne 'passed' -or $spawningProof.status -ne 'passed' -or $spawningAuthor.kind -ne 'spawningcue' -or $spawningProof.kind -ne 'spawningcue' -or
            !$spawningProof.original_full_cdos_signatures_and_business_graphs_preserved -or !$spawningProof.original_native_timeline_templates_curves_guids_and_bindings_preserved -or
            !$spawningProof.original_async_factory_proxy_assignment_callbacks_latent_uuid_and_delegate_identity_preserved -or !$spawningProof.original_native_parent_effects_and_lifetime_preserved -or
            $spawningProof.original_graph_nodes -ne 118 -or $spawningProof.transport_nodes -ne 7 -or $spawningProof.interface_nodes -ne 5 -or $spawningProof.python_timeline_clock_added -or $spawningProof.new_business_nodes -ne 0 -or
            $spawningProof.actual_registered_profile_method_counts.Python -ne 8 -or $spawningProof.actual_registered_profile_method_counts.BlueprintFallback -ne 8 -or @($spawningAuthor.assets).Count -ne 2){throw 'Current spawning Cue Timeline/async/delegate/Profile proof incomplete'}
        foreach($asset in $spawningAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Spawning Cue asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $spawningSummaryPath;Add-JumpInput $spawningProofPath
    }
    if($TraversalCues){
        $traversalRoot=[IO.Path]::GetFullPath($TraversalCueAuthoringDirectory)
        if(!$traversalRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned traversal Cue revision required'}
        $traversalSummaryPath=Join-Path $traversalRoot 'summary.json';$traversalProofPath=Join-Path $traversalRoot 'assets.json'
        $traversalAuthor=Get-Content -LiteralPath $traversalSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $traversalProof=Get-Content -LiteralPath $traversalProofPath -Raw|ConvertFrom-Json -Depth 80
        if($traversalAuthor.status -ne 'passed' -or $traversalProof.status -ne 'passed' -or $traversalAuthor.kind -ne 'traversalcues' -or $traversalProof.kind -ne 'traversalcues' -or
            !$traversalProof.original_full_cdos_signatures_and_business_graphs_preserved -or !$traversalProof.original_native_parent_effects_and_timer_preserved -or !$traversalProof.original_native_launcher_timeline_templates_curves_guids_and_bindings_preserved -or
            !$traversalProof.original_teleporter_increment_macro_graph_retained -or $traversalProof.python_timeline_clock_added -or $traversalProof.new_business_nodes -ne 0 -or
            $traversalProof.cues.launcher.original_graph_nodes -ne 98 -or $traversalProof.cues.teleporter.original_graph_nodes -ne 92 -or $traversalProof.cues.launcher.transport_nodes -ne 4 -or $traversalProof.cues.teleporter.transport_nodes -ne 0 -or
            $traversalProof.cues.launcher.actual_registered_profile_method_counts.Python -ne 3 -or $traversalProof.cues.launcher.actual_registered_profile_method_counts.BlueprintFallback -ne 3 -or
            $traversalProof.cues.teleporter.actual_registered_profile_method_counts.Python -ne 1 -or $traversalProof.cues.teleporter.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or @($traversalAuthor.assets).Count -ne 4){throw 'Current traversal Timeline/macro/Profile proof incomplete'}
        foreach($asset in $traversalAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Traversal Cue asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $traversalSummaryPath;Add-JumpInput $traversalProofPath
    }
    if($HeroBurstCues){
        $heroBurstRoot=[IO.Path]::GetFullPath($HeroBurstCueAuthoringDirectory)
        if(!$heroBurstRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned hero burst Cue revision required'}
        $heroBurstSummaryPath=Join-Path $heroBurstRoot 'summary.json';$heroBurstProofPath=Join-Path $heroBurstRoot 'assets.json'
        $heroBurstAuthor=Get-Content -LiteralPath $heroBurstSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $heroBurstProof=Get-Content -LiteralPath $heroBurstProofPath -Raw|ConvertFrom-Json -Depth 80
        if($heroBurstAuthor.status -ne 'passed' -or $heroBurstProof.status -ne 'passed' -or $heroBurstAuthor.kind -ne 'heroburstcues' -or $heroBurstProof.kind -ne 'heroburstcues' -or
            !$heroBurstProof.original_full_cdos_signatures_and_business_graphs_preserved -or !$heroBurstProof.original_native_parent_effects_and_five_second_minimum_timer_preserved -or
            !$heroBurstProof.native_timeline_tick_update_and_finish_retained -or $heroBurstProof.python_timeline_clock_added -or $heroBurstProof.new_business_nodes -ne 0 -or
            $heroBurstProof.cues.dash.original_graph_nodes -ne 63 -or $heroBurstProof.cues.death.original_graph_nodes -ne 91 -or $heroBurstProof.cues.dash.transport_nodes -ne 8 -or $heroBurstProof.cues.death.transport_nodes -ne 8 -or
            !$heroBurstProof.cues.dash.original_native_timeline_templates_curves_guids_and_event_bindings_preserved -or !$heroBurstProof.cues.death.original_native_timeline_templates_curves_guids_and_event_bindings_preserved -or
            $heroBurstProof.cues.dash.actual_registered_profile_method_counts.Python -ne 3 -or $heroBurstProof.cues.dash.actual_registered_profile_method_counts.BlueprintFallback -ne 3 -or
            $heroBurstProof.cues.death.actual_registered_profile_method_counts.Python -ne 3 -or $heroBurstProof.cues.death.actual_registered_profile_method_counts.BlueprintFallback -ne 3 -or @($heroBurstAuthor.assets).Count -ne 4){throw 'Current native hero burst Timeline/template/Profile proof incomplete'}
        foreach($asset in $heroBurstAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Hero burst Cue asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $heroBurstSummaryPath;Add-JumpInput $heroBurstProofPath
    }
    if($CharacterDamage){
        $damageRoot=[IO.Path]::GetFullPath($CharacterDamageAuthoringDirectory)
        if(!$damageRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned character damage revision required'}
        $damageSummaryPath=Join-Path $damageRoot 'summary.json';$damageProofPath=Join-Path $damageRoot 'assets.json'
        $damageAuthor=Get-Content -LiteralPath $damageSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $damageProof=Get-Content -LiteralPath $damageProofPath -Raw|ConvertFrom-Json -Depth 80
        if($damageAuthor.status -ne 'passed' -or $damageProof.status -ne 'passed' -or $damageAuthor.kind -ne 'characterdamage' -or $damageProof.kind -ne 'characterdamage' -or
            !$damageProof.original_full_cdo_event_signatures_business_and_rpc_preserved -or !$damageProof.native_parent_burst_effects_and_lifetime_timer_preserved -or
            !$damageProof.original_unreliable_multicast_shell_preserved -or $damageProof.rpc_function_overridden -or !$damageProof.original_native_rng_nodes_ranges_and_select_topology_retained -or
            !$damageProof.typed_native_message_thunk_adapter -or $damageProof.original_graph_nodes -ne 160 -or $damageProof.transport_nodes -ne 25 -or !$damageProof.generic_native_interface_array_count_and_object_accessors -or $damageProof.new_business_nodes -ne 0 -or
            $damageProof.actual_registered_profile_method_counts.Python -ne 7 -or $damageProof.actual_registered_profile_method_counts.BlueprintFallback -ne 7 -or @($damageAuthor.assets).Count -ne 2){throw 'Current damage parent/RPC/RNG/message proof incomplete'}
        foreach($asset in $damageAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Character damage asset changed'};Add-JumpInput $path
        }}
        if((Get-FileHash -LiteralPath $damageProof.caller_probe.asset).Hash -ne $damageProof.caller_probe.sha256){throw 'Character damage typed caller changed'}
        Add-JumpInput $damageProof.caller_probe.asset;Add-JumpInput $damageSummaryPath;Add-JumpInput $damageProofPath
    }
    if($MessageWidgets){
        $messageRoot=[IO.Path]::GetFullPath($MessageWidgetAuthoringDirectory)
        if(!$messageRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned message widget revision required'}
        $messageSummaryPath=Join-Path $messageRoot 'summary.json';$messageProofPath=Join-Path $messageRoot 'assets.json'
        $messageAuthor=Get-Content -LiteralPath $messageSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $messageProof=Get-Content -LiteralPath $messageProofPath -Raw|ConvertFrom-Json -Depth 80
        if($messageAuthor.status -ne 'passed' -or $messageProof.status -ne 'passed' -or $messageAuthor.kind -ne 'messagewidgets' -or $messageProof.kind -ne 'messagewidgets' -or
            !$messageProof.original_full_cdos_widget_trees_event_signatures_and_business_preserved -or !$messageProof.original_localized_text_pins_retained -or
            $messageProof.localized_text_roundtripped_through_python -or !$messageProof.original_native_listener_node_and_exact_channel_reused -or !$messageProof.no_python_subscription_roots -or
            $messageProof.original_graph_nodes.match -ne 70 -or $messageProof.original_graph_nodes.waiting -ne 18 -or $messageProof.transport_nodes.match -ne 11 -or $messageProof.transport_nodes.waiting -ne 8 -or
            $messageProof.actual_registered_profile_method_counts.match.Python -ne 3 -or $messageProof.actual_registered_profile_method_counts.match.BlueprintFallback -ne 3 -or
            $messageProof.actual_registered_profile_method_counts.waiting.Python -ne 2 -or $messageProof.actual_registered_profile_method_counts.waiting.BlueprintFallback -ne 2 -or @($messageAuthor.assets).Count -ne 4){throw 'Current message style/localized text/native listener proof incomplete'}
        foreach($asset in $messageAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Message widget asset changed'};Add-JumpInput $path
        }}
        if((Get-FileHash -LiteralPath $messageProof.caller_probe.asset).Hash -ne $messageProof.caller_probe.sha256){throw 'Typed message widget probe changed'}
        Add-JumpInput $messageProof.caller_probe.asset;Add-JumpInput $messageSummaryPath;Add-JumpInput $messageProofPath
    }
    if($CueWidgets -or $MessageWidgets){
        $cueRoot=[IO.Path]::GetFullPath($CueWidgetAuthoringDirectory)
        if(!$cueRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned Cue widget revision required'}
        $cueSummaryPath=Join-Path $cueRoot 'summary.json';$cueProofPath=Join-Path $cueRoot 'assets.json'
        $cueAuthor=Get-Content -LiteralPath $cueSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $cueProof=Get-Content -LiteralPath $cueProofPath -Raw|ConvertFrom-Json -Depth 80
        if($cueAuthor.status -ne 'passed' -or $cueProof.status -ne 'passed' -or $cueAuthor.kind -ne 'cuewidgets' -or $cueProof.kind -ne 'cuewidgets' -or
            !$cueProof.original_full_cdo_preserved -or !$cueProof.original_business_graphs_preserved_with_dispatch -or !$cueProof.original_native_parent_start_call_preserved -or
            !$cueProof.child_defaults_event_signatures_and_asset_bytes_preserved -or !$cueProof.base_owned_gates -or !$cueProof.production_abstract_base_preserved -or $cueProof.original_graph_nodes -ne 40 -or
            $cueProof.transport_nodes -ne 8 -or $cueProof.new_business_nodes -ne 0 -or $cueProof.actual_registered_profile_method_counts.Python -ne 2 -or
            $cueProof.actual_registered_profile_method_counts.BlueprintFallback -ne 2 -or @($cueAuthor.assets).Count -ne 2){throw 'Current Cue widget base/native parent/child proof incomplete'}
        foreach($asset in $cueAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Cue widget asset changed'};Add-JumpInput $path
        }}
        foreach($entry in $cueProof.child_reference_hashes.PSObject.Properties){
            $path=Join-Path $stage $entry.Name
            if((Get-FileHash -LiteralPath $path).Hash -ne $entry.Value){throw 'Original Cue child asset changed'};Add-JumpInput $path
        }
        if((Get-FileHash -LiteralPath $cueProof.caller_probe.asset).Hash -ne $cueProof.caller_probe.sha256){throw 'Cue manager BP caller changed'}
        if((Get-FileHash -LiteralPath $cueProof.fixture_probe.asset).Hash -ne $cueProof.fixture_probe.sha256 -or !$cueProof.fixture_probe.stage_only){throw 'Cue concrete diagnostic child changed'}
        Add-JumpInput $cueProof.fixture_probe.asset
        Add-JumpInput $cueProof.caller_probe.asset;Add-JumpInput $cueSummaryPath;Add-JumpInput $cueProofPath
    }
    if($Footstep){
        $footRoot=[IO.Path]::GetFullPath($FootstepAuthoringDirectory)
        if(!$footRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned footstep revision required'}
        $footSummaryPath=Join-Path $footRoot 'summary.json';$footProofPath=Join-Path $footRoot 'assets.json'
        $footAuthor=Get-Content -LiteralPath $footSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $footProof=Get-Content -LiteralPath $footProofPath -Raw|ConvertFrom-Json -Depth 80
        if($footAuthor.status -ne 'passed' -or $footProof.status -ne 'passed' -or $footAuthor.kind -ne 'footstep' -or $footProof.kind -ne 'footstep' -or
            !$footProof.original_full_cdo_preserved -or !$footProof.interface_signature_preserved -or !$footProof.original_business_graphs_preserved_with_dispatch -or
            !$footProof.native_register_restore_passed -or !$footProof.original_retriggerable_delay_node_reused -or !$footProof.native_delay_uuid_preserved -or
            !$footProof.cleanup_tests_validity_not_active -or $footProof.native_delay_seconds -ne 3 -or $footProof.original_graph_nodes -ne 93 -or
            $footProof.transport_nodes -ne 3 -or $footProof.new_business_nodes -ne 0 -or
            $footProof.actual_registered_profile_method_counts.Python -ne 2 -or $footProof.actual_registered_profile_method_counts.BlueprintFallback -ne 2 -or @($footAuthor.assets).Count -ne 2){throw 'Current footstep interface/Niagara/latent proof incomplete'}
        foreach($asset in $footAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Footstep asset changed'};Add-JumpInput $path
        }}
        if((Get-FileHash -LiteralPath $footProof.caller_probe.asset).Hash -ne $footProof.caller_probe.sha256){throw 'Footstep typed caller changed'}
        Add-JumpInput $footProof.caller_probe.asset;Add-JumpInput $footSummaryPath;Add-JumpInput $footProofPath
    }
    if($WeaponFireFX -or (($WeaponActorFire -or $WeaponAbilityFire) -and $WeaponFireFXAuthoringDirectory)){
        $fxRoot=[IO.Path]::GetFullPath($WeaponFireFXAuthoringDirectory)
        if(!$fxRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned weapon fire FX revision required'}
        $fxSummaryPath=Join-Path $fxRoot 'summary.json';$fxProofPath=Join-Path $fxRoot 'assets.json'
        $fxAuthor=Get-Content -LiteralPath $fxSummaryPath -Raw|ConvertFrom-Json -Depth 80;$fxProof=Get-Content -LiteralPath $fxProofPath -Raw|ConvertFrom-Json -Depth 80
        if($fxAuthor.status -ne 'passed' -or $fxProof.status -ne 'passed' -or $fxAuthor.kind -ne 'weaponfirefx' -or $fxProof.kind -ne 'weaponfirefx' -or
            !$fxProof.original_full_cdo_preserved -or !$fxProof.original_business_graphs_preserved_with_dispatch -or !$fxProof.original_retriggerable_delay_node_reused -or
            !$fxProof.native_delay_uuid_preserved -or !$fxProof.cleanup_tests_validity_not_active -or $fxProof.native_delay_seconds -ne 3 -or $fxProof.transport_nodes -ne 3 -or
            $fxProof.new_business_nodes -ne 0 -or $fxProof.actual_registered_profile_method_counts.Python -ne 2 -or $fxProof.actual_registered_profile_method_counts.BlueprintFallback -ne 2 -or @($fxAuthor.assets).Count -ne 2){throw 'Current native weapon fire FX delay/dispatch proof incomplete'}
        foreach($asset in $fxAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Weapon fire FX asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $fxSummaryPath;Add-JumpInput $fxProofPath
    }
    if($WeaponActorBegin -or (($WeaponActorFire -or $WeaponActorHelpers -or $WeaponAbilityFire) -and $WeaponActorBeginAuthoringDirectory)){
        $beginRoot=[IO.Path]::GetFullPath($WeaponActorBeginAuthoringDirectory)
        if(!$beginRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned weapon BeginPlay revision required'}
        $beginSummaryPath=Join-Path $beginRoot 'summary.json';$beginProofPath=Join-Path $beginRoot 'assets.json'
        $beginAuthor=Get-Content -LiteralPath $beginSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $beginProof=Get-Content -LiteralPath $beginProofPath -Raw|ConvertFrom-Json -Depth 80
        if($beginAuthor.status -ne 'passed' -or $beginProof.status -ne 'passed' -or $beginAuthor.kind -ne 'weaponactorbegin' -or $beginProof.kind -ne 'weaponactorbegin' -or
            !$beginProof.original_full_cdo_preserved -or !$beginProof.original_graphs_unmodified -or !$beginProof.native_register_restore_passed -or !$beginProof.parent_rebuilt_from_official -or
            !$beginProof.begin_play_migrated -or !$beginProof.native_weak_delegate_retained -or $beginProof.python_callback_retained -or $beginProof.transport_nodes -ne 4 -or $beginProof.new_business_nodes -ne 0 -or
            $beginProof.actual_registered_profile_method_counts.Python -ne 7 -or $beginProof.actual_registered_profile_method_counts.BlueprintFallback -ne 7 -or @($beginAuthor.assets).Count -ne 2){throw 'Current seven-method weapon BeginPlay proof incomplete'}
        foreach($asset in $beginAuthor.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Weapon BeginPlay asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $beginSummaryPath;Add-JumpInput $beginProofPath
    }
    if($WeaponActorFire -or (($WeaponActorHelpers -or $WeaponAbilityFire) -and $WeaponActorFireAuthoringDirectory)){
        $fireRoot=[IO.Path]::GetFullPath($WeaponActorFireAuthoringDirectory)
        if(!$fireRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned weapon Fire revision required'}
        $fireSummaryPath=Join-Path $fireRoot 'summary.json';$fireProofPath=Join-Path $fireRoot 'assets.json'
        $fireAuthor=Get-Content -LiteralPath $fireSummaryPath -Raw|ConvertFrom-Json -Depth 80
        $fireProof=Get-Content -LiteralPath $fireProofPath -Raw|ConvertFrom-Json -Depth 80
        if($fireAuthor.status -ne 'passed' -or $fireProof.status -ne 'passed' -or $fireAuthor.kind -ne 'weaponactorfire' -or $fireProof.kind -ne 'weaponactorfire' -or
            !$fireProof.original_full_cdo_preserved -or !$fireProof.original_graphs_unmodified -or !$fireProof.native_register_restore_passed -or !$fireProof.native_original_fx_actors_retained -or !$fireProof.parent_saved_bytes_unchanged -or
            $fireProof.actual_registered_profile_method_counts.Python -ne 5 -or $fireProof.actual_registered_profile_method_counts.BlueprintFallback -ne 5 -or
            $fireProof.new_business_nodes -ne 0 -or $fireProof.begin_play_migrated -or @($fireAuthor.assets).Count -ne 2){throw 'Current five-method weapon Fire proof incomplete'}
        $fireAssets=$fireAuthor.assets
        if($WeaponActorBeginAuthoringDirectory){
            if($beginAuthor.previous_dash_directory -ne $fireRoot){throw 'Weapon Fire regression requires exact previous revision'}
            $fireAssets=$beginAuthor.assets
        }
        foreach($asset in $fireAssets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Weapon Fire asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $fireSummaryPath;Add-JumpInput $fireProofPath
    }
    if($WeaponActorHelpers){
        $helperRoot=[IO.Path]::GetFullPath($WeaponActorHelpersAuthoringDirectory)
        if(!$helperRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned weapon helper authoring required'}
        $helperSummary=Join-Path $helperRoot 'summary.json';$helperReport=Join-Path $helperRoot 'assets.json'
        $author=Get-Content -LiteralPath $helperSummary -Raw|ConvertFrom-Json -Depth 80
        $proof=Get-Content -LiteralPath $helperReport -Raw|ConvertFrom-Json -Depth 80
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne 'weaponactorhelpers' -or $proof.kind -ne 'weaponactorhelpers' -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_register_restore_passed -or $proof.new_business_nodes -ne 0 -or
            $proof.actual_registered_profile_method_counts.Python -ne 4 -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 4 -or
            @($proof.inherited_children).Count -ne 3 -or @($author.assets).Count -ne 2 -or $proof.fire_and_begin_play_migrated){throw 'Current native weapon parent helper proof incomplete'}
        $helperAssets=$author.assets
        if($WeaponActorFireAuthoringDirectory){
            if($fireAuthor.previous_dash_directory -ne $helperRoot){throw 'Weapon helper regression requires exact previous parent revision'}
            $helperAssets=if($WeaponActorBeginAuthoringDirectory){$beginAuthor.assets}else{$fireAuthor.assets}
        }
        foreach($asset in $helperAssets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Weapon helper asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $helperSummary;Add-JumpInput $helperReport
    }
    if($GrenadeFlightNetwork){
        $flightRoot=[IO.Path]::GetFullPath($GrenadeFlightAbilityAuthoringDirectory)
        if(!$flightRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned natural Grenade ability revision required'}
        $flightSummary=Join-Path $flightRoot 'summary.json';$flightReport=Join-Path $flightRoot 'assets.json'
        $author=Get-Content -LiteralPath $flightSummary -Raw|ConvertFrom-Json -Depth 80
        $proof=Get-Content -LiteralPath $flightReport -Raw|ConvertFrom-Json -Depth 80
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne 'grenadeactivation' -or $proof.kind -ne 'grenadeactivation' -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_register_restore_passed -or
            !$proof.actual_activation_event_overridden -or !$proof.activation_aim_business_migrated -or $proof.projectile_actor_business_migrated -or
            $proof.new_business_nodes -ne 0 -or $proof.actual_registered_profile_method_counts.Python -ne 3 -or
            $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 3 -or @($author.assets).Count -ne 2){throw 'Current native Grenade activation proof required for flight integration'}
        foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Natural flight ability asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $flightSummary;Add-JumpInput $flightReport
        foreach($relative in @('Engine/Source/Runtime/Engine/Private/DataReplication.cpp','Engine/Source/Runtime/Engine/Private/DataChannel.cpp','Engine/Source/Runtime/Engine/Private/NetDriver.cpp','Engine/Source/Runtime/Core/Public/Misc/NetworkGuid.h')){Add-JumpInput (Join-Path $EngineRoot $relative)}
    }
    if($GrenadeDetonate){
        $root=[IO.Path]::GetFullPath($GrenadeDetonateAuthoringDirectory)
        if(!$root.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned explosion revision proof required'}
        $authorPath=Join-Path $root 'summary.json';$proofPath=Join-Path $root 'assets.json'
        $author=Get-Content -LiteralPath $authorPath -Raw|ConvertFrom-Json -Depth 80
        $proof=Get-Content -LiteralPath $proofPath -Raw|ConvertFrom-Json -Depth 80
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne 'grenadedetonate' -or $proof.kind -ne 'grenadedetonate' -or
            !$proof.original_full_cdo_preserved -or !$proof.original_business_graphs_preserved_with_dispatch -or !$proof.native_server_rpc_flags_preserved -or
            !$proof.native_register_restore_passed -or !$proof.native_do_once_retained -or !$proof.native_weak_delegate_retained -or
            !$proof.python_body_has_no_original_fallthrough -or $proof.transport_nodes -ne 3 -or $proof.new_business_nodes -ne 0 -or
            $proof.actual_registered_profile_method_counts.Python -ne 7 -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 7 -or
            !$proof.actor_detonate_damage_business_migrated -or @($author.assets).Count -ne 2){throw 'Accepted native explosion transport/retained-body proof required'}
        foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Grenade explosion asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $authorPath;Add-JumpInput $proofPath
    }
    if($GrenadeHit){
        $hitRoot=[IO.Path]::GetFullPath($GrenadeHitAuthoringDirectory)
        if(!$hitRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned Hit revision required'}
        $hitSummary=Join-Path $hitRoot 'summary.json';$hitReport=Join-Path $hitRoot 'assets.json'
        $author=Get-Content -LiteralPath $hitSummary -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $hitReport -Raw|ConvertFrom-Json -Depth 80
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne 'grenadehit' -or $proof.kind -ne 'grenadehit' -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_register_restore_passed -or !$proof.native_server_rpc_flags_preserved -or
            $proof.new_business_nodes -ne 0 -or $proof.actual_registered_profile_method_counts.Python -ne 6 -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 6 -or
            !$proof.original_hit_policy.all_reflected_inputs_preserved -or !$proof.original_hit_policy.different_team_clears_fuse_then_requests_native_rpc -or
            $proof.actor_detonate_damage_business_migrated -or @($author.assets).Count -ne 2){throw 'Accepted native Actor Hit team/timer/RPC/audio proof required'}
        foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Grenade Hit asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $hitSummary;Add-JumpInput $hitReport
    }
    if($GrenadeBegin){
        $beginRoot=[IO.Path]::GetFullPath($GrenadeBeginAuthoringDirectory)
        if(!$beginRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned BeginPlay revision required'}
        $beginSummary=Join-Path $beginRoot 'summary.json';$beginReport=Join-Path $beginRoot 'assets.json'
        $author=Get-Content -LiteralPath $beginSummary -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $beginReport -Raw|ConvertFrom-Json -Depth 80
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne 'grenadebegin' -or $proof.kind -ne 'grenadebegin' -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_register_restore_passed -or !$proof.native_server_rpc_flags_preserved -or
            $proof.new_business_nodes -ne 0 -or $proof.actual_registered_profile_method_counts.Python -ne 5 -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 5 -or
            $proof.original_begin_policy.native_function_name_api -ne 'K2_SetTimer' -or !$proof.original_begin_policy.native_timer_actor_owner -or
            $proof.original_begin_policy.new_native_adapters -ne 0 -or $proof.actor_detonate_damage_business_migrated -or @($author.assets).Count -ne 2){throw 'Accepted original Actor BeginPlay/native timer proof required'}
        foreach($asset in @(Get-JumpCurrentActorAssets $author)){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Grenade BeginPlay asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $beginSummary;Add-JumpInput $beginReport
        foreach($relative in @('Engine/Source/Runtime/Engine/Private/KismetSystemLibrary.cpp','Engine/Source/Runtime/Engine/Classes/Kismet/KismetSystemLibrary.h',
            'Engine/Source/Runtime/Engine/Public/Materials/MaterialInterface.h','Engine/Source/Runtime/Engine/Private/TimerManager.cpp')){Add-JumpInput (Join-Path $EngineRoot $relative)}
    }
    if($GrenadeActions){
        $actionRoot=[IO.Path]::GetFullPath($GrenadeActionsAuthoringDirectory)
        if(!$actionRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned Actor action revision required'}
        $actionSummary=Join-Path $actionRoot 'summary.json';$actionReport=Join-Path $actionRoot 'assets.json'
        $author=Get-Content -LiteralPath $actionSummary -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $actionReport -Raw|ConvertFrom-Json -Depth 80
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne 'grenadeactions' -or $proof.kind -ne 'grenadeactions' -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_register_restore_passed -or !$proof.native_server_rpc_flags_preserved -or
            $proof.new_business_nodes -ne 0 -or $proof.actual_registered_profile_method_counts.Python -ne 4 -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 4 -or
            $proof.original_action_policy.speed_divisor -ne 2. -or !$proof.original_action_policy.forward_not_normalized -or !$proof.original_action_policy.invalid_trail_stops_after_conserved_write -or
            $proof.actor_fuse_detonate_damage_business_migrated -or @($author.assets).Count -ne 2){throw 'Accepted retained Actor teleport/destroy proof required'}
        foreach($asset in @(Get-JumpCurrentActorAssets $author)){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Grenade action asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $actionSummary;Add-JumpInput $actionReport
        Add-JumpInput (Join-Path $EngineRoot 'Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraComponent.cpp')
    }
    if($GrenadeCleanup){
        $cleanupRoot=[IO.Path]::GetFullPath($GrenadeCleanupAuthoringDirectory)
        if(!$cleanupRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned cleanup revision proof required'}
        $cleanupSummary=Join-Path $cleanupRoot 'summary.json';$cleanupReport=Join-Path $cleanupRoot 'assets.json'
        $author=Get-Content -LiteralPath $cleanupSummary -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $cleanupReport -Raw|ConvertFrom-Json -Depth 80
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne 'grenadecleanup' -or $proof.kind -ne 'grenadecleanup' -or $proof.original_cleanup_policy.native_timer_seconds -ne .16){throw 'Original native cleanup provenance required'}
        Add-JumpInput $cleanupSummary;Add-JumpInput $cleanupReport
        $cleanupKind='grenadecleanup';$cleanupMethods=2
        if($GrenadeActionsAuthoringDirectory){
            $currentRoot=[IO.Path]::GetFullPath($GrenadeActionsAuthoringDirectory)
            if(!$currentRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned current Actor action revision required'}
            $currentSummary=Join-Path $currentRoot 'summary.json';$currentReport=Join-Path $currentRoot 'assets.json'
            $author=Get-Content -LiteralPath $currentSummary -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $currentReport -Raw|ConvertFrom-Json -Depth 80
            $baseHash=(Get-FileHash -LiteralPath $cleanupSummary).Hash
            if($author.previous_dash_directory -ne $cleanupRoot -or !@($author.hashes|Where-Object {$_.path -eq $cleanupSummary -and $_.sha256 -eq $baseHash}).Count){throw 'Cleanup regression requires matching current action revision chain'}
            Add-JumpInput $currentSummary;Add-JumpInput $currentReport
            $cleanupKind='grenadeactions';$cleanupMethods=4
        }
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne $cleanupKind -or $proof.kind -ne $cleanupKind -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_register_restore_passed -or !$proof.native_server_rpc_flags_preserved -or
            $proof.new_business_nodes -ne 0 -or $proof.actual_registered_profile_method_counts.Python -ne $cleanupMethods -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne $cleanupMethods -or
            $proof.actor_fuse_detonate_damage_business_migrated -or @($author.assets).Count -ne 2){throw 'Accepted original native cleanup timer/profile proof required'}
        foreach($asset in @(Get-JumpCurrentActorAssets $author)){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Grenade cleanup asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $cleanupSummary;Add-JumpInput $cleanupReport
        foreach($header in @('Engine/Source/Runtime/Engine/Classes/Components/PrimitiveComponent.h','Engine/Source/Runtime/Engine/Classes/GameFramework/ProjectileMovementComponent.h')){Add-JumpInput (Join-Path $EngineRoot $header)}
    }
    if($GrenadeVFX){
        $vfxRoot=[IO.Path]::GetFullPath($GrenadeVFXAuthoringDirectory)
        if(!$vfxRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned VFX authoring proof required'}
        $vfxSummary=Join-Path $vfxRoot 'summary.json';$vfxReport=Join-Path $vfxRoot 'assets.json'
        $author=Get-Content -LiteralPath $vfxSummary -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $vfxReport -Raw|ConvertFrom-Json -Depth 80
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne 'grenadevfx' -or $proof.kind -ne 'grenadevfx'){throw 'Original retained VFX authoring provenance required'}
        Add-JumpInput $vfxSummary;Add-JumpInput $vfxReport
        $vfxKind='grenadevfx';$vfxMethods=1;$vfxWhole=$proof.actor_collision_fuse_explosion_damage_migrated
        if($GrenadeCleanupAuthoringDirectory){
            $revisionRoot=[IO.Path]::GetFullPath($GrenadeCleanupAuthoringDirectory)
            if(!$revisionRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned current Actor revision required'}
            $revisionSummary=Join-Path $revisionRoot 'summary.json';$revisionReport=Join-Path $revisionRoot 'assets.json'
            $author=Get-Content -LiteralPath $revisionSummary -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $revisionReport -Raw|ConvertFrom-Json -Depth 80
            if($author.previous_dash_directory -ne $vfxRoot -or !$proof.native_server_rpc_flags_preserved -or $proof.original_cleanup_policy.native_timer_seconds -ne .16){throw 'VFX regression requires matching retained Actor revision provenance'}
            $baseHash=(Get-FileHash -LiteralPath $vfxSummary).Hash
            if(!@($author.hashes|Where-Object {$_.path -eq $vfxSummary -and $_.sha256 -eq $baseHash}).Count){throw 'Original VFX proof not frozen by current Actor revision'}
            Add-JumpInput $revisionSummary;Add-JumpInput $revisionReport
            $vfxKind='grenadecleanup';$vfxMethods=2;$vfxWhole=$proof.actor_fuse_detonate_damage_business_migrated
        }
        if($GrenadeActionsAuthoringDirectory){
            if(!$GrenadeCleanupAuthoringDirectory){throw 'VFX action regression requires the intermediate cleanup revision'}
            $currentRoot=[IO.Path]::GetFullPath($GrenadeActionsAuthoringDirectory)
            if(!$currentRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned VFX current action revision required'}
            $currentSummary=Join-Path $currentRoot 'summary.json';$currentReport=Join-Path $currentRoot 'assets.json'
            $author=Get-Content -LiteralPath $currentSummary -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $currentReport -Raw|ConvertFrom-Json -Depth 80
            $baseHash=(Get-FileHash -LiteralPath $revisionSummary).Hash
            if($author.previous_dash_directory -ne $revisionRoot -or !@($author.hashes|Where-Object {$_.path -eq $revisionSummary -and $_.sha256 -eq $baseHash}).Count){throw 'VFX regression requires matching current action revision chain'}
            Add-JumpInput $currentSummary;Add-JumpInput $currentReport
            $vfxKind='grenadeactions';$vfxMethods=4;$vfxWhole=$proof.actor_fuse_detonate_damage_business_migrated
        }
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $author.kind -ne $vfxKind -or $proof.kind -ne $vfxKind -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_register_restore_passed -or $proof.new_business_nodes -ne 0 -or
            $proof.actual_registered_profile_method_counts.Python -ne $vfxMethods -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne $vfxMethods -or
            $proof.original_class -ne '/ShooterCore/Weapon/Grenade/B_Grenade.B_Grenade_C' -or $proof.original_vfx_policy.red_team_id -ne 1 -or
            $vfxWhole -or @($author.assets).Count -ne 2){throw 'Accepted retained Grenade Actor VFX proof required'}
        foreach($asset in @(Get-JumpCurrentActorAssets $author)){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Grenade VFX asset changed'};Add-JumpInput $path
        }}
        Add-JumpInput $vfxSummary;Add-JumpInput $vfxReport
        foreach($header in @('Engine/Plugins/FX/Niagara/Source/Niagara/Public/NiagaraParameterStore.h','Engine/Plugins/FX/Niagara/Source/Niagara/Public/NiagaraComponent.h',
            'Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraFunctionLibrary.cpp','Engine/Plugins/FX/Niagara/Source/Niagara/Private/NiagaraComponent.cpp')){Add-JumpInput (Join-Path $EngineRoot $header)}
    }
    if($GrenadeWidget -or $GrenadeActivation){
        $grenadeRoot=[IO.Path]::GetFullPath($GrenadeAuthoringDirectory)
        if(!$grenadeRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Grenade UI proof must be workspace-owned'}
        $grenadeSummary=Join-Path $grenadeRoot 'summary.json';$grenadeReport=Join-Path $grenadeRoot 'assets.json'
        $author=Get-Content -LiteralPath $grenadeSummary -Raw|ConvertFrom-Json -Depth 80
        $proof=Get-Content -LiteralPath $grenadeReport -Raw|ConvertFrom-Json -Depth 80
        $grenadeKind=if($GrenadeActivation){'grenadeactivation'}else{'grenadewidget'}
        $grenadeCount=if($GrenadeActivation){3}else{2}
        if($author.status -ne 'passed' -or $author.kind -ne $grenadeKind -or $proof.status -ne 'passed' -or $proof.kind -ne $grenadeKind -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_register_restore_passed -or
            $proof.new_business_nodes -ne 0 -or
            $proof.actual_registered_profile_method_counts.Python -ne $grenadeCount -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne $grenadeCount -or
            @($author.assets).Count -ne 2){throw 'Accepted retained Grenade UI native event proof required'}
        if($proof.original_class -ne '/ShooterCore/Input/Abilities/GA_Grenade.GA_Grenade_C'){throw 'Wrong Grenade native target'}
        if($GrenadeActivation){
            if(!$proof.actual_activation_event_overridden -or !$proof.activation_aim_business_migrated -or $proof.projectile_actor_business_migrated -or
                $proof.original_activation_policy.montage_completion_connections -ne 0 -or !$proof.original_activation_policy.end_immediately_after_message){throw 'Grenade activation retained native policy proof incomplete'}
        }elseif($proof.native_end_adapter_nodes -ne 0 -or $proof.whole_grenade_activation_projectile_damage_migrated -or
            ($proof.implemented_methods -join ',') -ne 'K2_OnPawnAvatarSet,K2_OnAbilityRemoved'){throw 'Wrong Grenade UI native events'}
        foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Grenade UI asset changed'}
            Add-JumpInput $path
        }}
        Add-JumpInput $grenadeSummary;Add-JumpInput $grenadeReport
    }
    if($MeleeHitMontage){
        $meleeRoot=[IO.Path]::GetFullPath($MeleeAuthoringDirectory)
        if(!$meleeRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Melee proof must be workspace-owned'}
        $meleeSummary=Join-Path $meleeRoot 'summary.json';$meleeReport=Join-Path $meleeRoot 'assets.json'
        $auth=Get-Content -LiteralPath $meleeSummary -Raw|ConvertFrom-Json -Depth 100;$proof=Get-Content -LiteralPath $meleeReport -Raw|ConvertFrom-Json -Depth 100
        if($auth.status -ne 'passed' -or $auth.kind -ne 'meleehitmontage' -or $proof.status -ne 'passed' -or $proof.kind -ne 'meleehitmontage' -or
            !$proof.original_full_cdo_preserved -or !$proof.original_graphs_unmodified -or !$proof.native_register_restore_passed -or
            $proof.new_business_nodes -ne 0 -or $proof.native_end_adapter_nodes -ne 0 -or @($auth.assets).Count -ne 2 -or
            $proof.actual_registered_profile_method_counts.Python -ne 1 -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or
            $proof.original_selector.nodes -ne 24 -or $proof.original_selector.min -ne -.5 -or $proof.original_selector.max -ne .5 -or
            !$proof.caller_probe.stage_only -or $proof.caller_probe.gameplay_business -or !$proof.caller_probe.typed_ability_and_actor_references -or
            $proof.caller_probe.nodes -ne 3 -or !$proof.caller_probe.virtual_bp_function_call -or $proof.whole_melee_activation_trace_damage_migrated){throw 'Accepted retained Melee helper/caller proof required'}
        $currentMelee=@($auth.assets)
        if($MeleeActivationAuthoringDirectory){
            $entryRoot=[IO.Path]::GetFullPath($MeleeActivationAuthoringDirectory)
            if(!$entryRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Melee entry proof must be workspace-owned'}
            $entryPath=Join-Path $entryRoot 'summary.json';$entryReport=Join-Path $entryRoot 'assets.json'
            $revision=Get-Content -LiteralPath $entryPath -Raw|ConvertFrom-Json -Depth 100;$entryProof=Get-Content -LiteralPath $entryReport -Raw|ConvertFrom-Json -Depth 100
            if($revision.status -ne 'passed' -or $revision.kind -ne 'meleeactivation' -or $entryProof.status -ne 'passed' -or
                !$entryProof.original_full_cdo_preserved -or !$entryProof.original_business_graphs_preserved_with_dispatch -or
                !$entryProof.native_register_restore_passed -or !$entryProof.actual_activation_event_overridden -or
                !$entryProof.native_end_teardown_bypass -or $entryProof.native_end_transport_signature.owner -ne $proof.original_class -or
                $entryProof.actual_registered_profile_method_counts.Python -ne 3 -or $entryProof.actual_registered_profile_method_counts.BlueprintFallback -ne 3 -or
                $entryProof.transport_nodes -ne 7 -or $entryProof.new_business_nodes -ne 0 -or $entryProof.whole_melee_trace_damage_business_migrated -or
                $entryProof.native_trace_entry -ne 'UEPMeleeAuthorityTrace' -or ($entryProof.native_trace_signature.flags -band 0x40) -or
                [IO.Path]::GetFullPath($revision.previous_dash_directory) -ne $meleeRoot){throw 'Accepted guarded Melee activation revision required'}
            foreach($method in @('Slelect Hit Montage','K2_ActivateAbility','MontageHit')){
                if(($entryProof.original_signatures.$method|ConvertTo-Json -Depth 30 -Compress) -ne ($proof.extra_signatures.$method|ConvertTo-Json -Depth 30 -Compress)){throw 'Melee entry changed accepted signatures'}
            }
            foreach($old in $auth.assets){
                $before=@($revision.previous_assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
                if($before.Count -ne 1 -or (Get-FileHash -LiteralPath $before[0].stage_backup).Hash -ne $old.sha256 -or
                    (Get-FileHash -LiteralPath $before[0].overlay_backup).Hash -ne $old.sha256){throw 'Melee helper-to-entry before provenance differs'}
            }
            $currentMelee=@($revision.assets);Add-JumpInput $entryPath;Add-JumpInput $entryReport
        }
        if($MeleeTraceAuthoringDirectory){
            $traceRoot=[IO.Path]::GetFullPath($MeleeTraceAuthoringDirectory)
            if(!$traceRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Melee trace proof must be workspace-owned'}
            $tracePath=Join-Path $traceRoot 'summary.json';$traceReport=Join-Path $traceRoot 'assets.json'
            $traceRevision=Get-Content -LiteralPath $tracePath -Raw|ConvertFrom-Json -Depth 100
            $traceProof=Get-Content -LiteralPath $traceReport -Raw|ConvertFrom-Json -Depth 100
            if($traceRevision.status -ne 'passed' -or $traceRevision.kind -ne 'meleetrace' -or $traceProof.status -ne 'passed' -or $traceProof.kind -ne 'meleetrace' -or
                !$traceProof.original_full_cdo_preserved -or !$traceProof.original_business_graphs_preserved_with_dispatch -or !$traceProof.original_trace_body_retained -or
                !$traceProof.python_trace_has_no_original_fallthrough -or !$traceProof.native_register_restore_passed -or !$traceProof.native_end_teardown_bypass -or
                $traceProof.native_end_transport_signature.owner -ne $proof.original_class -or $traceProof.native_trace_entry -ne 'UEPMeleeAuthorityTrace' -or
                ($traceProof.native_trace_signature.flags -band 0x40) -or @($traceProof.native_trace_signature.parameters).Count -ne 0 -or
                $traceProof.actual_registered_profile_method_counts.Python -ne 4 -or $traceProof.actual_registered_profile_method_counts.BlueprintFallback -ne 4 -or
                $traceProof.transport_nodes -ne 1 -or $traceProof.new_business_nodes -ne 0 -or @($traceProof.declared_dispatch_endpoints).Count -ne 2 -or
                $traceProof.whole_melee_trace_damage_business_migrated -or [IO.Path]::GetFullPath($traceRevision.previous_dash_directory) -ne $entryRoot){throw 'Accepted Melee authority dispatch revision required'}
            foreach($method in @('Slelect Hit Montage','K2_ActivateAbility','MontageHit','K2_OnEndAbility','UEPMeleeAuthorityTrace')){
                $expected=if($method -eq 'K2_OnEndAbility'){$entryProof.native_end_transport_signature}elseif($method -eq 'UEPMeleeAuthorityTrace'){$entryProof.native_trace_signature}else{$entryProof.original_signatures.$method}
                if(($traceProof.original_signatures.$method|ConvertTo-Json -Depth 30 -Compress) -ne ($expected|ConvertTo-Json -Depth 30 -Compress)){throw 'Melee trace changed accepted signature'}
            }
            foreach($old in $currentMelee){
                $before=@($traceRevision.previous_assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
                if($before.Count -ne 1 -or (Get-FileHash -LiteralPath $before[0].stage_backup).Hash -ne $old.sha256 -or
                    (Get-FileHash -LiteralPath $before[0].overlay_backup).Hash -ne $old.sha256){throw 'Melee entry-to-trace before provenance differs'}
                Add-JumpInput $before[0].stage_backup;Add-JumpInput $before[0].overlay_backup
            }
            $currentMelee=@($traceRevision.assets);Add-JumpInput $tracePath;Add-JumpInput $traceReport
        }
        foreach($asset in $currentMelee){
            if((Get-FileHash -LiteralPath $asset.stage).Hash -ne $asset.sha256 -or (Get-FileHash -LiteralPath $asset.overlay).Hash -ne $asset.sha256){throw 'Authored Melee asset bytes changed'}
            Add-JumpInput $asset.stage;Add-JumpInput $asset.overlay
        }
        if((Get-FileHash -LiteralPath $proof.caller_probe.asset).Hash -ne $proof.caller_probe.sha256){throw 'Melee native BP caller changed'}
        Add-JumpInput $proof.caller_probe.asset;Add-JumpInput $meleeSummary;Add-JumpInput $meleeReport
        foreach($entry in $proof.reference_hashes.PSObject.Properties){if((Get-FileHash -LiteralPath $entry.Name).Hash -ne $entry.Value){throw 'Official Melee reference changed'};Add-JumpInput $entry.Name}
        if($MeleeNetworkFixtureAuthoringDirectory){
            $fixtureRoot=[IO.Path]::GetFullPath($MeleeNetworkFixtureAuthoringDirectory)
            if(!$fixtureRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Melee fixture proof must be workspace-owned'}
            $fixtureSummary=Join-Path $fixtureRoot 'summary.json';$fixtureReport=Join-Path $fixtureRoot 'assets.json'
            $fixtureAuthor=Get-Content -LiteralPath $fixtureSummary -Raw|ConvertFrom-Json -Depth 80
            $fixture=Get-Content -LiteralPath $fixtureReport -Raw|ConvertFrom-Json -Depth 80
            $fixtureAsset=Join-Path $stage 'Content/UEPValidation/BP_MeleeNetworkFloor.uasset'
            if($fixtureAuthor.status -ne 'passed' -or $fixture.status -ne 'passed' -or $fixture.kind -ne 'meleetracenetworkfixture' -or
                !$fixture.stage_only -or $fixture.gameplay_business -or $fixture.runtime_acceptance -or !$fixture.native_replication_defaults -or
                !$fixture.native_component_archetype_preserved_for_clients -or ($fixture.extent -join ',') -ne '5000,5000,20' -or
                $fixture.native_object_type -ne 0 -or $fixture.asset -ne $fixtureAsset -or (Get-FileHash -LiteralPath $fixtureAsset).Hash -ne $fixture.sha256){throw 'Accepted native replicated Melee floor required'}
            Add-JumpInput $fixtureSummary;Add-JumpInput $fixtureReport;Add-JumpInput $fixtureAsset
        }
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
    if($MeleeHitMontage){$flag='-UEPMeleeHitMontageResult';$marker='UEP_MELEE_HIT_MONTAGE'}
    if($MeleeActivation){$flag='-UEPMeleeActivationResult';$marker='UEP_MELEE_ACTIVATION'}
    if($MeleeTrace){$flag='-UEPMeleeTraceResult';$marker='UEP_MELEE_TRACE'}
    if($GrenadeWidget){$flag='-UEPGrenadeWidgetResult';$marker='UEP_GRENADE_WIDGET'}
    if($GrenadeActivation){$flag='-UEPGrenadeActivationResult';$marker='UEP_GRENADE_ACTIVATION'}
    if($GrenadeVFX){$flag='-UEPGrenadeVFXResult';$marker='UEP_GRENADE_VFX'}
    if($GrenadeCleanup){$flag='-UEPGrenadeCleanupResult';$marker='UEP_GRENADE_CLEANUP'}
    if($GrenadeActions){$flag='-UEPGrenadeActionsResult';$marker='UEP_GRENADE_ACTIONS'}
    if($GrenadeBegin){$flag='-UEPGrenadeBeginResult';$marker='UEP_GRENADE_BEGIN'}
    if($GrenadeHit){$flag='-UEPGrenadeHitResult';$marker='UEP_GRENADE_HIT'}
    if($GrenadeDetonate){$flag='-UEPGrenadeDetonateResult';$marker='UEP_GRENADE_DETONATE'}
    if($NetShooterActor){$flag='-UEPNetShooterActorResult';$marker='UEP_NETSHOOTER_ACTOR'}
    if($NetShooterAbility){$flag='-UEPNetShooterAbilityResult';$marker='UEP_NETSHOOTER_ABILITY'}
    if($WeaponActorHelpers){$flag='-UEPWeaponActorHelpersResult';$marker='UEP_WEAPON_ACTOR_HELPERS'}
    if($WeaponActorFire){$flag='-UEPWeaponActorFireResult';$marker='UEP_WEAPON_ACTOR_FIRE'}
    if($WeaponActorBegin){$flag='-UEPWeaponActorBeginResult';$marker='UEP_WEAPON_ACTOR_BEGIN'}
    if($WeaponFireFX){$flag='-UEPWeaponFireFXResult';$marker='UEP_WEAPON_FIRE_FX'}
    if($Footstep){$flag='-UEPFootstepResult';$marker='UEP_FOOTSTEP'}
    if($CueWidgets){$flag='-UEPCueWidgetResult';$marker='UEP_CUE_WIDGET'}
    if($MessageWidgets){$flag='-UEPMessageWidgetResult';$marker='UEP_MESSAGE_WIDGET'}
    if($CharacterDamage){$flag='-UEPCharacterDamageResult';$marker='UEP_CHARACTER_DAMAGE'}
    if($HeroBurstCues){$flag='-UEPHeroBurstCueResult';$marker='UEP_HERO_BURST_CUE'}
    if($MacroClosure){$flag='-UEPMacroClosureResult';$marker='UEP_MACRO_CLOSURE'}
    if($ShooterEQS){$flag='-UEPShooterEQSResult';$marker='UEP_SHOOTER_EQS'}
    if($ShooterAI){$flag='-UEPShooterAIResult';$marker='UEP_SHOOTER_AI'}
    if($GamePhases){$flag='-UEPGamePhasesResult';$marker='UEP_GAME_PHASES'}
    if($EliminationScore){$flag='-UEPEliminationScoreResult';$marker='UEP_ELIMINATION_SCORE'}
    if($ControlPointWidgets){$flag='-UEPControlPointWidgetsResult';$marker='UEP_CONTROL_POINT_WIDGETS'}
    if($ScoreboardStyle){$flag='-UEPScoreboardStyleResult';$marker='UEP_SCOREBOARD_STYLE'}
    if($ScoreboardList){$flag='-UEPScoreboardListResult';$marker='UEP_SCOREBOARD_LIST'}
    if($ScoreboardRows){$flag='-UEPScoreboardRowsResult';$marker='UEP_SCOREBOARD_ROWS'}
    if($EliminationWidgets){$flag='-UEPEliminationWidgetsResult';$marker='UEP_ELIMINATION_WIDGETS'}
    if($AccoladeWidgets){$flag='-UEPAccoladeWidgetsResult';$marker='UEP_ACCOLADE_WIDGETS'}
    if($AccoladeRelay){$flag='-UEPAccoladeRelayResult';$marker='UEP_ACCOLADE_RELAY'}
    if($EliminationFeedRelay){$flag='-UEPEliminationFeedRelayResult';$marker='UEP_ELIMINATION_FEED_RELAY'}
    if($ControlPointFeedback){$flag='-UEPControlPointFeedbackResult';$marker='UEP_CONTROL_POINT_FEEDBACK'}
    if($ControlPointState){$flag='-UEPControlPointStateResult';$marker='UEP_CONTROL_POINT_STATE'}
    if($ControlPointHelpers){$flag='-UEPControlPointHelpersResult';$marker='UEP_CONTROL_POINT_HELPERS'}
    if($CPScoring){$flag='-UEPCPScoringResult';$marker='UEP_CP_SCORING'}
    if($TDMScoring){$flag='-UEPTDMScoringResult';$marker='UEP_TDM_SCORING'}
    if($ScoringBase){$flag='-UEPScoringBaseResult';$marker='UEP_SCORING_BASE'}
    if($PhysicsFields){$flag='-UEPPhysicsFieldResult';$marker='UEP_PHYSICS_FIELD'}
    if($SmallBurstCues){$flag='-UEPSmallBurstCueResult';$marker='UEP_SMALL_BURST_CUE'}
    if($SpawningCue){$flag='-UEPSpawningCueResult';$marker='UEP_SPAWNING_CUE'}
    if($TraversalCues){$flag='-UEPTraversalCueResult';$marker='UEP_TRAVERSAL_CUE'}
    if($WeaponFireCues){$flag='-UEPWeaponFireCuesResult';$marker='UEP_WEAPON_FIRE_CUES'}
    if($WeaponAudioMath){$flag='-UEPWeaponAudioMathResult';$marker='UEP_WEAPON_AUDIO_MATH'}
    if($WeaponAudioDispatch){$flag='-UEPWeaponAudioDispatchResult';$marker='UEP_WEAPON_AUDIO_DISPATCH'}
    if($WeaponAudioWhiz){$flag='-UEPWeaponAudioWhizResult';$marker='UEP_WEAPON_AUDIO_WHIZ'}
    if($WeaponAudioEarly){$flag='-UEPWeaponAudioEarlyResult';$marker='UEP_WEAPON_AUDIO_EARLY'}
    if($WeaponAudioCold){$flag='-UEPWeaponAudioColdResult';$marker='UEP_WEAPON_AUDIO_COLD'}
    if($WeaponAudioEffect){$flag='-UEPWeaponAudioEffectResult';$marker='UEP_WEAPON_AUDIO_EFFECT'}
    if($MusicControls){$flag='-UEPMusicControlsResult';$marker='UEP_MUSIC_CONTROLS'}
    if($MusicLifecycle){$flag='-UEPMusicLifecycleResult';$marker='UEP_MUSIC_LIFECYCLE'}
    if($MusicFamily){$flag='-UEPMusicFamilyResult';$marker='UEP_MUSIC_FAMILY'}
    if($WindSystem){$flag='-UEPWindSystemResult';$marker='UEP_WIND_SYSTEM'}
    if($GeneralAudio){$flag='-UEPGeneralAudioResult';$marker='UEP_GENERAL_AUDIO'}
    if($WeaponDecals){$flag='-UEPWeaponDecalsResult';$marker='UEP_WEAPON_DECALS'}
    if($WeaponImpacts){$flag='-UEPWeaponImpactsResult';$marker='UEP_WEAPON_IMPACTS'}
    if($WeaponAbilityFire){$flag='-UEPWeaponAbilityFireResult';$marker='UEP_WEAPON_ABILITY_FIRE'}
    if($DashLocalDirection){$flag='-UEPDashLocalDirectionResult';$marker='UEP_DASH_LOCAL_DIRECTION'}
    if($DashActivation){$flag='-UEPDashActivationResult';$marker='UEP_DASH_ACTIVATION'}
    if($DashTasks){$flag='-UEPDashTasksResult';$marker='UEP_DASH_TASKS'}
    if($DashTasksLifecycle){$flag='-UEPDashTasksLifecycleResult';$marker='UEP_DASH_TASKS_LIFECYCLE'}
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360',
        '-NoLoadingScreen','-ExecCmds=t.MaxFPS 60','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython','-NoDDCCleanup',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        "$flag=$output/jump.json","-abslog=$output/jump.log")
    if($ThreadedLoading){$arguments+=@('-AsyncLoadingThread')}
    if($WeaponAudioCold){$arguments+=@("-UEPAudioColdWeapon=$WeaponAudioColdWeapon")}
    if($WeaponAudioNetwork){$arguments+=@('-UEPWeaponAudioNetwork')}
    if($WeaponAudioEarlyOpenGeometry){$arguments+=@('-UEPWeaponAudioEarlyOpenGeometry')}
    if($WeaponAudioWhiz -and !$WeaponAudioWhizNoSound){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($WeaponAudioEffect){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($SmallBurstCues){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($AccoladeWidgets){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($ShooterEQS){$arguments+=@("-UEPShooterEQSProfile=$ShooterEQSProfile","-UEPShooterEQSMode=$ShooterEQSMode");if($ShooterEQSMode -eq 'cp'){$arguments[1]='/ShooterMaps/Maps/L_Convolution_Blockout?Experience=B_LyraShooterGame_ControlPoints?NumBots=3'}}
    if($ShooterAI){$arguments+=@("-UEPShooterAIProfile=$ShooterAIProfile","-UEPShooterAIMode=$ShooterAIMode");if($ShooterAIMode -eq 'cp'){$arguments[1]='/ShooterMaps/Maps/L_Convolution_Blockout?Experience=B_LyraShooterGame_ControlPoints?NumBots=3'}}
    if($GamePhases){$arguments+=@("-UEPGamePhasesProfile=$GamePhasesProfile")}
    if($EliminationScore){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($ControlPointWidgets){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($ControlPointFeedback){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($MusicControls){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($MusicLifecycle){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($MusicFamily){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($GeneralAudio){$arguments=@($arguments|Where-Object {$_ -ne '-NoSound'});$arguments+=@('-DeterministicAudio')}
    if($GrenadeFlightNetwork){$arguments+=@('-LogCmds=LogNetTraffic Log,LogRepTraffic Log,LogRep Verbose')}
    # Dedicated-server/NullRHI disables rendering; preserve the single common
    # argument initialization and add only this explicit server-only variant.
    if($GrenadeHeadless){$arguments+=@('-server','-NullRHI','-port=7794','-multihome=127.0.0.1','-UEPGrenadeHeadless')}
    if($PawnWireIdentity){$arguments+=@('-UEPRequireNetworkIdentity')}
    if($WeaponAbilityFireNetwork){$arguments+=@("-UEPWeaponFireNetworkWeapon=$WeaponFireNetworkWeapon")}
    if($LazyPawnLifecycle){$arguments+=@('-UEPLazyPawnLifecycle','-LogCmds=LogLyra Verbose')}
    if($JoinResetStress){$arguments+=@('-UEPJoinResetStress')}
    if($MeleeCharacterStartupProfile){$arguments+=@("-UEPReplicaCharacterStartupProfile=$MeleeCharacterStartupProfile",'-LogCmds=LogLyra Verbose')}
    if($MeleeWarmupJoin){$arguments+=@('-UEPReplicaWarmupJoin')}
    if($MeleeCharacterOriginalBeginPlay){$arguments+=@('-UEPReplicaCharacterOriginalBeginPlay')}
    if($MeleeCharacterOriginalSubset){$arguments+=@("-UEPReplicaCharacterOriginalSubset=$MeleeCharacterOriginalSubset")}
    if($AutoRespawnListeners){$arguments+=@('-UEPAutoRespawnListeners')}
    if($AutoRespawnEvents){$arguments+=@('-UEPAutoRespawnEvents')}
    if($AutoRespawnActivation){$arguments+=@('-UEPAutoRespawnActivation')}
    if($CharacterInventory){$arguments+=@('-UEPCharacterInventory')}
    if($CharacterLoadoutNatural){$arguments+=@('-UEPCharacterLoadoutNatural')}
    if($ControlPointWidgets){$arguments[1]='/ShooterMaps/Maps/L_Convolution_Blockout?Experience=B_LyraShooterGame_ControlPoints?NumBots=3'}
    if($ScoreboardStyle){$arguments+=@("-UEPScoreboardStyleMode=$ScoreboardStyleMode");if($ScoreboardStyleMode -eq 'cp'){$arguments[1]='/ShooterMaps/Maps/L_Convolution_Blockout?Experience=B_LyraShooterGame_ControlPoints?NumBots=3'}}
    if($ControlPointFeedback){$arguments[1]='/ShooterMaps/Maps/L_Convolution_Blockout?Experience=B_LyraShooterGame_ControlPoints?NumBots=3'}
    if($ControlPointState){$arguments[1]='/ShooterMaps/Maps/L_Convolution_Blockout?Experience=B_LyraShooterGame_ControlPoints?NumBots=3'}
    if($ControlPointHelpers){$arguments[1]='/ShooterMaps/Maps/L_Convolution_Blockout?Experience=B_LyraShooterGame_ControlPoints?NumBots=3'}
    if($CPScoring){$arguments[1]='/ShooterMaps/Maps/L_Convolution_Blockout?Experience=B_LyraShooterGame_ControlPoints?NumBots=3'}
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
            if($MeleeHitMontage){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPMeleeHitMontageResult=*'})}
            if($MeleeActivation){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPMeleeActivationResult=*'})}
            if($MeleeTrace){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPMeleeTraceResult=*'})}
            if($GrenadeWidget){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPGrenadeWidgetResult=*'})}
            if($GrenadeActivationNetwork){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPGrenadeActivationResult=*'})}
            if($GrenadeDetonateNetwork){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPGrenadeDetonateResult=*'})}
            if($WeaponAbilityFireNetwork){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPWeaponAbilityFireResult=*'})}
            if($NetShooterNetwork){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPNetShooterAbilityResult=*'})}
            if($DashLocalDirection){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPDashLocalDirectionResult=*'})}
            if($DashActivation){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPDashActivationResult=*'})}
            if($DashTasks){$peerArguments=@($peerArguments|Where-Object {$_ -notlike '-UEPDashTasksResult=*'})}
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
            if($MeleeHitMontage){$resultFlag='-UEPMeleeHitMontageNetworkResult'}
            if($MeleeActivation){$resultFlag='-UEPMeleeActivationNetworkResult'}
            if($MeleeTrace){$resultFlag='-UEPMeleeTraceNetworkResult'}
            if($GrenadeWidget){$resultFlag='-UEPGrenadeWidgetNetworkResult'}
            if($GrenadeActivationNetwork){$resultFlag='-UEPGrenadeActivationNetworkResult'}
            if($GrenadeDetonateNetwork){$resultFlag='-UEPGrenadeDetonateNetworkResult'}
            if($GrenadeFlightNetwork){$resultFlag='-UEPGrenadeFlightNetworkResult'}
            if($WeaponAbilityFireNetwork){$resultFlag='-UEPWeaponAbilityFireNetworkResult'}
            if($WeaponFireCueNetwork){$resultFlag='-UEPWeaponFireCueNetworkResult'}
            if($NotificationRelaysNetwork){$resultFlag='-UEPNotificationRelaysNetworkResult'}
            if($NetShooterNetwork){$resultFlag='-UEPNetShooterNetworkResult'}
            if($NetShooterImpactNetwork){$resultFlag='-UEPNetShooterImpactNetworkResult'}
            if($DashRPCInput){$resultFlag='-UEPDashRPCInputNetworkResult'}
            if($DashLocalDirection){$resultFlag='-UEPDashLocalDirectionNetworkResult'}
            if($DashActivation){$resultFlag='-UEPDashActivationNetworkResult'}
            if($DashTasks){$resultFlag='-UEPDashTasksNetworkResult'}
            if($DashTasksNetworkLifecycle){$resultFlag='-UEPDashTasksNetworkLifecycleResult'}
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
                        Write-UEPJumpExitToken -Path "$output/$peer-exited.json" -Token @{peer=$peer;run_id=$run;exit_code=0} -OutputRoot $output
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
            if($MeleeHitMontage){$pass=if($peer -eq 'server'){'UEP_MELEE_HIT_MONTAGE_NETWORK_PASSED'}else{'UEP_MELEE_HIT_MONTAGE_SHUTDOWN_PASSED'}}
            if($MeleeActivation){$pass=if($peer -eq 'server'){'UEP_MELEE_ACTIVATION_NETWORK_PASSED'}else{'UEP_MELEE_ACTIVATION_SHUTDOWN_PASSED'}}
            if($MeleeTrace){$pass=if($peer -eq 'server'){'UEP_MELEE_TRACE_NETWORK_PASSED'}else{'UEP_MELEE_TRACE_SHUTDOWN_PASSED'}}
            if($GrenadeWidget){$pass=if($peer -eq 'server'){'UEP_GRENADE_WIDGET_NETWORK_PASSED'}else{'UEP_GRENADE_WIDGET_NETWORK_SHUTDOWN_PASSED'}}
            if($GrenadeActivationNetwork){$pass=if($peer -eq 'server'){'UEP_GRENADE_ACTIVATION_NETWORK_PASSED'}else{'UEP_GRENADE_ACTIVATION_NETWORK_SHUTDOWN_PASSED'}}
            if($GrenadeDetonateNetwork){$pass=if($peer -eq 'server'){'UEP_GRENADE_DETONATE_NETWORK_PASSED'}else{'UEP_GRENADE_DETONATE_NETWORK_SHUTDOWN_PASSED'}}
            if($GrenadeFlightNetwork){$pass=if($peer -eq 'server'){'UEP_GRENADE_FLIGHT_NETWORK_PASSED'}else{'UEP_GRENADE_FLIGHT_NETWORK_SHUTDOWN_PASSED'}}
            if($WeaponAbilityFireNetwork){$pass=if($peer -eq 'server'){'UEP_WEAPON_FIRE_NETWORK_PASSED'}else{'UEP_WEAPON_FIRE_NETWORK_SHUTDOWN_PASSED'}}
            if($WeaponFireCueNetwork){$pass=if($peer -eq 'server'){'UEP_WEAPON_CUE_NETWORK_PASSED'}else{'UEP_WEAPON_CUE_NETWORK_SHUTDOWN_PASSED'}}
            if($NotificationRelaysNetwork){$pass=if($peer -eq 'server'){'UEP_NOTIFICATION_RELAYS_NETWORK_PASSED'}else{'UEP_NOTIFICATION_RELAYS_SHUTDOWN_PASSED'}}
            if($NetShooterNetwork){$pass=if($peer -eq 'server'){'UEP_NETSHOOTER_NETWORK_PASSED'}else{'UEP_NETSHOOTER_NETWORK_SHUTDOWN_PASSED'}}
            if($NetShooterImpactNetwork){
                $pass=if($peer -eq 'server'){'UEP_NETSHOOTER_IMPACT_PASSED'}else{'UEP_NETSHOOTER_IMPACT_SHUTDOWN_PASSED'}
                $baselinePython=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
                $baselineArgs=@('-B','-m','uep_lyra_weapons.netshooter_actor_log_contract','--log',"$output/$peer.log",'--clean-log',"$output/$peer-baseline-audited.log",'--result',"$output/$peer-template-baseline.json")
                if(!$summary.Contains('source_template_baseline_audits')){$summary['source_template_baseline_audits']=@{}}
                $summary.source_template_baseline_audits[$peer]=Invoke-UEPValidationProcess $baselinePython $baselineArgs (Join-Path $overlay 'Content/Scripts') (Join-Path $output "$peer-template-audit") 'Original NetShooter peer template baseline audit' 30
                $log=Get-Content -LiteralPath "$output/$peer-baseline-audited.log" -Raw
            }
            if($DashRPCInput){$pass=if($peer -eq 'server'){'UEP_DASH_RPC_INPUT_NETWORK_PASSED'}else{'UEP_DASH_RPC_INPUT_SHUTDOWN_PASSED'}}
            if($DashLocalDirection){$pass=if($peer -eq 'server'){'UEP_DASH_LOCAL_DIRECTION_NETWORK_PASSED'}else{'UEP_DASH_LOCAL_DIRECTION_SHUTDOWN_PASSED'}}
            if($DashActivation){$pass=if($peer -eq 'server'){'UEP_DASH_ACTIVATION_NETWORK_PASSED'}else{'UEP_DASH_ACTIVATION_SHUTDOWN_PASSED'}}
            if($DashTasks){$pass=if($peer -eq 'server'){'UEP_DASH_TASKS_NETWORK_PASSED'}else{'UEP_DASH_TASKS_SHUTDOWN_PASSED'}}
            if($DashTasksNetworkLifecycle){$pass=if($peer -eq 'server'){'UEP_DASH_TASKS_NETWORK_LIFECYCLE_NETWORK_PASSED'}else{'UEP_DASH_TASKS_NETWORK_LIFECYCLE_SHUTDOWN_PASSED'}}
            Assert-UEPFocusedLog $log $pass -RequirePythonExit
            if($GrenadeActivationNetwork -and $log -match '(?im)ImportText.*Missing opening parenthesis'){throw 'Grenade network native parameter default import failed'}
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
        if($MeleeHitMontage){$module='uep_lyra_abilities.melee_hit_montage_contract'}
        if($DashLocalDirection){$module='uep_lyra_abilities.dash_local_direction_contract'}
        if($MeleeActivation){$module='uep_lyra_abilities.melee_activation_network_contract'}
        if($MeleeTrace){$module='uep_lyra_abilities.melee_trace_network_contract'}
        if($GrenadeWidget){$module='uep_lyra_abilities.grenade_widget_network_contract'}
        if($GrenadeActivationNetwork){$module='uep_lyra_abilities.grenade_activation_network_contract'}
        if($GrenadeDetonateNetwork){$module='uep_lyra_weapons.grenade_detonate_network_contract'}
        if($GrenadeFlightNetwork){$module='uep_lyra_weapons.grenade_flight_network_contract'}
        if($WeaponAbilityFireNetwork){$module='uep_lyra_weapons.weapon_ability_fire_network_contract'}
        if($WeaponFireCueNetwork){$module='uep_lyra_weapons.weapon_fire_cue_network_contract'}
        if($NotificationRelaysNetwork){$module='uep_lyra_hud.notification_relays_network_contract'}
        if($WeaponAudioNetwork){$module='uep_lyra_weapons.weapon_audio_network_contract'}
        if($NetShooterNetwork){$module='uep_lyra_weapons.netshooter_network_contract'}
        if($NetShooterImpactNetwork){$module='uep_lyra_weapons.netshooter_impact_network_contract'}
        if($DashActivation){$module='uep_lyra_abilities.dash_activation_contract'}
        if($DashTasks){$module='uep_lyra_abilities.dash_tasks_contract'}
        $gateArgs=@('--directory',$output)
        if($DashTasksNetworkLifecycle){$module='uep_lyra_abilities.dash_tasks_network_lifecycle_contract'}
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
        if($MeleeHitMontage){$module='uep_lyra_abilities.melee_hit_montage_contract'}
        if($DashLocalDirection){$module='uep_lyra_abilities.dash_local_direction_contract'}
        if($DashActivation){$module='uep_lyra_abilities.dash_activation_contract'}
        if($DashTasks){$module='uep_lyra_abilities.dash_tasks_contract'}
        if($MeleeActivation){$module='uep_lyra_abilities.melee_activation_contract'}
        if($MeleeTrace){$module='uep_lyra_abilities.melee_trace_contract'}
        if($GrenadeWidget){$module='uep_lyra_abilities.grenade_widget_contract'}
        if($GrenadeActivation){$module='uep_lyra_abilities.grenade_activation_contract'}
        if($GrenadeVFX){$module='uep_lyra_weapons.grenade_vfx_contract'}
        if($GrenadeCleanup){$module='uep_lyra_weapons.grenade_cleanup_contract'}
        if($GrenadeActions){$module='uep_lyra_weapons.grenade_actions_contract'}
        if($GrenadeBegin){$module='uep_lyra_weapons.grenade_begin_contract'}
        if($GrenadeHit){$module='uep_lyra_weapons.grenade_hit_contract'}
        if($GrenadeDetonate){$module='uep_lyra_weapons.grenade_detonate_contract'}
        if($NetShooterActor){$module='uep_lyra_weapons.netshooter_actor_contract'}
        if($NetShooterAbility){$module='uep_lyra_weapons.netshooter_ability_contract'}
        if($WeaponActorHelpers){$module='uep_lyra_weapons.weapon_actor_helpers_contract'}
        if($WeaponActorFire){$module='uep_lyra_weapons.weapon_actor_fire_contract'}
        if($WeaponActorBegin){$module='uep_lyra_weapons.weapon_actor_begin_contract'}
        if($WeaponFireFX){$module='uep_lyra_weapons.weapon_fire_fx_contract'}
        if($Footstep){$module='uep_lyra_weapons.footstep_contract'}
        if($CueWidgets){$module='uep_lyra_hud.cue_widget_contract'}
        if($MessageWidgets){$module='uep_lyra_hud.message_widget_contract'}
        if($CharacterDamage){$module='uep_lyra_weapons.character_damage_contract'}
        if($HeroBurstCues){$module='uep_lyra_weapons.hero_burst_cue_contract'}
        if($MacroClosure){$module='uep_lyra_weapons.macro_closure_contract'}
        if($ShooterEQS){$module='uep_lyra_world.shooter_eqs_contract'}
        if($ShooterAI){$module='uep_lyra_world.shooter_ai_contract'}
        if($GamePhases){$module='uep_lyra_weapons.game_phases_contract'}
        if($EliminationScore){$module='uep_lyra_hud.elimination_score_contract'}
        if($ControlPointWidgets){$module='uep_lyra_hud.control_point_widgets_contract'}
        if($ScoreboardStyle){$module='uep_lyra_hud.scoreboard_style_contract'}
        if($ScoreboardList){$module='uep_lyra_hud.scoreboard_list_contract'}
        if($ScoreboardRows){$module='uep_lyra_hud.scoreboard_rows_contract'}
        if($EliminationWidgets){$module='uep_lyra_hud.elimination_widgets_contract'}
        if($AccoladeWidgets){$module='uep_lyra_hud.accolade_widgets_contract'}
        if($AccoladeRelay){$module='uep_lyra_hud.accolade_relay_contract'}
        if($EliminationFeedRelay){$module='uep_lyra_hud.elimination_feed_relay_contract'}
        if($ControlPointFeedback){$module='uep_lyra_world.control_point_feedback_contract'}
        if($ControlPointState){$module='uep_lyra_world.control_point_state_contract'}
        if($ControlPointHelpers){$module='uep_lyra_world.control_point_helpers_contract'}
        if($CPScoring){$module='uep_lyra_weapons.cp_scoring_contract'}
        if($TDMScoring){$module='uep_lyra_weapons.tdm_scoring_contract'}
        if($ScoringBase){$module='uep_lyra_weapons.scoring_base_contract'}
        if($PhysicsFields){$module='uep_lyra_weapons.physics_field_contract'}
        if($SmallBurstCues){$module='uep_lyra_weapons.small_burst_cue_contract'}
        if($SpawningCue){$module='uep_lyra_weapons.spawning_cue_contract'}
        if($TraversalCues){$module='uep_lyra_weapons.traversal_cue_contract'}
        if($WeaponFireCues){$module='uep_lyra_weapons.weapon_fire_cue_contract'}
        if($WeaponAudioMath){$module='uep_lyra_weapons.weapon_audio_math_contract'}
        if($WeaponAudioDispatch){$module='uep_lyra_weapons.weapon_audio_dispatch_contract'}
        if($WeaponAudioWhiz){$module='uep_lyra_weapons.weapon_audio_whiz_contract'}
        if($WeaponAudioEarly){$module='uep_lyra_weapons.weapon_audio_early_contract'}
        if($WeaponAudioCold){$module='uep_lyra_weapons.weapon_audio_cold_contract'}
        if($WeaponAudioEffect){$module='uep_lyra_weapons.weapon_audio_effect_contract'}
        if($MusicControls){$module='uep_lyra_audio.music_manager_contract'}
        if($MusicLifecycle){$module='uep_lyra_audio.music_lifecycle_contract'}
        if($MusicFamily){$module='uep_lyra_audio.music_family_contract'}
        if($WindSystem){$module='uep_lyra_audio.wind_system_contract'}
        if($GeneralAudio){$module='uep_lyra_audio.general_audio_contract'}
        if($WeaponDecals){$module='uep_lyra_weapons.weapon_decals_contract'}
        if($WeaponImpacts){$module='uep_lyra_weapons.weapon_impacts_contract'}
        if($WeaponAbilityFire){$module='uep_lyra_weapons.weapon_ability_fire_contract'}
        $gateArgs=@('--report',"$output/jump.json")
        if($GrenadeHeadless){$gateArgs+=@('--headless')}
        if($DashTasksLifecycle){$module='uep_lyra_abilities.dash_tasks_lifecycle_contract'}
        if($CharacterInventory -and $AutoRespawnReset){$gateArgs+=@('--reset')}
        if($CharacterLifecycle -and $AutoRespawnReset){$gateArgs+=@('--reset')}
        if($WeaponActorFire -and ($WeaponFireFXAuthoringDirectory -or $WeaponDecalsAuthoringDirectory -or $WeaponImpactsAuthoringDirectory)){
            $fxIntegration=Get-Content -LiteralPath "$output/jump.json" -Raw|ConvertFrom-Json -Depth 80
            if(!$fxIntegration.world_owned_test_components_destroyed){throw 'Parent Fire left world-owned test Niagara components'}
            $expectedFX=@()
            if($WeaponFireFXAuthoringDirectory){$expectedFX+='/Game/Effects/Blueprints/B_WeaponFire.B_WeaponFire_C'}
            if($WeaponDecalsAuthoringDirectory){$expectedFX+='/Game/Effects/Blueprints/B_WeaponDecals.B_WeaponDecals_C'}
            if($WeaponImpactsAuthoringDirectory){$expectedFX+='/Game/Effects/Blueprints/B_WeaponImpacts.B_WeaponImpacts_C'}
            foreach($expected in $expectedFX){
                $entries=@($fxIntegration.cases|ForEach-Object {$_.events}|Where-Object {$_.class -eq $expected})
                if($expected -notin $fxIntegration.declared_fx_observed -or $entries.Count -ne 24 -or
                    @($entries|Where-Object {!$_.production_handler_used -or $_.production_profile -ne 'Python'}).Count){throw 'Parent Fire did not use/restorably observe the current production FX Profile'}
            }
        }
        $log=Get-Content -LiteralPath "$output/jump.log" -Raw
        if($EliminationScore -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'TDM score/countdown audio requires the native offline renderer'}
        if($ControlPointWidgets -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'CP widget countdown requires the actual offline native audio renderer'}
        if($ControlPointFeedback -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'Point feedback requires the actual offline native audio renderer'}
        if($AccoladeWidgets -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'Accolade widgets require the native offline audio renderer'}
        if($SmallBurstCues -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'Small Burst Cue audio requires the actual offline native renderer'}
        if($SmallBurstCues -and ([regex]::Matches($log,'LogBlueprintUserMessages:.*NOT VALID')).Count -ne 2){throw 'Both original and Python pickup invalid-FX messages required'}
        if($WeaponAudioEffect -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'Actual effect initialization requires the offline native audio renderer'}
        if($MusicControls -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'Music controls require the actual offline native audio renderer'}
        if($MusicLifecycle -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'Music lifecycle requires the actual offline native audio renderer'}
        if($MusicFamily -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'Music family requires the actual offline native audio renderer'}
        if($GeneralAudio -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'GeneralAudio requires the actual offline native audio renderer'}
        if($WeaponAudioWhiz -and !$WeaponAudioWhizNoSound -and $log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'Actual offline native audio renderer was not selected'}
        if($NetShooterActor){
            $baselinePython=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
            $baselineArgs=@('-B','-m','uep_lyra_weapons.netshooter_actor_log_contract','--log',"$output/jump.log",'--clean-log',"$output/jump-baseline-audited.log",'--result',"$output/source-template-baseline.json")
            $summary['source_template_baseline_audit']=Invoke-UEPValidationProcess $baselinePython $baselineArgs (Join-Path $overlay 'Content/Scripts') (Join-Path $output 'source-template-audit') 'Original NetShooter template baseline audit' 30
            $log=Get-Content -LiteralPath "$output/jump-baseline-audited.log" -Raw
        }
        Assert-UEPFocusedLog $log ($marker+'_SHUTDOWN_PASSED') -RequirePythonExit
        if($GrenadeActivation -and $log -match '(?im)ImportText.*Missing opening parenthesis'){throw 'Grenade native parameter default import failed'}
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
