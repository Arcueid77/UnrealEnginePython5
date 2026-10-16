#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Batch,
    [Parameter(Mandatory=$true)][string]$Scope,
    [Parameter(Mandatory=$true)][string[]]$EvidenceDirectories,
    [Parameter(Mandatory=$true)][string]$OutputFile,
    [string[]]$ScopeSourceFiles=@(),[hashtable]$SourcePathMap=@{},[string]$HostReport)
# A compact evidence index, not a substitute for native semantic report gates.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$prefix=$repo+[IO.Path]::DirectorySeparatorChar
$output=[IO.Path]::GetFullPath($OutputFile)
$allowed=@((Join-Path $repo 'Validation/AcceptedBatches'),(Join-Path $repo 'Demos/UEPLyraIntegration/Migration/Acceptance'))
if(!@($allowed|Where-Object {$output.StartsWith(([IO.Path]::GetFullPath($_)+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)}).Count){throw 'Batch evidence output must stay in the acceptance ledger'}
if(Test-Path -LiteralPath $output){throw 'Use a new evidence snapshot name; preserve prior proof'}
function Relative([string]$Path){[IO.Path]::GetRelativePath($repo,[IO.Path]::GetFullPath($Path)).Replace('\','/')}
function Field($Value,[string]$Name){$property=$Value.PSObject.Properties[$Name];if($null -ne $property){return $property.Value};return $null}
$snapshot=[ordered]@{schema_version=1;batch=$Batch;scope=$Scope;recorded_utc=[DateTime]::UtcNow.ToString('o')
    status='evidence_snapshot';full_version_acceptance=$false;release_publication=$false
    evidence_scope='Only the explicitly listed runs; historical binaries remain historical'
    core_parent_commit=(& git -C $repo rev-parse HEAD);examples_parent_commit=(& git -C (Join-Path $repo 'Demos') rev-parse HEAD)
    runs=@();source_files=@();host_report=$null}
$inputs=@()
foreach($directory in $EvidenceDirectories){
    $root=[IO.Path]::GetFullPath($directory)
    if(!$root.StartsWith((Join-Path $repo '.build/') ,[StringComparison]::OrdinalIgnoreCase)){throw 'Native evidence must be workspace-owned'}
    $path=Join-Path $root 'summary.json';$summary=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -Depth 100
    if($summary.status -ne 'passed' -or (Field $summary 'error')){throw "Unpassed native evidence: $root"}
    $process=Field $summary 'process';$processes=Field $summary 'processes';$gate=Field $summary 'external_gate'
    if($null -eq $gate){$gate=Field $summary 'validation'}
    if($null -ne $process -and (Field $process 'exit_code') -ne 0){throw 'Failed or missing native process exit code'}
    $exits=[ordered]@{}
    if($null -ne $processes){
        # Older drivers record an array; newer drivers use a peer-name object.
        $peers=if($processes -is [Array]){@($processes|ForEach-Object {
            @{name=(Field $_ 'name');value=$_}
        })}else{@($processes.PSObject.Properties|ForEach-Object {@{name=$_.Name;value=$_.Value}})}
        foreach($peer in $peers){
            $code=Field $peer.value 'exit_code'
            if(!$peer.name -or $null -eq $code -or $code -ne 0 -or $exits.Contains($peer.name)){throw 'Failed, duplicate or incomplete native peer'}
            $exits[$peer.name]=$code
        }
    }
    if($null -ne $gate -and (Field $gate 'exit_code') -ne 0){throw 'Failed or missing independent semantic gate exit code'}
    $rows=@()
    foreach($name in @('hashes','input_hashes','source_hashes','binary_hashes')){
        $values=Field $summary $name;if($null -ne $values){$rows+=@($values)}
    }
    $variantExits=[ordered]@{}
    foreach($variant in @(Field $summary 'variants')){
        if($null -eq $variant){continue}
        $name=Field $variant 'variant';$run=Field $variant 'process'
        if(!$name -or (Field $variant 'status') -ne 'passed' -or $null -eq $run -or
            (Field $run 'exit_code') -ne 0 -or $variantExits.Contains($name)){throw 'Failed, duplicate or incomplete native variant'}
        $variantExits[$name]=Field $run 'exit_code'
        foreach($key in @('binary_hashes','script_hashes')){$rows+=@(Field $variant $key)}
    }
    $inputs+=@($rows)
    $dlls=@($rows|Where-Object {(Field $_ 'path') -match 'UnrealEditor-UnrealEnginePython\.dll$'}|ForEach-Object {$_.sha256}|Sort-Object -Unique)
    $row=[ordered]@{directory=(Relative $root);summary_sha256=(Get-FileHash -LiteralPath $path).Hash;status=$summary.status
        uep_dll_sha256=$dlls;frozen_input_records=$rows.Count;process_exit_code=if($null -ne $process){$process.exit_code}else{$null}
        peer_exit_codes=$exits;variant_exit_codes=$variantExits;independent_gate_exit_code=if($null -ne $gate){$gate.exit_code}else{$null};report_hashes=@()}
    foreach($name in @('jump.json','server.json','A.json','B0.json','B1.json','pie.json','audit.json')){
        $report=Join-Path $root $name
        if(Test-Path -LiteralPath $report){$row.report_hashes+=@{file=$name;sha256=(Get-FileHash -LiteralPath $report).Hash}}
    }
    $snapshot.runs+=$row
}
foreach($file in $ScopeSourceFiles){
    $path=[IO.Path]::GetFullPath($file)
    if(!$path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Scope source outside repository'}
    $hash=(Get-FileHash -LiteralPath $path).Hash
    $inputPath=$path
    if($SourcePathMap.ContainsKey($path)){
        $inputPath=[IO.Path]::GetFullPath($SourcePathMap[$path])
        if(!$inputPath.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Mapped historical input outside workspace'}
    }
    $matching=@($inputs|Where-Object {(Field $_ 'path') -eq $inputPath -and $_.sha256 -eq $hash}).Count
    $snapshot.source_files+=@{path=(Relative $path);sha256=$hash;native_input_path=(Relative $inputPath)
        matches_at_least_one_listed_native_input=($matching -gt 0)}
}
if($HostReport){
    $hostPath=[IO.Path]::GetFullPath($HostReport)
    if(!$hostPath.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Host evidence outside workspace'}
    $hostValue=Get-Content -LiteralPath $hostPath -Raw|ConvertFrom-Json -Depth 50
    if($hostValue.status -ne 'passed'){throw 'Unpassed host models'}
    $snapshot.host_report=@{path=(Relative $hostPath);sha256=(Get-FileHash -LiteralPath $hostPath).Hash;result=$hostValue}
}
New-Item -ItemType Directory -Path (Split-Path $output -Parent) -Force|Out-Null
$snapshot|ConvertTo-Json -Depth 20|Set-Content -LiteralPath $output -Encoding utf8
Write-Host "Saved bounded batch evidence: $Batch"
