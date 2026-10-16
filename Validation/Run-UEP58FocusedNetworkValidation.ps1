[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet(2)][int]$ClientCount=2,
    [switch]$WeaponGameplay,
    [switch]$CombatHUD,
    [switch]$DebugSpread,
    [switch]$ProductionReticles,
    [switch]$ReticleHosts,
    [switch]$AbilityProgress,
    [switch]$AbilityFailure,
    [switch]$DashCooldown,
    [switch]$RespawnTimer,
    [switch]$QuickBarSlots,
    [switch]$Nameplates,
    [switch]$NameplateOriginalTrace,
    [switch]$HealthbarPublicEntries,
    [string]$NameplateAssetAuthoringDirectory,
    [string]$NameplateTransportRevisionDirectory,
    [string]$PackagedExecutable,
    [switch]$PackagedClientsOnly,
    [ValidateRange(1024,65535)][int]$ServerPort=7788,
    [ValidateRange(60,900)][int]$RuntimeTimeoutSeconds=900
)

# This entry never invokes UBT/UAT, repairs metadata, saves assets or changes Firewall.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($CombatHUD -and (!$WeaponGameplay -or $PackagedExecutable)) {
    throw 'CombatHUD requires WeaponGameplay in the current Editor network lane; no new package is implied'
}
if ($DebugSpread -and !$CombatHUD) { throw 'DebugSpread requires the opt-in CombatHUD lane' }
if ($ProductionReticles -and !$CombatHUD) { throw 'ProductionReticles requires the opt-in CombatHUD lane' }
if ($ReticleHosts -and !$ProductionReticles) { throw 'ReticleHosts requires the opt-in ProductionReticles lane' }
if ($AbilityProgress -and !$CombatHUD) { throw 'AbilityProgress requires the opt-in CombatHUD lane' }
if ($AbilityFailure -and !$CombatHUD) { throw 'AbilityFailure requires the opt-in CombatHUD lane' }
if ($DashCooldown -and !$CombatHUD) { throw 'DashCooldown requires the opt-in CombatHUD lane' }
if ($RespawnTimer -and !$CombatHUD) { throw 'RespawnTimer requires the opt-in CombatHUD lane' }
if ($QuickBarSlots -and !$CombatHUD) { throw 'QuickBarSlots requires the opt-in CombatHUD lane' }
if ($Nameplates -and (!$CombatHUD -or !$NameplateAssetAuthoringDirectory)) { throw 'Nameplates requires CombatHUD and accepted component authoring' }
if ($NameplateOriginalTrace -and !$Nameplates) { throw 'Original nameplate diagnostic requires Nameplates' }
if ($HealthbarPublicEntries -and !$WeaponGameplay) { throw 'Public healthbar entries require the real-weapon restart lane' }
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'UEPNameplateAssetProvenance.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
if (!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))) { throw 'Unmarked Lyra stage' }
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+[IO.Path]::GetFullPath($StageProject)+'*')}).Count){throw 'Matching stage already running'}
if (Test-Path -LiteralPath $output) { throw 'Use a fresh network evidence directory' }
New-Item -ItemType Directory -Path $output | Out-Null
$runId=[guid]::NewGuid().ToString('N')
$handles=@{}
$summary=[ordered]@{
    schema_version=1; status='failed'; scope='loopback-dedicated-two-clients'; run_id=$runId
    required_client_count=2; multi_client_acceptance=$false; full_acceptance=$false
    weapon_gameplay=[bool]$WeaponGameplay; weapon_network_acceptance=$false
    combat_hud=[bool]$CombatHUD; combat_hud_acceptance=$false; combat_images=@()
    debug_spread=[bool]$DebugSpread; debug_spread_acceptance=$false
    production_reticles=[bool]$ProductionReticles; production_reticle_acceptance=$false
    reticle_hosts=[bool]$ReticleHosts; reticle_host_acceptance=$false
    ability_progress=[bool]$AbilityProgress; ability_progress_acceptance=$false
    ability_failure=[bool]$AbilityFailure; ability_failure_acceptance=$false
    dash_cooldown=[bool]$DashCooldown; dash_cooldown_acceptance=$false
    respawn_timer=[bool]$RespawnTimer; respawn_timer_acceptance=$false
    quickbar_slots=[bool]$QuickBarSlots; quickbar_slots_acceptance=$false
    nameplates=[bool]$Nameplates; nameplate_acceptance=$false
    diagnostic_original_remove_wrapper=[bool]$NameplateOriginalTrace
    acceptance_eligible=(!$NameplateOriginalTrace)
    healthbar_public_entries=[bool]$HealthbarPublicEntries; healthbar_public_entry_acceptance=$false
    healthbar_public_entry_counts=$null
    native_interaction_producer_tested=$false; replicated_duration_message_tested=$false
    client_render_budget=$null; visual_fidelity_acceptance=$false
    cpp_compile_executed=$false; cook_package_executed=$false; rendered=$false
    core_commit=(& git -C $repo rev-parse HEAD); examples_commit=(& git -C (Join-Path $repo 'Demos') rev-parse HEAD)
    core_worktree=@(& git -C $repo status --short); examples_worktree=@(& git -C (Join-Path $repo 'Demos') status --short)
    native_source_hashes=@(); input_hashes=@(); processes=@{}; hud_audit=$null; host_tests=$null; contract_tests=$null
    engine_build_id=$null; protocol_validation=$null; error=$null
    engine_version=$null; python_version=$null; asset_registry_primed=$false
    packaged_runtime=$false; packaged_executable=$null
    packaged_server=$false; packaged_topology=$null
}

