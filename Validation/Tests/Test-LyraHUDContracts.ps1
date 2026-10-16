[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path $PSScriptRoot -Parent) "LyraHUDContracts.ps1")

$cases = [System.Collections.Generic.List[string]]::new()

function Test-Case {
    param([string]$Name, [scriptblock]$Body)
    & $Body
    $cases.Add($Name)
    Write-Output "PASS $Name"
}

function Assert-Rejected {
    param([scriptblock]$Body, [string]$Message)
    $rejected = $false
    try { & $Body | Out-Null }
    catch {
        if ($Message -and !$_.Exception.Message.Contains($Message)) { throw }
        $rejected = $true
    }
    if (!$rejected) { throw "Expected validation to reject this fixture" }
}

function Copy-Fixture {
    param([object]$Value)
    return ($Value | ConvertTo-Json -Depth 25 | ConvertFrom-Json)
}

function New-HUDState {
    return [pscustomobject]@{
        active_widget_count = 1; active_widgets = @("fixture-widget")
        live_widget_reference_count = 1
        construct_count = 3; destruct_count = 2; teardown_count = 2
        controller_bind_count = 3; controller_unbind_count = 2
        health_bind_count = 4; health_unbind_count = 3
        health_events = @([pscustomobject]@{ health = 100 })
        errors = @()
    }
}

function New-ShutdownReport {
    $before = New-HUDState
    $final = Copy-Fixture $before
    $final.active_widget_count = 0
    $final.active_widgets = @()
    $final.live_widget_reference_count = 0
    $final.controller_unbind_count = 3
    $final.health_unbind_count = 4
    $final.destruct_count = 3
    $final.teardown_count = 3
    return [pscustomobject]@{
        schema_version = 5; status = "passed"; hud = $before
        shutdown = [pscustomobject]@{
            status = "passed"; phase = "python_atexit"; hud = $final
        }
    }
}

# Synthetic shape only, not an exported Blueprint or retained runtime result.
function New-Audit {
    $healthbar = [pscustomobject]@{
        role = "healthbar"; path = "/Game/UI/Hud/W_Healthbar"
        generated_class = "W_Healthbar_C"; graphs = @("synthetic EventGraph")
        reflected_properties = @("HealthNumber", "NormalizedHealth", "HealthOldValue", "HealthNewValue", "BarFillMID", "PythonMixinProfile")
        reflected_functions = @("Construct", "InitializeBarVisuals", "SetDynamicMaterials", "GetPythonMixinSet", "GetPythonMixinProfile")
        mixin = [pscustomobject]@{
            implemented_interfaces = @("UEPPythonMixinInterface")
            mixin_set_path = "/Game/UEPMixins/DA_LyraHealthbarMixin.DA_LyraHealthbarMixin"
            mixin_set_class = "UEPPythonMixinSet"
            selected_profile = "Python"; default_profile = "Python"
            profiles = @(
                [pscustomobject]@{profile_name="Python"; python_module="uep_lyra_hud.healthbar_mixin"; python_class="LyraHealthbarPythonProfile"},
                [pscustomobject]@{profile_name="BlueprintFallback"; python_module="uep_lyra_hud.healthbar_mixin"; python_class="LyraHealthbarBlueprintFallbackProfile"}
            )
        }
    }
    return [pscustomobject]@{
        schema_version=1; status="passed"; engine_version=@(5,8)
        widget_blueprints=@(
            $healthbar,
            [pscustomobject]@{role="default_hud_layout"; path="/Game/UI/Hud/W_DefaultHUDLayout"; generated_class="W_DefaultHUDLayout_C"; graphs=@("synthetic")},
            [pscustomobject]@{role="shooter_hud_layout"; path="/ShooterCore/UserInterface/W_ShooterHUDLayout"; generated_class="W_ShooterHUDLayout_C"; graphs=@("synthetic")}
        )
        data_assets=@([pscustomobject]@{
            role="shooter_hud_action_set"; path="/ShooterCore/Experiences/LAS_ShooterGame_StandardHUD"
            asset_class="LyraExperienceActionSet"; action_count=1; game_features_to_enable=@("ShooterCore")
            actions=@([pscustomobject]@{class="GameFeatureAction_AddWidgets"; layout_entry_count=1; widget_entry_count=11})
        })
    }
}

