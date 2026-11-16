#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot = 'F:\UnrealEngine',
    [Parameter(Mandatory = $true)][string]$StageProject,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [string]$ReusePackageEvidence,
    [switch]$SkipPackagedNetwork,
    [ValidateRange(1024,65535)][int]$ServerPort = 7797,
    [ValidateRange(1,64)][int]$MaxParallelActions = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'LyraWeaponHUDContracts.ps1')
$repo = Split-Path $PSScriptRoot -Parent
$stage = Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output = [IO.Path]::GetFullPath($OutputDirectory)
$package = Join-Path $repo '.build\LyraValidation\Full\Package'
$packageMarker = Join-Path $package '.uep-lyra-full-package.json'
if (!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))) { throw 'Marked full Lyra stage required' }
if (Test-Path -LiteralPath $output) { throw 'Use a fresh evidence directory' }
New-Item -ItemType Directory -Path $output | Out-Null
$summary = [ordered]@{schema_version=1; status='failed'; scope='packaged-weapon-batch-1a'; full_acceptance=$false
    cpp_compile_executed=$false; cook_package_executed=$false; previous_package_backup=$null
    input_hashes=@(); build=$null; package=$null; differential=$null; network=$null; error=$null
    reused_package_evidence=$null; packaged_executable=$null; packaged_executable_sha256=$null
    packaged_network_status='not_run'; packaged_network_skipped=[bool]$SkipPackagedNetwork}
