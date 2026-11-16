#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,[switch]$GrantGE)
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
if(Test-Path -LiteralPath $output){throw 'Use fresh inventory authoring evidence directory'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*')}).Count){throw 'Matching stage already running'}
$overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
$toolsRoot=Join-Path $repo 'Demos\UEPLyraIntegration\Tools'
$script=Join-Path $toolsRoot $(if($GrantGE){'generate_grant_ge_mixin_assets.py'}else{'generate_inventory_pad_mixin_assets.py'})
$marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
$referenceRoot=Split-Path $marker.source -Parent
$relativeRoot='Plugins\GameFeatures\ShooterCore\Content\Blueprint'
$names=if($GrantGE){@('B_GrantAbilityPad_ApplyGE')}else{@('B_GrantInventory_Pad','B_GrantInventoryPad_WithMesh')}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';runtime_acceptance=$false;cpp_compile_executed=$false
    cook_package_executed=$false;kind=$(if($GrantGE){'grant-ge'}else{'inventory'});hashes=@();assets=@();process=$null;error=$null;backups=@()}
function Add-InventoryHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $engineId=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    $pluginId=(Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    if($engineId -ne $pluginId){throw 'Editor BuildId mismatch'}
    $summary.editor_build_id=$engineId
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source mismatch'}
        Add-InventoryHash $source.FullName;Add-InventoryHash $target
    }
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-InventoryHash $source.FullName;Add-InventoryHash $target
    }
    foreach($name in $names){
        $relative=Join-Path $relativeRoot "$name.uasset"
        $reference=Join-Path $referenceRoot $relative
        $target=Join-Path $stage $relative
        Add-InventoryHash $reference
        if(!(Test-Path -LiteralPath (Join-Path $overlay $relative))){Copy-Item -LiteralPath $reference -Destination $target -Force}
        $backup=Join-Path $output "before-$name.uasset"
        Copy-Item -LiteralPath $target -Destination $backup
        $hash=(Get-FileHash -LiteralPath $target).Hash
        if((Get-FileHash -LiteralPath $backup).Hash -ne $hash){throw 'Inventory backup mismatch'}
        $summary.backups+=@{source=$target;copy=$backup;sha256=$hash}
    }
    foreach($path in @($PSCommandPath,$script,(Join-Path $toolsRoot 'stage_safety.py'),
        (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))){Add-InventoryHash $path}
    if($GrantGE){Add-InventoryHash (Join-Path $toolsRoot 'mixin_graph_gates.py')}
    $stageFlag=if($GrantGE){'-UEPGrantGEStageRoot'}else{'-UEPInventoryPadStageRoot'}
    $resultFlag=if($GrantGE){'-UEPGenerateGrantGEResult'}else{'-UEPGenerateInventoryPadResult'}
    $successMarker=if($GrantGE){'UEP_GRANT_GE_ASSETS_PASSED'}else{'UEP_INVENTORY_PAD_ASSETS_PASSED'}
    $arguments=@($project,'-run=Py',$script,"$stageFlag=$stage","$resultFlag=$output\assets.json",
        '-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',"-abslog=$output\assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Inventory parent/child authoring' 300
    $report=Get-Content -LiteralPath (Join-Path $output 'assets.json') -Raw|ConvertFrom-Json -Depth 40
    if($GrantGE){
        if($report.status -ne 'passed' -or $report.runtime_acceptance -or !$report.class_preserved -or
           !$report.original_blocks_retained -or !$report.native_curve_preserved -or $report.gate_count -ne 6 -or
           $report.ftext_transport_nodes -ne 4 -or @($report.original_graphs).Count -ne 2){throw 'Grant-GE authoring gate incomplete'}
    }elseif($report.status -ne 'passed' -or $report.runtime_acceptance -or !$report.class_preserved -or
       $report.related_class_routers_used -or !$report.single_parent_interface_set -or !$report.original_blocks_retained -or
       !$report.exception_defaults_to_no_original -or @($report.gates).Count -ne 4 -or
       @($report.gates|Where-Object {!$_.original_blocks_retained -or $_.added_dispatch_nodes -ne 2}).Count){throw 'Inventory authoring gate incomplete'}
    $log=Get-Content -LiteralPath (Join-Path $output 'assets.log') -Raw
    Assert-UEPFocusedLog $log $successMarker
    if($log -notmatch ('(?s)'+$successMarker+'.*Goodbye Python.*Log file closed')){throw 'World-pad authoring exit incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Inventory input changed'}}
    $setAsset=if($GrantGE){'Content\UEPMixins\DA_GrantGEPadMixin.uasset'}else{'Content\UEPMixins\DA_InventoryPadMixin.uasset'}
    $outputs=@($names|ForEach-Object {Join-Path $relativeRoot "$_.uasset"})+@($setAsset)
    foreach($relative in $outputs){
        $from=Join-Path $stage $relative;$to=Join-Path $overlay $relative
        New-Item -ItemType Directory -Path (Split-Path $to -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $from -Destination $to -Force
        $hash=(Get-FileHash -LiteralPath $from).Hash
        if((Get-FileHash -LiteralPath $to).Hash -ne $hash){throw 'Inventory canonical copy mismatch'}
        $summary.assets+=@{stage=$from;overlay=$to;sha256=$hash}
    }
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "World-pad asset authoring ($($summary.kind)): $($summary.status); not native runtime acceptance; $output"
