#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [switch]$CheckPlayableStartup,
    [ValidateRange(10,60)][int]$PlayableObservationSeconds=20
)

# No compilation, cooking, asset authoring, metadata repair or firewall changes.
# The first four weapon overlays must already be installed in the marked stage.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'LyraWeaponHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
if (!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))) { throw 'A marked disposable Lyra stage is required' }
if (Test-Path -LiteralPath $output) { throw 'Use a fresh weapon HUD evidence directory' }
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{
    schema_version=1; status='failed'; full_acceptance=$false; weapon_network_acceptance=$false
    cpp_compile_executed=$false; cook_package_executed=$false; assets_saved=$false
    core_commit=(& git -C $repo rev-parse HEAD); examples_commit=(& git -C (Join-Path $repo 'Demos') rev-parse HEAD)
    core_worktree=@(& git -C $repo status --short); examples_worktree=@(& git -C (Join-Path $repo 'Demos') status --short)
    native_binary_provenance='Existing staged binaries with source/hash parity; no fresh build proof'
    engine_build_id=$null; input_hashes=@(); reference_hashes=@(); process=$null
    differential=$null; playable_startup=$null; error=$null
}
$playableHandle=$null

function Add-WeaponInputHash {
    param([string]$Path)
    $summary.input_hashes += @{path=$Path; sha256=(Get-FileHash -LiteralPath $Path).Hash}
}

