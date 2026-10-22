#Requires -Version 7.0
param(
    [string]$EngineRoot='F:/UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet('Python','BlueprintFallback')][string]$Profile='Python',
    [switch]$NaturalBomb
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject)
$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath("$repo/.build")+[IO.Path]::DirectorySeparatorChar
. "$PSScriptRoot/UEPValidationProcesses.ps1"
foreach($path in @($stage,$output)){if(!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned marked stage/output required'}}
if(!(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane active'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='Actual Arena two-local-player native input/drop/cost/instigator ownership';profile=$Profile;full_acceptance=$false;network_acceptance=$false;packaged_runtime=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;external_gate=$null;error=$null}
if($NaturalBomb){$summary.scope='Actual Arena original input/natural bomb self-death/native HUD with foreign local-player control'}
function Add-InputHash([string]$Path){$summary.hashes+=@{path=[IO.Path]::GetFullPath($Path);sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $overlay="$repo/Demos/UEPLyraIntegration/Overlay"
    foreach($source in Get-ChildItem -LiteralPath "$overlay/Content/Scripts" -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-InputHash $source.FullName;Add-InputHash $target
    }
    foreach($author in @('20261021-arena-drop-bomb/Assets01','20261021-arena-bomb-base/Assets02','20261021-arena-bomb-visual/Assets01')){
        $root="$repo/.build/LyraValidation/BlueprintPython/$author"
        $value=Get-Content -LiteralPath "$root/summary.json" -Raw|ConvertFrom-Json -Depth 80
        $proof=Get-Content -LiteralPath "$root/assets.json" -Raw|ConvertFrom-Json -Depth 80
        if($value.status -ne 'passed' -or $proof.status -ne 'passed'){throw 'Accepted original Arena family authoring required'}
        foreach($asset in $value.assets){foreach($file in @($asset.stage,$asset.overlay)){if((Get-FileHash -LiteralPath $file).Hash -ne $asset.sha256){throw 'Accepted Arena asset changed'};Add-InputHash $file}}
        Add-InputHash "$root/summary.json";Add-InputHash "$root/assets.json"
    }
    if($NaturalBomb){
        $arenaAssets=@(Get-ChildItem -LiteralPath "$overlay/Plugins/GameFeatures/TopDownArena/Content" -Recurse -File -Filter '*.uasset')+@(Get-ChildItem -LiteralPath "$overlay/Content/UEPMixins" -File -Filter 'DA_Arena*.uasset')
        foreach($source in $arenaAssets){
            $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
            if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Arena family staged asset differs from checked source'}
            Add-InputHash $source.FullName;Add-InputHash $target
        }
    }
    $probeRoot="$repo/.build/LyraValidation/BlueprintPython/20261021-arena-bomb-base/Probe01"
    $probe=Get-Content -LiteralPath "$probeRoot/probe.json" -Raw|ConvertFrom-Json
    if($probe.status -ne 'passed' -or !$probe.stage_only -or $probe.gameplay_business -or (Get-FileHash -LiteralPath $probe.asset).Hash -ne $probe.sha256){throw 'Verified read-only native attribute observer required'}
    Add-InputHash $probe.asset;Add-InputHash "$probeRoot/probe.json"
    $marker=Get-Content -LiteralPath "$stage/.uep-lyra-full-stage.json" -Raw|ConvertFrom-Json
    $official=Split-Path $marker.source -Parent
    foreach($relative in @('Plugins/GameFeatures/TopDownArena/Content/Maps/L_TopDown_LocalMultiplayer.umap','Plugins/GameFeatures/TopDownArena/Content/Game/InputData_Arena.uasset','Plugins/GameFeatures/TopDownArena/Content/Game/AbilitySet_Arena.uasset','Plugins/GameFeatures/TopDownArena/Content/Game/HeroData_Arena.uasset')){
        $a=Join-Path $stage $relative;$b=Join-Path $official $relative
        if((Get-FileHash -LiteralPath $a).Hash -ne (Get-FileHash -LiteralPath $b).Hash){throw 'Original Arena map/input/ability data changed'}
        Add-InputHash $a;Add-InputHash $b
    }
    $build=(Get-Content -LiteralPath "$EngineRoot/Engine/Binaries/Win64/UnrealEditor.modules" -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $file=Join-Path $stage $relative
        if((Get-Content -LiteralPath $file -Raw|ConvertFrom-Json).BuildId -ne $build){throw 'Editor BuildId differs'}
        Add-InputHash $file
    }
    foreach($file in @($PSCommandPath,"$PSScriptRoot/UEPValidationProcesses.ps1","$repo/Source/UnrealEnginePython/Private/UEPyMixin.cpp","$repo/Source/UnrealEnginePython/Private/UObject/UEPyInput.cpp","$stage/Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll","$stage/Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll","$EngineRoot/Engine/Source/Runtime/Engine/Private/GameInstance.cpp","$EngineRoot/Engine/Source/Runtime/Slate/Private/Framework/Application/SlateApplication.cpp","$repo/Source/UnrealEnginePython/Private/SlateApplication/UEPyFSlateApplication.cpp","$repo/Source/UnrealEnginePython/Private/Slate/UEPyFCharacterEvent.cpp")){Add-InputHash $file}
    $resultFlag=if($NaturalBomb){'UEPArenaNaturalResult'}else{'UEPArenaLocalInputResult'}
    $profileFlag=if($NaturalBomb){'UEPArenaNaturalProfile'}else{'UEPArenaLocalInputProfile'}
    $arguments=@($project,'/TopDownArena/Maps/L_TopDown_LocalMultiplayer?NumBots=0','-game','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720','-unattended','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup','-ExecCmds=t.MaxFPS 60',"-UserDir=$output/user/","-$resultFlag=$output/result.json","-$profileFlag=$Profile","-abslog=$output/runtime.log")
    if($NaturalBomb){$arguments+=@('-FixedSeed','-UseFixedTimeStep','-FPS=60')}
    $summary.process=Invoke-UEPValidationProcess "$EngineRoot/Engine/Binaries/Win64/UnrealEditor.exe" $arguments $stage "$output/runtime" 'Arena local input ownership' 300
    $log=Get-Content -LiteralPath "$output/runtime.log" -Raw
    $marker=if($NaturalBomb){'UEP_ARENA_NATURAL'}else{'UEP_ARENA_LOCAL_INPUT'}
    if($log -match 'Traceback|Log\w+:\s*Error:|Ensure condition failed|Fatal error' -or !($log.IndexOf($marker+'_DIFFERENTIAL_PASSED') -ge 0 -and $log.IndexOf($marker+'_DIFFERENTIAL_PASSED') -lt $log.IndexOf('Goodbye Python') -and $log.IndexOf('Goodbye Python') -lt $log.IndexOf($marker+'_SHUTDOWN_PASSED') -and $log.IndexOf($marker+'_SHUTDOWN_PASSED') -lt $log.LastIndexOf('Log file closed'))){throw 'Arena native strict log/order gate failed'}
    if($log -notmatch 'Slate User Registered\.  User Index 1' -or $log -notmatch 'Slate User Destroyed\.  User Index 1'){throw 'Owned synthetic Slate user lifetime incomplete'}
    $contract=if($NaturalBomb){'uep_lyra_abilities.arena_natural_bomb_contract'}else{'uep_lyra_abilities.arena_local_input_contract'}
    $summary.external_gate=Invoke-UEPValidationProcess "$EngineRoot/Engine/Binaries/ThirdParty/Python3/Win64/python.exe" @('-B','-m',$contract,'--report',"$output/result.json") "$overlay/Content/Scripts" "$output/gate" 'Independent Arena local-player semantic gate' 30
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Arena frozen native input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host 'Arena two-local-player input ownership gate passed'
