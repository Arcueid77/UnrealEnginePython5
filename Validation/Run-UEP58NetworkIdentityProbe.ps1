#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$IdentityBuildDirectory,[Parameter(Mandatory=$true)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$buildRoot=[IO.Path]::GetFullPath($IdentityBuildDirectory);$output=[IO.Path]::GetFullPath($OutputDirectory)
foreach($path in @($stage,$buildRoot,$output)){if(!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned stage/build/output required'}}
if(!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json')) -or (Test-Path -LiteralPath $output)){throw 'Marked stage/fresh output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool,cl,link -ErrorAction SilentlyContinue).Count){throw 'Another native/build lane is active'}
$buildPath=Join-Path $buildRoot 'summary.json';$build=Get-Content -LiteralPath $buildPath -Raw|ConvertFrom-Json -Depth 80
$dll=Join-Path $stage 'Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPNetworkIdentity.dll'
if($build.status -ne 'built_requires_native_acceptance' -or !$build.checked_engine_and_existing_binaries_unchanged -or $build.engine_full_compile_executed -or $build.lyra_cpp_compile_executed -or
    $build.identity_dll.path -ne $dll -or (Get-FileHash -LiteralPath $dll).Hash -ne $build.identity_dll.sha256){throw 'Current reviewed identity-only DLL required'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';cpp_compile_executed=$false;cook_package_executed=$false;network_acceptance=$false;full_acceptance=$false
    bounded_native_invalid_lookup_acceptance=$false;hashes=@();process=$null;error=$null}
function Add-IdentityProbeInput([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    foreach($row in $build.source_hashes){foreach($path in @($row.path,$row.stage)){if((Get-FileHash -LiteralPath $path).Hash -ne $row.sha256){throw 'Built identity source changed'};Add-IdentityProbeInput $path}}
    $helper=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay/Content/Scripts/uep_lyra_abilities/network_identity.py'
    $staged=Join-Path $stage 'Content/Scripts/uep_lyra_abilities/network_identity.py'
    Copy-Item -LiteralPath $helper -Destination $staged -Force
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/probe_network_identity.py'
    foreach($path in @($PSCommandPath,$buildPath,$dll,$helper,$staged,$script)){Add-IdentityProbeInput $path}
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython','-NoDDCCleanup',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        "-UEPNetworkIdentityStage=$stage","-UEPNetworkIdentityProbeResult=$output/probe.json","-abslog=$output/probe.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'probe') 'Native read-only identity invalid lookup probe' 120
    $report=Get-Content -LiteralPath "$output/probe.json" -Raw|ConvertFrom-Json -Depth 30
    if($report.status -ne 'passed' -or $report.actual_native_calls -ne 2 -or $report.network_acceptance -or $report.full_acceptance -or $report.assets_saved -or $report.ids_created -or $report.gameplay_state_written){throw 'Native invalid-lookup proof failed'}
    $log=Get-Content -LiteralPath "$output/probe.log" -Raw;Assert-UEPFocusedLog $log 'UEP_NETWORK_IDENTITY_INVALID_PROBE_PASSED'
    if($log -notmatch '(?s)UEP_NETWORK_IDENTITY_INVALID_PROBE_PASSED.*Goodbye Python.*Log file closed'){throw 'Native probe shutdown ordering incomplete'}
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Native probe input changed'}}
    $summary.bounded_native_invalid_lookup_acceptance=$true;$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 15|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host 'Native null/non-world identity lookup passed; network agreement not yet accepted'
