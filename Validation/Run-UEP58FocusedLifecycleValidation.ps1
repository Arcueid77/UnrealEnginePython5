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
if (!(Test-Path -LiteralPath (Join-Path $stage '.uep-validation-stage'))) { throw 'Marked generic validation host required' }
if (Test-Path -LiteralPath $output) { throw 'Use a fresh evidence directory' }
New-Item -ItemType Directory -Path $output | Out-Null
$summary = [ordered]@{schema_version=1; status='failed'; cpp_compile_executed=$false; cook_package_executed=$false
    native_binary_provenance='Existing compiled generic host and UEP modules; source parity checked'
    source_hashes=@(); binary_hashes=@(); process=$null; error=$null}
try {
    foreach ($mapping in @(
        @{source=(Join-Path $repo 'Source'); target=(Join-Path $stage 'Plugins\UnrealEnginePython\Source')},
        @{source=(Join-Path $PSScriptRoot 'UEP58Host\Source'); target=(Join-Path $stage 'Source')}
    )) {
        foreach ($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File) {
            $relative = [IO.Path]::GetRelativePath($mapping.source, $source.FullName)
            $hash = (Get-FileHash -LiteralPath $source.FullName).Hash
            if ($hash -ne (Get-FileHash -LiteralPath (Join-Path $mapping.target $relative)).Hash) { throw "Native source differs: $relative" }
            $summary.source_hashes += @{path=$source.FullName; sha256=$hash}
        }
    }
    $buildId = (Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.version') -Raw | ConvertFrom-Json).BuildId
    foreach ($directory in @('Binaries\Win64', 'Plugins\UnrealEnginePython\Binaries\Win64')) {
        $binaryRoot = Join-Path $stage $directory
        if ((Get-Content -LiteralPath (Join-Path $binaryRoot 'UnrealEditor.modules') -Raw | ConvertFrom-Json).BuildId -ne $buildId) { throw 'Stale module metadata' }
        foreach ($binary in Get-ChildItem -LiteralPath $binaryRoot -Filter 'UnrealEditor-*.dll') {
            $summary.binary_hashes += @{path=$binary.FullName; sha256=(Get-FileHash -LiteralPath $binary.FullName).Hash}
        }
    }
    foreach ($mapping in @(
        @{source=(Join-Path $PSScriptRoot 'UEP58Host\Content\Scripts'); target=(Join-Path $stage 'Content\Scripts')},
        @{source=(Join-Path $repo 'Content\Scripts'); target=(Join-Path $stage 'Plugins\UnrealEnginePython\Content\Scripts')}
    )) {
        foreach ($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File -Filter '*.py') {
            $target = Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source, $source.FullName))
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $source.FullName -Destination $target -Force
            $summary.source_hashes += @{path=$source.FullName; sha256=(Get-FileHash -LiteralPath $source.FullName).Hash}
        }
    }
    $fixture = Join-Path $PSScriptRoot 'UEP58Host\Tests\mixin_pie_validation.py'
    $summary.source_hashes += @{path=$fixture; sha256=(Get-FileHash -LiteralPath $fixture).Hash}
    $arguments = @($StageProject, '-unattended', '-nop4', '-NullRHI', '-NoSound', '-NoSplash', '-UTF8Output',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging', '-notraceserver', '-trace=none',
        "-UEPPIEScript=$fixture", "-UEPPIEResult=$output\pie.json", "-abslog=$output\pie.log")
    $summary.process = Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output 'pie') 'repeated-PIE' 240
    $report = Get-Content -LiteralPath (Join-Path $output 'pie.json') -Raw | ConvertFrom-Json
    if ($report.status -ne 'passed' -or !$report.same_editor_process -or @($report.sessions).Count -ne 3) { throw 'Repeated PIE did not pass' }
    foreach ($session in $report.sessions) {
        if (!$session.placed_and_spawned -or !$session.construction -or !$session.native_gc_collected -or !$session.router_restored -or
            $session.closed_scopes -ne 2 -or ($session.begin_end_counts -join ',') -ne '2,2') { throw 'PIE session has incomplete lifecycle proof' }
    }
    $log = Get-Content -LiteralPath (Join-Path $output 'pie.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_MIXIN_PIE_PASSED'
    if ($log -notmatch '(?s)UEP_MIXIN_PIE_PASSED.*Goodbye Python.*Log file closed') { throw 'PIE completion/exit order is incomplete' }
    foreach ($input in @($summary.source_hashes) + @($summary.binary_hashes)) {
        if ((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256) { throw "Input changed during PIE: $($input.path)" }
    }
    $summary.status = 'passed'
}
catch { $summary.error = $_.ToString(); throw }
finally { $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8 }
Write-Host "Repeated PIE lifecycle validation: $($summary.status); $output"
