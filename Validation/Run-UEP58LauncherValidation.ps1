#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,
      [ValidateSet('Audit','Author','Runtime')][string]$Mode='Audit',[string]$AssetAuthoringDirectory,[switch]$Spawner,[string]$AssetAuditDirectory,[switch]$Teleporter,[switch]$ActionTouch,[switch]$TouchRegions,[switch]$Click,[switch]$UnusedHeal)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(@(@($Spawner,$Teleporter,$ActionTouch,$TouchRegions,$UnusedHeal)|Where-Object {$_}).Count -gt 1){throw 'Choose one actor/widget batch'}
if($TouchRegions -and $Mode -ne 'Audit'){throw 'Touch regions are a read-only scope decision, not a behavior implementation'}
if($Click -and (!$ActionTouch -or $Mode -ne 'Runtime')){throw 'Click requires the action-touch runtime lane'}
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked workspace stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Use fresh launcher evidence directory'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*')}).Count){throw 'Matching stage already running'}
$overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
$toolsRoot=Join-Path $repo 'Demos\UEPLyraIntegration\Tools'
$marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
$referenceRoot=Split-Path $marker.source -Parent
$relativeRoot=if($UnusedHeal){'Plugins\GameFeatures\ShooterCore\Content\Items\HealthPickup_Unused'}elseif($ActionTouch -or $TouchRegions){'Content\UI\Hud'}else{'Plugins\GameFeatures\ShooterCore\Content\Blueprint'}
$names=@(if($UnusedHeal){'GA_HealPickup'}elseif($TouchRegions){'W_TouchRegion_Base';'W_TouchRegion_Right';'W_TouchRegion_Left'}elseif($ActionTouch){'W_ActionTouchButton';'W_ActionTouchButton_MobileOnly'}elseif($Teleporter){'B_Teleport'}elseif($Spawner){'B_WeaponSpawner';'B_AbilitySpawner'}else{'B_Launcher';'B_Launcher_Push';'B_Launcher_Up'})
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';mode=$Mode;runtime_acceptance=$false;full_acceptance=$false
    network_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false
    hashes=@();assets=@();backups=@();process=$null;error=$null}