Test-Case "single presenter passes" { Assert-LyraHUDActiveState (New-HUDState) "client" }
Test-Case "two balanced presenters fail" {
    $hud = New-HUDState
    $hud.active_widget_count = 2; $hud.live_widget_reference_count = 2
    $hud.active_widgets = @("first", "second")
    $hud.controller_bind_count++; $hud.health_bind_count++
    Assert-Rejected { Assert-LyraHUDActiveState $hud "client" } "Exactly one"
}
Test-Case "zero client presenters fail" {
    $hud = (New-ShutdownReport).shutdown.hud
    Assert-Rejected { Assert-LyraHUDActiveState $hud "client" } "Exactly one"
}
Test-Case "live reference ledger mismatch fails" {
    $hud = New-HUDState; $hud.live_widget_reference_count = 2
    Assert-Rejected { Assert-LyraHUDActiveState $hud "client" } "Exactly one"
}
Test-Case "missing active counter fails closed" {
    $hud = New-HUDState; $hud.PSObject.Properties.Remove("active_widget_count")
    Assert-Rejected { Assert-LyraHUDActiveState $hud "client" } "absent HUD counter"
}
Test-Case "dedicated server cannot construct a presenter" {
    Assert-Rejected { Assert-LyraHUDActiveState (New-HUDState) "server" } "Dedicated-server"
}
Test-Case "clean final snapshot passes" { Assert-LyraHUDShutdownReport (New-ShutdownReport) }
Test-Case "missing shutdown evidence fails" {
    $report = New-ShutdownReport; $report.PSObject.Properties.Remove("shutdown")
    Assert-Rejected { Assert-LyraHUDShutdownReport $report } "final Python-exit"
}
Test-Case "pending shutdown cannot pass" {
    $report = New-ShutdownReport; $report.status = "awaiting_shutdown"
    Assert-Rejected { Assert-LyraHUDShutdownReport $report } "final Python-exit"
}
Test-Case "residual controller callback fails" {
    $report = New-ShutdownReport; $report.shutdown.hud.controller_unbind_count--
    Assert-Rejected { Assert-LyraHUDShutdownReport $report } "retained owned callbacks"
}
Test-Case "residual health callback fails" {
    $report = New-ShutdownReport; $report.shutdown.hud.health_unbind_count--
    Assert-Rejected { Assert-LyraHUDShutdownReport $report } "retained owned callbacks"
}
Test-Case "residual widget reference fails" {
    $report = New-ShutdownReport; $report.shutdown.hud.live_widget_reference_count = 1
    Assert-Rejected { Assert-LyraHUDShutdownReport $report } "retained a presenter"
}
Test-Case "resetting final counters cannot erase leaks" {
    $report = New-ShutdownReport
    $report.shutdown.hud.health_bind_count = 0; $report.shutdown.hud.health_unbind_count = 0
    Assert-Rejected { Assert-LyraHUDShutdownReport $report } "lost prior evidence"
}
Test-Case "old schema cannot claim final acceptance" {
    $report = New-ShutdownReport; $report.schema_version = 4
    Assert-Rejected { Assert-LyraHUDShutdownReport $report } "final Python-exit"
}
Test-Case "ordered shutdown log passes" {
    Assert-LyraHUDShutdownLog "UEP_LYRA_AWAITING_SHUTDOWN`nGoodbye Python`nUEP_LYRA_HUD_SHUTDOWN_PASSED`nLog file closed"
}
Test-Case "missing final shutdown log marker fails" {
    Assert-Rejected { Assert-LyraHUDShutdownLog "UEP_LYRA_AWAITING_SHUTDOWN`nGoodbye Python`nLog file closed" } "ordered exit evidence"
}
Test-Case "pre-quit pass marker cannot prove shutdown" {
    Assert-Rejected { Assert-LyraHUDShutdownLog "UEP_LYRA_HUD_SHUTDOWN_PASSED`nUEP_LYRA_AWAITING_SHUTDOWN`nGoodbye Python`nLog file closed" } "ordered exit evidence"
}
Test-Case "shutdown log failure cannot be hidden by pass marker" {
    Assert-Rejected { Assert-LyraHUDShutdownLog "UEP_LYRA_AWAITING_SHUTDOWN`nGoodbye Python`nUEP_LYRA_HUD_SHUTDOWN_FAILED`nUEP_LYRA_HUD_SHUTDOWN_PASSED`nLog file closed" } "records failure"
}
Test-Case "valid synthetic audit passes" { Assert-LyraHUDAuditData (New-Audit) }
Test-Case "missing Interface fails audit" {
    $audit = New-Audit; $audit.widget_blueprints[0].mixin.implemented_interfaces = @()
    Assert-Rejected { Assert-LyraHUDAuditData $audit } "Mixin declaration"
}
Test-Case "invalid selector fails audit" {
    $audit = New-Audit; $audit.widget_blueprints[0].mixin.selected_profile = "invalid"
    Assert-Rejected { Assert-LyraHUDAuditData $audit } "Mixin declaration"
}
Test-Case "wrong Python profile fails audit" {
    $audit = New-Audit; $audit.widget_blueprints[0].mixin.profiles[0].python_class = "Wrong"
    Assert-Rejected { Assert-LyraHUDAuditData $audit } "Mixin profile"
}
Test-Case "wrong Add Widgets shape fails audit" {
    $audit = New-Audit; $audit.data_assets[0].actions[0].widget_entry_count = 10
    Assert-Rejected { Assert-LyraHUDAuditData $audit } "Add Widgets"
}
Test-Case "All and standalone audit routing" {
    if (!(Test-LyraHUDAuditRequired "All" $true) -or
        !(Test-LyraHUDAuditRequired "HUDAudit" $false) -or
        (Test-LyraHUDAuditRequired "Standalone" $true) -or
        (Test-LyraHUDAuditRequired "All" $false)) { throw "Audit routing is inconsistent" }
}
Test-Case "All rejects absent audit" {
    Assert-Rejected { Get-LyraFullAcceptanceFlag "All" $true $true $null } "passed HUD audit"
}
Test-Case "All rejects failed audit" {
    Assert-Rejected { Get-LyraFullAcceptanceFlag "All" $true $true ([pscustomobject]@{status="failed"}) } "passed HUD audit"
}
function New-MultiClientNetwork {
    $processes = [pscustomobject]@{}
    foreach ($peer in @('server', 'A', 'B0', 'B1')) {
        $processes | Add-Member -NotePropertyName $peer -NotePropertyValue ([pscustomobject]@{exit_code=0;pid=100;duration_seconds=10})
    }
    return [pscustomobject]@{status='passed';schema_version=1;multi_client_acceptance=$true;required_client_count=2
        scope='loopback-dedicated-two-clients';processes=$processes
        protocol_validation=[pscustomobject]@{status='passed';required_client_count=2;process_instances=4;scenario_ids=@(1..16 | ForEach-Object {'N{0:00}' -f $_})}}
}
Test-Case "All with every required gate can set its flag" {
    $passed = [pscustomobject]@{status="passed"}
    if (!(Get-LyraFullAcceptanceFlag "All" $true $true $passed $passed $passed (New-MultiClientNetwork))) { throw "Expected full flag" }
}
Test-Case "All rejects missing multi-client evidence" {
    $passed = [pscustomobject]@{status='passed'}
    Assert-Rejected { Get-LyraFullAcceptanceFlag 'All' $true $true $passed $passed $passed } 'passed two-client'
}
Test-Case "one client cannot satisfy the network gate" {
    $network = New-MultiClientNetwork; $network.required_client_count=1
    Assert-Rejected { Assert-LyraMultiClientNetworkData $network } 'passed two-client'
}
Test-Case "missing rejoin process cannot satisfy the network gate" {
    $network = New-MultiClientNetwork; $network.processes.PSObject.Properties.Remove('B1')
    Assert-Rejected { Assert-LyraMultiClientNetworkData $network } 'process exits'
}
Test-Case "missing network phase cannot satisfy the gate" {
    $network = New-MultiClientNetwork; $network.protocol_validation.scenario_ids=@('N01')
    Assert-Rejected { Assert-LyraMultiClientNetworkData $network } 'scenario coverage'
}
Test-Case "forced network exit cannot satisfy the gate" {
    $network = New-MultiClientNetwork; $network.processes.A.exit_code=1
    Assert-Rejected { Assert-LyraMultiClientNetworkData $network } 'Unclean two-client'
}
Test-Case "All rejects missing rendered checks" {
    $passed = [pscustomobject]@{status="passed"}
    Assert-Rejected { Get-LyraFullAcceptanceFlag "All" $true $true $passed $passed $null } "passed callsite and rendered"
}
Test-Case "All rejects missing cross-Actor checks" {
    $passed = [pscustomobject]@{status="passed"}
    Assert-Rejected { Get-LyraFullAcceptanceFlag "All" $true $true $passed $null $passed } "passed callsite and rendered"
}
Test-Case "skip and narrow lanes cannot claim full acceptance" {
    if ((Get-LyraFullAcceptanceFlag "All" $true $false $null) -or
        (Get-LyraFullAcceptanceFlag "All" $false $true $null) -or
        (Get-LyraFullAcceptanceFlag "Network" $true $true $null)) { throw "Diagnostic lane claimed full acceptance" }
}

