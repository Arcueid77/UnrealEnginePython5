#Requires -Version 7.0
[CmdletBinding()]
param([string]$EngineRoot='F:\UnrealEngine',[Parameter(Mandatory=$true)][string]$StageProject,
      [Parameter(Mandatory=$true)][string]$OutputDirectory,[switch]$Network,[switch]$Producer,
      [string]$OriginalDefaultAuditDirectory,[string]$PriorCombinedDirectory,
      [ValidateRange(1024,65535)][int]$ServerPort=7792)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Producer -and !$Network){throw 'Real original interaction producer requires server and two clients'}
if($Producer -and (!$OriginalDefaultAuditDirectory -or !$PriorCombinedDirectory)){throw 'Producer requires accepted original default and combined asset provenance directories'}
. (Join-Path $PSScriptRoot 'UEPValidationProcesses.ps1')
. (Join-Path $PSScriptRoot 'LyraHUDContracts.ps1')
$repo=Split-Path $PSScriptRoot -Parent
$project=[IO.Path]::GetFullPath($StageProject);$stage=Split-Path $project -Parent
$output=[IO.Path]::GetFullPath($OutputDirectory)
$prefix=[IO.Path]::GetFullPath((Join-Path $repo '.build'))+[IO.Path]::DirectorySeparatorChar
if(!$stage.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or !$output.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or
   !(Test-Path -LiteralPath (Join-Path $stage '.uep-lyra-full-stage.json'))){throw 'Marked workspace stage/output required'}
if(Test-Path $output){throw 'Fresh inspection directory required'}
if(@(Get-Process -Name UnrealEditor,UnrealEditor-Cmd,UnrealBuildTool -ErrorAction SilentlyContinue).Count){throw 'Another native lane is active'}
New-Item -ItemType Directory -Path $output|Out-Null
$summary=[ordered]@{schema_version=1;status='failed';runtime_acceptance=$false;native_interaction_producer_tested=$false
    cpp_compile_executed=$false;cook_package_executed=$false;hashes=@();process=$null;error=$null}
