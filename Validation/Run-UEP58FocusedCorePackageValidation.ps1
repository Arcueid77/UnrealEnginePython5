#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$GameBuildSummary,
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(!(Test-Path -LiteralPath (Join-Path $stage '.uep-validation-stage')) -or [IO.Path]::GetFileNameWithoutExtension($StageProject) -ne 'UEP58Host'){
    throw 'Marked existing Generic UEP58Host stage required'
}
if(Test-Path -LiteralPath $output){throw 'Use a fresh package evidence directory'}
$build=Get-Content -LiteralPath $GameBuildSummary -Raw|ConvertFrom-Json
if($build.status -ne 'passed' -or $build.target -ne 'UEP58Host' -or $build.platform -ne 'Win64' -or
    $build.configuration -ne 'Development' -or $build.process.exit_code -ne 0){throw 'Verified current Game build required'}
$builtGame=Join-Path $stage 'Binaries/Win64/UEP58Host.exe'
$builtProduct=@($build.products|Where-Object{[IO.Path]::GetFullPath($_.path) -eq [IO.Path]::GetFullPath($builtGame)})
if($builtProduct.Count -ne 1 -or (Get-FileHash -LiteralPath $builtGame).Hash -ne $builtProduct[0].sha256){throw 'Game executable differs from the recorded build'}
$receipt=Get-Content -LiteralPath (Join-Path $stage 'Binaries/Win64/UEP58Host.target') -Raw|ConvertFrom-Json
if($receipt.TargetName -ne 'UEP58Host' -or $receipt.Platform -ne 'Win64' -or $receipt.Configuration -ne 'Development'){
    throw 'Actual Generic Game receipt required'
}
New-Item -ItemType Directory -Path $output|Out-Null
$archive=Join-Path $output 'Archive'
$logs=Join-Path $output 'UAT'
$summary=[ordered]@{schema_version=1;status='failed';target='UEP58Host';platform='Win64';configuration='Development'
    cpp_compile_executed_by_this_driver=$false;reuse_game_build_summary=$GameBuildSummary
    reuse_game_build_summary_sha256=(Get-FileHash -LiteralPath $GameBuildSummary).Hash
    cook_map='/Engine/Maps/Entry';iterative_cook=$true;versioned_cooked_content=$true;archive=$archive;input_hashes=@();cook_process=$null
    process=$null;external_gate=$null;semantic_gate=$null;products=@();complete_six_suite_gate=$false;error=$null}
