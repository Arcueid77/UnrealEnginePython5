#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$PreviousBuildDirectory='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplay/20261101-CPP08/Build02',
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory)
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool|cl|link)\.exe$'}).Count){throw 'Another native lane is active'}
$python='F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe';$tools=Join-Path $repo 'Demos/UEPLyraIntegration/Tools'
& $python -B -X utf8 "$tools/prepare_native_interaction_fixture_rebuild.py" --previous $PreviousBuildDirectory --output $output
if($LASTEXITCODE -ne 0){throw 'Native witness rebuild plan failed'}
$plan=Get-Content -LiteralPath "$output/Plan/plan.json" -Raw|ConvertFrom-Json -Depth 32
$summary=[ordered]@{schema_version=1;status='failed';batch='CPP08';module='LyraGame';error=$null;cpp_compile_executed=$false;header_generation_executed=$false;engine_full_compile_executed=$false;cook_package_executed=$false;runtime_acceptance=$false;plan=$null;processes=@{};generated=@();products=@();control_inputs=@();previous_build=$PreviousBuildDirectory}
function Get-NativeFixtureHash([string]$Path){return @{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    New-Item -ItemType Directory -Path "$output/Controls"|Out-Null
    foreach($path in @($PSCommandPath,"$tools/prepare_native_interaction_fixture_rebuild.py",(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'))){Copy-Item -LiteralPath $path -Destination "$output/Controls";$summary.control_inputs+=Get-NativeFixtureHash $path}
    $summary.plan=Get-NativeFixtureHash "$output/Plan/plan.json"
    foreach($file in Get-ChildItem -LiteralPath $plan.generated_directory -File -Recurse){$summary.generated+=Get-NativeFixtureHash $file.FullName}
    $toolchain=Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64'
    foreach($step in $plan.steps){
        $arguments=@('@'+$step.rsp);if($step.name -eq 'import-library'){$arguments=@('/LIB')+$arguments}
        $record=Invoke-UEPValidationProcess (Join-Path $toolchain $step.tool) $arguments 'F:/UnrealEngine/Engine/Source' (Join-Path $output $step.name) ('native-witness-'+$step.name) 1200
        $summary.processes[$step.name]=$record;$summary.cpp_compile_executed=$true
        if(((Get-Content -LiteralPath $record.stdout -Raw)+(Get-Content -LiteralPath $record.stderr -Raw)) -match '(?im)(error (C\d+|LNK\d+)|warning (C\d+|LNK\d+))'){throw 'Native witness compiler/linker diagnostic failed'}
    }
    foreach($row in @($plan.sources)+@($plan.derived)+@($plan.protected)+@($summary.generated)+@($summary.control_inputs)){
        if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw "Frozen native witness input changed: $($row.path)"}
    }
    $summary.products+=Get-NativeFixtureHash $plan.binary;$summary.status='built_requires_native_acceptance'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 24|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
