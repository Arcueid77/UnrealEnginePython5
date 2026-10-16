#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$AuditDirectory,[Parameter(Mandatory=$true)][string]$OutputDirectory,
      [switch]$Candidate,[string]$AssetAuthoringDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked disposable stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Fresh original context evidence required'}
if([bool]$Candidate -ne [bool]$AssetAuthoringDirectory){throw 'Python smoke requires its accepted native authoring directory'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
$audit=Get-Content -LiteralPath (Join-Path $AuditDirectory 'summary.json') -Raw|ConvertFrom-Json -Depth 70
$proof=Get-Content -LiteralPath (Join-Path $AuditDirectory 'audit.json') -Raw|ConvertFrom-Json -Depth 90
if($audit.status -ne 'passed' -or $proof.status -ne 'passed' -or $proof.runtime_acceptance -or $proof.assets_modified -or @($proof.assets).Count -ne 10){throw 'Original pressed-widget context audit required'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';runtime_acceptance=$false;bounded_original_bp_context=$false
    bounded_python_smoke=$false;source_mode=$(if($Candidate){'PythonSmoke'}else{'OriginalBP'})
    cpp_compile_executed=$false;cook_package_executed=$false;assets_modified=$false;hashes=@();process=$null;external_gate=$null;error=$null}
function Add-ContextHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $id=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $relative
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Native context BuildId mismatch'}
        Add-ContextHash $path
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName))
            if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native context source mismatch'}
            Add-ContextHash $file.FullName;Add-ContextHash $target
        }
    }
    if($Candidate){
        $author=Get-Content -LiteralPath (Join-Path $AssetAuthoringDirectory 'summary.json') -Raw|ConvertFrom-Json -Depth 80
        $authored=Get-Content -LiteralPath (Join-Path $AssetAuthoringDirectory 'assets.json') -Raw|ConvertFrom-Json -Depth 90
        if($author.status -ne 'passed' -or $authored.kind -ne 'widgetpressed' -or !$authored.original_class_defaults_signature_graphs_preserved -or
           !$authored.original_full_cdo_preserved -or !$authored.native_children_unchanged -or @($author.assets).Count -ne 2){throw 'Candidate pressed-widget native authoring proof incomplete'}
        foreach($asset in $author.assets){foreach($path in @($asset.stage,$asset.overlay)){
            if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Candidate asset hash differs'}
            Add-ContextHash $path
        }}
        Add-ContextHash (Join-Path $AssetAuthoringDirectory 'summary.json');Add-ContextHash (Join-Path $AssetAuthoringDirectory 'assets.json')
    }
    foreach($entry in $proof.reference_hashes.PSObject.Properties){
        if($Candidate -and [IO.Path]::GetFullPath($entry.Name) -eq [IO.Path]::GetFullPath((Join-Path $stage 'Plugins/GameFeatures/ShooterCore/Content/Input/Abilities/GAB_ShowWidget_WhenInputPressed.uasset'))){
            if(@($author.assets|Where-Object {[IO.Path]::GetFullPath($_.stage) -eq [IO.Path]::GetFullPath($entry.Name)}).Count -ne 1){throw 'Candidate root missing from authored assets'}
            Add-ContextHash $entry.Name;continue
        }
        if((Get-FileHash -LiteralPath $entry.Name).Hash -ne $entry.Value){throw 'Original context asset changed'}
        Add-ContextHash $entry.Name
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        Add-ContextHash $file.FullName;Add-ContextHash $target
    }
    foreach($path in @($PSCommandPath,(Join-Path $AuditDirectory 'summary.json'),(Join-Path $AuditDirectory 'audit.json'),
        (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),(Join-Path $PSScriptRoot 'LyraHUDContracts.ps1'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){Add-ContextHash $path}
    $arguments=@($StageProject,'/ShooterExplorer/Maps/L_InventoryTestMap?Experience=B_TestInventoryExperience?NumBots=0',
        '-game','-RenderOffscreen','-windowed','-ResX=640','-ResY=360','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-NoLoadingScreen','-NoDDCCleanup','-AsyncLoadingThread','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession',
        '-notraceserver','-trace=none',"-UEPWidgetPressedContextResult=$output/context.json","-abslog=$output/context.log")
    if($Candidate){$arguments+=@('-UEPWidgetPressedContextMode=PythonSmoke')}
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe') $arguments $stage (Join-Path $output 'context') 'Original pressed-widget context gameplay preflight' 180
    $report=Get-Content -LiteralPath "$output/context.json" -Raw|ConvertFrom-Json -Depth 90
    if($report.status -ne 'passed'){throw 'Original pressed-widget runtime context report failed'}
    if($report.source_mode -ne $summary.source_mode){throw 'Pressed-widget context source mode differs'}
    $log=Get-Content -LiteralPath "$output/context.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_WIDGET_PRESSED_CONTEXT_SHUTDOWN_PASSED' -RequirePythonExit
    if($log -match '(?im)Accessed None|Accessed array.*out of bounds'){throw 'Original context has invalid BP runtime state'}
    if($log -notmatch '(?s)UEP_WIDGET_PRESSED_CONTEXT_READY.*Goodbye Python.*UEP_WIDGET_PRESSED_CONTEXT_SHUTDOWN_PASSED.*Log file closed'){throw 'Original context shutdown ordering incomplete'}
    $gateArguments=@('-B','-m','uep_lyra_abilities.widget_pressed_context_contract','--report',"$output/context.json")
    $summary.external_gate=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe') $gateArguments (Join-Path $overlay 'Content/Scripts') (Join-Path $output 'report-gate') 'Original context independent evidence gate' 30
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Original context frozen input changed'}}
    $summary.status='passed';$summary.bounded_original_bp_context=!$Candidate;$summary.bounded_python_smoke=[bool]$Candidate
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Original pressed-widget context: $($summary.status); $output"
