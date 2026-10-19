#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$OutputDirectory,[string]$Python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe',
    [string[]]$TestPattern=@(),[switch]$FullRegression)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build/CommitVerification'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Fresh workspace-owned commit verification directory required'}
New-Item -ItemType Directory -Path "$output/workspace/Demos" -Force|Out-Null
$summary=[ordered]@{schema_version=2;status='failed';core_commit=(& git -C $repo rev-parse HEAD);core_index_tree=$null;examples_index_tree=$null
    host_report="$output/workspace/.build/host.json";native_runtime_acceptance=$false;cpp_compile_executed=$false;error=$null}
$priorPythonPath=$env:PYTHONPATH
try{
    $inspectionArgs=@('--repo',(Join-Path $repo 'Demos'))
    if($FullRegression){$inspectionArgs+='--all-index'}
    & $Python -B (Join-Path $PSScriptRoot 'Inspect-UEPStagedExamples.py') @inspectionArgs
    if($LASTEXITCODE -ne 0){throw 'Staged eager imports/syntax failed'}
    $summary.examples_index_tree=(& git -C (Join-Path $repo 'Demos') write-tree)
    if($LASTEXITCODE -ne 0){throw 'Cannot resolve Examples index tree'}
    $summary.core_index_tree=(& git -C $repo write-tree)
    if($LASTEXITCODE -ne 0){throw 'Cannot resolve core index tree'}
    $coreChanges=@(& git -C $repo diff --cached --name-only -- . ':!Demos')
    if($LASTEXITCODE -ne 0){throw 'Cannot read core index changes'}
    $examplesBase=(& git -C $repo rev-parse HEAD:Demos)
    if($LASTEXITCODE -ne 0){throw 'Cannot resolve committed Examples baseline'}
    $exampleChanges=@(& git -C (Join-Path $repo 'Demos') diff --cached $examplesBase --name-only|ForEach-Object {'Demos/'+$_})
    if($LASTEXITCODE -ne 0){throw 'Cannot read Examples index changes'}
    ConvertTo-Json -InputObject @($coreChanges+$exampleChanges) | Set-Content -LiteralPath "$output/changes.json" -Encoding utf8
    & git -C $repo archive -o "$output/core.tar" $summary.core_index_tree Source Content Validation
    if($LASTEXITCODE -ne 0){throw 'Core snapshot archive failed'}
    & git -C (Join-Path $repo 'Demos') archive -o "$output/examples.tar" $summary.examples_index_tree
    if($LASTEXITCODE -ne 0){throw 'Examples snapshot archive failed'}
    & tar -xf "$output/core.tar" -C "$output/workspace"
    if($LASTEXITCODE -ne 0){throw 'Core snapshot extraction failed'}
    & tar -xf "$output/examples.tar" -C "$output/workspace/Demos"
    if($LASTEXITCODE -ne 0){throw 'Examples snapshot extraction failed'}
    $env:PYTHONPATH="$output/workspace/Demos/UEPLyraIntegration/Overlay/Content/Scripts;$output/workspace/Content/Scripts"
    $hostArgs=@('--result',$summary.host_report,'--changes-file',"$output/changes.json")
    if($FullRegression){$hostArgs+='--all'}
    foreach($pattern in $TestPattern){$hostArgs+=@('--test-pattern',$pattern)}
    & $Python -B "$output/workspace/Validation/Run-UEPLyraHostTests.py" @hostArgs
    if($LASTEXITCODE -ne 0){throw 'Isolated staged-tree models failed'}
    $report=Get-Content -LiteralPath $summary.host_report -Raw|ConvertFrom-Json
    if($report.status -ne 'passed' -or $report.runtime_acceptance){throw 'Staged-tree host evidence invalid'}
    $summary.tests_run=$report.tests_run;$summary.selection=$report.selection;$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{
    $env:PYTHONPATH=$priorPythonPath
    $summary|ConvertTo-Json -Depth 8|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8
}
Write-Host "Isolated Examples index verification: $($summary.status)"
