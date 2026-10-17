#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
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
    !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json')) -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
$relative='Content/UEPValidation/BP_MeleeNetworkFloor.uasset'
if((Test-Path -LiteralPath (Join-Path $stage $relative)) -or (Test-Path -LiteralPath (Join-Path $repo "Demos/UEPLyraIntegration/Overlay/$relative"))){throw 'Fresh stage-only floor required'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';kind='meleetracenetworkfixture';runtime_acceptance=$false;gameplay_business=$false
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;error=$null}
function Add-MeleeFixtureHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $build=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($name in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $name
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $build){throw 'Matching native BuildId required'}
        Add-MeleeFixtureHash $path
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName))
            if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source parity mismatch'}
            Add-MeleeFixtureHash $file.FullName;Add-MeleeFixtureHash $target
        }
    }
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_melee_network_fixture.py'
    foreach($path in @($PSCommandPath,$script,(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){Add-MeleeFixtureHash $path}
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython','-NoDDCCleanup',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-AsyncLoadingThread',
        "-UEPDashRPCStageRoot=$stage","-UEPMeleeNetworkFixtureResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Private replicated native Melee collision fixture' 180
    $proof=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 50
    if($proof.status -ne 'passed' -or $proof.kind -ne $summary.kind -or !$proof.stage_only -or $proof.gameplay_business -or $proof.runtime_acceptance -or
        $proof.asset -ne (Join-Path $stage $relative) -or (Get-FileHash -LiteralPath $proof.asset).Hash -ne $proof.sha256 -or
        !$proof.native_replication_defaults -or !$proof.native_component_archetype_preserved_for_clients -or
        ($proof.extent -join ',') -ne '5000,5000,20' -or $proof.native_object_type -ne 0){throw 'Native private floor proof incomplete'}
    $log=Get-Content -LiteralPath "$output/assets.log" -Raw
    Assert-UEPFocusedLog $log 'UEP_MELEE_NETWORK_FIXTURE_PASSED'
    if($log -notmatch '(?s)UEP_MELEE_NETWORK_FIXTURE_PASSED.*Goodbye Python.*Log file closed'){throw 'Private floor exit incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Private floor frozen input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Private native Melee floor: $($summary.status); $output"
