#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$StageProject,[Parameter(Mandatory=$true)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {throw 'Fresh owned visual evidence directory required'}
New-Item -ItemType Directory -Path "$output/Control"|Out-Null
$source=Join-Path $PSScriptRoot 'Run-UEP58FocusedNetworkValidation.ps1'
$original=[IO.File]::ReadAllText($source)
$anchor='$arguments+=''-UEPLyraWeaponNetwork'''
if([regex]::Matches($original,[regex]::Escape($anchor)).Count -ne 1) {throw 'Network control injection boundary changed'}
$derived=$original.Replace('$PSScriptRoot',("'"+$PSScriptRoot.Replace("'","''")+"'"))
$derived=$derived.Replace($anchor,($anchor+"`n        `$arguments+=@('-UEPLyraBatch1AVisual','-ini:Engine:[Python]:ImportModules=uep_lyra_batch1a_visual')"))
$derived=$derived.Replace("'-ResX=640','-ResY=360'","'-ResX=1280','-ResY=720'")
$driver=Join-Path $output 'Control/Run-Network.ps1'
[IO.File]::WriteAllText($driver,$derived,[Text.UTF8Encoding]::new($false))
@{schema_version=1;original=@{path=$source;sha256=(Get-FileHash -LiteralPath $source).Hash};
    derived=@{path=$driver;sha256=(Get-FileHash -LiteralPath $driver).Hash};
    changes=@('Bind helper paths to the original Validation directory','Add explicit visual test import/flag','Render clients at1280x720');
    production_source_changed=$false;cpp_compile_executed=$false;cook_package_executed=$false}|
    ConvertTo-Json -Depth 5|Set-Content -LiteralPath "$output/control-provenance.json" -Encoding utf8
& $driver -StageProject $StageProject -OutputDirectory "$output/Network" -WeaponGameplay -TestPattern @('test_weapon_network_protocol.py','test_network_screenshots.py')
$summary=Get-Content -LiteralPath "$output/Network/summary.json" -Raw|ConvertFrom-Json -Depth 10
if($summary.status -ne 'passed') {throw 'Native network producer failed; retain raw visual sidecars and logs'}
Write-Host 'Native Batch1A visual capture completed; actual images and sidecar contracts still require independent review'
