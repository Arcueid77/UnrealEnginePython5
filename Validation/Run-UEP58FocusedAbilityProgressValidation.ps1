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
$markerPath=Join-Path $stage '.uep-lyra-full-stage.json'
if (!(Test-Path -LiteralPath $markerPath)) {throw 'Marked disposable stage required'}
if (Test-Path -LiteralPath $output) {throw 'Use a fresh evidence directory'}
$running=@(Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*')
})
if($running.Count){throw 'A matching stage process is already running; do not duplicate the test'}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';full_acceptance=$false;network_acceptance=$false
    test_owned_pair=$false;production_reachability_tested=$true;native_interaction_producer_tested=$false
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;image=$null;error=$null}
try {
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File) {
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        $digest=(Get-FileHash -LiteralPath $source.FullName).Hash
        if($digest -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source differs from the staged binary source'}
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
    foreach($relative in @('Content\UEPMixins\DA_W_AbilityProgressMixin.uasset',
                          'Content\UEPInterop\BP_UEPGameplayMessages.uasset',
                          'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_AbilityProgress.uasset')) {
        $source=Join-Path $overlay $relative;$target=Join-Path $stage $relative
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Progress or typed transport asset differs'}
        foreach($path in @($source,$target)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    }
    $marker=Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
    foreach($path in @((Join-Path (Split-Path $marker.source -Parent) 'Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_AbilityProgress.uasset'),
                      (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))) {
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    $engineModules=Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json
    $pluginModules=Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json
    if($engineModules.BuildId -ne $pluginModules.BuildId){throw 'Native Editor BuildId mismatch'}
    $summary.editor_build_id=$engineModules.BuildId
    $arguments=@($project,'/ShooterMaps/Maps/L_Expanse?NumBots=3','-game','-RenderOffscreen','-windowed','-ResX=1280','-ResY=720',
        '-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none','-ExecCmds=t.MaxFPS 60',
        "-UEPAbilityProgressResult=$output\progress.json","-abslog=$output\progress.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output 'progress') 'Ability progress original BP/Python game-time differential' 300
    $report=Get-Content -LiteralPath (Join-Path $output 'progress.json') -Raw | ConvertFrom-Json
    $names=@('initial-collapsed','typed-owner-duration','foreign-owner-ignored','repeated-duration-restarts',
             'paused-game-time-frozen','last-second-precision','countdown-completed','hidden-blueprint-resume',
             'hidden-python-resume','resumed-message-exact-once','destruct-no-late-delivery','same-widget-native-reconstruct')
    if($report.status -ne 'passed' -or @($report.cases).Count -ne $names.Count -or
        $report.full_acceptance -or $report.network_acceptance -or $report.test_owned_pair -or
        !$report.production_reachability_tested -or $report.production_default_profile -ne 'Python' -or
        $report.production_widget -notmatch 'W_ShooterHUDLayout.*W_AbilityProgress' -or $report.native_interaction_producer_tested -or
        $report.widget_tick_invoked_by_fixture -or !$report.compiled_vm_transport -or !$report.profile_resume_explicit -or
        $report.paused_wall_seconds -lt 1.0 -or $null -ne $report.error){throw 'Incomplete progress comparison'}
    if(($report.cases.name -join '|') -ne ($names -join '|')){throw 'Missing, duplicated or reordered progress case'}
    foreach($case in $report.cases){
        foreach($key in @('duration','start','visibility','text')){
            if($key -eq 'start' -and $case.name -eq 'initial-collapsed'){continue}
            if($case.python.$key -ne $case.blueprint.$key){throw 'Progress model/text/visibility differs'}
        }
        if([math]::Abs($case.python.percent-$case.blueprint.percent) -ge 0.00001 -or
            ($case.python.active_range -join '|') -ne ($case.blueprint.active_range -join '|')){throw 'Progress material differs'}
    }
    foreach($name in @('typed-owner-duration','repeated-duration-restarts','last-second-precision','resumed-message-exact-once','same-widget-native-reconstruct')){
        if(($report.cases | Where-Object name -eq $name).automatic_ticks -le 1){throw 'Missing automatic UMG Tick'}
    }
    $final=$report.shutdown
    if($final.active_count -ne 0 -or $final.scopes_created -lt 3 -or
        $final.scopes_created -ne $final.scopes_closed -or @($final.errors).Count){throw 'Progress scope shutdown incomplete'}
    $log=Get-Content -LiteralPath (Join-Path $output 'progress.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_ABILITY_PROGRESS_DIFFERENTIAL_PASSED'
    Assert-UEPFocusedLog $log 'UEP_ABILITY_PROGRESS_SHUTDOWN_PASSED' -RequirePythonExit
    $imagePath=[IO.Path]::GetFullPath($report.image)
    if($imagePath -ne (Join-Path $output 'ability-progress.png')){throw 'Progress screenshot outside evidence directory'}
    $bytes=[IO.File]::ReadAllBytes($imagePath)
    if($bytes.Length -lt 8 -or ($bytes[0..7] -join ',') -ne '137,80,78,71,13,10,26,10'){throw 'Missing progress PNG'}
    $summary.image=@{path=$imagePath;sha256=(Get-FileHash -LiteralPath $imagePath).Hash}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Progress input changed during validation'}}
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Ability progress BP/Python differential: $($summary.status); $output"
