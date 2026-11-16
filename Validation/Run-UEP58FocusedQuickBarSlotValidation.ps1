#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$AssetAuthoringDirectory
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
if($author.status -ne 'passed' -or $author.widget -ne 'QuickBarSlot' -or $author.runtime_acceptance -or @($author.assets).Count -ne 3){throw 'Accepted quickbar/transport authoring required'}
foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Quickbar authoring asset changed'}}}
if(Test-Path -LiteralPath $output){throw 'Use fresh runtime evidence directory'}
if(@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*') }).Count){throw 'Matching stage already running'}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';bounded_runtime_acceptance=$false;full_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;external_named_query_migrated=$false
    hashes=@();process=$null;report_gate=$null;image=$null;error=$null}
function Add-QuickBarHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try {
    $engineId=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json).BuildId
    $pluginId=(Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json).BuildId
    if($engineId -ne $pluginId){throw 'Editor BuildId mismatch'}
    $summary.editor_build_id=$engineId
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source mismatch'}
        Add-QuickBarHash $source.FullName;Add-QuickBarHash $target
    }
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-QuickBarHash $source.FullName;Add-QuickBarHash $target
    }
    foreach($asset in $author.assets){Add-QuickBarHash $asset.stage;Add-QuickBarHash $asset.overlay}
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
    Add-QuickBarHash (Join-Path (Split-Path $marker.source -Parent) 'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_QuickBarSlot.uasset')
    Add-QuickBarHash $PSCommandPath;Add-QuickBarHash (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll')
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720',
        '-NoLoadingScreen','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',
        "-UEPQuickBarSlotResult=$output\quickbar.json","-abslog=$output\quickbar.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output 'quickbar') 'Production quickbar differential' 300
    $python=Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\Python3\Win64\python.exe'
    $contract=Join-Path $overlay 'Content\Scripts\uep_lyra_hud\quickbar_slot_contract.py'
    $null=Invoke-UEPValidationProcess $python @('-B',$contract,'--report',(Join-Path $output 'quickbar.json')) $repo (Join-Path $output 'report-gate') 'Quickbar report gate' 30
    $summary.report_gate=Get-Content -LiteralPath (Join-Path $output 'report-gate-stdout.log') -Raw | ConvertFrom-Json
    if($summary.report_gate.status -ne 'passed' -or !$summary.report_gate.bounded_runtime_acceptance){throw 'Quickbar report gate incomplete'}
    $log=Get-Content -LiteralPath (Join-Path $output 'quickbar.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_QUICKBAR_SHUTDOWN_PASSED' -RequirePythonExit
    if($log -notmatch '(?s)UEP_QUICKBAR_DIFFERENTIAL_PASSED.*Goodbye Python.*UEP_QUICKBAR_SHUTDOWN_PASSED.*Log file closed'){throw 'Quickbar exit ordering incomplete'}
    $image=Join-Path $output 'quickbar-slots.png'
    $bytes=[IO.File]::ReadAllBytes($image)
    if($bytes.Length -lt 1024 -or ($bytes[0..7] -join ',') -ne '137,80,78,71,13,10,26,10'){throw 'Quickbar screenshot invalid'}
    $summary.image=@{path=$image;sha256=(Get-FileHash -LiteralPath $image).Hash;visually_inspected=$false}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Quickbar input changed during validation'}}
    $summary.status='passed';$summary.bounded_runtime_acceptance=$true
    $summary.external_named_query_migrated=$true
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Quickbar bounded runtime gate passed, named query verified: $output"
