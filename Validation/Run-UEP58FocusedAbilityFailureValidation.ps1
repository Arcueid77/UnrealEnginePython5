#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$AssetAuthoringDirectory,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [switch]$WorkspaceRuntimeCache,
    [switch]$CultureIdentity,
    [string]$TextFixtureAssetResult,
    [switch]$NativeProducer,
    [string]$NativeProducerAuditDirectory,
    [switch]$RealForeignOwner
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($NativeProducer -and $CultureIdentity){throw 'Choose either native producer or culture fixture'}
if($RealForeignOwner -and !$NativeProducer){throw 'RealForeignOwner requires the native GAS producer lane'}
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$build=[IO.Path]::GetFullPath((Join-Path $repo '.build'))
$project=[IO.Path]::GetFullPath($StageProject)
$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$authoring=[IO.Path]::GetFullPath($AssetAuthoringDirectory)
foreach($path in @($stage,$output,$authoring)) {
    if(!$path.StartsWith($build+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Stage and evidence must stay inside this workspace .build directory'
    }
}
$markerPath=Join-Path $stage '.uep-lyra-full-stage.json'
if(!(Test-Path -LiteralPath $markerPath)){throw 'Marked disposable full stage required'}
if(Test-Path -LiteralPath $output){throw 'Use a fresh evidence directory'}
if(@(Get-Process -Name 'UnrealEditor','UnrealEditor-Cmd','LyraGame' -ErrorAction SilentlyContinue).Count){
    throw 'An Unreal process is already running; do not duplicate the test'
}
# Preflight must reject this lane before launching UE if authoring never ran.
$assetSummary=Get-Content -LiteralPath (Join-Path $authoring 'summary.json') -Raw | ConvertFrom-Json -Depth 50
if($assetSummary.status -ne 'passed'){throw 'Accepted failure asset authoring is required before launching a runtime fixture'}
$assetReport=Get-Content -LiteralPath (Join-Path $authoring 'assets.json') -Raw | ConvertFrom-Json -Depth 50
if($assetSummary.status -ne 'passed' -or $assetReport.status -ne 'passed' -or
   !$assetReport.class_preserved -or !$assetReport.transport.old_graphs_unchanged -or
   $assetReport.runtime_acceptance -or !$assetReport.original_proxy_stored -or
   $assetReport.native_widget_tick_declared -or $assetReport.tick_declaration_nodes -ne 0 -or !$assetReport.native_latent_completion_declared -or
   $assetReport.explicit_listener_entry -ne 'UEPResumeFailureObservation') {throw 'Accepted failure asset authoring is required'}
$expected=@('ReadUI','ReadVerb','ReadDuration','BroadcastUI','BroadcastVerb','BroadcastDuration',
            'ReadFailure','BroadcastFailure','CopyFailureText','SameFailureText')
if((@($assetReport.transport.functions.name | Sort-Object) -join '|') -ne (@($expected | Sort-Object) -join '|')) {
    throw 'Extended typed transport function inventory differs'
}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';full_acceptance=$false;network_acceptance=$false
    native_ability_producer_tested=$false;native_localized_text_identity_tested=[bool]$CultureIdentity
    runtime_cache_policy=$(if($WorkspaceRuntimeCache){'isolated-workspace-cache'}else{'reuse-existing-runtime-cache'})
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;image=$null;error=$null}
try {
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File) {
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        $digest=(Get-FileHash -LiteralPath $source.FullName).Hash
        if($digest -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source differs from staged binary source'}
        foreach($path in @($source.FullName,$target)){$summary.hashes+=@{path=$path;sha256=$digest}}
    }
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach($mapping in @(
        @{source=(Join-Path $overlay 'Content\Scripts');target=(Join-Path $stage 'Content\Scripts')},
        @{source=(Join-Path $repo 'Content\Scripts');target=(Join-Path $stage 'Plugins\UnrealEnginePython\Content\Scripts')}
    )) {
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File -Filter '*.py') {
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $source.FullName -Destination $target -Force
            foreach($path in @($source.FullName,$target)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
        }
    }
    foreach($relative in @('Content\UEPMixins\DA_W_AbilityFailureFeedbackMixin.uasset',
                          'Content\UEPInterop\BP_UEPGameplayMessages.uasset',
                          'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_AbilityFailureFeedback.uasset')) {
        $source=Join-Path $overlay $relative;$target=Join-Path $stage $relative
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Failure or typed transport asset differs'}
        foreach($path in @($source,$target)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    }
    $marker=Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
    $reference=Join-Path (Split-Path $marker.source -Parent) 'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_AbilityFailureFeedback.uasset'
    if((Get-FileHash -LiteralPath $reference).Hash -ne $assetReport.reference_sha256){throw 'Official reference differs from authoring input'}
    $engineModules=Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json
    $pluginModules=Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json
    if($engineModules.BuildId -ne $pluginModules.BuildId){throw 'Editor/plugin BuildId mismatch'}
    foreach($relative in @('Binaries\Win64\UnrealEditor.modules','Plugins\UEPLyraBridge\Binaries\Win64\UnrealEditor.modules')){
        if((Get-Content -Raw -LiteralPath (Join-Path $stage $relative)|ConvertFrom-Json).BuildId -ne $engineModules.BuildId){throw 'Project/bridge BuildId mismatch'}
    }
    $summary.editor_build_id=$engineModules.BuildId
    # A Blueprint asset's prior authoring provenance is not a DLL BuildId.
    # Preserve it separately; native binaries must match the current Editor.
    $summary.asset_authoring_editor_build_id=$assetSummary.editor_build_id
    if($NativeProducer){
        if(!$NativeProducerAuditDirectory){throw 'Accepted original native producer defaults audit required'}
        $auditSummary=Get-Content -Raw -LiteralPath (Join-Path $NativeProducerAuditDirectory 'summary.json')|ConvertFrom-Json -Depth 30
        $auditPath=Join-Path $NativeProducerAuditDirectory 'audit.json'
        $audit=Get-Content -Raw -LiteralPath $auditPath|ConvertFrom-Json -Depth 90
        if($auditSummary.status -ne 'passed' -or $audit.status -ne 'passed' -or $audit.runtime_acceptance -or $audit.assets_modified -or
           $auditSummary.editor_build_id -ne $engineModules.BuildId){throw 'Original native producer defaults audit incomplete'}
        foreach($input in $audit.reference_hashes.PSObject.Properties){
            if((Get-FileHash -LiteralPath $input.Name).Hash -ne $input.Value){throw 'Original native ability changed since audit'}
            $summary.hashes+=@{path=$input.Name;sha256=(Get-FileHash -LiteralPath $input.Name).Hash}
        }
        foreach($file in @($auditPath,(Join-Path $NativeProducerAuditDirectory 'summary.json'))){
            $summary.hashes+=@{path=$file;sha256=(Get-FileHash -LiteralPath $file).Hash}
        }
    }
    if($CultureIdentity){
        if(!$TextFixtureAssetResult){throw 'Native culture lane requires an accepted text fixture asset report'}
        $fixture=Get-Content -LiteralPath $TextFixtureAssetResult -Raw | ConvertFrom-Json -Depth 30
        if($fixture.status -ne 'passed' -or !$fixture.fixture_only -or $fixture.runtime_acceptance){throw 'Native text fixture not authored'}
        foreach($path in @($TextFixtureAssetResult,(Join-Path $stage 'Content\UEPValidation\BP_UEPFailureTextFixture.uasset'))){
            $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
        }
    }
    foreach($path in @($reference,(Join-Path $authoring 'summary.json'),(Join-Path $authoring 'assets.json'),
                      $PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),
                      (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))) {
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    $cache=Join-Path $build 'TaskRuntimeCache'
    foreach($directory in @('Temp','User','DDC')){New-Item -ItemType Directory -Path (Join-Path $cache $directory) -Force | Out-Null}
    $environment=@{}
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720',
        '-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-ExecCmds=t.MaxFPS 60',
        "-UEPAbilityFailureResult=$output\failure.json","-abslog=$output\failure.log")
    if($CultureIdentity){$arguments+='-UEPAbilityFailureCulture'}
    if($NativeProducer){$arguments+='-UEPAbilityFailureNativeProducer'}
    if($RealForeignOwner){$arguments+='-UEPAbilityFailureRealForeignOwner'}
    if($WorkspaceRuntimeCache){
        $environment=@{'UE-LocalDataCachePath'=(Join-Path $cache 'DDC');TEMP=(Join-Path $cache 'Temp');TMP=(Join-Path $cache 'Temp')}
        $arguments+="-UserDir=$cache\User\"
    }
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output 'failure') 'Failure feedback production BP/Python differential' 300 $environment
    foreach($name in @('failure.json','failure.log')){if(!(Test-Path -LiteralPath (Join-Path $output $name))){throw 'Unreal result/log missing; no runtime acceptance'}}
    $report=Get-Content -LiteralPath (Join-Path $output 'failure.json') -Raw | ConvertFrom-Json -Depth 50
    $python=Join-Path $EngineRoot 'Engine\Binaries\ThirdParty\Python3\Win64\python.exe'
    $contract=Join-Path $overlay $(if($NativeProducer){'Content\Scripts\uep_lyra_hud\ability_failure_native_contract.py'}else{'Content\Scripts\uep_lyra_hud\ability_failure_contract.py'})
    $gateArguments=@('-B',$contract,(Join-Path $output 'failure.json'))
    if($CultureIdentity){$gateArguments+='--culture'}
    $summary.report_gate=Invoke-UEPValidationProcess $python $gateArguments $repo (Join-Path $output 'report-gate') 'Failure feedback evidence gate' 30 $environment
    $log=Get-Content -LiteralPath (Join-Path $output 'failure.log') -Raw
    $prefix=if($NativeProducer){'UEP_FAILURE_NATIVE_'}elseif($CultureIdentity){'UEP_FAILURE_CULTURE_'}else{'UEP_ABILITY_FAILURE_'}
    Assert-UEPFocusedLog $log ($prefix+'DIFFERENTIAL_PASSED')
    Assert-UEPFocusedLog $log ($prefix+'SHUTDOWN_PASSED') -RequirePythonExit
    if($log.IndexOf($prefix+'DIFFERENTIAL_PASSED') -ge $log.IndexOf($prefix+'SHUTDOWN_PASSED')){throw 'Failure marker order differs'}
    $images=if($CultureIdentity -or $NativeProducer){@($report.images)}else{@($report.image)}
    $summary.images=@()
    foreach($image in $images){
        $imagePath=[IO.Path]::GetFullPath($image)
        if((Split-Path $imagePath -Parent) -ne $output){throw 'Failure screenshot outside evidence directory'}
        $bytes=[IO.File]::ReadAllBytes($imagePath)
        if($bytes.Length -lt 8 -or ($bytes[0..7] -join ',') -ne '137,80,78,71,13,10,26,10'){throw 'Missing failure PNG'}
        $summary.images+=@{path=$imagePath;sha256=(Get-FileHash -LiteralPath $imagePath).Hash}
    }
    if(!$CultureIdentity){$summary.image=$summary.images[0]}
    if($NativeProducer){$summary.native_ability_producer_tested=$true;$summary.native_producer_cases=@($report.cases).Count}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Failure input changed during validation'}}
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Failure feedback bounded BP/Python differential: $($summary.status); $output"
