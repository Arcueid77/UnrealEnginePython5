#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',
    [string]$StageProject='F:/UnrealEnginePython5/.build/LyraValidation/Full/Stage/Lyra/LyraStarterGame.uproject',
    [Parameter(Mandatory=$true)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
    !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json") -or (Test-Path -LiteralPath $output)){throw 'Marked isolated stage and fresh build output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|UnrealBuildTool|AutomationTool|LyraGame)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path "$output/PreviousBinaries"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';scope='isolated-LyraGame-Editor-module-simulated-proxy-init-guard';cpp_compile_executed=$false;cook_package_executed=$false;runtime_acceptance=$false;full_acceptance=$false;hashes=@();protected=@();previous_products=@();products=@();actions=@();plan=$null;build=$null;error=$null}
function Get-GuardHash([string]$Path){return @{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try{
    $official='F:/LyraStarterGame/Source/LyraGame/Character/LyraHeroComponent.cpp'
    $target=Join-Path $stage 'Source/LyraGame/Character/LyraHeroComponent.cpp'
    $patch=Join-Path $repo 'Demos/UEPLyraIntegration/Migration/NativeFixes/LyraHeroComponent-simulated-proxy-owner.patch'
    if((Get-FileHash -LiteralPath $official).Hash -ne 'D036B6BBBF0FC8170CB31D0F3271D887D44F1B683DB564F0E036F74B0E68D3E7'){throw 'Reviewed official Lyra source changed'}
    $before=[IO.File]::ReadAllText($official)
    $newline=if($before.Contains("`r`n")){"`r`n"}else{"`n"}
    $anchor="`t`treturn LyraPS && Manager->HasFeatureReachedInitState(Pawn, ULyraPawnExtensionComponent::NAME_ActorFeatureName, LyraGameplayTags::InitState_DataInitialized);"
    if([regex]::Matches($before,[regex]::Escape($anchor)).Count -ne 1){throw 'One exact native init-state anchor required'}
    $lines=@(Get-Content -LiteralPath $patch | Where-Object {$_.StartsWith('+') -and !$_.StartsWith('+++')} | ForEach-Object {$_.Substring(1)})
    if($lines.Count -ne 8){throw 'Reviewed eight-line patch required'}
    $expected=$before.Replace($anchor,(($lines -join $newline)+$newline+$anchor))
    $current=[IO.File]::ReadAllText($target)
    if($current -ceq $before){[IO.File]::WriteAllText($target,$expected,[Text.UTF8Encoding]::new($false))}
    elseif($current -cne $expected){throw 'Stage contains an unrelated native edit'}
    $summary.hashes+=Get-GuardHash $target
    foreach($path in @($PSCommandPath,$patch,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'),$project)){$summary.hashes+=Get-GuardHash $path}
    foreach($path in @($official,(Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules'),(Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Engine.dll'),"$stage/Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll","$stage/Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor-UEPLyraBridge.dll")){$summary.protected+=Get-GuardHash $path}
    foreach($name in @('UnrealEditor-LyraGame.dll','UnrealEditor-LyraGame.pdb','UnrealEditor.modules','LyraEditor.target')){
        $path=Join-Path "$stage/Binaries/Win64" $name
        if(Test-Path -LiteralPath $path){$copy=Join-Path "$output/PreviousBinaries" $name;Copy-Item -LiteralPath $path -Destination $copy;$summary.previous_products+=Get-GuardHash $copy}
    }
    # Reuse this stage's generated MSVC commands. Normal UBT module selection also
    # follows stale Engine import-library dependencies; this refresh owns only
    # the unity translation unit containing HeroComponent and its two link steps.
    $intermediate=Join-Path $stage 'Intermediate/Build/Win64/x64/UnrealEditor/Development/LyraGame'
    $units=@(Get-ChildItem -LiteralPath $intermediate -Filter 'Module.LyraGame.*.cpp' | Where-Object {(Get-Content -LiteralPath $_.FullName -Raw).Contains('/Source/LyraGame/Character/LyraHeroComponent.cpp')})
    if($units.Count -ne 1){throw 'One existing unity translation unit containing HeroComponent required'}
    $toolchain=Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64'
    $steps=@(@{name='compile';tool='cl.exe';rsp=$units[0].FullName+'.obj.rsp'},@{name='import-library';tool='link.exe';rsp="$intermediate/UnrealEditor-LyraGame.lib.rsp"},@{name='link-dll';tool='link.exe';rsp="$intermediate/UnrealEditor-LyraGame.dll.rsp"})
    foreach($path in @($units[0].FullName,"$intermediate/LyraGame.Shared.rsp","$intermediate/Definitions.LyraGame.h")){$summary.hashes+=Get-GuardHash $path}
    foreach($file in Get-ChildItem -LiteralPath "$stage/Source" -Recurse -File){$summary.hashes+=Get-GuardHash $file.FullName}
    foreach($relative in @('Engine/Binaries/Win64/UnrealEditor-NetCore.dll','Engine/Intermediate/Build/Win64/x64/UnrealEditor/Development/NetCore/UnrealEditor-NetCore.lib','Engine/Intermediate/Build/Win64/x64/UnrealEditor/Development/NetCore/Module.NetCore.cpp.obj')){$summary.protected+=Get-GuardHash (Join-Path $EngineRoot $relative)}
    foreach($step in $steps){
        $contents=Get-Content -LiteralPath $step.rsp -Raw
        if($contents -notmatch 'LyraGame' -or $contents -match '(?im)/(?:OUT|Fo|PDB):?"?(?:\.\./|F:/UnrealEngine/Engine/)'){throw 'Response file contains a protected Engine output'}
        $summary.hashes+=Get-GuardHash $step.rsp
        $tool=Join-Path $toolchain $step.tool;$summary.hashes+=Get-GuardHash $tool
        $summary.actions+=@{name=$step.name;executable=$tool;response_file=$step.rsp}
    }
    $summary.cpp_compile_executed=$true
    foreach($step in $summary.actions){
        $arguments=@('@'+$step.response_file)
        if($step.name -eq 'import-library'){$arguments=@('/LIB')+$arguments}
        $record=Invoke-UEPValidationProcess $step.executable $arguments (Join-Path $EngineRoot 'Engine/Source') (Join-Path $output $step.name) $step.name 1200
        $log=(Get-Content -LiteralPath $record.stdout -Raw)+(Get-Content -LiteralPath $record.stderr -Raw)
        if($log -match '(?im)(error (C\d+|LNK\d+)|warning (C\d+|LNK\d+))'){throw 'Incremental MSVC diagnostics failed'}
        $step.process=$record
    }
    foreach($path in @($summary.hashes)+@($summary.protected)){if((Get-FileHash -LiteralPath $path.path).Hash -ne $path.sha256){throw "Frozen/protected build input changed: $($path.path)"}}
    foreach($name in @('UnrealEditor-LyraGame.dll','UnrealEditor.modules')){$summary.products+=Get-GuardHash (Join-Path "$stage/Binaries/Win64" $name)}
    $summary.status='passed'
}catch{$summary.error=$_.ToString();throw}
finally{$summary|ConvertTo-Json -Depth 14|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Isolated LyraGame guard build: $($summary.status); $output"
