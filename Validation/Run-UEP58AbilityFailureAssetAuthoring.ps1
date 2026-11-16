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
if(!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked stage required'}
if(Test-Path -LiteralPath $output){throw 'Use a fresh authoring evidence directory'}
if(@(Get-Process -Name 'UnrealEditor','UnrealEditor-Cmd','LyraGame' -ErrorAction SilentlyContinue).Count){
    throw 'An Unreal process is already running; authoring must not overlap it'
}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';runtime_acceptance=$false;cpp_compile_executed=$false
    cook_package_executed=$false;hashes=@();process=$null;error=$null}
try {
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        $digest=(Get-FileHash -LiteralPath $source.FullName).Hash
        if($digest -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source differs'}
        foreach($path in @($source.FullName,$target)){$summary.hashes+=@{path=$path;sha256=$digest}}
    }
    $engine=Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json
    $plugin=Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json
    if($engine.BuildId -ne $plugin.BuildId){throw 'Editor BuildId mismatch'}
    $summary.editor_build_id=$engine.BuildId
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        foreach($path in @($source.FullName,$target)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    }
    $relative='Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_AbilityFailureFeedback.uasset'
    $source=Join-Path $overlay $relative;$target=Join-Path $stage $relative
    if(!(Test-Path -LiteralPath $source)){
        $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
        Copy-Item -LiteralPath (Join-Path (Split-Path $marker.source -Parent) $relative) -Destination $target -Force
    }
    $script=Join-Path $repo 'Demos\UEPLyraIntegration\Tools\generate_ability_failure_mixin_assets.py'
    foreach($path in @($script,(Join-Path $repo 'Demos\UEPLyraIntegration\Tools\message_payload_graphs.py'),
                      (Join-Path $repo 'Demos\UEPLyraIntegration\Tools\stage_safety.py'),
                      (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))){
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    $cache=Join-Path $repo '.build\TaskRuntimeCache'
    foreach($directory in @($cache,(Join-Path $cache 'Temp'),(Join-Path $cache 'User'),(Join-Path $cache 'DDC'))){
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $environment=@{'UE-LocalDataCachePath'=(Join-Path $cache 'DDC');TEMP=(Join-Path $cache 'Temp');TMP=(Join-Path $cache 'Temp')}
    $arguments=@($project,'-run=Py',$script,"-UEPAbilityFailureStageRoot=$stage","-UEPGenerateAbilityFailureResult=$output\assets.json",
        "-UserDir=$cache\User\",'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',"-abslog=$output\assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Failure UI asset authoring' 300 $environment
    if(!(Test-Path -LiteralPath (Join-Path $output 'assets.json')) -and !(Test-Path -LiteralPath (Join-Path $output 'assets.log'))){
        throw 'Unreal exited before producing its log or fixture result; initialization was not reached and asset authoring is not accepted'
    }
    $report=Get-Content -LiteralPath (Join-Path $output 'assets.json') -Raw | ConvertFrom-Json -Depth 40
    if($report.status -ne 'passed' -or !$report.class_preserved -or $report.runtime_acceptance -or
        !$report.transport.old_graphs_unchanged -or !$report.transport.text_primitives_have_no_branch_or_string_conversion -or
        $report.native_widget_tick_declared -or $report.tick_declaration_nodes -ne 0 -or !$report.native_latent_completion_declared -or
        !$report.original_proxy_stored -or $report.explicit_listener_entry -ne 'UEPResumeFailureObservation'){throw 'Asset authoring gate incomplete'}
    $log=Get-Content -LiteralPath (Join-Path $output 'assets.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_ABILITY_FAILURE_ASSETS_PASSED'
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Authoring source changed during run'}}
    foreach($relative in @('Content\UEPInterop\BP_UEPGameplayMessages.uasset',
        'Content\UEPMixins\DA_W_AbilityFailureFeedbackMixin.uasset',
        'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_AbilityFailureFeedback.uasset')){
        $from=Join-Path $stage $relative;$to=Join-Path $overlay $relative
        New-Item -ItemType Directory -Path (Split-Path $to -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $from -Destination $to -Force
        if((Get-FileHash -LiteralPath $from).Hash -ne (Get-FileHash -LiteralPath $to).Hash){throw 'Canonical asset copy differs'}
    }
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Failure UI asset authoring: $($summary.status); runtime acceptance is still false"
