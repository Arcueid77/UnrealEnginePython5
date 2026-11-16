# Narrow weapon presenter evidence. This cannot set a release/network flag.
function Assert-LyraWeaponHUDData {
    param([Parameter(Mandatory=$true)][object]$Report)
    if ($Report.schema_version -ne 1 -or $Report.status -ne 'passed' -or
        $Report.scope -ne 'isolated-real-UMG-BP-Python-differential' -or
        $Report.full_acceptance -ne $false -or $Report.network_acceptance -ne $false -or
        $Report.class_identity_preserved -ne $true -or $Report.persisted_declarations_used -ne $true -or
        $Report.restored_classes -ne 4) { throw 'Missing isolated weapon HUD proof or invalid acceptance claim' }
    $names = @('W_WeaponAmmoAndName', 'W_AmmoCounter_Pistol', 'W_AmmoCounter_Rifle', 'W_AmmoCounter_Shotgun')
    $declarations = @($Report.declarations)
    if (($declarations.asset -join '|') -ne ($names -join '|')) { throw 'Incomplete persisted weapon declarations' }
    foreach ($declaration in $declarations) {
        $expectedSet = '/Game/UEPMixins/DA_' + $declaration.asset + 'Mixin.DA_' + $declaration.asset + 'Mixin'
        if ($declaration.mixin_set -ne $expectedSet -or $declaration.default_profile -ne 'Python' -or
            $declaration.runtime_class -ne ($declaration.asset + '_C')) { throw 'Weapon Interface/CDO selector mismatch' }
    }
    $expected = foreach ($name in $names) {
        foreach ($scenario in @('initialized','ammo-5','ammo-4','ammo-3','ammo-2','ammo-1','ammo-0','ammo-30','weapon-switch')) {
            "$name|$scenario"
        }
        if ($name -eq $names[0]) {
            foreach ($scenario in @('empty-slot','slot-restored','reload-input-dispatch')) { "$name|$scenario" }
        } else { "$name|brush-helper" }
    }
    $actual = @($Report.cases | ForEach-Object { $_.asset + '|' + $_.scenario })
    if (($actual -join ';') -ne ($expected -join ';')) { throw 'Missing, duplicated or reordered weapon scenarios' }
    foreach ($case in $Report.cases) {
        if ($case.scenario -eq 'brush-helper') {
            if ($case.resource_matches_argument -ne $true -or $case.counter_style_preserved -ne $true) {
                throw 'Weapon brush helper differs from BP'
            }
            continue
        }
        if ($case.python_calls.Tick -le 0) { throw 'Weapon scenario did not execute Python' }
        if ($case.scenario -eq 'reload-input-dispatch') {
            if ($case.native_input_intent_only -ne $true -or $case.python_calls.ReloadClicked -ne 1) {
                throw 'Native local reload input dispatch is absent'
            }
            continue
        }
        if (($case.baseline | ConvertTo-Json -Depth 8 -Compress) -ne
            ($case.python | ConvertTo-Json -Depth 8 -Compress)) { throw 'Weapon BP/Python differential failed' }
        $current = if ($case.scenario -like 'ammo-*') { [int]$case.scenario.Substring(5) }
                   elseif ($case.scenario -in @('weapon-switch','empty-slot')) { 8 } else { 30 }
        if ($case.asset -eq $names[0]) {
            $spare = if ($case.scenario -in @('weapon-switch','empty-slot')) { '57' } else { '1,234' }
            $visibility = if ($case.scenario -eq 'empty-slot') { 2 } else { 0 }
            if ($case.python.magazine -cne [string]$current -or $case.python.spare -cne $spare -or
                $case.python.visibility -ne $visibility -or $case.python.name -cne '{Weapon Name}') {
                throw 'Weapon panel differs from authored native state'
            }
        } else {
            $maximum = if ($case.scenario -eq 'weapon-switch') { 8 } else { 30 }
            $threshold = @{W_AmmoCounter_Pistol=2; W_AmmoCounter_Rifle=4; W_AmmoCounter_Shotgun=1}[$case.asset]
            foreach ($part in @('bar','glow')) {
                $value = $case.python.$part
                if (![double]::IsFinite([double]$value.Rounds_Max) -or
                    ![double]::IsFinite([double]$value.Rounds_Current) -or
                    ![double]::IsFinite([double]$value.IsLowAmmo) -or
                    $value.Rounds_Max -ne $maximum -or $value.Rounds_Current -ne $current -or
                    $value.IsLowAmmo -ne [int]($current -le $threshold)) { throw 'Weapon material state differs from authored thresholds' }
            }
        }
    }
    if (@($Report.images).Count -ne 1) { throw 'Missing weapon differential screenshot' }
}

function Assert-LyraWeaponLifecycleData {
    param([Parameter(Mandatory=$true)][object]$Report)
    if (!$Report.PSObject.Properties['subscription_scope'] -or $Report.subscription_scope.status -ne 'passed' -or
        $Report.subscription_scope.native_message_callbacks -ne 1 -or !$Report.subscription_scope.cancel_verified -or
        $Report.subscription_scope.payload_access -ne $false) { throw 'Native signal/cancel evidence is absent' }
    if (!$Report.PSObject.Properties['profile_switches'] -or @($Report.profile_switches).Count -ne 4 -or
        (($Report.profile_switches.asset -join '|') -ne 'W_WeaponAmmoAndName|W_AmmoCounter_Pistol|W_AmmoCounter_Rifle|W_AmmoCounter_Shotgun')) {
        throw 'Live weapon profile switching evidence is absent'
    }
    foreach ($switch in $Report.profile_switches) {
        if ($switch.status -ne 'passed' -or !$switch.without_reconstruct -or $switch.observer_count_restored -ne 4) {
            throw 'Live weapon profile switch did not resume observation'
        }
    }
    if (!$Report.PSObject.Properties['reload_cycles'] -or @($Report.reload_cycles).Count -ne 3) { throw 'Three controlled reload cycles are required' }
    foreach($cycle in $Report.reload_cycles) {
        if ($cycle.status -ne 'passed' -or !$cycle.new_widget -or !$cycle.native_gc_collected -or
            $cycle.before.active_count -ne 1 -or $cycle.after.active_count -ne 0 -or $cycle.after.active_scopes -ne 0 -or
            $cycle.after.ticker_active -or $cycle.after.subscribed -ne $cycle.after.unsubscribed -or
            $cycle.after.scope_created -ne $cycle.after.scope_closed -or @($cycle.after.errors).Count -ne 0) {
            throw 'Controlled reload retained subscriptions or lacks native GC proof'
        }
    }
}
