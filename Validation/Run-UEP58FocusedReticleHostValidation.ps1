#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject)
$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$markerPath=Join-Path $stage '.uep-lyra-full-stage.json'
if (!(Test-Path -LiteralPath $markerPath)) {throw 'Marked stage required'}
if (Test-Path -LiteralPath $output) {throw 'Use fresh evidence directory'}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';full_acceptance=$false;network_acceptance=$false
    physical_pickup_tested=$false;lethal_damage_tested=$false;cpp_compile_executed=$false
    cook_package_executed=$false;hashes=@();process=$null;image=$null;error=$null}
try {
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File) {
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        $digest=(Get-FileHash -LiteralPath $source.FullName).Hash
        if($digest -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source differs'}
        foreach($path in @($source.FullName,$target)){$summary.hashes+=@{path=$path;sha256=$digest}}
    }
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach($mapping in @(
        @{source=(Join-Path $overlay 'Content\Scripts');target=(Join-Path $stage 'Content\Scripts')},
        @{source=(Join-Path $repo 'Content\Scripts');target=(Join-Path $stage 'Plugins\UnrealEnginePython\Content\Scripts')}
    )) {
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File -Filter '*.py') {
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $source.FullName -Destination $target -Force
            foreach($path in @($source.FullName,$target)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
        }
    }
    foreach($relative in @('Content\UEPMixins\DA_W_WeaponReticleHostMixin.uasset',
                          'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_WeaponReticleHost.uasset')) {
        $source=Join-Path $overlay $relative;$target=Join-Path $stage $relative
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Host asset differs'}
        foreach($path in @($source,$target)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    }
    $marker=Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
    foreach($path in @((Join-Path (Split-Path $marker.source -Parent) 'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_WeaponReticleHost.uasset'),
                      (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))) {
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    $engineModules=Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json
    $pluginModules=Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json
    if($engineModules.BuildId -ne $pluginModules.BuildId){throw 'Native Editor BuildId mismatch'}
    $summary.editor_build_id=$engineModules.BuildId
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720',
        '-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-ExecCmds=t.MaxFPS 60',
        "-UEPReticleHostResult=$output\host.json","-abslog=$output\host.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output 'host') 'Production weapon reticle host BP/Python differential' 300
    $report=Get-Content -LiteralPath (Join-Path $output 'host.json') -Raw | ConvertFrom-Json
    if($report.status -ne 'passed' -or @($report.cases).Count -ne 8 -or $report.full_acceptance -or $report.network_acceptance -or
        !$report.production_host -or !$report.native_death_event_injected -or !$report.native_death_visibility_and_exact_once_callback -or
        $report.physical_pickup_tested -or $report.lethal_damage_tested -or $report.inventory_weapon_health_properties_written -or
        $null -ne $report.error){throw 'Incomplete host comparison'}
    foreach($name in @('production-native-initial','live-blueprint-profile','live-python-profile-resumed',
                       'null-weapon-clears','test-owned-native-weapon-without-instigator','real-native-weapon-restored',
                       'native-pickup-equip-Rifle','native-pickup-equip-Shotgun')){
        if(@($report.cases | Where-Object name -eq $name).Count -ne 1){throw 'Missing or duplicated host case'}
    }
    foreach($case in $report.cases){if(!$case.same_class -or $case.automatic_ticks -le 0){throw 'Host class or automatic Tick differs'}}
    foreach($key in @('host_shutdown','reticle_shutdown')){
        $final=$report.$key
        if($final.active_count -ne 0 -or $final.scopes_created -le 0 -or
            $final.scopes_created -ne $final.scopes_closed -or @($final.errors).Count -ne 0){throw 'Host or child scopes survived shutdown'}
    }
    $log=Get-Content -LiteralPath (Join-Path $output 'host.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_RETICLE_HOST_DIFFERENTIAL_PASSED'
    Assert-UEPFocusedLog $log 'UEP_RETICLE_HOST_SHUTDOWN_PASSED' -RequirePythonExit
    $imagePath=[IO.Path]::GetFullPath($report.image)
    if($imagePath -ne (Join-Path $output 'reticle-host.png')){throw 'Host screenshot outside evidence directory'}
    $bytes=[IO.File]::ReadAllBytes($imagePath)
    if($bytes.Length -lt 8 -or ($bytes[0..7] -join ',') -ne '137,80,78,71,13,10,26,10'){throw 'Missing host PNG'}
    $summary.image=@{path=$imagePath;sha256=(Get-FileHash -LiteralPath $imagePath).Hash}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Host input changed during validation'}}
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Reticle host BP/Python differential: $($summary.status); $output"