function Add-LauncherHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $engineId=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries\Win64\UnrealEditor.modules','Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules','Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor.modules')){
        $path=Join-Path $stage $relative
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $engineId){throw 'Editor BuildId mismatch'}
        Add-LauncherHash $path
    }
    $summary.editor_build_id=$engineId
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins\UnrealEnginePython\Source')},
        @{source=(Join-Path $repo 'Demos\UEPLyraIntegration\Plugins\UEPLyraBridge\Source');target=(Join-Path $stage 'Plugins\UEPLyraBridge\Source')})){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source mismatch'}
            Add-LauncherHash $source.FullName;Add-LauncherHash $target
        }
    }
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-LauncherHash $source.FullName;Add-LauncherHash $target
    }
    foreach($name in $names){
        $relative=if($TouchRegions -and $name -eq 'W_TouchRegion_Left'){'Plugins\GameFeatures\ShooterCore\Content\Input\W_TouchRegion_Left.uasset'}else{Join-Path $relativeRoot "$name.uasset"}
        $reference=Join-Path $referenceRoot $relative;$target=Join-Path $stage $relative
        Add-LauncherHash $reference
        if($Mode -eq 'Author'){
            if((Get-FileHash -LiteralPath $reference).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Fresh original launcher inputs required'}
            $backup=Join-Path $output "before-$name.uasset";Copy-Item -LiteralPath $target -Destination $backup
            $summary.backups+=@{source=$target;copy=$backup;sha256=(Get-FileHash -LiteralPath $backup).Hash}
        }else{Add-LauncherHash $target}
    }
    if($Mode -eq 'Runtime'){
        $authorPath=Join-Path $AssetAuthoringDirectory 'summary.json';$author=Get-Content -LiteralPath $authorPath -Raw|ConvertFrom-Json -Depth 40
        $expectedAssets=if($ActionTouch -or $Spawner){3}elseif($Teleporter -or $UnusedHeal){2}else{4}
        if($author.status -ne 'passed' -or $author.runtime_acceptance -or $author.mode -ne 'Author' -or @($author.assets).Count -ne $expectedAssets){throw 'Accepted actor authoring required'}
        foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Launcher authored asset changed'}
            Add-LauncherHash $path
        }}
        Add-LauncherHash $authorPath
        if($Spawner){
            $auditPath=Join-Path $AssetAuditDirectory 'launcher.json'
            $audit=Get-Content -LiteralPath $auditPath -Raw|ConvertFrom-Json -Depth 60
            if($audit.status -ne 'passed' -or @($audit.pickups).Count -ne 5){throw 'Original spawner/pickup audit required'}
            foreach($hash in $audit.reference_hashes.PSObject.Properties){
                # The two BP copies intentionally changed during authoring;
                # original references and all pickup data must remain equal.
                if($hash.Name -like '*\Blueprint\B_*Spawner.uasset' -and $hash.Name.StartsWith($stage,[StringComparison]::OrdinalIgnoreCase)){continue}
                if((Get-FileHash -LiteralPath $hash.Name).Hash -ne $hash.Value){throw 'Spawner audit input/reference changed'}
                Add-LauncherHash $hash.Name
            }
            Add-LauncherHash $auditPath
            foreach($root in @($overlay,$stage)){Add-LauncherHash (Join-Path $root 'Content\UEPInterop\BP_UEPGameplayMessages.uasset')}
        }
        if($ActionTouch){
            $auditPath=Join-Path $AssetAuditDirectory 'launcher.json'
            $audit=Get-Content -LiteralPath $auditPath -Raw|ConvertFrom-Json -Depth 70
            $authored=Get-Content -LiteralPath (Join-Path $AssetAuthoringDirectory 'launcher.json') -Raw|ConvertFrom-Json -Depth 70
            if($audit.status -ne 'passed' -or !$audit.fire_button_is_composite_not_subclass -or !$authored.native_tick_metadata_preserved){throw 'Original touch scheduling/composition proof required'}
            foreach($asset in $audit.assets){
                $metadata=$authored.original_tick_metadata.PSObject.Properties[$asset.asset].Value
                if($metadata.TickFrequency -ne $asset.defaults.TickFrequency -or $metadata.bHasScriptImplementedTick -ne $asset.defaults.bHasScriptImplementedTick){throw 'Original touch Tick metadata differs'}
            }
            foreach($hash in $audit.reference_hashes.PSObject.Properties){
                if($hash.Name.StartsWith($stage,[StringComparison]::OrdinalIgnoreCase) -and $hash.Name -like '*\UI\Hud\W_ActionTouchButton*.uasset'){continue}
                if((Get-FileHash -LiteralPath $hash.Name).Hash -ne $hash.Value){throw 'Original touch reference/composite changed'}
                Add-LauncherHash $hash.Name
            }
            Add-LauncherHash $auditPath;Add-LauncherHash (Join-Path $AssetAuthoringDirectory 'launcher.json')
        }
    }
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),
        (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'),
        (Join-Path $stage 'Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor-UEPLyraBridge.dll'))){Add-LauncherHash $path}
    $common=@('-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',"-abslog=$output\launcher.log")
    if($Mode -in @('Audit','Author')){
        $script=Join-Path $toolsRoot $(if($UnusedHeal -and $Mode -eq 'Audit'){'audit_unused_heal.py'}elseif($UnusedHeal){'generate_heal_ability_mixin_assets.py'}elseif($TouchRegions){'audit_touch_regions.py'}elseif($ActionTouch -and $Mode -eq 'Audit'){'audit_action_touch.py'}elseif($ActionTouch){'generate_action_touch_mixin_assets.py'}elseif($Teleporter -and $Mode -eq 'Audit'){'audit_teleporter.py'}elseif($Teleporter){'generate_teleporter_mixin_assets.py'}elseif($Spawner -and $Mode -eq 'Audit'){'audit_spawners.py'}elseif($Spawner){'generate_spawner_mixin_assets.py'}elseif($Mode -eq 'Audit'){'audit_launchers.py'}else{'generate_launcher_mixin_assets.py'})
        Add-LauncherHash $script;Add-LauncherHash (Join-Path $toolsRoot 'stage_safety.py')
        if($Mode -eq 'Author'){Add-LauncherHash (Join-Path $toolsRoot 'mixin_graph_gates.py')}
        if(($ActionTouch -or $UnusedHeal) -and $Mode -eq 'Author'){Add-LauncherHash (Join-Path $toolsRoot 'message_payload_graphs.py')}
        if($TouchRegions){Add-LauncherHash (Join-Path $toolsRoot 'mixin_graph_gates.py')}
        $resultFlag=if($UnusedHeal -and $Mode -eq 'Audit'){'-UEPUnusedHealAuditResult'}elseif($UnusedHeal){'-UEPGenerateHealAbilityResult'}elseif($TouchRegions){'-UEPTouchRegionsAuditResult'}elseif($ActionTouch -and $Mode -eq 'Audit'){'-UEPActionTouchAuditResult'}elseif($ActionTouch){'-UEPGenerateActionTouchResult'}elseif($Teleporter -and $Mode -eq 'Audit'){'-UEPTeleporterAuditResult'}elseif($Teleporter){'-UEPGenerateTeleporterResult'}elseif($Spawner -and $Mode -eq 'Audit'){'-UEPSpawnerAuditResult'}elseif($Spawner){'-UEPGenerateSpawnerResult'}elseif($Mode -eq 'Audit'){'-UEPLauncherAuditResult'}else{'-UEPGenerateLauncherResult'}
        $stageFlag=if($UnusedHeal){'-UEPUnusedHealStageRoot'}elseif($TouchRegions){'-UEPTouchRegionsStageRoot'}elseif($ActionTouch){'-UEPActionTouchStageRoot'}elseif($Teleporter){'-UEPTeleporterStageRoot'}elseif($Spawner){'-UEPSpawnerStageRoot'}else{'-UEPLauncherStageRoot'}
        $arguments=@($project,'-run=Py',$script,'-NullRHI',"$stageFlag=$stage","$resultFlag=$output\launcher.json")+$common
        $executable=Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
        $successMarker=if($UnusedHeal -and $Mode -eq 'Audit'){'UEP_UNUSED_HEAL_AUDIT_PASSED'}elseif($UnusedHeal){'UEP_HEAL_ABILITY_ASSETS_PASSED'}elseif($TouchRegions){'UEP_TOUCH_REGIONS_AUDIT_PASSED'}elseif($ActionTouch -and $Mode -eq 'Audit'){'UEP_ACTION_TOUCH_AUDIT_PASSED'}elseif($ActionTouch){'UEP_ACTION_TOUCH_ASSETS_PASSED'}elseif($Teleporter -and $Mode -eq 'Audit'){'UEP_TELEPORTER_AUDIT_PASSED'}elseif($Teleporter){'UEP_TELEPORTER_ASSETS_PASSED'}elseif($Spawner -and $Mode -eq 'Audit'){'UEP_SPAWNER_AUDIT_PASSED'}elseif($Spawner){'UEP_SPAWNER_ASSETS_PASSED'}elseif($Mode -eq 'Audit'){'UEP_LAUNCHER_AUDIT_PASSED'}else{'UEP_LAUNCHER_ASSETS_PASSED'}
    }else{
        $runtimeFlag=if($UnusedHeal){'-UEPHealAbilityResult'}elseif($Click){'-UEPActionTouchClickResult'}elseif($ActionTouch){'-UEPActionTouchResult'}elseif($Teleporter){'-UEPTeleporterResult'}elseif($Spawner){'-UEPSpawnerResult'}else{'-UEPLauncherResult'}
        $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360',
            '-NoLoadingScreen','-ExecCmds=t.MaxFPS 60',"$runtimeFlag=$output\launcher.json")+$common
        $executable=Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe'
        $runtimeMarker=if($UnusedHeal){'UEP_HEAL_ABILITY'}elseif($Click){'UEP_ACTION_TOUCH_CLICK'}elseif($ActionTouch){'UEP_ACTION_TOUCH'}elseif($Teleporter){'UEP_TELEPORTER'}elseif($Spawner){'UEP_SPAWNER'}else{'UEP_LAUNCHER'};$successMarker=$runtimeMarker+'_SHUTDOWN_PASSED'
    }
    $summary.process=Invoke-UEPValidationProcess $executable $arguments $stage (Join-Path $output 'launcher') "Launcher $Mode" 300
    $report=Get-Content -LiteralPath (Join-Path $output 'launcher.json') -Raw|ConvertFrom-Json -Depth 90
    if($report.status -ne 'passed'){throw 'Launcher report failed'}
    if($Mode -eq 'Audit'){
        if(@($report.assets).Count -ne $names.Count -or $report.runtime_acceptance){throw 'Incomplete read-only actor audit'}
    }elseif($Mode -eq 'Author'){
        $expectedGates=if($ActionTouch -or $UnusedHeal){0}elseif($Teleporter){5}elseif($Spawner){8}else{7};$expectedGraphs=if($UnusedHeal){1}elseif($ActionTouch -or $Teleporter){5}elseif($Spawner){6}else{7}
        if($report.runtime_acceptance -or !$report.class_preserved -or !$report.single_parent_interface_set -or
           !$report.original_blocks_retained -or $report.gate_count -ne $expectedGates -or @($report.original_graphs).Count -ne $expectedGraphs){throw 'Incomplete actor authoring'}
        if($Spawner -and (!$report.native_curve_preserved -or !$report.original_failure_rpc_transport_retained -or $report.reload_interface_adapter_nodes -ne 4)){throw 'Incomplete spawner transport/curve proof'}
        if($Teleporter -and (!$report.original_replication_flag_preserved -or !$report.original_signatures_preserved)){throw 'Incomplete teleporter transport proof'}
        if($ActionTouch -and (!$report.direct_function_mixin -or !$report.original_async_proxy_exposed_for_owned_cleanup -or !$report.typed_payload_vm_transport -or !$report.native_tick_metadata_preserved)){throw 'Incomplete action-touch transport/lifecycle proof'}
        if($UnusedHeal -and (!$report.direct_function_mixin -or !$report.original_montage_effect_instancing_network_preserved -or !$report.original_task_exposed_for_observation -or $report.native_end_lifecycle_adapter_nodes -ne 4 -or !$report.original_end_heal_unmixed_forwarder)){throw 'Incomplete heal ability transport/default proof'}
    }else{
        $python=Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\Python3\Win64\python.exe'
        $contract=Join-Path $overlay $(if($UnusedHeal){'Content\Scripts\uep_lyra_world\heal_ability_contract.py'}elseif($Click){'Content\Scripts\uep_lyra_hud\action_touch_click_contract.py'}elseif($ActionTouch){'Content\Scripts\uep_lyra_hud\action_touch_contract.py'}elseif($Teleporter){'Content\Scripts\uep_lyra_world\teleporter_contract.py'}elseif($Spawner){'Content\Scripts\uep_lyra_world\spawner_contract.py'}else{'Content\Scripts\uep_lyra_world\launcher_contract.py'})
        $null=Invoke-UEPValidationProcess $python @('-B',$contract,'--report',(Join-Path $output 'launcher.json')) $repo (Join-Path $output 'report-gate') 'Launcher report gate' 30
        $summary.runtime_acceptance=$true
    }
    $log=Get-Content -LiteralPath (Join-Path $output 'launcher.log') -Raw
    if($Mode -eq 'Runtime'){
        Assert-UEPFocusedLog $log $successMarker -RequirePythonExit
        if($log -notmatch ('(?s)'+$runtimeMarker+'_DIFFERENTIAL_PASSED.*Goodbye Python.*'+$runtimeMarker+'_SHUTDOWN_PASSED.*Log file closed')){throw 'Actor runtime exit ordering incomplete'}
    }else{
        Assert-UEPFocusedLog $log $successMarker
        if($log -notmatch ('(?s)'+$successMarker+'.*Goodbye Python.*Log file closed')){throw 'Launcher commandlet exit ordering incomplete'}
    }
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Launcher input/reference changed'}}
    if($Mode -eq 'Author'){
        $setAsset=if($UnusedHeal){'Content\UEPMixins\DA_HealAbilityMixin.uasset'}elseif($ActionTouch){'Content\UEPMixins\DA_ActionTouchMixin.uasset'}elseif($Teleporter){'Content\UEPMixins\DA_TeleporterMixin.uasset'}elseif($Spawner){'Content\UEPMixins\DA_SpawnerMixin.uasset'}else{'Content\UEPMixins\DA_LauncherMixin.uasset'}
        $outputs=@($names|ForEach-Object {Join-Path $relativeRoot "$_.uasset"})+@($setAsset)
        foreach($relative in $outputs){
            $from=Join-Path $stage $relative;$to=Join-Path $overlay $relative
            New-Item -ItemType Directory -Path (Split-Path $to -Parent) -Force|Out-Null
            Copy-Item -LiteralPath $from -Destination $to -Force
            $hash=(Get-FileHash -LiteralPath $from).Hash
            if((Get-FileHash -LiteralPath $to).Hash -ne $hash){throw 'Launcher canonical copy mismatch'}
            $summary.assets+=@{stage=$from;overlay=$to;sha256=$hash}
        }
    }
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Launcher $Mode validation: $($summary.status); $output"
