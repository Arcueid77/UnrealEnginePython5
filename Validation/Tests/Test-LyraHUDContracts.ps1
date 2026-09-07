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
Test-Case "All with a checked audit can set its flag" {
    if (!(Get-LyraFullAcceptanceFlag "All" $true $true ([pscustomobject]@{status="passed"}))) { throw "Expected full flag" }
}
Test-Case "skip and narrow lanes cannot claim full acceptance" {
    if ((Get-LyraFullAcceptanceFlag "All" $true $false $null) -or
        (Get-LyraFullAcceptanceFlag "All" $false $true $null) -or
        (Get-LyraFullAcceptanceFlag "Network" $true $true $null)) { throw "Diagnostic lane claimed full acceptance" }
}

[pscustomobject]@{status="passed"; test_count=$cases.Count; tests=@($cases)} | ConvertTo-Json -Depth 3
