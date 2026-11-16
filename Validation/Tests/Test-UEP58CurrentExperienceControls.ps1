#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$EvidenceRoot,[Parameter(Mandatory=$true)][string]$Result)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$wrapper=Join-Path $repo 'Validation/Run-UEP58CurrentExperienceValidation.ps1'
$integration=Get-Content -LiteralPath "$EvidenceRoot/integration-review.json" -Raw|ConvertFrom-Json -Depth 60
if($integration.runs.Count -ne 12) {throw 'Twelve actual accepted controls required'}
$parses=0
foreach($path in @($wrapper)+@($integration.runs|ForEach-Object {Join-Path $repo ($_.directory+'/Control/Run-Experience.ps1')})) {
    $tokens=$null;$errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
    if($errors.Count) {throw "Control parse failure: $path"};$parses++
}
$stage=Join-Path $repo '.build/LyraValidation/Full/Stage/Lyra/LyraStarterGame.uproject'
$checked=0
function Reject-Preflight([hashtable]$Arguments,[string]$Expected) {
    $rejected=$false
    try {& $wrapper @Arguments} catch {if($_.ToString() -notmatch $Expected) {throw};$rejected=$true}
    if(!$rejected -or (Test-Path -LiteralPath $Arguments.OutputDirectory)) {throw 'Invalid preflight launched/created evidence'}
    $script:checked++
}
$common=@{Scenario='ExplorerFollow';Profile='Python';StageProject=$stage}
$outside=$common.Clone();$outside.OutputDirectory=Join-Path ([IO.Path]::GetTempPath()) ('uep-rejected-'+[guid]::NewGuid())
Reject-Preflight $outside 'Marked stage and fresh owned'
$options=$common.Clone();$options.OutputDirectory="$EvidenceRoot/Rejected-Options";$options.NaturalBomb=$true
Reject-Preflight $options 'Bomb timing options require ArenaLocalInput'
function Get-CimInstance {param([string]$ClassName) [pscustomobject]@{Name='UnrealEditor.exe';CommandLine='owned test placeholder'}}
try {
    $lane=$common.Clone();$lane.OutputDirectory="$EvidenceRoot/Rejected-Lane"
    Reject-Preflight $lane 'Another native lane is active'
} finally {Remove-Item Function:Get-CimInstance}
$summary=[ordered]@{status='passed';selected_ps_checks=($parses+$checked);control_parse_checks=$parses;invalid_preflight_checks=$checked;native_processes_launched=0}
$summary|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $Result -Encoding utf8
$summary|ConvertTo-Json -Compress
