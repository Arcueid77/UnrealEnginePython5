# Validate a current family revision without rewriting historical asset proof.
function Get-UEPAbilityWidgetFamilyProvenance {
    param([string]$BaseDirectory,[string]$RevisionDirectory)
    $basePath=Join-Path $BaseDirectory 'summary.json'
    $base=Get-Content -LiteralPath $basePath -Raw|ConvertFrom-Json -Depth 80
    $revisionPath=Join-Path $RevisionDirectory 'summary.json'
    $revision=Get-Content -LiteralPath $revisionPath -Raw|ConvertFrom-Json -Depth 80
    $capabilityPath=Join-Path $RevisionDirectory 'assets.json'
    $capability=Get-Content -LiteralPath $capabilityPath -Raw|ConvertFrom-Json -Depth 90
    if($base.status -ne 'passed' -or $base.runtime_acceptance -or @($base.assets).Count -ne 4 -or
        $revision.status -ne 'passed' -or $revision.runtime_acceptance -or $revision.kind -ne 'emoteparent' -or
        @($revision.assets).Count -ne 4 -or $capability.status -ne 'passed' -or $capability.kind -ne 'emoteparent' -or
        !$capability.original_class_defaults_signature_graphs_preserved -or !$capability.original_full_cdo_preserved -or
        !$capability.single_parent_router -or !$capability.existing_ads_profiles_defaults_graphs_preserved){
        throw 'Accepted Jump base and current shared-parent family revision required'
    }
    $adsDirectory=$revision.previous_family_directory
    $adsPath=Join-Path $adsDirectory 'summary.json'
    $ads=Get-Content -LiteralPath $adsPath -Raw|ConvertFrom-Json -Depth 90
    $adsCapabilityPath=Join-Path $adsDirectory 'assets.json'
    $adsCapability=Get-Content -LiteralPath $adsCapabilityPath -Raw|ConvertFrom-Json -Depth 90
    if($ads.status -ne 'passed' -or $ads.runtime_acceptance -or $ads.kind -ne 'adsparent' -or @($ads.assets).Count -ne 3 -or
        $adsCapability.status -ne 'passed' -or !$adsCapability.single_parent_router -or
        !$adsCapability.original_class_defaults_signature_graphs_preserved){throw 'Intermediate ADS family capability missing'}
    $replaced=@()
    foreach($old in $base.assets){
        $intermediate=@($ads.assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        if(!$intermediate.Count){continue}
        if($intermediate.Count -ne 1){throw 'Duplicate intermediate family output'}
        $before=@($ads.previous_assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        if($before.Count -ne 1 -or (Get-FileHash -LiteralPath $before[0].stage_backup).Hash -ne $old.sha256 -or
            (Get-FileHash -LiteralPath $before[0].overlay_backup).Hash -ne $old.sha256){
            throw 'ADS revision did not consume the accepted original Jump family asset'
        }
        $replaced+=$old.stage
    }
    if($replaced.Count -ne 2){throw 'Expected exactly shared-parent BP and Set replacements'}
    foreach($old in $ads.assets){
        $next=@($revision.assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        $before=@($revision.previous_assets|Where-Object {$_.stage -eq $old.stage -and $_.overlay -eq $old.overlay})
        if($next.Count -ne 1 -or $before.Count -ne 1 -or
            (Get-FileHash -LiteralPath $before[0].stage_backup).Hash -ne $old.sha256 -or
            (Get-FileHash -LiteralPath $before[0].overlay_backup).Hash -ne $old.sha256){
            throw 'Emote revision did not consume the accepted ADS family asset'
        }
    }
    $assets=@($base.assets|Where-Object {$_.stage -notin $replaced})+@($revision.assets)
    foreach($asset in $assets){foreach($path in @($asset.stage,$asset.overlay)){
        if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Current shared-parent family asset differs'}
    }}
    return @{assets=$assets;evidence=@($basePath,$revisionPath,$capabilityPath,$adsPath,$adsCapabilityPath)}
}
