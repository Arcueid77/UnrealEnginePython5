#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot = 'F:\UnrealEngine',
    [Parameter(Mandatory = $true)][string]$StageProject,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [string[]]$TestName=@()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'UEPCallMatrixCases.ps1')
$selectedCases=@(Get-UEPCallMatrixCases -TestName $TestName)
$repo = Split-Path $PSScriptRoot -Parent
$stage = Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (!(Test-Path -LiteralPath (Join-Path $stage '.uep-validation-stage'))) { throw 'Marked generic host required' }
if (Test-Path -LiteralPath $output) { throw 'Use a fresh evidence directory' }
New-Item -ItemType Directory -Path $output | Out-Null
$summary = [ordered]@{schema_version=1; status='failed'; cpp_compile_executed=$false; cook_package_executed=$false
    native_binary_provenance='Existing source-matching generic host and UEP Editor modules'
    input_hashes=@(); tests=@(); error=$null;selected_test_names=@($selectedCases.name)
    full_matrix_executed=($selectedCases.Count -eq 11);full_regression_requested=$false}
function Add-CallMatrixInput([string]$Path) {
    $summary.input_hashes += @{path=$Path; sha256=(Get-FileHash -LiteralPath $Path).Hash}
}
try {
    Add-CallMatrixInput $PSCommandPath
    Add-CallMatrixInput (Join-Path $PSScriptRoot 'UEPCallMatrixCases.ps1')
    foreach ($mapping in @(
        @{source=(Join-Path $repo 'Source'); target=(Join-Path $stage 'Plugins\UnrealEnginePython\Source')},
        @{source=(Join-Path $PSScriptRoot 'UEP58Host\Source'); target=(Join-Path $stage 'Source')}
    )) {
        foreach ($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File) {
            $target = Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source, $source.FullName))
            if ((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw 'Native source differs' }
            Add-CallMatrixInput $source.FullName; Add-CallMatrixInput $target
        }
    }
    $version = Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.version'
    $id = (Get-Content -LiteralPath $version -Raw | ConvertFrom-Json).BuildId
    Add-CallMatrixInput $version
    foreach ($directory in @('Binaries\Win64','Plugins\UnrealEnginePython\Binaries\Win64')) {
        $root = Join-Path $stage $directory
        $manifest = Join-Path $root 'UnrealEditor.modules'
        if ((Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).BuildId -ne $id) { throw 'Module BuildId differs' }
        Add-CallMatrixInput $manifest
        foreach ($binary in Get-ChildItem -LiteralPath $root -Filter 'UnrealEditor-*.dll') { Add-CallMatrixInput $binary.FullName }
    }
    foreach ($test in $selectedCases) {
        $script = Join-Path $PSScriptRoot ('UEP58Host\Tests\' + $test.script)
        Add-CallMatrixInput $script
        $resultPath = Join-Path $output ($test.name + '.json')
        $logPath = Join-Path $output ($test.name + '.log')
        $arguments = @($StageProject, '-unattended', '-nop4', '-NullRHI', '-NoSound', '-NoSplash', '-UTF8Output', '-culture=en',
            '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging', '-notraceserver', '-trace=none',
            '-run=Py', $script, "-$($test.result)=$resultPath", "-abslog=$logPath")
        if ($test.name -ne 'signature-shared') { $arguments += '-DisablePython' }
        if ($test.name -eq 'named-outputs-negative') { $arguments += '-UEPNamedOutputNegative' }
        $handle = Start-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output $test.name) $test.name
        try {
            if (!$handle.process.WaitForExit(240000)) { throw 'Call matrix fixture timed out' }
            $process = Complete-UEPValidationProcess $handle
            $report = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
            $log = Get-Content -LiteralPath $logPath -Raw
            if ($report.status -ne 'passed') { throw "$($test.name) failed" }
            if ($test.name -eq 'mixin-exception') {
                if ($process.exit_code -notin @(0,1) -or !$report.no_original_after_python_exception -or !$report.recovered -or
                    ($report.native_signals -join ',') -ne '11,33,44') { throw 'Mixin exception recovery is incomplete' }
                if ($log -notmatch 'LogPython: Error: UEP_EXPECTED_MIXIN_EXCEPTION' -or $log -match 'Fatal error:|Assertion failed|Unhandled Exception|Ensure condition failed') { throw 'Unexpected exception boundary log' }
                foreach ($line in $log -split "`n" | Where-Object {$_ -match 'Log\w+:\s*Error:'}) {
                    if ($line -notmatch 'LogPython:\s*Error:\s*(UEP_EXPECTED_MIXIN_EXCEPTION|RuntimeError: UEP_EXPECTED_MIXIN_EXCEPTION|Traceback \(most recent call last\):|File ".*mixin_exception_validation\.py", line \d+, in BroadcastSignal)') {
                        throw 'Unexpected error in exception fixture'
                    }
                }
                if ($log -notmatch '(?s)UEP_MIXIN_EXCEPTION_PASSED.*Goodbye Python.*Log file closed') { throw 'Expected exception fixture did not shut down normally' }
            }
            elseif ($test.name -eq 'named-outputs-negative') {
                $expected=@('wrong-dictionary-type','missing-second-output','extra-key-after-conversion','valid-profile-recovery','original-restoration-after-rejection')
                if($process.exit_code -notin @(0,1) -or $report.full_acceptance -or ($report.cases -join '|') -ne ($expected -join '|')){throw 'Named-output rejection/recovery data incomplete'}
                $allowed='Invalid named outputs for mixin function Command|named mixin outputs require a dictionary|named mixin output omitted Command.Accepted|named mixin output dictionary has unexpected keys'
                if($log -match 'Fatal error:|Assertion failed|Unhandled Exception|Ensure condition failed'){throw 'Unexpected named-output crash/ensure'}
                foreach($line in $log -split "`n" | Where-Object {$_ -match 'Log\w+:\s*Error:'}){
                    if($line -notmatch ('LogPython:\s*Error:\s*('+$allowed+')\s*$')){throw 'Unexpected named-output negative error'}
                }
                foreach($reason in @('named mixin outputs require a dictionary','named mixin output omitted Command.Accepted','named mixin output dictionary has unexpected keys')){
                    if($log -notmatch [regex]::Escape($reason)){throw 'Expected named-output rejection absent'}
                }
                if($log -notmatch '(?s)UEP_MIXIN_NAMED_OUTPUT_PASSED.*Goodbye Python.*Log file closed'){throw 'Named-output negative fixture did not close normally'}
            }
            else {
                if ($process.exit_code -ne 0) { throw 'Non-exception fixture exited nonzero' }
                Assert-UEPFocusedLog $log $test.marker
                if ($test.name -eq 'delegate-broadcast') {
                    if (($report.signals -join ',') -ne '11,22,33' -or !$report.empty_delegate -or
                        !$report.rejected_parameter -or !$report.recovery -or !$report.no_late_delivery -or
                        $report.full_acceptance) { throw 'Native multicast broadcast proof incomplete' }
                }
                if ($test.name -eq 'callsite') { Assert-UEPMixinCallsiteData $report }
                if ($test.name -eq 'named-outputs') {
                    if($report.full_acceptance -or !$report.same_class -or @($report.cases).Count -ne 7){throw 'Named-output positive data incomplete'}
                }
            }
            $summary.tests += @{name=$test.name; status='passed'; process=$process; report=$resultPath}
            Write-Host "$($test.name) passed"
        }
        finally { Stop-UEPValidationProcess $handle; $handle.process.Dispose() }
    }
    foreach ($input in $summary.input_hashes) {
        if ((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256) { throw 'Call matrix input changed' }
    }
    $summary.status = 'passed'
}
catch { $summary.error = $_.ToString(); throw }
finally { $summary | ConvertTo-Json -Depth 9 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8 }
Write-Host "Focused call matrix: $($summary.status); $output"
