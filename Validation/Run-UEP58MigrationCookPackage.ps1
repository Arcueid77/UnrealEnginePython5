#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$GameBuildDirectory,
    [Parameter(Mandatory=$true)][string]$PackagePlan)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$buildRoot=[IO.Path]::GetFullPath($GameBuildDirectory);$planPath=[IO.Path]::GetFullPath($PackagePlan)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
foreach($path in @($stage,$output,$buildRoot,$planPath)){if(!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned migration stage/build/plan/output required'}}
if(!(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh archive output required'}
$activeNative=@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')})
if($activeNative.Count){throw 'Another native lane is active'}
$build=Get-Content -LiteralPath "$buildRoot/summary.json" -Raw|ConvertFrom-Json -Depth 50
if($build.status -ne 'passed' -or $build.scope -ne 'current-Development-LyraGame-build-only' -or !$build.no_engine_changes_requested -or $build.process.exit_code -ne 0 -or @($build.products).Count -ne 2){throw 'Accepted current protected Game build required'}
foreach($product in $build.products){if((Get-FileHash -LiteralPath $product.path).Hash -ne $product.sha256){throw 'Built Game product changed'}}
$plan=Get-Content -LiteralPath $planPath -Raw|ConvertFrom-Json -Depth 80
if($plan.status -ne 'passed' -or !$plan.inspection_only -or ($plan.static_scope -join ',') -ne '246,182,63,11' -or @($plan.candidate_assets).Count -ne 246 -or @($plan.accepted_overlay_assets).Count -lt 1 -or @($plan.runtime_maps).Count -lt 12){throw 'Complete original migration package inventory required'}
function Assert-PlanInputs {
    foreach($asset in $plan.candidate_assets){if((Get-FileHash -LiteralPath $asset.stage).Hash -ne $asset.sha256){throw 'Planned candidate asset changed'}}
    foreach($asset in $plan.accepted_overlay_assets){if((Get-FileHash -LiteralPath (Join-Path $stage $asset.relative_path)).Hash -ne $asset.sha256){throw 'Planned overlay asset changed'}}
    foreach($script in $plan.script_hashes){if((Get-FileHash -LiteralPath (Join-Path $stage $script.relative_path)).Hash -ne $script.sha256){throw 'Planned stage script changed'}}
    foreach($map in $plan.runtime_maps){if((Get-FileHash -LiteralPath (Join-Path $stage $map.relative_path)).Hash -ne $map.sha256){throw 'Planned runtime map changed'}}
    if((Get-FileHash -LiteralPath $plan.staged_plugin_descriptor.path).Hash -ne $plan.staged_plugin_descriptor.sha256){throw 'Planned plugin descriptor changed'}
    foreach($input in @($build.hashes)+@($build.engine_inputs)){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Accepted game-build source or protected Engine input changed'}}
}
Assert-PlanInputs
$maps=@($plan.runtime_maps|ForEach-Object {$_.package})+@($plan.engine_entry_map_required)
$directories=@($plan.proposed_cook_directory_paths|ForEach-Object {$_.physical_directory})
foreach($directory in $directories){$absolute=[IO.Path]::GetFullPath($directory);if(!$absolute.StartsWith(($stage+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath $absolute -PathType Container)){throw 'Cook directory escapes or is absent from marked stage'}}
New-Item -ItemType Directory -Path "$output/Archive"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='current-original-migration-content-cook-package';cpp_compile_executed=$false;cook_package_executed=$false;runtime_acceptance=$false;full_acceptance=$false;hashes=@();process=$null;archive="$output/Archive";maps=$maps;cook_directories=$directories;products=@();packaged_executable=$null;packaged_script_count=0;packaged_core_script_count=0;container_listing=$null;container_inspection=$null;package_inventory=$null;error=$null}
function Add-CookHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
$priorLogFolder=$env:uebp_LogFolder;$priorFinalLogFolder=$env:uebp_FinalLogFolder
try{
    foreach($file in @($PSCommandPath,$project,$planPath,"$buildRoot/summary.json","$stage/Config/DefaultGame.ini")){Add-CookHash $file}
    foreach($product in $build.products){Add-CookHash $product.path}
    $coreScripts=Join-Path $repo 'Content/Scripts'
    foreach($source in Get-ChildItem -LiteralPath $coreScripts -Recurse -File -Filter '*.py'){
        $relative=[IO.Path]::GetRelativePath($coreScripts,$source.FullName)
        $copy=Join-Path "$stage/Plugins/UnrealEnginePython/Content/Scripts" $relative
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Current core Python helper differs from stage'}
        Add-CookHash $source.FullName;Add-CookHash $copy
    }
    $env:uebp_LogFolder="$output/UAT";$env:uebp_FinalLogFolder=$env:uebp_LogFolder;New-Item -ItemType Directory -Path $env:uebp_LogFolder|Out-Null
    $dotnet=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/DotNet/10.0/win-x64/dotnet.exe'
    $uat=Join-Path $EngineRoot 'Engine/Binaries/DotNET/AutomationTool/AutomationTool.dll'
    $arguments=@($uat,'BuildCookRun',"-project=$project",'-noP4','-utf8output','-WaitForUATMutex','-unattended','-platform=Win64','-clientconfig=Development','-target=LyraGame','-skipbuild','-SkipBuildEditor','-nocompile','-nocompileeditor','-cook','-stage','-pak','-archive',"-archivedirectory=$output/Archive",('-map='+($maps -join '+')),('-MapsToCook='+($maps -join '+')),('-cookdir='+($directories -join '+')),'-AdditionalCookerOptions=-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging -notraceserver -SkipZenStore','-nodebuginfo')
    $summary.cook_package_executed=$true
    $summary.process=Invoke-UEPValidationProcess $dotnet $arguments $stage (Join-Path $output 'cook-package') 'Current complete migration content cook/package' 7200
    $log=Get-Content -LiteralPath "$output/cook-package-stdout.log" -Raw
    if($log -notmatch 'BUILD SUCCESSFUL' -or $log -notmatch 'AutomationTool exiting with ExitCode=0' -or $log -match '(?im)(Log\w+:\s*Error:|Fatal error:|Assertion failed|Unhandled Exception|Ensure condition failed)' -or $log -match 'Registered Python mixin'){throw 'Cook/package failed strict gate or activated runtime Mixin routing during cook'}
    foreach($file in Get-ChildItem -LiteralPath "$output/Archive" -Recurse -File|Where-Object {$_.Name -eq 'LyraGame.exe' -or $_.Extension -in @('.pak','.utoc','.ucas')}){$summary.products+=@{path=$file.FullName;sha256=(Get-FileHash -LiteralPath $file.FullName).Hash}}
    $internal=Join-Path "$output/Archive/Windows" (([IO.Path]::GetFileNameWithoutExtension($project))+'/Binaries/Win64/LyraGame.exe')
    $gameProduct=@($build.products|Where-Object {[IO.Path]::GetFileName($_.path) -eq 'LyraGame.exe'})
    if($gameProduct.Count -ne 1 -or !(Test-Path -LiteralPath $internal) -or (Get-FileHash -LiteralPath $internal).Hash -ne $gameProduct[0].sha256){throw 'Packaged internal executable differs from accepted current Game build'}
    if(!@($summary.products|Where-Object {[IO.Path]::GetExtension($_.path) -in @('.pak','.utoc','.ucas')}).Count){throw 'Cooked package containers missing'}
    $summary.packaged_executable=$internal
    $packagedProject=Split-Path (Split-Path (Split-Path $internal -Parent) -Parent) -Parent
    foreach($script in $plan.script_hashes){
        $copy=Join-Path $packagedProject $script.relative_path
        if(!(Test-Path -LiteralPath $copy) -or (Get-FileHash -LiteralPath $copy).Hash -ne $script.sha256){throw "Packaged Python script missing or changed: $($script.relative_path)"}
        $summary.packaged_script_count++
    }
    foreach($source in Get-ChildItem -LiteralPath $coreScripts -Recurse -File -Filter '*.py'){
        $copy=Join-Path "$packagedProject/Plugins/UnrealEnginePython/Content/Scripts" ([IO.Path]::GetRelativePath($coreScripts,$source.FullName))
        if(!(Test-Path -LiteralPath $copy) -or (Get-FileHash -LiteralPath $copy).Hash -ne (Get-FileHash -LiteralPath $source.FullName).Hash){throw 'Packaged core Python helper missing or changed'}
        $summary.packaged_core_script_count++
    }
    $unrealPak=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealPak.exe'
    $inspector=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/inspect_migration_container.py'
    Add-CookHash $unrealPak;Add-CookHash $inspector
    $listing=Join-Path $output 'containers.csv'
    $summary.container_listing=Invoke-UEPValidationProcess $unrealPak @("-ListContainer=$packagedProject/Content/Paks","-csv=$listing","-abslog=$output/container-list.log") $stage (Join-Path $output 'container-list') 'Read-only cooked container listing' 180
    $listingLog=Get-Content -LiteralPath "$output/container-list-stdout.log" -Raw
    if($listingLog -match '(?im)(Log\w+:\s*Error:|Fatal error:|Assertion failed|Unhandled Exception|Ensure condition failed)' -or !(Test-Path -LiteralPath $listing)){throw 'Cooked container listing failed strict gate'}
    $python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
    $summary.package_inventory=Join-Path $output 'package-inventory.json'
    $summary.container_inspection=Invoke-UEPValidationProcess $python @('-B',$inspector,'--plan',$planPath,'--csv',$listing,'--result',$summary.package_inventory) $repo (Join-Path $output 'container-inspection') 'Frozen migration package content inventory' 60
    $inventory=Get-Content -LiteralPath $summary.package_inventory -Raw|ConvertFrom-Json -Depth 20
    if($inventory.status -ne 'passed'){throw 'Cook completed but original migration package presence needs explicit missing-content review'}
    Assert-PlanInputs
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Frozen cook input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$env:uebp_LogFolder=$priorLogFolder;$env:uebp_FinalLogFolder=$priorFinalLogFolder;$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Current migration cook/package: $($summary.status); $output"
