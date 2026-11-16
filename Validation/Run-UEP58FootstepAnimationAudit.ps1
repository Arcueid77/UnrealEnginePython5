#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject)
$stage=Split-Path $project -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh owned audit output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';runtime_acceptance=$false;full_acceptance=$false;assets_modified=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;error=$null}
function Add-AuditHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $module=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules';$build=(Get-Content -LiteralPath $module -Raw|ConvertFrom-Json).BuildId;Add-AuditHash $module
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){$file=Join-Path $stage $relative;if((Get-Content -LiteralPath $file -Raw|ConvertFrom-Json).BuildId -ne $build){throw 'Native BuildId mismatch'};Add-AuditHash $file}
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},@{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){$copy=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName));if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Native source mismatch'};Add-AuditHash $file.FullName;Add-AuditHash $copy}
    }
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/audit_footstep_animation_ingress.py'
    foreach($file in @($PSCommandPath,$script,(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),(Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'),(Join-Path $stage 'Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll'))){Add-AuditHash $file}
    $official=Split-Path ((Get-Content -LiteralPath "$stage/.uep-lyra-full-stage.json" -Raw|ConvertFrom-Json).source) -Parent
    foreach($name in @('AnimNotify_LyraContextEffects.cpp','AnimNotify_LyraContextEffects.h')){Add-AuditHash (Join-Path $official "Source/LyraGame/Feedback/ContextEffects/$name")}
    foreach($relative in @('Content/Effects/Blueprints/B_FootStep.uasset','Content/Characters/Heroes/B_Hero_Default.uasset','Plugins/GameFeatures/ShooterCore/Content/Game/B_Hero_ShooterMannequin.uasset')){Add-AuditHash (Join-Path $stage $relative)}
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',"-UEPAnimationAuditStage=$stage","-UEPAnimationAuditResult=$output/audit.json","-abslog=$output/audit.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'audit') 'Read-only original locomotion notify inspection' 180
    $report=Get-Content -LiteralPath "$output/audit.json" -Raw|ConvertFrom-Json -Depth 60
    if($report.status -ne 'passed' -or $report.assets_modified -or $report.assets_saved_or_compiled -or $report.runtime_acceptance -or $report.runtime_dispatch_tested -or $report.animation_playback_executed -or !$report.source_animations_byte_identical -or $report.native_context_notify_count -lt 1){throw 'Read-only native animation inspection failed'}
    Assert-UEPFocusedLog (Get-Content -LiteralPath "$output/audit.log" -Raw) 'UEP_FOOTSTEP_ANIMATION_AUDIT_PASSED'
    foreach($frozen in $summary.hashes){if((Get-FileHash -LiteralPath $frozen.path).Hash -ne $frozen.sha256){throw 'Frozen audit input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Read-only animation audit: $($summary.status); $output"
