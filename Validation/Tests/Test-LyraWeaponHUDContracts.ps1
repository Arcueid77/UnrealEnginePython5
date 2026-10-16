Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'LyraWeaponHUDContracts.ps1')
$tests=[Collections.Generic.List[string]]::new()

function Test-Case {
    param([string]$Name,[scriptblock]$Body)
    & $Body
    $tests.Add($Name)
}
function Assert-Rejected {
    param([scriptblock]$Body,[string]$Pattern)
    try { & $Body } catch { if ($_.ToString() -notmatch $Pattern) { throw }; return }
    throw "Contract accepted invalid evidence: $Pattern"
}

function New-WeaponReport {
    $names=@('W_WeaponAmmoAndName','W_AmmoCounter_Pistol','W_AmmoCounter_Rifle','W_AmmoCounter_Shotgun')
    $declarations=foreach ($name in $names) {
        [pscustomobject]@{asset=$name; mixin_set="/Game/UEPMixins/DA_${name}Mixin.DA_${name}Mixin"
            default_profile='Python'; runtime_class=($name + '_C')}
    }
    $cases=foreach ($name in $names) {
        $scenarios=@('initialized','ammo-5','ammo-4','ammo-3','ammo-2','ammo-1','ammo-0','ammo-30','weapon-switch')
        if ($name -eq $names[0]) { $scenarios+=@('empty-slot','slot-restored','reload-input-dispatch') } else { $scenarios+='brush-helper' }
        foreach ($scenario in $scenarios) {
            if ($scenario -eq 'brush-helper') {
                [pscustomobject]@{asset=$name; scenario=$scenario; resource_matches_argument=$true; counter_style_preserved=$true}
                continue
            }
            if ($scenario -eq 'reload-input-dispatch') {
                [pscustomobject]@{asset=$name; scenario=$scenario; native_input_intent_only=$true; python_calls=[pscustomobject]@{Tick=1; ReloadClicked=1}}
                continue
            }
            $current=if ($scenario -like 'ammo-*') { [int]$scenario.Substring(5) } elseif ($scenario -in @('weapon-switch','empty-slot')) {8} else {30}
            if ($name -eq $names[0]) {
                $snapshot=[pscustomobject]@{magazine=[string]$current; spare=$(if ($scenario -in @('weapon-switch','empty-slot')) {'57'} else {'1,234'})
                    name='{Weapon Name}'; visibility=$(if ($scenario -eq 'empty-slot') {2} else {0})}
            } else {
                $maximum=if ($scenario -eq 'weapon-switch') {8} else {30}
                $threshold=@{W_AmmoCounter_Pistol=2; W_AmmoCounter_Rifle=4; W_AmmoCounter_Shotgun=1}[$name]
                $material=[pscustomobject]@{Rounds_Max=$maximum; Rounds_Current=$current; IsLowAmmo=[int]($current -le $threshold)}
                $snapshot=[pscustomobject]@{bar=$material; glow=$material}
            }
            [pscustomobject]@{asset=$name; scenario=$scenario; baseline=$snapshot; python=$snapshot; python_calls=[pscustomobject]@{Tick=1}}
        }
    }
    return [pscustomobject]@{schema_version=1; status='passed'; scope='isolated-real-UMG-BP-Python-differential'
        full_acceptance=$false; network_acceptance=$false; class_identity_preserved=$true; persisted_declarations_used=$true
        restored_classes=4; declarations=@($declarations); cases=@($cases); images=@('weapon.png')}
}

