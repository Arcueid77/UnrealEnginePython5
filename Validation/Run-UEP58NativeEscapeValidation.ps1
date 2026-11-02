#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplay/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$BuildEvidenceDirectory,
    [Parameter(Mandatory=$true)][string]$AssetEvidenceDirectory,
    [Parameter(Mandatory=$true)][string]$FixtureEvidenceDirectory,
    [switch]$Headless
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Owned stage and fresh escape output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
$build=Get-Content -LiteralPath "$BuildEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 30
$assets=Get-Content -LiteralPath "$AssetEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 30
if($build.status -ne 'built_requires_native_acceptance' -or $null -ne $build.error -or $assets.status -ne 'passed' -or $assets.assets.Count -ne 5){throw 'Accepted native escape build/resources required'}
foreach($row in $build.products){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Native escape module changed'}}
foreach($row in $assets.assets){if((Get-FileHash -LiteralPath (Join-Path $stage $row.relative)).Hash -ne $row.sha256){throw 'Native escape asset changed'}}
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';batch='CPP09';validation_mode=if($Headless){'headless_policy'}else{'actual_window'};actual_window_input_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;network_acceptance=$false;hashes=@();process=$null;error=$null}
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
    $fixtures=Get-Content -LiteralPath "$FixtureEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 20
    if($fixtures.status -ne 'passed' -or $fixtures.fixtures.Count -ne 3){throw 'Isolated native UI worlds required'}
    foreach($row in $fixtures.fixtures){$path=Join-Path $stage $row.relative;if((Get-FileHash -LiteralPath $path).Hash -ne $row.sha256){throw 'UI world fixture changed'};$summary.hashes+=@{path=$path;sha256=$row.sha256}}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    $run=[guid]::NewGuid().ToString('N');$summary.run_id=$run
    $arguments=@($StageProject,'/Game/UEPValidation/L_EscapeUI_A','-game','-windowed','-ResX=1280','-ResY=720','-ForceRes','-FixedSeed','-ExecCmds=t.MaxFPS 60',"-UEPNativeEscapeResult=$output/runtime.json","-UEPNativeEscapeRun=$run",
        "-UserDir=$cache/User/CPP09/",'-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-NoDDCCleanup',"-abslog=$output/runtime.log")
    $executable='F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor.exe'
    $deadline=1020;$lane='native Escape actual window input validation'
    if($Headless){$executable='F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe';$arguments+=@('-NullRHI','-RenderOffscreen','-UEPNativeEscapeHeadless');$deadline=300;$lane='native Escape headless policy validation'}
    $summary.process=Invoke-UEPValidationProcess $executable $arguments $stage "$output/runtime" $lane $deadline $environment
    $runtime=Get-Content -LiteralPath "$output/runtime.json" -Raw|ConvertFrom-Json -Depth 70
    if($runtime.status -ne 'passed'){throw "Native escape pair failed: $($runtime.error)"}
    $log=Get-Content -LiteralPath "$output/runtime.log" -Raw
    $checked=$log
    $marker=if($Headless){'UEP_NATIVE_ESCAPE_HEADLESS_PASSED'}else{'UEP_NATIVE_ESCAPE_DIFFERENTIAL_PASSED'}
    $exitMarker=if($Headless){'UEP_NATIVE_ESCAPE_HEADLESS_SHUTDOWN_PASSED'}else{'UEP_NATIVE_ESCAPE_SHUTDOWN_PASSED'}
    Assert-UEPFocusedLog $checked $marker
    Assert-UEPFocusedLog $checked $exitMarker -RequirePythonExit
    $gateArguments=@('-B','-X','utf8','-m','uep_lyra_native.escape_validation_contract','--report',"$output/runtime.json")
    if($Headless){$gateArguments+='--headless'}else{$gateArguments+=@('--actions',"$output/ui-actions.json")}
    $gate=Invoke-UEPValidationProcess $python $gateArguments "$overlay/Content/Scripts" "$output/independent-gate" 'Native/Python escape independent gate' 30
    Copy-Item -LiteralPath $gate.stdout -Destination "$output/comparison.json"
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen escape validation input changed'}}
    $summary.status='passed'
    $summary.actual_window_input_acceptance=!$Headless
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 16|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
