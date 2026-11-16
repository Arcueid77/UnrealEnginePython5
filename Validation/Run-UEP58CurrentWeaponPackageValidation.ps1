#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$CookPackageDirectory,[Parameter(Mandatory=$true)][string]$GameBuildDirectory,
    [Parameter(Mandatory=$true)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'LyraWeaponHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {
    throw 'Fresh owned package evidence directory required'
}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count) {
    throw 'Another native lane is active'
}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='current actual packaged weapon example using unchanged cooked assets'
    cpp_compile_executed=$false;cook_package_executed=$false;full_acceptance=$false;network_acceptance=$false
    packaged_runtime=$false;hashes=@();prepare=$null;process=$null;payload_summary=$null;image=$null;error=$null}
function Add-CurrentWeaponInput([string]$Path) {
    $summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}
}
try {
    $python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
    $preparer=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/prepare_current_runtime_package.py'
    foreach($path in @($PSCommandPath,$preparer,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),
        (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $PSScriptRoot 'LyraWeaponHUDContracts.ps1'))) {
        Add-CurrentWeaponInput $path
    }
    $payload=Join-Path $output 'Payload'
    $summary.prepare=Invoke-UEPValidationProcess $python @('-B','-X','utf8',$preparer,'--stage',$stage,
        '--cook-directory',$CookPackageDirectory,'--game-build',$GameBuildDirectory,'--output',$payload) $repo (Join-Path $output 'prepare') 'Derive current package; preserve original cooked archive' 300
    $payloadSummary=Join-Path $payload 'summary.json'
    $prepared=Get-Content -LiteralPath $payloadSummary -Raw|ConvertFrom-Json -Depth 30
    if($prepared.status -ne 'passed' -or $prepared.cpp_compile_executed -or $prepared.cook_package_executed) {throw 'Derived package preparation failed'}
    $summary.payload_summary=@{path=$payloadSummary;sha256=(Get-FileHash -LiteralPath $payloadSummary).Hash}
    $executable=$prepared.packaged_executable
    $binary=Split-Path $executable -Parent
    $arguments=@("-basedir=$binary",'/Engine/Maps/Entry?game=/Script/Engine.GameModeBase','-unattended','-RenderOffscreen',
        '-windowed','-ResX=1440','-ResY=900','-ForceRes','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-ExecCmds=t.MaxFPS 60',
        "-UEPLyraWeaponHUDResult=$output/weapon.json","-abslog=$output/weapon.log","-UserDir=$output/user/")
    $summary.process=Invoke-UEPValidationProcess $executable $arguments $binary (Join-Path $output 'weapon') 'Current real packaged BP/Python weapon presenters' 300
    $report=Get-Content -LiteralPath "$output/weapon.json" -Raw|ConvertFrom-Json -Depth 50
    Assert-LyraWeaponHUDData $report;Assert-LyraWeaponLifecycleData $report
    if($report.shutdown.phase -ne 'python_atexit' -or !$report.shutdown.owned_resources_closed_before_exit) {throw 'Owned cleanup before exit absent'}
    $log=Get-Content -LiteralPath "$output/weapon.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_WEAPON_HUD_DIFFERENTIAL_PASSED'
    Assert-UEPFocusedLog $log 'UEP_WEAPON_HUD_SHUTDOWN_PASSED' -RequirePythonExit
    if($log -match 'Traceback' -or $log -notmatch '(?s)UEP_WEAPON_HUD_DIFFERENTIAL_PASSED.*Goodbye Python.*UEP_WEAPON_HUD_SHUTDOWN_PASSED.*Log file closed') {throw 'Strict packaged shutdown ordering failed'}
    foreach($row in @($prepared.hashes)+@($prepared.products)+@($summary.hashes)) {
        if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Frozen current package input/product changed'}
    }
    $imagePath=Join-Path $output 'weapon.png'
    if(!(Test-Path -LiteralPath $imagePath)) {throw 'Actual packaged screenshot missing'}
    $summary.image=@{path=$imagePath;sha256=(Get-FileHash -LiteralPath $imagePath).Hash}
    $summary.packaged_runtime=$true;$summary.status='passed'
} catch {$summary.error=$_.ToString();throw}
finally {$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Current packaged weapon example: $($summary.status)"
