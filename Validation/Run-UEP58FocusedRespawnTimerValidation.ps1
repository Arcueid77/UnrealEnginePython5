#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$AssetAuthoringDirectory,
    [switch]$NativeRespawn
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject)
$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked workspace stage/output required'}
$author=Get-Content -LiteralPath (Join-Path $AssetAuthoringDirectory 'summary.json') -Raw | ConvertFrom-Json -Depth 40
if($author.status -ne 'passed' -or $author.widget -ne 'RespawnTimer' -or $author.runtime_acceptance -or @($author.assets).Count -ne 2){throw 'Accepted Respawn authoring required'}
foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Respawn authoring asset changed'}}}
if(Test-Path -LiteralPath $output){throw 'Use fresh runtime evidence directory'}
if(@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*') }).Count){throw 'Matching stage already running'}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';bounded_runtime_acceptance=$false;full_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;audio_enabled=$true;acoustic_parity_tested=$false
    native_respawn_producer_tested=$false;hashes=@();process=$null;report_gate=$null;image=$null;error=$null}
function Add-RespawnHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try {
    $engineId=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json).BuildId
    $pluginId=(Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json).BuildId
    if($engineId -ne $pluginId){throw 'Editor BuildId mismatch'}
    $summary.editor_build_id=$engineId
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source mismatch'}
        Add-RespawnHash $source.FullName;Add-RespawnHash $target
    }
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-RespawnHash $source.FullName;Add-RespawnHash $target
    }
    foreach($relative in @('Content\UEPInterop\BP_UEPGameplayMessages.uasset','Content\UEPMixins\DA_W_RespawnTimerMixin.uasset',
        'Plugins\GameFeatures\ShooterCore\Content\Game\Respawn\W_RespawnTimer.uasset')){
        if((Get-FileHash -LiteralPath (Join-Path $stage $relative)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $overlay $relative)).Hash){throw 'Respawn asset differs'}
        Add-RespawnHash (Join-Path $stage $relative);Add-RespawnHash (Join-Path $overlay $relative)
    }
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
    Add-RespawnHash (Join-Path (Split-Path $marker.source -Parent) 'Plugins\GameFeatures\ShooterCore\Content\Game\Respawn\W_RespawnTimer.uasset')
    Add-RespawnHash $PSCommandPath;Add-RespawnHash (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll')
    $resultFlag=if($NativeRespawn){'-UEPRespawnNativeResult='}else{'-UEPRespawnResult='}
    $prefixMarker=if($NativeRespawn){'UEP_RESPAWN_NATIVE'}else{'UEP_RESPAWN'}
    $successMarker=if($NativeRespawn){'UEP_RESPAWN_NATIVE_PASSED'}else{'UEP_RESPAWN_DIFFERENTIAL_PASSED'}
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720',
        '-NoLoadingScreen','-unattended','-nop4','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',
        ($resultFlag+"$output\respawn.json"),"-abslog=$output\respawn.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output 'respawn') 'Production respawn timer/audio differential' 300
    $python=Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\Python3\Win64\python.exe'
    $contractName=if($NativeRespawn){'respawn_native_contract.py'}else{'respawn_timer_contract.py'}
    $contract=Join-Path $overlay ('Content\Scripts\uep_lyra_hud\'+$contractName)
    $null=Invoke-UEPValidationProcess $python @('-B',$contract,'--report',(Join-Path $output 'respawn.json')) $repo (Join-Path $output 'report-gate') 'Respawn report gate' 30
    $summary.report_gate=Get-Content -LiteralPath (Join-Path $output 'report-gate-stdout.log') -Raw | ConvertFrom-Json
    if($summary.report_gate.status -ne 'passed' -or !$summary.report_gate.bounded_runtime_acceptance){throw 'Respawn report gate incomplete'}
    $log=Get-Content -LiteralPath (Join-Path $output 'respawn.log') -Raw
    $shutdownMarker=$prefixMarker+'_SHUTDOWN_PASSED'
    Assert-UEPFocusedLog $log $shutdownMarker -RequirePythonExit
    if($log -notmatch ('(?s)'+$successMarker+'.*Goodbye Python.*'+$shutdownMarker+'.*Log file closed')){throw 'Respawn exit ordering incomplete'}
    $image=Join-Path $output 'respawn-timer.png'
    $bytes=[IO.File]::ReadAllBytes($image)
    if($bytes.Length -lt 1024 -or ($bytes[0..7] -join ',') -ne '137,80,78,71,13,10,26,10'){throw 'Respawn screenshot invalid'}
    $summary.image=@{path=$image;sha256=(Get-FileHash -LiteralPath $image).Hash;visually_inspected=$false}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Respawn input changed during validation'}}
    $summary.status='passed';$summary.bounded_runtime_acceptance=$true
    $summary.native_respawn_producer_tested=[bool]$NativeRespawn
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Respawn bounded runtime gate passed; inspect image: $output"
