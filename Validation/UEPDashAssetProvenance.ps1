# Preserve the accepted selector proof; verify the explicit two-asset RPC revision.
function Get-UEPDashRPCInputRevision {
    param([string]$BaseDirectory,[string]$RevisionDirectory,[switch]$Historical)
    $basePath=Join-Path $BaseDirectory 'summary.json';$baseReport=Join-Path $BaseDirectory 'assets.json'
    $revisionPath=Join-Path $RevisionDirectory 'summary.json';$revisionReport=Join-Path $RevisionDirectory 'assets.json'
    $base=Get-Content -LiteralPath $basePath -Raw|ConvertFrom-Json -Depth 90
    $original=Get-Content -LiteralPath $baseReport -Raw|ConvertFrom-Json -Depth 90
    $revision=Get-Content -LiteralPath $revisionPath -Raw|ConvertFrom-Json -Depth 90
    $proof=Get-Content -LiteralPath $revisionReport -Raw|ConvertFrom-Json -Depth 90
    if($base.status -ne 'passed' -or $base.kind -ne 'dashselector' -or @($base.assets).Count -ne 2 -or
        $revision.status -ne 'passed' -or $revision.kind -ne 'dashrpcinput' -or $revision.runtime_acceptance -or @($revision.assets).Count -ne 2 -or
        $proof.status -ne 'passed' -or $proof.kind -ne 'dashrpcinput' -or !$proof.original_full_cdo_preserved -or
        !$proof.native_server_rpc_flags_preserved -or !$proof.original_business_graphs_preserved_with_dispatch -or !$proof.native_register_restore_passed -or
        !$proof.python_replaces_two_remote_stores -or !$proof.native_commit_tasks_animation_movement_retained -or $proof.whole_dash_activation_migrated -or
        $proof.transport_nodes -ne 4 -or $proof.new_business_nodes -ne 0 -or $proof.actual_registered_profile_method_counts.Python -ne 2 -or
        $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 2 -or $proof.gate_signature.parameters.Count -ne 3){throw 'Accepted bounded Dash RPC input proof required'}
    if([IO.Path]::GetFullPath($revision.previous_dash_directory) -ne [IO.Path]::GetFullPath($BaseDirectory)){throw 'RPC revision does not consume this selector proof'}
    foreach($method in @('SelectDirectionalMontage','K2_ActivateAbility','SendInfo')){
        if(($proof.original_signatures.$method|ConvertTo-Json -Depth 30 -Compress) -ne ($original.extra_signatures.$method|ConvertTo-Json -Depth 30 -Compress)){
            throw 'RPC revision changed original signature/Net flags'
        }
    }
    foreach($old in $base.assets){
        $before=@($revision.previous_assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        $current=@($revision.assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        if($before.Count -ne 1 -or $current.Count -ne 1 -or (Get-FileHash -LiteralPath $before[0].stage_backup).Hash -ne $old.sha256 -or
            (Get-FileHash -LiteralPath $before[0].overlay_backup).Hash -ne $old.sha256){throw 'Dash selector-to-RPC asset provenance differs'}
        if(!$Historical -and ((Get-FileHash -LiteralPath $current[0].stage).Hash -ne $current[0].sha256 -or
            (Get-FileHash -LiteralPath $current[0].overlay).Hash -ne $current[0].sha256)){throw 'Current RPC asset bytes differ'}
    }
    return @{assets=@($revision.assets);evidence=@($basePath,$baseReport,$revisionPath,$revisionReport);proof=$proof}
}

function Get-UEPDashLocalDirectionRevision {
    param([string]$BaseDirectory,[string]$RPCDirectory,[string]$LocalDirectory,[switch]$Historical)
    $rpc=Get-UEPDashRPCInputRevision $BaseDirectory $RPCDirectory -Historical
    $rpcSummary=Get-Content -LiteralPath (Join-Path $RPCDirectory 'summary.json') -Raw|ConvertFrom-Json -Depth 90
    $path=Join-Path $LocalDirectory 'summary.json';$reportPath=Join-Path $LocalDirectory 'assets.json'
    $revision=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -Depth 90
    $proof=Get-Content -LiteralPath $reportPath -Raw|ConvertFrom-Json -Depth 90
    if($revision.status -ne 'passed' -or $revision.kind -ne 'dashlocaldirection' -or $revision.runtime_acceptance -or @($revision.assets).Count -ne 2 -or
        $proof.status -ne 'passed' -or $proof.kind -ne 'dashlocaldirection' -or !$proof.original_full_cdo_preserved -or
        !$proof.original_business_graphs_preserved_with_dispatch -or !$proof.native_server_rpc_flags_preserved -or !$proof.native_register_restore_passed -or
        !$proof.native_direction_property_read -or !$proof.unused_positive_output_retained -or $proof.local_direction_transport_nodes -ne 5 -or
        $proof.new_business_nodes -ne 0 -or $proof.whole_dash_activation_migrated -or $proof.actual_registered_profile_method_counts.Python -ne 3 -or
        $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 3 -or $proof.gate_signature.parameters.Count -ne 1 -or
        [IO.Path]::GetFullPath($revision.previous_dash_directory) -ne [IO.Path]::GetFullPath($RPCDirectory)){throw 'Accepted local direction revision required'}
    foreach($method in @('SelectDirectionalMontage','K2_ActivateAbility','SendInfo')){
        if(($proof.original_signatures.$method|ConvertTo-Json -Depth 30 -Compress) -ne ($rpc.proof.original_signatures.$method|ConvertTo-Json -Depth 30 -Compress)){throw 'Local direction changed original signatures/Net flags'}
    }
    if(($proof.original_signatures.UEPDashStoreRemoteInput|ConvertTo-Json -Depth 30 -Compress) -ne ($rpc.proof.gate_signature|ConvertTo-Json -Depth 30 -Compress)){throw 'Local direction changed accepted RPC gateway'}
    foreach($old in $rpcSummary.assets){
        $before=@($revision.previous_assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        $current=@($revision.assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        if($before.Count -ne 1 -or $current.Count -ne 1 -or (Get-FileHash -LiteralPath $before[0].stage_backup).Hash -ne $old.sha256 -or
            (Get-FileHash -LiteralPath $before[0].overlay_backup).Hash -ne $old.sha256){throw 'RPC-to-local provenance differs'}
        if(!$Historical -and ((Get-FileHash -LiteralPath $current[0].stage).Hash -ne $current[0].sha256 -or
            (Get-FileHash -LiteralPath $current[0].overlay).Hash -ne $current[0].sha256)){throw 'Current local direction asset bytes differ'}
    }
    return @{assets=@($revision.assets);evidence=@($rpc.evidence)+@($path,$reportPath);proof=$proof}
}

function Get-UEPDashActivationRevision {
    param([string]$BaseDirectory,[string]$RPCDirectory,[string]$LocalDirectory,[string]$ActivationDirectory,[switch]$Historical)
    $local=Get-UEPDashLocalDirectionRevision $BaseDirectory $RPCDirectory $LocalDirectory -Historical
    $path=Join-Path $ActivationDirectory 'summary.json';$reportPath=Join-Path $ActivationDirectory 'assets.json'
    $revision=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -Depth 90
    $proof=Get-Content -LiteralPath $reportPath -Raw|ConvertFrom-Json -Depth 90
    if($revision.status -ne 'passed' -or $revision.kind -ne 'dashactivation' -or $revision.runtime_acceptance -or @($revision.assets).Count -ne 2 -or
        $proof.status -ne 'passed' -or $proof.kind -ne 'dashactivation' -or !$proof.original_full_cdo_preserved -or
        !$proof.original_business_graphs_preserved_with_dispatch -or !$proof.native_server_rpc_flags_preserved -or !$proof.native_register_restore_passed -or
        !$proof.actual_activation_event_overridden -or $proof.native_task_entry_nodes -ne 1 -or $proof.new_business_nodes -ne 0 -or
        $proof.whole_dash_activation_migrated -or $proof.native_task_entry -ne 'UEPDashStartNativeTasks' -or
        @($proof.task_entry_signature.parameters).Count -ne 0 -or ($proof.task_entry_signature.flags -band 0x40) -or
        $proof.actual_registered_profile_method_counts.Python -ne 4 -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 4 -or
        [IO.Path]::GetFullPath($revision.previous_dash_directory) -ne [IO.Path]::GetFullPath($LocalDirectory)){throw 'Accepted actual activation revision required'}
    foreach($method in @('SelectDirectionalMontage','K2_ActivateAbility','SendInfo','UEPDashStoreRemoteInput')){
        if(($proof.original_signatures.$method|ConvertTo-Json -Depth 30 -Compress) -ne ($local.proof.original_signatures.$method|ConvertTo-Json -Depth 30 -Compress)){
            throw 'Activation revision changed original signature/Net flags'
        }
    }
    if(($proof.original_signatures.UEPDashPrepareLocalDirection|ConvertTo-Json -Depth 30 -Compress) -ne ($local.proof.gate_signature|ConvertTo-Json -Depth 30 -Compress)){
        throw 'Activation revision changed accepted local preparation gateway'
    }
    foreach($old in $local.assets){
        $before=@($revision.previous_assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        $current=@($revision.assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        if($before.Count -ne 1 -or $current.Count -ne 1 -or (Get-FileHash -LiteralPath $before[0].stage_backup).Hash -ne $old.sha256 -or
            (Get-FileHash -LiteralPath $before[0].overlay_backup).Hash -ne $old.sha256){throw 'Local-to-activation provenance differs'}
        if(!$Historical -and ((Get-FileHash -LiteralPath $current[0].stage).Hash -ne $current[0].sha256 -or
            (Get-FileHash -LiteralPath $current[0].overlay).Hash -ne $current[0].sha256)){throw 'Current activation asset bytes differ'}
    }
    return @{assets=@($revision.assets);evidence=@($local.evidence)+@($path,$reportPath);proof=$proof}
}

function Get-UEPDashTasksRevision {
    param([string]$BaseDirectory,[string]$RPCDirectory,[string]$LocalDirectory,[string]$ActivationDirectory,[string]$TasksDirectory)
    $activation=Get-UEPDashActivationRevision $BaseDirectory $RPCDirectory $LocalDirectory $ActivationDirectory -Historical
    $path=Join-Path $TasksDirectory 'summary.json';$reportPath=Join-Path $TasksDirectory 'assets.json'
    $revision=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json -Depth 90
    $proof=Get-Content -LiteralPath $reportPath -Raw|ConvertFrom-Json -Depth 90
    if($revision.status -ne 'passed' -or $revision.kind -ne 'dashtasks' -or $revision.runtime_acceptance -or @($revision.assets).Count -ne 2 -or
        $proof.status -ne 'passed' -or $proof.kind -ne 'dashtasks' -or !$proof.original_full_cdo_preserved -or
        !$proof.original_business_graphs_preserved_with_dispatch -or !$proof.native_server_rpc_flags_preserved -or !$proof.native_register_restore_passed -or
        !$proof.original_native_delay_reused -or !$proof.transport_default_zero -or !$proof.python_rpc_body_has_no_original_fallthrough -or
        $proof.task_transport_nodes -ne 15 -or !$proof.native_end_teardown_bypass -or $proof.native_end_guard -ne 'UEPDashTearingDown' -or
        $proof.native_end_gate -ne 'UEPDashNativeEnded' -or @($proof.dispatch_transport_endpoints).Count -ne 12 -or $proof.new_business_nodes -ne 0 -or
        $proof.native_end_transport_signature.owner -ne $proof.original_class -or
        $proof.whole_dash_activation_migrated -or $proof.native_task_entry -ne 'UEPDashStartNativeTasks' -or $proof.native_delay_entry -ne 'UEPDashBeginNativeDelay' -or
        $proof.delay_transport_property -ne 'UEPDashDelayDuration' -or $proof.actual_registered_profile_method_counts.Python -ne 7 -or
        $proof.actual_registered_profile_method_counts.BlueprintFallback -ne 7 -or @($proof.after_delay_signature.parameters).Count -ne 1 -or
        @($proof.native_delay_signature.parameters).Count -ne 1 -or ($proof.native_delay_signature.flags -band 0x40) -or
        $proof.original_signatures.K2_OnEndAbility.owner -ne '/Script/GameplayAbilities.GameplayAbility' -or
        [IO.Path]::GetFullPath($revision.previous_dash_directory) -ne [IO.Path]::GetFullPath($ActivationDirectory)){throw 'Accepted task/Delay revision required'}
    foreach($method in @('SelectDirectionalMontage','K2_ActivateAbility','SendInfo','UEPDashStoreRemoteInput','UEPDashPrepareLocalDirection')){
        if(($proof.original_signatures.$method|ConvertTo-Json -Depth 30 -Compress) -ne ($activation.proof.original_signatures.$method|ConvertTo-Json -Depth 30 -Compress)){
            throw 'Task revision changed accepted original signature/Net flags'
        }
    }
    if(($proof.original_signatures.UEPDashStartNativeTasks|ConvertTo-Json -Depth 30 -Compress) -ne ($activation.proof.task_entry_signature|ConvertTo-Json -Depth 30 -Compress)){
        throw 'Task revision changed accepted native task entry signature'
    }
    foreach($old in $activation.assets){
        $before=@($revision.previous_assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        $current=@($revision.assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        if($before.Count -ne 1 -or $current.Count -ne 1 -or (Get-FileHash -LiteralPath $before[0].stage_backup).Hash -ne $old.sha256 -or
            (Get-FileHash -LiteralPath $before[0].overlay_backup).Hash -ne $old.sha256 -or (Get-FileHash -LiteralPath $current[0].stage).Hash -ne $current[0].sha256 -or
            (Get-FileHash -LiteralPath $current[0].overlay).Hash -ne $current[0].sha256){throw 'Activation-to-tasks provenance/current bytes differ'}
    }
    return @{assets=@($revision.assets);evidence=@($activation.evidence)+@($path,$reportPath);proof=$proof}
}
