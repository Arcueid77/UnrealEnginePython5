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
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {throw 'Owned native stage and fresh validation output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count) {throw 'Another native lane is active'}
$build=Get-Content -LiteralPath "$BuildEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 24
$assets=Get-Content -LiteralPath "$AssetEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 24
if($build.status -ne 'built_requires_native_acceptance' -or $null -ne $build.error -or $assets.status -ne 'passed' -or $null -ne $assets.error -or $assets.assets.Count -ne 3) {throw 'Successful build and complete processor asset family required'}
foreach($row in $build.products) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Native module differs from successful build'}}
foreach($row in $assets.assets) {if((Get-FileHash -LiteralPath (Join-Path $stage $row.relative)).Hash -ne $row.sha256) {throw 'Native asset differs from successful authoring'}}
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';batch='CPP06';synthetic_native_messages=$false;actual_damage_or_network_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();processes=@{};error=$null}
$python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
try {
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($file in Get-ChildItem -LiteralPath "$overlay/Content/Scripts" -Recurse -File -Filter '*.py') {
        $relative=[IO.Path]::GetRelativePath($overlay,$file.FullName);$target=Join-Path $stage $relative;$archive=Join-Path "$output/Inputs/Overlay" $relative
        foreach($path in @($target,$archive)) {New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $path -Force}
        foreach($path in @($file.FullName,$target,$archive)) {$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    }
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'))) {
        Copy-Item -LiteralPath $path -Destination "$output/Inputs";$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    foreach($row in $build.products) {$summary.hashes+=$row}
    foreach($row in $assets.assets) {$summary.hashes+=@{path=(Join-Path $stage $row.relative);sha256=$row.sha256}}
    $cache=Join-Path $repo '.build/TaskRuntimeCache'
    foreach($dir in @('Temp','User','DDC')) {New-Item -ItemType Directory -Path "$cache/$dir" -Force|Out-Null}
    $environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    foreach($profile in @('NativeFallback','Python')) {
        $dir=Join-Path $output $profile;New-Item -ItemType Directory -Path $dir|Out-Null
        $arguments=@($StageProject,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-NullRHI','-RenderOffscreen',
            '-FixedSeed','-ExecCmds=t.MaxFPS 60',"-UEPNativeSpawnerProfile=$profile","-UEPNativeSpawnerResult=$dir/runtime.json",
            "-UserDir=$cache/User/",'-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
            '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-NoDDCCleanup',"-abslog=$dir/runtime.log")
        $summary.processes[$profile]=Invoke-UEPValidationProcess 'F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' $arguments $stage "$dir/runtime" "$profile native callback differential" 420 $environment
        $result=Get-Content -LiteralPath "$dir/runtime.json" -Raw|ConvertFrom-Json -Depth 60
        if($result.status -ne 'passed') {throw "$profile native callback fixture failed"}
        $log=Get-Content -LiteralPath "$dir/runtime.log" -Raw
        Assert-UEPFocusedLog $log 'UEP_NATIVE_SPAWNER_DIFFERENTIAL_PASSED'
        Assert-UEPFocusedLog $log 'UEP_NATIVE_SPAWNER_SHUTDOWN_PASSED'
    }
    $contract=Join-Path $overlay 'Content/Scripts/uep_lyra_native/spawner_validation_contract.py'
    $gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8','-m','uep_lyra_native.spawner_validation_contract','--native',"$output/NativeFallback/runtime.json",'--python',"$output/Python/runtime.json") "$overlay/Content/Scripts" "$output/independent-gate" 'Native/Python spawning differential' 30
    Copy-Item -LiteralPath $gate.stdout -Destination "$output/comparison.json"
    foreach($row in $summary.hashes) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Frozen callback validation input changed'}}
    $summary.status='passed'
} catch {$summary.error=$_.ToString();throw}
finally {$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
