# Exercise the exact driver function without loading its launch/preparation code.
#Requires -Version 7.0
param([Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Fresh workspace output required'}
New-Item -ItemType Directory -Path $output|Out-Null
$driver=Join-Path $PSScriptRoot 'Run-UEP58CurrentMeleeReadinessValidation.ps1';$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($driver,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Current melee driver parsing failed'}
$node=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Read-MeleeLiveJson'},$true)
. ([ScriptBlock]::Create($node.Extent.Text))
$exitNode=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'New-MeleeExitRecord'},$true)
. ([ScriptBlock]::Create($exitNode.Extent.Text))
$exitRecord=New-MeleeExitRecord 'owned-test-run' 'A' 0
if($exitRecord.run_id -ne 'owned-test-run' -or $exitRecord.peer -ne 'A' -or $exitRecord.exit_code -ne 0){throw 'Driver exit token lost owned run identity'}
$exitRecord|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $output 'A-exited.json') -Encoding utf8
$missing=Join-Path $output 'missing.json'
function Test-Path {param([string]$LiteralPath)return $true}
if($null -ne (Read-MeleeLiveJson $missing)){throw 'Existence/open replacement gap did not remain pending'}
Remove-Item Function:Test-Path
$file=Join-Path $output 'state.json'
$exclusive=[IO.FileStream]::new($file,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try{
    $bytes=[Text.Encoding]::UTF8.GetBytes('{"ready":true}');$exclusive.Write($bytes,0,$bytes.Length);$exclusive.Flush()
    if($null -ne (Read-MeleeLiveJson $file)){throw 'Transient exclusive file did not remain pending'}
}finally{$exclusive.Dispose()}
if(!(Read-MeleeLiveJson $file).ready){throw 'Released JSON file did not parse unchanged'}
'{"incomplete":'|Set-Content -LiteralPath $file -Encoding utf8
$badJsonRejected=$false
try{$null=Read-MeleeLiveJson $file}catch{$badJsonRejected=$true}
if(!$badJsonRejected){throw 'Malformed JSON was incorrectly treated as pending'}
$otherIoRejected=$false
try{$null=Read-MeleeLiveJson $output}catch{$otherIoRejected=$true}
if(!$otherIoRejected){throw 'Nontransient directory access was incorrectly treated as pending'}
[ordered]@{status='passed';replacement_gap_pending=$true;exclusive_share_violation_pending=$true;released_json_unchanged=$true;malformed_json_rejected=$true;unrelated_io_error_rejected=$true;owned_client_exit_run_id_preserved=$true;native_launch_executed=$false;driver_sha256=(Get-FileHash -LiteralPath $driver).Hash}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8
Get-Content -LiteralPath (Join-Path $output 'summary.json')
