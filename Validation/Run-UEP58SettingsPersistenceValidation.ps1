#Requires -Version 7.0
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,[ValidateSet('BlueprintFallback','Python')][string]$Profile='BlueprintFallback',[ValidateSet('write','read_restore')][string]$Mode='write',[Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$UserRoot,[string]$PreviousReport)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory);$user=[IO.Path]::GetFullPath($UserRoot);$prefix=[IO.Path]::GetFullPath("$repo/.build")+[IO.Path]::DirectorySeparatorChar
. "$repo/Validation/UEPValidationProcesses.ps1"
foreach($path in @($stage,$output,$user)){if(!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned output/user path required'}}
if(!(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json")){throw 'Marked full Lyra stage required'}
if((Test-Path -LiteralPath $output) -or ($Mode -eq 'write' -and (Test-Path -LiteralPath $user))){throw 'Fresh output and fresh write-mode user root required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane active'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='actual native setting UI cancel/apply/owned persistence';profile=$Profile;mode=$Mode;user_root=$user;full_acceptance=$false;runtime_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;external_gate=$null;error=$null}
try{
    $scripts="$repo/Demos/UEPLyraIntegration/Overlay/Content/Scripts"
    foreach($source in Get-ChildItem -LiteralPath $scripts -Recurse -File -Filter '*.py'){
        $copy=Join-Path "$stage/Content/Scripts" ([IO.Path]::GetRelativePath($scripts,$source.FullName));New-Item -ItemType Directory -Path (Split-Path $copy -Parent) -Force|Out-Null;Copy-Item -LiteralPath $source.FullName -Destination $copy -Force
        foreach($path in @($source.FullName,$copy)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    }
    foreach($path in @($PSCommandPath,"$repo/Source/UnrealEnginePython/Private/UEPyMixin.cpp","$stage/Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll")){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    if($Mode -eq 'read_restore'){
        if(!(Test-Path -LiteralPath $PreviousReport)){throw 'Previous actual write report required'}
        $summary.hashes+=@{path=$PreviousReport;sha256=(Get-FileHash -LiteralPath $PreviousReport).Hash}
    }
    $arguments=@("$stage/LyraStarterGame.uproject",'/ShooterMaps/Maps/L_FiringRange_WP?NumBots=0','-game','-unattended','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-NoDDCCleanup','-UEPAutoRespawnListeners','-UEPAutoRespawnEvents','-UEPAutoRespawnActivation','-ExecCmds=t.MaxFPS 60',"-UserDir=$user/","-UEPSettingsPersistenceResult=$output/result.json","-UEPSettingsPersistenceUserRoot=$user","-UEPSettingsPersistenceProfile=$Profile","-UEPSettingsPersistenceMode=$Mode","-abslog=$output/runtime.log")
    if($PreviousReport){$arguments+="-UEPSettingsPersistenceWriteReport=$PreviousReport"}
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe') $arguments $stage "$output/runtime" 'Native settings UI owned-user persistence' 300
    $log=Get-Content -LiteralPath "$output/runtime.log" -Raw
    if($log -match 'Traceback|Log\w+:\s*Error:|Ensure condition failed|Fatal error' -or !($log.IndexOf('UEP_SETTINGS_PERSISTENCE_DIFFERENTIAL_PASSED') -ge 0 -and $log.IndexOf('UEP_SETTINGS_PERSISTENCE_DIFFERENTIAL_PASSED') -lt $log.IndexOf('Goodbye Python') -and $log.IndexOf('Goodbye Python') -lt $log.IndexOf('UEP_SETTINGS_PERSISTENCE_SHUTDOWN_PASSED') -and $log.IndexOf('UEP_SETTINGS_PERSISTENCE_SHUTDOWN_PASSED') -lt $log.LastIndexOf('Log file closed'))){throw 'Native settings strict log/order gate failed'}
    $gate=@('-B','-m','uep_lyra_hud.settings_persistence_contract','--report',"$output/result.json")
    if($PreviousReport){$gate+=@('--previous',$PreviousReport)}
    $summary.external_gate=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe') $gate $scripts "$output/gate" 'Independent native settings persistence semantic gate' 30
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen settings input changed'}}
    $summary.runtime_acceptance=$true;$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host 'Native settings persistence scoped gate passed'
