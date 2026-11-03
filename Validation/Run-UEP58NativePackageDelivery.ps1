#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/Reproduction/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [string]$GameBuildDirectory,
    [string]$FixtureEvidenceDirectory,
    [ValidateRange(1,99)][int]$CookAttempt=1,
    [switch]$ReusePackagePlan
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned delivery evidence root required'}
if(!$GameBuildDirectory){$GameBuildDirectory=Join-Path $output 'H04-GameBuild01'}
if(!$FixtureEvidenceDirectory){$FixtureEvidenceDirectory=Join-Path $output 'H04-Fixtures01'}
$plan=Join-Path $output 'H04-package-plan.json'
$cookName='H04-Cook'+$CookAttempt.ToString('00');$cookDirectory=Join-Path $output $cookName
$summaryName=if($CookAttempt -eq 1){'H04-delivery-summary.json'}else{'H04-delivery-summary-Cook'+$CookAttempt.ToString('00')+'.json'}
$children=@($cookName,'H04-PackagedExceptions01','H04-PackagedFrontend01','H04-PackagedDamageNetwork01','H04-PackagedPawnNetwork01',$summaryName)
$freshPaths=@($children|ForEach-Object {Join-Path $output $_});if(!$ReusePackagePlan){$freshPaths+=@($plan)}
foreach($path in $freshPaths){if(Test-Path -LiteralPath $path){throw 'Delivery requires fresh plan/cook/runtime evidence paths'}}
if($ReusePackagePlan -and !(Test-Path -LiteralPath $plan)){throw 'Existing frozen package plan required'}
New-Item -ItemType Directory -Path $output -Force|Out-Null
$controlHash=(Get-FileHash -LiteralPath $PSCommandPath).Hash
$summary=[ordered]@{schema_version=1;status='failed';scope='current-Win64-Development-native-package-delivery';physical_input_tested=$false;children=@();error=$null}
try{
    $stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
    $python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
    & $python -B -X utf8 (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/check_native_game_output_scope.py') --stage $stage --engine F:/UnrealEngine --result "$GameBuildDirectory/scoped-output-final.json"
    if($LASTEXITCODE -ne 0){throw 'Final Game compiler output scope failed'}
    if(!$ReusePackagePlan){
        & $python -B -X utf8 (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/plan_native_hardening_package.py') --stage $stage --overlay (Join-Path $repo 'Demos/UEPLyraIntegration/Overlay') --manifest (Join-Path $repo 'Demos/UEPLyraIntegration/Migration/batches.json') --fixtures "$FixtureEvidenceDirectory/assets.json" --result $plan
        if($LASTEXITCODE -ne 0){throw 'Complete current native package inventory failed'}
    }
    & (Join-Path $PSScriptRoot 'Run-UEP58MigrationCookPackage.ps1') -StageProject $StageProject -OutputDirectory $cookDirectory -GameBuildDirectory $GameBuildDirectory -PackagePlan $plan
    foreach($mode in @('Exceptions','Frontend')){
        & (Join-Path $PSScriptRoot 'Run-UEP58PackagedNativeValidation.ps1') -CookEvidenceDirectory $cookDirectory -OutputDirectory "$output/H04-Packaged$($mode)01" -Mode $mode
    }
    foreach($family in @('Damage','Pawn')){
        $port=if($family -eq 'Damage'){19011}else{19021}
        & (Join-Path $PSScriptRoot 'Run-UEP58PackagedNativeNetwork.ps1') -StageProject $StageProject -CookEvidenceDirectory $cookDirectory -OutputDirectory "$output/H04-Packaged$($family)Network01" -Family $family -ServerPort $port
    }
    foreach($name in $children|Where-Object {$_ -notlike '*.json'}){
        $path=Join-Path $output "$name/summary.json";$child=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -Depth 30
        if($child.status -ne 'passed'){throw 'Delivery child gate did not pass'}
        $summary.children+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    if((Get-FileHash -LiteralPath $PSCommandPath).Hash -ne $controlHash){throw 'Frozen delivery entrypoint changed'}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 10|Set-Content -LiteralPath (Join-Path $output $summaryName) -Encoding utf8}
