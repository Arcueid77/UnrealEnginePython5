#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$BuildEvidenceDirectory,
    [Parameter(Mandatory=$true)][string]$AssetEvidenceDirectory,
    [ValidateSet('Native','Python','Default')][string]$Profile='Python',
    [ValidateSet('frontend','parts','camera')][string]$Kind='frontend'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory)
$owned=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Owned stage and fresh output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
$build=Get-Content -LiteralPath "$BuildEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 25;$assets=Get-Content -LiteralPath "$AssetEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 25
if($build.status -ne 'built_requires_native_acceptance' -or $null -ne $build.error -or $assets.status -ne 'passed' -or $assets.assets.Count -ne 2){throw 'Successful lifecycle build and assets required'}
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$summary=[ordered]@{status='failed';batch='CPP16-18';profile=$Profile;kind=$Kind;runtime_acceptance=$false;network_acceptance=$false;cpp_compile_executed=$false;hashes=@();process=$null;error=$null}
$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay';$scripts=Join-Path $overlay 'Content/Scripts'
function Add-NativeArenaHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    foreach($row in $build.products){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Compiled lifecycle module changed'};Add-NativeArenaHash $row.path}
    foreach($row in @($assets.assets)+@($assets.fixtures)+@($assets.retained_abilities)){if((Get-FileHash -LiteralPath (Join-Path $stage $row.relative)).Hash -ne $row.sha256){throw 'Death assets changed'};Add-NativeArenaHash (Join-Path $stage $row.relative)}
    foreach($file in Get-ChildItem -LiteralPath $scripts -Recurse -File -Filter '*.py'){
        $relative=[IO.Path]::GetRelativePath($overlay,$file.FullName)
        foreach($path in @((Join-Path $stage $relative),(Join-Path "$output/Inputs/Overlay" $relative))){New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $path -Force;Add-NativeArenaHash $path}
        Add-NativeArenaHash $file.FullName
    }
    foreach($file in Get-ChildItem -LiteralPath $overlay -Recurse -File -Filter '*.uasset'){
        $copy=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName));if((Get-FileHash -LiteralPath $copy).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){throw 'Overlay asset changed'};Add-NativeArenaHash $copy;Add-NativeArenaHash $file.FullName
    }
    foreach($file in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'))){Copy-Item -LiteralPath $file -Destination "$output/Inputs";Add-NativeArenaHash $file}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    $profileName=if($Profile -eq 'Default'){'Python'}else{(Get-Culture).TextInfo.ToTitleCase($Kind)+$Profile};$map=if($Kind -eq 'frontend'){'/Game/System/FrontEnd/Maps/L_LyraFrontEnd'}else{'/ShooterMaps/Maps/L_Expanse?NumBots=0'}
    $arguments=@($StageProject,$map,'-game','-NullRHI','-RenderOffscreen','-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup','-ExecCmds=t.MaxFPS 60',"-UEPNativeWorldPolicyKind=$Kind","-UEPNativeWorldPolicyProfile=$profileName","-UEPNativeWorldPolicyResult=$output/runtime.json","-abslog=$output/runtime.log","-UserDir=$cache/User/CPP16/World/")
    $summary.process=Invoke-UEPValidationProcess 'F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' $arguments $stage "$output/runtime" 'native world policy lifecycle' 240 $environment
    $report=Get-Content -LiteralPath "$output/runtime.json" -Raw|ConvertFrom-Json -Depth 90;if($report.status -ne 'passed'){throw "world policy failed: $($report.error)"}
    Assert-UEPFocusedLog (Get-Content -LiteralPath "$output/runtime.log" -Raw) 'UEP_NATIVE_WORLD_SHUTDOWN_PASSED' -RequirePythonExit
    $summary.gate=Invoke-UEPValidationProcess 'F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe' @('-B','-X','utf8','-m','uep_lyra_native.world_validation_contract','--report',"$output/runtime.json") $scripts "$output/independent-gate" 'native world policy independent gate' 30
    Copy-Item -LiteralPath $summary.gate.stdout -Destination "$output/comparison.json"
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen world policy input changed'}}
    $summary.status='passed';$summary.runtime_acceptance=$true
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 16|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
