#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,[Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$PreparationDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Fresh owned UI preparation stage/output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path "$output/PreviousAssets" -Force|Out-Null
$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay';$summary=[ordered]@{schema_version=1;status='failed';kind='uipreparationprobe';runtime_acceptance=$false;full_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();assets=@();process=$null;error=$null}
function Freeze([string]$File){$summary.hashes+=@{path=[IO.Path]::GetFullPath($File);sha256=(Get-FileHash -LiteralPath $File).Hash}}
try{
    $buildId=(Get-Content -LiteralPath "$EngineRoot/Engine/Binaries/Win64/UnrealEditor.modules" -Raw|ConvertFrom-Json).BuildId
    foreach($folder in @('Binaries/Win64','Plugins/UnrealEnginePython/Binaries/Win64','Plugins/UEPLyraBridge/Binaries/Win64')){if((Get-Content -LiteralPath "$stage/$folder/UnrealEditor.modules" -Raw|ConvertFrom-Json).BuildId -ne $buildId){throw 'UI preparation BuildId mismatch'};Freeze "$stage/$folder/UnrealEditor.modules"}
    foreach($mapping in @(@{source="$repo/Source";target="$stage/Plugins/UnrealEnginePython/Source"},@{source="$repo/Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source";target="$stage/Plugins/UEPLyraBridge/Source"})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){$target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName));if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'UI preparation native source parity mismatch'};Freeze $file.FullName;Freeze $target}
    }
    foreach($file in Get-ChildItem -LiteralPath "$overlay/Content/Scripts" -Recurse -File -Filter '*.py'){$target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName));New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $target -Force;Freeze $file.FullName;Freeze $target}
    $revisionRoot=[IO.Path]::GetFullPath($PreparationDirectory)
    if(!$revisionRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned accepted UI preparation revision required'}
    $revisionSummary="$revisionRoot/summary.json";$revisionProof="$revisionRoot/assets.json";$revision=Get-Content -LiteralPath $revisionSummary -Raw|ConvertFrom-Json -Depth 90;$proof=Get-Content -LiteralPath $revisionProof -Raw|ConvertFrom-Json -Depth 90
    if($revision.status -ne 'passed' -or $proof.status -ne 'passed' -or $revision.kind -ne 'uipreparation' -or @($revision.assets).Count -ne 3){throw 'Passed UI preparation revision required'}
    foreach($asset in $revision.assets){foreach($file in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $file).Hash -ne $asset.sha256){throw 'Current UI preparation asset changed'};Freeze $file}}
    Freeze $revisionSummary;Freeze $revisionProof;Freeze "$stage/Content/UI/Menu/Experiences/W_NonInteractiveSpinner.uasset"
    $script="$repo/Demos/UEPLyraIntegration/Tools/generate_ui_preparation_probe.py"
    foreach($file in @($PSCommandPath,$script,"$PSScriptRoot/UEPValidationProcesses.ps1","$PSScriptRoot/LyraHUDContracts.ps1","$stage/Content/UI/Menu/Experiences/UIExperienceMacros.uasset","$stage/Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll","$stage/Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll","$repo/.build/LyraValidation/BlueprintPython/20261012-audit/blueprints.json")){Freeze $file}
    foreach($tool in @('stage_safety.py','generate_dash_selector_assets.py','generate_accolade_widget_assets.py','mixin_graph_gates.py','message_payload_graphs.py')){Freeze "$repo/Demos/UEPLyraIntegration/Tools/$tool"}
    $arguments=@($StageProject,'-run=Py',$script,'-NullRHI','-NoSound','-unattended','-nop4','-NoSplash','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',"-UEPPreparationProbeStage=$stage","-UEPPreparationProbeResult=$output/assets.json","-UEPHeroAbilityAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess "$EngineRoot/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" $arguments $stage "$output/assets" 'Native original UI preparation macro probe' 300
    $report=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 90
    if($report.status -ne 'passed' -or $report.kind -ne 'uipreparationprobe' -or !$report.stage_only -or !$report.original_macro_unchanged -or $report.original_macro_nodes -ne 7){throw 'Exact original stage-only UI macro probe required'}
    if((Get-FileHash -LiteralPath $report.fixture.asset).Hash -ne $report.fixture.sha256){throw 'UI macro probe hash differs'}
    $log=Get-Content -LiteralPath "$output/assets.log" -Raw;Assert-UEPFocusedLog $log 'UEP_UI_PREPARATION_PROBE_AUTHORING_PASSED'
    if($log -notmatch '(?s)UEP_UI_PREPARATION_PROBE_AUTHORING_PASSED.*Goodbye Python.*Log file closed'){throw 'UI preparation native shutdown incomplete'}
    foreach($file in $summary.hashes){if((Get-FileHash -LiteralPath $file.path).Hash -ne $file.sha256){throw 'UI preparation frozen input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Native UI macro probe: $($summary.status); $output"
