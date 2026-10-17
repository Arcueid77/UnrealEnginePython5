#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:/UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,[Parameter(Mandatory=$true)][string]$PreviousDashDirectory,
    [ValidateSet('dashrpcinput','dashlocaldirection','dashactivation','dashtasks','meleeactivation','meleetrace')][string]$Kind='dashrpcinput')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory);$overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
    !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json')) -or (Test-Path -LiteralPath $output)){throw 'Marked stage and fresh output required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
$previousRoot=[IO.Path]::GetFullPath($PreviousDashDirectory)
if(!$previousRoot.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Previous Dash proof must be workspace-owned'}
$previous=Get-Content -LiteralPath (Join-Path $previousRoot 'summary.json') -Raw|ConvertFrom-Json -Depth 90
$previousKind=switch($Kind){'meleetrace'{'meleeactivation'} 'meleeactivation'{'meleehitmontage'} 'dashtasks'{'dashactivation'} 'dashactivation'{'dashlocaldirection'} 'dashlocaldirection'{'dashrpcinput'} default{'dashselector'}}
if($previous.status -ne 'passed' -or $previous.kind -ne $previousKind -or $previous.runtime_acceptance -or @($previous.assets).Count -ne 2){throw 'Accepted preceding Dash authoring required'}
$relative=@('Plugins/GameFeatures/ShooterCore/Content/Game/Dash/GA_Hero_Dash.uasset','Content/UEPMixins/DA_DashSelectorMixin.uasset')
if($Kind -in @('meleeactivation','meleetrace')){$relative=@('Plugins/GameFeatures/ShooterCore/Content/Game/Melee/GA_Melee.uasset','Content/UEPMixins/DA_MeleeHitMontageMixin.uasset')}
foreach($name in $relative){
    $from=Join-Path $stage $name;$other=Join-Path $overlay $name
    $row=@($previous.assets|Where-Object {$_.stage -eq $from -and $_.overlay -eq $other})
    if($row.Count -ne 1 -or (Get-FileHash -LiteralPath $from).Hash -ne $row[0].sha256 -or (Get-FileHash -LiteralPath $other).Hash -ne $row[0].sha256){throw 'Accepted Dash input paths/bytes differ'}
}
New-Item -ItemType Directory -Path "$output/PreviousAssets"|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';kind=$Kind;runtime_acceptance=$false;full_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;previous_dash_directory=$previousRoot
    previous_assets=@();assets=@();hashes=@();process=$null;error=$null}
