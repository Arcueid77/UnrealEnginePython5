#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [string]$CookEvidenceDirectory='F:/UnrealEnginePython5/.build/LyraValidation/Hardening/20261103/H04-Cook02',
    [ValidateRange(5,120)][int]$CaptureSeconds=20,
    [ValidateRange(5,180)][int]$WarmupSeconds=45,
    [switch]$Pilot
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'UEPPackagedNativeDependencies.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Owned fresh rendered comparison output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
$cook=Get-Content -LiteralPath "$CookEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 40
if($cook.status -ne 'passed' -or !$cook.cook_package_executed){throw 'Accepted current package required'}
$game=$cook.packaged_executable;$project=Split-Path (Split-Path (Split-Path $game -Parent) -Parent) -Parent;$package=Split-Path $project -Parent
New-Item -ItemType Directory -Path "$output/Inputs","$output/Captures" -Force|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='actual-offscreen-D3D12-native-world-policy-frame-and-CPU-comparison';pilot=[bool]$Pilot;cpp_compile_executed=$false;cook_package_executed=$false;physical_input_tested=$false;hashes=@();process=$null;os_samples=@();error=$null}
function Pin-RenderedInput([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    foreach($row in $cook.products){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Current packaged product changed'};Pin-RenderedInput $row.path}
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'UEPPackagedNativeDependencies.ps1'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/rendered_performance_runtime.py'))){Pin-RenderedInput $path;Copy-Item -LiteralPath $path -Destination "$output/Inputs"}
    foreach($source in Get-ChildItem -LiteralPath "$project/Content/Scripts" -Recurse -File -Filter '*.py'){Pin-RenderedInput $source.FullName}
    $bootstrap="import sys`nsys.path.insert(0, r'$output/Inputs')`nimport rendered_performance_runtime`n"
    $bootstrap|Set-Content -LiteralPath "$output/Inputs/start_performance.py" -Encoding utf8NoBOM
    Pin-RenderedInput "$output/Inputs/start_performance.py";Pin-RenderedInput "$output/Inputs/rendered_performance_runtime.py"
    $summary.hardware=@{cpu=Get-CimInstance Win32_Processor|Select-Object Name,NumberOfCores,NumberOfLogicalProcessors;gpu=Get-CimInstance Win32_VideoController|Select-Object Name,DriverVersion}
    $capturePrefix='H05_'+[Guid]::NewGuid().ToString('N')
    $arguments=@('/ShooterMaps/Maps/L_Expanse?NumBots=3','-d3d12','-RenderOffscreen','-ResX=1920','-ResY=1080','-ForceRes','-windowed','-NoVSync','-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup',"-ExecCmds=py.exec $output/Inputs/start_performance.py", "-UEPPerfResult=$output/runtime.json","-UEPPerfPrefix=$capturePrefix","-UEPPerfSeconds=$CaptureSeconds","-UEPPerfWarmup=$WarmupSeconds","-abslog=$output/runtime.log","-UserDir=$output/User/")
    if($Pilot){$arguments+='-UEPPerfPilot'}
    $cache=Join-Path $repo '.build/TaskRuntimeCache';$environment=@{'UE-LocalDataCachePath'="$cache/DDC";TEMP="$cache/Temp";TMP="$cache/Temp"}
    $handle=Start-UEPValidationProcess $game $arguments (Split-Path $game -Parent) "$output/runtime" 'actual GPU native/Python frame and CPU comparison' $environment
    try{
        $nextSample=0.;$summary.loaded_python=$null
        while(!$handle.process.HasExited){
            if($handle.stopwatch.Elapsed.TotalSeconds -gt 1000){throw 'Rendered comparison timed out'}
            if($null -eq $summary.loaded_python){$summary.loaded_python=Get-UEPPackagedPythonDependency $handle.process $package}
            if($handle.stopwatch.Elapsed.TotalSeconds -ge $nextSample){$handle.process.Refresh();$summary.os_samples+=@{elapsed_seconds=[math]::Round($handle.stopwatch.Elapsed.TotalSeconds,4);unix_ms=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds();cpu_seconds=$handle.process.TotalProcessorTime.TotalSeconds;private_bytes=$handle.process.PrivateMemorySize64;handles=$handle.process.HandleCount};$nextSample+=1.}
            Start-Sleep -Milliseconds 100
        }
        $summary.process=Complete-UEPValidationProcess $handle
        if($summary.process.exit_code -ne 0){throw 'Actual rendered packaged process failed'}
    }finally{Stop-UEPValidationProcess $handle;$handle.process.Dispose()}
    $report=Get-Content -LiteralPath "$output/runtime.json" -Raw|ConvertFrom-Json -Depth 35
    if($report.status -ne 'passed' -or !$report.selector_restored -or $null -eq $summary.loaded_python){throw 'Rendered runtime did not close successfully'}
    $log=Get-Content -LiteralPath "$output/runtime.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_RENDERED_PERFORMANCE_SHUTDOWN_PASSED' -RequirePythonExit
    if($log -notmatch 'D3D12 RHI|Using Default RHI: D3D12|RHI Selected: D3D12' -or $log -notmatch 'NVIDIA GeForce RTX 3080'){throw 'Actual D3D12 hardware rendering not proven'}
    $searchRoots=@("$output/User","$project/Saved")|Where-Object {Test-Path -LiteralPath $_}
    foreach($row in $report.blocks){
        $matches=@($searchRoots|ForEach-Object {Get-ChildItem -LiteralPath $_ -Recurse -File -Filter $row.csv_basename})
        if($matches.Count -ne 1){throw "One closed native CSV required: $($row.csv_basename)"}
        Copy-Item -LiteralPath $matches[0].FullName -Destination "$output/Captures"
    }
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen rendered comparison input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 35|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
