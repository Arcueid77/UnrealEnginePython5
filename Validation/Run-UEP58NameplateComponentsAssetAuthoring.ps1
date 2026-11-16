#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject)
$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked workspace stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Use fresh evidence directory'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*')}).Count){throw 'Matching stage already running'}
$overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
$toolsRoot=Join-Path $repo 'Demos\UEPLyraIntegration\Tools'
$script=Join-Path $toolsRoot 'generate_nameplate_component_mixin_assets.py'
$marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
$referenceRoot=Split-Path $marker.source -Parent
$transport='Content\UEPInterop\BP_UEPGameplayMessages.uasset'
$names=@('NameplateSource','NameplateManagerComponent')
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';runtime_acceptance=$false;cpp_compile_executed=$false
    cook_package_executed=$false;hashes=@();assets=@();process=$null;error=$null}
function Add-NameplateComponentHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try {
    $engineId=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    $pluginId=(Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    if($engineId -ne $pluginId){throw 'Editor BuildId mismatch'}
    $summary.editor_build_id=$engineId
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source mismatch'}
        Add-NameplateComponentHash $source.FullName;Add-NameplateComponentHash $target
    }
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-NameplateComponentHash $source.FullName;Add-NameplateComponentHash $target
    }
    if((Get-FileHash -LiteralPath (Join-Path $overlay $transport)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $stage $transport)).Hash){throw 'Accepted transport differs'}
    Add-NameplateComponentHash (Join-Path $overlay $transport)
    foreach($name in $names){
        $relative="Content\UI\Indicators\$name.uasset"
        $reference=Join-Path $referenceRoot $relative
        Add-NameplateComponentHash $reference
        if(!(Test-Path -LiteralPath (Join-Path $overlay $relative))){Copy-Item -LiteralPath $reference -Destination (Join-Path $stage $relative) -Force}
    }
    foreach($path in @($PSCommandPath,$script,(Join-Path $toolsRoot 'stage_safety.py'),(Join-Path $toolsRoot 'message_payload_graphs.py'),
                       (Join-Path $toolsRoot 'blueprint_graph_digest.py'),(Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))){Add-NameplateComponentHash $path}
    $arguments=@($project,'-run=Py',$script,"-UEPNameplateComponentsStageRoot=$stage","-UEPGenerateNameplateComponentsResult=$output\assets.json",
        '-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',"-abslog=$output\assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Nameplate component authoring' 300
    $report=Get-Content -LiteralPath (Join-Path $output 'assets.json') -Raw|ConvertFrom-Json -Depth 40
    $functions=@($report.transport.functions)
    if($report.status -ne 'passed' -or $report.runtime_acceptance -or !$report.ownership_only -or
        (@($report.components.asset) -join ',') -ne ($names -join ',') -or
        @($report.components|Where-Object {!$_.class_preserved}).Count -ne 0 -or
        !$report.transport.old_graphs_unchanged -or $report.transport.business_logic -or !$report.transport.wildcard_calls_use_compiled_vm -or
        @($report.transport.old_graph_digests.PSObject.Properties).Count -ne 15 -or $functions.Count -ne 19 -or
        ($functions|Measure-Object -Property nodes -Sum).Sum -ne 59){throw 'Nameplate component asset gate incomplete'}
    $log=Get-Content -LiteralPath (Join-Path $output 'assets.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_NAMEPLATE_COMPONENTS_ASSETS_PASSED'
    if($log -notmatch '(?s)UEP_NAMEPLATE_COMPONENTS_ASSETS_PASSED.*Goodbye Python.*Log file closed'){throw 'Nameplate authoring exit incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Nameplate authoring input changed'}}
    $outputs=@($transport)
    foreach($name in $names){$outputs+="Content\UI\Indicators\$name.uasset";$outputs+="Content\UEPMixins\DA_${name}Mixin.uasset"}
    foreach($asset in $outputs){
        $from=Join-Path $stage $asset;$to=Join-Path $overlay $asset
        New-Item -ItemType Directory -Path (Split-Path $to -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $from -Destination $to -Force
        $hash=(Get-FileHash -LiteralPath $from).Hash
        if($hash -ne (Get-FileHash -LiteralPath $to).Hash){throw 'Nameplate canonical copy differs'}
        $summary.assets+=@{stage=$from;overlay=$to;sha256=$hash}
    }
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Nameplate component authoring passed; not runtime acceptance: $output"