function Add-DashHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
$mutating=$false
$copiedOverlay=@{}
try{
    foreach($name in @('summary.json','assets.json')){Add-DashHash (Join-Path $previousRoot $name)}
    $id=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($name in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $path=Join-Path $stage $name
        if((Get-Content -LiteralPath $path -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Matching native BuildId required'}
        Add-DashHash $path
    }
    for($index=0;$index -lt $relative.Count;$index++){
        $from=Join-Path $stage $relative[$index];$other=Join-Path $overlay $relative[$index]
        $first="$output/PreviousAssets/stage-$index.uasset";$second="$output/PreviousAssets/overlay-$index.uasset"
        Copy-Item -LiteralPath $from -Destination $first;Copy-Item -LiteralPath $other -Destination $second
        Add-DashHash $first;Add-DashHash $second
        $summary.previous_assets+=@{stage=$from;overlay=$other;stage_backup=$first;overlay_backup=$second}
    }
    foreach($mapping in @(@{source=(Join-Path $repo 'Source');target=(Join-Path $stage 'Plugins/UnrealEnginePython/Source')},
        @{source=(Join-Path $repo 'Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source');target=(Join-Path $stage 'Plugins/UEPLyraBridge/Source')})){
        foreach($file in Get-ChildItem -LiteralPath $mapping.source -Recurse -File){
            $target=Join-Path $mapping.target ([IO.Path]::GetRelativePath($mapping.source,$file.FullName))
            if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source parity mismatch'}
            Add-DashHash $file.FullName;Add-DashHash $target
        }
    }
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$file.FullName))
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        Add-DashHash $file.FullName;Add-DashHash $target
    }
    $generator=switch($Kind){'meleetrace'{'generate_melee_trace_assets.py'} 'meleeactivation'{'generate_melee_activation_assets.py'} 'dashtasks'{'generate_dash_tasks_assets.py'} 'dashactivation'{'generate_dash_activation_assets.py'} 'dashlocaldirection'{'generate_dash_local_direction_assets.py'} default{'generate_dash_rpc_input_assets.py'}}
    $script=Join-Path $repo "Demos/UEPLyraIntegration/Tools/$generator"
    foreach($path in @($PSCommandPath,$script,(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/stage_safety.py'),
        (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/mixin_graph_gates.py'),(Join-Path $repo 'Demos/UEPLyraIntegration/Tools/message_payload_graphs.py'),
        (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_dash_selector_assets.py'),
        (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll'))){Add-DashHash $path}
    if($Kind -in @('meleeactivation','meleetrace')){Add-DashHash (Join-Path $repo 'Demos/UEPLyraIntegration/Tools/generate_melee_hit_montage_assets.py')}
    $mutating=$true
    $arguments=@($project,'-run=Py',$script,'-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-UTF8Output','-DisablePython','-NoDDCCleanup',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession','-notraceserver','-trace=none','-AsyncLoadingThread',
        "-UEPDashRPCStageRoot=$stage","-UEPHeroAbilityAssetsResult=$output/assets.json","-abslog=$output/assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') 'Dash native RPC receiver two-store authoring' 240
    $proof=Get-Content -LiteralPath "$output/assets.json" -Raw|ConvertFrom-Json -Depth 90
    $methods=switch($Kind){'meleetrace'{4} 'meleeactivation'{3} 'dashtasks'{7} 'dashactivation'{4} 'dashlocaldirection'{3} default{2}}
    if($proof.status -ne 'passed' -or $proof.kind -ne $Kind -or !$proof.original_full_cdo_preserved -or !$proof.native_server_rpc_flags_preserved -or
        !$proof.original_business_graphs_preserved_with_dispatch -or !$proof.native_commit_tasks_animation_movement_retained -or
        $proof.whole_dash_activation_migrated -or $proof.new_business_nodes -ne 0 -or !$proof.native_register_restore_passed -or
        $proof.actual_registered_profile_method_counts.Python -ne $methods -or $proof.actual_registered_profile_method_counts.BlueprintFallback -ne $methods -or
        ($proof.assets -join ',') -ne ($relative -join ',')){throw 'Dash RPC receiver authoring proof incomplete'}
    if($Kind -eq 'dashrpcinput' -and (!$proof.python_replaces_two_remote_stores -or $proof.transport_nodes -ne 4)){throw 'RPC two-store dispatch proof incomplete'}
    if($Kind -eq 'meleetrace' -and (!$proof.original_trace_body_retained -or !$proof.python_trace_has_no_original_fallthrough -or
        $proof.native_end_transport_signature.owner -ne $proof.original_class -or !$proof.native_end_teardown_bypass -or
        $proof.native_end_guard -ne 'UEPMeleeTearingDown' -or $proof.native_end_gate -ne 'UEPMeleeNativeEnded' -or
        $proof.native_trace_entry -ne 'UEPMeleeAuthorityTrace' -or @($proof.native_trace_signature.parameters).Count -ne 0 -or
        ($proof.native_trace_signature.flags -band 0x40) -or $proof.transport_nodes -ne 1 -or
        @($proof.declared_dispatch_endpoints).Count -ne 2 -or $proof.whole_melee_trace_damage_business_migrated)){throw 'Melee authority dispatch/retained BP/guarded End proof incomplete'}
    if($Kind -eq 'meleeactivation' -and (!$proof.actual_activation_event_overridden -or !$proof.native_end_teardown_bypass -or
        $proof.native_end_transport_signature.owner -ne $proof.original_class -or $proof.native_end_guard -ne 'UEPMeleeTearingDown' -or
        $proof.native_end_gate -ne 'UEPMeleeNativeEnded' -or $proof.native_trace_entry -ne 'UEPMeleeAuthorityTrace' -or
        @($proof.native_trace_signature.parameters).Count -ne 0 -or ($proof.native_trace_signature.flags -band 0x40) -or
        $proof.transport_nodes -ne 7 -or $proof.whole_melee_trace_damage_business_migrated)){throw 'Melee activation/native trace entry/guarded End proof incomplete'}
    if($Kind -eq 'dashlocaldirection' -and ($proof.local_direction_transport_nodes -ne 5 -or !$proof.unused_positive_output_retained -or !$proof.native_direction_property_read)){
        throw 'Local direction original graph/five-node/current-property dispatch proof incomplete'
    }
    if($Kind -eq 'dashactivation' -and ($proof.native_task_entry_nodes -ne 1 -or !$proof.actual_activation_event_overridden -or
        $proof.native_task_entry -ne 'UEPDashStartNativeTasks' -or @($proof.task_entry_signature.parameters).Count -ne 0 -or ($proof.task_entry_signature.flags -band 0x40))){
        throw 'Actual activation override/one native non-RPC task entry proof incomplete'
    }
    if($Kind -eq 'dashtasks' -and ($proof.task_transport_nodes -ne 15 -or !$proof.original_native_delay_reused -or !$proof.transport_default_zero -or !$proof.native_end_teardown_bypass -or
        $proof.native_end_guard -ne 'UEPDashTearingDown' -or $proof.native_end_gate -ne 'UEPDashNativeEnded' -or
        $proof.native_end_transport_signature.owner -ne $proof.original_class -or
        !$proof.python_rpc_body_has_no_original_fallthrough -or @($proof.dispatch_transport_endpoints).Count -ne 12 -or
        $proof.native_delay_entry -ne 'UEPDashBeginNativeDelay' -or $proof.delay_transport_property -ne 'UEPDashDelayDuration')){
        throw 'Task/Delay dispatch, original latent node and no double remote body proof incomplete'
    }
    $log=Get-Content -LiteralPath "$output/assets.log" -Raw
    $marker=switch($Kind){'meleetrace'{'UEP_MELEE_TRACE_ASSETS_PASSED'} 'meleeactivation'{'UEP_MELEE_ACTIVATION_ASSETS_PASSED'} 'dashtasks'{'UEP_DASH_TASKS_ASSETS_PASSED'} 'dashactivation'{'UEP_DASH_ACTIVATION_ASSETS_PASSED'} 'dashlocaldirection'{'UEP_DASH_LOCAL_DIRECTION_ASSETS_PASSED'} default{'UEP_DASH_RPC_INPUT_ASSETS_PASSED'}}
    Assert-UEPFocusedLog $log $marker
    if($log -notmatch ('(?s)'+$marker+'.*Goodbye Python.*Log file closed')){throw 'Dash authoring exit incomplete'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Dash authoring frozen input changed'}}
    foreach($name in $relative){
        $from=Join-Path $stage $name;$other=Join-Path $overlay $name
        $before=@($summary.previous_assets|Where-Object overlay -eq $other)[0]
        if((Get-FileHash -LiteralPath $other).Hash -ne (Get-FileHash -LiteralPath $before.overlay_backup).Hash){throw 'Overlay changed during authoring; preserve concurrent changes'}
        $copiedOverlay[$other]=(Get-FileHash -LiteralPath $from).Hash
        Copy-Item -LiteralPath $from -Destination $other -Force
        $hash=(Get-FileHash -LiteralPath $from).Hash
        if((Get-FileHash -LiteralPath $other).Hash -ne $hash){throw 'Dash revised Overlay copy mismatch'}
        $summary.assets+=@{stage=$from;overlay=$other;sha256=$hash}
    }
    $summary.status='passed'
}catch{
    $summary.error=$_.ToString()
    if($mutating){foreach($before in $summary.previous_assets){
        $failed=Join-Path $output ('failed-'+[IO.Path]::GetFileName($before.stage))
        if(Test-Path -LiteralPath $before.stage){Copy-Item -LiteralPath $before.stage -Destination $failed}
        Copy-Item -LiteralPath $before.stage_backup -Destination $before.stage -Force
        if($copiedOverlay.ContainsKey($before.overlay) -and (Get-FileHash -LiteralPath $before.overlay).Hash -eq $copiedOverlay[$before.overlay]){
            Copy-Item -LiteralPath $before.overlay_backup -Destination $before.overlay -Force
        }
    }}
    throw
}finally{$summary|ConvertTo-Json -Depth 15|Set-Content -LiteralPath "$output/summary.json" -Encoding utf8}
Write-Host "Dash RPC input authoring: $($summary.status); $output"
