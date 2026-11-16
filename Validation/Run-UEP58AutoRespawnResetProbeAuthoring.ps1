#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked disposable stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Fresh Reset probe authoring output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
$asset=Join-Path $stage 'Content/UEPValidation/BP_AutoRespawnResetProbe.uasset'
if(Test-Path -LiteralPath $asset){throw 'Do not overwrite an existing stage-only fixture'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{status='failed';runtime_acceptance=$false;stage_only=$true;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();error=$null}
try{
    $id=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $relative
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Reset probe native BuildId mismatch'}
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_auto_respawn_reset_probe.py'
    foreach($path in @($PSCommandPath,$script,(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),
        (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/message_payload_graphs.py'),
        (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',
        "-UEPResetProbeStageRoot=$stage","-UEPResetProbeResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Stage-only typed Reset observer' 120
    $report=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json
    if($report.status -ne 'passed' -or !$report.stage_only -or !$report.typed_vm_reader -or $report.runtime_acceptance -or $report.gameplay_logic -or
        $report.function -ne 'ReadReset' -or $report.nodes -ne 4 -or $report.broadcast_graphs -ne 0 -or
        [IO.Path]::GetFullPath($report.asset) -ne $asset -or (Get-FileHash -LiteralPath $asset).Hash -ne $report.sha256){throw 'Typed Reset observer authoring proof incomplete'}
    $log=Get-Content -LiteralPath "$output/assets.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_RESET_PROBE_ASSETS_PASSED'
    if($log -notmatch '(?s)UEP_RESET_PROBE_ASSETS_PASSED.*Goodbye Python.*Log file closed'){throw 'Reset observer authoring shutdown order incomplete'}
    foreach($entry in $summary.hashes){if((Get-FileHash -LiteralPath $entry.path).Hash -ne $entry.sha256){throw 'Reset observer authoring input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Stage-only Reset observer authoring: $($summary.status); $output"
