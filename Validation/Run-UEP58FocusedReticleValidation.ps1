#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot = 'F:\UnrealEngine',
    [Parameter(Mandatory = $true)][string]$StageProject,
    [Parameter(Mandatory = $true)][string]$OutputDirectory
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
New-Item -ItemType Directory -Path $output | Out-Null
$summary = [ordered]@{schema_version=1; status='failed'; full_acceptance=$false; network_acceptance=$false
    cpp_compile_executed=$false; cook_package_executed=$false; culture='en'; hashes=@(); process=$null; error=$null}
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
    foreach ($relative in @('Content\UEPMixins\DA_W_Reticle_AmmoBarMixin.uasset', 'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_Reticle_AmmoBar.uasset')) {
        $source = Join-Path $overlay $relative
        $target = Join-Path $stage $relative
        if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw 'Reticle asset differs' }
        $summary.hashes += @{path=$source; sha256=(Get-FileHash -LiteralPath $source).Hash}
        $summary.hashes += @{path=$target; sha256=(Get-FileHash -LiteralPath $target).Hash}
    }
    $marker = Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
    $reference = Join-Path (Split-Path $marker.source -Parent) 'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_Reticle_AmmoBar.uasset'
    $summary.hashes += @{path=$reference; sha256=(Get-FileHash -LiteralPath $reference).Hash}
    $binary = Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'
    $summary.hashes += @{path=$binary; sha256=(Get-FileHash -LiteralPath $binary).Hash}
    $args = @($StageProject, '/Engine/Maps/Entry?game=/Script/Engine.GameModeBase', '-game', '-RenderOffscreen', '-windowed', '-ResX=1280', '-ResY=720',
        '-unattended', '-nop4', '-NoSound', '-NoSplash', '-NoLoadingScreen', '-culture=en', '-UTF8Output', '-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging', '-notraceserver', '-trace=none', '-ExecCmds=t.MaxFPS 60',
        "-UEPReticleAmmoResult=$output\reticle.json", "-abslog=$output\reticle.log")
    $summary.process = Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $args $stage (Join-Path $output 'reticle') 'Reticle BP/Python differential' 180
    $report = Get-Content -LiteralPath (Join-Path $output 'reticle.json') -Raw | ConvertFrom-Json
    if ($report.status -ne 'passed' -or @($report.cases).Count -ne 10 -or !$report.original_bp_compared -or
        !$report.class_identity_preserved -or !$report.live_profile_round_trip -or $report.full_acceptance -or $report.network_acceptance) { throw 'Incomplete reticle comparison' }
    foreach ($case in $report.cases) {
        if ($case.bp.range -ne $case.python.range -or $case.bp.segments -ne $case.python.segments -or
            $case.python.segments -ne $case.maximum * 4 + 1) { throw 'Reticle material differs from BP' }
    }
    $final = $report.observer_cleanup
    if ($final.active_count -ne 0 -or $final.active_scopes -ne 0 -or $final.ticker_active -or @($final.errors).Count -ne 0) { throw 'Reticle observer was not cleaned up' }
    $log = Get-Content -LiteralPath (Join-Path $output 'reticle.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_RETICLE_DIFFERENTIAL_PASSED'
    if ($log -notmatch '(?s)UEP_RETICLE_DIFFERENTIAL_PASSED.*Goodbye Python.*Log file closed') { throw 'Reticle did not exit normally' }
    $image = [IO.File]::ReadAllBytes($report.image)
    if (($image[0..7] -join ',') -ne '137,80,78,71,13,10,26,10') { throw 'Rendered reticle image missing' }
    $summary.image = @{path=$report.image; sha256=(Get-FileHash -LiteralPath $report.image).Hash}
    foreach ($input in $summary.hashes) {
        if ((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256) { throw 'Reticle input/reference changed' }
    }
    $summary.status = 'passed'
}
catch { $summary.error=$_.ToString(); throw }
finally { $summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8 }
Write-Host "Focused reticle pilot: $($summary.status); $output"
