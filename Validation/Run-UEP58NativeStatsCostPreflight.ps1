#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplay/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$owned=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Owned stage and fresh preflight output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path "$output/Controls"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='CPP-016 through CPP-018 read-only preflight';runtime_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;assets_saved=$false;hashes=@();process=$null;error=$null}
try{
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/probe_native_stats_cost_assets.py'
    foreach($path in @($script,$PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),(Join-Path $stage 'Binaries/Win64/UnrealEditor-LyraGame.dll'),(Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'),(Join-Path $stage 'Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll'))){
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
        if($path.EndsWith('.py') -or $path.EndsWith('.ps1')){Copy-Item -LiteralPath $path -Destination "$output/Controls"}
    }
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    $arguments=@($StageProject,'-run=Py',$script,"-UEPNativeStatsCostStage=$stage","-UEPNativeStatsCostPreflightResult=$output/assets.json","-UserDir=$cache/User/",'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-NoDDCCleanup',"-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess 'F:/UnrealEngine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' $arguments $stage "$output/assets" 'native stats and costs read-only preflight' 420 $environment
    $assets=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 60
    if($assets.status -ne 'passed' -or $assets.assets_saved -or !$assets.asset_hashes_unchanged){throw 'Read-only stats/cost preflight failed'}
    foreach($row in $assets.source_assets){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Preflight asset changed'}}
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen preflight input changed'}}
    $log=Get-Content -LiteralPath "$output/assets.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_NATIVE_STATS_COST_PREFLIGHT_PASSED'
    if($log -notmatch '(?s)UEP_NATIVE_STATS_COST_PREFLIGHT_PASSED.*PyCommandlet_0 finished execution \(result 0\).*Goodbye Python.*Log file closed'){throw 'Commandlet preflight lacks successful ordered exit evidence'}
    $summary.counts=$assets.counts;$summary.binding_read_failures=@($assets.read_failures).Count;$summary.status='passed'
} catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 16|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
