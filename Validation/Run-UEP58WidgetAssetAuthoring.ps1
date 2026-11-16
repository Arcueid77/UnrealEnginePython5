#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$EngineRoot='F:\UnrealEngine',
    [Parameter(Mandatory=$true)][string]$StageProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [ValidateSet('DashCooldown','RespawnTimer','QuickBarSlot','Nameplate')][string]$Widget='DashCooldown'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject)
$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$buildPrefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($buildPrefix,[StringComparison]::OrdinalIgnoreCase) -or
   !$output.StartsWith($buildPrefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked workspace validation stage/output required'}
if(Test-Path -LiteralPath $output){throw 'Use fresh authoring evidence directory'}
if(@(Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^UnrealEditor(-Cmd)?\.exe$|^LyraGame.*\.exe$' -and $_.CommandLine -like ('*'+$project+'*')
}).Count){throw 'Matching stage process already running'}
$kind=if($Widget -eq 'DashCooldown'){'Dash'}else{'Respawn'}
$relative="Plugins\GameFeatures\ShooterCore\Content\Game\$kind\W_$Widget.uasset"
$dataRelative="Content\UEPMixins\DA_W_${Widget}Mixin.uasset"
$generator=if($Widget -eq 'DashCooldown'){'generate_dash_cooldown_mixin_assets.py'}else{'generate_respawn_timer_mixin_assets.py'}
$cleanupNodes=if($Widget -eq 'DashCooldown'){4}else{5}
$resume="UEPResume${kind}Observation"
if($Widget -eq 'QuickBarSlot') {
    $kind='QuickBar'
    $relative='Plugins\GameFeatures\ShooterCore\Content\UserInterface\HUD\W_QuickBarSlot.uasset'
    $generator='generate_quickbar_slot_mixin_assets.py'
    $cleanupNodes=0
    $resume='UEPResumeQuickBarSlotObservation'
}
if($Widget -eq 'Nameplate') {
    $kind='Nameplate'
    $relative='Content\UI\Indicators\W_Nameplate.uasset'
    $generator='generate_nameplate_mixin_assets.py'
    $cleanupNodes=6
    $resume='UEPResumeNameplateObservation'
}
$successMarker="UEP_$($kind.ToUpper())_ASSETS_PASSED"
$overlay=Join-Path $repo 'Demos\UEPLyraIntegration\Overlay'
$marker=Get-Content -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json') -Raw | ConvertFrom-Json
$reference=Join-Path (Split-Path $marker.source -Parent) $relative
$script=Join-Path (Join-Path $repo 'Demos\UEPLyraIntegration\Tools') $generator
New-Item -ItemType Directory -Path $output | Out-Null
$summary=[ordered]@{schema_version=1;status='failed';widget=$Widget;runtime_acceptance=$false
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;error=$null;assets=@()}
function Add-WidgetHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash -LiteralPath $Path).Hash}}
try {
    $engineId=(Get-Content -LiteralPath (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json).BuildId
    $pluginId=(Get-Content -LiteralPath (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor.modules') -Raw | ConvertFrom-Json).BuildId
    if($engineId -ne $pluginId){throw 'Editor BuildId mismatch'}
    $summary.editor_build_id=$engineId
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins\UnrealEnginePython\Source\'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash -LiteralPath $source.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Native source mismatch'}
        Add-WidgetHash $source.FullName;Add-WidgetHash $target
    }
    foreach($source in Get-ChildItem -LiteralPath (Join-Path $overlay 'Content\Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-WidgetHash $source.FullName;Add-WidgetHash $target
    }
    foreach($path in @($PSCommandPath,$script,(Join-Path $repo 'Demos\UEPLyraIntegration\Tools\stage_safety.py'),$reference,
                      (Join-Path $stage 'Plugins\UnrealEnginePython\Binaries\Win64\UnrealEditor-UnrealEnginePython.dll'))){Add-WidgetHash $path}
    $transport='Content\UEPInterop\BP_UEPGameplayMessages.uasset'
    if((Get-FileHash -LiteralPath (Join-Path $overlay $transport)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $stage $transport)).Hash){throw 'Accepted transport differs'}
    Add-WidgetHash (Join-Path $overlay $transport)
    if($Widget -ne 'QuickBarSlot'){Add-WidgetHash (Join-Path $stage $transport)}
    else{Add-WidgetHash (Join-Path $repo 'Demos\UEPLyraIntegration\Tools\message_payload_graphs.py')}
    $target=Join-Path $stage $relative
    if(!(Test-Path -LiteralPath (Join-Path $overlay $relative))){Copy-Item -LiteralPath $reference -Destination $target -Force}
    $arguments=@($project,'-run=Py',$script,"-UEP${kind}StageRoot=$stage","-UEPGenerate${kind}Result=$output\assets.json",
        '-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-culture=en','-UTF8Output','-DisablePython',
        '-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging','-notraceserver','-trace=none',"-abslog=$output\assets.log")
    $summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe') $arguments $stage (Join-Path $output 'assets') "$Widget widget authoring" 300
    $report=Get-Content -LiteralPath (Join-Path $output 'assets.json') -Raw | ConvertFrom-Json -Depth 40
    $transportAccepted=if($Widget -eq 'QuickBarSlot'){
        $functions=@($report.transport.functions)
        # Explicit known inventories, not a relaxed count/minimum. Extending
        # the adapter requires fresh authoring evidence; old frozen hashes
        # remain untouched and cannot certify the new shared asset.
        $expectedTransport=@{ReadUI=4;BroadcastUI=2;ReadVerb=4;BroadcastVerb=2;ReadDuration=4;BroadcastDuration=2
            ReadFailure=4;BroadcastFailure=2;CopyFailureText=3;SameFailureText=5;ReadQuickBarSlots=4;BroadcastQuickBarSlots=2
            ReadQuickBarActiveIndex=4;BroadcastQuickBarActiveIndex=2;InjectAxis1DForAction=3}
        if(@($functions|Where-Object {$_.name -match 'Nameplate'}).Count){
            $expectedTransport.ReadNameplateInfo=4;$expectedTransport.BroadcastNameplateInfo=2
            $expectedTransport.ReadNameplateRequest=4;$expectedTransport.BroadcastNameplateRequest=2
        }
        $inventoryMatches=$functions.Count -eq $expectedTransport.Count -and
            @($functions|Where-Object {!$expectedTransport.ContainsKey($_.name) -or $_.nodes -ne $expectedTransport[$_.name]}).Count -eq 0 -and
            @($functions.name|Sort-Object -Unique).Count -eq $expectedTransport.Count
        $report.transport.old_graphs_unchanged -and !$report.transport.business_logic -and
        $report.transport.wildcard_calls_use_compiled_vm -and $report.transport.preserves_all_existing_functions -and $inventoryMatches -and
        @($report.transport.old_graph_digests.PSObject.Properties).Count -ge 10 -and $report.original_widget_tick_retained
    }elseif($Widget -eq 'Nameplate'){
        $report.existing_transport_reused -and $report.original_widget_tick_retained -and
        (@($report.init_state_transport_nodes) -join ',') -eq '4,4'
    }else{$report.existing_transport_reused}
    if($report.status -ne 'passed' -or !$report.class_preserved -or !$report.original_proxy_stored -or
       !$transportAccepted -or $report.cleanup_nodes -ne $cleanupNodes -or $report.cleanup_business_logic -or
       $report.runtime_acceptance -or $report.explicit_resume -ne $resume){throw 'Widget asset gate incomplete'}
    $log=Get-Content -LiteralPath (Join-Path $output 'assets.log') -Raw
    Assert-UEPFocusedLog $log $successMarker
    if($log -notmatch ('(?s)'+$successMarker+'.*Goodbye Python.*Log file closed')){throw 'Authoring did not close cleanly'}
    foreach($input in $summary.hashes){if((Get-FileHash -LiteralPath $input.path).Hash -ne $input.sha256){throw 'Authoring input changed'}}
    $outputs=@($relative,$dataRelative)
    if($Widget -eq 'QuickBarSlot'){$outputs+=$transport}
    foreach($asset in $outputs){
        $from=Join-Path $stage $asset;$to=Join-Path $overlay $asset
        New-Item -ItemType Directory -Path (Split-Path $to -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $from -Destination $to -Force
        $digest=(Get-FileHash -LiteralPath $from).Hash
        if($digest -ne (Get-FileHash -LiteralPath $to).Hash){throw 'Canonical copy differs'}
        $summary.assets+=@{stage=$from;overlay=$to;sha256=$digest}
    }
    $summary.status='passed'
}
catch{$summary.error=$_.ToString();throw}
finally{$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'summary.json') -Encoding utf8}
Write-Host "Widget authoring passed; not runtime acceptance: $output"
