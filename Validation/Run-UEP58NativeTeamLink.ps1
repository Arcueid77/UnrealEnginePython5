#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$PreviousBuildDirectory,[Parameter(Mandatory=$true)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
$repo=Split-Path $PSScriptRoot -Parent;$output=[IO.Path]::GetFullPath($OutputDirectory);$previous=[IO.Path]::GetFullPath($PreviousBuildDirectory)
$owned=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or !$previous.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {throw 'Owned previous build and fresh link output required'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UnrealBuildTool|AutomationTool|cl|link)\.exe$' -or ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count) {throw 'Another native lane is active'}
$old=Get-Content -LiteralPath "$previous/summary.json" -Raw|ConvertFrom-Json -Depth 30
$plan=Get-Content -LiteralPath "$previous/Plan/plan.json" -Raw|ConvertFrom-Json -Depth 30
if($old.status -ne 'failed' -or $old.error -notlike '*import-library exited 1181*' -or $old.processes.uht.exit_code -ne 0 -or $old.processes.'compile-1'.exit_code -ne 0 -or $old.processes.'compile-2'.exit_code -ne 0) {throw 'Both successful affected compilations and the bounded failed link are required'}
$frozen=@($plan.sources)+@($plan.derived)+@($plan.protected)+@($old.generated)+@($old.control_inputs)
foreach($row in $frozen) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw "Previous compiled input changed: $($row.path)"}}
New-Item -ItemType Directory -Path "$output/Plan","$output/Controls"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';batch='CPP02';module='LyraGame';cpp_compile_executed=$false;uht_executed=$false;engine_full_compile_executed=$false;cook_package_executed=$false;runtime_acceptance=$false;reused_compile_evidence=@{path="$previous/summary.json";sha256=(Get-FileHash -LiteralPath "$previous/summary.json").Hash};products=@();processes=@{};frozen=@();error=$null}
try {
    $relative='Intermediate/Build/Win64/x64/UnrealEditor/Development/LyraGame'
    $inter=Join-Path $plan.stage $relative;$baseInter=Join-Path $plan.baseline $relative
    foreach($name in @('Module.LyraGame.1.cpp.obj','Module.LyraGame.3.cpp.obj')) {$path=Join-Path $inter $name;$frozen+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    foreach($name in @('UnrealEditor-LyraGame.lib.rsp','UnrealEditor-LyraGame.dll.rsp')) {
        $text=Get-Content -LiteralPath (Join-Path $inter $name) -Raw
        foreach($slash in @($false,$true)) {
            $missing=Join-Path $inter 'Module.LyraGame.2.cpp.obj';$reused=Join-Path $baseInter 'Module.LyraGame.2.cpp.obj'
            if($slash) {$missing=$missing.Replace('\','/');$reused=$reused.Replace('\','/')}
            $text=$text.Replace($missing,$reused)
        }
        $path=Join-Path "$output/Plan" $name;$text|Set-Content -LiteralPath $path -Encoding utf8
        $frozen+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}
    }
    foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1'))) {Copy-Item -LiteralPath $path -Destination "$output/Controls";$frozen+=@{path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash}}
    $plan|Add-Member -NotePropertyName reused_compile_evidence -NotePropertyValue $summary.reused_compile_evidence
    $plan|ConvertTo-Json -Depth 24|Set-Content -LiteralPath "$output/Plan/plan.json" -Encoding utf8
    $link=Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/link.exe'
    foreach($step in @('import-library','link-dll')) {
        $name=if($step -eq 'import-library') {'UnrealEditor-LyraGame.lib.rsp'} else {'UnrealEditor-LyraGame.dll.rsp'}
        $arguments=@('@'+(Join-Path "$output/Plan" $name));if($step -eq 'import-library') {$arguments=@('/LIB')+$arguments}
        $summary.processes[$step]=Invoke-UEPValidationProcess $link $arguments 'F:/UnrealEngine/Engine/Source' "$output/$step" "native-team-$step" 1200
        $record=$summary.processes[$step];$diagnostics=(Get-Content -LiteralPath $record.stdout -Raw)+(Get-Content -LiteralPath $record.stderr -Raw)
        if($diagnostics -match '(?im)(error (C\d+|LNK\d+)|warning (C\d+|LNK\d+))') {throw 'Native team linker diagnostics failed'}
    }
    foreach($row in $frozen) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Frozen compile/link dependency changed'}}
    $summary.frozen=$frozen;$summary.products+=@{path=$plan.binary;sha256=(Get-FileHash -LiteralPath $plan.binary).Hash}
    $summary.status='built_requires_native_acceptance'
} catch {$summary.error=$_.ToString();throw}
finally {$summary|ConvertTo-Json -Depth 24|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
