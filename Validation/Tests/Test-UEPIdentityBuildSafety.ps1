#Requires -Version 7.0
# Static tool/plan invariants only, not compilation or native networking.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
foreach($name in @('Inspect-UEP58ModuleRefresh.ps1','Run-UEP58ReviewedIdentityRefresh.ps1','Run-UEP58NetworkIdentityProbe.ps1','Run-UEP58JumpValidation.ps1')){
    $tokens=$null;$errors=$null
    [Management.Automation.Language.Parser]::ParseFile((Join-Path $root $name),[ref]$tokens,[ref]$errors)|Out-Null
    if($errors.Count){throw "Identity tool parse error: $name"}
}
$build=Get-Content -LiteralPath (Join-Path $root 'Run-UEP58ReviewedIdentityRefresh.ps1') -Raw
foreach($value in @("@(`$plan.Actions).Count -ne 3",'Module.UEPNetworkIdentity.cpp','UnrealEditor-UEPNetworkIdentity.dll','UnrealEditor-UEPNetworkIdentity.lib',
    "@('compile','links')",'Frozen identity source changed','Frozen action response/source changed','Protected engine/existing binary changed',
    'Never rewrite an incompatible existing module BuildId','-Mode=Execute','-NoEngineChanges')){
    if(!$build.Contains($value)){throw "Missing narrow-build boundary: $value"}
}
if($build -match '\$manifest\.BuildId\s*='){throw 'Build tool must not rewrite an incompatible SDK id'}
$probe=Get-Content -LiteralPath (Join-Path $root 'Run-UEP58NetworkIdentityProbe.ps1') -Raw
if(!$probe.Contains('UEP_NETWORK_IDENTITY_INVALID_PROBE_PASSED.*Goodbye Python.*Log file closed')){throw 'Commandlet completion order not enforced'}
$runtime=Get-Content -LiteralPath (Join-Path $root 'Run-UEP58JumpValidation.ps1') -Raw
foreach($value in @('Current reviewed read-only identity DLL required','Identity build source changed','-UEPRequireNetworkIdentity')){
    if(!$runtime.Contains($value)){throw "Missing runtime identity proof guard: $value"}
}
Write-Host 'Identity tool safety checks PASS: 8 (not native runtime acceptance)'
