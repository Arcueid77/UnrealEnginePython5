#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$PreviousFamilyDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked workspace stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Fresh Emote authoring evidence required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
$previousPath=Join-Path $PreviousFamilyDirectory 'summary.json'
$previous=Get-Content -LiteralPath $previousPath -Raw|ConvertFrom-Json -Depth 80
if($previous.status -ne 'passed' -or $previous.kind -ne 'adsparent' -or $previous.runtime_acceptance -or @($previous.assets).Count -ne 3){throw 'Accepted prior ADS family authoring required'}
foreach($asset in $previous.assets){foreach($path in @($asset.stage,$asset.overlay)){
    if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Previous family assets changed; historical evidence must not be rewritten'}
}}
$relative=@('Content/Characters/Heroes/Abilities/GA_AbilityWithWidget.uasset','Content/UEPMixins/DA_AbilityWidgetMixin.uasset',
    'Plugins/GameFeatures/ShooterCore/Content/Game/Emote/GA_Emote.uasset','Plugins/GameFeatures/ShooterCore/Content/Input/Abilities/GA_ADS.uasset')
if(Test-Path -LiteralPath (Join-Path $overlay $relative[2])){throw 'Do not overwrite an existing Emote Overlay asset'}
New-Item -ItemType Directory -Path "$output/PreviousAssets"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';kind='emoteparent';runtime_acceptance=$false;full_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;previous_family_directory=[IO.Path]::GetFullPath($PreviousFamilyDirectory)
    previous_assets=@();assets=@();hashes=@();process=$null;error=$null}
function Add-EmoteHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
$mutating=$false;$copiedNew=$false
try{
    Add-EmoteHash $previousPath
    Add-EmoteHash (Join-Path $PreviousFamilyDirectory 'assets.json')
    $id=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($file in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $file
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Emote matching native BuildId required'}
        Add-EmoteHash $path
    }
    for($index=0;$index -lt $relative.Count;$index++){
        $from=Join-Path $stage $relative[$index];$other=Join-Path $overlay $relative[$index]
        if($index -ne 2 -and (Get-FileHash -LiteralPath $from).Hash -ne (Get-FileHash -LiteralPath $other).Hash){throw 'Family stage/Overlay asset mismatch'}
        $backup="$output/PreviousAssets/stage-$index.uasset"
        Copy-Item -LiteralPath $from -Destination $backup
        $row=@{stage=$from;overlay=$other;stage_backup=$backup;overlay_backup=$null}
        Add-EmoteHash $backup
        if(Test-Path -LiteralPath $other){
            $row.overlay_backup="$output/PreviousAssets/overlay-$index.uasset"
            Copy-Item -LiteralPath $other -Destination $row.overlay_backup
            Add-EmoteHash $row.overlay_backup
        }
        $summary.previous_assets+=$row
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName))
            if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Emote native source mismatch'}
            Add-EmoteHash $file.FullName;Add-EmoteHash $target
        }
    }
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        Add-EmoteHash $file.FullName;Add-EmoteHash $target
    }
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_emote_parent_assets.py'
    foreach($path in @($PSCommandPath,$script,(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),
        (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/mixin_graph_gates.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/message_payload_graphs.py'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){Add-EmoteHash $path}
    $mutating=$true
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-AsyncLoadingThread',
        "-UEPEmoteStageRoot=$stage","-UEPEmoteAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Emote shared-parent retained BP authoring' 240
    $report=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 90
    if($report.status -ne 'passed' -or $report.kind -ne 'emoteparent' -or !$report.single_parent_router -or
        !$report.original_class_defaults_signature_graphs_preserved -or !$report.original_full_cdo_preserved -or
        !$report.existing_ads_profiles_defaults_graphs_preserved -or $report.runtime_acceptance -or
        $report.native_end_adapter_nodes -ne 4 -or $report.precise_delegate_remove_nodes -ne 4 -or @($report.assets).Count -ne 4){throw 'Emote authoring proof incomplete'}
    $log=Get-Content -LiteralPath "$output/assets.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_EMOTE_PARENT_ASSETS_PASSED'
    if($log -notmatch '(?s)UEP_EMOTE_PARENT_ASSETS_PASSED.*Goodbye Python.*Log file closed'){throw 'Emote authoring exit incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Emote authoring frozen input changed'}}
    foreach($file in $report.assets){
        if($file -notin $relative){throw 'Unexpected Emote output path'}
        $from=Join-Path $stage $file;$to=Join-Path $overlay $file
        New-Item -ItemType Directory -Path (Split-Path $to -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $from -Destination $to -Force
        if($file -eq $relative[2]){$copiedNew=$true}
        $hash=(Get-FileHash -LiteralPath $from).Hash
        if((Get-FileHash -LiteralPath $to).Hash -ne $hash){throw 'Emote Overlay copy mismatch'}
        $summary.assets+=@{stage=$from;overlay=$to;sha256=$hash}
    }
    $summary.status='passed'
}catch{
    $summary.error=$_.ToString()
    if($mutating){foreach($before in $summary.previous_assets){
        Copy-Item -LiteralPath $before.stage_backup -Destination $before.stage -Force
        if($before.overlay_backup){Copy-Item -LiteralPath $before.overlay_backup -Destination $before.overlay -Force}
    }}
    if($copiedNew){
        $created=[IO.Path]::GetFullPath((Join-Path $overlay $relative[2]))
        if(!$created.StartsWith(([IO.Path]::GetFullPath($overlay)+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)){throw 'Failed output is outside Overlay'}
        Move-Item -LiteralPath $created -Destination "$output/failed-overlay-GA_Emote.uasset"
    }
    throw
}finally{$summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Emote family authoring: $($summary.status); $output"