function Write-NetworkJSON {
    param([string]$Path, [object]$Value)
    New-Item -ItemType Directory -Path (Split-Path $Path -Parent) -Force | Out-Null
    $temporary=$Path + '.driver.tmp'
    $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $temporary -Encoding utf8
    for($attempt=0; $attempt -lt 10; $attempt++) {
        try {[IO.File]::Move($temporary,$Path,$true); return}
        catch [IO.IOException] {if($attempt -eq 9){throw}; Start-Sleep -Milliseconds 5}
    }
}

function Read-NetworkJSON {
    param([string]$Path)
    for($attempt=0; $attempt -lt 10; $attempt++) {
        $reader=$null; $stream=$null
        try {
            $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
            $reader=[IO.StreamReader]::new($stream)
            return ($reader.ReadToEnd() | ConvertFrom-Json)
        }
        catch [IO.IOException] {if($attempt -eq 9){throw}; Start-Sleep -Milliseconds 5}
        finally {if($null -ne $reader){$reader.Dispose()}elseif($null -ne $stream){$stream.Dispose()}}
    }
}

function Add-InputHash {
    param([string]$Path)
    $summary.input_hashes += @{path=[IO.Path]::GetFullPath($Path);sha256=(Get-FileHash -LiteralPath $Path).Hash}
}

function Assert-NetworkPeer {
    param([string]$Peer)
    $report=Read-NetworkJSON (Join-Path $output ($Peer + '.json'))
    $schema=if($WeaponGameplay){4}else{1}
    if ($report.run_id -ne $runId -or $report.peer -ne $Peer -or $report.network_schema_version -ne $schema) { throw 'Peer report identity mismatch' }
    if ($report.status -eq 'failed') { throw "Network peer $Peer failed: $($report.error)" }
    $mode=if($Peer -eq 'server'){'server'}else{'client'}
    Assert-LyraHUDActiveState -HUD $report.hud -ExpectedMode $mode
    Assert-LyraHUDShutdownReport -Report $report
    $log=Get-Content -LiteralPath (Join-Path $output ($Peer + '.log')) -Raw
    Assert-UEPFocusedLog $log 'UEP_LYRA_HUD_SHUTDOWN_PASSED' -RequirePythonExit
    Assert-LyraHUDShutdownLog $log
    if ($report.mode -ne $mode -or $report.status -ne 'passed') { throw 'Peer did not pass after exit' }
}

