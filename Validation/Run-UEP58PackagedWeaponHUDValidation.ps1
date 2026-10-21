#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$CookPackageDirectory,[Parameter(Mandatory=$true)][string]$OutputDirectory)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
. (Join-Path $PSScriptRoot 'LyraWeaponHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory);$cookRoot=[IO.Path]::GetFullPath($CookPackageDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
foreach($path in @($output,$cookRoot)){if(!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned archive/output required'}}
if(Test-Path -LiteralPath $output){throw 'Fresh isolated package snapshot required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane active'}
$cook=Get-Content -LiteralPath "$cookRoot/summary.json" -Raw|ConvertFrom-Json -Depth 40
if($cook.status -ne 'passed' -or $cook.scope -ne 'current-original-migration-content-cook-package' -or $cook.process.exit_code -ne 0){throw 'Accepted current migration content package required'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='isolated actual packaged weapon/ammo UMG BP/Python comparison and lifetime';packaged_runtime=$false;full_acceptance=$false;network_acceptance=$false;build_executed=$false;cook_package_executed=$false;hashes=@();derived_products=@();script_overrides=@();copy_process=$null;process=$null;error=$null}
function Add-Input([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    foreach($row in @($cook.hashes)+@($cook.products)){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Accepted base package or input changed'};$summary.hashes+=$row}
    $planPath=@($cook.hashes|Where-Object {$_.path -like '*package-plan*.json'})
    if($planPath.Count -ne 1){throw 'Frozen base package plan required'}
    $plan=Get-Content -LiteralPath $planPath[0].path -Raw|ConvertFrom-Json -Depth 60
    $baseArchive=[IO.Path]::GetFullPath($cook.archive);$archive=Join-Path $output 'Archive'
    $python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
    $copyCode='import shutil,sys;shutil.copytree(sys.argv[1],sys.argv[2],copy_function=shutil.copy2)'
    $summary.copy_process=Invoke-UEPValidationProcess $python @('-B','-c',$copyCode,$baseArchive,$archive) $repo (Join-Path $output 'snapshot-copy') 'Independent writable package copy; base immutable' 300
    foreach($row in $cook.products){
        $copy=Join-Path $archive ([IO.Path]::GetRelativePath($baseArchive,$row.path))
        if((Get-FileHash -LiteralPath $copy).Hash -ne $row.sha256){throw 'Copied native/cooked product differs'}
        $summary.derived_products+=@{path=$copy;sha256=$row.sha256}
    }
    $executable=Join-Path $archive ([IO.Path]::GetRelativePath($baseArchive,$cook.packaged_executable));$binary=Split-Path $executable -Parent
    $projectRoot=Split-Path (Split-Path $binary -Parent) -Parent
    $relative='Content/Scripts/uep_lyra_hud/weapon_validation.py'
    foreach($script in $plan.script_hashes){$copy=Join-Path $projectRoot $script.relative_path;if((Get-FileHash -LiteralPath $copy).Hash -ne $script.sha256){throw 'Base project Python payload differs'}}
    $source=Join-Path $repo ('Demos/UEPLyraIntegration/Overlay/'+$relative);$target=Join-Path $projectRoot $relative
    $prior=(Get-FileHash -LiteralPath $target).Hash;Copy-Item -LiteralPath $target -Destination (Join-Path $output 'base-weapon-validation.py')
    Copy-Item -LiteralPath $source -Destination $target -Force
    $summary.script_overrides+=@{relative_path=$relative;source=$source;target=$target;base_sha256=$prior;sha256=(Get-FileHash -LiteralPath $target).Hash;scope='validation shutdown evidence only'}
    foreach($file in @($PSCommandPath,$source,$target,(Join-Path $PSScriptRoot 'LyraWeaponHUDContracts.ps1'),(Join-Path $cookRoot 'summary.json'))){Add-Input $file}
    $arguments=@("-basedir=$binary",'/Engine/Maps/Entry?game=/Script/Engine.GameModeBase','-unattended','-RenderOffscreen','-windowed','-ResX=1440','-ResY=900','-ForceRes','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-ExecCmds=t.MaxFPS 60',"-UEPLyraWeaponHUDResult=$output/weapon.json","-abslog=$output/weapon.log","-UserDir=$output/user/")
    $summary.process=Invoke-UEPValidationProcess $executable $arguments $binary (Join-Path $output 'weapon') 'Actual packaged BP/Python weapon presenters' 300
    $report=Get-Content -LiteralPath "$output/weapon.json" -Raw|ConvertFrom-Json -Depth 50
    Assert-LyraWeaponHUDData $report;Assert-LyraWeaponLifecycleData $report
    if($report.shutdown.phase -ne 'python_atexit' -or !$report.shutdown.owned_resources_closed_before_exit){throw 'Weapon exit phase or owned cleanup proof missing'}
    $log=Get-Content -LiteralPath "$output/weapon.log" -Raw;Assert-UEPFocusedLog $log 'UEP_WEAPON_HUD_DIFFERENTIAL_PASSED';Assert-UEPFocusedLog $log 'UEP_WEAPON_HUD_SHUTDOWN_PASSED' -RequirePythonExit
    if($log -match 'Traceback' -or !($log.IndexOf('UEP_WEAPON_HUD_DIFFERENTIAL_PASSED') -lt $log.IndexOf('Goodbye Python') -and $log.IndexOf('Goodbye Python') -lt $log.IndexOf('UEP_WEAPON_HUD_SHUTDOWN_PASSED'))){throw 'Weapon strict shutdown ordering failed'}
    foreach($row in @($summary.hashes)+@($summary.derived_products)){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen base/snapshot/runtime input changed'}}
    $summary.packaged_runtime=$true;$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host 'Packaged weapon HUD comparison and lifetime gate passed; full version remains open'
