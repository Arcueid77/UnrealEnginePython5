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
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
if (!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))) {throw 'Marked stage required'}
if (Test-Path -LiteralPath $output) {throw 'Use fresh evidence directory'}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';full_acceptance=$false;network_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;error=$null}
try {
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File) {
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source differs'}
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
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
    foreach($kind in @('Pistol','Rifle','Shotgun')) {
        foreach($relative in @("Content\UEPMixins\DA_W_Reticle_${kind}Mixin.uasset","Plugins\GameFeatures\ShooterCore\Content\Weapons\$kind\W_Reticle_$kind.uasset")) {
            $source=Join-Path $overlay $relative;$target=Join-Path $stage $relative
            if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Reticle asset differs'}
            foreach($path in @($source,$target)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
        }
        $reference=Join-Path (Split-Path $marker.source -Parent) "Plugins\GameFeatures\ShooterCore\Content\Weapons\$kind\W_Reticle_$kind.uasset"
        $summary.hashes+=@{path=$reference;sha256=(Get-FileHash -LiteralPath $reference).Hash}
    }
    foreach($path in @((Join-Path $overlay 'Content\UEPInterop\BP_UEPGameplayMessages.uasset'),
                      (Join-Path $stage 'Content\UEPInterop\BP_UEPGameplayMessages.uasset'),
                      (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))) {
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    $args=@($StageProject,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720',
        '-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-ExecCmds=t.MaxFPS 60',
        "-UEPWeaponReticleResult=$output\reticles.json","-abslog=$output\reticles.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $args $stage (Join-Path $output 'reticles') 'Production reticle BP/Python native differential' 240
    $r=Get-Content -LiteralPath (Join-Path $output 'reticles.json') -Raw | ConvertFrom-Json
    if($r.status -ne 'passed' -or @($r.cases).Count -ne 6 -or @($r.message_cases).Count -ne 3 -or
        !$r.repeated_elimination_and_suicide_filter -or !$r.real_ads_input_tested -or $r.real_elimination_gameplay_tested -or
        !$r.real_equipped_shotgun_tested -or $r.native_shotgun_ammo_after -ge $r.native_shotgun_ammo_before -or
        $r.inventory_or_weapon_spread_written -or $r.network_acceptance -or $r.full_acceptance){throw 'Incomplete reticle comparison'}
    foreach($case in $r.cases){if(!$case.same_class -or $case.automatic_python_ticks -le 0){throw 'Reticle class/Tick differs'}}
    $final=$r.reticle_shutdown
    if($final.active_count -ne 0 -or $final.scopes_created -ne $final.scopes_closed -or @($final.errors).Count -ne 0){throw 'Reticle scopes remained'}
    $log=Get-Content -LiteralPath (Join-Path $output 'reticles.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_WEAPON_RETICLE_DIFFERENTIAL_PASSED'
    Assert-UEPFocusedLog $log 'UEP_WEAPON_RETICLE_SHUTDOWN_PASSED' -RequirePythonExit
    $bytes=[IO.File]::ReadAllBytes($r.image)
    if(($bytes[0..7] -join ',') -ne '137,80,78,71,13,10,26,10'){throw 'Missing rendered reticle image'}
    $summary.image=@{path=$r.image;sha256=(Get-FileHash -LiteralPath $r.image).Hash}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Reticle input changed'}}
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Production reticle differential: $($summary.status); $output"