$handles=@{};$summary.network_inspection=[bool]$Network;$summary.processes=@{}
function Add-InspectionHash([string]$Path){$summary.hashes+=@{path=$Path;sha256=(Get-FileHash $Path).Hash}}
try{
    $id=(Get-Content (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.modules') -Raw|ConvertFrom-Json).BuildId
    foreach($relative in @('Binaries/Win64/UnrealEditor.modules','Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor.modules','Plugins/UEPLyraBridge/Binaries/Win64/UnrealEditor.modules')){
        $file=Join-Path $stage $relative
        if((Get-Content $file -Raw|ConvertFrom-Json).BuildId -ne $id){throw 'Native BuildId mismatch'}
        Add-InspectionHash $file
    }
    foreach($source in Get-ChildItem (Join-Path $repo 'Source') -Recurse -File){
        $target=Join-Path $stage ('Plugins/UnrealEnginePython/Source/'+[IO.Path]::GetRelativePath((Join-Path $repo 'Source'),$source.FullName))
        if((Get-FileHash $source.FullName).Hash -ne (Get-FileHash $target).Hash){throw 'Native source mismatch'}
        Add-InspectionHash $source.FullName;Add-InspectionHash $target
    }
    $overlay=Join-Path $repo 'Demos/UEPLyraIntegration/Overlay'
    foreach($source in Get-ChildItem (Join-Path $overlay 'Content/Scripts') -Recurse -File -Filter '*.py'){
        $target=Join-Path $stage ([IO.Path]::GetRelativePath($overlay,$source.FullName))
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force
        Add-InspectionHash $source.FullName;Add-InspectionHash $target
    }
    $marker=Get-Content (Join-Path $stage '.uep-lyra-full-stage.json') -Raw|ConvertFrom-Json
    $relative='Plugins/GameFeatures/ShooterExplorer/Content/Maps/L_InteractionTestMap.umap'
    $original=Join-Path (Split-Path $marker.source -Parent) $relative;$copy=Join-Path $stage $relative
    if((Get-FileHash $original).Hash -ne (Get-FileHash $copy).Hash){throw 'Original interaction map differs'}
    Add-InspectionHash $original;Add-InspectionHash $copy;Add-InspectionHash $PSCommandPath
    Add-InspectionHash (Join-Path $stage 'Plugins/UnrealEnginePython/Binaries/Win64/UnrealEditor-UnrealEnginePython.dll')
    if($Producer){
        $gate=Join-Path $repo 'Demos/UEPLyraIntegration/Tools/validate_interaction_producer_reports.py'
        $originalAudit=Join-Path $OriginalDefaultAuditDirectory 'audit.json'
        $combinedAudit=Join-Path $PriorCombinedDirectory 'summary.json'
        Add-InspectionHash $gate;Add-InspectionHash $originalAudit;Add-InspectionHash $combinedAudit
    }
    $arguments=@($project,'/ShooterExplorer/Maps/L_InteractionTestMap','-game','-NullRHI','-unattended','-nop4','-NoSound','-NoSplash','-NoLoadingScreen',
        '-culture=en','-UTF8Output','-DisablePython','-DisablePlugins=AndroidFileServer,UdpMessaging,TcpMessaging,RemoteSession',
        '-notraceserver','-trace=none',"-UEPInteractionInspectionResult=$output/inspection.json","-abslog=$output/inspection.log")
    if($Producer){$arguments+='-UEPInteractionProducer'}
    $peers=if($Network){@('server','A','B0')}else{@('inspection')}
    if($Network){
        foreach($peer in $peers){
            $peerArguments=@($arguments|Where-Object {$_ -ne '-game' -and $_ -notlike '-UEPInteractionInspectionResult=*' -and $_ -notlike '-abslog=*'})
            if($peer -eq 'server'){$peerArguments+=@('-server',"-port=$ServerPort",'-multihome=127.0.0.1')}
            else{
                $peerArguments[1]="127.0.0.1:$ServerPort"+$(if($Producer){"?Name=UEPInteraction_$peer"}else{''});$peerArguments+='-game'
                if($Producer){$peerArguments=@($peerArguments|Where-Object {$_ -ne '-NullRHI'})+@('-RenderOffscreen','-windowed','-ResX=640','-ResY=360',
                    '-ExecCmds=t.MaxFPS 30,sg.ShadowQuality 0,sg.GlobalIlluminationQuality 0,sg.ReflectionQuality 0,r.Streaming.PoolSize 256')}
            }
            $peerArguments+=@("-UEPInteractionPeer=$peer","-UEPInteractionInspectionResult=$output/$peer.json","-abslog=$output/$peer.log")
            $exe=Join-Path $EngineRoot $(if($peer -eq 'server'){'Engine/Binaries/Win64/UnrealEditor-Cmd.exe'}else{'Engine/Binaries/Win64/UnrealEditor.exe'})
            $handles[$peer]=Start-UEPValidationProcess $exe $peerArguments $stage (Join-Path $output $peer) "Original interaction map $peer"
            if($peer -eq 'server'){
                $watch=[Diagnostics.Stopwatch]::StartNew()
                while($true){
                    if($handles[$peer].process.HasExited){throw 'Original interaction server exited before listen'}
                    if((Test-Path "$output/server.log") -and (Get-Content "$output/server.log" -Raw) -match "listening on port $ServerPort"){break}
                    if($watch.Elapsed.TotalSeconds -gt 90){throw 'Original interaction server listen timeout'}
                    Start-Sleep -Milliseconds 250
                }
            }
        }
        $watch=[Diagnostics.Stopwatch]::StartNew()
        while(@($handles.Values|Where-Object {!$_.process.HasExited}).Count){
            if($watch.Elapsed.TotalSeconds -gt 300){throw 'Original interaction network inspection timeout'}
            foreach($peer in $peers){if($handles[$peer].process.HasExited -and $handles[$peer].process.ExitCode -ne 0){throw "Original interaction peer $peer failed"}}
            if($Producer){
                foreach($peer in @('A','B0')){
                    if($handles[$peer].process.HasExited -and $null -eq $handles[$peer].result){
                        $summary.processes[$peer]=Complete-UEPValidationProcess $handles[$peer]
                        @{peer=$peer;exit_code=$summary.processes[$peer].exit_code}|ConvertTo-Json|
                            Set-Content (Join-Path $output "$peer-exited.json") -Encoding utf8
                    }
                }
            }
            foreach($peer in $peers){
                $reportPath=Join-Path $output "$peer.json"
                if(Test-Path $reportPath){
                    try{$peerReport=Get-Content $reportPath -Raw|ConvertFrom-Json -Depth 80}catch{continue}
                    if($peerReport.status -eq 'failed'){throw "Original interaction peer $peer report failed"}
                }
            }
            Start-Sleep -Milliseconds 250
        }
        foreach($peer in $peers){
            if($null -eq $handles[$peer].result){$summary.processes[$peer]=Complete-UEPValidationProcess $handles[$peer]}
        }
    }else{$summary.process=Invoke-UEPValidationProcess (Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor.exe') $arguments $stage (Join-Path $output 'inspection') 'Read-only original interaction map inspection' 180}
    foreach($peer in $peers){
        $report=Get-Content (Join-Path $output "$peer.json") -Raw|ConvertFrom-Json -Depth 80
        if($Producer){
            if($report.status -ne 'passed' -or !$report.native_interaction_producer_tested -or !$report.original_world_restored -or
               $report.synthetic_duration_broadcast -or $report.python_handler_replayed -or $report.activation_handler_replayed -or
               $report.enhanced_input_pipeline_tested -or $report.replicated_duration_message_tested -or
               @($report.cases).Count -ne $(if($peer -eq 'server'){2}else{1})){throw 'Original interaction producer proof incomplete'}
        }elseif($report.status -ne 'passed' -or $report.runtime_acceptance -or $report.native_interaction_producer_tested -or $report.gameplay_state_written -or @($report.interactables).Count -lt 1){throw 'Original world inspection incomplete'}
        $log=Get-Content (Join-Path $output "$peer.log") -Raw
        $readyMarker=if($Producer){'UEP_INTERACTION_PRODUCER_READY'}else{'UEP_INTERACTION_WORLD_INSPECTION_READY'}
        $passMarker=if($Producer){'UEP_INTERACTION_PRODUCER_PASSED'}else{'UEP_INTERACTION_WORLD_INSPECTION_PASSED'}
        Assert-UEPFocusedLog $log $passMarker -RequirePythonExit
        if($log -notmatch ('(?s)'+$readyMarker+'.*Goodbye Python.*'+$passMarker+'.*Log file closed')){throw 'Inspection shutdown ordering incomplete'}
    }
    foreach($input in $summary.hashes){if((Get-FileHash $input.path).Hash -ne $input.sha256){throw 'Inspection input changed'}}
    if($Producer){
        $python=Join-Path $EngineRoot 'Engine/Binaries/ThirdParty/Python3/Win64/python.exe'
        $null=Invoke-UEPValidationProcess $python @('-B',$gate,'--directory',$output,'--original-default-audit',$originalAudit,'--prior-combined',$combinedAudit) $repo (Join-Path $output 'external-gate') 'Original interaction external report and asset gate' 30
        $summary.external_gate=Get-Content (Join-Path $output 'external-gate-stdout.log') -Raw|ConvertFrom-Json
        if($summary.external_gate.status -ne 'passed'){throw 'Original interaction external gate failed'}
    }
    $summary.status='passed'
    $summary.native_interaction_producer_tested=[bool]$Producer
}catch{$summary.error=$_.ToString();throw}
finally{
    foreach($handle in $handles.Values){Stop-UEPValidationProcess $handle;$handle.process.Dispose()}
    $summary|ConvertTo-Json -Depth 10|Set-Content (Join-Path $output 'summary.json') -Encoding utf8
}
Write-Host "Original interaction world inspection: $($summary.status); $output"
