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
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-validation-stage'))){throw 'Marked workspace generic host/output required'}
if(Test-Path -LiteralPath $output){throw 'Fresh evidence directory required'}
if(@(Get-CimInstance Win32_Process | Where-Object {$_.Name -match '^UnrealEditor(-Cmd)?\.exe$'}).Count){throw 'An Editor process is already running'}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';bounded_runtime_acceptance=$false;full_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();assets=@();processes=@();error=$null
    package_root=('/Game/UEPValidation/PackageLoad_'+[guid]::NewGuid().ToString('N'))}
function Add-PackageLoadHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try {
    foreach($mapping in @(
        @{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins\UnrealEnginePython\Source')},
        @{source=(Join-Path $PSScriptRoot 'UEP58Host\Source');target=(Join-Path $stage 'Source')}
    )){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source mismatch'}
            Add-PackageLoadHash $source.FullName;Add-PackageLoadHash $target
        }
    }
    $version=Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.version'
    $metadata=Get-Content -LiteralPath $version -Raw | ConvertFrom-Json
    $summary.engine_version="$($metadata.MajorVersion).$($metadata.MinorVersion).$($metadata.PatchVersion)"
    $summary.editor_build_id=$metadata.BuildId
    Add-PackageLoadHash $version;Add-PackageLoadHash $project;Add-PackageLoadHash $PSCommandPath
    foreach($relative in @('Binaries\Win64','Plugins\UnrealEnginePython\Binaries\Win64')){
        $root=Join-Path $stage $relative
        $manifest=Join-Path $root 'UnrealEditor.modules'
        if((Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json).BuildId -ne $metadata.BuildId){throw 'Stale module metadata'}
        Add-PackageLoadHash $manifest
        foreach($binary in Get-ChildItem -LiteralPath $root -Filter 'UnrealEditor-*.dll' -File){Add-PackageLoadHash $binary.FullName}
    }
    foreach($mapping in @(
        @{source=(Join-Path $PSScriptRoot 'UEP58Host\Content\Scripts');target=(Join-Path $stage 'Content\Scripts')},
        @{source=(Join-Path $repo 'Content\Scripts');target=(Join-Path $stage 'Plugins\UnrealEnginePython\Content\Scripts')}
    )){
        foreach($source in Get-ChildItem -LiteralPath $mapping.source -Recurse -Filter '*.py' -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$source.FullName))
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $source.FullName -Destination $target -Force
            Add-PackageLoadHash $source.FullName;Add-PackageLoadHash $target
        }
    }
    $fixture=Join-Path $PSScriptRoot 'UEP58Host\Tests\mixin_package_load_validation.py'
    Add-PackageLoadHash $fixture
    foreach($phase in @('author','load')){
        $arguments=@($project,'-unattended','-nop4','-NullRHI','-NoSound','-NoSplash','-UTF8Output','-DisablePython',
            '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',
            '-run=Py',$fixture,"-UEPPackageLoadPhase=$phase","-UEPPackageLoadRoot=$($summary.package_root)",
            "-UEPPackageLoadResult=$output\$phase.json","-abslog=$output\$phase.log")
        $summary.processes+=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output $phase) "saved-package-$phase" 180
        $report=Get-Content -LiteralPath (Join-Path $output "$phase.json") -Raw | ConvertFrom-Json
        if($report.status -ne 'passed' -or $report.phase -ne $phase){throw 'Saved-package fixture failed'}
        $log=Get-Content -LiteralPath (Join-Path $output "$phase.log") -Raw
        Assert-UEPFocusedLog $log 'UEP_PACKAGE_LOAD_PASSED'
        if($log -notmatch '(?s)UEP_PACKAGE_LOAD_PASSED.*Goodbye Python.*Log file closed'){throw 'Saved-package process did not close normally'}
        if($phase -eq 'author'){
            foreach($name in @('MixinSet','Companion','Main')){
                $asset=Join-Path $stage ('Content\'+$summary.package_root.Substring('/Game/'.Length).Replace('/','\')+'\'+$name+'.uasset')
                $summary.assets+=@{path=$asset;sha256=(Get-FileHash -LiteralPath $asset).Hash}
            }
        }
        else {
            if(!$report.automatic_registration -or $report.explicit_registration_called -or
               !$report.imported_package_discovered -or $report.full_acceptance -or @($report.classes).Count -ne 2){throw 'Automatic/imported discovery proof incomplete'}
            foreach($class in $report.classes){
                if(!$class.same_class -or !$class.automatic_fallback -or !$class.original_restored -or
                   $class.python_value -ne 11 -or ($class.native_signals -join ',') -ne '22,33,44'){throw 'Routed/original behavior incomplete'}
            }
        }
        Write-Host "Saved package $phase passed"
    }
    if($summary.processes[0].pid -eq $summary.processes[1].pid){throw 'Fresh process identity was not established'}
    foreach($input in @($summary.hashes)+@($summary.assets)){
        if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Saved-package fixture input changed'}
    }
    $summary.status='passed';$summary.bounded_runtime_acceptance=$true
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Saved-package automatic discovery: $($summary.status); $output"
