#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplay/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [Parameter(Mandatory=$true)][string]$BuildEvidenceDirectory,
    [switch]$InspectOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$owned=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {throw 'Owned native stage and fresh output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count) {throw 'Another native lane is active'}
$build=Get-Content -LiteralPath "$BuildEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 24
if($build.status -ne 'built_requires_native_acceptance' -or $null -ne $build.error) {throw 'Successful native message build evidence required'}
foreach($row in $build.products) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Compiled native module changed'}}
New-Item -ItemType Directory -Path "$output/Controls"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';inspect_only=[bool]$InspectOnly;runtime_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;error=$null}
try {
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($file in Get-ChildItem -LiteralPath "$overlay/Content/Scripts" -Recurse -File -Filter '*.py') {
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        foreach($path in @($file.FullName,$target)) {$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    }
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_native_interaction_assets.py'
    foreach($path in @($script,$PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/mixin_graph_gates.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/explorer_character_cdo.py'))) {
        Copy-Item -LiteralPath $path -Destination "$output/Controls"
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    foreach($row in $build.products) {$summary.hashes+=$row}
    $cache=Join-Path $repo '.build/TaskRuntimeCache'
    foreach($dir in @('Temp','User','DDC')) {New-Item -ItemType Directory -Path "$cache/$dir" -Force|Out-Null}
    $environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    $arguments=@($StageProject,'-run=Py',$script,"-UEPNativeInteractionStageRoot=$stage","-UEPNativeInteractionAssetsResult=$output/assets.json",
        "-UserDir=$cache/User/",'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-NoDDCCleanup',"-abslog=$output/assets.log")
    if($InspectOnly) {$arguments+='-UEPNativeInteractionInspectOnly'}
    $summary.process=Invoke-UEPValidationProcess 'F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' $arguments $stage "$output/assets" 'Native message asset authoring' 420 $environment
    $assets=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 60
    if($assets.status -ne 'passed') {throw 'Native message asset result failed'}
    Assert-UEPFocusedLog (Get-Content -LiteralPath "$output/assets.log" -Raw) 'UEP_NATIVE_INTERACTION_ASSETS_PASSED'
    foreach($row in $summary.hashes) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Frozen authoring input changed'}}
    if(!$InspectOnly) {
        if(!$assets.assets_saved -or $assets.policy_events -ne 2 -or $assets.asset_family_count -ne 2) {throw 'Complete production message processor family required'}
        foreach($relative in $assets.assets) {
            $from=Join-Path $stage $relative;$to=Join-Path $overlay $relative
            New-Item -ItemType Directory -Path (Split-Path $to -Parent) -Force|Out-Null
            Copy-Item -LiteralPath $from -Destination $to -Force
            if((Get-FileHash -LiteralPath $from).Hash -ne (Get-FileHash -LiteralPath $to).Hash) {throw 'Canonical native processor asset differs'}
        }
        $summary.assets=@($assets.assets|ForEach-Object { @{relative=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $stage $_)).Hash} })
        $summary.fixtures=$assets.fixtures
    }
    $summary.status='passed'
} catch {$summary.error=$_.ToString();throw}
finally {$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
