#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/Reproduction/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output) -or !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json")){throw 'Marked owned stage and fresh authoring output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$'}).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$tool=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_packaged_native_fixtures.py'
$summary=[ordered]@{schema_version=1;status='failed';stage_only=$true;production_assets_unchanged=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;assets=@();error=$null}
try{
    foreach($file in @($PSCommandPath,$tool,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/message_payload_graphs.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'))){Copy-Item -LiteralPath $file -Destination "$output/Inputs";$summary.hashes+=@{path=$file;sha256=(Get-FileHash -LiteralPath $file).Hash}}
    foreach($relative in @('Binaries/Win64/UnrealEditor-LyraGame.dll','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll')){$path=Join-Path $stage $relative;$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    $arguments=@($StageProject,'-run=Py',$tool,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',"-UEPPackagedFixtureStageRoot=$stage","-UEPPackagedFixtureResult=$output/assets.json","-abslog=$output/assets.log","-UserDir=$cache/User/H04Authoring/")
    $summary.process=Invoke-UEPValidationProcess 'F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' $arguments $stage "$output/assets" 'Only three packaged-native VM observers' 240 $environment
    $assets=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 12
    if($assets.status -ne 'passed' -or !$assets.stage_only -or !$assets.production_assets_unchanged -or $assets.fixture_count -ne 3){throw 'Stage-only native fixture family failed'}
    Assert-UEPFocusedLog (Get-Content -LiteralPath "$output/assets.log" -Raw) 'UEP_PACKAGED_NATIVE_FIXTURES_PASSED'
    foreach($asset in $assets.assets){if((Get-FileHash -LiteralPath (Join-Path $stage $asset.relative_path)).Hash -ne $asset.sha256){throw 'Authored native observer differs'}}
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen native observer authoring input changed'}}
    $summary.status='passed';$summary.production_assets_unchanged=$true;$summary.assets=$assets.assets
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
