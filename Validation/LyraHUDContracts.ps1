# Pure validation contracts. Dot-sourcing this file never stages or launches UE.

function Test-LyraHUDAuditRequired {
    param([string]$Mode, [bool]$HUDSliceEnabled)
    return $Mode -eq "HUDAudit" -or ($Mode -eq "All" -and $HUDSliceEnabled)
}

function Get-LyraFullAcceptanceFlag {
    param(
        [string]$Mode,
        [bool]$GameplaySliceEnabled,
        [bool]$HUDSliceEnabled,
        [object]$HUDAudit
    )
    if ($Mode -ne "All" -or !$GameplaySliceEnabled -or !$HUDSliceEnabled) {
        return $false
    }
    if ($null -eq $HUDAudit -or $HUDAudit.status -ne "passed") {
        throw "Full Lyra acceptance requires a passed HUD audit in this invocation"
    }
    return $true
}

function Get-LyraHUDCounter {
    param([Parameter(Mandatory = $true)][object]$HUD, [string]$Name)
    $property = $HUD.PSObject.Properties[$Name]
    if ($null -eq $property -or
        !($property.Value -is [int] -or $property.Value -is [long]) -or
        $property.Value -lt 0) {
        throw "Invalid or absent HUD counter: $Name"
    }
    return [long]$property.Value
}

function Assert-LyraHUDActiveState {
    param(
        [Parameter(Mandatory = $true)][object]$HUD,
        [Parameter(Mandatory = $true)][string]$ExpectedMode
    )
    $active = Get-LyraHUDCounter $HUD "active_widget_count"
    $references = Get-LyraHUDCounter $HUD "live_widget_reference_count"
    foreach ($counter in @(
        "construct_count", "destruct_count", "teardown_count",
        "controller_bind_count", "controller_unbind_count",
        "health_bind_count", "health_unbind_count"
    )) {
        $null = Get-LyraHUDCounter $HUD $counter
    }
    if (@($HUD.errors).Count -ne 0 -or @($HUD.active_widgets).Count -ne $active) {
        throw "HUD errors or active-widget ledger mismatch"
    }
    if ($ExpectedMode -in @("server", "server_exit")) {
        if ($active -ne 0 -or $references -ne 0 -or $HUD.construct_count -ne 0 -or
            $HUD.controller_bind_count -ne 0 -or $HUD.health_bind_count -ne 0 -or
            @($HUD.health_events).Count -ne 0) {
            throw "Dedicated-server HUD state must be empty"
        }
    }
    elseif ($active -ne 1 -or $references -ne 1) {
        throw "Exactly one local HUD presenter and widget reference are required"
    }
    if (($HUD.controller_bind_count - $HUD.controller_unbind_count) -ne $active -or
        ($HUD.health_bind_count - $HUD.health_unbind_count) -ne $active) {
        throw "Active HUD delegate balance is inconsistent"
    }
}

function Assert-LyraHUDShutdownReport {
    param([Parameter(Mandatory = $true)][object]$Report)
    if ($Report.schema_version -lt 5 -or $Report.status -ne "passed" -or
        !$Report.PSObject.Properties["shutdown"] -or
        $Report.shutdown.status -ne "passed" -or
        $Report.shutdown.phase -ne "python_atexit") {
        throw "HUD report lacks final Python-exit acceptance"
    }
    $finalHUD = $Report.shutdown.hud
    if (@($finalHUD.errors).Count -ne 0 -or
        (Get-LyraHUDCounter $finalHUD "active_widget_count") -ne 0 -or
        @($finalHUD.active_widgets).Count -ne 0 -or
        (Get-LyraHUDCounter $finalHUD "live_widget_reference_count") -ne 0) {
        throw "HUD shutdown retained a presenter/reference or recorded errors"
    }
    foreach ($counter in @(
        "construct_count", "destruct_count", "teardown_count",
        "controller_bind_count", "controller_unbind_count",
        "health_bind_count", "health_unbind_count"
    )) {
        if ((Get-LyraHUDCounter $finalHUD $counter) -lt
            (Get-LyraHUDCounter $Report.hud $counter)) {
            throw "HUD shutdown lost prior evidence: $counter"
        }
    }
    if ($finalHUD.controller_bind_count -ne $finalHUD.controller_unbind_count -or
        $finalHUD.health_bind_count -ne $finalHUD.health_unbind_count) {
        throw "HUD shutdown retained owned callbacks"
    }
}

function Assert-LyraHUDShutdownLog {
    param([Parameter(Mandatory = $true)][string]$LogContents)
    $previous = -1
    foreach ($marker in @(
        "UEP_LYRA_AWAITING_SHUTDOWN", "Goodbye Python",
        "UEP_LYRA_HUD_SHUTDOWN_PASSED", "Log file closed"
    )) {
        $index = $LogContents.IndexOf($marker, [System.StringComparison]::Ordinal)
        if ($index -lt 0 -or $index -le $previous) {
            throw "HUD shutdown log lacks ordered exit evidence: $marker"
        }
        $previous = $index
    }
    if ($LogContents.Contains("UEP_LYRA_HUD_SHUTDOWN_FAILED")) {
        throw "HUD shutdown log records failure"
    }
}

