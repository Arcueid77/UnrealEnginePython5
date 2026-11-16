#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$OutputDirectory,
    [string]$BuildEvidenceDirectory='.build/LyraValidation/BlueprintPython/20261026-pawn-init-guard/Build04LinkResume',
    [ValidateRange(0,30)][int]$ClientB0LaunchDelaySeconds=8,
    [ValidateRange(1024,65535)][int]$ServerPort=54913)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Fresh private validation output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|UnrealBuildTool|AutomationTool|LyraGame)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
$evidence=[IO.Path]::GetFullPath($BuildEvidenceDirectory)
if(!$evidence.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Private build evidence required'}
$build=Get-Content -LiteralPath "$evidence/summary.json" -Raw|ConvertFrom-Json -Depth 40
if($build.status -ne 'passed'){throw 'Successful isolated guard build required'}
$resumed=$build.PSObject.Properties.Name -contains 'reuses_successful_compile'
if($resumed -and !$build.compile_source_and_input_hashes_verified){throw 'Verified resumed compile inputs required'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';error=$null;scope='same delayed-client native Pawn readiness regression after isolated guard';client_b0_launch_delay_seconds=$ClientB0LaunchDelaySeconds;cpp_compile_executed=$false;cook_package_executed=$false;assets_saved=$false;full_acceptance=$false;hashes=@();native_summary=$null;network_acceptance=$false}
function Add-InitGuardHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    foreach($row in @($build.products)+@($build.protected)){
        if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Guard build or protected native inputs changed'}
        Add-InitGuardHash $row.path
    }
    $compile=if($resumed){Get-Content -LiteralPath $build.reuses_successful_compile -Raw|ConvertFrom-Json -Depth 40}else{$build}
    if($compile.actions[0].process.exit_code -ne 0){throw 'Pinned successful compile missing'}
    $target=Join-Path $repo '.build/LyraValidation/Full/Stage/Lyra/Source/LyraGame/Character/LyraHeroComponent.cpp'
    $record=@($compile.hashes|Where-Object {[IO.Path]::GetFullPath($_.path) -eq [IO.Path]::GetFullPath($target)})
    if(!$record.Count -or (Get-FileHash -LiteralPath $target).Hash -ne $record[0].sha256){throw 'Compiled Hero guard source changed'}
    foreach($file in Get-ChildItem -LiteralPath (Join-Path (Split-Path $target -Parent) '..') -Recurse -File){Add-InitGuardHash $file.FullName}
    foreach($path in @($target,$PSCommandPath,"$evidence/summary.json",(Join-Path $PSScriptRoot 'Run-UEP58CurrentMeleeReadinessValidation.ps1'))){Add-InitGuardHash $path}
    if($resumed){Add-InitGuardHash $build.reuses_successful_compile}
    & (Join-Path $PSScriptRoot 'Run-UEP58CurrentMeleeReadinessValidation.ps1') -OutputDirectory "$output/Network" -ServerPort $ServerPort -ClientB0LaunchDelaySeconds $ClientB0LaunchDelaySeconds -CaptureNativeStacks
    $native=Get-Content -LiteralPath "$output/Network/summary.json" -Raw|ConvertFrom-Json -Depth 20
    if($native.status -ne 'passed' -or !$native.network_acceptance -or $native.external_gate.exit_code -ne 0){throw 'Delayed client gameplay regression failed'}
    foreach($row in $summary.hashes){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Frozen guard validation input changed'}}
    $summary.native_summary=@{path="$output/Network/summary.json";sha256=(Get-FileHash -LiteralPath "$output/Network/summary.json").Hash;processes=$native.processes;external_gate=$native.external_gate}
    $summary.network_acceptance=$true;$summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 16|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
