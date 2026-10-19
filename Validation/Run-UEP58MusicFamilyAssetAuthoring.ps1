#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$LifecycleAuthoringDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$baselineRoot=[IO.Path]::GetFullPath($LifecycleAuthoringDirectory);$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !$baselineRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked disposable stage and owned family proof required'}
if(Test-Path -LiteralPath $output){throw 'Fresh music family evidence required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Native lane active'}
$baselinePath=Join-Path $baselineRoot 'summary.json';$proofPath=Join-Path $baselineRoot 'assets.json'
$baseline=Get-Content $baselinePath -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content $proofPath -Raw|ConvertFrom-Json -Depth 80
if($baseline.status -ne 'passed' -or $baseline.kind -ne 'musiclifecycle' -or @($baseline.assets).Count -ne 2 -or $proof.status -ne 'passed' -or
   !$proof.original_full_cdo_and_signatures_preserved -or !$proof.native_listener_lifetime_unchanged -or $proof.actual_registered_profile_method_counts.Python -ne 8){throw 'Exact accepted music lifecycle baseline required'}
$inputs=@();foreach($asset in $baseline.assets){
    $relative=[IO.Path]::GetRelativePath($stage,[IO.Path]::GetFullPath($asset.stage))
    if($relative.StartsWith('..') -or [IO.Path]::GetFullPath($asset.overlay) -ne [IO.Path]::GetFullPath((Join-Path $overlay $relative))){throw 'Baseline family asset outside stage/Overlay'}
    foreach($p in @($asset.stage,$asset.overlay)){if((Get-FileHash $p).Hash -ne $asset.sha256){throw 'Music lifecycle baseline changed'}}
    $inputs+=@{stage=$asset.stage;overlay=$asset.overlay;overlay_existed=$true}
}
$marker=Get-Content (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
foreach($relative in @('Content/Audio/Blueprints/B_MusicManagerComponent_FE.uasset','Plugins/GameFeatures/ShooterCore/Content/Elimination/B_MusicManagerComponent_Elimination.uasset','Plugins/GameFeatures/ShooterCore/Content/ControlPoint/B_MusicManagerComponent_ControlPoint.uasset')){
    $from=Join-Path $stage $relative;$to=Join-Path $overlay $relative;$official=Join-Path (Split-Path $marker.source -Parent) $relative
    if((Test-Path -LiteralPath $to) -or (Get-FileHash $from).Hash -ne (Get-FileHash $official).Hash){throw 'Fresh original music descendant required'}
    $inputs+=@{stage=$from;overlay=$to;overlay_existed=$false}
}
$probe=Join-Path $stage 'Content/UEPValidation/BP_MusicFamilyProbe.uasset';if(Test-Path -LiteralPath $probe){throw 'Fresh family probe required'}
New-Item -ItemType Directory -Path "$output/PreviousAssets","$output/FailedAssets"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';kind='musicfamily';runtime_acceptance=$false;full_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false
    hashes=@();assets=@();previous_assets=@();process=$null;error=$null;baseline_directory=$baselineRoot}
