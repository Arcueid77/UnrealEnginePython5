#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot = 'F:\UnrealEngine',
    [Parameter(Mandatory = $true)][string]$StageProject,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [int]$ServerPort = 18583
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo = Split-Path $PSScriptRoot -Parent
$stage = Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))) { throw 'Marked disposable stage required' }
if (Test-Path -LiteralPath $output) { throw 'Use a fresh evidence directory' }
if ($ServerPort -lt 1024 -or $ServerPort -gt 65535) { throw 'Invalid server port' }
$probe = [Net.Sockets.UdpClient]::new()
try { $probe.Client.ExclusiveAddressUse=$true; $probe.Client.Bind([Net.IPEndPoint]::new([Net.IPAddress]::Loopback,$ServerPort)) }
finally { $probe.Dispose() }
New-Item -ItemType Directory -Path $output | Out-Null
$runId = [guid]::NewGuid().ToString('N')
$handles = @{}
$summary = [ordered]@{schema_version=1; status='failed'; run_id=$runId; client_count=2; cases=16
    cpp_compile_executed=$false; cook_package_executed=$false; full_acceptance=$false; hashes=@(); processes=@(); error=$null}
try {
    foreach ($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File) {
        $target = Join-Path $stage ('Plugins\UnrealEnginePython\Source\' + [IO.Path]::GetRelativePath((Join-Path $repo 'Source'), $source.FullName))
        if ((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw 'Native source differs' }
    }
    $overlay = Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach ($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py') {
        $target = Join-Path $stage ([IO.Path]::GetRelativePath($overlay, $source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        $summary.hashes += @{path=$source.FullName; sha256=(Get-FileHash -LiteralPath $source.FullName).Hash}
    }
    $marker = Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
    foreach ($relative in @('Content\UEPMixins\DA_BP_GameplayEffectPadMixin.uasset','Content\Environments\Gameplay\BP_GameplayEffectPad.uasset')) {
        $source = Join-Path $overlay $relative
        $target = Join-Path $stage $relative
        if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw 'Pad asset differs' }
        $summary.hashes += @{path=$source; sha256=(Get-FileHash -LiteralPath $source).Hash}
        $summary.hashes += @{path=$target; sha256=(Get-FileHash -LiteralPath $target).Hash}
    }
    foreach ($name in @('BP_GameplayEffectPad','B_GameplayEffectPad_Child_Healing')) {
        $reference = Join-Path (Split-Path $marker.source -Parent) "Content\Environments\Gameplay\$name.uasset"
        $summary.hashes += @{path=$reference; sha256=(Get-FileHash -LiteralPath $reference).Hash}
    }
    $binary = Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'
    $summary.hashes += @{path=$binary; sha256=(Get-FileHash -LiteralPath $binary).Hash}
    $common = @('-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-ExecCmds=t.MaxFPS 60',
        '-Multiprocess','-UEPLyraMultiClient','-UEPLyraHUDSlice','-UEPEffectPadNetwork',"-UEPLyraNetRun=$runId","-UEPLyraNetDirectory=$output")
    foreach ($peer in @('server','A','B0')) {
        $url = if ($peer -eq 'server') {'/ShooterMaps/Maps/L_Expanse?NumBots=3'} else {"127.0.0.1:$ServerPort"}
        $arguments = @($StageProject,$url) + $common + @("-UEPLyraNetPeer=$peer","-abslog=$output\$peer.log")
        if ($peer -eq 'server') { $arguments += @('-server','-NullRHI',"-port=$ServerPort",'-multihome=127.0.0.1') }
        else { $arguments += @('-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360') }
        $handles[$peer] = Start-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output $peer) $peer
    }
    $timer = [Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        $ready = @('server','A','B0') | Where-Object { Test-Path -LiteralPath (Join-Path $output "ready-$_.json") }
        if (@($ready).Count -eq 3) { break }
        foreach ($peer in @('server','A','B0')) {
            if ($handles[$peer].process.HasExited) { throw "Pad peer $peer exited early" }
            $report = Join-Path $output "$peer.json"
            if (Test-Path -LiteralPath $report) {
                if ((Get-Content -LiteralPath $report -Raw | ConvertFrom-Json).status -eq 'failed') { throw "Pad peer $peer failed" }
            }
        }
        if ($timer.Elapsed.TotalSeconds -gt 420) { throw 'Pad network timed out' }
        Start-Sleep -Milliseconds 200
    }
    foreach ($peer in @('server','A','B0')) {
        if ((Get-Content -LiteralPath (Join-Path $output "ready-$peer.json") -Raw | ConvertFrom-Json).run_id -ne $runId) { throw 'Foreign readiness file' }
    }
    @{run_id=$runId} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'release.json.tmp') -Encoding utf8
    Move-Item -LiteralPath (Join-Path $output 'release.json.tmp') -Destination (Join-Path $output 'release.json')
    foreach ($peer in @('server','A','B0')) {
        if (!$handles[$peer].process.WaitForExit(60000)) { throw 'Pad network shutdown timed out' }
        $process = Complete-UEPValidationProcess $handles[$peer]
        if ($process.exit_code -ne 0) { throw "Pad peer $peer exit code differs" }
        $summary.processes += $process
        $log = Get-Content -LiteralPath (Join-Path $output "$peer.log") -Raw
        Assert-UEPFocusedLog $log 'UEP_EFFECT_PAD_NETWORK_PASSED'
        Assert-UEPFocusedLog $log 'UEP_LYRA_HUD_SHUTDOWN_PASSED' -RequirePythonExit
    }
    $python = Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\Python3\Win64\python.exe'
    $validator = Join-Path $repo 'Demos\UEPLyraIntegration\Tools\validate_effect_pad_network_reports.py'
    $summary.validation = Invoke-UEPValidationProcess $python @('-B',$validator,$output) $repo (Join-Path $output 'reports') 'Pad network report validation' 60
    foreach ($input in $summary.hashes) {
        if ((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256) { throw 'Pad network input/reference changed' }
    }
    $summary.status = 'passed'
}
catch { $summary.error=$_.ToString(); throw }
finally {
    foreach ($handle in $handles.Values) { Stop-UEPValidationProcess $handle; $handle.process.Dispose() }
    $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8
}
Write-Host "Effect Pad two-client network: $($summary.status); $output"
