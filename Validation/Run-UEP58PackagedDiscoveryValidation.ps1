#Requires -Version 7.0
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,[Parameter(Mandatory=$true)][string]$AuthoringDirectory,[ValidateSet('Editor','Packaged')][string]$Mode='Packaged',[Parameter(Mandatory=$true)][string]$OutputDirectory,[string]$CookDirectory)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=Split-Path $PSScriptRoot -Parent;$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent;$authorRoot=[IO.Path]::GetFullPath($AuthoringDirectory);$output=[IO.Path]::GetFullPath($OutputDirectory)
. "$repo/Validation/UEPValidationProcesses.ps1"
$prefix=[IO.Path]::GetFullPath("$repo/.build")+[IO.Path]::DirectorySeparatorChar
foreach($path in @($stage,$authorRoot)){if(!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned stage/authoring paths required'}}
if(!(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json")){throw 'Marked full Lyra stage required'}
if(!$output.StartsWith([IO.Path]::GetFullPath("$repo/.build")+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Fresh owned runtime evidence required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane active'}
$author=Get-Content -LiteralPath "$authorRoot/summary.json" -Raw|ConvertFrom-Json -Depth 30
if($author.status -ne 'passed' -or $author.process.exit_code -ne 0){throw 'Accepted fresh authoring required'}
$executable=(Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe');$working=$stage;$entry=@("$stage/LyraStarterGame.uproject",'/Engine/Maps/Entry?game=/Script/Engine.GameModeBase','-game');$packageInputs=@()
if($Mode -eq 'Packaged'){
    $cookRoot=[IO.Path]::GetFullPath($CookDirectory)
    if(!$cookRoot.StartsWith([IO.Path]::GetFullPath("$repo/.build")+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned current package required'}
    $cook=Get-Content -LiteralPath "$cookRoot/summary.json" -Raw|ConvertFrom-Json -Depth 40
    if($cook.status -ne 'passed' -or $cook.scope -ne 'current-original-migration-content-cook-package' -or $cook.process.exit_code -ne 0){throw 'Accepted current complete migration cook required'}
    $executable=[IO.Path]::GetFullPath($cook.packaged_executable);$working=Split-Path $executable -Parent
    if(!$executable.StartsWith(([IO.Path]::GetFullPath($cook.archive)+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)){throw 'Runtime escapes accepted archive'}
    $entry=@("-basedir=$working",'/Engine/Maps/Entry?game=/Script/Engine.GameModeBase')
    $packageInputs=@($cook.hashes)+@($cook.products)+@(@{path="$cookRoot/summary.json";sha256=(Get-FileHash -LiteralPath "$cookRoot/summary.json").Hash})
}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='fresh-process actor imported-actor widget and precompiled-caller automatic discovery';mode=$Mode;packaged_runtime=($Mode -eq 'Packaged');runtime_acceptance=$false;full_acceptance=$false;cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;external_gate=$null;error=$null}
try{
    foreach($row in @($author.assets)+$packageInputs){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Authored asset or accepted package changed'};$summary.hashes+=$row}
    foreach($path in @($PSCommandPath,$executable,"$authorRoot/assets.json","$repo/Source/UnrealEnginePython/Private/UEPyMixin.cpp","$stage/Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll")){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    $arguments=$entry+@('-unattended','-NullRHI','-NoSound','-NoSplash','-NoLoadingScreen','-culture=en','-LogCmds=LogAutomationTest Log','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',"-UEPPackagedDiscoveryAssets=$authorRoot/assets.json","-UEPPackagedDiscoveryResult=$output/result.json","-abslog=$output/runtime.log","-UserDir=$output/user/")
    $summary.process=Invoke-UEPValidationProcess $executable $arguments $working "$output/runtime" 'Fresh-process actual automatic discovery' 300
    $log=Get-Content -LiteralPath "$output/runtime.log" -Raw
    if($log -match 'Traceback|Log\w+:\s*Error:|Ensure condition failed|Fatal error' -or !($log.IndexOf('UEP_PACKAGED_DISCOVERY_DIFFERENTIAL_PASSED') -ge 0 -and $log.IndexOf('UEP_PACKAGED_DISCOVERY_DIFFERENTIAL_PASSED') -lt $log.IndexOf('Goodbye Python') -and $log.IndexOf('Goodbye Python') -lt $log.IndexOf('UEP_PACKAGED_DISCOVERY_SHUTDOWN_PASSED') -and $log.IndexOf('UEP_PACKAGED_DISCOVERY_SHUTDOWN_PASSED') -lt $log.LastIndexOf('Log file closed'))){throw 'Discovery strict log/order gate failed'}
    $summary.external_gate=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe') @('-B','-m','uep_packaged_discovery_contract','--report',"$output/result.json") "$repo/Demos/UEPLyraIntegration/Overlay/Content/Scripts" "$output/gate" 'Independent actual discovery semantic gate' 30
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen runtime input changed'}}
    $summary.runtime_acceptance=$true;$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Fresh actual $Mode discovery gate: $($summary.status)"