function Add-FamilyInput([string]$Path){$p=[IO.Path]::GetFullPath($Path);$summary.hashes+=@{path=$p;sha256=(Get-FileHash -LiteralPath $p).Hash}}
$mutating=$false
try{
    Add-FamilyInput $baselinePath;Add-FamilyInput $proofPath
    $id=(Get-Content (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($file in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $p=Join-Path $stage $file;if((Get-Content $p -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Family native BuildId mismatch'};Add-FamilyInput $p
    }
    $i=0;foreach($asset in $inputs){
        $before="$output/PreviousAssets/stage-$i.uasset";$other="$output/PreviousAssets/overlay-$i.uasset";Copy-Item -LiteralPath $asset.stage -Destination $before;Add-FamilyInput $before
        if($asset.overlay_existed){Copy-Item -LiteralPath $asset.overlay -Destination $other;Add-FamilyInput $other}
        $summary.previous_assets+=@{stage=$asset.stage;overlay=$asset.overlay;stage_backup=$before;overlay_backup=$other;overlay_existed=$asset.overlay_existed};$i++
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},@{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($source in Get-ChildItem $mapping.source -Recurse -File){$target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName));if((Get-FileHash $source.FullName).Hash -ne (Get-FileHash $target).Hash){throw 'Family native source mismatch'};Add-FamilyInput $source.FullName;Add-FamilyInput $target}
    }
    foreach($source in Get-ChildItem (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName));New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null;Copy-Item -LiteralPath $source.FullName -Destination $target -Force;Add-FamilyInput $source.FullName;Add-FamilyInput $target
    }
    $tools=Join-Path $repo 'Demos/UEPLyraIntegration/Tools';$script=Join-Path $tools 'generate_music_family_assets.py'
    foreach($p in @($PSCommandPath,$script,(Join-Path $tools 'generate_music_manager_assets.py'),(Join-Path $tools 'generate_dash_selector_assets.py'),(Join-Path $tools 'stage_safety.py'),(Join-Path $tools 'mixin_graph_gates.py'),(Join-Path $tools 'message_payload_graphs.py'),$proof.caller_probe.asset)){Add-FamilyInput $p}
    $mutating=$true;$arguments=@($project,'-run=Py',$script,'-NullRHI','-NoSound','-unattended','-nop4','-NoSplash','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',"-UEPMusicFamilyStage=$stage","-UEPMusicLifecycleBaseline=$baselinePath","-UEPHeroAbilityAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Base-owned family gates and retained native child delays/listener' 240
    $report=Get-Content "$output/assets.json" -Raw|ConvertFrom-Json -Depth 100
    if($report.status -ne 'passed' -or $report.kind -ne 'musicfamily' -or !$report.original_full_cdos_and_signatures_preserved -or !$report.original_business_graphs_preserved_with_dispatch -or !$report.base_graphs_unchanged -or
       !$report.base_owned_mixin_only -or !$report.native_cp_listener_reused -or $report.native_delay_nodes_reused -ne 3 -or $report.native_parent_calls_preserved -ne 3 -or $report.transport_nodes -ne 24 -or
       $report.actual_registered_profile_method_counts.Python -ne 11 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 11 -or @($report.assets).Count -ne 5){throw 'Music family inheritance/latent/listener proof incomplete'}
    $log=Get-Content "$output/assets.log" -Raw;Assert-UEPFocusedLog $log 'UEP_MUSIC_FAMILY_ASSETS_PASSED'
    if($log -notmatch '(?s)UEP_MUSIC_FAMILY_ASSETS_PASSED.*Goodbye Python.*Log file closed'){throw 'Family commandlet shutdown incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash $input.path).Hash -ne $input.sha256){throw 'Frozen family input changed'}}
    foreach($relative in $report.assets){$from=Join-Path $stage $relative;$to=Join-Path $overlay $relative;New-Item -ItemType Directory -Path (Split-Path $to -Parent) -Force|Out-Null;Copy-Item -LiteralPath $from -Destination $to -Force;$hash=(Get-FileHash $from).Hash;if((Get-FileHash $to).Hash -ne $hash){throw 'Family output copy mismatch'};$summary.assets+=@{stage=$from;overlay=$to;sha256=$hash}}
    $summary.status='passed'
}catch{
    $summary.error=$_.ToString()
    if($mutating){$i=0;foreach($before in $summary.previous_assets){Copy-Item -LiteralPath $before.stage -Destination "$output/FailedAssets/stage-$i.uasset" -Force;Copy-Item -LiteralPath $before.stage_backup -Destination $before.stage -Force
        if($before.overlay_existed){Copy-Item -LiteralPath $before.overlay_backup -Destination $before.overlay -Force}elseif(Test-Path -LiteralPath $before.overlay){Copy-Item -LiteralPath $before.overlay -Destination "$output/FailedAssets/overlay-$i.uasset";Remove-Item -LiteralPath $before.overlay};$i++}
        if(Test-Path -LiteralPath $probe){Copy-Item -LiteralPath $probe -Destination "$output/FailedAssets/BP_MusicFamilyProbe.uasset";Remove-Item -LiteralPath $probe}}
    throw
}finally{$summary|ConvertTo-Json -Depth 14|Set-Content "$output/summary.json" -Encoding utf8}
Write-Output "Music family authoring: $($summary.status); $output"
