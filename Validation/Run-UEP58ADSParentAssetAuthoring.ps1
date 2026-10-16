#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$DraftAssetsDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
    !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked disposable stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Fresh ADS parent evidence directory required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'A native lane is active'}
$draft=Get-Content (Join-Path $DraftAssetsDirectory 'summary.json') -Raw|ConvertFrom-Json -Depth 70
if($draft.status -ne 'passed' -or $draft.kind -ne 'ads' -or @($draft.assets).Count -ne 2){throw 'Exact accepted ADS draft authoring required'}
foreach($asset in $draft.assets){foreach($path in @($asset.stage,$asset.overlay)){
    if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'ADS draft changed; do not supersede'}
}}
New-Item -ItemType Directory -Path "$output/PreviousAssets","$output/RetiredAssets"|Out-Null
$summary=[ordered]@{status='failed';kind='adsparent';runtime_acceptance=$false;full_acceptance=$false;assets=@();hashes=@();previous_assets=@()
    cpp_compile_executed=$false;cook_package_executed=$false;process=$null;error=$null}
function Add-ADSInput([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
$relative=@('Content/Characters/Heroes/Abilities/GA_AbilityWithWidget.uasset','Content/UEPMixins/DA_AbilityWidgetMixin.uasset',
    'Plugins/GameFeatures/ShooterCore/Content/Input/Abilities/GA_ADS.uasset','Content/UEPMixins/DA_ADSAbilityMixin.uasset')
$mutating=$false
try{
    $id=(Get-Content (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($file in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $file
        if((Get-Content $path -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'ADS parent native BuildId mismatch'}
        Add-ADSInput $path
    }
    for($i=0;$i -lt $relative.Count;$i++){
        $from=Join-Path $stage $relative[$i];$other=Join-Path $overlay $relative[$i]
        if((Get-FileHash $from).Hash -ne (Get-FileHash $other).Hash){throw 'ADS parent stage/Overlay input mismatch'}
        $before="$output/PreviousAssets/stage-$i.uasset";$beforeOverlay="$output/PreviousAssets/overlay-$i.uasset"
        Copy-Item -LiteralPath $from -Destination $before;Copy-Item -LiteralPath $other -Destination $beforeOverlay
        $summary.previous_assets+=@{stage=$from;overlay=$other;stage_backup=$before;overlay_backup=$beforeOverlay}
        Add-ADSInput $before;Add-ADSInput $beforeOverlay
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($source in Get-ChildItem $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            if((Get-FileHash $source.FullName).Hash -ne (Get-FileHash $target).Hash){throw 'ADS parent native source mismatch'}
            Add-ADSInput $source.FullName;Add-ADSInput $target
        }
    }
    foreach($source in Get-ChildItem (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force;Add-ADSInput $source.FullName;Add-ADSInput $target
    }
    $marker=Get-Content (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    $official=Join-Path (Split-Path $marker.source -Parent) $relative[2]
    Add-ADSInput $official
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_ads_parent_assets.py'
    foreach($path in @($PSCommandPath,$script,(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),
        (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/mixin_graph_gates.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/message_payload_graphs.py'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){Add-ADSInput $path}
    $mutating=$true
    Copy-Item -LiteralPath $official -Destination (Join-Path $stage $relative[2]) -Force
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-AsyncLoadingThread',
        "-UEPADSParentStageRoot=$stage","-UEPADSParentAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'ADS single-parent typed gate authoring' 240
    $report=Get-Content "$output/assets.json" -Raw|ConvertFrom-Json -Depth 90
    if($report.status -ne 'passed' -or !$report.single_parent_router -or !$report.original_class_defaults_signature_graphs_preserved -or
        $report.runtime_acceptance -or @($report.assets).Count -ne 3){throw 'ADS shared-parent authoring proof incomplete'}
    $log=Get-Content "$output/assets.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_ADS_PARENT_ASSETS_PASSED'
    if($log -notmatch '(?s)UEP_ADS_PARENT_ASSETS_PASSED.*Goodbye Python.*Log file closed'){throw 'ADS parent commandlet exit incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash $input.path).Hash -ne $input.sha256){throw 'ADS parent frozen input changed'}}
    foreach($file in $report.assets){
        $from=Join-Path $stage $file;$to=Join-Path $overlay $file
        Copy-Item -LiteralPath $from -Destination $to -Force
        $hash=(Get-FileHash $from).Hash
        if((Get-FileHash $to).Hash -ne $hash){throw 'ADS parent output copy mismatch'}
        $summary.assets+=@{stage=$from;overlay=$to;sha256=$hash}
    }
    # Retire only the exact, hash-verified draft Set created by Assets03. Both
    # versions remain recoverable alongside all four before-asset backups.
    $unusedStage=[IO.Path]::GetFullPath((Join-Path $stage $relative[3]));$unusedOverlay=[IO.Path]::GetFullPath((Join-Path $overlay $relative[3]))
    if(!$unusedStage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
        !$unusedOverlay.StartsWith(([IO.Path]::GetFullPath($overlay)+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)){throw 'Retired ADS Set target outside intended stage/Overlay'}
    Move-Item -LiteralPath $unusedStage -Destination "$output/RetiredAssets/stage-DA_ADSAbilityMixin.uasset"
    Move-Item -LiteralPath $unusedOverlay -Destination "$output/RetiredAssets/overlay-DA_ADSAbilityMixin.uasset"
    $summary.retired_draft_set_recoverable=$true;$summary.status='passed'
}catch{
    $summary.error=$_.ToString()
    if($mutating){foreach($before in $summary.previous_assets){
        Copy-Item -LiteralPath $before.stage_backup -Destination $before.stage -Force
        Copy-Item -LiteralPath $before.overlay_backup -Destination $before.overlay -Force
    }}
    throw
}finally{$summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "ADS parent asset authoring: $($summary.status); $output"
