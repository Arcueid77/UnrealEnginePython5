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
if (!(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))) {throw 'Marked disposable stage required'}
if (Test-Path -LiteralPath $output) {throw 'Use a fresh evidence directory'}
if(@(Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*')
}).Count){throw 'Matching stage process already running'}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';full_acceptance=$false;cpp_compile_executed=$false
    cook_package_executed=$false;hashes=@();process=$null;error=$null}
try {
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        $digest=(Get-FileHash -LiteralPath $source.FullName).Hash
        if($digest -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source differs'}
        foreach($path in @($source.FullName,$target)){$summary.hashes+=@{path=$path;sha256=$digest}}
    }
    $overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
    foreach($mapping in @(
        @{source=(Join-Path $overlay 'Content\Scripts');target=(Join-Path $stage 'Content\Scripts')},
        @{source=(Join-Path $repo 'Content\Scripts');target=(Join-Path $stage 'Plugins\UnrealEnginePython\Content\Scripts')}
    )){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File -Filter '*.py'){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $source.FullName -Destination $target -Force
            foreach($path in @($source.FullName,$target)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
        }
    }
    $relative='Content\UEPInterop\BP_UEPGameplayMessages.uasset'
    $source=Join-Path $overlay $relative;$target=Join-Path $stage $relative
    if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Transport asset differs'}
    foreach($path in @($source,$target,(Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))){
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    $engine=Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json
    $plugin=Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json
    if($engine.BuildId -ne $plugin.BuildId){throw 'Editor BuildId mismatch'}
    $summary.editor_build_id=$engine.BuildId
    $arguments=@($project,'/Engine/Maps/Entry?game=/Script/Engine.GameModeBase','-game','-RenderOffscreen',
        '-windowed','-ResX=640','-ResY=360','-NoLoadingScreen',
        '-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',
        "-UEPTypedMessageResult=$output\transport.json","-abslog=$output\transport.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output 'transport') 'Typed UI/Verb transport adapter regression' 180
    $report=Get-Content -LiteralPath (Join-Path $output 'transport.json') -Raw | ConvertFrom-Json
    if($report.status -ne 'passed' -or $report.full_acceptance -or $report.wildcard_process_event_called -or
        $report.native_gameplay_input_tested -or $report.business_migration_complete -or !$report.compiled_vm_transport -or
        !$report.nested_payload_copy_preserved -or !$report.wrong_reader_rejected -or !$report.outside_delivery_rejected -or
        !$report.close_idempotent -or !$report.scopes_closed -or $report.callbacks_after_close -ne 0 -or
        $report.legacy_signals -ne 3 -or @($report.typed_ui).Count -ne 3 -or @($report.typed_verb).Count -ne 1 -or
        $report.typed_verb[0].magnitude -ne 3.5 -or $null -ne $report.error){throw 'Incomplete typed transport regression'}
    if(($report.typed_ui.on -join '|') -ne 'True|False|True' -or
        ($report.typed_ui.local_owner -join '|') -ne 'True|True|False'){throw 'Typed UI payload/owner order differs'}
    $log=Get-Content -LiteralPath (Join-Path $output 'transport.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_TYPED_MESSAGE_PASSED'
    if($log -notmatch '(?s)UEP_TYPED_MESSAGE_PASSED.*Goodbye Python.*Log file closed'){throw 'Transport did not shut down normally'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Transport input changed during validation'}}
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Typed transport regression: $($summary.status); $output"
