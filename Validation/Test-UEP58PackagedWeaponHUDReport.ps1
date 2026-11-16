#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Report,[Parameter(Mandatory=$true)][string]$OutputFile)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'LyraWeaponHUDContracts.ps1')
$data=Get-Content -LiteralPath $Report -Raw|ConvertFrom-Json -Depth 60
Assert-LyraWeaponHUDData $data
Assert-LyraWeaponLifecycleData $data
if($data.shutdown.phase -ne 'python_atexit' -or !$data.shutdown.owned_resources_closed_before_exit){throw 'Actual Python exit and pre-exit owned cleanup evidence required'}
$image=@($data.images)
if($image.Count -ne 1 -or !(Test-Path -LiteralPath $image[0])){throw 'Native weapon HUD image missing'}
$bytes=[IO.File]::ReadAllBytes($image[0])
if($bytes.Length -lt 24 -or [Convert]::ToBase64String($bytes[0..7]) -ne 'iVBORw0KGgo='){throw 'Native screenshot is not a PNG'}
$width=([uint32]$bytes[16] -shl 24) -bor ([uint32]$bytes[17] -shl 16) -bor ([uint32]$bytes[18] -shl 8) -bor [uint32]$bytes[19]
$height=([uint32]$bytes[20] -shl 24) -bor ([uint32]$bytes[21] -shl 16) -bor ([uint32]$bytes[22] -shl 8) -bor [uint32]$bytes[23]
if($width -lt 1280 -or $height -lt 720){throw 'Both presenter columns require a sufficiently large actual viewport'}
@{schema_version=1;status='passed';scope='independent actual weapon HUD state and lifecycle report';cases=@($data.cases).Count;components=@($data.declarations).Count;controlled_reload_cycles=@($data.reload_cycles).Count;native_image=@{path=$image[0];width=$width;height=$height;sha256=(Get-FileHash -LiteralPath $image[0]).Hash};visual_inspection_completed=$false;full_acceptance=$false}|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $OutputFile -Encoding utf8
Write-Host 'Independent packaged weapon HUD report gate passed'
