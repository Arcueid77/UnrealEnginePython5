#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$CookEvidenceDirectory,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet('Exceptions','Frontend')][string]$Mode='Exceptions'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'UEPPackagedNativeDependencies.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Owned fresh packaged runtime output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
$cook=Get-Content -LiteralPath "$CookEvidenceDirectory/summary.json" -Raw|ConvertFrom-Json -Depth 50
if($cook.status -ne 'passed' -or $cook.scope -ne 'current-original-migration-content-cook-package' -or !$cook.cook_package_executed){throw 'Accepted current cooked package required'}
$gameExe=[IO.Path]::GetFullPath($cook.packaged_executable)
if(!$gameExe.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($gameExe) -ne 'LyraGame.exe'){throw 'Owned actual inner packaged executable required'}
foreach($row in $cook.products){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Packaged native/container product changed'}}
$project=Split-Path (Split-Path (Split-Path $gameExe -Parent) -Parent) -Parent
$packageRoot=Split-Path $project -Parent
$buildSummaryPath=@($cook.hashes|Where-Object {[IO.Path]::GetFileName($_.path) -eq 'summary.json'})[0].path
$gameBuild=Get-Content -LiteralPath $buildSummaryPath -Raw|ConvertFrom-Json -Depth 30
$receipt=@($gameBuild.products|Where-Object {[IO.Path]::GetFileName($_.path) -eq 'LyraGame.target'})[0].path
New-Item -ItemType Directory -Path "$output/Inputs"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='actual-current-packaged-native-runtime';mode=$Mode;packaged_runtime=$true;cpp_compile_executed=$false;cook_package_executed=$false;physical_input_tested=$false;hashes=@();process=$null;error=$null}
function Pin-PackagedInput([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
$python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe';$scripts=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay/Content/Scripts'
try{
    $dependencyTool=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/inspect_native_package_dependencies.py'
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $PSScriptRoot 'UEPPackagedNativeDependencies.ps1'),$dependencyTool,$receipt,"$CookEvidenceDirectory/summary.json",$gameExe)){Pin-PackagedInput $path}
    foreach($row in $cook.products){Pin-PackagedInput $row.path}
    foreach($mapping in @(@{source=$scripts;target="$project/Content/Scripts"},@{source=(Join-Path $repo 'Content/Scripts');target="$project/Plugins/UnrealEnginePython/Content/Scripts"})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File -Filter '*.py'){
            $copy=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName))
            if((Get-FileHash -LiteralPath $copy).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){throw 'Packaged current Python dependency missing or changed'}
            Pin-PackagedInput $file.FullName;Pin-PackagedInput $copy
        }
    }
    $map=if($Mode -eq 'Frontend'){'/Game/System/FrontEnd/Maps/L_LyraFrontEnd'}else{'/ShooterMaps/Maps/L_Expanse?NumBots=3'}
    $arguments=@($map,'-NullRHI','-RenderOffscreen','-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup','-ExecCmds=t.MaxFPS 60',"-abslog=$output/runtime.log","-UserDir=$output/User/")
    if($Mode -eq 'Exceptions'){$arguments+=@('-UEPHardeningMode=Exceptions',"-UEPHardeningResult=$output/runtime.json")}
    else{$arguments+=@('-UEPNativeWorldPolicyKind=frontend','-UEPNativeWorldPolicyProfile=Python',"-UEPNativeWorldPolicyResult=$output/runtime.json")}
    $handle=Start-UEPValidationProcess $gameExe $arguments (Split-Path $gameExe -Parent) "$output/runtime" "actual packaged $Mode"
    try{
        $summary.loaded_python=$null
        while(!$handle.process.HasExited){
            if($handle.stopwatch.Elapsed.TotalSeconds -gt 420){throw 'Packaged native runtime timed out'}
            if($null -eq $summary.loaded_python){$summary.loaded_python=Get-UEPPackagedPythonDependency $handle.process $packageRoot}
            Start-Sleep -Milliseconds 200
        }
        $summary.process=Complete-UEPValidationProcess $handle
        if($summary.process.exit_code -ne 0 -or $null -eq $summary.loaded_python){throw 'Packaged process failed or did not load its own CPython runtime'}
    }finally{Stop-UEPValidationProcess $handle;$handle.process.Dispose()}
    $report=Get-Content -LiteralPath "$output/runtime.json" -Raw|ConvertFrom-Json -Depth 80
    if($report.status -ne 'passed'){throw "Packaged native runtime failed: $($report.error)"}
    if($Mode -eq 'Exceptions'){
        $logTool=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/check_hardening_log.py';Pin-PackagedInput $logTool
        $summary.log_gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8',$logTool,'--log',"$output/runtime.log",'--expected','13') $repo "$output/log-gate" 'Packaged exact expected exception log' 30
        $contract='uep_lyra_native.hardening_validation_contract'
    }else{Assert-UEPFocusedLog (Get-Content -LiteralPath "$output/runtime.log" -Raw) 'UEP_NATIVE_WORLD_SHUTDOWN_PASSED' -RequirePythonExit;$contract='uep_lyra_native.world_validation_contract'}
    $summary.contract=Invoke-UEPValidationProcess $python @('-B','-X','utf8','-m',$contract,'--report',"$output/runtime.json") "$project/Content/Scripts" "$output/independent-gate" 'Actual packaged native result contract' 30
    $summary.dependency_gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8',$dependencyTool,'--package',$packageRoot,'--engine','F:/UnrealEngine','--receipt',$receipt,'--log',"$output/runtime.log",'--working',(Split-Path $gameExe -Parent),'--result',"$output/dependencies.json") $repo "$output/dependency-gate" 'Packaged CPython receipt and actual runtime home' 60
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen packaged input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 16|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
