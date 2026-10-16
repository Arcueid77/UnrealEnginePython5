#Requires -Version 7.0
# Static orchestration checks, not native gameplay/exit acceptance.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$path=Join-Path (Split-Path $PSScriptRoot -Parent) 'Run-UEP58JumpValidation.ps1'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
if(@($errors).Count){throw 'Native driver parse errors'}
$initial=@($ast.FindAll({param($node)
    $node -is [Management.Automation.Language.AssignmentStatementAst] -and
    $node.Left -is [Management.Automation.Language.VariableExpressionAst] -and
    $node.Left.VariablePath.UserPath -eq 'arguments' -and
    $node.Operator -eq [Management.Automation.Language.TokenKind]::Equals
},$true))
if($initial.Count -ne 1){throw 'Expected one common native argument initialization'}
$values=@($initial[0].Right.FindAll({param($node)
    $node -is [Management.Automation.Language.StringConstantExpressionAst]
},$true)|ForEach-Object {$_.Value})
if(@($values|Where-Object {$_ -eq '-NoDDCCleanup'}).Count -ne 1){throw 'Scoped native cache housekeeping must be disabled exactly once'}
foreach($flag in @('-game','-RenderOffscreen','-unattended','-NoSound','-DisablePython')){
    if($flag -notin $values){throw "Native scenario launch contract missing: $flag"}
}
$source=$ast.Extent.Text
if(!$source.Contains('$watch.Elapsed.TotalSeconds -gt 520') -or
   !$source.Contains('$summary.processes[$peer].exit_code -ne 0')){throw 'Native timeout or real process exit gate changed'}
if(!$source.Contains('Assert-UEPFocusedLog') -or !$source.Contains('$summary.external_gate')){throw 'Independent report/log gates missing'}
Write-Host 'Native driver safety checks PASS: 5 (no runtime acceptance claim)'
