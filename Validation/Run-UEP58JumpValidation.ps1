#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,
      [Parameter(Mandatory=$true)][string]$AssetAuthoringDirectory,[switch]$WidgetLifecycle,[switch]$Network,[switch]$Quickslot,[switch]$Death,[switch]$ThreadedLoading,[switch]$Cosmetics,[switch]$AutoReload,[switch]$HeroHeal,[switch]$ADS,[switch]$DropWeapon,[switch]$ReloadMagazine,
      [switch]$WeaponInstance,[switch]$SpawnEffect,[switch]$DeviceColor,[switch]$Emote,[switch]$WidgetHeld,[switch]$EquipmentGC,[switch]$EquipmentDeath,[switch]$EquipmentIntegration,[switch]$EquipmentBlueprintFallback,[string]$EquipmentAuthoringDirectory,
      [string]$AbilityWidgetFamilyRevisionDirectory,
      [ValidateSet('tdm','cp')][string]$WidgetHeldMode='tdm',
      [ValidateRange(1024,65535)][int]$ServerPort=7794,
      [ValidateSet('pistol','rifle','shotgun','netshooter')][string]$ReloadWeapon='pistol')
# Only existing binaries and already authored disposable assets. No build/cook.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
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
    if(!$WeaponInstance -and !$SpawnEffect -and !$DeviceColor -and !$Emote -and !$WidgetHeld){
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
    if(!$preserved){throw 'Original native ability signature/default/graph proof missing'}
    foreach($entry in $authored.reference_hashes.PSObject.Properties){
        if((Get-FileHash -LiteralPath $entry.Name).Hash -ne $entry.Value){throw 'Official reference changed'}
        Add-JumpInput $entry.Name
    }
    Add-JumpInput $assetReport
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
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360',
        '-NoLoadingScreen','-ExecCmds=t.MaxFPS 60','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython','-NoDDCCleanup',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        "$flag=$output/jump.json","-abslog=$output/jump.log")
    if($ThreadedLoading){$arguments+=@('-AsyncLoadingThread')}
    if($WidgetHeld){
        $arguments+=@("-UEPWidgetHeldTarget=$WidgetHeldMode")
        if($WidgetHeldMode -eq 'cp'){$arguments[1]='/ShooterMaps/Maps/L_Convolution_Blockout?Experience=B_LyraShooterGame_ControlPoints?NumBots=3'}
    }
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
            Assert-UEPFocusedLog $log $pass -RequirePythonExit
            if($WidgetHeld -and $log -match '(?im)Accessed None|Accessed array.*out of bounds'){throw 'Held-widget native BP runtime warning indicates invalid UI context'}
            if($log -notmatch ('(?s)Goodbye Python.*'+$pass+'.*Log file closed')){throw 'Native Jump network shutdown ordering failed'}
        }
        $module=if($ReloadMagazine){'uep_lyra_abilities.reload_magazine_network_contract'}elseif($DropWeapon){'uep_lyra_abilities.drop_weapon_network_contract'}elseif($ADS){'uep_lyra_abilities.ads_network_contract'}elseif($HeroHeal){'uep_lyra_abilities.hero_heal_network_contract'}elseif($AutoReload){'uep_lyra_abilities.autoreload_network_contract'}elseif($Cosmetics){'uep_lyra_characters.cosmetic_network_contract'}elseif($Quickslot){'uep_lyra_abilities.quickslot_network_contract'}else{'uep_lyra_abilities.jump_network_contract'}
        if($EquipmentIntegration){$module='uep_lyra_weapons.weapon_instance_network_contract'}
        if($SpawnEffect){$module='uep_lyra_abilities.spawn_effect_network_contract'}
        if($Emote){$module='uep_lyra_abilities.emote_network_contract'}
        if($WidgetHeld){$module='uep_lyra_abilities.widget_held_network_contract'}
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
        $gateArgs=@('--report',"$output/jump.json")
        $log=Get-Content -LiteralPath "$output/jump.log" -Raw
        Assert-UEPFocusedLog $log ($marker+'_SHUTDOWN_PASSED') -RequirePythonExit
        if($WidgetHeld -and $log -match '(?im)Accessed None|Accessed array.*out of bounds'){throw 'Held-widget native BP runtime warning indicates invalid UI context'}
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