function Assert-LyraHUDAuditData {
    param(
        [Parameter(Mandatory = $true)][object]$Report,
        [string]$ResultPath = "<in-memory HUD audit>"
    )
    if ($report.schema_version -ne 1 -or
        $report.status -ne "passed" -or
        $report.engine_version[0] -ne 5 -or
        $report.engine_version[1] -ne 8) {
        throw "Lyra HUD audit failed its status/engine contract: $ResultPath"
    }

    $expectedBlueprints = @(
        @{ role = "healthbar"; path = "/Game/UI/Hud/W_Healthbar" },
        @{ role = "default_hud_layout"; path = "/Game/UI/Hud/W_DefaultHUDLayout" },
        @{ role = "shooter_hud_layout"; path = "/ShooterCore/UserInterface/W_ShooterHUDLayout" }
    )
    foreach ($expected in $expectedBlueprints) {
        $matches = @($report.widget_blueprints | Where-Object {
            $_.role -eq $expected.role -and $_.path -eq $expected.path
        })
        if ($matches.Count -ne 1 -or
            !([string]$matches[0].generated_class) -or
            @($matches[0].graphs).Count -le 0) {
            throw "Lyra HUD audit lacks '$($expected.role)' Blueprint evidence: $ResultPath"
        }
    }
    $healthbar = @($report.widget_blueprints | Where-Object role -eq "healthbar")[0]
    foreach ($propertyName in @(
        "HealthNumber",
        "NormalizedHealth",
        "HealthOldValue",
        "HealthNewValue",
        "BarFillMID",
        "PythonMixinProfile"
    )) {
        if (@($healthbar.reflected_properties) -notcontains $propertyName) {
            throw "Lyra HUD audit healthbar lacks property '$propertyName': $ResultPath"
        }
    }
    foreach ($functionName in @(
        "Construct",
        "InitializeBarVisuals",
        "SetDynamicMaterials",
        "GetPythonMixinSet",
        "GetPythonMixinProfile"
    )) {
        if (@($healthbar.reflected_functions) -notcontains $functionName) {
            throw "Lyra HUD audit healthbar lacks function '$functionName': $ResultPath"
        }
    }
    $mixin = $healthbar.mixin
    if (@($mixin.implemented_interfaces) -notcontains "UEPPythonMixinInterface" -or
        $mixin.mixin_set_path -ne "/Game/UEPMixins/DA_LyraHealthbarMixin.DA_LyraHealthbarMixin" -or
        $mixin.mixin_set_class -ne "UEPPythonMixinSet" -or
        $mixin.selected_profile -ne "Python" -or
        $mixin.default_profile -ne "Python") {
        throw "Lyra HUD audit healthbar Mixin declaration is inconsistent: $ResultPath"
    }
    $expectedMixinProfiles = @(
        @{
            profile_name = "Python"
            python_module = "uep_lyra_hud.healthbar_mixin"
            python_class = "LyraHealthbarPythonProfile"
        },
        @{
            profile_name = "BlueprintFallback"
            python_module = "uep_lyra_hud.healthbar_mixin"
            python_class = "LyraHealthbarBlueprintFallbackProfile"
        }
    )
    if (@($mixin.profiles).Count -ne $expectedMixinProfiles.Count) {
        throw "Lyra HUD audit healthbar Mixin profile count is inconsistent: $ResultPath"
    }
    foreach ($expectedProfile in $expectedMixinProfiles) {
        $profiles = @($mixin.profiles | Where-Object {
            $_.profile_name -eq $expectedProfile.profile_name -and
            $_.python_module -eq $expectedProfile.python_module -and
            $_.python_class -eq $expectedProfile.python_class
        })
        if ($profiles.Count -ne 1) {
            throw "Lyra HUD audit lacks Mixin profile '$($expectedProfile.profile_name)': $ResultPath"
        }
    }
    $actionSet = @($report.data_assets | Where-Object {
        $_.role -eq "shooter_hud_action_set" -and
        $_.path -eq "/ShooterCore/Experiences/LAS_ShooterGame_StandardHUD"
    })
    if ($actionSet.Count -ne 1 -or
        $actionSet[0].asset_class -ne "LyraExperienceActionSet" -or
        $actionSet[0].action_count -ne 1 -or
        @($actionSet[0].game_features_to_enable) -notcontains "ShooterCore") {
        throw "Lyra HUD audit lacks the Shooter HUD action-set evidence: $ResultPath"
    }
    $addWidgetsActions = @($actionSet[0].actions | Where-Object {
        $_.class -eq "GameFeatureAction_AddWidgets" -and
        $_.layout_entry_count -eq 1 -and
        $_.widget_entry_count -eq 11
    })
    if ($addWidgetsActions.Count -ne 1) {
        throw "Lyra HUD audit Shooter action set lacks the expected Add Widgets layout: $ResultPath"
    }
}
