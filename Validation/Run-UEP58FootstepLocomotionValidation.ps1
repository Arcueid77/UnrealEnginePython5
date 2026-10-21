#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$HeroMotionAuthoringDirectory,
    [Parameter(Mandatory=$true)][string]$AnimationAuditDirectory,
    [ValidateSet('Python','BlueprintFallback')][string]$Profile='Python',
    [ValidateRange(1024,65535)][int]$ServerPort=18595)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory);$authorRoot=[IO.Path]::GetFullPath($HeroMotionAuthoringDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
foreach($path in @($stage,$output,$authorRoot)){if(!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Workspace-owned marked stage/evidence required'}}
if(!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json')) -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
$author=Get-Content -LiteralPath "$authorRoot/summary.json" -Raw|ConvertFrom-Json -Depth 100;$proof=Get-Content -LiteralPath "$authorRoot/assets.json" -Raw|ConvertFrom-Json -Depth 100
if($author.status -ne 'passed' -or $proof.status -ne 'passed' -or $proof.kind -ne 'herodefaultmotion' -or !$proof.original_parent_bytes_cdo_public_abis_all_nodes_guids_and_business_graphs_preserved -or !$proof.original_parent_selector_stencil_hide_ragdoll_and_death_methods_preserved -or $proof.method_counts.Python -ne 6 -or $proof.method_counts.BlueprintFallback -ne 6 -or @($author.assets).Count -ne 2){throw 'Accepted six-method original parent motion proof required'}
$socket=[Net.Sockets.UdpClient]::new();try{$socket.Client.ExclusiveAddressUse=$true;$socket.Client.Bind([Net.IPEndPoint]::new([Net.IPAddress]::Loopback,$ServerPort))}finally{$socket.Dispose()}
New-Item -ItemType Directory -Path $output|Out-Null
$auditRoot=[IO.Path]::GetFullPath($AnimationAuditDirectory);if(!$auditRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned original animation audit required'}
$audit=Get-Content -LiteralPath "$auditRoot/audit.json" -Raw|ConvertFrom-Json -Depth 50;$auditSummary=Get-Content -LiteralPath "$auditRoot/summary.json" -Raw|ConvertFrom-Json -Depth 50
if($audit.status -ne 'passed' -or $auditSummary.status -ne 'passed' -or $auditSummary.process.exit_code -ne 0 -or !$audit.source_animations_byte_identical -or $audit.runtime_dispatch_tested -or @($audit.sequences).Count -ne 5 -or $audit.native_context_notify_count -ne 28){throw 'Accepted read-only original native animation audit required'}
$run=[guid]::NewGuid().ToString('N');$handles=@{};$summary=[ordered]@{schema_version=1;status='failed';run_id=$run;runtime_scope='Actual owner Enhanced Input movement and AnimBP notification; server authority movement observation';profile=$Profile;network_acceptance=$false;full_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();server_rendering='RenderOffscreen320x180';client_rendering='RenderOffscreen';processes=@{};external_gates=@{};error=$null}
function Add-MotionHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
function Read-MotionState([string]$File){
    $stream=$null;$reader=$null
    try{$stream=[IO.File]::Open($File,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete));$reader=[IO.StreamReader]::new($stream,[Text.Encoding]::UTF8,$true);return ($reader.ReadToEnd()|ConvertFrom-Json -Depth 90)}
    catch [IO.IOException]{return $null}
    finally{if($null -ne $reader){$reader.Dispose()}elseif($null -ne $stream){$stream.Dispose()}}
}
try{
    $engineModule=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules';$build=(Get-Content -LiteralPath $engineModule -Raw|ConvertFrom-Json).BuildId;Add-MotionHash $engineModule
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){$file=Join-Path $stage $relative;if((Get-Content -LiteralPath $file -Raw|ConvertFrom-Json).BuildId -ne $build){throw 'Matching native BuildIds required'};Add-MotionHash $file}
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},@{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){$copy=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName));if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Native source mismatch'};Add-MotionHash $file.FullName;Add-MotionHash $copy}
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){$copy=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName));New-Item -ItemType Directory -Path (Split-Path $copy -Parent) -Force|Out-Null;Copy-Item -LiteralPath $file.FullName -Destination $copy -Force;Add-MotionHash $file.FullName;Add-MotionHash $copy}
    foreach($asset in $author.assets){foreach($file in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $file).Hash -ne $asset.sha256){throw 'Parent motion asset changed'};Add-MotionHash $file}}
    if(!$proof.motion_caller.stage_only -or (Get-FileHash -LiteralPath $proof.motion_caller.asset).Hash -ne $proof.motion_caller.sha256){throw 'Native typed motion caller changed'}
    Add-MotionHash $proof.motion_caller.asset;Add-MotionHash "$authorRoot/summary.json";Add-MotionHash "$authorRoot/assets.json"
    Add-MotionHash "$auditRoot/audit.json";Add-MotionHash "$auditRoot/summary.json"
    foreach($entry in $audit.frozen_asset_hashes.PSObject.Properties){if((Get-FileHash -LiteralPath $entry.Name).Hash -ne $entry.Value){throw 'Original animation changed'};Add-MotionHash $entry.Name}
    $assetHashes=[ordered]@{}
    foreach($relative in @('Content/Characters/Heroes/B_SimpleHeroPawn.uasset','Plugins/GameFeatures/ShooterExplorer/Content/Blueprint/B_SimpleFollowPawn.uasset','Plugins/GameFeatures/ShooterExplorer/Content/Blueprint/B_SimpleFollowPawn_Big.uasset','Plugins/GameFeatures/ShooterExplorer/Content/Blueprint/B_Hero_Explorer.uasset','Plugins/GameFeatures/ShooterExplorer/Content/Blueprint/B_Pawn_Explorer.uasset','Plugins/GameFeatures/ShooterCore/Content/Game/B_Hero_ShooterMannequin.uasset','Content/Effects/Blueprints/B_FootStep.uasset','Content/UEPMixins/DA_FootstepMixin.uasset')){
        foreach($root in @($stage,$overlay)){$file=Join-Path $root $relative;if(Test-Path -LiteralPath $file){$assetHashes[$file]=(Get-FileHash -LiteralPath $file).Hash;Add-MotionHash $file}}
    }
    $assetHashes|ConvertTo-Json -Depth 5|Set-Content -LiteralPath "$output/motion-assets.json" -Encoding utf8
    foreach($file in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),(Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'),(Join-Path $stage 'Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll'),(Join-Path $EngineRoot 'Engine/Source/Runtime/Engine/Private/GameplayStatics.cpp'),(Join-Path $EngineRoot 'Engine/Source/Runtime/Engine/Private/KismetSystemLibrary.cpp'))){Add-MotionHash $file}
    $common=@('-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360','-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup','-ExecCmds=t.MaxFPS 60','-Multiprocess',"-UEPFootstepLocomotionProfile=$Profile","-UEPFootstepAnimationAudit=$auditRoot/audit.json","-UEPFootstepAnimationRun=$run","-UEPFootstepAnimationHashes=$output/motion-assets.json",'-UEPAutoRespawnListeners','-UEPAutoRespawnEvents','-UEPAutoRespawnActivation')
    foreach($role in @('server','client')){
        $url=if($role -eq 'server'){'/ShooterMaps/Maps/L_FiringRange_WP?listen?NumBots=0'}else{"127.0.0.1:$ServerPort"};$arguments=@($project,$url)+$common+@("-UEPFootstepAnimationRole=$role","-UEPFootstepLocomotionResult=$output/$role.json","-abslog=$output/$role.log","-UserDir=$output/$role-user/")
        if($role -eq 'server'){$arguments=@($arguments|Where-Object {$_ -notlike '-ResX=*' -and $_ -notlike '-ResY=*'})+@('-ResX=320','-ResY=180',"-port=$ServerPort",'-multihome=127.0.0.1')}
        $handles[$role]=Start-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe') $arguments $stage (Join-Path $output $role) $role
    }
    $timer=[Diagnostics.Stopwatch]::StartNew()
    while($true){
        $ready=@('server','client')|Where-Object {Test-Path -LiteralPath "$output/ready-$_.json"}
        if(@($ready).Count -eq 2){break}
        foreach($role in @('server','client')){if($handles[$role].process.HasExited){throw "Motion peer $role exited early"};$report=Read-MotionState "$output/$role.json";if($null -ne $report -and $report.status -eq 'failed'){throw "Motion peer $role failed"}}
        if($timer.Elapsed.TotalSeconds -gt 360){throw 'Motion readiness or native lifetime timed out'};Start-Sleep -Milliseconds 200
    }
    foreach($role in @('server','client')){if((Get-Content -LiteralPath "$output/ready-$role.json" -Raw|ConvertFrom-Json).run_id -ne $run){throw 'Foreign motion readiness file'}}
    @{run_id=$run}|ConvertTo-Json|Set-Content -LiteralPath "$output/release.tmp" -Encoding utf8;Move-Item -LiteralPath "$output/release.tmp" -Destination "$output/release.json"
    foreach($role in @('server','client')){
        if(!$handles[$role].process.WaitForExit(60000)){throw 'Motion peer shutdown timed out'};$summary.processes[$role]=Complete-UEPValidationProcess $handles[$role];if($summary.processes[$role].exit_code -ne 0){throw 'Animation native peer exit failure'}
        $report=Get-Content -LiteralPath "$output/$role.json" -Raw|ConvertFrom-Json -Depth 90;if($report.status -ne 'passed'){throw "Motion peer $role report gate failed"}
        $log=Get-Content -LiteralPath "$output/$role.log" -Raw;Assert-UEPFocusedLog $log 'UEP_FOOTSTEP_LOCOMOTION_DIFFERENTIAL_PASSED';Assert-UEPFocusedLog $log 'UEP_FOOTSTEP_LOCOMOTION_SHUTDOWN_PASSED' -RequirePythonExit
        $summary.external_gates[$role]=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe') @('-B','-m','uep_lyra_weapons.footstep_locomotion_contract','--report',"$output/$role.json") (Join-Path $overlay 'Content/Scripts') (Join-Path $output "$role-gate") 'Native locomotion independent gate' 30
    }
    foreach($frozen in $summary.hashes){if((Get-FileHash -LiteralPath $frozen.path).Hash -ne $frozen.sha256){throw 'Motion frozen input changed'}};$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{foreach($role in @($handles.Keys)){ $handle=$handles[$role];Stop-UEPValidationProcess $handle;$summary.processes[$role]=Complete-UEPValidationProcess $handle;$handle.process.Dispose()};$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Native listen-server/client parent motion: $($summary.status); $output"
