#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/Full/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet('Python','BlueprintFallback')][string]$Profile='Python',
    [ValidateSet('Frontend','Experience','Host','Replay','Settings')][string]$Scenario='Frontend',
    [ValidateSet('life','quit','quick','host','write','read_restore')][string]$Mode='life',
    [string]$UserRoot,[string]$PreviousReport)
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
$lanes=@{
    Frontend=@{prefix='UEPFrontendMenu';marker='UEP_FRONTEND_MENU';contract='frontend_menu_contract.py';modes=@('life','quit')}
    Experience=@{prefix='UEPExperienceScreen';marker='UEP_EXPERIENCE_SCREEN';contract='experience_screen_contract.py';modes=@('life','quick')}
    Host=@{prefix='UEPHostSession';marker='UEP_HOST_SESSION';contract='host_session_contract.py';modes=@('life','host')}
    Replay=@{prefix='UEPReplayRuntime';marker='UEP_REPLAY_RUNTIME';contract='replay_runtime_contract.py';modes=@('life')}
    Settings=@{prefix='UEPSettingsPersistence';marker='UEP_SETTINGS_PERSISTENCE';contract='settings_persistence_contract.py';modes=@('write','read_restore')}
}
$lane=$lanes[$Scenario]
if($Mode -notin $lane.modes){throw 'Unsupported UI scenario/mode pair'}
if($Scenario -eq 'Settings'){
    if(!$UserRoot){throw 'Owned shared-settings user root required'}
    $user=[IO.Path]::GetFullPath($UserRoot)
    if(!$user.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or ($Mode -eq 'write' -and (Test-Path -LiteralPath $user))){throw 'Fresh marked settings user directory required for write'}
    if($Mode -eq 'read_restore'){
        if(!$PreviousReport -or ![IO.Path]::GetFullPath($PreviousReport).StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath $PreviousReport) -or !(Test-Path -LiteralPath $user)){throw 'Owned previous actual settings write required'}
    }
}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scenario=$Scenario;mode=$Mode;profile=$Profile;bounded_runtime_acceptance=$false;full_acceptance=$false;network_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;assets_saved=$false;hashes=@();process=$null;external_gate=$null;error=$null}
function Add-FailureHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $build=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($name in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $name
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $build){throw 'Native BuildId mismatch'}
        Add-FailureHash $path
    }
    $sdkPath=Join-Path $repo '.build/LyraValidation/BlueprintPython/20261023-pawn-sdk-causality/SDKBuild01/summary.json'
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
    $contract=Join-Path $overlay ("Content/Scripts/uep_lyra_hud/"+$lane.contract)
    foreach($path in @($PSCommandPath,$project,$contract,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'))){Add-FailureHash $path}
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $stage 'Config') -Recurse -File){Add-FailureHash $file.FullName}
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $stage 'Content/UEPValidation') -Filter '*.uasset' -Recurse -File){Add-FailureHash $file.FullName}
    $nativeGuard=Join-Path $repo '.build/LyraValidation/BlueprintPython/20261026-pawn-init-guard/Build04LinkResume/summary.json'
    $guard=Get-Content -LiteralPath $nativeGuard -Raw|ConvertFrom-Json -Depth 30
    if($guard.status -ne 'passed'){throw 'Accepted isolated native guard build required'}
    foreach($row in @($guard.products)+@($guard.protected)){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Native guard/protected input changed'};Add-FailureHash $row.path}
    Add-FailureHash $nativeGuard
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=0','-game','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720','-NoLoadingScreen',
        '-ExecCmds=t.MaxFPS 60','-unattended','-nop4','-DeterministicAudio','-NoSplash','-culture=en','-UTF8Output','-DisablePython','-NoDDCCleanup',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        "-$($lane.prefix)Result=$output/result.json","-$($lane.prefix)Profile=$Profile","-$($lane.prefix)Mode=$Mode","-abslog=$output/result.log","-UserDir=$output/user/",'-UEPAutoRespawnListeners','-UEPAutoRespawnEvents','-UEPAutoRespawnActivation',
        '-ini:Engine:[OnlineSubsystem]:DefaultPlatformService=Null','-ini:Engine:[OnlineServices]:DefaultServices=Null')
    if($Scenario -eq 'Replay'){$arguments+="-UEPReplayBrowserProfile=$Profile"}
    if($Scenario -eq 'Settings'){
        $arguments=@($arguments|Where-Object {!$_.StartsWith('-UserDir=')})
        $arguments+=@("-UserDir=$user/","-UEPSettingsPersistenceUserRoot=$user")
        if($Mode -eq 'read_restore'){Add-FailureHash ([IO.Path]::GetFullPath($PreviousReport));$arguments+="-UEPSettingsPersistenceWriteReport=$([IO.Path]::GetFullPath($PreviousReport))"}
    }
    $summary.process=Invoke-UEPValidationProcess -Executable (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe') -Arguments $arguments -WorkingDirectory $stage -LogPrefix "$output/result" -Name 'Current native UI navigation and session path refresh' -TimeoutSeconds 420
    $python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
    $summary.external_gate=Invoke-UEPValidationProcess -Executable $python -Arguments @('-B','-X','utf8',$contract,'--report',"$output/result.json") -WorkingDirectory $repo -LogPrefix "$output/gate" -Name 'Native UI routes semantic gate' -TimeoutSeconds 30 -Environment @{PYTHONPATH=(Join-Path $overlay 'Content/Scripts')}
    $log=Get-Content -LiteralPath "$output/result.log" -Raw
    if($log -notmatch 'Using Audio Hardware Device Non-realtime Renderer'){throw 'UI routes lane requires the existing offline native audio renderer'}
    Assert-UEPFocusedLog $log ($lane.marker+'_SHUTDOWN_PASSED') -RequirePythonExit
    if($log -notmatch ("(?s)"+$lane.marker+"_DIFFERENTIAL_PASSED.*Goodbye Python.*"+$lane.marker+"_SHUTDOWN_PASSED.*Log file closed")){throw 'UI routes native shutdown ordering incomplete'}
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen UI routes input changed'}}
    $summary.status='passed';$summary.bounded_runtime_acceptance=$true
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
