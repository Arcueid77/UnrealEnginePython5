#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',
    [string]$StageProject='F:/UnrealEnginePython5/.build/Validation/UEP58Host/UEP58Host.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet('default','long-ascii','long-unicode','shared-unicode')][string[]]$Cases=@('default','long-ascii','long-unicode','shared-unicode'),
    [string]$ExistingPathFixture,
    [Alias('ExpectStartupFailure')][switch]$ExpectBootstrapFailure)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output) -or
    !(Test-Path -LiteralPath (Join-Path $stage '.uep-validation-stage'))){throw 'Marked generic stage and fresh owned evidence directory required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool,cl,link -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
if($ExpectBootstrapFailure -and $Cases.Count -ne 1){throw 'A negative startup control must select one explicit case'}
if($ExistingPathFixture -and ($Cases.Count -ne 1 -or ![IO.Path]::GetFullPath($ExistingPathFixture).StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase))){throw 'Reusing a path fixture requires one case and an owned fixture'}
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';cpp_compile_executed=$false;cook_package_executed=$false
    full_acceptance=$false;expected_failure=[bool]$ExpectBootstrapFailure;hashes=@();cases=@();error=$null}
try{
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEP58Host/Tests/bootstrap_path_validation.py'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules'))){
        $summary.hashes+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    foreach($case in $Cases){
        $caseRoot=Join-Path $output $case
        New-Item -ItemType Directory -Path $caseRoot | Out-Null
        $paths=@{};$modules=@{}
        if($ExistingPathFixture){
            $fixture=Get-Content -LiteralPath $ExistingPathFixture -Raw | ConvertFrom-Json -Depth 6
            if($fixture.case -ne $case -or $fixture.shared_interpreter -ne ($case -eq 'shared-unicode')){throw 'Existing path fixture case differs'}
            foreach($property in $fixture.paths.PSObject.Properties){
                if(![IO.Path]::GetFullPath([string]$property.Value).StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Existing fixture path escaped workspace'}
                $paths[$property.Name]=[string]$property.Value
            }
            foreach($property in $fixture.modules.PSObject.Properties){$modules[$property.Name]=[string]$property.Value}
            foreach($inputFile in @(Get-Item -LiteralPath $ExistingPathFixture)+@(Get-Item -LiteralPath $paths.zip)+@(Get-ChildItem -LiteralPath $paths.scripts,$paths.additional -Filter '*.py' -File)){
                $summary.hashes+=@{path=$inputFile.FullName;sha256=(Get-FileHash -LiteralPath $inputFile.FullName).Hash}
            }
        }elseif($case -ne 'default'){
            $segment=if($case -eq 'long-ascii'){'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789'}else{'路径-模块-é-abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789'}
            $long=Join-Path $caseRoot $segment
            foreach($name in @('scripts','additional')){New-Item -ItemType Directory -Path "$long/$name" -Force | Out-Null;$paths[$name]="$long/$name"}
            $paths.zip="$long/modules.zip"
            Set-Content -LiteralPath "$($paths.scripts)/uep_boot_scripts.py" -Value "VALUE='scripts-脚本'" -Encoding utf8
            Set-Content -LiteralPath "$($paths.additional)/uep_boot_additional.py" -Value "VALUE='additional-模块'" -Encoding utf8
            Set-Content -LiteralPath "$($paths.scripts)/uep_boot_order.py" -Value "VALUE='scripts'" -Encoding utf8
            Set-Content -LiteralPath "$($paths.additional)/uep_boot_order.py" -Value "VALUE='additional'" -Encoding utf8
            $zip=[IO.Compression.ZipFile]::Open($paths.zip,[IO.Compression.ZipArchiveMode]::Create)
            try{$entry=$zip.CreateEntry('uep_boot_zip.py');$writer=[IO.StreamWriter]::new($entry.Open(),[Text.UTF8Encoding]::new($false));try{$writer.Write("VALUE='zip-归档'")}finally{$writer.Dispose()}}finally{$zip.Dispose()}
            $modules=@{uep_boot_scripts='scripts-脚本';uep_boot_additional='additional-模块';uep_boot_order='additional';uep_boot_zip='zip-归档'}
            foreach($value in $paths.Values){if([Text.Encoding]::UTF8.GetByteCount($value) -le 128){throw 'Configured path does not exercise heap conversion'}}
        }
        $expected="$caseRoot/expected.json"
        @{case=$case;paths=$paths;modules=$modules;shared_interpreter=($case -eq 'shared-unicode')} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $expected -Encoding utf8
        foreach($inputFile in Get-ChildItem -LiteralPath $caseRoot -Recurse -File){$summary.hashes+=@{path=$inputFile.FullName;sha256=(Get-FileHash -LiteralPath $inputFile.FullName).Hash}}
        $report="$caseRoot/result.json";$log="$caseRoot/native.log"
        $arguments=@($StageProject,'-unattended','-nop4','-NullRHI','-NoSound','-NoSplash','-UTF8Output','-culture=en','-notraceserver','-trace=none',
            '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-run=Py',(Join-Path $PSScriptRoot 'UEP58Host/Tests/bootstrap_path_validation.py'),
            "-UEPBootstrapPathsExpected=$expected","-UEPBootstrapPathsResult=$report","-abslog=$log")
        if($case -ne 'shared-unicode'){$arguments+='-DisablePython'}
        if($paths.Count){$arguments+=@("-ini:Engine:[Python]:ZipPath=$($paths.zip)","-ini:Engine:[Python]:ScriptsPath=$($paths.scripts)","-ini:Engine:[Python]:AdditionalModulesPath=$($paths.additional)")}
        $handle=Start-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage "$caseRoot/process" "Bootstrap paths $case"
        try{
            $timer=[Diagnostics.Stopwatch]::StartNew()
            while(!$handle.process.WaitForExit(1000)){if($timer.Elapsed.TotalSeconds -gt 90){throw 'Bootstrap path process timeout'}}
            $process=Complete-UEPValidationProcess $handle
            $text=Get-Content -LiteralPath $log -Raw
            $item=@{case=$case;process=$process;report=$report;log=$log;expected=$expected}
            $summary.cases+=,$item
            if($ExpectBootstrapFailure){
                $crashed=$process.exit_code -ne 0 -and !(Test-Path -LiteralPath $report) -and $text -match 'EXCEPTION_ACCESS_VIOLATION' -and $text -match 'UESetupPythonInterpreter'
                $missingPath=$false
                if(Test-Path -LiteralPath $report){
                    $negative=Get-Content -LiteralPath $report -Raw | ConvertFrom-Json -Depth 8
                    $missingPath=$negative.status -eq 'failed' -and $negative.case -eq $case -and $negative.error -match 'ValueError:.*is not in list'
                }
                if(!$crashed -and !$missingPath){throw 'Expected bootstrap crash or configured-path corruption was not reproduced'}
                $item.status=if($crashed){'expected_startup_failure'}else{'expected_configured_path_failure'}
            }else{
                if($process.exit_code -ne 0){throw "Bootstrap path case $case exited with error"}
                $result=Get-Content -LiteralPath $report -Raw | ConvertFrom-Json -Depth 8
                if($result.status -ne 'passed' -or $result.native_sum -ne 42){throw 'Native bootstrap path/import/reflection report failed'}
                Assert-UEPFocusedLog $text 'UEP_BOOTSTRAP_PATH_PASSED'
                if($text -notmatch '(?s)UEP_BOOTSTRAP_PATH_PASSED.*Goodbye Python.*Log file closed'){throw 'Bootstrap completion/Python exit/log close ordering incomplete'}
                $item.status='passed'
            }
        }finally{Stop-UEPValidationProcess $handle;$handle.process.Dispose()}
    }
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Bootstrap frozen input changed'}}
    $summary.status=if($ExpectBootstrapFailure){'expected_bootstrap_failure'}else{'passed'}
}catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Bootstrap paths: $($summary.status)"
