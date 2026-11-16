#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$AssetAuthoringDirectory,
      [switch]$PlayerInventory,[switch]$GrantGE)
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
$authorPath=Join-Path $AssetAuthoringDirectory 'summary.json'
$author=Get-Content -LiteralPath $authorPath -Raw|ConvertFrom-Json -Depth 40
$expectedAssets=if($GrantGE){2}else{3}
if($GrantGE -and $PlayerInventory){throw 'Choose one native world-pad lane'}
if($author.status -ne 'passed' -or $author.runtime_acceptance -or @($author.assets).Count -ne $expectedAssets){throw 'Accepted world-pad authoring required'}
foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Inventory authored asset changed'}}}
if(Test-Path -LiteralPath $output){throw 'Use fresh inventory runtime evidence directory'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*')}).Count){throw 'Matching stage already running'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';bounded_runtime_acceptance=$false;full_acceptance=$false
    network_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;asset_authoring=$authorPath
    real_player_inventory_lane=[bool]$PlayerInventory
    grant_ge_lane=[bool]$GrantGE
    hashes=@();process=$null;report_gate=$null;error=$null}
function Add-InventoryRuntimeHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $engineId=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    $pluginId=(Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    if($engineId -ne $pluginId){throw 'Editor BuildId mismatch'}
    $summary.editor_build_id=$engineId
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source mismatch'}
        Add-InventoryRuntimeHash $source.FullName;Add-InventoryRuntimeHash $target
    }
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-InventoryRuntimeHash $source.FullName;Add-InventoryRuntimeHash $target
    }
    foreach($asset in $author.assets){Add-InventoryRuntimeHash $asset.stage;Add-InventoryRuntimeHash $asset.overlay}
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    $referenceNames=if($GrantGE){@('B_GrantAbilityPad_ApplyGE')}else{@('B_GrantInventory_Pad','B_GrantInventoryPad_WithMesh')}
    foreach($name in $referenceNames){
        Add-InventoryRuntimeHash (Join-Path (Split-Path $marker.source -Parent) "Plugins\GameFeatures\ShooterCore\Content\Blueprint\$name.uasset")
    }
    foreach($path in @($PSCommandPath,$authorPath,(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),
        (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))){Add-InventoryRuntimeHash $path}
    $resultFlag=if($GrantGE){'-UEPGrantGEResult'}elseif($PlayerInventory){'-UEPInventoryPadPlayerResult'}else{'-UEPInventoryPadResult'}
    $marker=if($GrantGE){'UEP_GRANT_GE'}elseif($PlayerInventory){'UEP_INVENTORY_PLAYER'}else{'UEP_INVENTORY_PAD'}
    $contractFile=if($GrantGE){'grant_ge_pad_contract.py'}elseif($PlayerInventory){'inventory_pad_player_contract.py'}else{'inventory_pad_contract.py'}
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360',
        '-NoLoadingScreen','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        "$resultFlag=$output\inventory.json","-abslog=$output\inventory.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output 'inventory') 'Native inventory pad differential' 300
    $python=Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\Python3\Win64\python.exe'
    $contract=Join-Path $overlay "Content\Scripts\uep_lyra_world\$contractFile"
    $null=Invoke-UEPValidationProcess $python @('-B',$contract,'--report',(Join-Path $output 'inventory.json')) $repo (Join-Path $output 'report-gate') 'Inventory report gate' 30
    $summary.report_gate=Get-Content -LiteralPath (Join-Path $output 'report-gate-stdout.log') -Raw|ConvertFrom-Json
    if($summary.report_gate.status -ne 'passed' -or !$summary.report_gate.bounded_runtime_acceptance){throw 'Inventory report gate incomplete'}
    $log=Get-Content -LiteralPath (Join-Path $output 'inventory.log') -Raw
    Assert-UEPFocusedLog $log ($marker+'_SHUTDOWN_PASSED') -RequirePythonExit
    if($log -notmatch ('(?s)'+$marker+'_DIFFERENTIAL_PASSED.*Goodbye Python.*'+$marker+'_SHUTDOWN_PASSED.*Log file closed')){throw 'Inventory exit ordering incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Inventory input changed'}}
    $summary.status='passed';$summary.bounded_runtime_acceptance=$true
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Inventory bounded native differential: $($summary.status); $output"
