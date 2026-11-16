#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [string]$SDKBuildSummary)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
    !(Test-Path -LiteralPath (Join-Path $stage '.uep-validation-stage')) -or (Test-Path -LiteralPath $output)){throw 'Marked workspace host and fresh output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool,cl,link -ErrorAction SilentlyContinue).Count){throw 'Another native/build lane is active'}
if(!$SDKBuildSummary){$SDKBuildSummary=Join-Path $repo '.build/LyraValidation/BlueprintPython/20261023-pawn-sdk-causality/SDKBuild01/summary.json'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='native production Mixin RPC/delegate/editor-latent registration rejection'
    cpp_compile_executed=$false;cook_package_executed=$false;full_regression_executed=$false;full_acceptance=$false
    input_hashes=@();process=$null;external_gate=$null;error=$null}
function Freeze([string]$Path){$summary.input_hashes+=@{path=[IO.Path]::GetFullPath($Path);sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
                         @{source=(Join-Path $PSScriptRoot 'UEP58Host/Source');target=(Join-Path $stage 'Source')})){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Existing host/native source differs;no automatic build'}
            Freeze $source.FullName;Freeze $target
        }
    }
    $version=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.version';$id=(Get-Content -LiteralPath $version -Raw|ConvertFrom-Json).BuildId;Freeze $version
    foreach($relative in @('Binaries/Win64','Plugins/UnrealEnginePython/Binaries/Win64')){
        $folder=Join-Path $stage $relative;$manifest=Join-Path $folder 'UnrealEditor.modules'
        if((Get-Content -LiteralPath $manifest -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Existing host module BuildId differs'}
        Freeze $manifest
        foreach($binary in Get-ChildItem -LiteralPath $folder -Filter 'UnrealEditor-*.dll'){Freeze $binary.FullName}
    }
    $proof=Get-Content -LiteralPath $SDKBuildSummary -Raw|ConvertFrom-Json -Depth 40
    if($proof.status -ne 'built_requires_native_acceptance' -or $proof.process.exit_code -ne 0){throw 'Accepted existing SDK build required'}
    $binary=Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'
    $matches=@($proof.binary_after|Where-Object {[IO.Path]::GetFileName($_.path) -eq [IO.Path]::GetFileName($binary)})
    if(!$matches.Count -or @($matches|Where-Object {$_.sha256 -ne (Get-FileHash -LiteralPath $binary).Hash}).Count){throw 'Existing host does not use the approved current SDK binary'}
    Freeze $SDKBuildSummary;Freeze $project;Freeze $PSCommandPath;Freeze (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
    $script=Join-Path $PSScriptRoot 'UEP58Host/Tests/mixin_rejection_validation.py'
    $contract=Join-Path $PSScriptRoot 'UEP58Host/Tests/mixin_rejection_contract.py'
    Freeze $script;Freeze $contract
    $report=Join-Path $output 'rejection.json';$log=Join-Path $output 'rejection.log'
    $arguments=@($project,'-unattended','-nop4','-NullRHI','-NoSound','-NoSplash','-UTF8Output','-culture=en','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',
        '-run=Py',$script,"-UEPMixinRejectionResult=$report","-abslog=$log")
    $handle=Start-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'native') 'Focused native Mixin rejection'
    try{if(!$handle.process.WaitForExit(240000)){throw 'Focused native Mixin rejection timed out'}}
    finally{Stop-UEPValidationProcess $handle;$summary.process=Complete-UEPValidationProcess $handle;$handle.process.Dispose()}
    if($summary.process.exit_code -ne 0){throw "Focused native Mixin rejection exited $($summary.process.exit_code)"}
    $python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
    $summary.external_gate=Invoke-UEPValidationProcess $python @('-B','-X','utf8',$contract,'--report',$report,'--log',$log) $repo (Join-Path $output 'gate') 'Independent Mixin rejection report gate' 60
    foreach($input in $summary.input_hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Native rejection input changed during the run'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 15|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Focused native Mixin rejection: $($summary.status)"
