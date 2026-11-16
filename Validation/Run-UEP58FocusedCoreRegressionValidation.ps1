#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet('core-shared','core-standalone','exception-shared','exception-standalone','editor')]
    [string[]]$TestName=@('core-shared','core-standalone','exception-shared','exception-standalone','editor')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
if(!$TestName.Count -or @($TestName|Select-Object -Unique).Count -ne $TestName.Count){throw 'Select one or more unique core suites'}
$repo=Split-Path $PSScriptRoot -Parent
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(!(Test-Path -LiteralPath (Join-Path $stage '.uep-validation-stage'))){throw 'Marked existing generic host required'}
if(Test-Path -LiteralPath $output){throw 'Use a fresh evidence directory'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';cpp_compile_executed=$false;cook_package_executed=$false
    complete_six_suite_gate=$false;packaged_runtime=$false;selected_test_names=$TestName;input_hashes=@();tests=@();generated_asset_artifacts=@();error=$null}
function Save-CoreInput([string]$Path){$summary.input_hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),$StageProject)){Save-CoreInput $path}
    foreach($mapping in @(
        @{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $PSScriptRoot 'UEP58Host/Source');target=(Join-Path $stage 'Source')}
    )){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source differs from the compiled host stage'}
            Save-CoreInput $source.FullName
            Save-CoreInput $target
        }
    }
    $version=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.version'
    $buildId=(Get-Content -LiteralPath $version -Raw|ConvertFrom-Json).BuildId
    Save-CoreInput $version
    foreach($directory in @('Binaries/Win64','Plugins/UnrealEnginePython/Binaries/Win64')){
        $binaryRoot=Join-Path $stage $directory;$manifest=Join-Path $binaryRoot 'UnrealEditor.modules'
        if((Get-Content -LiteralPath $manifest -Raw|ConvertFrom-Json).BuildId -ne $buildId){throw 'Stale native module BuildId'}
        Save-CoreInput $manifest
        foreach($binary in Get-ChildItem -LiteralPath $binaryRoot -Filter 'UnrealEditor-*.dll'){Save-CoreInput $binary.FullName}
    }
    foreach($relative in @('Content/Scripts','Plugins/UnrealEnginePython/Content/Scripts')){
        foreach($script in Get-ChildItem -LiteralPath (Join-Path $stage $relative) -Filter '*.py' -File -Recurse){Save-CoreInput $script.FullName}
    }
    $python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
    $gate=Join-Path $PSScriptRoot 'UEP58Host/Tests/core_regression_contract.py'
    Save-CoreInput $gate
    foreach($name in $TestName){
        $isEditor=$name -eq 'editor';$isException=$name.StartsWith('exception-')
        $ownedAssets=@()
        if($isEditor){
            $editorSuffix='UEP_'+[Guid]::NewGuid().ToString('N')
            $summary.editor_asset_suffix=$editorSuffix
            foreach($file in @('M_UEP58Validation.uasset','LS_UEP58Validation.uasset')){
                $file=[IO.Path]::GetFileNameWithoutExtension($file)+'_'+$editorSuffix+'.uasset'
                $asset=[IO.Path]::GetFullPath((Join-Path $stage ('Content/UEPValidation/'+$file)))
                if(!$asset.StartsWith($stage.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Test asset outside owned stage'}
                if(Test-Path -LiteralPath $asset){throw 'Refusing to overwrite a preexisting editor test asset'}
                $ownedAssets+=,$asset
            }
        }
        $scriptName=if($isEditor){'editor_validation.py'}elseif($isException){'exception_validation.py'}else{'core_validation.py'}
        $script=Join-Path $PSScriptRoot ('UEP58Host/Tests/'+$scriptName)
        Save-CoreInput $script
        $report=Join-Path $output ($name+'.json');$log=Join-Path $output ($name+'.log')
        $arguments=@($StageProject,'-unattended','-nop4','-NullRHI','-NoSound','-NoSplash','-UTF8Output','-culture=en',
            '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none')
        if($isEditor){$arguments+=@("-ExecutePythonScript=$script",'-ScriptErrorsAreFatal',"-UEPValidationAssetSuffix=$editorSuffix")}
        else{
            $arguments+=@('-run=Py',$script,('-UEPValidationMode='+$name.Split('-',2)[1]))
            if($name.EndsWith('-standalone')){$arguments+='-DisablePython'}
        }
        # UEP-owned commandlet sys.argv starts at the script; its options must follow it.
        $arguments+=@("-UEPValidationResult=$report","-abslog=$log")
        $executable=Join-Path $EngineRoot ('Engine/Binaries/Win64/'+$(if($isEditor){'UnrealEditor.exe'}else{'UnrealEditor-Cmd.exe'}))
        $handle=Start-UEPValidationProcess $executable $arguments $stage (Join-Path $output $name) $name
        try{
            if(!$handle.process.WaitForExit(300000)){throw 'Focused core suite timed out'}
            $process=Complete-UEPValidationProcess $handle
            $entry=[ordered]@{name=$name;status='failed';process=$process;report=$report;log=$log;external_gate=$null;semantic_gate=$null}
            $summary.tests+=,$entry
            $gateArguments=@('-B','-X','utf8',$gate,'--kind',$name,'--report',$report,'--log',$log,'--exit-code',[string]$process.exit_code)
            $gateHandle=Start-UEPValidationProcess $python $gateArguments $repo (Join-Path $output ($name+'-gate')) ($name+' independent gate')
            try{
                if(!$gateHandle.process.WaitForExit(30000)){throw 'Independent core report gate timed out'}
                $entry.external_gate=Complete-UEPValidationProcess $gateHandle
                if($entry.external_gate.exit_code -ne 0){throw 'Independent core report gate failed'}
            }
            finally{Stop-UEPValidationProcess $gateHandle;$gateHandle.process.Dispose()}
            $entry.semantic_gate=Get-Content -LiteralPath $entry.external_gate.stdout -Raw|ConvertFrom-Json
            $entry.status='passed'
            Write-Host "$name passed"
        }
        finally{
            Stop-UEPValidationProcess $handle;$handle.process.Dispose()
            foreach($asset in $ownedAssets){
                if(Test-Path -LiteralPath $asset){
                    $archive=Join-Path $output ('EditorAssets/'+[IO.Path]::GetFileName($asset))
                    New-Item -ItemType Directory -Path (Split-Path $archive -Parent) -Force|Out-Null
                    Copy-Item -LiteralPath $asset -Destination $archive
                    if((Get-FileHash -LiteralPath $asset).Hash -ne (Get-FileHash -LiteralPath $archive).Hash){throw 'Editor asset archive differs'}
                    $summary.generated_asset_artifacts+=@{path=$asset;archive=$archive;sha256=(Get-FileHash -LiteralPath $archive).Hash;retained_in_stage=$true}
                }
            }
        }
    }
    foreach($input in $summary.input_hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Frozen core input changed'}}
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Focused core regressions: $($summary.status); $output"
