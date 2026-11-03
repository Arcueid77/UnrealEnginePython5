#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/Reproduction/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$CookEvidenceDirectory,
    [ValidateRange(1024,65535)][int]$ServerPort=19011,
    [ValidateSet('Damage','Pawn')][string]$Family='Damage'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'UEPPackagedNativeDependencies.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {throw 'Owned native stage and fresh network output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count) {throw 'Another native lane is active'}
$socket=[Net.Sockets.UdpClient]::new();try {$socket.Client.ExclusiveAddressUse=$true;$socket.Client.Bind([Net.IPEndPoint]::new([Net.IPAddress]::Loopback,$ServerPort))} finally {$socket.Dispose()}
$cook=Get-Content -LiteralPath "$CookEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 50
if($cook.status -ne 'passed' -or $cook.scope -ne 'current-original-migration-content-cook-package' -or !$cook.cook_package_executed){throw 'Closed accepted current package required'}
foreach($row in $cook.products){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Packaged product changed'}}
$gameExe=[IO.Path]::GetFullPath($cook.packaged_executable)
if(!$gameExe.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($gameExe) -ne 'LyraGame.exe'){throw 'Owned actual inner Game executable required'}
$packageProject=Split-Path (Split-Path (Split-Path $gameExe -Parent) -Parent) -Parent
$packageRoot=Split-Path $packageProject -Parent
$buildSummaryPath=@($cook.hashes|Where-Object {[IO.Path]::GetFileName($_.path) -eq 'summary.json'})[0].path
$gameBuild=Get-Content -LiteralPath $buildSummaryPath -Raw|ConvertFrom-Json -Depth 30
$receipt=@($gameBuild.products|Where-Object {[IO.Path]::GetFileName($_.path) -eq 'LyraGame.target'})[0].path
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';batch='H04';packaged_runtime=$true;packaged_authority_mode='ListenServer';host_local_player_removal_requested=$true;actual_native_rule_network=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();lanes=@{};error=$null}
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
    Add-NativeCostHash $gameExe;Add-NativeCostHash "$CookEvidenceDirectory/summary.json"
    foreach($row in $cook.products){Add-NativeCostHash $row.path}
    foreach($mapping in @(@{source=$scripts;target="$packageProject/Content/Scripts"},@{source=(Join-Path $repo 'Content/Scripts');target="$packageProject/Plugins/UnrealEnginePython/Content/Scripts"})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File -Filter '*.py'){
            $copy=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName))
            if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Packaged Python payload differs from current source'}
            Add-NativeCostHash $file.FullName;Add-NativeCostHash $copy
        }
    }
    $dependencyTool=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/inspect_native_package_dependencies.py'
    $networkContract=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/check_packaged_native_network.py'
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $PSScriptRoot 'UEPPackagedNativeDependencies.ps1'),$dependencyTool,$networkContract,$receipt,(Join-Path $scripts 'uep_lyra_native/rule_network_contract.py'))) {Copy-Item -LiteralPath $path -Destination "$output/Inputs";Add-NativeCostHash $path}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}

    foreach($weapon in @('rule')) {
        $dir=Join-Path $output $weapon;New-Item -ItemType Directory -Path $dir|Out-Null
        $run=[guid]::NewGuid().ToString('N');$handles=@{};$case=[ordered]@{status='failed';run_id=$run;processes=@{};loaded_python=@{};dependency_gates=@{};error=$null};$summary.lanes[$weapon]=$case
        try {
            foreach($peer in @('server','A','B0')) {
                $url=if($peer -eq 'server') {'/ShooterMaps/Maps/L_Expanse?listen?NumBots=3'} else {"127.0.0.1:$ServerPort"}
                $arguments=@($url,'-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython',
                    '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',
                    '-UEPRequireNetworkIdentity','-UEPAutoRespawnListeners','-UEPAutoRespawnEvents','-UEPAutoRespawnActivation','-UEPNativeResetNetwork','-UEPNativeRuleNetwork',"-UEPNativeRuleNetworkFamily=$Family",
                    "-UEPJumpPeer=$peer","-UEPJumpRun=$run","-UEPAutoRespawnResetNetworkResult=$dir/$peer.json",
                    "-abslog=$dir/$peer.log","-UserDir=$cache/User/H04/$weapon/$peer/")
                if($peer -eq 'server') {$arguments+=@('-NullRHI','-RenderOffscreen',"-port=$ServerPort",'-multihome=127.0.0.1','-ExecCmds=DebugRemovePlayer 0,t.MaxFPS 60')}
                else {$arguments+=@('-game','-NullRHI','-RenderOffscreen','-ExecCmds=t.MaxFPS 30')}
                $handles[$peer]=Start-UEPValidationProcess $gameExe $arguments (Split-Path $gameExe -Parent) "$dir/$peer" "$weapon native costs $peer" $environment
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
                    if($null -ne $r -and !$case.loaded_python.ContainsKey($peer)){
                        $dependency=Get-UEPPackagedPythonDependency $handles[$peer].process $packageRoot
                        if($null -ne $dependency){$case.loaded_python[$peer]=$dependency}
                    }
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
                Assert-UEPFocusedLog $log 'UEP_NATIVE_RULE_NETWORK_SHUTDOWN_PASSED' -RequirePythonExit
                if($log -notmatch '(?s)Goodbye Python.*UEP_NATIVE_RULE_NETWORK_SHUTDOWN_PASSED.*Log file closed'){throw 'Native cost network shutdown ordering failed'}
                if(!$case.loaded_python.ContainsKey($peer)){throw 'Packaged network peer did not prove its loaded CPython runtime'}
                $case.dependency_gates[$peer]=Invoke-UEPValidationProcess $python @('-B','-X','utf8',$dependencyTool,'--package',$packageRoot,'--engine','F:/UnrealEngine','--receipt',$receipt,'--log',"$dir/$peer.log",'--working',(Split-Path $gameExe -Parent),'--result',"$dir/$peer-dependencies.json") $repo "$dir/$peer-dependency-gate" 'Packaged network CPython receipt and actual home' 60
            }
            $case.external_gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8',$networkContract,'--directory',$dir,'--family',$Family,'--result',"$dir/listen-independent-gate.json") $repo "$dir/independent-gate" "$weapon packaged listen prediction/authority gate" 30
            $case.status='passed'
        } catch {$case.error=$_.ToString();throw}
        finally {foreach($peer in @($handles.Keys)) {$handle=$handles[$peer];Stop-UEPValidationProcess $handle;$case.processes[$peer]=Complete-UEPValidationProcess $handle;$handle.process.Dispose()};$handles=@{}}
    }
    foreach($row in $summary.hashes) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Frozen cost network input changed'}}
    $summary.status='passed';$summary.actual_native_rule_network=$true
} catch {$summary.error=$_.ToString();throw}
finally {$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
