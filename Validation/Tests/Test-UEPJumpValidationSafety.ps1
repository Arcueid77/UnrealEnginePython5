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
if(!$source.Contains('if($CharacterDeathReplication -and (!$Network -or !$CharacterDeathStarted))')){throw 'Native replicated death requires its current profile and network lane'}
if(!$source.Contains("if(`$CharacterDeathReplication){`$module='uep_lyra_characters.death_replication_contract'}")){throw 'Replicated death independent semantic gate missing'}
if(!$source.Contains("'Grenade activation requires a separate standalone lane and current revision proof'") -or
   !$source.Contains("if(`$GrenadeActivation){`$flag='-UEPGrenadeActivationResult'")){throw 'Grenade activation must use a separate explicit standalone entry'}
if(!$source.Contains("if(`$GrenadeActivation){`$module='uep_lyra_abilities.grenade_activation_contract'}") -or
   !$source.Contains("'Grenade native parameter default import failed'")){throw 'Grenade activation independent semantic/default import gates missing'}
if(!$source.Contains("if(`$GrenadeActivationNetwork)") -or
   !$source.Contains("'Network Grenade activation must explicitly request its predicted two-owner fixture'")){throw 'Grenade predicted activation must be an explicit separate lane'}
if(!$source.Contains("if(`$GrenadeActivationNetwork){`$module='uep_lyra_abilities.grenade_activation_network_contract'}") -or
   !$source.Contains("'-UEPGrenadeActivationNetworkResult'")){throw 'Grenade predicted activation result/independent gate missing'}
if(!$source.Contains("'Grenade VFX requires its separate standalone Actor lane and current proof'") -or
   !$source.Contains("if(`$GrenadeVFX){`$flag='-UEPGrenadeVFXResult'")){throw 'Grenade Actor VFX fixture must have its explicit standalone entry'}
if(!$source.Contains("if(`$GrenadeVFX){`$module='uep_lyra_weapons.grenade_vfx_contract'}") -or
   !$source.Contains("'Accepted retained Grenade Actor VFX proof required'")){throw 'Grenade VFX asset/native independent gates missing'}
if(!$source.Contains("'Grenade cleanup requires a separate original native timer Actor lane and current revision'") -or
   !$source.Contains("if(`$GrenadeCleanup){`$flag='-UEPGrenadeCleanupResult'")){throw 'Grenade native timer fixture requires explicit separate entry'}
if(!$source.Contains("if(`$GrenadeCleanup){`$module='uep_lyra_weapons.grenade_cleanup_contract'}") -or
   !$source.Contains("'VFX regression requires matching retained Actor revision provenance'")){throw 'Cleanup native semantic gate/current VFX provenance missing'}
if(!$source.Contains("'Grenade actions require separate native ordinary-entry lane and current Actor proof'") -or
   !$source.Contains("if(`$GrenadeActions){`$flag='-UEPGrenadeActionsResult'")){throw 'Actor action fixture must use explicit isolated native entry'}
if(!$source.Contains("if(`$GrenadeActions){`$module='uep_lyra_weapons.grenade_actions_contract'}") -or
   !$source.Contains("'Cleanup regression requires matching current action revision chain'")){throw 'Actor action independent gate/current family provenance missing'}
if(!$source.Contains("'Grenade BeginPlay requires separate native Actor-owned timer lane and current proof'") -or
   !$source.Contains("if(`$GrenadeBegin){`$flag='-UEPGrenadeBeginResult'")){throw 'BeginPlay needs isolated actual Actor timer lane'}
if(!$source.Contains("if(`$GrenadeBegin){`$module='uep_lyra_weapons.grenade_begin_contract'}") -or
   !$source.Contains("'Current BeginPlay family native revision chain proof incomplete'")){throw 'BeginPlay independent gate/current family proof missing'}
if(!$source.Contains("'Headless Grenade requires its dedicated native server-only BeginPlay lane'") -or
   !$source.Contains("'-server','-NullRHI','-port=7794','-multihome=127.0.0.1','-UEPGrenadeHeadless'")){throw 'Headless Actor lane must be explicit existing native server/no-render/local bind'}
if(!$source.Contains("if(`$GrenadeHeadless){`$gateArgs+=@('--headless')}") -or
   !$source.Contains("`$beginAllowed=@(") -or !$source.Contains("'GrenadeHeadless'")){throw 'Headless native mode semantic gate missing'}
Write-Host 'Native driver safety checks PASS: 21 (no runtime acceptance claim)'
