#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/Full/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateRange(10,60)][int]$ObservationSeconds=20)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Fresh evidence and marked isolated stage required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';error=$null;cpp_compile_executed=$false;cook_package_executed=$false;full_acceptance=$false;hashes=@();focused_directory="$output/Focused";source_and_binary_reuse_verified=$false;native_processes=2}
function Add-StartupHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    foreach($path in @($PSCommandPath,"$PSScriptRoot/Run-UEP58FocusedWeaponHUDValidation.ps1","$PSScriptRoot/UEPValidationProcesses.ps1","$PSScriptRoot/LyraHUDContracts.ps1","$PSScriptRoot/LyraWeaponHUDContracts.ps1")){Add-StartupHash $path}
    $sdkPath=Join-Path $repo '.build/LyraValidation/BlueprintPython/20261023-pawn-sdk-causality/SDKBuild01/summary.json'
    $sdk=Get-Content -LiteralPath $sdkPath -Raw|ConvertFrom-Json -Depth 30
    if($sdk.status -ne 'built_requires_native_acceptance' -or $sdk.process.exit_code -ne 0){throw 'Reviewed SDK build required'}
    foreach($row in @($sdk.source_hashes)+@($sdk.binary_after)){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Reviewed SDK source/binary changed'};Add-StartupHash $row.path}
    Add-StartupHash $sdkPath
    $guardPath=Join-Path $repo '.build/LyraValidation/BlueprintPython/20261026-pawn-init-guard/Build04LinkResume/summary.json'
    $guard=Get-Content -LiteralPath $guardPath -Raw|ConvertFrom-Json -Depth 30
    if($guard.status -ne 'passed'){throw 'Reviewed isolated native guard required'}
    foreach($row in @($guard.products)+@($guard.protected)){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Native guard/protected input changed'};Add-StartupHash $row.path}
    Add-StartupHash $guardPath
    $summary.source_and_binary_reuse_verified=$true
    & "$PSScriptRoot/Run-UEP58FocusedWeaponHUDValidation.ps1" -EngineRoot $EngineRoot -StageProject $StageProject -OutputDirectory "$output/Focused" -CheckPlayableStartup -PlayableObservationSeconds $ObservationSeconds -RenderOffscreen
    $path="$output/Focused/summary.json";$child=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -Depth 40
    if($child.status -ne 'passed' -or $child.process.exit_code -ne 0 -or $child.differential.status -ne 'passed' -or $child.playable_startup.status -ne 'passed' -or !$child.playable_startup.intentional_owned_process_stop -or !$child.playable_startup.no_validation_flags -or $child.playable_startup.alive_observation_seconds -ne $ObservationSeconds){throw 'Focused/normal startup pair failed'}
    if(@($child.playable_startup.process.arguments|Where-Object {$_.StartsWith('-UEP',[StringComparison]::OrdinalIgnoreCase)}).Count){throw 'Normal playable process has a UEP test flag'}
    Add-StartupHash $path
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen startup input changed'}}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 12|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Current startup pair: $($summary.status); $output"
