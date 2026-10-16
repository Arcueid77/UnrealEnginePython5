#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked disposable stage/output required'}
if(Test-Path $output){throw 'Fresh authoring evidence directory required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Native lane already active'}
New-Item -ItemType Directory -Path "$output/PreviousAssets"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';runtime_acceptance=$false;full_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();assets=@();process=$null;error=$null}
function Add-JumpHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash $Path).Hash}}
try{
    $id=(Get-Content (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules')){
        $file=Join-Path $stage $relative
        if((Get-Content $file -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Native BuildId mismatch'}
        Add-JumpHash $file
    }
    foreach($file in Get-ChildItem (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins/UnrealEnginePython/Source/'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$file.FullName))
        if((Get-FileHash $file.FullName).Hash -ne (Get-FileHash $target).Hash){throw 'Native source mismatch'}
        Add-JumpHash $file.FullName;Add-JumpHash $target
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($file in Get-ChildItem (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        Add-JumpHash $file.FullName;Add-JumpHash $target
    }
    $marker=Get-Content (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    foreach($name in @('GA_Hero_Jump','GA_AbilityWithWidget')){
        $relative="Content/Characters/Heroes/Abilities/$name.uasset"
        $original=Join-Path (Split-Path $marker.source -Parent) $relative;$copy=Join-Path $stage $relative
        if((Get-FileHash $original).Hash -ne (Get-FileHash $copy).Hash){throw 'Fresh unchanged jump/widget stage assets required'}
        Copy-Item -LiteralPath $copy -Destination "$output/PreviousAssets/$name.uasset"
        Add-JumpHash $original;Add-JumpHash "$output/PreviousAssets/$name.uasset"
    }
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_jump_ability_mixin_assets.py'
    Add-JumpHash $script;Add-JumpHash $PSCommandPath
    Add-JumpHash (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll')
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        "-UEPJumpStageRoot=$stage","-UEPJumpAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Original jump/shared-widget Interface authoring' 240
    $report=Get-Content "$output/assets.json" -Raw|ConvertFrom-Json -Depth 90
    if($report.status -ne 'passed' -or $report.runtime_acceptance -or !$report.original_class_defaults_signatures_and_graphs_preserved -or
       @($report.assets).Count -ne 4 -or @($report.classes).Count -ne 2){throw 'Jump/shared-widget asset proof incomplete'}
    $log=Get-Content "$output/assets.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_JUMP_ABILITY_ASSETS_PASSED'
    if($log -notmatch '(?s)UEP_JUMP_ABILITY_ASSETS_PASSED.*Goodbye Python.*Log file closed'){throw 'Jump asset exit ordering incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash $input.path).Hash -ne $input.sha256){throw 'Jump authoring frozen input changed'}}
    foreach($relative in $report.assets){
        $source=Join-Path $stage $relative;$target=Join-Path $overlay $relative
        if(Test-Path $target){throw 'Do not overwrite an existing Overlay ability asset'}
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source -Destination $target
        $summary.assets+=@{stage=$source;overlay=$target;sha256=(Get-FileHash $source).Hash}
    }
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 12|Set-Content "$output/summary.json" -Encoding utf8}
Write-Host "Original jump/shared-widget asset authoring: $($summary.status); $output"
