function Get-UIPreparationCurrentAssets {
    param([object[]]$Assets)
    if(!$UIExperienceMacroDirectory){return $Assets}
    $revisionRoot=[IO.Path]::GetFullPath($UIExperienceMacroDirectory)
    if(!$revisionRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Owned UI preparation revision required'}
    $revisionSummaryPath=Join-Path $revisionRoot 'summary.json';$revisionProofPath=Join-Path $revisionRoot 'assets.json';$revisionBaselinePath=Join-Path $revisionRoot 'baselines.json'
    $revision=Get-Content -LiteralPath $revisionSummaryPath -Raw|ConvertFrom-Json -Depth 90;$proof=Get-Content -LiteralPath $revisionProofPath -Raw|ConvertFrom-Json -Depth 90;$parents=Get-Content -LiteralPath $revisionBaselinePath -Raw|ConvertFrom-Json -Depth 90
    if($revision.status -ne 'passed' -or $proof.status -ne 'passed' -or $revision.kind -ne 'uipreparation' -or $proof.kind -ne 'uipreparation' -or @($revision.assets).Count -ne 3 -or !$proof.original_macro_library_unchanged -or !$proof.all_original_caller_signatures_cdos_visuals_nodes_and_guids_preserved -or !$proof.one_native_latent_load_per_consumer_shared_by_both_profiles -or !$proof.python_pure_class_cast_setter_then_original_continuation){throw 'Complete current UI preparation semantic/transport proof required'}
    foreach($family in @(@{name='selection';count=11},@{name='host';count=13},@{name='entry';count=9})){
        $row=$proof.consumers.($family.name);$parent=$parents.($family.name)
        if($row.added_transport_nodes -ne 10 -or $row.method_counts.Python -ne $family.count -or $row.method_counts.BlueprintFallback -ne $family.count -or !$row.all_incoming_original_exec_paths_share_one_native_load -or $row.before_sha256 -ne $parent.sha256){throw 'Complete UI preparation consumer revision required'}
        foreach($backup in @($parent.stage_backup,$parent.overlay_backup)){if((Get-FileHash -LiteralPath $backup).Hash -ne $parent.sha256){throw 'UI preparation parent backup changed'};Add-JumpInput $backup}
    }
    foreach($row in $revision.assets){foreach($path in @($row.stage,$row.overlay)){if((Get-FileHash -LiteralPath $path).Hash -ne $row.sha256){throw 'UI preparation current asset changed'};Add-JumpInput $path}}
    if((Get-FileHash -LiteralPath (Join-Path $stage 'Content/UI/Menu/Experiences/UIExperienceMacros.uasset')).Hash -ne $proof.original_macro_sha256){throw 'Original UI macro definition changed'}
    foreach($file in @($revisionSummaryPath,$revisionProofPath,$revisionBaselinePath,$PSCommandPath)){Add-JumpInput $file}
    foreach($old in $Assets){
        $current=@($revision.assets|Where-Object {$_.stage -eq $old.stage})
        if($current.Count -gt 1){throw 'Duplicate current UI preparation asset'}
        if($current.Count){$consumer=@($proof.consumers.PSObject.Properties|Where-Object {$_.Value.relative -eq $current[0].relative});if($consumer.Count -ne 1 -or $consumer[0].Value.before_sha256 -ne $old.sha256){throw 'UI preparation parent chain mismatch'};@{stage=$current[0].stage;overlay=$current[0].overlay;sha256=$current[0].sha256}}
        else{$old}
    }
}
