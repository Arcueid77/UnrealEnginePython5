[CmdletBinding()]
param(
    [string]$EngineRoot = 'F:\UnrealEngine',
    [Parameter(Mandatory = $true)][string]$NativeProject,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [ValidateSet('Mixin', 'PythonFirst')][string[]]$Variants = @('Mixin', 'PythonFirst')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo = Split-Path $PSScriptRoot -Parent
$nativeStage = Split-Path ([IO.Path]::GetFullPath($NativeProject)) -Parent
$stage = Join-Path $repo '.build\Demos\UEPPythonThirdPerson'
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (!(Test-Path -LiteralPath (Join-Path $nativeStage '.uep-lyra-full-stage.json'))) { throw 'Marked source-binary Lyra stage required' }
if (!(Test-Path -LiteralPath (Join-Path $stage '.uep-demo-stage'))) { throw 'Prepare a marked Third Person stage first' }
if (Test-Path -LiteralPath $output) { throw 'Use a fresh evidence directory' }
New-Item -ItemType Directory -Path $output | Out-Null
$engineVersion = Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.version'
$summary = [ordered]@{schema_version=1; status='failed'; cpp_compile_executed=$false; cook_package_executed=$false
    native_binary_provenance='UEP Editor modules reused from source-matching Lyra stage; Third Person native host reused'
    engine_version_hash=(Get-FileHash -LiteralPath $engineVersion).Hash; native_source_hashes=@(); input_hashes=@(); variants=@(); error=$null}
foreach ($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $repo 'Demos/Run-UEPThirdPersonDemo.ps1'))) {
    $summary.input_hashes += @{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
}
function Save-ThirdPersonInput([string]$Path,[string]$Lane) {
    $relative=[IO.Path]::GetRelativePath($stage,$Path)
    if ($relative.StartsWith('..') -or [IO.Path]::IsPathRooted($relative)) { throw 'Frozen input must be inside the owned demo stage' }
    $frozen=Join-Path $Lane ('inputs/'+$relative)
    New-Item -ItemType Directory -Path (Split-Path $frozen -Parent) -Force|Out-Null
    Copy-Item -LiteralPath $Path -Destination $frozen
    return @{path=$frozen;native_input_path=$Path;sha256=(Get-FileHash -LiteralPath $frozen).Hash}
}
try {
    foreach ($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File) {
        $relative = [IO.Path]::GetRelativePath((Join-Path $repo 'Source'), $source.FullName)
        $hash = (Get-FileHash -LiteralPath $source.FullName).Hash
        if ($hash -ne (Get-FileHash -LiteralPath (Join-Path $nativeStage "Plugins\UnrealEnginePython\Source\$relative")).Hash) { throw "Source binary stage differs: $relative" }
        $summary.native_source_hashes += @{path=$source.FullName; sha256=$hash}
        $summary.input_hashes += @{path=$source.FullName;sha256=$hash}
    }
    foreach ($variant in $Variants) {
        $lane = Join-Path $output $variant
        New-Item -ItemType Directory -Path $lane | Out-Null
        $prepare = @('-NoProfile', '-NonInteractive', '-File', (Join-Path $repo 'Demos\Run-UEPThirdPersonDemo.ps1'),
            '-EngineRoot', $EngineRoot, '-PluginRoot', $repo, '-Variant', $variant, '-Mode', 'Prepare', '-Incremental')
        $null = Invoke-UEPValidationProcess (Get-Process -Id $PID).Path $prepare $repo (Join-Path $lane 'prepare') 'Prepare owned Third Person stage' 120
        $binaryRoot = Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64'
        New-Item -ItemType Directory -Path $binaryRoot -Force | Out-Null
        $binaries = @()
        foreach ($binary in Get-ChildItem -LiteralPath (Join-Path $nativeStage 'Plugins\UnrealEnginePython\Binaries\Win64') -Filter 'UnrealEditor-*.dll') {
            $target = Join-Path $binaryRoot $binary.Name
            Copy-Item -LiteralPath $binary.FullName -Destination $target -Force
            $binaries += Save-ThirdPersonInput $target $lane
        }
        $hostDll = Join-Path $stage 'Binaries\Win64\UnrealEditor-UEPPythonThirdPerson.dll'
        $binaries += Save-ThirdPersonInput $hostDll $lane
        $metadataPath = Join-Path $stage 'Intermediate\Build\Win64\x64\UEPPythonThirdPersonEditor\Development\TargetMetadata.json'
        $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
        $prefix = $stage.TrimEnd('\') + '\'
        if ($null -ne $metadata.Version -or !$metadata.ReceiptFile.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Metadata is not project-only' }
        foreach ($entry in $metadata.FileToManifest.PSObject.Properties) {
            if (!$entry.Name.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Metadata would write outside the owned demo' }
        }
        $metadataArguments = @((Join-Path $EngineRoot 'Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll'),
            '-Mode=WriteMetadata', "-Input=$metadataPath", '-Version=2')
        $null = Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\DotNet\10.0\win-x64\dotnet.exe') $metadataArguments $stage (Join-Path $lane 'project-metadata') 'Refresh owned project metadata' 120
        if ((Get-FileHash -LiteralPath $engineVersion).Hash -ne $summary.engine_version_hash) { throw 'Engine version changed' }
        foreach ($manifest in @((Join-Path $stage 'Binaries/Win64/UnrealEditor.modules'),(Join-Path $binaryRoot 'UnrealEditor.modules'))) {
            if ((Get-Content -LiteralPath $manifest -Raw|ConvertFrom-Json).BuildId -ne (Get-Content -LiteralPath $engineVersion -Raw|ConvertFrom-Json).BuildId) { throw 'Third Person native module BuildId differs' }
            $binaries += Save-ThirdPersonInput $manifest $lane
        }
        $url = '/Game/ThirdPerson/Lvl_ThirdPerson'
        $smokeFlag = '-UEPMixinThirdPersonSmokeResult=' + (Join-Path $lane 'smoke.json')
        if ($variant -eq 'PythonFirst') {
            $url += '?game=/Engine/Transient.UEPThirdPersonGameMode'
            $smokeFlag = '-UEPPythonThirdPersonSmokeResult=' + (Join-Path $lane 'smoke.json')
        }
        $scripts = @()
        foreach ($root in @((Join-Path $stage 'Content\Scripts'), (Join-Path $stage 'Plugins\UnrealEnginePython\Content\Scripts'))) {
            foreach ($script in Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.py') {
                $scripts += Save-ThirdPersonInput $script.FullName $lane
            }
        }
        $arguments = @((Join-Path $stage 'UEPPythonThirdPerson.uproject'), $url, '-game', '-RenderOffscreen', '-windowed', '-ResX=1280', '-ResY=720',
            '-unattended', '-nop4', '-NoSound', '-NoSplash', '-UTF8Output', '-DisablePython', '-culture=en',
            '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,ResonanceAudio', '-notraceserver', '-trace=none',
            $smokeFlag, "-UEPThirdPersonVisualDirectory=$lane", "-abslog=$lane\smoke.log")
        Write-Host "Rendered $variant gameplay regression"
        $process = Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $lane 'smoke') $variant 300
        $report = Get-Content -LiteralPath (Join-Path $lane 'smoke.json') -Raw | ConvertFrom-Json
        $visible = Get-Content -LiteralPath (Join-Path $lane 'visible.json') -Raw | ConvertFrom-Json
        if ($report.status -ne 'passed' -or $visible.status -ne 'passed' -or @($visible.frames).Count -ne 3) { throw "$variant gameplay or images failed" }
        if ($report.movement_distance -le 25 -or $report.look_delta -le 0.1) { throw 'Native input movement/look proof incomplete' }
        if ($variant -eq 'Mixin') {
            if ($report.schema_version -ne 4 -or $report.jump_height -le 10 -or $report.character_class -ne 'BP_ThirdPersonCharacter_C') { throw 'Mixin jump/class proof incomplete' }
        }
        elseif ($report.schema_version -ne 5 -or !$report.jump_observed -or $report.map_travel_count -ne 1) { throw 'Python-first jump/travel proof incomplete' }
        $marker = 'UEP_MIXIN_THIRD_PERSON_SMOKE_PASSED'
        if ($variant -eq 'PythonFirst') { $marker = 'UEP_PYTHON_THIRD_PERSON_SMOKE_PASSED' }
        $log = Get-Content -LiteralPath (Join-Path $lane 'smoke.log') -Raw
        Assert-UEPFocusedLog $log $marker
        if ($log -notmatch ('(?s)' + [regex]::Escape($marker) + '.*Goodbye Python.*UEP_THIRD_PERSON_VISIBLE_SHUTDOWN_PASSED.*Log file closed')) { throw 'Gameplay completion/exit order is incomplete' }
        foreach ($input in @($binaries) + @($scripts)) {
            if ((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256 -or (Get-FileHash -LiteralPath $input.native_input_path).Hash -ne $input.sha256) { throw "Input changed during $variant" }
        }
        $summary.variants += @{variant=$variant; status='passed'; process=$process; binary_hashes=$binaries; script_hashes=$scripts
            smoke=(Join-Path $lane 'smoke.json'); visible=(Join-Path $lane 'visible.json')}
    }
    foreach ($input in $summary.input_hashes) {
        if ((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256) { throw 'Third Person validation entrypoint changed' }
    }
    $summary.status = 'passed'
}
catch { $summary.error = $_.ToString(); throw }
finally { $summary | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8 }
Write-Host "Third Person rendered regressions: $($summary.status); $output"
