#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplay/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$BuildEvidenceDirectory,
    [Parameter(Mandatory=$true)][string]$AssetEvidenceDirectory,
    [ValidateRange(1024,65535)][int]$ServerPort=18814,
    [switch]$ValidateTeam,
    [string]$TeamAssetEvidenceDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {throw 'Owned native stage and fresh network output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count) {throw 'Another native lane is active'}
$socket=[Net.Sockets.UdpClient]::new();try {$socket.Client.ExclusiveAddressUse=$true;$socket.Client.Bind([Net.IPEndPoint]::new([Net.IPAddress]::Loopback,$ServerPort))} finally {$socket.Dispose()}
$build=Get-Content -LiteralPath "$BuildEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 24
$assets=Get-Content -LiteralPath "$AssetEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 24
if($build.status -ne 'built_requires_native_acceptance' -or $null -ne $build.error -or $assets.status -ne 'passed' -or $assets.assets.Count -ne 7) {throw 'Successful build and processor asset family required'}
foreach($row in $build.products) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Compiled native module changed'}}
foreach($row in $assets.assets) {if((Get-FileHash -LiteralPath (Join-Path $stage $row.relative)).Hash -ne $row.sha256) {throw 'Authored native asset changed'}}
if($ValidateTeam) {
    $teamAssets=Get-Content -LiteralPath "$TeamAssetEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 24
    if($teamAssets.status -ne 'passed' -or $teamAssets.assets.Count -ne 3) {throw 'Accepted team asset family required'}
    foreach($row in $teamAssets.assets) {if((Get-FileHash -LiteralPath (Join-Path $stage $row.relative)).Hash -ne $row.sha256) {throw 'Authored team asset changed'}}
}
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';batch='CPP01';actual_native_damage_and_network=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();profiles=@{};error=$null}
if($ValidateTeam) {$summary.batch='CPP02'}
$python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe';$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay';$scripts=Join-Path $overlay 'Content/Scripts';$handles=@{}
function Add-NativeMessageHash([string]$Path) {$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
function Read-NativeMessageReport([string]$Path) {
    $value=& $python -B -X utf8 -c 'import sys,json;from pathlib import Path;sys.path.insert(0,sys.argv[1]);from uep_lyra_network_io import read_json;print(json.dumps(read_json(Path(sys.argv[2]))))' $scripts $Path
    if($LASTEXITCODE -ne 0) {throw 'Shared network JSON read failed'}
    return ($value|ConvertFrom-Json -Depth 70)
}
function Write-NativeMessageToken([string]$Path,[hashtable]$Value) {
    & $python -B -X utf8 -c 'import sys,json;from pathlib import Path;sys.path.insert(0,sys.argv[1]);from uep_lyra_network_io import atomic_write;atomic_write(Path(sys.argv[2]),json.loads(sys.argv[3]))' $scripts $Path ($Value|ConvertTo-Json -Depth 8 -Compress)
    if($LASTEXITCODE -ne 0) {throw 'Atomic network token write failed'}
}
try {
    foreach($file in Get-ChildItem -LiteralPath $scripts -Recurse -File -Filter '*.py') {
        $relative=[IO.Path]::GetRelativePath($overlay,$file.FullName);$copy=Join-Path $stage $relative;$archive=Join-Path "$output/Inputs/Overlay" $relative
        foreach($path in @($copy,$archive)) {New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $path -Force;Add-NativeMessageHash $path}
        Add-NativeMessageHash $file.FullName
    }
    foreach($file in Get-ChildItem -LiteralPath $overlay -Recurse -File -Filter '*.uasset') {
        $copy=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash) {throw 'Accepted overlay asset differs from native stage'}
        Add-NativeMessageHash $file.FullName;Add-NativeMessageHash $copy
    }
    foreach($relative in @('Binaries/Win64/UnrealEditor-LyraGame.dll','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll','Plugins/GameFeatures/ShooterCore/Binaries/Win64/UnrealEditor-ShooterCoreRuntime.dll','Content/UEPValidation/BP_EliminationFeedProbe.uasset','Content/UEPValidation/BP_AccoladeRelayProbe.uasset')) {Add-NativeMessageHash (Join-Path $stage $relative)}
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'))) {Copy-Item -LiteralPath $path -Destination "$output/Inputs";Add-NativeMessageHash $path}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    foreach($profile in @('NativeFallback','Python')) {
        $dir=Join-Path $output $profile;New-Item -ItemType Directory -Path $dir|Out-Null
        $run=[guid]::NewGuid().ToString('N');$handles=@{};$case=[ordered]@{status='failed';run_id=$run;processes=@{};error=$null};$summary.profiles[$profile]=$case
        try {
            foreach($peer in @('server','A','B0')) {
                $url=if($peer -eq 'server') {'/ShooterMaps/Maps/L_Expanse?NumBots=9'} else {"127.0.0.1:$ServerPort"}
                $arguments=@($StageProject,$url,'-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython',
                    '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',
                    '-UEPRequireNetworkIdentity','-UEPAutoRespawnListeners','-UEPAutoRespawnEvents','-UEPAutoRespawnActivation',
                    "-UEPNativeMessageNetworkPeer=$peer","-UEPNativeMessageNetworkRun=$run","-UEPNativeMessageNetworkProfile=$profile",
                    "-UEPNativeMessageNetworkResult=$dir/$peer.json","-abslog=$dir/$peer.log","-UserDir=$cache/User/CPP01/$profile/$peer/")
                if($ValidateTeam) {$arguments+="-UEPNativeTeamProfile=$profile"}
                if($peer -eq 'server') {$arguments+=@('-server','-NullRHI',"-port=$ServerPort",'-multihome=127.0.0.1','-ExecCmds=t.MaxFPS 60');$exe='F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe'}
                else {$arguments+=@('-game','-NullRHI','-RenderOffscreen','-ExecCmds=t.MaxFPS 30');$exe='F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe'}
                $handles[$peer]=Start-UEPValidationProcess $exe $arguments $stage "$dir/$peer" "$profile native rules $peer" $environment
                if($peer -eq 'server') {
                    $listen=[Diagnostics.Stopwatch]::StartNew()
                    while($true) {
                        if($handles.server.process.HasExited) {throw 'Authority exited before listen'}
                        if((Test-Path -LiteralPath "$dir/server.log") -and (Get-Content -LiteralPath "$dir/server.log" -Raw) -match "listening on port $ServerPort") {break}
                        if($listen.Elapsed.TotalSeconds -gt 120) {throw 'Authority listen timed out'}
                        Start-Sleep -Milliseconds 200
                    }
                }
            }
            $timer=[Diagnostics.Stopwatch]::StartNew()
            while($true) {
                if(@(@('server','A','B0')|Where-Object {Test-Path -LiteralPath "$dir/ready-$_.json"}).Count -eq 3) {break}
                foreach($peer in @('server','A','B0')) {
                    $r=Read-NativeMessageReport "$dir/$peer.json"
                    if($null -ne $r -and $r.status -eq 'failed') {throw "Native rule peer $peer failed: $($r.error)"}
                    if($handles[$peer].process.HasExited) {throw "Native rule peer $peer exited early"}
                }
                if($timer.Elapsed.TotalSeconds -gt 420) {throw 'Native rule network barrier timed out'}
                Start-Sleep -Milliseconds 200
            }
            foreach($peer in @('server','A','B0')) {if((Read-NativeMessageReport "$dir/ready-$peer.json").run_id -ne $run) {throw 'Foreign native network barrier'}}
            Write-NativeMessageToken "$dir/release.json" @{run_id=$run}
            foreach($peer in @('A','B0','server')) {
                if($peer -eq 'server') {
                    if($handles.server.process.HasExited) {throw 'Authority exited before both client exits'}
                    Write-NativeMessageToken "$dir/server-release.json" @{run_id=$run;client_exit_codes=@{A=$case.processes.A.exit_code;B0=$case.processes.B0.exit_code}}
                }
                if(!$handles[$peer].process.WaitForExit(60000)) {throw 'Native rule shutdown timed out'}
                $case.processes[$peer]=Complete-UEPValidationProcess $handles[$peer]
                if($case.processes[$peer].exit_code -ne 0) {throw 'Native rule process failed'}
                $r=Get-Content -LiteralPath "$dir/$peer.json" -Raw|ConvertFrom-Json -Depth 70
                if($r.status -ne 'passed') {throw "Native rule peer $peer shutdown gate failed: $($r.error)"}
                $log=Get-Content -LiteralPath "$dir/$peer.log" -Raw
                Assert-UEPFocusedLog $log 'UEP_NATIVE_RULE_NETWORK_PASSED'
                Assert-UEPFocusedLog $log 'UEP_NATIVE_RULE_SHUTDOWN_PASSED' -RequirePythonExit
            }
            $case.external_gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8','-m','uep_lyra_native.message_network_contract','--directory',$dir) $scripts "$dir/independent-gate" "$profile native GAS/network independent gate" 30
            $case.status='passed'
        } catch {$case.error=$_.ToString();throw}
        finally {foreach($peer in @($handles.Keys)) {$handle=$handles[$peer];Stop-UEPValidationProcess $handle;$case.processes[$peer]=Complete-UEPValidationProcess $handle;$handle.process.Dispose()};$handles=@{}}
    }
    foreach($row in $summary.hashes) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Frozen network input changed'}}
    $summary.status='passed';$summary.actual_native_damage_and_network=$true
} catch {$summary.error=$_.ToString();throw}
finally {$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