function Start-NetworkPeer {
    param([string]$Peer)
    if ($handles.ContainsKey($Peer)) { throw 'Duplicate process launch' }
    $mode=if($Peer -eq 'server'){'server'}else{'client'}
    $url=if($mode -eq 'server'){'/ShooterMaps/Maps/L_Expanse?NumBots=3'}else{
        "127.0.0.1:${ServerPort}"
    }
    $entry = @($StageProject, $url)
    $usesPackage = $PackagedExecutable -and !($mode -eq 'server' -and $PackagedClientsOnly)
    if ($usesPackage) { $entry = @("-basedir=$packagedBaseDirectory", $url) }
    $arguments=$entry + $common + @('-Multiprocess','-UEPLyraMultiClient','-UEPLyraHUDSlice',
        "-UEPLyraMode=$mode","-UEPLyraNetPeer=$Peer","-UEPLyraNetRun=$runId","-UEPLyraNetDirectory=$output",
        "-abslog=$(Join-Path $output ($Peer + '.log'))")
    # This lane tests native game networking, not RemoteSession's unrelated
    # auto-host service (whose shared default port conflicts across processes).
    if($Nameplates){$arguments=@($arguments|ForEach-Object {if($_ -eq '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging'){'-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession'}else{$_}})}
    if($mode -eq 'server'){$arguments+=@('-server',"-port=$ServerPort",'-multihome=127.0.0.1')}else{$arguments+='-game'}
    if($WeaponGameplay) {
        $arguments+='-UEPLyraWeaponNetwork'
        if ($CombatHUD) { $arguments+='-UEPLyraCombatHUD' }
        if ($DebugSpread) { $arguments+='-UEPLyraDebugSpread' }
        if ($ProductionReticles) { $arguments+='-UEPLyraProductionReticles' }
        if ($ReticleHosts) { $arguments+='-UEPLyraReticleHosts' }
        if ($AbilityProgress) { $arguments+='-UEPLyraAbilityProgress' }
        if ($AbilityFailure) { $arguments+='-UEPLyraAbilityFailure' }
        if ($DashCooldown) { $arguments+='-UEPLyraDashCooldown' }
        if ($QuickBarSlots) { $arguments+='-UEPLyraQuickBarSlots' }
        if ($Nameplates) { $arguments+='-UEPLyraNameplates' }
        if ($NameplateOriginalTrace) { $arguments+='-UEPNameplateOriginalTrace' }
        if ($RespawnTimer) {
            $arguments+='-UEPLyraRespawnTimer'
            if($mode -eq 'client'){$arguments=@($arguments | Where-Object {$_ -ne '-NoSound'})}
        }
        if($mode -eq 'client') {
            $arguments=@($arguments | Where-Object {$_ -ne '-NullRHI'}) + @('-RenderOffscreen','-windowed','-ResX=640','-ResY=360')
            if($Nameplates) {
                # Three editor processes must fit the 32 GB validation host.
                # This lane proves gameplay/UI state, not high-quality rendering.
                $budget='t.MaxFPS 30,sg.ViewDistanceQuality 0,sg.AntiAliasingQuality 0,sg.ShadowQuality 0,sg.GlobalIlluminationQuality 0,sg.ReflectionQuality 0,sg.PostProcessQuality 0,sg.TextureQuality 0,sg.EffectsQuality 0,sg.FoliageQuality 0,r.Streaming.PoolSize 256'
                $arguments=@($arguments | Where-Object {$_ -notlike '-ExecCmds=*'}) + "-ExecCmds=$budget"
                $summary.client_render_budget=$budget
            }
        }
    }
    $executable = $runtimeExecutable
    $directory = $runtimeDirectory
    if ($mode -eq 'server' -and $PackagedClientsOnly) { $executable = $editor; $directory = $stage }
    $handles[$Peer]=Start-UEPValidationProcess $executable $arguments $directory (Join-Path $output $Peer) $Peer
    Write-Host "Started network peer $Peer, PID $($handles[$Peer].process.Id)"
}

