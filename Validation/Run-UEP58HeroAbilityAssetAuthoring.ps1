#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,
      [Parameter(Mandatory=$true)][ValidateSet('quickslot','death','autoreload','heroheal','dropweapon','reloadmagazine','weaponinstance','spawneffect','devicecolor','widgetheld')][string]$Kind)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
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
    if($Kind -eq 'devicecolor'){$relative='Plugins/GameFeatures/ShooterCore/Content/Game/B_TeamColor_DeviceProperty.uasset'}
    if($Kind -eq 'widgetheld'){$relative='Plugins/GameFeatures/ShooterCore/Content/Input/Abilities/GAB_ShowWidget_WhileInputHeld.uasset'}
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
    if($Kind -eq 'devicecolor'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_device_color_assets.py')}
    if($Kind -eq 'widgetheld'){Add-HeroHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_widget_held_assets.py')}
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',
        "-UEPHeroAbilityStageRoot=$stage","-UEPHeroAbilityKind=$Kind","-UEPHeroAbilityAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Retained hero ability Interface authoring' 240
    $report=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 80
    $expectedEndNodes=if($Kind -in @('weaponinstance','devicecolor')){0}else{4}
    if($report.status -ne 'passed' -or !$report.original_class_defaults_signature_graphs_preserved -or $report.native_end_adapter_nodes -ne $expectedEndNodes -or
       @($report.assets).Count -ne 2 -or $report.runtime_acceptance -or $report.kind -ne $Kind){throw 'Hero ability authoring proof incomplete'}
    if($Kind -eq 'widgetheld' -and (!$report.original_full_cdo_preserved -or !$report.native_children_unchanged -or $report.soft_class_path_transport_nodes -ne 4 -or $report.native_state_teardown_guard_nodes -ne 4)){
        throw 'Held-widget original CDO/children/typed soft-class transport proof incomplete'
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