function New-Callsite {
    $counts = [ordered]@{original=@(1,0,1,1,0,1); mixed=@(1,1,2,2,0,1); mixed_again=@(1,2,2,3,0,1); profiles_swapped=@(2,2,1,3,1,2); restored=@(3,2,1,4,1,1)}
    $phases = foreach ($name in $counts.Keys) {
        $values = $counts[$name]
        [pscustomobject]@{name=$name; targets=@(
            [pscustomobject]@{actor='first'; class='Fixture_C'; blueprint_calls=$values[0]; python_calls=$values[1]; last_route=$values[2]},
            [pscustomobject]@{actor='second'; class='Fixture_C'; blueprint_calls=$values[3]; python_calls=$values[4]; last_route=$values[5]}
        )}
    }
    return [pscustomobject]@{schema_version=1; status='passed'; assets_saved=$false; evidence=[pscustomobject]@{caller_compiled_before_registration=$true; zero_parameter_native_fallback=$true; same_class=$true; restoration_passed=$true; phases=@($phases)}}
}

function New-Visual {
    $names = @('initial','damage_interpolating','damage_settled','heal_interpolating','heal_settled','death_interpolating','death_settled','respawn')
    $targets = @(100,60,60,100,100,0,0,100)
    $displayed = @(100,93,60,67,100,83,0,100)
    $frames = for ($index=0; $index -lt 8; $index++) {
        [pscustomobject]@{name=$names[$index]; current=$displayed[$index]; target=$targets[$index]; normalized=$targets[$index]/100.0; pending_elimination=$false;
            animations=@([pscustomobject]@{animation=$(if ($index -eq 6) {'OnEliminated'} else {'OnSpawned'})})}
    }
    $final = (New-ShutdownReport).shutdown.hud
    $final.construct_count=1; $final.destruct_count=1
    return [pscustomobject]@{schema_version=1; status='passed'; frames=@($frames); shutdown=$final}
}