try {
    $engineBuildVersion=Join-Path $EngineRoot 'Engine\Build\Build.version'
    $buildVersion=Read-NetworkJSON $engineBuildVersion
    if($buildVersion.MajorVersion -ne 5 -or $buildVersion.MinorVersion -ne 8){throw 'UE 5.8 is required'}
    $summary.engine_version="$($buildVersion.MajorVersion).$($buildVersion.MinorVersion).$($buildVersion.PatchVersion)"
    Add-InputHash $engineBuildVersion
    foreach($script in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $repo 'Demos\UEPLyraIntegration\Tools\validate_network_reports.py'),(Join-Path $repo 'Demos\UEPLyraIntegration\Tools\audit_hud.py'),(Join-Path $PSScriptRoot 'Tests\Test-LyraHUDContracts.ps1'))){Add-InputHash $script}
    foreach($test in Get-ChildItem -LiteralPath (Join-Path $repo 'Demos\UEPLyraIntegration\Tests') -Filter '*.py' -File){Add-InputHash $test.FullName}
    $engineVersionPath=Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.version'
    $summary.engine_build_id=(Get-Content -LiteralPath $engineVersionPath -Raw | ConvertFrom-Json).BuildId
    if ([string]::IsNullOrWhiteSpace($summary.engine_build_id)) { throw 'Missing Engine BuildId' }
    Add-InputHash $engineVersionPath
    foreach($manifest in @((Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules'),
        (Join-Path $stage 'Binaries\Win64\UnrealEditor.modules'),
        (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules'),
        (Join-Path $stage 'Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor.modules'))) {
        if ((Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).BuildId -ne $summary.engine_build_id) { throw "Stale module metadata: $manifest" }
        Add-InputHash $manifest
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins\UnrealEnginePython\Source')},
        @{source=(Join-Path $repo 'Demos\UEPLyraIntegration\Plugins\UEPLyraBridge\Source');target=(Join-Path $stage 'Plugins\UEPLyraBridge\Source')})) {
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File) {
            $relative=[IO.Path]::GetRelativePath($mapping.source,$source.FullName)
            $target=Join-Path $mapping.target $relative
            $hash=(Get-FileHash -LiteralPath $source.FullName).Hash
            if ((Get-FileHash -LiteralPath $target).Hash -ne $hash) { throw "Native source mismatch: $relative" }
            $summary.native_source_hashes+=@{source=$source.FullName;target=$target;sha256=$hash}
        }
    }
    foreach($binary in @((Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-NetCore.dll'),
        (Join-Path $stage 'Binaries\Win64\UnrealEditor-LyraGame.dll'),
        (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'),
        (Join-Path $stage 'Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor-UEPLyraBridge.dll'))) {Add-InputHash $binary}
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    if($Nameplates){
        $provenance=Get-UEPNameplateAssetProvenance $NameplateAssetAuthoringDirectory $NameplateTransportRevisionDirectory $stage $overlay
        foreach($asset in $provenance.assets){Add-InputHash $asset.stage;Add-InputHash $asset.overlay}
        foreach($path in $provenance.evidence){Add-InputHash $path}
        Add-InputHash (Join-Path $PSScriptRoot 'UEPNameplateAssetProvenance.ps1')
        foreach($relative in @('Content\UI\Indicators\W_Nameplate.uasset','Content\UEPMixins\DA_W_NameplateMixin.uasset')){
            $source=Join-Path $overlay $relative;$target=Join-Path $stage $relative
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Nameplate Widget asset mismatch'}
            Add-InputHash $source;Add-InputHash $target
        }
        $nameplateMarker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
        foreach($name in @('NameplateSource','NameplateManagerComponent','W_Nameplate')){
            Add-InputHash (Join-Path (Split-Path $nameplateMarker.source -Parent) "Content\UI\Indicators\$name.uasset")
        }
    }
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Content\Scripts') -Recurse -File -Filter '*.py') {
        $target=Join-Path (Join-Path $stage 'Plugins\UnrealEnginePython') ([IO.Path]::GetRelativePath($repo,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-InputHash $source.FullName; Add-InputHash $target
    }
    foreach($relative in @('Content\UI\Hud\W_Healthbar.uasset','Content\UEPMixins\DA_LyraHealthbarMixin.uasset')) {
        $source=Join-Path $overlay $relative; $target=Join-Path $stage $relative
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw "Asset mismatch: $relative"}
        Add-InputHash $source; Add-InputHash $target
    }
    if($WeaponGameplay) {
        $summary.scope='loopback-dedicated-two-clients-real-weapon-input'
        $summary.rendered=$true
        foreach($source in @((Get-ChildItem -LiteralPath (Join-Path $overlay 'Plugins') -Recurse -File -Filter '*.uasset')) +
            @(Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\UEPMixins') -File -Filter 'DA_W_*Mixin.uasset')) {
            $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
            if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Weapon asset mismatch'}
            Add-InputHash $source.FullName; Add-InputHash $target
        }
    }
    if($ProductionReticles -or $AbilityProgress -or $AbilityFailure -or $DashCooldown -or $RespawnTimer -or $QuickBarSlots -or $Nameplates) {
        $relative='Content\UEPInterop\BP_UEPGameplayMessages.uasset'
        $source=Join-Path $overlay $relative; $target=Join-Path $stage $relative
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Typed message adapter differs'}
        Add-InputHash $source; Add-InputHash $target
    }
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
    if($Nameplates) {
        $relative='Plugins\GameFeatures\ShooterCore\Content\Experiences\LAS_ShooterGame_StandardComponents.uasset'
        $staged=Join-Path $stage $relative
        $reference=Join-Path (Split-Path $marker.source -Parent) $relative
        if((Get-FileHash -LiteralPath $staged).Hash -ne (Get-FileHash -LiteralPath $reference).Hash){throw 'Native nameplate component placement changed'}
        Add-InputHash $staged; Add-InputHash $reference
    }
    Add-InputHash (Join-Path (Split-Path $marker.source -Parent) 'Content\UI\Hud\W_Healthbar.uasset')
    if ($WeaponGameplay) {
        foreach ($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Plugins') -Recurse -File -Filter '*.uasset') {
            $reference=Join-Path (Split-Path $marker.source -Parent) ([IO.Path]::GetRelativePath($overlay,$source.FullName))
            Add-InputHash $reference
        }
    }
    Add-InputHash $StageProject
    foreach($config in Get-ChildItem -LiteralPath (Join-Path $stage 'Config') -Recurse -File) {Add-InputHash $config.FullName}
    $scripts=Join-Path $overlay 'Content\Scripts'
    foreach($source in Get-ChildItem -LiteralPath $scripts -Recurse -File -Filter '*.py') {
        $target=Join-Path (Join-Path $stage 'Content\Scripts') ([IO.Path]::GetRelativePath($scripts,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-InputHash $source.FullName; Add-InputHash $target
    }
    $python=Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\Python3\Win64\python.exe'
    $editor=Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
    $runtimeExecutable = $editor
    $runtimeDirectory = $stage
    if ($PackagedExecutable) {
        if (!$WeaponGameplay) { throw 'Packaged network lane currently requires WeaponGameplay' }
        if (!$PackagedClientsOnly) { throw 'LyraGame is a Game target; use PackagedClientsOnly with the Editor dedicated server' }
        $runtimeExecutable = [IO.Path]::GetFullPath($PackagedExecutable)
        $runtimeDirectory = Split-Path $runtimeExecutable -Parent
        $package = Join-Path $repo '.build\LyraValidation\Full\Package'
        $expectedExecutable = Join-Path $package 'Windows\LyraGame\Binaries\Win64\LyraGame.exe'
        $packagedBaseDirectory = Join-Path $package 'Windows\LyraStarterGame\Binaries\Win64'
        if ($runtimeExecutable -ne $expectedExecutable -or !(Test-Path -LiteralPath (Join-Path $package '.uep-lyra-full-package.json'))) {
            throw 'Use the marked stable package executable covered by the existing firewall rule'
        }
        foreach ($mapping in @(
            @{source=(Join-Path $overlay 'Content\Scripts'); target=(Join-Path $package 'Windows\LyraStarterGame\Content\Scripts')},
            @{source=(Join-Path $repo 'Content\Scripts'); target=(Join-Path $package 'Windows\LyraStarterGame\Plugins\UnrealEnginePython\Content\Scripts')}
        )) {
            foreach ($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File -Filter '*.py') {
                $target = Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source, $source.FullName))
                if ((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw 'Packaged Python input differs' }
                Add-InputHash $target
            }
        }
        Add-InputHash $runtimeExecutable
        $summary.packaged_runtime = $true
        $summary.packaged_executable = $runtimeExecutable
        $summary.packaged_topology = 'Editor dedicated server with two packaged Game clients'
    }
    elseif ($PackagedClientsOnly) { throw 'PackagedClientsOnly requires PackagedExecutable' }
    $env:PYTHONIOENCODING='utf-8'; $env:PYTHONDONTWRITEBYTECODE='1'
    $summary.python_version=(& $python -B -c 'import platform; print(platform.python_version())').Trim()
    if($LASTEXITCODE -ne 0 -or $summary.python_version -notlike '3.11.*'){throw 'Bundled CPython 3.11 is required'}
    Add-InputHash $python
    $summary.host_tests=Invoke-UEPValidationProcess $python @('-B','-m','unittest','discover','-s',(Join-Path $repo 'Demos\UEPLyraIntegration\Tests'),'-p','test_*.py','-v') $repo (Join-Path $output 'host-tests') 'Python host tests' 60
    $summary.contract_tests=Invoke-UEPValidationProcess (Get-Process -Id $PID).Path @('-NoProfile','-File',(Join-Path $PSScriptRoot 'Tests\Test-LyraHUDContracts.ps1')) $repo (Join-Path $output 'contract-tests') 'PowerShell contract tests' 60
    $common=@('-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en',
        '-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging',
        '-notraceserver','-trace=none','-stdout','-FullStdOutLogOutput','-ExecCmds=t.MaxFPS 60')
    $cache=Join-Path $stage 'Intermediate\CachedAssetRegistry'
    if (!(Test-Path -LiteralPath $cache) -or @(Get-ChildItem -LiteralPath $cache -Recurse -File).Count -eq 0) {
        $prime=Join-Path $repo 'Demos\UEPLyraIntegration\Tools\prime_asset_registry.py'
        $null=Invoke-UEPValidationProcess $editor (@($StageProject)+$common+@('-AssetGatherAll=true','-AssetRegistryDiscoveryCache=AlwaysWrite','-run=Py',$prime,"-UEPLyraAssetRegistryPrimeResult=$(Join-Path $output 'prime.json')","-abslog=$(Join-Path $output 'prime.log')")) $stage (Join-Path $output 'prime') 'Asset registry prime' 600
        if((Get-Content -LiteralPath (Join-Path $output 'prime.json') -Raw | ConvertFrom-Json).status -ne 'passed'){throw 'Registry prime failed'}
        $summary.asset_registry_primed=$true
    }
    $audit=Join-Path $repo 'Demos\UEPLyraIntegration\Tools\audit_hud.py'
    $null=Invoke-UEPValidationProcess $editor (@($StageProject)+$common+@('-run=Py',$audit,"-UEPLyraHUDAuditResult=$(Join-Path $output 'hud-audit.json')","-abslog=$(Join-Path $output 'hud-audit.log')")) $stage (Join-Path $output 'hud-audit') 'HUD audit' 300
    $auditReport=Get-Content -LiteralPath (Join-Path $output 'hud-audit.json') -Raw | ConvertFrom-Json
    Assert-LyraHUDAuditData $auditReport (Join-Path $output 'hud-audit.json')
    Assert-UEPFocusedLog (Get-Content -LiteralPath (Join-Path $output 'hud-audit.log') -Raw) 'UEP_LYRA_HUD_AUDIT_PASSED'
    $summary.hud_audit=@{status='passed';report=(Join-Path $output 'hud-audit.json')}
    $network=[Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
    if ((@($network.GetActiveTcpListeners().Port)+@($network.GetActiveUdpListeners().Port)) -contains $ServerPort) {throw 'Requested network port is occupied'}
    Start-NetworkPeer 'server'
    $deadline=[DateTime]::UtcNow.AddSeconds($RuntimeTimeoutSeconds)
    $releaseSent=$false; $lastPhase=''; $aStarted=$false
    while([DateTime]::UtcNow -lt $deadline) {
        foreach($peer in @($handles.Keys)) {
            $handle=$handles[$peer]
            if($handle.process.HasExited -and $null -eq $handle.result) {
                $result=Complete-UEPValidationProcess $handle
                $summary.processes[$peer]=$result
                if($result.exit_code -ne 0){throw "$peer exited $($result.exit_code)"}
                Assert-NetworkPeer $peer
                if(!$releaseSent -and $peer -ne 'B0'){throw "$peer exited before final release"}
                Write-NetworkJSON (Join-Path $output "exits\$peer.json") @{run_id=$runId;peer=$peer;exit_code=$result.exit_code}
                Write-Host "Network peer $peer exited cleanly"
            }
        }
        if(!$aStarted -and (Test-Path -LiteralPath (Join-Path $output 'server.log'))) {
            $log=Get-Content -LiteralPath (Join-Path $output 'server.log') -Raw
            if($log -match "listening on port $ServerPort" -and $log -match 'UEP_LYRA_BRIDGE_ATTACHED'){Start-NetworkPeer 'A';$aStarted=$true}
        }
        foreach($peer in @('B0','B1')) {
            $launch=Join-Path $output "launch-$peer.json"
            if(!$handles.ContainsKey($peer) -and (Test-Path -LiteralPath $launch)) {
                $request=Read-NetworkJSON $launch
                if($request.run_id -ne $runId -or $request.peer -ne $peer){throw 'Wrong launch identity'}
                if($peer -eq 'B1' -and (!$handles.ContainsKey('B0') -or $null -eq $handles.B0.result)){throw 'B1 requested before B0 exited'}
                Start-NetworkPeer $peer
            }
        }
        $ready=@(@('server','A','B1') | Where-Object {Test-Path -LiteralPath (Join-Path $output "ready-$_.json")})
        if(!$releaseSent -and $ready.Count -eq 3) {
            foreach($peer in $ready){if((Read-NetworkJSON (Join-Path $output "ready-$peer.json")).run_id -ne $runId){throw 'Stale ready barrier'}}
            Write-NetworkJSON (Join-Path $output 'release.json') @{run_id=$runId}
            $releaseSent=$true
        }
        $phasePath=Join-Path $output 'phase.json'
        if(Test-Path -LiteralPath $phasePath){$phase=(Read-NetworkJSON $phasePath).phase;if($phase -ne $lastPhase){Write-Host "Network phase: $phase";$lastPhase=$phase}}
        if($releaseSent -and $handles.Count -eq 4 -and @($handles.Values | Where-Object {$null -eq $_.result}).Count -eq 0){break}
        Start-Sleep -Milliseconds 250
    }
    if(!$releaseSent -or $summary.processes.Count -ne 4){throw 'Network scenario incomplete or timed out'}
    $validator=Join-Path $repo 'Demos\UEPLyraIntegration\Tools\validate_network_reports.py'
    if($WeaponGameplay){$validator=Join-Path $repo 'Demos\UEPLyraIntegration\Tools\validate_weapon_network_reports.py'}
    $validatorArguments = @('-B',$validator,'--directory',$output,'--run-id',$runId)
    if ($CombatHUD) { $validatorArguments += '--combat-hud' }
    if ($DebugSpread) { $validatorArguments += '--debug-spread' }
    if ($ProductionReticles) { $validatorArguments += '--production-reticles' }
    if ($ReticleHosts) { $validatorArguments += '--reticle-hosts' }
    if ($AbilityProgress) { $validatorArguments += '--ability-progress' }
    if ($AbilityFailure) { $validatorArguments += '--ability-failure' }
    if ($DashCooldown) { $validatorArguments += '--dash-cooldown' }
    if ($RespawnTimer) { $validatorArguments += '--respawn-timer' }
    if ($QuickBarSlots) { $validatorArguments += '--quickbar-slots' }
    if ($Nameplates) { $validatorArguments += '--nameplates' }
    $null=Invoke-UEPValidationProcess $python $validatorArguments $repo (Join-Path $output 'protocol-validation') 'Network report validation' 60
    $summary.protocol_validation=Get-Content -LiteralPath (Join-Path $output 'protocol-validation-stdout.log') -Raw | ConvertFrom-Json
    if ($CombatHUD) {
        if (!$summary.protocol_validation.combat_hud_acceptance) { throw 'Combat HUD protocol was not validated' }
        foreach ($peer in @('A','B0','B1')) {
            $report=Read-NetworkJSON (Join-Path $output ($peer + '.json'))
            $images=@($report.combat_hud_slice.images)
            if ($images.Count -eq 0) { throw 'Missing native combat HUD screenshot' }
            foreach ($image in $images) {
                if ((Split-Path ([IO.Path]::GetFullPath($image)) -Parent) -ne $output) { throw 'Foreign screenshot path' }
                $bytes=[IO.File]::ReadAllBytes($image)
                if (($bytes[0..7] -join ',') -ne '137,80,78,71,13,10,26,10') { throw 'Invalid combat HUD screenshot' }
                $summary.combat_images+=@{path=$image;sha256=(Get-FileHash -LiteralPath $image).Hash}
            }
        }
        $summary.combat_hud_acceptance=$true
    }
    if ($DebugSpread) {
        if (!$summary.protocol_validation.debug_spread_acceptance) { throw 'Debug spread protocol was not validated' }
        $summary.debug_spread_acceptance=$true
    }
    if ($ProductionReticles) {
        if (!$summary.protocol_validation.production_reticle_acceptance) { throw 'Production reticle protocol was not validated' }
        $summary.production_reticle_acceptance=$true
    }
    if ($ReticleHosts) {
        if (!$summary.protocol_validation.reticle_host_acceptance) { throw 'Reticle host protocol was not validated' }
        $summary.reticle_host_acceptance=$true
    }
    if ($AbilityProgress) {
        if (!$summary.protocol_validation.ability_progress_acceptance) { throw 'Ability progress protocol was not validated' }
        $summary.ability_progress_acceptance=$true
    }
    if ($AbilityFailure) {
        if (!$summary.protocol_validation.ability_failure_acceptance) { throw 'Ability failure protocol was not validated' }
        $summary.ability_failure_acceptance=$true
    }
    if ($DashCooldown) {
        if (!$summary.protocol_validation.dash_cooldown_acceptance) { throw 'Dash cooldown protocol was not validated' }
        $summary.dash_cooldown_acceptance=$true
    }
    if ($RespawnTimer) {
        if (!$summary.protocol_validation.respawn_timer_acceptance) { throw 'Respawn timer protocol was not validated' }
        $summary.respawn_timer_acceptance=$true
    }
    if ($QuickBarSlots) {
        if (!$summary.protocol_validation.quickbar_slots_acceptance) { throw 'Quickbar slots protocol was not validated' }
        $summary.quickbar_slots_acceptance=$true
    }
    if ($Nameplates) {
        if (!$summary.protocol_validation.nameplate_acceptance) { throw 'Nameplate protocol was not validated' }
        $summary.nameplate_acceptance=$true
    }
    if($HealthbarPublicEntries){
        $owner=Read-NetworkJSON (Join-Path $output 'A.json')
        $counts=$owner.shutdown.hud.public_entry_counts
        if($counts.'Health Changed' -lt 1 -or $counts.OnPosessedPawnChanged -lt 1){throw 'Native Health/Pawn delivery did not traverse public Python ingress'}
        $summary.healthbar_public_entry_counts=$counts
        $summary.healthbar_public_entry_acceptance=$true
    }
    foreach($validationInput in $summary.input_hashes){if((Get-FileHash -LiteralPath $validationInput.path).Hash -ne $validationInput.sha256){throw "Validation input changed: $($validationInput.path)"}}
    foreach($native in $summary.native_source_hashes){foreach($path in @($native.source,$native.target)){if((Get-FileHash -LiteralPath $path).Hash -ne $native.sha256){throw 'Native source changed during validation'}}}
    $summary.multi_client_acceptance=$true
    $summary.weapon_network_acceptance=[bool]$WeaponGameplay
    if($NameplateOriginalTrace){
        foreach($key in @($summary.Keys|Where-Object {$_ -like '*_acceptance'})){$summary[$key]=$false}
    }
    $summary.status='passed'
}
catch {$summary.error=$_.ToString();throw}
finally {
    foreach($peer in @($handles.Keys)) {
        $handle=$handles[$peer]
        Stop-UEPValidationProcess $handle
        $summary.processes[$peer]=$handle.result
        $handle.process.Dispose()
    }
    Write-NetworkJSON (Join-Path $output 'summary.json') $summary
}
if($NameplateOriginalTrace){Write-Host "Two-client original-call diagnostic completed; not acceptance: $output"}
else{Write-Host "Two-client network acceptance passed: $output"}
