#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$DispatchAuthoringDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
$baselineRoot=[IO.Path]::GetFullPath($DispatchAuthoringDirectory)
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !$baselineRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked disposable stage and owned evidence required'}
if(Test-Path -LiteralPath $output){throw 'Fresh static audio dispatch evidence required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'A native lane is active'}
$baselinePath=Join-Path $baselineRoot 'summary.json';$baseline=Get-Content -LiteralPath $baselinePath -Raw|ConvertFrom-Json -Depth 80
$proofPath=Join-Path $baselineRoot 'assets.json';$proof=Get-Content -LiteralPath $proofPath -Raw|ConvertFrom-Json -Depth 80
if($baseline.status -ne 'passed' -or $baseline.kind -ne 'weaponaudiodispatch' -or @($baseline.assets).Count -ne 3 -or $proof.status -ne 'passed' -or
   !$proof.original_full_cdo_preserved -or !$proof.original_static_signatures_flags_preserved -or $proof.transport_nodes -ne 20){throw 'Accepted static audio math baseline required'}
$relative='Plugins/GameFeatures/ShooterCore/Content/System/Audio/WeaponAudioFunctions.uasset'
$new=@('Content/UEPMixins/BP_WeaponAudioWhizRouter.uasset','Content/UEPMixins/DA_WeaponAudioWhizMixin.uasset','Content/UEPValidation/BP_WeaponAudioWhizCaller.uasset')
foreach($asset in $baseline.assets){
    $expectedRelative=[IO.Path]::GetRelativePath($stage,[IO.Path]::GetFullPath($asset.stage))
    if($expectedRelative.StartsWith('..') -or [IO.Path]::GetFullPath($asset.overlay) -ne [IO.Path]::GetFullPath((Join-Path $overlay $expectedRelative))){throw 'Baseline asset outside current stage/Overlay'}
    foreach($path in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Math baseline changed; do not supersede'}}
}
foreach($file in $new){foreach($root in @($stage,$overlay)){if(Test-Path -LiteralPath (Join-Path $root $file)){throw 'Dispatch output already exists'}}}
New-Item -ItemType Directory -Path "$output/PreviousAssets","$output/FailedAssets"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';kind='weaponaudiowhiz';runtime_acceptance=$false;full_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();assets=@();process=$null;error=$null;baseline_directory=$baselineRoot}
function Add-AudioInput([string]$Path){$resolved=[IO.Path]::GetFullPath($Path);$summary.hashes+=@{path=$resolved;sha256=(Get-FileHash -LiteralPath $resolved).Hash}}
$mutating=$false
try{
    Add-AudioInput $baselinePath;Add-AudioInput $proofPath
    $id=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($file in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $file
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Audio dispatch native BuildId mismatch'};Add-AudioInput $path
    }
    foreach($root in @($stage,$overlay)){
        $name=if($root -eq $stage){'stage'}else{'overlay'};$backup="$output/PreviousAssets/$name.uasset"
        Copy-Item -LiteralPath (Join-Path $root $relative) -Destination $backup;Add-AudioInput $backup
    }
    foreach($asset in $baseline.assets|Where-Object {$_.stage -ne (Join-Path $stage $relative)}){Add-AudioInput $asset.stage;Add-AudioInput $asset.overlay}
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Audio dispatch native source mismatch'}
            Add-AudioInput $source.FullName;Add-AudioInput $target
        }
    }
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force;Add-AudioInput $source.FullName;Add-AudioInput $target
    }
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    Add-AudioInput (Join-Path (Split-Path $marker.source -Parent) $relative)
    Add-AudioInput (Join-Path $stage 'Content/Audio/Effects/SubmixEffects/TAP_EarlyReflections.uasset')
    foreach($file in @('Content/UEPMixins/BP_WeaponAudioMathRouter.uasset','Content/UEPMixins/DA_WeaponAudioMathMixin.uasset','Content/UEPValidation/BP_WeaponAudioMathCaller.uasset','Content/UEPValidation/BP_WeaponAudioDispatchCaller.uasset')){Add-AudioInput (Join-Path $stage $file)}
    $tools=Join-Path $repo 'Demos/UEPLyraIntegration/Tools';$script=Join-Path $tools 'generate_weapon_audio_whiz_assets.py'
    foreach($path in @($PSCommandPath,$script,(Join-Path $tools 'generate_weapon_audio_math_assets.py'),(Join-Path $tools 'generate_dash_selector_assets.py'),
        (Join-Path $tools 'stage_safety.py'),(Join-Path $tools 'mixin_graph_gates.py'),(Join-Path $tools 'message_payload_graphs.py'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){Add-AudioInput $path}
    $mutating=$true
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',
        "-UEPAudioWhizStage=$stage","-UEPAudioDispatchBaseline=$baselinePath","-UEPHeroAbilityAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Static weapon WhizBy authoring' 240
    $report=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 100
    if($report.status -ne 'passed' -or !$report.original_full_cdo_preserved -or !$report.original_static_signatures_flags_preserved -or
       !$report.original_business_graphs_preserved_with_dispatch -or !$report.original_local_defaults_preserved -or !$report.existing_math_transport_preserved -or !$report.existing_dispatch_transport_preserved -or
       $report.transport_nodes -ne 5 -or $report.new_business_nodes -ne 0 -or $report.baseline_graph_nodes -ne 366 -or
       $report.static_functions_registered_as_mixins -or $report.actual_registered_profile_method_counts.Python -ne 1 -or
       $report.actual_registered_profile_method_counts.BlueprintFallback -ne 1 -or @($report.assets).Count -ne 3 -or $report.runtime_acceptance){throw 'Static dispatch graph/ABI proof incomplete'}
    $log=Get-Content -LiteralPath "$output/assets.log" -Raw;Assert-UEPFocusedLog $log 'UEP_WEAPON_AUDIO_WHIZ_ASSETS_PASSED'
    if($log -notmatch '(?s)UEP_WEAPON_AUDIO_WHIZ_ASSETS_PASSED.*Goodbye Python.*Log file closed'){throw 'Audio dispatch commandlet shutdown incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Audio dispatch frozen input changed'}}
    foreach($file in $report.assets){
        $from=Join-Path $stage $file;$to=Join-Path $overlay $file
        Copy-Item -LiteralPath $from -Destination $to -Force;$hash=(Get-FileHash -LiteralPath $from).Hash
        if((Get-FileHash -LiteralPath $to).Hash -ne $hash){throw 'Audio dispatch output copy mismatch'}
        $summary.assets+=@{stage=$from;overlay=$to;sha256=$hash}
    }
    $summary.status='passed'
}catch{
    $summary.error=$_.ToString()
    if($mutating){
        foreach($root in @($stage,$overlay)){
            $name=if($root -eq $stage){'stage'}else{'overlay'}
            if(Test-Path -LiteralPath (Join-Path $root $relative)){Copy-Item -LiteralPath (Join-Path $root $relative) -Destination "$output/FailedAssets/$name-library.uasset" -Force}
            Copy-Item -LiteralPath "$output/PreviousAssets/$name.uasset" -Destination (Join-Path $root $relative) -Force
            foreach($file in $new){$path=Join-Path $root $file;if(Test-Path -LiteralPath $path){
                Copy-Item -LiteralPath $path -Destination (Join-Path "$output/FailedAssets" ($name+'-'+[IO.Path]::GetFileName($file))) -Force
                Remove-Item -LiteralPath $path
            }}
        }
    }
    throw
}finally{$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Static audio WhizBy authoring: $($summary.status); $output"
