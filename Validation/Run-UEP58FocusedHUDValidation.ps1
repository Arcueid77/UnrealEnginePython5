[CmdletBinding()]
param(
    [string]$EngineRoot = 'F:\UnrealEngine',
    [Parameter(Mandatory = $true)][string]$StageProject,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [ValidateSet('All', 'Callsite', 'Visual')][string]$Mode = 'All',
    [switch]$SwitchDuringAnimation,
    [switch]$RenderOffscreen
)

# No UBT, cook, package, asset save, reference-project edit, or metadata repair.
# Reuses a marked full-content stage whose native sources must already match.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
if ($SwitchDuringAnimation -and $Mode -ne 'Visual') { throw 'SwitchDuringAnimation is only valid with Mode Visual' }
$repo = Split-Path $PSScriptRoot -Parent
$stage = Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) { throw "Use a new evidence directory: $output" }
if (!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))) { throw 'A marked disposable Lyra stage is required' }
New-Item -ItemType Directory -Path $output | Out-Null
$summary = [ordered]@{
    schema_version = 1; status = 'failed'; mode = $Mode; full_acceptance = $false
    cpp_compile_executed = $false; cook_package_executed = $false
    rendered_offscreen = [bool]$RenderOffscreen
    native_binary_provenance = 'Reused existing stage; hashes and source parity are checked, no fresh build proof'
    core_commit = (& git -C $repo rev-parse HEAD)
    examples_commit = (& git -C (Join-Path $repo 'Demos') rev-parse HEAD)
    core_worktree_status = @(& git -C $repo status --short)
    examples_worktree_status = @(& git -C (Join-Path $repo 'Demos') status --short)
    engine_build_id = $null; binary_hashes = @(); script_hashes = @()
    mixin_callsite = $null; hud_visual = $null; error = $null
}

function Invoke-FocusedProcess {
    param([string]$Executable, [string[]]$Arguments, [string]$Name)
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $Executable
    $start.WorkingDirectory = $stage
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $stdout = $null
    $stderr = $null
    Write-Host "[$Name] Reusing staged binaries; no build/cook/package"
    try {
        $null = $process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (!$process.WaitForExit(240000)) {
            $process.Kill($true)
            $process.WaitForExit()
            throw "$Name timed out"
        }
        if ($process.ExitCode -ne 0) { throw "$Name exited with code $($process.ExitCode)" }
    }
    finally {
        if ($null -ne $stdout -and $null -ne $stderr) {
            ($stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()) |
                Set-Content -LiteralPath (Join-Path $output "$Name-stdout.log") -Encoding utf8
        }
        $process.Dispose()
    }
}

