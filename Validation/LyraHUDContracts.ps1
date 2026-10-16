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
        [object]$HUDAudit,
        [object]$MixinCallsite,
        [object]$HUDVisual,
        [object]$MultiClientNetwork
    )
    if ($Mode -ne "All" -or !$GameplaySliceEnabled -or !$HUDSliceEnabled) {
        return $false
    }
    if ($null -eq $HUDAudit -or $HUDAudit.status -ne "passed") {
        throw "Full Lyra acceptance requires a passed HUD audit in this invocation"
    }
    if ($null -eq $MixinCallsite -or $MixinCallsite.status -ne "passed" -or
        $null -eq $HUDVisual -or $HUDVisual.status -ne "passed") {
        throw "Full Lyra acceptance requires passed callsite and rendered HUD checks in this invocation"
    }
    Assert-LyraMultiClientNetworkData $MultiClientNetwork
    return $true
}

function Assert-LyraMultiClientNetworkData {
    param([object]$Report)
    if ($null -eq $Report -or $Report.status -ne 'passed' -or
        $Report.schema_version -ne 1 -or $Report.multi_client_acceptance -ne $true -or
        $Report.required_client_count -ne 2 -or $Report.scope -ne 'loopback-dedicated-two-clients') {
        throw 'Full Lyra acceptance requires passed two-client network evidence in this invocation'
    }
    $protocol = $Report.protocol_validation
    if ($null -eq $protocol -or $protocol.status -ne 'passed' -or
        $protocol.required_client_count -ne 2 -or $protocol.process_instances -ne 4 -or
        (@($protocol.scenario_ids) -join '|') -ne ((1..16 | ForEach-Object {'N{0:00}' -f $_}) -join '|')) {
        throw 'Incomplete two-client network scenario coverage'
    }
    if ($null -eq $Report.processes -or
        (@($Report.processes.PSObject.Properties.Name | Sort-Object) -join '|') -ne 'A|B0|B1|server') {
        throw 'Missing two-client network process exits'
    }
    foreach ($peer in @('server', 'A', 'B0', 'B1')) {
        $processResult = $Report.processes.$peer
        if ($processResult.exit_code -ne 0 -or $processResult.pid -le 0 -or $processResult.duration_seconds -le 0) {
            throw "Unclean two-client network process exit: $peer"
        }
    }
}

function Assert-UEPMixinCallsiteData {
    param([Parameter(Mandatory = $true)][object]$Report)
    if ($Report.schema_version -ne 1 -or $Report.status -ne "passed" -or $Report.assets_saved -ne $false -or
        $Report.evidence.caller_compiled_before_registration -ne $true -or
        $Report.evidence.zero_parameter_native_fallback -ne $true -or
        $Report.evidence.same_class -ne $true -or $Report.evidence.restoration_passed -ne $true) {
        throw "Missing precompiled cross-Actor Mixin evidence"
    }
    $expected = [ordered]@{
        original = '1,0,1|1,0,1'; mixed = '1,1,2|2,0,1'; mixed_again = '1,2,2|3,0,1'
        profiles_swapped = '2,2,1|3,1,2'; restored = '3,2,1|4,1,1'
    }
    $phases = @($Report.evidence.phases)
    if (($phases.name -join '|') -ne ($expected.Keys -join '|')) { throw "Callsite phases are incomplete or reordered" }
    $firstTargets = @($phases[0].targets)
    if ($firstTargets.Count -ne 2 -or $firstTargets[0].actor -eq $firstTargets[1].actor -or
        $firstTargets[0].class -ne $firstTargets[1].class) { throw "Callsite requires two same-class instances" }
    foreach ($phase in $phases) {
        $targets = @($phase.targets)
        if ($targets.Count -ne 2) { throw "Callsite target count mismatch" }
        $counts = @()
        for ($index = 0; $index -lt 2; $index++) {
            $target = $targets[$index]
            if ($target.actor -ne $firstTargets[$index].actor -or $target.class -ne $firstTargets[0].class) {
                throw "Callsite changed target instance or class"
            }
            $counts += (@('blueprint_calls', 'python_calls', 'last_route') | ForEach-Object { Get-LyraHUDCounter $target $_ }) -join ','
        }
        if (($counts -join '|') -ne $expected[$phase.name]) { throw "Callsite dispatch counters failed: $($phase.name)" }
    }
}

