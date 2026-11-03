#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:/UnrealEngine',
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet('Exceptions','Benchmark','Soak')][string]$Mode='Exceptions',
    [ValidateRange(60,86400)][int]$DurationSeconds=1200,
    [ValidateRange(0,86400)][int]$TravelAfterSeconds=0
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Owned marked stage and fresh hardening output required'}
if(!(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json")){throw 'Stage marker missing'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';mode=$Mode;cpp_compile_executed=$false;cook_package_executed=$false;physical_input_tested=$false;hashes=@();process=$null;os_samples=@();error=$null}
$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay';$scripts=Join-Path $overlay 'Content/Scripts';$python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
function Add-HardeningHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    foreach($file in Get-ChildItem -LiteralPath $scripts -Recurse -File -Filter '*.py'){
        $relative=[IO.Path]::GetRelativePath($overlay,$file.FullName)
        foreach($path in @((Join-Path $stage $relative),(Join-Path "$output/Inputs/Overlay" $relative))){New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $path -Force;Add-HardeningHash $path}
        Add-HardeningHash $file.FullName
    }
    foreach($file in Get-ChildItem -LiteralPath $overlay -Recurse -File -Filter '*.uasset'){
        $copy=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName));if((Get-FileHash -LiteralPath $copy).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){throw 'Accepted overlay asset differs from stage'};Add-HardeningHash $copy;Add-HardeningHash $file.FullName
    }
    foreach($relative in @('Binaries/Win64/UnrealEditor-LyraGame.dll','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll','Plugins/GameFeatures/ShooterCore/Binaries/Win64/UnrealEditor-ShooterCoreRuntime.dll')){Add-HardeningHash (Join-Path $stage $relative)}
    foreach($file in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/check_hardening_log.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/check_hardening_stability.py'))){Copy-Item -LiteralPath $file -Destination "$output/Inputs";Add-HardeningHash $file}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    $arguments=@($StageProject,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-NullRHI','-RenderOffscreen','-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup','-ExecCmds=t.MaxFPS 60',"-UEPHardeningMode=$Mode","-UEPHardeningResult=$output/runtime.json","-UEPHardeningDuration=$DurationSeconds","-abslog=$output/runtime.log","-UserDir=$cache/User/Hardening/$Mode/")
    if($TravelAfterSeconds){$arguments+=@("-UEPHardeningTravelAfter=$TravelAfterSeconds")}
    $handle=Start-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage "$output/runtime" "native hardening $Mode" $environment
    try{
        $nextSample=0.;$limit=if($Mode -eq 'Soak'){$DurationSeconds+240}else{300}
        while(!$handle.process.HasExited){
            if($handle.stopwatch.Elapsed.TotalSeconds -gt $limit){throw 'Hardening runtime deadline exceeded'}
            if($handle.stopwatch.Elapsed.TotalSeconds -ge $nextSample){$handle.process.Refresh();$summary.os_samples+=@{elapsed_seconds=[math]::Round($handle.stopwatch.Elapsed.TotalSeconds,3);private_bytes=$handle.process.PrivateMemorySize64;working_set=$handle.process.WorkingSet64;handles=$handle.process.HandleCount;threads=$handle.process.Threads.Count};$nextSample+=10.}
            Start-Sleep -Milliseconds 200
        }
        $summary.process=Complete-UEPValidationProcess $handle;if($summary.process.exit_code -ne 0){throw 'Native hardening process failed'}
    }finally{Stop-UEPValidationProcess $handle;$handle.process.Dispose()}
    $report=Get-Content -LiteralPath "$output/runtime.json" -Raw|ConvertFrom-Json -Depth 80
    if($report.status -ne 'passed'){throw "Hardening failed: $($report.error)"}
    $expected=if($Mode -eq 'Exceptions'){13}else{0}
    $summary.log_gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8',(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/check_hardening_log.py'),'--log',"$output/runtime.log",'--expected',"$expected") $repo "$output/log-gate" 'Precise expected exception log gate' 30
    $summary.contract=Invoke-UEPValidationProcess $python @('-B','-X','utf8','-m','uep_lyra_native.hardening_validation_contract','--report',"$output/runtime.json") $scripts "$output/independent-gate" 'Independent native hardening contract' 30
    if($Mode -eq 'Soak'){
        $summary.os_samples|ConvertTo-Json -Depth 5|Set-Content -LiteralPath "$output/os-samples.json" -Encoding utf8
        $summary.stability_gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8',(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/check_hardening_stability.py'),'--report',"$output/runtime.json",'--samples',"$output/os-samples.json") $repo "$output/stability-gate" 'Post-warmup runtime stability budgets' 30
    }
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen hardening input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 18|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
