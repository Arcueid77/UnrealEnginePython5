#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/Full/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet('BlueprintFallback','Python')][string]$Profile='Python')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
    !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json')) -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh workspace output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or
    ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='Original Arena two-local-player native bomb/opponent death/kill and team score';profile=$Profile
    full_acceptance=$false;network_acceptance=$false;packaged_runtime=$false;cpp_compile_executed=$false;cook_package_executed=$false
    assets_saved=$false;bounded_pose_fixture_used=$true;hashes=@();process=$null;external_gate=$null;error=$null}
function Add-ArenaHash([string]$Path){$summary.hashes+=@{path=[IO.Path]::GetFullPath($Path);sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    $build=(Get-Content -LiteralPath "$EngineRoot/Engine/Binaries/Win64/UnrealEditor.modules" -Raw|ConvertFrom-Json).BuildId
    foreach($name in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $name
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $build){throw 'Native BuildId mismatch'}
        Add-ArenaHash $path
    }
    $sdkPath=Join-Path $repo '.build/LyraValidation/BlueprintPython/20261023-pawn-sdk-causality/SDKBuild01/summary.json'
    $sdk=Get-Content -LiteralPath $sdkPath -Raw|ConvertFrom-Json -Depth 30
    if($sdk.process.exit_code -ne 0){throw 'Accepted current SDK build required'}
    foreach($row in @($sdk.source_hashes)+@($sdk.binary_after)){
        if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Current SDK source/binary differs from reviewed build'}
        Add-ArenaHash $row.path
    }
    Add-ArenaHash $sdkPath
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName))
            if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source parity mismatch'}
            Add-ArenaHash $file.FullName;Add-ArenaHash $target
        }
    }
    foreach($file in Get-ChildItem -LiteralPath "$overlay/Content/Scripts" -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        if(!(Test-Path -LiteralPath $target) -or (Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){Copy-Item -LiteralPath $file.FullName -Destination $target}
        Add-ArenaHash $file.FullName;Add-ArenaHash $target
    }
    $arenaAssets=@(Get-ChildItem -LiteralPath "$overlay/Plugins/GameFeatures/TopDownArena/Content" -Recurse -File -Filter '*.uasset')+
        @(Get-ChildItem -LiteralPath "$overlay/Content/UEPMixins" -File -Filter 'DA_Arena*.uasset')
    foreach($file in $arenaAssets){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Accepted Arena asset changed'}
        Add-ArenaHash $file.FullName;Add-ArenaHash $target
    }
    $probeRoot=Join-Path $repo '.build/LyraValidation/BlueprintPython/20261021-arena-bomb-base/Probe01'
    $probe=Get-Content -LiteralPath "$probeRoot/probe.json" -Raw|ConvertFrom-Json
    if($probe.status -ne 'passed' -or !$probe.stage_only -or $probe.gameplay_business -or (Get-FileHash -LiteralPath $probe.asset).Hash -ne $probe.sha256){throw 'Verified read-only Arena attribute observer required'}
    Add-ArenaHash $probe.asset;Add-ArenaHash "$probeRoot/probe.json"
    Add-ArenaHash "$stage/Content/UEPValidation/BP_GamePhaseProbe.uasset"
    $marker=Get-Content -LiteralPath "$stage/.uep-lyra-full-stage.json" -Raw|ConvertFrom-Json
    $official=Split-Path $marker.source -Parent
    foreach($relative in @('Plugins/GameFeatures/TopDownArena/Content/Maps/L_TopDown_LocalMultiplayer.umap','Plugins/GameFeatures/TopDownArena/Content/Game/InputData_Arena.uasset','Plugins/GameFeatures/TopDownArena/Content/Game/AbilitySet_Arena.uasset','Plugins/GameFeatures/TopDownArena/Content/Game/HeroData_Arena.uasset')){
        $a=Join-Path $stage $relative;$b=Join-Path $official $relative
        if((Get-FileHash -LiteralPath $a).Hash -ne (Get-FileHash -LiteralPath $b).Hash){throw 'Original Arena map/input/ability data changed'}
        Add-ArenaHash $a;Add-ArenaHash $b
    }
    foreach($file in Get-ChildItem -LiteralPath "$stage/Config" -Recurse -File){Add-ArenaHash $file.FullName}
    foreach($file in @($PSCommandPath,$project,"$PSScriptRoot/UEPValidationProcesses.ps1","$PSScriptRoot/LyraHUDContracts.ps1",
        "$stage/Binaries/Win64/UnrealEditor-LyraGame.dll","$stage/Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll","$stage/Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll")){Add-ArenaHash $file}
    $arguments=@($project,'/TopDownArena/Maps/L_TopDown_LocalMultiplayer?NumBots=0','-game','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720',
        '-unattended','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython','-FixedSeed',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup','-ExecCmds=t.MaxFPS 60',
        "-UserDir=$output/user/","-UEPArenaOpponentResult=$output/result.json","-UEPArenaOpponentProfile=$Profile","-abslog=$output/runtime.log")
    $summary.process=Invoke-UEPValidationProcess -Executable "$EngineRoot/Engine/Binaries/Win64/UnrealEditor.exe" -Arguments $arguments -WorkingDirectory $stage -LogPrefix "$output/runtime" -Name "Arena opponent bomb: $Profile" -TimeoutSeconds 240
    $log=Get-Content -LiteralPath "$output/runtime.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_ARENA_OPPONENT_SHUTDOWN_PASSED' -RequirePythonExit
    if($log -notmatch '(?s)UEP_ARENA_OPPONENT_DIFFERENTIAL_PASSED.*Goodbye Python.*UEP_ARENA_OPPONENT_SHUTDOWN_PASSED.*Log file closed'){throw 'Arena native shutdown ordering incomplete'}
    if($log -notmatch 'Slate User Registered\.  User Index 1' -or $log -notmatch 'Slate User Destroyed\.  User Index 1'){throw 'Owned Slate user lifetime incomplete'}
    $summary.external_gate=Invoke-UEPValidationProcess -Executable "$EngineRoot/Engine/Binaries/ThirdParty/Python3/Win64/python.exe" -Arguments @('-B','-X','utf8','-m','uep_lyra_abilities.arena_opponent_bomb_contract','--report',"$output/result.json") -WorkingDirectory $repo -LogPrefix "$output/gate" -Name 'Independent Arena opponent bomb gate' -TimeoutSeconds 30 -Environment @{PYTHONPATH="$overlay/Content/Scripts"}
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen Arena native input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