function Add-PackageInput([string]$Path) {
    $summary.input_hashes += @{path=$Path; sha256=(Get-FileHash -LiteralPath $Path).Hash}
}
try {
    foreach ($mapping in @(
        @{source=(Join-Path $repo 'Source'); target=(Join-Path $stage 'Plugins\UnrealEnginePython\Source')},
        @{source=(Join-Path $repo 'Demos\UEPLyraIntegration\Plugins\UEPLyraBridge\Source'); target=(Join-Path $stage 'Plugins\UEPLyraBridge\Source')}
    )) {
        foreach ($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File) {
            $target = Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source, $source.FullName))
            if ((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw 'Native source differs' }
            Add-PackageInput $source.FullName; Add-PackageInput $target
        }
    }
    $overlay = Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach ($mapping in @(
        @{source=(Join-Path $repo 'Content\Scripts'); target=(Join-Path $stage 'Plugins\UnrealEnginePython\Content\Scripts')},
        @{source=(Join-Path $overlay 'Content\Scripts'); target=(Join-Path $stage 'Content\Scripts')}
    )) {
        foreach ($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File -Filter '*.py') {
            $target = Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source, $source.FullName))
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $source.FullName -Destination $target -Force
            Add-PackageInput $source.FullName; Add-PackageInput $target
        }
    }
    foreach ($source in Get-ChildItem -LiteralPath $overlay -Recurse -File -Filter '*.uasset') {
        $target = Join-Path $stage ([IO.Path]::GetRelativePath($overlay, $source.FullName))
        if ((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw 'Packaged overlay asset differs' }
        Add-PackageInput $source.FullName; Add-PackageInput $target
    }
    Add-PackageInput $StageProject
    if ($ReusePackageEvidence) {
        $previous = Get-Content -LiteralPath $ReusePackageEvidence -Raw | ConvertFrom-Json
        if ($previous.schema_version -ne 1 -or $previous.scope -ne 'packaged-weapon-batch-1a' -or
            $previous.build.exit_code -ne 0 -or $previous.package.exit_code -ne 0) { throw 'No successful build/package evidence to reuse' }
        foreach ($input in $previous.input_hashes) {
            if ((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256) { throw 'Reused package inputs changed' }
        }
        $uat = Get-Content -LiteralPath $previous.package.stdout -Raw
        if ($uat -notmatch 'BUILD SUCCESSFUL' -or $uat -notmatch 'AutomationTool exiting with ExitCode=0' -or
            $uat -match '(?im)(Log\w+:\s*Error:|Fatal error:|Assertion failed|Unhandled Exception|Ensure condition failed)' -or
            $uat -match 'Registered Python mixin') { throw 'Referenced package log failed strict checks' }
        $internal = Join-Path $package 'Windows\LyraStarterGame\Binaries\Win64\LyraGame.exe'
        $runtimeHash = $null
        if ($previous.PSObject.Properties['packaged_executable_sha256'] -and $previous.packaged_executable_sha256) {
            $runtimeHash = $previous.packaged_executable_sha256
        }
        elseif ($previous.package.PSObject.Properties['executable_sha256']) { $runtimeHash = $previous.package.executable_sha256 }
        if (!(Test-Path -LiteralPath $packageMarker) -or !$runtimeHash -or
            (Get-FileHash -LiteralPath $internal).Hash -ne $runtimeHash) { throw 'Referenced package executable changed' }
        $summary.reused_package_evidence = @{path=$ReusePackageEvidence; sha256=(Get-FileHash -LiteralPath $ReusePackageEvidence).Hash}
        Write-Host 'Reuse unchanged successful archive; no build/cook'
    }
    else {
    $dotnet = Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\DotNet\10.0\win-x64\dotnet.exe'
    $ubt = Join-Path $EngineRoot 'Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll'
    $arguments = @($ubt, 'LyraGame', 'Win64', 'Development', "-Project=$StageProject", '-NoEngineChanges',
        '-WaitMutex', '-NoHotReload', '-NoUBA', "-MaxParallelActions=$MaxParallelActions", "-Log=$output\build-game.log")
    Write-Host 'Build current game target; Engine output changes prohibited'
    $summary.cpp_compile_executed = $true
    $summary.build = Invoke-UEPValidationProcess $dotnet $arguments $stage (Join-Path $output 'build-game') 'LyraGame build' 3600
    $buildLog = Get-Content -LiteralPath (Join-Path $output 'build-game.log') -Raw
    if ($buildLog -notmatch 'Result: Succeeded' -or $buildLog -match '(?im)(error (C\d+|LNK\d+)|warning (C\d+|LNK\d+))') { throw 'Game build has errors or compiler diagnostics' }
    if (Test-Path -LiteralPath $package) {
        if (!(Test-Path -LiteralPath $packageMarker) -or
            (Get-Content -LiteralPath $packageMarker -Raw | ConvertFrom-Json).purpose -ne 'UEP Lyra full-content disposable package') { throw 'Unmarked previous package' }
        $parent = Join-Path $repo '.build\LyraValidation\Full'
        $backup = Join-Path $parent ('PreviousPackage-' + [guid]::NewGuid().ToString('N'))
        foreach ($path in @($package, $backup)) {
            if (![IO.Path]::GetFullPath($path).StartsWith(([IO.Path]::GetFullPath($parent).TrimEnd('\') + '\'), [StringComparison]::OrdinalIgnoreCase)) { throw 'Package move escapes validation workspace' }
        }
        Move-Item -LiteralPath $package -Destination $backup
        $summary.previous_package_backup = $backup
    }
    New-Item -ItemType Directory -Path $package | Out-Null
    $marker = Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
    @{schema_version=1; purpose='UEP Lyra full-content disposable package'; source=$marker.source} | ConvertTo-Json | Set-Content -LiteralPath $packageMarker -Encoding utf8
    $env:uebp_LogFolder = Join-Path $output 'package-uat'
    $env:uebp_FinalLogFolder = $env:uebp_LogFolder
    New-Item -ItemType Directory -Path $env:uebp_LogFolder | Out-Null
    $arguments = @((Join-Path $EngineRoot 'Engine\Binaries\DotNET\AutomationTool\AutomationTool.dll'), 'BuildCookRun',
        "-project=$StageProject", '-noP4', '-utf8output', '-WaitForUATMutex', '-unattended', '-platform=Win64',
        '-clientconfig=Development', '-target=LyraGame', '-skipbuild', '-SkipBuildEditor', '-nocompile', '-nocompileeditor',
        '-cook', '-stage', '-pak', '-archive', "-archivedirectory=$package", '-map=/ShooterMaps/Maps/L_Expanse',
        '-MapsToCook=/ShooterMaps/Maps/L_Expanse+/Engine/Maps/Entry',
        '-AdditionalCookerOptions=-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging -notraceserver -SkipZenStore', '-nodebuginfo')
    Write-Host 'Cook and stage current weapon examples'
    $summary.cook_package_executed = $true
    $summary.package = Invoke-UEPValidationProcess $dotnet $arguments $stage (Join-Path $output 'package') 'Lyra cook/package' 7200
    $uat = Get-Content -LiteralPath (Join-Path $output 'package-stdout.log') -Raw
    if ($uat -notmatch 'BUILD SUCCESSFUL' -or $uat -notmatch 'AutomationTool exiting with ExitCode=0' -or
        $uat -match '(?im)(Log\w+:\s*Error:|Fatal error:|Assertion failed|Unhandled Exception|Ensure condition failed)' -or
        $uat -match 'Registered Python mixin') { throw 'Cook/package did not pass strict checks' }
    }
    $internal = Join-Path $package 'Windows\LyraStarterGame\Binaries\Win64\LyraGame.exe'
    $binaryDirectory = Join-Path $package 'Windows\LyraGame\Binaries\Win64'
    New-Item -ItemType Directory -Path $binaryDirectory -Force | Out-Null
    foreach ($file in Get-ChildItem -LiteralPath (Split-Path $internal -Parent) -Force) {
        Copy-Item -LiteralPath $file.FullName -Destination $binaryDirectory -Recurse -Force
    }
    $executable = Join-Path $binaryDirectory 'LyraGame.exe'
    if ((Get-FileHash -LiteralPath $internal).Hash -ne (Get-FileHash -LiteralPath $executable).Hash) { throw 'Stable executable differs from archive' }
    $summary.packaged_executable = $executable
    $summary.packaged_executable_sha256 = (Get-FileHash -LiteralPath $executable).Hash
    $reportPath = Join-Path $output 'weapon.json'
    $arguments = @("-basedir=$(Split-Path $internal -Parent)", '/Engine/Maps/Entry?game=/Script/Engine.GameModeBase', '-unattended', '-NoSound', '-NoSplash', '-NoLoadingScreen',
        '-culture=en', '-UTF8Output', '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging', '-notraceserver', '-trace=none',
        '-RenderOffscreen', '-windowed', '-ResX=1280', '-ResY=720', '-ExecCmds=t.MaxFPS 60', "-UEPLyraWeaponHUDResult=$reportPath", "-abslog=$output\weapon.log")
    Write-Host 'Packaged BP/Python differential and native GC validation'
    $summary.differential = Invoke-UEPValidationProcess $executable $arguments $binaryDirectory (Join-Path $output 'weapon') 'Packaged weapon differential' 300
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Assert-LyraWeaponHUDData $report
    Assert-LyraWeaponLifecycleData $report
    Assert-UEPFocusedLog (Get-Content -LiteralPath (Join-Path $output 'weapon.log') -Raw) 'UEP_WEAPON_HUD_DIFFERENTIAL_PASSED'
    if (!$SkipPackagedNetwork) {
    $networkDirectory = Join-Path $output 'Network'
    $arguments = @('-NoProfile', '-NonInteractive', '-File', (Join-Path $PSScriptRoot 'Run-UEP58FocusedNetworkValidation.ps1'),
        '-EngineRoot', $EngineRoot, '-StageProject', $StageProject, '-OutputDirectory', $networkDirectory,
        '-WeaponGameplay', '-PackagedExecutable', $executable, '-PackagedClientsOnly', '-ServerPort', "$ServerPort")
    Write-Host 'Editor dedicated server and two packaged clients, real weapon input'
    $summary.network = Invoke-UEPValidationProcess (Get-Process -Id $PID).Path $arguments $repo (Join-Path $output 'network') 'Packaged weapon network' 1100
    $network = Get-Content -LiteralPath (Join-Path $networkDirectory 'summary.json') -Raw | ConvertFrom-Json
    if ($network.status -ne 'passed' -or !$network.weapon_network_acceptance -or !$network.packaged_runtime) { throw 'Packaged weapon network failed' }
    $summary.packaged_network_status = 'passed'
    }
    foreach ($input in $summary.input_hashes) {
        if ((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256) { throw "Input changed during package validation: $($input.path)" }
    }
    $summary.status = 'passed'
}
catch { $summary.error = $_.ToString(); throw }
finally { $summary | ConvertTo-Json -Depth 9 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8 }
Write-Host "Packaged weapon batch validation: $($summary.status); $output"
