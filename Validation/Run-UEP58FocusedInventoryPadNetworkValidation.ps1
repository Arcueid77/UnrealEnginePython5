#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$AssetAuthoringDirectory,
      [ValidateRange(1024,65535)][int]$ServerPort=18584,[switch]$GrantGE,[switch]$Launcher,[switch]$Spawner,[string]$AssetAuditDirectory,[switch]$Teleporter,[switch]$ActionTouch,[switch]$HealAbility)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(@(@($GrantGE,$Launcher,$Spawner,$Teleporter,$ActionTouch,$HealAbility)|Where-Object {$_}).Count -gt 1){throw 'Choose one native world-actor/UI network lane'}
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
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^UnrealEditor(-Cmd)?\.exe$' -and
    ($_.CommandLine -replace '/','\') -like ('*'+($project -replace '/','\')+'*')}).Count){throw 'Matching stage already running'}
$authorPath=Join-Path $AssetAuthoringDirectory 'summary.json'
$author=Get-Content -LiteralPath $authorPath -Raw|ConvertFrom-Json -Depth 40
$expectedAssets=if($Launcher){4}elseif($GrantGE -or $Teleporter -or $HealAbility){2}else{3}
if($author.status -ne 'passed' -or $author.runtime_acceptance -or @($author.assets).Count -ne $expectedAssets){throw 'Accepted world-pad authoring required'}
$socket=[Net.Sockets.UdpClient]::new()
try{$socket.Client.ExclusiveAddressUse=$true;$socket.Client.Bind([Net.IPEndPoint]::new([Net.IPAddress]::Loopback,$ServerPort))}finally{$socket.Dispose()}
New-Item -ItemType Directory -Path $output|Out-Null
$runId=[guid]::NewGuid().ToString('N')
$handles=@{}
$summary=[ordered]@{schema_version=1;status='failed';run_id=$runId;client_count=2;cases=$(if($ActionTouch){8}elseif($Spawner){36}elseif($Launcher -or $Teleporter -or $HealAbility){12}elseif($GrantGE){4}else{16});network_acceptance=$false
    kind=$(if($HealAbility){'heal-equipment-ability'}elseif($ActionTouch){'action-touch-local-ui'}elseif($Teleporter){'teleporter'}elseif($Spawner){'spawner'}elseif($Launcher){'launcher'}elseif($GrantGE){'grant-ge'}else{'inventory'})
    full_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();processes=@();error=$null}
function Add-InventoryNetHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
function Read-InventoryNetJSON([string]$Path){
    for($attempt=0;$attempt -lt 10;$attempt++){
        $stream=$null;$reader=$null
        try{
            $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
            $reader=[IO.StreamReader]::new($stream)
            return ($reader.ReadToEnd()|ConvertFrom-Json -Depth 90)
        }catch [IO.IOException]{if($attempt -eq 9){throw};Start-Sleep -Milliseconds 5}
        finally{if($null -ne $reader){$reader.Dispose()}elseif($null -ne $stream){$stream.Dispose()}}
    }
}
try{
    $engineId=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    $pluginId=(Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    if($engineId -ne $pluginId){throw 'Editor BuildId mismatch'}
    $summary.editor_build_id=$engineId
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source differs'}
        Add-InventoryNetHash $source.FullName;Add-InventoryNetHash $target
    }
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-InventoryNetHash $source.FullName;Add-InventoryNetHash $target
    }
    foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){
        if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Inventory asset differs'}
        Add-InventoryNetHash $path
    }}
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    $names=if($HealAbility){@('GA_HealPickup')}elseif($ActionTouch){@('W_ActionTouchButton','W_ActionTouchButton_MobileOnly')}elseif($Teleporter){@('B_Teleport')}elseif($Spawner){@('B_WeaponSpawner','B_AbilitySpawner')}elseif($Launcher){@('B_Launcher','B_Launcher_Push','B_Launcher_Up')}elseif($GrantGE){@('B_GrantAbilityPad_ApplyGE')}else{@('B_GrantInventory_Pad','B_GrantInventoryPad_WithMesh')}
    foreach($name in $names){
        $relative=if($HealAbility){"Plugins\GameFeatures\ShooterCore\Content\Items\HealthPickup_Unused\$name.uasset"}elseif($ActionTouch){"Content\UI\Hud\$name.uasset"}else{"Plugins\GameFeatures\ShooterCore\Content\Blueprint\$name.uasset"}
        Add-InventoryNetHash (Join-Path (Split-Path $marker.source -Parent) $relative)
    }
    if($Spawner){
        $auditPath=Join-Path $AssetAuditDirectory 'launcher.json';$audit=Get-Content -LiteralPath $auditPath -Raw|ConvertFrom-Json -Depth 60
        if($audit.status -ne 'passed' -or @($audit.pickups).Count -ne 5){throw 'Original spawner data audit required'}
        foreach($hash in $audit.reference_hashes.PSObject.Properties){
            if($hash.Name -like '*\Blueprint\B_*Spawner.uasset' -and $hash.Name.StartsWith($stage,[StringComparison]::OrdinalIgnoreCase)){continue}
            if((Get-FileHash -LiteralPath $hash.Name).Hash -ne $hash.Value){throw 'Spawner original reference/data changed'}
            Add-InventoryNetHash $hash.Name
        }
        Add-InventoryNetHash $auditPath
        foreach($root in @($stage,(Split-Path $marker.source -Parent))){Add-InventoryNetHash (Join-Path $root 'Plugins\GameFeatures\ShooterMaps\Content\Maps\L_Expanse.umap')}
    }
    $validator=Join-Path $repo $(if($HealAbility){'Demos\UEPLyraIntegration\Tools\validate_heal_ability_network_reports.py'}elseif($ActionTouch){'Demos\UEPLyraIntegration\Tools\validate_action_touch_network_reports.py'}elseif($Teleporter){'Demos\UEPLyraIntegration\Tools\validate_teleporter_network_reports.py'}elseif($Spawner){'Demos\UEPLyraIntegration\Tools\validate_spawner_network_reports.py'}elseif($Launcher){'Demos\UEPLyraIntegration\Tools\validate_launcher_network_reports.py'}elseif($GrantGE){'Demos\UEPLyraIntegration\Tools\validate_grant_ge_network_reports.py'}else{'Demos\UEPLyraIntegration\Tools\validate_inventory_pad_network_reports.py'})
    $scenarioFlag=if($HealAbility){'-UEPHealAbilityNetwork'}elseif($ActionTouch){'-UEPActionTouchNetwork'}elseif($Teleporter){'-UEPTeleporterNetwork'}elseif($Spawner){'-UEPSpawnerNetwork'}elseif($Launcher){'-UEPLauncherNetwork'}elseif($GrantGE){'-UEPGrantGENetwork'}else{'-UEPInventoryPadNetwork'}
    $successMarker=if($HealAbility){'UEP_HEAL_NETWORK_PASSED'}elseif($ActionTouch){'UEP_ACTION_TOUCH_NETWORK_PASSED'}elseif($Teleporter){'UEP_TELEPORTER_NETWORK_PASSED'}elseif($Spawner){'UEP_SPAWNER_NETWORK_PASSED'}elseif($Launcher){'UEP_LAUNCHER_NETWORK_PASSED'}elseif($GrantGE){'UEP_GRANT_GE_NETWORK_PASSED'}else{'UEP_INVENTORY_NETWORK_PASSED'}
    foreach($path in @($PSCommandPath,$authorPath,$validator,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),
        (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))){Add-InventoryNetHash $path}
    $budget='t.MaxFPS 30,sg.ViewDistanceQuality 0,sg.AntiAliasingQuality 0,sg.ShadowQuality 0,sg.GlobalIlluminationQuality 0,sg.ReflectionQuality 0,sg.PostProcessQuality 0,sg.TextureQuality 0,sg.EffectsQuality 0,sg.FoliageQuality 0,r.Streaming.PoolSize 256'
    $summary.client_render_budget=$budget
    $common=@('-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        '-Multiprocess','-UEPLyraMultiClient','-UEPLyraHUDSlice',$scenarioFlag,"-UEPLyraNetRun=$runId","-UEPLyraNetDirectory=$output")
    function Start-InventoryNetPeer([string]$Peer){
        if($handles.ContainsKey($Peer)){throw 'Duplicate inventory process launch'}
        $url=if($Peer -eq 'server'){'/ShooterMaps/Maps/L_Expanse?NumBots=3'}else{"127.0.0.1:$ServerPort"}
        $arguments=@($project,$url)+$common+@("-UEPLyraNetPeer=$Peer","-abslog=$output\$Peer.log")
        if($Peer -eq 'server'){$arguments+=@('-server','-NullRHI',"-port=$ServerPort",'-multihome=127.0.0.1','-ExecCmds=t.MaxFPS 60')}
        else{$arguments+=@('-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360',"-ExecCmds=$budget")}
        $handles[$Peer]=Start-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output $Peer) $Peer
        Write-Host "Inventory peer $Peer started, PID $($handles[$Peer].process.Id)"
    }
    Start-InventoryNetPeer 'server'
    $timer=[Diagnostics.Stopwatch]::StartNew()
    while($true){
        if(!$handles.ContainsKey('A') -and (Test-Path -LiteralPath (Join-Path $output 'server.log'))){
            $log=Get-Content -LiteralPath (Join-Path $output 'server.log') -Raw
            if($log -match "listening on port $ServerPort" -and $log -match 'UEP_LYRA_BRIDGE_ATTACHED'){Start-InventoryNetPeer 'A'}
        }
        if($handles.ContainsKey('A') -and !$handles.ContainsKey('B0') -and (Test-Path -LiteralPath (Join-Path $output 'status\A.json'))){
            $status=Read-InventoryNetJSON (Join-Path $output 'status\A.json')
            if($status.run_id -ne $runId){throw 'Foreign inventory peer status'}
            if($status.ready){Start-InventoryNetPeer 'B0'}
        }
        foreach($peer in @($handles.Keys)){
            if($handles[$peer].process.HasExited){throw "Inventory peer $peer exited early"}
            $file=Join-Path $output "$peer.json"
            if(Test-Path -LiteralPath $file){$report=Read-InventoryNetJSON $file
                if($report.status -eq 'failed'){throw "Inventory peer $peer failed: $($report.error)"}}
        }
        if(@(@('server','A','B0')|Where-Object {Test-Path -LiteralPath (Join-Path $output "ready-$_.json")}).Count -eq 3){break}
        if($timer.Elapsed.TotalSeconds -gt 650){throw 'Inventory network timed out'}
        Start-Sleep -Milliseconds 250
    }
    foreach($peer in @('server','A','B0')){
        if((Read-InventoryNetJSON (Join-Path $output "ready-$peer.json")).run_id -ne $runId){throw 'Foreign inventory readiness'}
    }
    @{run_id=$runId}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $output 'release.json.tmp') -Encoding utf8
    Move-Item -LiteralPath (Join-Path $output 'release.json.tmp') -Destination (Join-Path $output 'release.json')
    foreach($peer in @('server','A','B0')){
        if(!$handles[$peer].process.WaitForExit(45000)){throw "Inventory peer $peer shutdown timed out"}
        $result=Complete-UEPValidationProcess $handles[$peer]
        $summary.processes+=$result
        if($result.exit_code -ne 0){throw "Inventory peer $peer exited $($result.exit_code)"}
        $log=Get-Content -LiteralPath (Join-Path $output "$peer.log") -Raw
        Assert-UEPFocusedLog $log $successMarker
        Assert-UEPFocusedLog $log 'UEP_LYRA_HUD_SHUTDOWN_PASSED' -RequirePythonExit
        Write-Host "Inventory peer $peer exited cleanly"
    }
    $python=Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\Python3\Win64\python.exe'
    $summary.validation=Invoke-UEPValidationProcess $python @('-B',$validator,$output) $repo (Join-Path $output 'reports') 'Inventory network report validation' 30
    $summary.protocol=Get-Content -LiteralPath (Join-Path $output 'reports-stdout.log') -Raw|ConvertFrom-Json
    $nativeProof=if($HealAbility){$summary.protocol.native_heal_equipment_owner_prediction_and_replication}elseif($ActionTouch){$summary.protocol.native_action_touch_two_owner_local_message_lifetime}elseif($Teleporter){$summary.protocol.native_teleporter_real_owner_movement_replication}elseif($Spawner){$summary.protocol.native_spawner_level_actor_inventory_health_cooldown_replication}elseif($Launcher){$summary.protocol.native_launcher_real_owner_physics_replication}elseif($GrantGE){$summary.protocol.native_grant_ge_health_and_default_cooldown}else{$summary.protocol.native_inventory_equipment_fire_replication}
    if($summary.protocol.status -ne 'passed' -or !$nativeProof){throw 'World-pad report gate incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Inventory network input/reference changed'}}
    $summary.status='passed';$summary.network_acceptance=$true
}catch{$summary.error=$_.ToString();throw}
finally{
    foreach($handle in $handles.Values){Stop-UEPValidationProcess $handle;$handle.process.Dispose()}
    $summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8
}
Write-Host "Inventory two-client native acceptance: $($summary.status); $output"
