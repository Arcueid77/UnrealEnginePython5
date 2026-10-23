#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/Full/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet('BlueprintFallback','Python')][string]$Profile='Python',[ValidateRange(1024,65535)][int]$ServerPort=54912)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
    !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json')) -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh workspace output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';bounded_runtime_acceptance=$false;full_acceptance=$false;network_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;assets_saved=$false;hashes=@();process=$null;external_gate=$null;error=$null}
function Read-ExplorerLiveJson([string]$Path){
    if(!(Test-Path -LiteralPath $Path)){return $null}
    try{$stream=[IO.FileStream]::new($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))}
    catch{
        if($_.Exception.InnerException -is [IO.FileNotFoundException] -or $_.Exception -is [IO.FileNotFoundException]){return $null}
        throw
    }
    try{$reader=[IO.StreamReader]::new($stream,[Text.Encoding]::UTF8);try{return ($reader.ReadToEnd()|ConvertFrom-Json -Depth 80)}finally{$reader.Dispose()}}finally{$stream.Dispose()}
}
$handles=@{};$summary.processes=@{}
function Add-FailureHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $build=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($name in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $name
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $build){throw 'Native BuildId mismatch'}
        Add-FailureHash $path
    }
    $sdkPath=Join-Path $repo '.build/LyraValidation/BlueprintPython/20261023-current-third-person/SDKBuild01/summary.json'
    $sdk=Get-Content -LiteralPath $sdkPath -Raw|ConvertFrom-Json -Depth 30
    foreach($row in $sdk.source_hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Reviewed SDK source changed'};Add-FailureHash $row.path}
    foreach($row in $sdk.binary_after){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Current SDK binary changed'};Add-FailureHash $row.path}
    Add-FailureHash $sdkPath
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName))
            if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source parity mismatch'}
            Add-FailureHash $file.FullName;Add-FailureHash $target
        }
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content/Scripts') -Filter '*.py' -Recurse -File){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        if(!(Test-Path -LiteralPath $target) -or (Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){Copy-Item -LiteralPath $file.FullName -Destination $target}
        Add-FailureHash $file.FullName;Add-FailureHash $target
    }
    foreach($file in Get-ChildItem -LiteralPath $overlay -Filter '*.uasset' -Recurse -File){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        if((Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){throw 'Accepted overlay asset differs from stage'}
        Add-FailureHash $file.FullName;Add-FailureHash $target
    }
    $contract=Join-Path $overlay 'Content/Scripts/uep_lyra_abilities/explorer_actions_network_contract.py'
    foreach($path in @($PSCommandPath,$project,$contract,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'))){Add-FailureHash $path}
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $stage 'Config') -Recurse -File){Add-FailureHash $file.FullName}
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $stage 'Content/UEPValidation') -Filter '*.uasset' -Recurse -File){Add-FailureHash $file.FullName}
    foreach($relative in @('Maps/L_InteractionTestMap.umap','Items/B_InteractableRock.uasset','Items/B_InteractableChair.uasset','System/Experiences/B_TestInventoryExperience.uasset','Game/HeroData_Explorer.uasset','Input/Abilities/AbilitySet_InventoryTest.uasset')){
        $current=Join-Path $stage "Plugins/GameFeatures/ShooterExplorer/Content/$relative"
        $original=Join-Path 'F:/LyraStarterGame' "Plugins/GameFeatures/ShooterExplorer/Content/$relative"
        if((Get-FileHash -LiteralPath $current).Hash -ne (Get-FileHash -LiteralPath $original).Hash){throw "Original Explorer map/config input differs: $relative"}
        Add-FailureHash $current;Add-FailureHash $original
    }
    $base=@($project,'/ShooterExplorer/Maps/L_InteractionTestMap','-unattended','-nop4','-NoSplash','-NoLoadingScreen','-culture=en','-UTF8Output','-DisablePython','-NoDDCCleanup',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        "-UEPExplorerActionsProfile=$Profile",'-ini:Engine:[OnlineSubsystem]:DefaultPlatformService=Null','-ini:Engine:[OnlineServices]:DefaultServices=Null')
    foreach($peer in @('server','A','B0')){
        $arguments=@($base)
        if($peer -eq 'server'){$arguments+=@('-server','-NullRHI','-NoSound',"-port=$ServerPort",'-multihome=127.0.0.1');$exe='UnrealEditor-Cmd.exe'}
        else{
            $arguments[1]="127.0.0.1:$ServerPort"+"?Name=UEPExplorer_$peer"
            $arguments+=@('-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360','-DeterministicAudio',
                '-ExecCmds=t.MaxFPS 30,sg.ShadowQuality 0,sg.GlobalIlluminationQuality 0,sg.ReflectionQuality 0,r.Streaming.PoolSize 256');$exe='UnrealEditor.exe'
        }
        $arguments+=@("-UEPExplorerActionsPeer=$peer","-UEPExplorerActionsNetworkResult=$output/$peer.json","-abslog=$output/$peer.log")
        $handles[$peer]=Start-UEPValidationProcess -Executable (Join-Path $EngineRoot "Engine/Binaries/Win64/$exe") -Arguments $arguments -WorkingDirectory $stage -LogPrefix "$output/$peer" -Name "Explorer predicted interaction $Profile $peer"
        if($peer -eq 'server'){
            $timer=[Diagnostics.Stopwatch]::StartNew()
            while($true){
                if($handles.server.process.HasExited){throw 'Explorer server exited before listen'}
                if((Test-Path -LiteralPath "$output/server.log") -and (Get-Content -LiteralPath "$output/server.log" -Raw) -match "listening on port $ServerPort"){break}
                if($timer.Elapsed.TotalSeconds -gt 90){throw 'Explorer server listen timeout'}
                Start-Sleep -Milliseconds 250
            }
        }
    }
    $timer=[Diagnostics.Stopwatch]::StartNew()
    while(@($handles.Values|Where-Object {!$_.process.HasExited}).Count){
        if($timer.Elapsed.TotalSeconds -gt 290){throw 'Explorer predicted interaction native network timeout'}
        foreach($peer in @('server','A','B0')){
            if($handles[$peer].process.HasExited -and $null -eq $handles[$peer].result){
                $summary.processes[$peer]=Complete-UEPValidationProcess $handles[$peer]
                if($summary.processes[$peer].exit_code -ne 0){throw "Explorer peer $peer exited with error"}
                if($peer -ne 'server'){@{peer=$peer;exit_code=0}|ConvertTo-Json|Set-Content -LiteralPath "$output/$peer-exited.json" -Encoding utf8}
            }
            $report=Read-ExplorerLiveJson "$output/$peer.json"
            if($null -ne $report -and $report.status -eq 'failed'){throw "Explorer peer $peer failed: $($report.error)"}
        }
        Start-Sleep -Milliseconds 250
    }
    foreach($peer in @('server','A','B0')){
        if($null -eq $handles[$peer].result){$summary.processes[$peer]=Complete-UEPValidationProcess $handles[$peer]}
        if($summary.processes[$peer].exit_code -ne 0){throw 'Explorer native peer nonzero exit'}
        $log=Get-Content -LiteralPath "$output/$peer.log" -Raw
        Assert-UEPFocusedLog $log 'UEP_EXPLORER_ACTIONS_NETWORK_PASSED' -RequirePythonExit
        if($log -notmatch '(?s)UEP_EXPLORER_ACTIONS_NETWORK_READY.*Goodbye Python.*UEP_EXPLORER_ACTIONS_NETWORK_PASSED.*Log file closed'){throw 'Explorer peer shutdown ordering incomplete'}
    }
    $python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
    $summary.external_gate=Invoke-UEPValidationProcess -Executable $python -Arguments @('-B','-X','utf8',$contract,'--directory',$output) -WorkingDirectory $repo -LogPrefix "$output/gate" -Name 'Explorer actual predicted interaction semantic gate' -TimeoutSeconds 30
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen Explorer network input changed'}}
    $summary.status='passed';$summary.bounded_runtime_acceptance=$true;$summary.network_acceptance=$true
}catch{$summary.error=$_.ToString();throw}
finally{
    foreach($peer in @($handles.Keys)){
        Stop-UEPValidationProcess $handles[$peer];$summary.processes[$peer]=$handles[$peer].result;$handles[$peer].process.Dispose()
    }
    $summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8
}