Test-Case 'valid isolated weapon evidence passes' { Assert-LyraWeaponHUDData (New-WeaponReport) }
Test-Case 'isolated fixture cannot claim network acceptance' {
    $report=New-WeaponReport; $report.network_acceptance=$true
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'acceptance claim'
}
Test-Case 'manual registration cannot replace persisted declarations' {
    $report=New-WeaponReport; $report.persisted_declarations_used=$false
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'Missing isolated'
}
Test-Case 'a replacement Python class is not a Mixin' {
    $report=New-WeaponReport; $report.declarations[0].runtime_class='PythonWeaponWidget_C'
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'selector mismatch'
}
Test-Case 'missing or duplicated scenarios fail' {
    $report=New-WeaponReport; $report.cases=@($report.cases | Select-Object -Skip 1)
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'scenarios'
    $report=New-WeaponReport; $report.cases+=@($report.cases[0])
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'scenarios'
}
Test-Case 'BP-only execution cannot pass the Python comparison' {
    $report=New-WeaponReport; $report.cases[0].python_calls.Tick=0
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'execute Python'
}
Test-Case 'two equally wrong material values still fail' {
    $report=New-WeaponReport
    $case=@($report.cases | Where-Object {$_.asset -eq 'W_AmmoCounter_Rifle' -and $_.scenario -eq 'ammo-4'})[0]
    $case.python.bar.IsLowAmmo=0
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'authored thresholds'
}
Test-Case 'wrong panel text cannot pass merely by matching BP/Python' {
    $report=New-WeaponReport; $report.cases[0].python.magazine='30,000'
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'authored native state'
}
Test-Case 'missing reload alias dispatch fails' {
    $report=New-WeaponReport
    $case=@($report.cases | Where-Object scenario -eq 'reload-input-dispatch')[0]
    $case.python_calls.ReloadClicked=0
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'reload input'
}
Test-Case 'cleanup and screenshot are required' {
    $report=New-WeaponReport; $report.restored_classes=3
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'Missing isolated'
    $report=New-WeaponReport; $report.images=@()
    Assert-Rejected {Assert-LyraWeaponHUDData $report} 'screenshot'
}

function New-LifecycleReport {
    return [pscustomobject]@{
        subscription_scope=[pscustomobject]@{status='passed';native_message_callbacks=1;cancel_verified=$true;payload_access=$false}
        profile_switches=@('W_WeaponAmmoAndName','W_AmmoCounter_Pistol','W_AmmoCounter_Rifle','W_AmmoCounter_Shotgun' | ForEach-Object {
            [pscustomobject]@{asset=$_;status='passed';without_reconstruct=$true;observer_count_restored=4}
        })
        reload_cycles=@(1..3 | ForEach-Object {
            [pscustomobject]@{status='passed';new_widget=$true;native_gc_collected=$true
                before=[pscustomobject]@{active_count=1}
                after=[pscustomobject]@{active_count=0;active_scopes=0;ticker_active=$false;subscribed=1;unsubscribed=1;scope_created=1;scope_closed=1;errors=@()}}
        })
    }
}
Test-Case 'controlled lifecycle evidence passes' { Assert-LyraWeaponLifecycleData (New-LifecycleReport) }
Test-Case 'live profile switch cannot leave observation stopped' {
    $report=New-LifecycleReport; $report.profile_switches[0].observer_count_restored=3
    Assert-Rejected {Assert-LyraWeaponLifecycleData $report} 'resume observation'
}
Test-Case 'native signal cancellation is mandatory' {
    $report=New-LifecycleReport; $report.subscription_scope.cancel_verified=$false
    Assert-Rejected {Assert-LyraWeaponLifecycleData $report} 'signal/cancel'
}
Test-Case 'housekeeper cleanup cannot replace native GC proof' {
    $report=New-LifecycleReport; $report.reload_cycles[0].native_gc_collected=$false
    Assert-Rejected {Assert-LyraWeaponLifecycleData $report} 'native GC'
}
Test-Case 'leaked message scopes and tickers fail' {
    $report=New-LifecycleReport; $report.reload_cycles[0].after.active_scopes=1
    Assert-Rejected {Assert-LyraWeaponLifecycleData $report} 'retained subscriptions'
    $report=New-LifecycleReport; $report.reload_cycles[0].after.ticker_active=$true
    Assert-Rejected {Assert-LyraWeaponLifecycleData $report} 'retained subscriptions'
}
Test-Case 'one reload cannot count as repeated lifecycle' {
    $report=New-LifecycleReport; $report.reload_cycles=@($report.reload_cycles[0])
    Assert-Rejected {Assert-LyraWeaponLifecycleData $report} 'Three controlled'
}
[pscustomobject]@{status='passed'; test_count=$tests.Count; tests=@($tests)} | ConvertTo-Json -Depth 3
