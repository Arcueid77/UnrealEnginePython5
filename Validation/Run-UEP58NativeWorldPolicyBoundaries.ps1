#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$BuildEvidenceDirectory,
    [Parameter(Mandatory=$true)][string]$AssetEvidenceDirectory,
    [ValidateSet('item','player')][string]$Kind='item'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory)
$owned=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Owned stage and fresh runtime output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
$build=Get-Content -LiteralPath "$BuildEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 25;$assets=Get-Content -LiteralPath "$AssetEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 25
if($build.status -ne 'built_requires_native_acceptance' -or $null -ne $build.error -or $assets.status -ne 'passed' -or $assets.assets.Count -ne 2){throw 'Successful initial-stat build and assets required'}
foreach($row in $build.products){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Compiled initial-stat module changed'}}
foreach($row in @($assets.assets)+@($assets.fixtures)+@($assets.retained_abilities)){if((Get-FileHash -LiteralPath (Join-Path $stage $row.relative)).Hash -ne $row.sha256){throw 'Cost asset or retained ability changed'}}
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$summary=[ordered]@{status='failed';batch='CPP16-18';runtime_acceptance=$false;network_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;error=$null}
$python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe';$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay';$scripts=Join-Path $overlay 'Content/Scripts'
try{
    foreach($file in Get-ChildItem -LiteralPath $scripts -Recurse -File -Filter '*.py'){
        $relative=[IO.Path]::GetRelativePath($overlay,$file.FullName)
        foreach($path in @((Join-Path $stage $relative),(Join-Path "$output/Inputs/Overlay" $relative))){New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $path -Force;$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
        $summary.hashes+=@{path=$file.FullName;sha256=(Get-FileHash -LiteralPath $file.FullName).Hash}
    }
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/validate_native_world_policy_boundaries.py'
    foreach($path in @($script,$PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'))){Copy-Item -LiteralPath $path -Destination "$output/Inputs";$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    foreach($row in $build.products){$summary.hashes+=$row}
    foreach($row in @($assets.assets)+@($assets.fixtures)+@($assets.retained_abilities)){$summary.hashes+=@{path=(Join-Path $stage $row.relative);sha256=$row.sha256}}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    $arguments=@($StageProject,'-run=Py',$script,"-UEPNativeCarrierStageRoot=$stage","-UEPNativeCarrierResult=$output/runtime.json","-UEPNativeCarrierKind=$Kind","-UserDir=$cache/User/",'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-NoDDCCleanup',"-abslog=$output/runtime.log")
    $summary.process=Invoke-UEPValidationProcess 'F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' $arguments $stage "$output/runtime" 'native initial-stat boundaries' 360 $environment
    $report=Get-Content -LiteralPath "$output/runtime.json" -Raw|ConvertFrom-Json -Depth 50
    if($report.status -ne 'passed'){throw "Native initial-stat boundary result failed: $($report.error)"}
    $log=Get-Content -LiteralPath "$output/runtime.log" -Raw;Assert-UEPFocusedLog $log 'UEP_NATIVE_WORLD_BOUNDARIES_PASSED'
    if($log -notmatch '(?s)UEP_NATIVE_WORLD_BOUNDARIES_PASSED.*PyCommandlet_0 finished execution \(result 0\).*Goodbye Python.*Log file closed'){throw 'Initial-stat commandlet lacks successful ordered exit'}
    $summary.gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8',$script,'--check-report',"$output/runtime.json") $scripts "$output/independent-gate" 'initial-stat independent gate' 30
    Copy-Item -LiteralPath $summary.gate.stdout -Destination "$output/comparison.json"
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen initial-stat runtime input changed'}}
    $summary.status='passed';$summary.runtime_acceptance=$true
} catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 16|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