try {
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
    $versionPath=Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.version'
    $summary.engine_build_id=(Get-Content -LiteralPath $versionPath -Raw | ConvertFrom-Json).BuildId
    if ([string]::IsNullOrWhiteSpace($summary.engine_build_id)) { throw 'Engine BuildId is absent' }
    foreach ($path in @($versionPath,
        (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules'),
        (Join-Path $stage 'Binaries\Win64\UnrealEditor.modules'),
        (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules'),
        (Join-Path $stage 'Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor.modules'))) {
        if ((Get-Content -LiteralPath $path -Raw | ConvertFrom-Json).BuildId -ne $summary.engine_build_id) {
            throw "Stale module metadata; use official UBT separately: $path"
        }
        Add-WeaponInputHash $path
    }
    foreach ($mapping in @(
        @{source=(Join-Path $repo 'Source'); target=(Join-Path $stage 'Plugins\UnrealEnginePython\Source')},
        @{source=(Join-Path $repo 'Demos\UEPLyraIntegration\Plugins\UEPLyraBridge\Source'); target=(Join-Path $stage 'Plugins\UEPLyraBridge\Source')}
    )) {
        foreach ($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File) {
            $relative=[IO.Path]::GetRelativePath($mapping.source,$source.FullName)
            $destination=Join-Path $mapping.target $relative
            if ((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
                throw "Staged native source differs: $relative"
            }
            Add-WeaponInputHash $source.FullName
            Add-WeaponInputHash $destination
        }
    }
    foreach ($binary in @(
        (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe'),
        (Join-Path $stage 'Binaries\Win64\UnrealEditor-LyraGame.dll'),
        (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'),
        (Join-Path $stage 'Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor-UEPLyraBridge.dll'))) { Add-WeaponInputHash $binary }
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach ($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Content\Scripts') -Recurse -File -Filter '*.py') {
        $destination=Join-Path (Join-Path $stage 'Plugins\UnrealEnginePython') ([IO.Path]::GetRelativePath($repo,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $destination -Force
        Add-WeaponInputHash $source.FullName; Add-WeaponInputHash $destination
    }
    foreach ($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py') {
        $destination=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $destination -Force
        if ((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) { throw 'Script sync failed' }
        Add-WeaponInputHash $source.FullName
        Add-WeaponInputHash $destination
    }
    # This regression owns the original four widgets, not every later batch's
    # assets. Keep exact membership so repository growth does not disable it.
    $assetRelatives=@('Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_WeaponAmmoAndName.uasset',
        'Content\UEPMixins\DA_W_WeaponAmmoAndNameMixin.uasset')
    foreach ($kind in @('Pistol','Rifle','Shotgun')) {
        $assetRelatives += "Plugins\GameFeatures\ShooterCore\Content\Weapons\$kind\W_AmmoCounter_$kind.uasset"
        $assetRelatives += "Content\UEPMixins\DA_W_AmmoCounter_${kind}Mixin.uasset"
    }
    $assets=@($assetRelatives | ForEach-Object { Get-Item -LiteralPath (Join-Path $overlay $_) })
    if ($assets.Count -ne 8) { throw 'Expected the four first-batch BPs and four Mixin Sets' }
    foreach ($source in $assets) {
        $relative=[IO.Path]::GetRelativePath($overlay,$source.FullName)
        $destination=Join-Path $stage $relative
        if ((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
            throw "Weapon asset must be staged separately before testing: $relative"
        }
        Add-WeaponInputHash $source.FullName
        Add-WeaponInputHash $destination
        # The marker's reference is read-only; never save or sync into it.
        if ($relative.StartsWith('Plugins')) {
            $reference=Join-Path (Split-Path $marker.source -Parent) $relative
            $summary.reference_hashes += @{path=$reference; sha256=(Get-FileHash -LiteralPath $reference).Hash}
        }
    }
    $common=@('-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-stdout','-FullStdOutLogOutput')
    $editor=Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe'
    $reportPath=Join-Path $output 'weapon.json'
    $logPath=Join-Path $output 'weapon.log'
    $arguments=@($StageProject,'/Engine/Maps/Entry?game=/Script/Engine.GameModeBase','-game') + $common +
        @('-windowed','-ResX=1280','-ResY=720','-NoLoadingScreen',"-UEPLyraWeaponHUDResult=$reportPath","-abslog=$logPath")
    $summary.process=Invoke-UEPValidationProcess $editor $arguments $stage (Join-Path $output 'weapon') 'weapon-differential'
    $report=Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    Assert-LyraWeaponHUDData $report
    Assert-LyraWeaponLifecycleData $report
    $content=Get-Content -LiteralPath $logPath -Raw
    Assert-UEPFocusedLog $content 'UEP_WEAPON_HUD_DIFFERENTIAL_PASSED'
    if ($content -notmatch '(?s)UEP_WEAPON_HUD_DIFFERENTIAL_PASSED.*Goodbye Python.*Log file closed') {
        throw 'Weapon differential lacks normal Python/process shutdown evidence'
    }
    $image=[IO.Path]::GetFullPath($report.images[0])
    if ((Split-Path $image -Parent) -ne $output -or [IO.Path]::GetExtension($image) -ne '.png') { throw 'Unexpected weapon screenshot path' }
    $bytes=[IO.File]::ReadAllBytes($image)
    if ($bytes.Length -lt 100 -or ($bytes[0..7] -join ',') -ne '137,80,78,71,13,10,26,10') { throw 'Missing or invalid weapon screenshot' }
    $summary.differential=@{status='passed'; report=$reportPath; unreal_log=$logPath; case_count=@($report.cases).Count
        image=@{path=$image; sha256=(Get-FileHash -LiteralPath $image).Hash}; persisted_declarations_used=$true
        pixel_diff_executed=$false; fire_gas_reload_acceptance=$false}

    if ($CheckPlayableStartup) {
        $playableLog=Join-Path $output 'playable.log'
        # No UEP test flags: merely observe this owned normal Lyra process.
        $arguments=@($StageProject,'/ShooterMaps/Maps/L_Expanse?NumBots=0','-game') + $common +
            @('-NullRHI',"-abslog=$playableLog")
        $playableHandle=Start-UEPValidationProcess $editor $arguments $stage (Join-Path $output 'playable') 'playable-startup'
        $readyAt=$null
        do {
            if ($playableHandle.process.HasExited) { throw 'Normal playable startup exited without a user/test exit request' }
            if ($playableHandle.stopwatch.Elapsed.TotalSeconds -gt 240) { throw 'Normal playable startup timed out' }
            $content=if (Test-Path -LiteralPath $playableLog) { Get-Content -LiteralPath $playableLog -Raw } else { '' }
            if ($content -match '(?im)(Log\w+:\s*Error:|Fatal error:|Assertion failed|Unhandled Exception|Ensure condition failed)') {
                throw 'Normal playable log contains an unexpected error'
            }
            if ($content -match 'UEP_LYRA_PLAYABLE_BOOTSTRAP_READY' -and $content -match 'UEP_LYRA_WEAPON_HUD_REGISTERED 4' -and
                $content -match 'OnExperienceLoadComplete' -and $null -eq $readyAt) {
                $readyAt=$playableHandle.stopwatch.Elapsed.TotalSeconds
            }
            if ($content -match 'UEP_LYRA_SMOKE_|UEP_WEAPON_HUD_DIFFERENTIAL_|UEP_LYRA_NETWORK_|Goodbye Python') {
                throw 'Normal playable startup entered a validation/exit path'
            }
            Start-Sleep -Milliseconds 250
        } while ($null -eq $readyAt -or $playableHandle.stopwatch.Elapsed.TotalSeconds - $readyAt -lt $PlayableObservationSeconds)
        $summary.playable_startup=@{status='passed'; no_validation_flags=$true; native_experience_loaded=$true
            alive_observation_seconds=$PlayableObservationSeconds; unreal_log=$playableLog; rendered=$false
            intentional_owned_process_stop=$true; graceful_exit_tested=$false}
        Stop-UEPValidationProcess $playableHandle
        $summary.playable_startup.process=Complete-UEPValidationProcess $playableHandle
    }
    foreach ($hash in @($summary.input_hashes) + @($summary.reference_hashes)) {
        if ((Get-FileHash -LiteralPath $hash.path).Hash -ne $hash.sha256) { throw "Validation input/reference changed: $($hash.path)" }
    }
    $summary.status='passed'
}
catch { $summary.error=$_.ToString(); throw }
finally {
    if ($null -ne $playableHandle) { Stop-UEPValidationProcess $playableHandle; $playableHandle.process.Dispose() }
    $summary | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8
}
Write-Host "Focused weapon HUD: $($summary.status); $output"
