#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$ControlsAuthoringDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$baselineRoot=[IO.Path]::GetFullPath($ControlsAuthoringDirectory)
$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay';$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !$baselineRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked disposable stage and owned evidence required'}
if(Test-Path -LiteralPath $output){throw 'Fresh music lifecycle authoring required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Native lane active'}
$baselinePath=Join-Path $baselineRoot 'summary.json';$proofPath=Join-Path $baselineRoot 'assets.json'
$baseline=Get-Content -LiteralPath $baselinePath -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $proofPath -Raw|ConvertFrom-Json -Depth 80
if($baseline.status -ne 'passed' -or $baseline.kind -ne 'musiccontrols' -or @($baseline.assets).Count -ne 2 -or $proof.status -ne 'passed' -or
   !$proof.original_graphs_unmodified -or !$proof.original_begin_play_listeners_preserved -or $proof.actual_registered_profile_method_counts.Python -ne 5){throw 'Exact accepted music controls baseline required'}
foreach($asset in $baseline.assets){
    $relative=[IO.Path]::GetRelativePath($stage,[IO.Path]::GetFullPath($asset.stage))
    if($relative.StartsWith('..') -or [IO.Path]::GetFullPath($asset.overlay) -ne [IO.Path]::GetFullPath((Join-Path $overlay $relative))){throw 'Baseline music asset outside stage/Overlay'}
    foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Music controls bytes changed'}}
}
$probe=Join-Path $stage 'Content/UEPValidation/BP_MusicListenerProbe.uasset';if(Test-Path -LiteralPath $probe){throw 'Fresh listener probe required'}
New-Item -ItemType Directory -Path "$output/PreviousAssets","$output/FailedAssets"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';kind='musiclifecycle';runtime_acceptance=$false;full_acceptance=$false;cpp_compile_executed=$false
    cook_package_executed=$false;hashes=@();assets=@();previous_assets=@();process=$null;error=$null;baseline_directory=$baselineRoot}
function Add-MusicInput([string]$Path){$p=[IO.Path]::GetFullPath($Path);$summary.hashes+=@{path=$p;sha256=(Get-FileHash -LiteralPath $p).Hash}}
$mutating=$false
try{
    Add-MusicInput $baselinePath;Add-MusicInput $proofPath
    $id=(Get-Content (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($file in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $p=Join-Path $stage $file;if((Get-Content $p -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Music lifecycle native BuildId mismatch'};Add-MusicInput $p
    }
    $i=0;foreach($asset in $baseline.assets){
        $before="$output/PreviousAssets/stage-$i.uasset";$other="$output/PreviousAssets/overlay-$i.uasset"
        Copy-Item -LiteralPath $asset.stage -Destination $before;Copy-Item -LiteralPath $asset.overlay -Destination $other
        $summary.previous_assets+=@{stage=$asset.stage;overlay=$asset.overlay;stage_backup=$before;overlay_backup=$other};Add-MusicInput $before;Add-MusicInput $other;$i++
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            if((Get-FileHash $source.FullName).Hash -ne (Get-FileHash $target).Hash){throw 'Music lifecycle native source mismatch'};Add-MusicInput $source.FullName;Add-MusicInput $target
        }
    }
    foreach($source in Get-ChildItem (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName));New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force;Add-MusicInput $source.FullName;Add-MusicInput $target
    }
    foreach($property in $proof.child_asset_hashes.PSObject.Properties){$p=Join-Path $stage $property.Name;if((Get-FileHash $p).Hash -ne $property.Value){throw 'Music descendant changed'};Add-MusicInput $p}
    Add-MusicInput $proof.caller_probe.asset
    $tools=Join-Path $repo 'Demos/UEPLyraIntegration/Tools';$script=Join-Path $tools 'generate_music_lifecycle_assets.py'
    foreach($p in @($PSCommandPath,$script,(Join-Path $tools 'generate_music_manager_assets.py'),(Join-Path $tools 'generate_dash_selector_assets.py'),
        (Join-Path $tools 'generate_weapon_audio_math_assets.py'),(Join-Path $tools 'stage_safety.py'),(Join-Path $tools 'mixin_graph_gates.py'),(Join-Path $tools 'message_payload_graphs.py'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){Add-MusicInput $p}
    $mutating=$true;$arguments=@($project,'-run=Py',$script,'-NullRHI','-NoSound','-unattended','-nop4','-NoSplash','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',
        "-UEPMusicLifecycleStage=$stage","-UEPMusicControlsBaseline=$baselinePath","-UEPHeroAbilityAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Retained native music listener/Python lifecycle authoring' 240
    $report=Get-Content "$output/assets.json" -Raw|ConvertFrom-Json -Depth 100
    if($report.status -ne 'passed' -or $report.kind -ne 'musiclifecycle' -or !$report.original_full_cdo_and_signatures_preserved -or !$report.original_business_graphs_preserved_with_dispatch -or
       !$report.no_python_subscription_roots -or !$report.native_listener_lifetime_unchanged -or $report.native_listener_nodes_reused -ne 2 -or $report.transport_nodes -ne 9 -or $report.new_business_nodes -ne 0 -or
       $report.actual_registered_profile_method_counts.Python -ne 8 -or $report.actual_registered_profile_method_counts.BlueprintFallback -ne 8 -or @($report.assets).Count -ne 2){throw 'Music lifecycle authoring proof incomplete'}
    $log=Get-Content "$output/assets.log" -Raw;Assert-UEPFocusedLog $log 'UEP_MUSIC_LIFECYCLE_ASSETS_PASSED'
    if($log -notmatch '(?s)UEP_MUSIC_LIFECYCLE_ASSETS_PASSED.*Goodbye Python.*Log file closed'){throw 'Music lifecycle shutdown incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash $input.path).Hash -ne $input.sha256){throw 'Frozen music lifecycle input changed'}}
    foreach($file in $report.assets){$from=Join-Path $stage $file;$to=Join-Path $overlay $file;Copy-Item -LiteralPath $from -Destination $to -Force;$hash=(Get-FileHash $from).Hash
        if((Get-FileHash $to).Hash -ne $hash){throw 'Music lifecycle output copy mismatch'};$summary.assets+=@{stage=$from;overlay=$to;sha256=$hash}}
    $summary.status='passed'
}catch{
    $summary.error=$_.ToString()
    if($mutating){$i=0;foreach($before in $summary.previous_assets){foreach($key in @('stage','overlay')){Copy-Item -LiteralPath $before.$key -Destination "$output/FailedAssets/$key-$i.uasset" -Force;Copy-Item -LiteralPath $before.($key+'_backup') -Destination $before.$key -Force};$i++}
        if(Test-Path -LiteralPath $probe){Copy-Item -LiteralPath $probe -Destination "$output/FailedAssets/BP_MusicListenerProbe.uasset";Remove-Item -LiteralPath $probe}}
    throw
}finally{$summary|ConvertTo-Json -Depth 14|Set-Content "$output/summary.json" -Encoding utf8}
Write-Output "Music lifecycle authoring: $($summary.status); $output"
