#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet('Python','BlueprintFallback')][string]$Profile='Python',
    [ValidateSet('A','B0')][string]$AttackerPeer='A',
    [ValidateRange(1024,65535)][int]$ServerPort=18812)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh network evidence required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
$socket=[Net.Sockets.UdpClient]::new();try{$socket.Client.ExclusiveAddressUse=$true;$socket.Client.Bind([Net.IPEndPoint]::new([Net.IPAddress]::Loopback,$ServerPort))}finally{$socket.Dispose()}
New-Item -ItemType Directory -Path $output|Out-Null
$run=[guid]::NewGuid().ToString('N');$handles=@{}
$summary=[ordered]@{schema_version=1;status='failed';profile=$Profile;attacker_peer=$AttackerPeer;run_id=$run;runtime_scope='Dedicated Editor server and two actual Editor clients; selected owner weapon input score/postgame/kill-feed pipeline';full_acceptance=$false;network_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();processes=@{};external_gate=$null;error=$null}
function Add-LethalHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
function Read-LethalReport([string]$Path){
    $reader=$null
    try{$reader=[IO.StreamReader]::new([IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete)));return ($reader.ReadToEnd()|ConvertFrom-Json -Depth 70)}
    catch [IO.IOException]{return $null}
    finally{if($null -ne $reader){$reader.Dispose()}}
}
try{
    $syntaxFiles=@((Join-Path $repo 'Demos/UEPLyraIntegration/Overlay/Content/Scripts/uep_lyra_weapons/weapon_lethal_network_validation.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Overlay/Content/Scripts/uep_lyra_weapons/weapon_lethal_network_contract.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Overlay/Content/Scripts/uep_lyra_hud/startup.py'))
    $syntaxCode='import ast,sys;from pathlib import Path;[ast.parse(Path(p).read_text(encoding="utf-8-sig"),filename=p) for p in sys.argv[1:]]'
    $null=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe') (@('-B','-c',$syntaxCode)+$syntaxFiles) $repo (Join-Path $output 'syntax-preflight') 'Native network script syntax preflight' 30
    $engineModule=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules';$build=(Get-Content -LiteralPath $engineModule -Raw|ConvertFrom-Json).BuildId;Add-LethalHash $engineModule
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){$file=Join-Path $stage $relative;if((Get-Content -LiteralPath $file -Raw|ConvertFrom-Json).BuildId -ne $build){throw 'Native network BuildId mismatch'};Add-LethalHash $file}
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},@{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){$copy=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName));if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Native source mismatch'};Add-LethalHash $file.FullName;Add-LethalHash $copy}
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($file in Get-ChildItem -LiteralPath "$overlay/Content/Scripts" -Recurse -File -Filter '*.py'){$copy=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName));New-Item -ItemType Directory -Path (Split-Path $copy -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $copy -Force;Add-LethalHash $file.FullName;Add-LethalHash $copy}
    foreach($file in Get-ChildItem -LiteralPath $overlay -Recurse -File -Filter '*.uasset'){$copy=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName));if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Accepted overlay asset differs from stage'};Add-LethalHash $file.FullName;Add-LethalHash $copy}
    foreach($spec in @(@{root='20261020-tdm-scoring/Assets02TypedSubsystem';kind='tdmscoring';methods=16},@{root='20261020-gameplay-relays/Assets01Elimination';kind='eliminationfeedrelay';methods=1},@{root='20261020-gameplay-relays/Assets02Accolade';kind='accoladerelay';methods=1})){
        $proofRoot=Join-Path $repo ('.build/LyraValidation/BlueprintPython/'+$spec.root);$proof=Get-Content -LiteralPath "$proofRoot/assets.json" -Raw|ConvertFrom-Json -Depth 80;$author=Get-Content -LiteralPath "$proofRoot/summary.json" -Raw|ConvertFrom-Json -Depth 80
        if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $proof.kind -ne $spec.kind -or $proof.actual_registered_profile_method_counts.Python -ne $spec.methods -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne $spec.methods){throw 'Accepted scoring and relay authoring proof required'}
        foreach($asset in $author.assets){if((Get-FileHash -LiteralPath $asset.stage).Hash -ne $asset.sha256 -or (Get-FileHash -LiteralPath $asset.overlay).Hash -ne $asset.sha256){throw 'Original accepted scoring/relay asset changed'}}
        if($spec.kind -ne 'tdmscoring'){if(!$proof.fixture.stage_only -or (Get-FileHash -LiteralPath $proof.fixture.asset).Hash -ne $proof.fixture.sha256){throw 'Typed native notification observer changed'};Add-LethalHash $proof.fixture.asset}
        Add-LethalHash "$proofRoot/assets.json";Add-LethalHash "$proofRoot/summary.json"
    }
    foreach($file in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $stage 'Binaries/Win64/UnrealEditor-LyraGame.dll'),(Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'),(Join-Path $stage 'Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll'))){Add-LethalHash $file}
    foreach($peer in @('server','A','B0')){
        $url=if($peer -eq 'server'){'/ShooterMaps/Maps/L_Expanse?NumBots=3'}else{"127.0.0.1:$ServerPort"}
        $arguments=@($project,$url,'-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup','-UEPRequireNetworkIdentity','-UEPAutoRespawnListeners','-UEPAutoRespawnEvents','-UEPAutoRespawnActivation',"-UEPTDMNetworkPeer=$peer","-UEPTDMNetworkRun=$run","-UEPTDMNetworkProfile=$Profile","-UEPWeaponLethalAttacker=$AttackerPeer","-UEPWeaponLethalNetworkResult=$output/$peer.json","-abslog=$output/$peer.log","-UserDir=$output/$peer-user/")
        if($peer -eq 'server'){$arguments+=@('-server','-NullRHI',"-port=$ServerPort",'-multihome=127.0.0.1','-ExecCmds=t.MaxFPS 60');$exe=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe'}else{$arguments+=@('-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360','-ExecCmds=t.MaxFPS 30,sg.ShadowQuality 0,sg.GlobalIlluminationQuality 0,sg.ReflectionQuality 0,r.Streaming.PoolSize 256');$exe=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe'}
        $handles[$peer]=Start-UEPValidationProcess $exe $arguments $stage (Join-Path $output $peer) $peer
        if($peer -eq 'server'){
            $listen=[Diagnostics.Stopwatch]::StartNew();while($true){if($handles[$peer].process.HasExited){throw 'Native authority exited before listen'};if((Test-Path -LiteralPath "$output/server.log") -and (Get-Content -LiteralPath "$output/server.log" -Raw) -match "listening on port $ServerPort"){break};if($listen.Elapsed.TotalSeconds -gt 90){throw 'Native authority listen timed out'};Start-Sleep -Milliseconds 200}
        }
    }
    $timer=[Diagnostics.Stopwatch]::StartNew()
    while($true){
        if(@(@('server','A','B0')|Where-Object {Test-Path -LiteralPath "$output/ready-$_.json"}).Count -eq 3){break}
        foreach($peer in @('server','A','B0')){if($handles[$peer].process.HasExited){throw "Native lethal peer $peer exited early"};$report=Read-LethalReport "$output/$peer.json";if($null -ne $report -and $report.status -eq 'failed'){throw "Native lethal peer $peer failed"}}
        if($timer.Elapsed.TotalSeconds -gt 420){throw 'Native lethal network handshake timed out'};Start-Sleep -Milliseconds 200
    }
    foreach($peer in @('server','A','B0')){if((Get-Content -LiteralPath "$output/ready-$peer.json" -Raw|ConvertFrom-Json).run_id -ne $run){throw 'Foreign native lethal barrier'}}
    @{run_id=$run}|ConvertTo-Json|Set-Content -LiteralPath "$output/release.tmp" -Encoding utf8;Move-Item -LiteralPath "$output/release.tmp" -Destination "$output/release.json"
    foreach($peer in @('A','B0','server')){
        if($peer -eq 'server'){
            if($handles.server.process.HasExited){throw 'Authority exited before both client process exits were released'}
            @{run_id=$run;client_exit_codes=@{A=$summary.processes.A.exit_code;B0=$summary.processes.B0.exit_code}}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath "$output/server-release.tmp" -Encoding utf8
            Move-Item -LiteralPath "$output/server-release.tmp" -Destination "$output/server-release.json"
        }
        if(!$handles[$peer].process.WaitForExit(60000)){throw 'Native lethal shutdown timed out'};$summary.processes[$peer]=Complete-UEPValidationProcess $handles[$peer];if($summary.processes[$peer].exit_code -ne 0){throw 'Native lethal process failed'}
        $report=Get-Content -LiteralPath "$output/$peer.json" -Raw|ConvertFrom-Json -Depth 80;if($report.status -ne 'passed'){throw "Native lethal $peer report failed"}
        $log=Get-Content -LiteralPath "$output/$peer.log" -Raw;Assert-UEPFocusedLog $log 'UEP_WEAPON_LETHAL_NETWORK_DIFFERENTIAL_PASSED';Assert-UEPFocusedLog $log 'UEP_WEAPON_LETHAL_NETWORK_SHUTDOWN_PASSED' -RequirePythonExit
    }
    $summary.external_gate=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe') @('-B','-m','uep_lyra_weapons.weapon_lethal_network_contract','--directory',$output) (Join-Path $overlay 'Content/Scripts') (Join-Path $output 'independent-gate') 'Three-peer native lethal scoring/notification gate' 30
    foreach($frozen in $summary.hashes){if((Get-FileHash -LiteralPath $frozen.path).Hash -ne $frozen.sha256){throw 'Frozen network input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{foreach($peer in @($handles.Keys)){$handle=$handles[$peer];Stop-UEPValidationProcess $handle;$summary.processes[$peer]=Complete-UEPValidationProcess $handle;$handle.process.Dispose()};$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Native TDM lethal $Profile`: $($summary.status); $output"
