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
    cpp_compile_executed=$false; cook_package_executed=$false; hashes=@(); process=$null; error=$null}
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
    foreach ($relative in @('Content\UEPMixins\DA_BP_GameplayEffectPadMixin.uasset', 'Content\Environments\Gameplay\BP_GameplayEffectPad.uasset')) {
        $source = Join-Path $overlay $relative
        $target = Join-Path $stage $relative
        if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw 'Effect pad asset differs' }
        $summary.hashes += @{path=$source; sha256=(Get-FileHash -LiteralPath $source).Hash}
        $summary.hashes += @{path=$target; sha256=(Get-FileHash -LiteralPath $target).Hash}
    }
    $marker = Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
    foreach ($relative in @('Content\Environments\Gameplay\BP_GameplayEffectPad.uasset', 'Content\Environments\Gameplay\B_GameplayEffectPad_Child_Healing.uasset')) {
        $reference = Join-Path (Split-Path $marker.source -Parent) $relative
        $summary.hashes += @{path=$reference; sha256=(Get-FileHash -LiteralPath $reference).Hash}
    }
    $binary = Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'
    $summary.hashes += @{path=$binary; sha256=(Get-FileHash -LiteralPath $binary).Hash}
    $args = @($StageProject, '/ShooterMaps/Maps/L_Expanse?NumBots=3', '-game', '-NullRHI',
        '-unattended', '-nop4', '-NoSound', '-NoSplash', '-NoLoadingScreen', '-culture=en', '-UTF8Output', '-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging', '-notraceserver', '-trace=none', '-ExecCmds=t.MaxFPS 60',
        "-UEPEffectPadGameplayResult=$output\gameplay.json", "-abslog=$output\gameplay.log")
    $summary.process = Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $args $stage (Join-Path $output 'gameplay') 'Effect Pad physical/native GAS differential' 240
    $report = Get-Content -LiteralPath (Join-Path $output 'gameplay.json') -Raw | ConvertFrom-Json
    if ($report.status -ne 'passed' -or @($report.cases).Count -ne 8 -or !$report.real_gas_verified -or
        !$report.physical_overlap_tested -or !$report.original_bp_compared -or $report.network_acceptance -or
        $report.overlap_handlers_called_by_probe -or $report.attributes_written_by_probe -or !$report.delegates_closed -or
        $report.shutdown.status -ne 'passed') { throw 'Incomplete physical/native GAS comparison' }
    if (@($report.cases | Select-Object -ExpandProperty class -Unique).Count -ne 2) { throw 'Missing parent/child class coverage' }
    foreach ($case in $report.cases) {
        if (@($case.rounds).Count -ne 2 -or (@($case.physical_events.type) -join ',') -ne 'begin,end,begin,end') { throw 'Missing physical overlap rounds' }
        foreach ($round in $case.rounds) {
            if ($round.inside_count -lt 1 -or $round.after_count -ne 0 -or [math]::Abs($round.inside - $round.after) -gt 0.05) { throw 'Native effect lifetime incorrect' }
        }
    }
    $log = Get-Content -LiteralPath (Join-Path $output 'gameplay.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_EFFECT_PAD_GAMEPLAY_PASSED'
    Assert-UEPFocusedLog $log 'UEP_LYRA_HUD_SHUTDOWN_PASSED' -RequirePythonExit
    foreach ($input in $summary.hashes) {
        if ((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256) { throw 'Effect pad input/reference changed' }
    }
    $summary.status = 'passed'
}
catch { $summary.error=$_.ToString(); throw }
finally { $summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8 }
Write-Host "Focused Effect Pad physical/GAS pilot: $($summary.status); $output"
