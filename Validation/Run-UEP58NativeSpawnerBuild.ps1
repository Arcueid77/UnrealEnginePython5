#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplay/Stage/Lyra/LyraStarterGame.uproject',
    [string]$BaselineStage='F:/UnrealEnginePython5/.build/LyraValidation/Full/Stage/Lyra',
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
$summary=[ordered]@{schema_version=1;status='failed';batch='CPP06';module='LyraGame';error=$null;
    cpp_compile_executed=$false;engine_full_compile_executed=$false;cook_package_executed=$false;
    runtime_acceptance=$false;patch=$null;plan=$null;processes=@{};generated=@();products=@();control_inputs=@()}
$python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
$tools=Join-Path $repo 'Demos/UEPLyraIntegration/Tools'
function Get-NativeRuleHash([string]$Path) {return @{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try {
    foreach($control in @($PSCommandPath,"$tools/native_spawner_patches.py","$tools/native_team_patches.py","$tools/prepare_native_spawner_build.py","$tools/prepare_native_message_build.py",(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'))) {
        Copy-Item -LiteralPath $control -Destination "$output/Controls"
        $summary.control_inputs+=Get-NativeRuleHash $control
    }
    & $python -B -X utf8 "$tools/native_spawner_patches.py" --stage $stage --output "$output/SourcePatch"
    if($LASTEXITCODE -ne 0) {throw 'Native event patch failed'}
    $summary.patch=Get-NativeRuleHash "$output/SourcePatch/summary.json"
    & $python -B -X utf8 "$tools/prepare_native_spawner_build.py" --stage $stage --baseline $BaselineStage --output "$output/Plan"
    if($LASTEXITCODE -ne 0) {throw 'Native module plan failed'}
    $plan=Get-Content -LiteralPath "$output/Plan/plan.json" -Raw|ConvertFrom-Json -Depth 20
    if($plan.uht_export_modules.Count -ne 1 -or $plan.uht_export_modules[0] -ne 'LyraGame') {throw 'Header generation must be limited to LyraGame'}
    $summary.plan=Get-NativeRuleHash "$output/Plan/plan.json"
    $dotnet='F:/UnrealEngine/Engine/Binaries/ThirdParty/DotNet/10.0/win-x64/dotnet.exe'
    $ubt='F:/UnrealEngine/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.dll'
    # UBT and managed UHT both consume -Log. Supplying one shared path makes
    # their two writers attempt to back up the same open file. Capture stdout
    # here and let each tool keep its distinct default internal log.
    $arguments=@($ubt,'-Mode=UnrealHeaderTool',$StageProject,$plan.uht_manifest,'-WarningsAsErrors')
    $summary.processes.uht=Invoke-UEPValidationProcess $dotnet $arguments 'F:/UnrealEngine/Engine/Source' "$output/UHT" 'native-rule-UHT' 1200
    foreach($file in Get-ChildItem -LiteralPath $plan.generated_directory -File -Recurse) {$summary.generated+=Get-NativeRuleHash $file.FullName}
    $toolchain=Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64'
    foreach($step in $plan.steps) {
        $arguments=@('@'+$step.rsp)
        if($step.name -eq 'import-library') {$arguments=@('/LIB')+$arguments}
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
    $summary.status='built_requires_native_acceptance'
} catch {$summary.error=$_.ToString();throw}
finally {$summary|ConvertTo-Json -Depth 24|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
