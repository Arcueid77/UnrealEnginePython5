#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('ExplorerExperience','ExplorerGameplay','ExplorerFollow','ExplorerActionsNetwork','ArenaLocalInput','ArenaOpponentBomb')][string]$Scenario,
    [Parameter(Mandatory=$true)][ValidateSet('BlueprintFallback','Python')][string]$Profile,
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [switch]$NaturalBomb,[switch]$VariableFrameTiming
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$stage=Split-Path ([IO.Path]::GetFullPath($StageProject)) -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
    (Test-Path -LiteralPath $output) -or !(Test-Path -LiteralPath "$stage/.uep-lyra-full-stage.json")) {throw 'Marked stage and fresh owned Experience evidence required'}
if(($NaturalBomb -or $VariableFrameTiming) -and $Scenario -ne 'ArenaLocalInput') {throw 'Bomb timing options require ArenaLocalInput'}
if($VariableFrameTiming -and !$NaturalBomb) {throw 'Variable timing requires NaturalBomb'}
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -match '^(UnrealEditor(-Cmd)?|LyraGame|UEPPythonThirdPerson|UnrealBuildTool|AutomationTool)\.exe$' -or
    ($_.Name -eq 'dotnet.exe' -and $_.CommandLine -match 'UnrealBuildTool\.dll|AutomationTool\.dll')}).Count) {throw 'Another native lane is active'}
$sdkPath=Join-Path $repo '.build/LyraValidation/BlueprintPython/20261023-pawn-sdk-causality/SDKBuild01/summary.json'
$sdk=Get-Content -LiteralPath $sdkPath -Raw|ConvertFrom-Json -Depth 30
if($sdk.status -ne 'built_requires_native_acceptance' -or $sdk.process.exit_code -ne 0 -or $null -ne $sdk.error) {throw 'Completed SDK236 build evidence required'}
$guards=@($sdk.source_hashes)+@($sdk.binary_after)
foreach($row in $guards) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Current SDK source/binary changed'}}
$source=Join-Path $PSScriptRoot ('Run-UEP58'+$Scenario+'Validation.ps1')
$original=[IO.File]::ReadAllText($source)
$oldSDK='.build/LyraValidation/BlueprintPython/20261023-current-third-person/SDKBuild01/summary.json'
$newSDK='.build/LyraValidation/BlueprintPython/20261023-pawn-sdk-causality/SDKBuild01/summary.json'
$replacements=[regex]::Matches($original,[regex]::Escape($oldSDK)).Count
if($Scenario.StartsWith('Explorer') -and $replacements -ne 1) {throw 'Expected Explorer SDK control boundary changed'}
if(!$Scenario.StartsWith('Explorer') -and $replacements) {throw 'Unreviewed Arena SDK replacement'}
$parseTokens=$null;$parseErrors=$null
$sourceAst=[Management.Automation.Language.Parser]::ParseInput($original,[ref]$parseTokens,[ref]$parseErrors)
if($parseErrors.Count -or $null -eq $sourceAst.ParamBlock) {throw 'Original Experience driver did not parse'}
$rootBinding="`n`$uepOriginalValidationRoot='"+$PSScriptRoot.Replace("'","''")+"'`n"
$derived=$original.Insert($sourceAst.ParamBlock.Extent.EndOffset,$rootBinding).Replace('$PSScriptRoot','$uepOriginalValidationRoot').Replace($oldSDK,$newSDK)
$liveReaderReplaced=$false
if($Scenario -eq 'ExplorerActionsNetwork') {
    $readers=@($sourceAst.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Read-ExplorerLiveJson'},$true))
    if($parseErrors.Count -or $readers.Count -ne 1) {throw 'Expected one original Explorer live-reader function'}
    $newReader=@'
function Read-ExplorerLiveJson([string]$Path){
    $raw=& '__PYTHON__' -B -X utf8 -c 'import json,sys;sys.path.insert(0,sys.argv[1]);from uep_lyra_network_io import read_json;print(json.dumps(read_json(sys.argv[2])))' '__SCRIPTS__' $Path
    if($LASTEXITCODE -ne 0) {throw 'Shared native JSON reader failed'}
    return ($raw|ConvertFrom-Json -Depth 80)
}
'@
    $newReader=$newReader.Replace('__PYTHON__','F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe').Replace('__SCRIPTS__',(Join-Path $repo 'Demos/UEPLyraIntegration/Overlay/Content/Scripts').Replace("'","''"))
    if(!$derived.Contains($readers[0].Extent.Text)) {throw 'Original live-reader replacement boundary changed'}
    $derived=$derived.Replace($readers[0].Extent.Text,$newReader);$liveReaderReplaced=$true
}
New-Item -ItemType Directory -Path "$output/Control"|Out-Null
$prior=Join-Path $output 'Control/original-driver.ps1'
Copy-Item -LiteralPath $source -Destination $prior
$driver=Join-Path $output 'Control/Run-Experience.ps1'
[IO.File]::WriteAllText($driver,$derived,[Text.UTF8Encoding]::new($false))
$provenance=[ordered]@{schema_version=1;scenario=$Scenario;profile=$Profile;
    wrapper=@{path=$PSCommandPath;sha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash};
    original=@{path=$source;archive=$prior;sha256=(Get-FileHash -LiteralPath $source).Hash};
    derived=@{path=$driver;sha256=(Get-FileHash -LiteralPath $driver).Hash};
    sdk=@{path=$sdkPath;sha256=(Get-FileHash -LiteralPath $sdkPath).Hash;guards=$guards};
    changes=@('Bind helpers through an explicit root variable,including interpolated paths','Use accepted current SDK236 instead of stale SDK235 fingerprint');
    sdk_path_replacements=$replacements;production_source_changed=$false;cpp_compile_executed=$false;cook_package_executed=$false}
$provenance.shared_python_live_reader=$liveReaderReplaced
$provenance|ConvertTo-Json -Depth 8|Set-Content -LiteralPath "$output/control-provenance.json" -Encoding utf8
$arguments=@{StageProject=$StageProject;OutputDirectory="$output/Runtime";Profile=$Profile}
if($NaturalBomb) {$arguments.NaturalBomb=$true}
if($VariableFrameTiming) {$arguments.VariableFrameTiming=$true}
& $driver @arguments
$summary=Get-Content -LiteralPath "$output/Runtime/summary.json" -Raw|ConvertFrom-Json -Depth 30
if($summary.status -ne 'passed') {throw 'Experience runtime failed; preserve its raw diagnostics'}
foreach($row in $guards) {if((Get-FileHash -LiteralPath $row.path).Hash -ne $row.sha256) {throw 'Frozen SDK input changed during Experience run'}}
Write-Host "Current Experience component passed: $Scenario $Profile;overall version remains separate"
