#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,
      [Parameter(Mandatory=$true)][string]$ReferenceRunDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked workspace stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Fresh initialization evidence directory required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame.*|UnrealBuildTool|AutomationTool)\.exe$'}).Count){throw 'Native validation lane is occupied'}
$referencePath=Join-Path $ReferenceRunDirectory 'summary.json'
$reference=Get-Content -LiteralPath $referencePath -Raw|ConvertFrom-Json -Depth 50
if($reference.status -ne 'passed' -or !$reference.quickbar_slots_acceptance -or @($reference.processes.PSObject.Properties).Count -ne 4 -or
   @($reference.processes.PSObject.Properties|Where-Object {$_.Value.exit_code -ne 0}).Count){throw 'Accepted current four-process QuickBar reference required'}
$overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
$assets=@()
foreach($relative in @('Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_QuickBarSlot.uasset','Content\UEPMixins\DA_W_QuickBarSlotMixin.uasset','Content\UEPInterop\BP_UEPGameplayMessages.uasset')){
    foreach($root in @($stage,$overlay)){
        $path=Join-Path $root $relative
        $pins=@($reference.input_hashes|Where-Object {$_.path -eq $path}|Select-Object -ExpandProperty sha256 -Unique)
        if($pins.Count -ne 1 -or (Get-FileHash -LiteralPath $path).Hash -ne $pins[0]){throw 'Current QuickBar class/Mixin/typed-transport differs from native reference'}
        $assets+=@{path=$path;sha256=$pins[0]}
    }
}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';mode='quickbar-native-initialization';process=$null;external_gate=$null
    hashes=@();error=$null;native_initialization_parity_tested=$false;cpp_compile_executed=$false;cook_package_executed=$false;full_acceptance=$false}
$nativeHandle=$null;$gateHandle=$null
function Add-InitializationHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $engineId=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries\Win64\UnrealEditor.modules','Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules','Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor.modules')){
        $path=Join-Path $stage $relative
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $engineId){throw 'Native module BuildId mismatch'}
        Add-InitializationHash $path
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins\UnrealEnginePython\Source')},
        @{source=(Join-Path $repo 'Demos\UEPLyraIntegration\Plugins\UEPLyraBridge\Source');target=(Join-Path $stage 'Plugins\UEPLyraBridge\Source')})){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source mismatch'}
            Add-InitializationHash $source.FullName;Add-InitializationHash $target
        }
    }
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-InitializationHash $source.FullName;Add-InitializationHash $target
    }
    foreach($asset in $assets){Add-InitializationHash $asset.path}
    foreach($relative in @('Binaries\Win64\UnrealEditor-LyraGame.dll','Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll','Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor-UEPLyraBridge.dll')){Add-InitializationHash (Join-Path $stage $relative)}
    foreach($path in @($PSCommandPath,$referencePath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'))){Add-InitializationHash $path}
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    Add-InitializationHash (Join-Path (Split-Path $marker.source -Parent) 'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_QuickBarSlot.uasset')
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360',
        '-NoLoadingScreen','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        '-ExecCmds=t.MaxFPS 60','-ini:Engine:[Python]:ImportModules=uep_lyra_hud.quickbar_initialization_validation',
        "-UEPQuickBarInitializationResult=$output\initialization.json","-abslog=$output\initialization.log")
    $nativeHandle=Start-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'native') 'Native QuickBar initialization'
    if(!$nativeHandle.process.WaitForExit(240000)){throw 'Native QuickBar initialization timeout'}
    $summary.process=Complete-UEPValidationProcess $nativeHandle
    if($summary.process.exit_code -ne 0){throw 'Native initialization process failed'}
    $python=Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\Python3\Win64\python.exe'
    $contract=Join-Path $overlay 'Content\Scripts\uep_lyra_hud\quickbar_initialization_contract.py'
    $gateHandle=Start-UEPValidationProcess $python @('-B','-X','utf8',$contract,'--report',(Join-Path $output 'initialization.json')) $repo (Join-Path $output 'gate') 'Native initialization report gate'
    if(!$gateHandle.process.WaitForExit(30000)){throw 'Initialization report gate timeout'}
    $summary.external_gate=Complete-UEPValidationProcess $gateHandle
    if($summary.external_gate.exit_code -ne 0){throw 'Native initialization report rejected'}
    $summary.report_gate=Get-Content -LiteralPath (Join-Path $output 'gate-stdout.log') -Raw|ConvertFrom-Json
    $log=Get-Content -LiteralPath (Join-Path $output 'initialization.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_QUICKBAR_INIT_SHUTDOWN_PASSED' -RequirePythonExit
    if($log -notmatch '(?s)UEP_QUICKBAR_INIT_DIFFERENTIAL_PASSED.*Goodbye Python.*UEP_QUICKBAR_INIT_SHUTDOWN_PASSED.*Log file closed'){throw 'Native initialization shutdown order differs'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Initialization frozen input changed'}}
    $summary.status='passed';$summary.native_initialization_parity_tested=$true
}catch{$summary.error=$_.ToString();throw}
finally{
    if($null -ne $nativeHandle){Stop-UEPValidationProcess $nativeHandle;$summary.process=Complete-UEPValidationProcess $nativeHandle;$nativeHandle.process.Dispose()}
    if($null -ne $gateHandle){Stop-UEPValidationProcess $gateHandle;$summary.external_gate=Complete-UEPValidationProcess $gateHandle;$gateHandle.process.Dispose()}
    $summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8
}
Write-Host "Native QuickBar initialization: $($summary.status)"
