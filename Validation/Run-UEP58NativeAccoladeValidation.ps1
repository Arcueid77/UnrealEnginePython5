#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplay/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$BuildEvidenceDirectory,
    [Parameter(Mandatory=$true)][string]$AssetEvidenceDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Owned stage and fresh accolade output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
$build=Get-Content -LiteralPath "$BuildEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 30
$assets=Get-Content -LiteralPath "$AssetEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 30
if($build.status -ne 'built_requires_native_acceptance' -or $null -ne $build.error -or $assets.status -ne 'passed' -or $assets.assets.Count -ne 2){throw 'Accepted native accolade build/resources required'}
foreach($row in $build.products){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Native accolade module changed'}}
foreach($row in $assets.assets){if((Get-FileHash -LiteralPath (Join-Path $stage $row.relative)).Hash -ne $row.sha256){throw 'Native accolade asset changed'}}
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';batch='CPP07';cpp_compile_executed=$false;cook_package_executed=$false;network_acceptance=$false;hashes=@();process=$null;error=$null}
$python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe';$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
try{
    foreach($file in Get-ChildItem -LiteralPath "$overlay/Content/Scripts" -Recurse -File -Filter '*.py'){
        $relative=[IO.Path]::GetRelativePath($overlay,$file.FullName);$target=Join-Path $stage $relative;$archive=Join-Path "$output/Inputs/Overlay" $relative
        foreach($path in @($target,$archive)){New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $path -Force}
        foreach($path in @($file.FullName,$target,$archive)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    }
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'))){Copy-Item -LiteralPath $path -Destination "$output/Inputs";$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    foreach($row in $build.products){$summary.hashes+=$row}
    foreach($row in $assets.assets){$summary.hashes+=@{path=(Join-Path $stage $row.relative);sha256=$row.sha256}}
    if($assets.fixtures.Count -ne 1){throw 'Cold native async fixture required'}
    foreach($row in $assets.fixtures){$path=Join-Path $stage $row.relative;if((Get-FileHash -LiteralPath $path).Hash -ne $row.sha256){throw 'Cold native async fixture changed'};Copy-Item -LiteralPath $path -Destination "$output/Inputs";$summary.hashes+=@{path=$path;sha256=$row.sha256}}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    $arguments=@($StageProject,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-NullRHI','-RenderOffscreen','-FixedSeed','-ExecCmds=t.MaxFPS 60',"-UEPNativeAccoladeResult=$output/runtime.json",
        "-UserDir=$cache/User/",'-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-NoDDCCleanup',"-abslog=$output/runtime.log")
    $summary.process=Invoke-UEPValidationProcess 'F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' $arguments $stage "$output/runtime" 'native accolade paired host validation' 420 $environment
    $runtime=Get-Content -LiteralPath "$output/runtime.json" -Raw|ConvertFrom-Json -Depth 70
    if($runtime.status -ne 'passed'){throw "Native accolade pair failed: $($runtime.error)"}
    $log=Get-Content -LiteralPath "$output/runtime.log" -Raw
    $expected='(?m)^.*LogLyra: Error: Failed to find accolade registry for tag None, accolades will not appear\r?$'
    if([regex]::Matches($log,$expected).Count -ne 2){throw 'Exactly two explicit invalid-registry failure logs required'}
    $checked=[regex]::Replace($log,$expected,'')
    Assert-UEPFocusedLog $checked 'UEP_NATIVE_ACCOLADE_DIFFERENTIAL_PASSED'
    Assert-UEPFocusedLog $checked 'UEP_NATIVE_ACCOLADE_SHUTDOWN_PASSED' -RequirePythonExit
    $gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8','-m','uep_lyra_native.accolade_validation_contract','--report',"$output/runtime.json") "$overlay/Content/Scripts" "$output/independent-gate" 'Native/Python accolade independent gate' 30
    Copy-Item -LiteralPath $gate.stdout -Destination "$output/comparison.json"
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen accolade validation input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 16|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
