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
if (!(Test-Path -LiteralPath $markerPath)) {throw 'Marked stage required'}
if (Test-Path -LiteralPath $output) {throw 'Use fresh evidence directory'}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';full_acceptance=$false;network_acceptance=$false
    physical_touch_tested=$false;input_suspend_resume_acceptance=$false;cpp_compile_executed=$false
    cook_package_executed=$false;hashes=@();process=$null;image=$null;error=$null}
try {
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File) {
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        $digest=(Get-FileHash -LiteralPath $source.FullName).Hash
        if($digest -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source differs'}
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
    foreach($relative in @('Content\UI\Hud\W_OpenMenuTouchButton.uasset','Content\UEPMixins\DA_W_OpenMenuTouchButtonMixin.uasset')) {
        $source=Join-Path $overlay $relative;$target=Join-Path $stage $relative
        if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Menu asset differs'}
        foreach($path in @($source,$target)){$summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    }
    $marker=Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
    foreach($path in @((Join-Path (Split-Path $marker.source -Parent) 'Content\UI\Hud\W_OpenMenuTouchButton.uasset'),
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
        "-UEPOpenMenuResult=$output\menu.json","-abslog=$output\menu.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.exe') $arguments $stage (Join-Path $output 'menu') 'CommonUI lazy menu BP/Python differential' 240
    $report=Get-Content -LiteralPath (Join-Path $output 'menu.json') -Raw | ConvertFrom-Json
    if($report.status -ne 'passed' -or @($report.cases).Count -ne 3 -or $report.full_acceptance -or
        $report.physical_touch_tested -or $report.class_preloaded_by_probe -or $report.menu_class_loaded_before -or
        $report.python_clicks -ne 1 -or $null -ne $report.error){throw 'Incomplete menu comparison'}
    if(($report.cases.profile -join ',') -ne 'Python,BlueprintFallback,Python'){throw 'Profile roundtrip differs'}
    foreach($case in $report.cases){
        if($case.menu_class -ne 'W_LyraGameMenu_C' -or $case.same_button_class -ne 'W_OpenMenuTouchButton_C' -or
            !$case.active -or !$case.native_async_layer_push -or !$case.native_deactivated){throw 'Menu class or native push/pop differs'}
    }
    if(!$report.cases[0].visible_after_transition){throw 'No rendered active menu'}
    $log=Get-Content -LiteralPath (Join-Path $output 'menu.log') -Raw
    Assert-UEPFocusedLog $log 'UEP_OPEN_MENU_DIFFERENTIAL_PASSED'
    if($log -notmatch 'Goodbye Python'){throw 'Missing native Python shutdown'}
    $imagePath=[IO.Path]::GetFullPath($report.image)
    if($imagePath -ne (Join-Path $output 'open-menu.png')){throw 'Menu screenshot outside evidence directory'}
    $bytes=[IO.File]::ReadAllBytes($imagePath)
    if($bytes.Length -lt 8 -or ($bytes[0..7] -join ',') -ne '137,80,78,71,13,10,26,10'){throw 'Missing rendered menu PNG'}
    $summary.image=@{path=$imagePath;sha256=(Get-FileHash -LiteralPath $imagePath).Hash}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Menu input changed during validation'}}
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Menu BP/Python differential: $($summary.status); $output"
