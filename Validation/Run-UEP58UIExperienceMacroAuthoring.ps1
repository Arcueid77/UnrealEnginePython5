#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,[Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$SelectionDirectory,[Parameter(Mandatory=$true)][string]$HostDirectory,[Parameter(Mandatory=$true)][string]$EntryDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Fresh owned UI preparation stage/output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path "$output/PreviousAssets" -Force|Out-Null
$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay';$summary=[ordered]@{schema_version=1;status='failed';kind='uipreparation';runtime_acceptance=$false;full_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();assets=@();process=$null;error=$null}
function Freeze([string]$File){$summary.hashes+=@{path=[IO.Path]::GetFullPath($File);sha256=(Get-FileHash -LiteralPath $File).Hash}}
try{
    $buildId=(Get-Content -LiteralPath "$EngineRoot/Engine/Binaries/Win64/UnrealEditor.modules" -Raw|ConvertFrom-Json).BuildId
    foreach($folder in @('Binaries/Win64','Plugins/UnrealEnginePython/Binaries/Win64','Plugins/UEPLyraBridge/Binaries/Win64')){if((Get-Content -LiteralPath "$stage/$folder/UnrealEditor.modules" -Raw|ConvertFrom-Json).BuildId -ne $buildId){throw 'UI preparation BuildId mismatch'};Freeze "$stage/$folder/UnrealEditor.modules"}
    foreach($mapping in @(@{source="$repo/Source";target="$stage/Plugins/UnrealEnginePython/Source"},@{source="$repo/Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source";target="$stage/Plugins/UEPLyraBridge/Source"})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){$target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName));if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'UI preparation native source parity mismatch'};Freeze $file.FullName;Freeze $target}
    }
    foreach($file in Get-ChildItem -LiteralPath "$overlay/Content/Scripts" -Recurse -File -Filter '*.py'){$target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName));New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $target -Force;Freeze $file.FullName;Freeze $target}
    $parents=@{};$expected=@{selection=@{root=$SelectionDirectory;kind='experiencescreen';widget='W_ExperienceSelectionScreen'};host=@{root=$HostDirectory;kind='hostsession';widget='W_HostSessionScreen'};entry=@{root=$EntryDirectory;kind='sessionentry';widget='W_SessionBrowserEntry'}}
    foreach($label in $expected.Keys){
        $family=$expected[$label];$parentRoot=[IO.Path]::GetFullPath($family.root)
        if(!$parentRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned accepted UI parent required'}
        $parentSummaryPath=Join-Path $parentRoot 'summary.json';$parentProofPath=Join-Path $parentRoot 'assets.json';$parent=Get-Content -LiteralPath $parentSummaryPath -Raw|ConvertFrom-Json -Depth 80;$proof=Get-Content -LiteralPath $parentProofPath -Raw|ConvertFrom-Json -Depth 80
        if($parent.status -ne 'passed' -or $proof.status -ne 'passed' -or $parent.kind -ne $family.kind -or $proof.kind -ne $family.kind){throw 'Accepted UI parent proof required'}
        $relative="Content/UI/Menu/Experiences/$($family.widget).uasset";$asset=@($parent.assets|Where-Object {[IO.Path]::GetFileName($_.stage) -eq "$($family.widget).uasset"})
        if($asset.Count -ne 1){throw 'Unique UI parent asset required'}
        foreach($path in @($asset[0].stage,$asset[0].overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $asset[0].sha256){throw 'UI parent Stage/Overlay changed'}}
        $stageBackup="$output/PreviousAssets/$label-stage.uasset";$overlayBackup="$output/PreviousAssets/$label-overlay.uasset";Copy-Item -LiteralPath $asset[0].stage -Destination $stageBackup;Copy-Item -LiteralPath $asset[0].overlay -Destination $overlayBackup;Freeze $stageBackup;Freeze $overlayBackup;Freeze $parentSummaryPath;Freeze $parentProofPath
        $parents[$label]=@{relative=$relative;sha256=$asset[0].sha256;stage_backup=$stageBackup;overlay_backup=$overlayBackup;parent_summary=$parentSummaryPath;parent_proof=$parentProofPath}
    }
    $baselinePath="$output/baselines.json";$parents|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $baselinePath -Encoding utf8;Freeze $baselinePath
    $script="$repo/Demos/UEPLyraIntegration/Tools/generate_ui_experience_preparation_assets.py"
    foreach($file in @($PSCommandPath,$script,"$PSScriptRoot/UEPValidationProcesses.ps1","$PSScriptRoot/LyraHUDContracts.ps1","$stage/Content/UI/Menu/Experiences/UIExperienceMacros.uasset","$stage/Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll","$stage/Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll","$repo/.build/LyraValidation/BlueprintPython/20261012-audit/blueprints.json")){Freeze $file}
    foreach($tool in @('stage_safety.py','generate_dash_selector_assets.py','generate_accolade_widget_assets.py','mixin_graph_gates.py','message_payload_graphs.py')){Freeze "$repo/Demos/UEPLyraIntegration/Tools/$tool"}
    $arguments=@($StageProject,'-run=Py',$script,'-NullRHI','-NoSound','-unattended','-nop4','-NoSplash','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',"-UEPPreparationStage=$stage","-UEPPreparationResult=$output/assets.json","-UEPHeroAbilityAssetsResult=$output/assets.json","-UEPPreparationBaselines=$baselinePath","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess "$EngineRoot/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" $arguments $stage "$output/assets" 'Native UI preparation consumer revision' 300
    $report=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 90
    if($report.status -ne 'passed' -or $report.kind -ne 'uipreparation' -or !$report.original_macro_library_unchanged -or !$report.all_original_caller_signatures_cdos_visuals_nodes_and_guids_preserved -or !$report.one_native_latent_load_per_consumer_shared_by_both_profiles -or @($report.assets).Count -ne 3){throw 'Native UI preparation revision proof incomplete'}
    $log=Get-Content -LiteralPath "$output/assets.log" -Raw;Assert-UEPFocusedLog $log 'UEP_UI_PREPARATION_AUTHORING_PASSED'
    if($log -notmatch '(?s)UEP_UI_PREPARATION_AUTHORING_PASSED.*Goodbye Python.*Log file closed'){throw 'UI preparation native shutdown incomplete'}
    foreach($file in $summary.hashes){if((Get-FileHash -LiteralPath $file.path).Hash -ne $file.sha256){throw 'UI preparation frozen input changed'}}
    foreach($relative in $report.assets){$source=Join-Path $stage $relative;$target=Join-Path $overlay $relative;Copy-Item -LiteralPath $source -Destination $target -Force;$summary.assets+=@{relative=$relative;stage=$source;overlay=$target;sha256=(Get-FileHash -LiteralPath $source).Hash}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Native UI preparation revision: $($summary.status); $output"
