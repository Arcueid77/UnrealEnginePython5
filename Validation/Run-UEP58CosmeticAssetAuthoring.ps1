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
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked disposable stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Fresh cosmetic authoring evidence required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path "$output/PreviousAssets"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';runtime_acceptance=$false;full_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();assets=@();process=$null;error=$null}
function Add-CosmeticHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $id=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $relative
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Native BuildId mismatch'}
        Add-CosmeticHash $path
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source parity mismatch'}
            Add-CosmeticHash $source.FullName;Add-CosmeticHash $target
        }
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-CosmeticHash $source.FullName;Add-CosmeticHash $target
    }
    $marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    foreach($name in @('B_CharacterSelection','B_PickRandomCharacter')){
        $relative="Content/Characters/Cosmetics/$name.uasset"
        $original=Join-Path (Split-Path $marker.source -Parent) $relative;$copy=Join-Path $stage $relative
        if((Get-FileHash -LiteralPath $original).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw 'Fresh original cosmetic stage asset required'}
        if(Test-Path -LiteralPath (Join-Path $overlay $relative)){throw 'Do not overwrite existing Overlay assets'}
        Copy-Item -LiteralPath $copy -Destination "$output/PreviousAssets/$name.uasset"
        Add-CosmeticHash $original;Add-CosmeticHash "$output/PreviousAssets/$name.uasset"
    }
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_cosmetic_mixin_assets.py'
    foreach($path in @($PSCommandPath,$script,(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),
        (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/mixin_graph_gates.py'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){Add-CosmeticHash $path}
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none',
        "-UEPCosmeticStageRoot=$stage","-UEPCosmeticAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Retained cosmetic component Interface authoring' 240
    $report=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 80
    if($report.status -ne 'passed' -or !$report.original_classes_defaults_signatures_graphs_preserved -or
       @($report.assets).Count -ne 4 -or $report.runtime_acceptance){throw 'Cosmetic authoring proof incomplete'}
    $log=Get-Content -LiteralPath "$output/assets.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_COSMETIC_ASSETS_PASSED'
    if($log -notmatch '(?s)UEP_COSMETIC_ASSETS_PASSED.*Goodbye Python.*Log file closed'){throw 'Cosmetic authoring exit ordering incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Frozen cosmetic authoring input changed'}}
    foreach($relative in $report.assets){
        $source=Join-Path $stage $relative;$target=Join-Path $overlay $relative
        if(Test-Path -LiteralPath $target){throw 'Do not overwrite existing Overlay output'}
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force|Out-Null
        Copy-Item -LiteralPath $source -Destination $target
        $hash=(Get-FileHash -LiteralPath $source).Hash
        if((Get-FileHash -LiteralPath $target).Hash -ne $hash){throw 'Cosmetic output copy differs'}
        $summary.assets+=@{stage=$source;overlay=$target;sha256=$hash}
    }
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Retained cosmetic component authoring: $($summary.status); $output"