function Save-CorePackageInput([string]$Path){$summary.input_hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
function Assert-CorePackageInputs{
    foreach($item in @($build.input_hashes)+@($summary.input_hashes)){
        if((Get-FileHash -LiteralPath $item.path).Hash -ne $item.sha256){throw 'Frozen package/build input changed'}
    }
}
try{
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),$GameBuildSummary,
        $builtGame,(Join-Path $stage 'Binaries/Win64/UEP58Host.target'),
        (Join-Path $PSScriptRoot 'UEP58Host/Tests/core_validation.py'),
        (Join-Path $PSScriptRoot 'UEP58Host/Tests/core_regression_contract.py'),
        (Join-Path $PSScriptRoot 'UEP58Host/Tests/packaged_core_contract.py'))){Save-CorePackageInput $path}
    Assert-CorePackageInputs
    $uat=Join-Path $EngineRoot 'Engine/Binaries/DotNET/AutomationTool/AutomationTool.dll'
    $dotnet=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/DotNet/10.0/win-x64/dotnet.exe'
    foreach($file in @('UnrealPak.exe','ShaderCompileWorker.exe')){
        if(!(Test-Path -LiteralPath (Join-Path $EngineRoot ('Engine/Binaries/Win64/'+$file)))){throw 'Prebuilt package tool missing'}
    }
    $arguments=@($uat,'BuildCookRun',"-project=$StageProject",'-noP4','-utf8output','-WaitForUATMutex','-unattended',
        '-nocompileuat','-nocompileeditor','-skipbuild','-platform=Win64','-clientconfig=Development','-target=UEP58Host',
        '-ubtargs=-NoEngineChanges -NoUBA -MaxParallelActions=2','-cook','-iterate','-VersionCookedContent','-stage','-pak','-archive',
        "-archivedirectory=$archive",'-map=/Engine/Maps/Entry','-AdditionalCookerOptions=-DisablePlugins=AndroidFileServer -SkipZenStore','-nodebuginfo')
    $handle=Start-UEPValidationProcess $dotnet $arguments $EngineRoot (Join-Path $output 'cook') 'Generic Entry cook/stage/archive without rebuild' @{
        uebp_LogFolder=$logs;uebp_FinalLogFolder=$logs}
    try{
        Write-Host "Started Entry-only cook/stage PID $($handle.process.Id); Game build explicitly skipped"
        $last=''
        while(!$handle.process.WaitForExit(5000)){
            if($handle.stopwatch.Elapsed.TotalHours -gt 2){throw 'Owning package timeout exceeded two hours'}
            $log=Join-Path $logs 'Log.txt'
            if(Test-Path -LiteralPath $log){
                $line=@(Get-Content -LiteralPath $log -Tail 12|Where-Object{$_ -match 'Cooked packages|packages cooked|COOK|STAGE|PAK|ARCHIVE|Error:|BUILD SUCCESSFUL'})|Select-Object -Last 1
                if($line -and $line -ne $last){Write-Host $line;$last=$line}
            }
        }
        $summary.cook_process=Complete-UEPValidationProcess $handle
        if($summary.cook_process.exit_code -ne 0){throw 'Entry package failed; retain cook outputs and diagnostics'}
    }
    finally{
        Stop-UEPValidationProcess $handle
        if($null -eq $summary.cook_process){$summary.cook_process=Complete-UEPValidationProcess $handle}
        $handle.process.Dispose()
    }
    $text=Get-Content -LiteralPath $summary.cook_process.stdout -Raw
    # Pak generation belongs to UAT's STAGE phase; verify its real archive below.
    foreach($marker in @('COOK COMMAND COMPLETED','STAGE COMMAND COMPLETED','ARCHIVE COMMAND COMPLETED','BUILD SUCCESSFUL')){
        if($text -notmatch [regex]::Escape($marker)){throw 'Incomplete package phase markers'}
    }
    if($text -match '(?m)^\[\d+/\d+\] (Compile|Link)'){throw 'Package driver unexpectedly rebuilt native code'}
    $game=Join-Path $archive 'Windows/UEP58Host/Binaries/Win64/UEP58Host.exe'
    if(!(Test-Path -LiteralPath $game) -or (Get-FileHash -LiteralPath $game).Hash -ne $builtProduct[0].sha256){
        throw 'Packaged real Game executable differs from current native build'
    }
    $paks=@(Get-ChildItem -LiteralPath (Join-Path $archive 'Windows/UEP58Host/Content/Paks') -File -Filter '*.pak')
    if(!$paks.Count){throw 'Actual cooked package archive required'}
    foreach($file in @((Get-Item -LiteralPath $game))+$paks){$summary.products+=@{path=$file.FullName;sha256=(Get-FileHash -LiteralPath $file.FullName).Hash}}
    Assert-CorePackageInputs
    $result=Join-Path $output 'packaged.json';$log=Join-Path $output 'packaged.log'
    $script=Join-Path $PSScriptRoot 'UEP58Host/Tests/core_validation.py'
    $runtime=@('-unattended','-nop4','-NullRHI','-NoSound','-NoSplash','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',
        ('-basedir='+[IO.Path]::GetDirectoryName($game)),"-UEPValidationScript=$script",'-UEPValidationMode=packaged',
        "-UEPValidationResult=$result","-abslog=$log")
    $handle=Start-UEPValidationProcess $game $runtime (Join-Path $archive 'Windows') (Join-Path $output 'packaged') 'Actual packaged core21'
    try{
        if(!$handle.process.WaitForExit(300000)){throw 'Packaged core runtime timed out'}
        $summary.process=Complete-UEPValidationProcess $handle
        $python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
        $gate=Join-Path $PSScriptRoot 'UEP58Host/Tests/packaged_core_contract.py'
        $gateArguments=@('-B','-X','utf8',$gate,'--report',$result,'--log',$log,'--exit-code',[string]$summary.process.exit_code)
        $gateHandle=Start-UEPValidationProcess $python $gateArguments $repo (Join-Path $output 'gate') 'Independent packaged core21 gate'
        try{
            if(!$gateHandle.process.WaitForExit(30000)){throw 'Packaged core report gate timed out'}
            $summary.external_gate=Complete-UEPValidationProcess $gateHandle
            if($summary.external_gate.exit_code -ne 0){throw 'Packaged core independent gate failed'}
            $summary.semantic_gate=Get-Content -LiteralPath $summary.external_gate.stdout -Raw|ConvertFrom-Json
        }
        finally{Stop-UEPValidationProcess $gateHandle;$gateHandle.process.Dispose()}
    }
    finally{
        Stop-UEPValidationProcess $handle
        if($null -eq $summary.process){$summary.process=Complete-UEPValidationProcess $handle}
        $handle.process.Dispose()
    }
    Assert-CorePackageInputs
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Actual Generic package core21: $($summary.status)"
