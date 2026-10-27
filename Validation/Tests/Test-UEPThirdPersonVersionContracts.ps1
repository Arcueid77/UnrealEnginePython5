#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$MixinReport,
      [Parameter(Mandatory=$true)][string]$PythonFirstReport,
      [Parameter(Mandatory=$true)][string]$Descriptor,
      [Parameter(Mandatory=$true)][string]$Result,
      [string]$Driver=(Join-Path $PSScriptRoot '../../Demos/Run-UEPThirdPersonDemo.ps1'))
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$errors=$null;$tokens=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile([IO.Path]::GetFullPath($Driver),[ref]$tokens,[ref]$errors)
if($errors.Count) {throw 'Demo driver does not parse'}
foreach($name in @('Assert-PythonFirstReport','Assert-MixinReport')) {
    $functions=@($ast.FindAll({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name},$true))
    if($functions.Count -ne 1) {throw 'Expected original assertion function missing/duplicated'}
    . ([ScriptBlock]::Create($functions[0].Extent.Text))
}
$version=[string](Get-Content -LiteralPath $Descriptor -Raw|ConvertFrom-Json).VersionName
if([string]::IsNullOrWhiteSpace($version)) {throw 'Expected descriptor version missing'}
$checks=@()
foreach($case in @(@{name='Mixin';file=$MixinReport;function='Assert-MixinReport'},@{name='PythonFirst';file=$PythonFirstReport;function='Assert-PythonFirstReport'})) {
    $report=Get-Content -LiteralPath $case.file -Raw|ConvertFrom-Json -Depth 40
    & $case.function -Report $report -ResultPath $case.file -Label 'actual package;exact build version' -ExpectedUEPVersion $version
    $checks+=@{variant=$case.name;check='actual_native_report_exact_descriptor_version';status='passed'}
    $rejected=$false
    try {& $case.function -Report $report -ResultPath $case.file -Label 'wrong version' -ExpectedUEPVersion ($version+'.wrong')}catch{$rejected=$true}
    if(!$rejected) {throw 'Wrong version was silently accepted'}
    $checks+=@{variant=$case.name;check='wrong_expected_version_rejected';status='passed'}
    $report.teardown.session_released=$false;$rejected=$false
    try {& $case.function -Report $report -ResultPath $case.file -Label 'lifetime failure' -ExpectedUEPVersion $version}catch{$rejected=$true}
    if(!$rejected) {throw 'Version correction hid a lifecycle failure'}
    $checks+=@{variant=$case.name;check='native_lifetime_failure_still_rejected';status='passed'}
}
$text=[IO.File]::ReadAllText([IO.Path]::GetFullPath($Driver))
if([regex]::Matches($text,'-ExpectedUEPVersion \$expectedUEPVersion').Count -ne 4) {throw 'All four actual smoke/package call sites must use the staged descriptor version'}
if($text -notmatch 'AndroidFileServer,UdpMessaging,TcpMessaging,ResonanceAudio') {throw 'Known Third Person Editor validation plugin scope missing'}
$report=[ordered]@{schema_version=1;status='passed';checks=$checks;expected_version=$version;driver_parse_checks=1;
    actual_call_sites_checked=4;driver=@{path=[IO.Path]::GetFullPath($Driver);sha256=(Get-FileHash -LiteralPath $Driver).Hash};
    native_processes_launched=0;cpp_compile_executed=$false;cook_package_executed=$false}
$report|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $Result -Encoding utf8
Write-Host "Third Person actual-report contract checks: $($checks.Count) passed"
