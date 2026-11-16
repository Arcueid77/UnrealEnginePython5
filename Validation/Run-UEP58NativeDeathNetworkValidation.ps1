#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$BuildEvidenceDirectory,
    [Parameter(Mandatory=$true)][string]$AssetEvidenceDirectory,
    [ValidateRange(1024,65535)][int]$ServerPort=18831,
    [ValidateSet('matrix','selfdestruct')][string]$Scenario='matrix'
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
if($build.status -ne 'built_requires_native_acceptance' -or $null -ne $build.error -or $assets.status -ne 'passed' -or $assets.assets.Count -ne 2) {throw 'Successful build and processor asset family required'}
foreach($row in $build.products) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Compiled native module changed'}}
foreach($row in $assets.assets) {if((Get-FileHash -LiteralPath (Join-Path $stage $row.relative)).Hash -ne $row.sha256) {throw 'Authored native asset changed'}}
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';batch='CPP14';actual_native_death_network=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();lanes=@{};error=$null}
$python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe';$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay';$scripts=Join-Path $overlay 'Content/Scripts';$handles=@{}
function Add-NativeCostHash([string]$Path) {$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
function Read-NativeCostReport([string]$Path) {
    $value=& $python -B -X utf8 -c 'import sys,json;from pathlib import Path;sys.path.insert(0,sys.argv[1]);from uep_lyra_network_io import read_json;print(json.dumps(read_json(Path(sys.argv[2]))))' $scripts $Path
    if($LASTEXITCODE -ne 0) {throw 'Shared network JSON read failed'}
    return ($value|ConvertFrom-Json -Depth 70)
}
function Write-NativeCostToken([string]$Path,[hashtable]$Value) {
    & $python -B -X utf8 -c 'import sys,json;from pathlib import Path;sys.path.insert(0,sys.argv[1]);from uep_lyra_network_io import atomic_write;atomic_write(Path(sys.argv[2]),json.loads(sys.argv[3]))' $scripts $Path ($Value|ConvertTo-Json -Depth 8 -Compress)
    if($LASTEXITCODE -ne 0) {throw 'Atomic network token write failed'}
}
try {
    foreach($file in Get-ChildItem -LiteralPath $scripts -Recurse -File -Filter '*.py') {
        $relative=[IO.Path]::GetRelativePath($overlay,$file.FullName);$copy=Join-Path $stage $relative;$archive=Join-Path "$output/Inputs/Overlay" $relative
        foreach($path in @($copy,$archive)) {New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $path -Force;Add-NativeCostHash $path}
        Add-NativeCostHash $file.FullName
    }
    foreach($file in Get-ChildItem -LiteralPath $overlay -Recurse -File -Filter '*.uasset') {
        $copy=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash) {throw 'Accepted overlay asset differs from native stage'}
        Add-NativeCostHash $file.FullName;Add-NativeCostHash $copy
    }
    foreach($relative in @('Binaries/Win64/UnrealEditor-LyraGame.dll','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll','Plugins/GameFeatures/ShooterCore/Binaries/Win64/UnrealEditor-ShooterCoreRuntime.dll','Content/UEPValidation/BP_EliminationFeedProbe.uasset','Content/UEPValidation/BP_AccoladeRelayProbe.uasset')) {Add-NativeCostHash (Join-Path $stage $relative)}
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/validate_native_death_network_reports.py'))) {Copy-Item -LiteralPath $path -Destination "$output/Inputs";Add-NativeCostHash $path}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}

    foreach($weapon in @('death')) {
        $dir=Join-Path $output $weapon;New-Item -ItemType Directory -Path $dir|Out-Null
        $run=[guid]::NewGuid().ToString('N');$handles=@{};$case=[ordered]@{status='failed';run_id=$run;processes=@{};error=$null};$summary.lanes[$weapon]=$case
        try {
            foreach($peer in @('server','A','B0')) {
                $url=if($peer -eq 'server') {'/ShooterMaps/Maps/L_Expanse?NumBots=3'} else {"127.0.0.1:$ServerPort"}
                $arguments=@($StageProject,$url,'-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython',
                    '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',
                    '-UEPRequireNetworkIdentity','-UEPAutoRespawnListeners','-UEPAutoRespawnEvents','-UEPAutoRespawnActivation','-UEPNativeDeathNetwork',"-UEPNativeDeathScenario=$Scenario",
                    "-UEPJumpPeer=$peer","-UEPJumpRun=$run","-UEPDeathNetworkResult=$dir/$peer.json",
                    "-abslog=$dir/$peer.log","-UserDir=$cache/User/CPP14/$weapon/$peer/")
                if($peer -eq 'server') {$arguments+=@('-server','-NullRHI',"-port=$ServerPort",'-multihome=127.0.0.1','-ExecCmds=t.MaxFPS 60')}
                else {$arguments+=@('-game','-NullRHI','-RenderOffscreen','-ExecCmds=t.MaxFPS 30')}
                $handles[$peer]=Start-UEPValidationProcess 'F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' $arguments $stage "$dir/$peer" "$weapon native costs $peer" $environment
                if($peer -eq 'server') {
                    $listen=[Diagnostics.Stopwatch]::StartNew()
                    while($true) {
                        if($handles.server.process.HasExited) {throw 'Cost authority exited before listen'}
                        if((Test-Path -LiteralPath "$dir/server.log") -and (Get-Content -LiteralPath "$dir/server.log" -Raw) -match "listening on port $ServerPort") {break}
                        if($listen.Elapsed.TotalSeconds -gt 120) {throw 'Cost authority listen timed out'}
                        Start-Sleep -Milliseconds 200
                    }
                }
            }
            $timer=[Diagnostics.Stopwatch]::StartNew()
            while($case.processes.Count -ne 3) {
                foreach($peer in @('A','B0','server')) {
                    $r=Read-NativeCostReport "$dir/$peer.json"
                    if($null -ne $r -and $r.status -eq 'failed') {throw "Native cost peer $peer failed: $($r.error)"}
                    if(!$case.processes.ContainsKey($peer) -and $handles[$peer].process.HasExited) {
                        $case.processes[$peer]=Complete-UEPValidationProcess $handles[$peer]
                        if($case.processes[$peer].exit_code -ne 0 -or $null -eq $r -or $r.status -ne 'passed') {throw "Native cost peer $peer exited without successful closed evidence"}
                        if($peer -ne 'server') {Write-NativeCostToken "$dir/$peer-exited.json" @{run_id=$run;exit_code=$case.processes[$peer].exit_code}}
                        elseif(!$case.processes.ContainsKey('A') -or !$case.processes.ContainsKey('B0')) {throw 'Cost authority exited before both clients'}
                    }
                }
                if($timer.Elapsed.TotalSeconds -gt 560) {throw 'Native cost network deadline exceeded'}
                Start-Sleep -Milliseconds 200
            }
            foreach($peer in @('server','A','B0')) {
                $log=Get-Content -LiteralPath "$dir/$peer.log" -Raw
                Assert-UEPFocusedLog $log 'UEP_NATIVE_DEATH_NETWORK_SHUTDOWN_PASSED' -RequirePythonExit
                if($log -notmatch '(?s)Goodbye Python.*UEP_NATIVE_DEATH_NETWORK_SHUTDOWN_PASSED.*Log file closed'){throw 'Native cost network shutdown ordering failed'}
            }
            $case.external_gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8',(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/validate_native_death_network_reports.py'),'--directory',$dir,'--scenario',$Scenario) $scripts "$dir/independent-gate" "$weapon native cost prediction/authority gate" 30
            $case.status='passed'
        } catch {$case.error=$_.ToString();throw}
        finally {foreach($peer in @($handles.Keys)) {$handle=$handles[$peer];Stop-UEPValidationProcess $handle;$case.processes[$peer]=Complete-UEPValidationProcess $handle;$handle.process.Dispose()};$handles=@{}}
    }
    foreach($row in $summary.hashes) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Frozen cost network input changed'}}
    $summary.status='passed';$summary.actual_native_death_network=$true
} catch {$summary.error=$_.ToString();throw}
finally {$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