Test-Case "synthetic cross-Actor evidence passes" {
    Assert-UEPMixinCallsiteData (New-Callsite)
    $missing = New-Callsite; $missing.evidence.zero_parameter_native_fallback=$false
    Assert-Rejected { Assert-UEPMixinCallsiteData $missing } 'Missing precompiled'
}
Test-Case "Python cannot fall through to BP" {
    $report=New-Callsite; $report.evidence.phases[1].targets[0].blueprint_calls++
    Assert-Rejected { Assert-UEPMixinCallsiteData $report } 'dispatch counters'
}
Test-Case "missing restoration fails" {
    $report=New-Callsite; $report.evidence.phases=@($report.evidence.phases | Select-Object -First 4)
    Assert-Rejected { Assert-UEPMixinCallsiteData $report } 'phases'
}
Test-Case "replaced actor type cannot count as mixin" {
    $report=New-Callsite; $report.evidence.phases[1].targets[0].class='PythonSubclass_C'
    Assert-Rejected { Assert-UEPMixinCallsiteData $report } 'instance or class'
}
Test-Case "synthetic rendered evidence passes" {
    Assert-LyraHUDVisualData (New-Visual)
    $switched = New-Visual
    $switched | Add-Member -NotePropertyName switch_during_animation -NotePropertyValue $true
    $switched.shutdown.destruct_count=0
    Assert-LyraHUDVisualData $switched
    Assert-UEPFocusedLog "Goodbye Python`nUEP_LYRA_HUD_VISUAL_PASSED`nLog file closed" 'UEP_LYRA_HUD_VISUAL_PASSED' -RequirePythonExit
}
Test-Case "rendered intermediate cannot snap to target" {
    $report=New-Visual; $report.frames[1].current=60
    Assert-Rejected { Assert-LyraHUDVisualData $report } 'interpolate'
}
Test-Case "rendered pending shutdown fails" {
    $report=New-Visual; $report.status='awaiting_shutdown'
    Assert-Rejected { Assert-LyraHUDVisualData $report } 'frames'
    Assert-Rejected { Assert-UEPFocusedLog "UEP_LYRA_HUD_VISUAL_PASSED`nLog file closed" 'UEP_LYRA_HUD_VISUAL_PASSED' -RequirePythonExit } 'ordered completion'
}
Test-Case "rendered missing frame fails" {
    $report=New-Visual; $report.frames=@($report.frames | Select-Object -First 7)
    Assert-Rejected { Assert-LyraHUDVisualData $report } 'frames'
}
Test-Case "rendered unfinished death fails" {
    $report=New-Visual; $report.frames[6].pending_elimination=$true
    Assert-Rejected { Assert-LyraHUDVisualData $report } 'death/respawn'
}
Test-Case "rendered residual reference fails" {
    $report=New-Visual; $report.shutdown.live_widget_reference_count=1
    Assert-Rejected { Assert-LyraHUDVisualData $report } 'retained owned state'
    Assert-Rejected { Assert-UEPFocusedLog "LogPython: Error: unrelated failure`nGoodbye Python`nUEP_LYRA_HUD_VISUAL_PASSED`nLog file closed" 'UEP_LYRA_HUD_VISUAL_PASSED' -RequirePythonExit } 'unexpected error'
}

[pscustomobject]@{status="passed"; test_count=$cases.Count; tests=@($cases)} | ConvertTo-Json -Depth 3