try {
    $versionPath = Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.version'
    $summary.engine_build_id = (Get-Content -LiteralPath $versionPath -Raw | ConvertFrom-Json).BuildId
    if ([string]::IsNullOrWhiteSpace($summary.engine_build_id)) { throw 'Engine BuildId is absent' }
    foreach ($manifest in @(
        (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules'),
        (Join-Path $stage 'Binaries\Win64\UnrealEditor.modules'),
        (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules'),
        (Join-Path $stage 'Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor.modules')
    )) {
        if ((Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).BuildId -ne $summary.engine_build_id) {
            throw "Stale module metadata; resolve with official UBT before testing: $manifest"
        }
    }
    foreach ($mapping in @(
        @{source=(Join-Path $repo 'Source'); target=(Join-Path $stage 'Plugins\UnrealEnginePython\Source')},
        @{source=(Join-Path $repo 'Demos\UEPLyraIntegration\Plugins\UEPLyraBridge\Source'); target=(Join-Path $stage 'Plugins\UEPLyraBridge\Source')}
    )) {
        foreach ($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File) {
            $relative = [IO.Path]::GetRelativePath($mapping.source, $source.FullName)
            if ((Get-FileHash -LiteralPath $source.FullName).Hash -ne
                (Get-FileHash -LiteralPath (Join-Path $mapping.target $relative)).Hash) { throw "Staged native source differs: $relative" }
        }
    }
    foreach ($binary in @(
        (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-NetCore.dll'),
        (Join-Path $stage 'Binaries\Win64\UnrealEditor-LyraGame.dll'),
        (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'),
        (Join-Path $stage 'Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor-UEPLyraBridge.dll')
    )) { $summary.binary_hashes += @{path=$binary; sha256=(Get-FileHash -LiteralPath $binary).Hash} }
    $scripts = Join-Path $repo 'Demos\UEPLyraIntegration\Overlay\Content\Scripts'
    foreach ($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Content\Scripts') -Recurse -File -Filter '*.py') {
        $relative = [IO.Path]::GetRelativePath($repo, $source.FullName)
        $destination = Join-Path (Join-Path $stage 'Plugins\UnrealEnginePython') $relative
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $destination -Force
        $summary.script_hashes += @{path=('Plugins\UnrealEnginePython\' + $relative); sha256=(Get-FileHash -LiteralPath $source.FullName).Hash}
    }
    foreach ($source in Get-ChildItem -LiteralPath $scripts -Recurse -File -Filter '*.py') {
        $relative = [IO.Path]::GetRelativePath($scripts, $source.FullName)
        $destination = Join-Path (Join-Path $stage 'Content\Scripts') $relative
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $destination -Force
        $hash = (Get-FileHash -LiteralPath $source.FullName).Hash
        if ((Get-FileHash -LiteralPath $destination).Hash -ne $hash) { throw "Script sync failed: $relative" }
        $summary.script_hashes += @{path=$relative; sha256=$hash}
    }
    $common = @('-unattended', '-nop4', '-NoSound', '-NoSplash', '-culture=en', '-UTF8Output', '-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging', '-notraceserver', '-trace=none', '-stdout', '-FullStdOutLogOutput')
    if ($Mode -in @('All', 'Callsite')) {
        $reportPath = Join-Path $output 'callsite.json'
        $logPath = Join-Path $output 'callsite.log'
        $fixture = Join-Path $PSScriptRoot 'UEP58Host\Tests\mixin_callsite_validation.py'
        $arguments = @($StageProject) + $common + @('-NullRHI', '-run=Py', $fixture, "-UEPMixinCallsiteResult=$reportPath", "-abslog=$logPath")
        Invoke-FocusedProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') $arguments 'callsite'
        Assert-UEPMixinCallsiteData (Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json)
        $log = Get-Content -LiteralPath $logPath -Raw
        Assert-UEPFocusedLog $log 'UEP_MIXIN_CALLSITE_PASSED'
        if ($log -notmatch 'UEP_MIXIN_CALLSITE_PASSED' -or $log -match 'UEP_MIXIN_CALLSITE_FAILED' -or $log -notmatch 'Log file closed') { throw 'Callsite log did not pass' }
        $summary.mixin_callsite = @{status='passed'; report=$reportPath; unreal_log=$logPath; script_sha256=(Get-FileHash -LiteralPath $fixture).Hash}
    }
    if ($Mode -in @('All', 'Visual')) {
        $reportPath = Join-Path $output 'visual.json'
        $logPath = Join-Path $output 'visual.log'
        $arguments = @($StageProject, '/Engine/Maps/Entry?game=/Script/Engine.GameModeBase', '-game') + $common +
            @('-windowed', '-ResX=1280', '-ResY=720', '-NoLoadingScreen', "-UEPLyraHUDVisualResult=$reportPath", "-abslog=$logPath")
        if ($SwitchDuringAnimation) { $arguments += '-UEPLyraHUDSwitchDuringAnimation' }
        if ($RenderOffscreen) { $arguments += '-RenderOffscreen' }
        $arguments += '-ExecCmds=t.MaxFPS 60'
        Invoke-FocusedProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments 'visual'
        $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
        Assert-LyraHUDVisualData $report
        if (!$report.delayed_asc_bootstrap_recovered) { throw 'Delayed ASC bootstrap recovery was not verified' }
        $log = Get-Content -LiteralPath $logPath -Raw
        Assert-UEPFocusedLog $log 'UEP_LYRA_HUD_VISUAL_PASSED' -RequirePythonExit
        if ($log -notmatch '(?s)Goodbye Python.*UEP_LYRA_HUD_VISUAL_PASSED.*Log file closed' -or $log -match 'UEP_LYRA_HUD_VISUAL_FAILED') { throw 'Rendered HUD log lacks successful exit evidence' }
        $images = @()
        foreach ($frame in $report.frames) {
            $imagePath = [IO.Path]::GetFullPath($frame.image)
            if ((Split-Path $imagePath -Parent) -ne $output -or [IO.Path]::GetExtension($imagePath) -ne '.png') { throw 'Unexpected screenshot path' }
            $bytes = [IO.File]::ReadAllBytes($imagePath)
            if ($bytes.Length -lt 100 -or ($bytes[0..7] -join ',') -ne '137,80,78,71,13,10,26,10') { throw 'Missing or invalid PNG screenshot' }
            $images += @{name=$frame.name; path=$imagePath; sha256=(Get-FileHash -LiteralPath $imagePath).Hash}
        }
        $summary.hud_visual = @{status='passed'; report=$reportPath; unreal_log=$logPath; images=$images}
    }
    if ($Mode -eq 'All') {
        # Keep ordinary Destruct and live profile-switch cleanup as separate
        # processes so one scenario cannot hide the other's owned-state ledger.
        $switchOutput = Join-Path $output 'SwitchDuringAnimation'
        $switchArguments = @('-NoProfile', '-NonInteractive', '-File', $PSCommandPath,
            '-EngineRoot', $EngineRoot, '-StageProject', $StageProject,
            '-OutputDirectory', $switchOutput, '-Mode', 'Visual', '-SwitchDuringAnimation')
        if ($RenderOffscreen) { $switchArguments += '-RenderOffscreen' }
        Invoke-FocusedProcess (Get-Process -Id $PID).Path $switchArguments 'visual-switch'
        $switchReport = Get-Content -LiteralPath (Join-Path $switchOutput 'summary.json') -Raw | ConvertFrom-Json
        if ($switchReport.status -ne 'passed') { throw 'Mid-animation profile switch failed' }
        $summary.hud_visual.switch_during_animation = $switchReport.hud_visual
    }
    if ((Get-Content -LiteralPath $versionPath -Raw | ConvertFrom-Json).BuildId -ne $summary.engine_build_id) { throw 'Shared Engine changed during acceptance' }
    foreach ($binary in $summary.binary_hashes) {
        if ((Get-FileHash -LiteralPath $binary.path).Hash -ne $binary.sha256) { throw "Binary changed during acceptance: $($binary.path)" }
    }
    $summary.status = 'passed'
}
catch { $summary.error = $_.ToString(); throw }
finally { $summary | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8 }
Write-Host "Focused HUD $Mode validation: $($summary.status); $output"
