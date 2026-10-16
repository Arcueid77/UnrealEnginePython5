#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$AssetAuthoringDirectory,
    [string]$TransportRevisionDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'UEPNameplateAssetProvenance.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject)
$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked workspace stage/output required'}
$authorPath=Join-Path $AssetAuthoringDirectory 'summary.json'
$author=Get-Content -LiteralPath $authorPath -Raw|ConvertFrom-Json -Depth 40
if($author.status -ne 'passed' -or $author.runtime_acceptance -or @($author.assets).Count -ne 5){throw 'Accepted nameplate component authoring required'}
$expected=@('Content\UEPInterop\BP_UEPGameplayMessages.uasset','Content\UI\Indicators\NameplateSource.uasset',
    'Content\UI\Indicators\NameplateManagerComponent.uasset','Content\UEPMixins\DA_NameplateSourceMixin.uasset',
    'Content\UEPMixins\DA_NameplateManagerComponentMixin.uasset')|Sort-Object
$actual=@($author.assets|ForEach-Object {[IO.Path]::GetRelativePath($stage,$_.stage)})|Sort-Object
if(($expected -join '|') -ne ($actual -join '|')){throw 'Wrong component authoring asset inventory'}
$overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
$provenance=Get-UEPNameplateAssetProvenance $AssetAuthoringDirectory $TransportRevisionDirectory $stage $overlay
if(Test-Path -LiteralPath $output){throw 'Use fresh component runtime evidence directory'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*')}).Count){throw 'Matching stage already running'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';bounded_runtime_acceptance=$false;full_acceptance=$false
    network_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;asset_authoring=$authorPath
    hashes=@();process=$null;report_gate=$null;error=$null}
function Add-ComponentHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try {
    $engineId=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    $pluginId=(Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    if($engineId -ne $pluginId){throw 'Editor BuildId mismatch'}
    $summary.editor_build_id=$engineId
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source mismatch'}
        Add-ComponentHash $source.FullName;Add-ComponentHash $target
    }
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-ComponentHash $source.FullName;Add-ComponentHash $target
    }
    foreach($asset in $provenance.assets){Add-ComponentHash $asset.stage;Add-ComponentHash $asset.overlay}
    foreach($path in $provenance.evidence){Add-ComponentHash $path}
    Add-ComponentHash (Join-Path $PSScriptRoot 'UEPNameplateAssetProvenance.ps1')
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    foreach($asset in @('NameplateSource','NameplateManagerComponent','W_Nameplate')){
        Add-ComponentHash (Join-Path (Split-Path $marker.source -Parent) "Content\UI\Indicators\$asset.uasset")
    }
    Add-ComponentHash $PSCommandPath
    Add-ComponentHash $authorPath
    Add-ComponentHash (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll')
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720',
        '-NoLoadingScreen','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',
        "-UEPNameplateComponentsResult=$output\components.json","-abslog=$output\components.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output 'components') 'Native nameplate component differential' 300
    $python=Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\Python3\Win64\python.exe'
    $contract=Join-Path $overlay 'Content\Scripts\uep_lyra_hud\nameplate_components_contract.py'
    $null=Invoke-UEPValidationProcess $python @('-B',$contract,'--report',(Join-Path $output 'components.json')) $repo (Join-Path $output 'report-gate') 'Nameplate component report gate' 30
    $summary.report_gate=Get-Content -LiteralPath (Join-Path $output 'report-gate-stdout.log') -Raw|ConvertFrom-Json
    if($summary.report_gate.status -ne 'passed' -or !$summary.report_gate.bounded_runtime_acceptance){throw 'Component report gate incomplete'}
    $log=Get-Content -LiteralPath (Join-Path $output 'components.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_NAMEPLATE_COMPONENTS_SHUTDOWN_PASSED' -RequirePythonExit
    if($log -notmatch '(?s)UEP_NAMEPLATE_COMPONENTS_DIFFERENTIAL_PASSED.*Goodbye Python.*UEP_NAMEPLATE_COMPONENTS_SHUTDOWN_PASSED.*Log file closed'){throw 'Component exit ordering incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Component input changed'}}
    $summary.status='passed';$summary.bounded_runtime_acceptance=$true
}
catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Bounded nameplate component differential: $($summary.status); $output"
