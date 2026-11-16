#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/Stage/Lyra/LyraStarterGame.uproject',
    [string]$PreviousBuild='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/20261102-CPP19/Build02BodyRepair',
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {throw 'Owned stage and fresh build output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count) {throw 'Another native lane is active'}
New-Item -ItemType Directory -Path $output|Out-Null
New-Item -ItemType Directory -Path "$output/Controls"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';batch='H01';module='LyraGame';error=$null;
    cpp_compile_executed=$false;engine_full_compile_executed=$false;cook_package_executed=$false;
    runtime_acceptance=$false;patch=$null;plan=$null;processes=@{};generated=@();products=@();control_inputs=@()}
$python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
$tools=Join-Path $repo 'Demos/UEPLyraIntegration/Tools'
function Get-NativeRuleHash([string]$Path) {return @{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try {
    foreach($control in @($PSCommandPath,"$tools/native_world_policy_patches.py","$tools/native_team_patches.py","$tools/prepare_native_hardening_build.py","$tools/prepare_native_message_build.py",(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'))) {
        Copy-Item -LiteralPath $control -Destination "$output/Controls"
        $summary.control_inputs+=Get-NativeRuleHash $control
    }
    & $python -B -X utf8 "$tools/prepare_native_hardening_build.py" --previous $PreviousBuild --output "$output/Repair"
    if($LASTEXITCODE -ne 0){throw 'Rule body repair plan failed'}
    New-Item -ItemType Directory -Path "$output/Plan"|Out-Null
    Copy-Item -LiteralPath "$output/Repair/Plan/plan.json" -Destination "$output/Plan/plan.json"
    $plan=Get-Content -LiteralPath "$output/Plan/plan.json" -Raw|ConvertFrom-Json -Depth 25
    $summary.generated=Get-Content -LiteralPath "$output/Repair/reused-generated.json" -Raw|ConvertFrom-Json -Depth 8
    $summary.plan=Get-NativeRuleHash "$output/Plan/plan.json"
    $summary.header_generation_executed=$false
    $toolchain=Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64'
    foreach($step in $plan.steps) {
        $arguments=@('@'+$step.rsp)
        if($step.name -like 'import-library*') {$arguments=@('/LIB')+$arguments}
        $summary.cpp_compile_executed=$true
        $record=Invoke-UEPValidationProcess (Join-Path $toolchain $step.tool) $arguments 'F:/UnrealEngine/Engine/Source' (Join-Path $output $step.name) ('native-rule-'+$step.name) 1200
        $summary.processes[$step.name]=$record
        $diagnostics=(Get-Content -LiteralPath $record.stdout -Raw)+(Get-Content -LiteralPath $record.stderr -Raw)
        if($diagnostics -match '(?im)(error (C\d+|LNK\d+)|warning (C\d+|LNK\d+))') {throw 'Native module compiler/linker diagnostics failed'}
    }
    foreach($row in @($plan.sources)+@($plan.derived)+@($plan.protected)+@($summary.generated)+@($summary.control_inputs)) {
        if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw "Frozen/protected input changed: $($row.path)"}
    }
    $summary.products+=Get-NativeRuleHash $plan.binary
    $summary.products+=Get-NativeRuleHash $plan.topdown_binary
    $summary.status='built_requires_native_acceptance'
} catch {$summary.error=$_.ToString();throw}
finally {$summary|ConvertTo-Json -Depth 24|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