function Assert-LyraHUDVisualData {
    param([Parameter(Mandatory = $true)][object]$Report)
    $names = @('initial', 'damage_interpolating', 'damage_settled', 'heal_interpolating', 'heal_settled', 'death_interpolating', 'death_settled', 'respawn')
    $targets = @(100, 60, 60, 100, 100, 0, 0, 100)
    if ($Report.schema_version -ne 1 -or $Report.status -ne 'passed' -or
        (@($Report.frames).name -join '|') -ne ($names -join '|')) { throw 'Missing rendered HUD frames' }
    for ($index = 0; $index -lt $names.Count; $index++) {
        $frame = $Report.frames[$index]
        if (![double]::IsFinite([double]$frame.current) -or ![double]::IsFinite([double]$frame.normalized) -or
            [double]$frame.target -ne $targets[$index] -or
            [math]::Abs([double]$frame.normalized - $targets[$index] / 100.0) -gt 0.0001) {
            throw 'Rendered HUD value mismatch'
        }
        if ($names[$index] -like '*_interpolating') {
            $previous = $targets[$index - 1]
            if ($frame.current -le [math]::Min($previous, $targets[$index]) -or
                $frame.current -ge [math]::Max($previous, $targets[$index])) { throw 'Rendered number did not interpolate' }
        }
        elseif ($frame.current -ne $targets[$index]) { throw 'Rendered number did not settle' }
    }
    if ($Report.frames[6].pending_elimination -ne $false -or
        $Report.frames[6].animations[-1].animation -ne 'OnEliminated' -or
        $Report.frames[7].animations[-1].animation -ne 'OnSpawned') { throw 'Rendered death/respawn animation chain failed' }
    $final = $Report.shutdown
    $switched = $Report.PSObject.Properties['switch_during_animation'] -and $Report.switch_during_animation
    $expectedDestructs = if ($switched) { 0 } else { 1 }
    if (@($final.errors).Count -ne 0 -or
        (Get-LyraHUDCounter $final 'active_widget_count') -ne 0 -or
        (Get-LyraHUDCounter $final 'live_widget_reference_count') -ne 0 -or
        (Get-LyraHUDCounter $final 'construct_count') -ne 1 -or
        (Get-LyraHUDCounter $final 'destruct_count') -ne $expectedDestructs -or
        (Get-LyraHUDCounter $final 'teardown_count') -lt 1 -or
        (Get-LyraHUDCounter $final 'controller_bind_count') -ne (Get-LyraHUDCounter $final 'controller_unbind_count') -or
        (Get-LyraHUDCounter $final 'health_bind_count') -ne (Get-LyraHUDCounter $final 'health_unbind_count')) {
        throw 'Rendered HUD exit retained owned state'
    }
}

function Assert-UEPFocusedLog {
    param([string]$Content, [string]$PassedMarker, [switch]$RequirePythonExit)
    if ($Content -match '(?im)(Log\w+:\s*Error:|Fatal error:|Assertion failed|Unhandled Exception|Ensure condition failed)') {
        throw 'Focused Unreal log contains an unexpected error'
    }
    $prefix = if ($RequirePythonExit) { 'Goodbye Python.*' } else { '' }
    if ($Content -notmatch ('(?s)' + $prefix + [regex]::Escape($PassedMarker) + '.*Log file closed')) {
        throw 'Focused Unreal log lacks ordered completion evidence'
    }
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
