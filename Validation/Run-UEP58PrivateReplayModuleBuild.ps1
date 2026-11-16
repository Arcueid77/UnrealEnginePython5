#Requires -Version 7.0
[CmdletBinding()]
param([string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/CppGameplayExtended/Stage/Lyra/LyraStarterGame.uproject',[Parameter(Mandatory=$true)][string]$OutputDirectory,[string]$ReuseFrom)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory)
$owned=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)){throw 'Owned private stage and fresh replay build required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|cl|link|UnrealBuildTool|AutomationTool)\.exe$'}).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path "$output/Controls"|Out-Null
$summary=[ordered]@{status='failed';private_test_dependency='InMemoryNetworkReplayStreaming';processes=@{};products=@();control_inputs=@();engine_files_modified=$false;engine_full_compile_executed=$false;error=$null}
function Replay-Hash([string]$Path){@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $script=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/prepare_private_replay_module.py'
    foreach($file in @($script,$PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'))){Copy-Item -LiteralPath $file -Destination "$output/Controls";$summary.control_inputs+=Replay-Hash $file}
    $prepareArguments=@('-B','-X','utf8',$script,'--stage',$stage,'--output',"$output/Plan")
    if($ReuseFrom){$prepareArguments+=@('--reuse-from',$ReuseFrom)}
    & 'F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe' @prepareArguments
    if($LASTEXITCODE -ne 0){throw 'Replay dependency plan failed'}
    $plan=Get-Content -LiteralPath "$output/Plan/plan.json" -Raw|ConvertFrom-Json -Depth 12
    $chain=Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64'
    foreach($step in $plan.steps){
        $arguments=@('@'+$step.rsp);if($step.name -eq 'import-library'){$arguments=@('/LIB')+$arguments}
        $record=Invoke-UEPValidationProcess (Join-Path $chain $step.tool) $arguments 'F:/UnrealEngine/Engine/Source' "$output/$($step.name)" 'private memory replay dependency' 300
        $summary.processes[$step.name]=$record
        if(((Get-Content -LiteralPath $record.stdout -Raw)+(Get-Content -LiteralPath $record.stderr -Raw)) -match '(?im)(error (C\d+|LNK\d+)|warning (C\d+|LNK\d+))'){throw 'Replay dependency diagnostics failed'}
    }
    foreach($row in @($plan.sources)+@($plan.derived)+@($plan.protected)+@($summary.control_inputs)){if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256){throw 'Replay dependency frozen input changed'}}
    Copy-Item -LiteralPath $plan.manifest -Destination "$output/Previous.modules"
    $manifest=Get-Content -LiteralPath $plan.manifest -Raw|ConvertFrom-Json -AsHashtable
    if($manifest.Modules.ContainsKey('InMemoryNetworkReplayStreaming')){throw 'Private module manifest already registered'}
    $manifest.Modules.InMemoryNetworkReplayStreaming='UnrealEditor-InMemoryNetworkReplayStreaming.dll'
    $manifest|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $plan.manifest -Encoding utf8
    $summary.products+=Replay-Hash $plan.binary;$summary.products+=Replay-Hash $plan.manifest;$summary.status='built_requires_native_acceptance'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
