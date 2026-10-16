# Accepted component assets, optionally followed by a no-semantic-change
# reauthoring of the shared VM transport. Historical evidence is never edited.
function Get-UEPNameplateAssetProvenance {
    param([string]$AuthoringDirectory,[string]$TransportRevisionDirectory,[string]$Stage,[string]$Overlay)
    $authorPath=Join-Path $AuthoringDirectory 'summary.json'
    $author=Get-Content -LiteralPath $authorPath -Raw|ConvertFrom-Json -Depth 40
    if($author.status -ne 'passed' -or $author.runtime_acceptance -or @($author.assets).Count -ne 5){throw 'Accepted component authoring required'}
    $relativeTransport='Content\UEPInterop\BP_UEPGameplayMessages.uasset'
    $assets=@($author.assets)
    $evidence=@($authorPath)
    if($TransportRevisionDirectory){
        $revisionPath=Join-Path $TransportRevisionDirectory 'summary.json'
        $capabilityPath=Join-Path $TransportRevisionDirectory 'assets.json'
        $revision=Get-Content -LiteralPath $revisionPath -Raw|ConvertFrom-Json -Depth 40
        $capability=Get-Content -LiteralPath $capabilityPath -Raw|ConvertFrom-Json -Depth 40
        $transport=$capability.transport
        $expected=@{ReadUI=4;BroadcastUI=2;ReadVerb=4;BroadcastVerb=2;ReadDuration=4;BroadcastDuration=2
            ReadFailure=4;BroadcastFailure=2;CopyFailureText=3;SameFailureText=5;ReadQuickBarSlots=4;BroadcastQuickBarSlots=2
            ReadQuickBarActiveIndex=4;BroadcastQuickBarActiveIndex=2;InjectAxis1DForAction=3
            ReadNameplateInfo=4;BroadcastNameplateInfo=2;ReadNameplateRequest=4;BroadcastNameplateRequest=2}
        $functions=@($transport.functions)
        if($revision.status -ne 'passed' -or $revision.widget -ne 'QuickBarSlot' -or $revision.runtime_acceptance -or
           $capability.status -ne 'passed' -or !$transport.old_graphs_unchanged -or !$transport.preserves_all_existing_functions -or
           $transport.business_logic -or !$transport.wildcard_calls_use_compiled_vm -or $functions.Count -ne 19 -or
           @($functions.name|Sort-Object -Unique).Count -ne 19 -or
           @($functions|Where-Object {!$expected.ContainsKey($_.name) -or $_.nodes -ne $expected[$_.name]}).Count -or
           @($transport.old_graph_digests.PSObject.Properties).Count -ne 19){throw 'Transport revision capability chain incomplete'}
        foreach($name in $expected.Keys){
            if($transport.old_graph_digests.$name -notmatch '^[0-9a-f]{64}$'){throw 'Missing preserved graph digest'}
        }
        $stageTransport=Join-Path $Stage $relativeTransport
        $overlayTransport=Join-Path $Overlay $relativeTransport
        $previous=@($assets|Where-Object {$_.stage -eq $stageTransport -and $_.overlay -eq $overlayTransport})
        $next=@($revision.assets|Where-Object {$_.stage -eq $stageTransport -and $_.overlay -eq $overlayTransport})
        if($previous.Count -ne 1 -or $next.Count -ne 1 -or
           @($revision.hashes|Where-Object {$_.path -eq $overlayTransport -and $_.sha256 -eq $previous[0].sha256}).Count -ne 1){throw 'Transport revision did not consume accepted prior asset'}
        $assets=@($assets|Where-Object {$_.stage -ne $stageTransport})+@($next[0])
        $evidence+=@($revisionPath,$capabilityPath)
    }
    foreach($asset in $assets){foreach($path in @($asset.stage,$asset.overlay)){
        if((Get-FileHash -LiteralPath $path).Hash -ne $asset.sha256){throw 'Accepted nameplate asset/revision differs'}
    }}
    return @{assets=$assets;evidence=$evidence}
}
