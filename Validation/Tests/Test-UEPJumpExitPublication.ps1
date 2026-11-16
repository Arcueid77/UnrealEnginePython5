#Requires -Version 7.0
# Exercise the exact owned publisher without UE or a fake process-exit claim.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$validation=Split-Path $PSScriptRoot -Parent
$source=Join-Path $validation 'Run-UEP58JumpValidation.ps1'
$tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Driver parse failed'}
$function=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Write-UEPJumpExitToken'},$true))
if($function.Count -ne 1){throw 'Exactly one native exit publisher required'}
Invoke-Expression $function[0].Extent.Text
$root=Join-Path (Split-Path $validation -Parent) ('.build/CommitVerification/DriverAtomicExit/'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root|Out-Null
$target=Join-Path $root 'A-exited.json';$run=[guid]::NewGuid().ToString()
Write-UEPJumpExitToken -Path $target -OutputRoot $root -Token @{peer='A';run_id=$run;exit_code=0}
$value=Get-Content -LiteralPath $target -Raw|ConvertFrom-Json
if($value.peer -ne 'A' -or $value.run_id -ne $run -or $value.exit_code -ne 0){throw 'Complete native token roundtrip failed'}
if(@(Get-ChildItem -LiteralPath $root -Filter '*.tmp' -Force).Count){throw 'Unpublished temporary stream remained'}
$before=(Get-FileHash -LiteralPath $target).Hash;$rejected=$false
try{Write-UEPJumpExitToken -Path $target -OutputRoot $root -Token @{peer='A';run_id='replacement';exit_code=0}}catch{$rejected=$true}
if(!$rejected -or (Get-FileHash -LiteralPath $target).Hash -ne $before){throw 'Previously published exit proof was overwritten'}
$rejected=$false
try{Write-UEPJumpExitToken -Path (Join-Path $root '../B0-exited.json') -OutputRoot $root -Token @{peer='B0';run_id=$run;exit_code=0}}catch{$rejected=$true}
if(!$rejected){throw 'Exit publisher escaped its exact evidence directory'}
$rejected=$false
try{Write-UEPJumpExitToken -Path (Join-Path $root 'B0-exited.json') -OutputRoot $root -Token @{peer='B0';run_id=$run;exit_code=1}}catch{$rejected=$true}
if(!$rejected -or (Test-Path -LiteralPath (Join-Path $root 'B0-exited.json'))){throw 'Nonzero exit was presented as successful'}
Write-Host 'Atomic native exit publication checks PASS: 4 (not native process/runtime acceptance)'
