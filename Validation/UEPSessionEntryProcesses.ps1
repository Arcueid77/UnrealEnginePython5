# Owned local listen host and two serial UI clients. No build/cook or remote host.
function Invoke-UEPSessionEntryPeers {
    param([string]$Executable,[string[]]$Arguments,[string]$Stage,[string]$Output,[int]$Port)
    $base=@($Arguments|Where-Object {$_ -notlike '-UEPSessionEntryResult=*' -and $_ -notlike '-abslog=*'})
    $base+=@("-UEPSessionEntryDirectory=$Output","-port=$Port")
    $processes=@{};$server=$null
    try{
        $serverArgs=$base+@('-UEPSessionEntryRole=host',"-UEPSessionEntryResult=$Output/host.json","-abslog=$Output/host.log")
        $server=Start-UEPValidationProcess $Executable $serverArgs $Stage "$Output/host" 'Owned LAN UI join host'
        $timer=[Diagnostics.Stopwatch]::StartNew()
        while(!(Test-Path -LiteralPath "$Output/host-ready.json")){
            if($server.process.HasExited){$processes.host=Complete-UEPValidationProcess $server;throw 'Owned LAN host exited before readiness'}
            if($timer.Elapsed.TotalSeconds -gt 180){throw 'Owned LAN host readiness timeout'}
            Start-Sleep -Milliseconds 250
        }
        foreach($profile in @('BlueprintFallback','Python')){
            $clientArgs=$base+@('-UEPSessionEntryRole=client',"-UEPSessionEntryProfile=$profile","-UEPSessionEntryResult=$Output/$profile.json","-abslog=$Output/$profile.log")
            $client=Start-UEPValidationProcess $Executable $clientArgs $Stage "$Output/$profile" "Owned browser entry $profile client"
            try{
                if(!$client.process.WaitForExit(300000)){throw 'Owned native entry client timeout'}
                $processes[$profile]=Complete-UEPValidationProcess $client
                if($processes[$profile].exit_code -ne 0){throw 'Owned native entry client process failed'}
            }finally{Stop-UEPValidationProcess $client;$processes[$profile]=$client.result;$client.process.Dispose()}
            $report=Get-Content -LiteralPath "$Output/$profile.json" -Raw|ConvertFrom-Json -Depth 90
            if($report.status -ne 'passed' -or $report.profile -ne $profile){throw 'Native entry client failed'}
        }
        'complete'|Set-Content -LiteralPath "$Output/host-stop.token" -Encoding utf8
        if(!$server.process.WaitForExit(30000)){throw 'Owned LAN host did not finish cleanup'}
        $processes.host=Complete-UEPValidationProcess $server
        if($processes.host.exit_code -ne 0){throw 'Owned LAN host failed'}
        foreach($peer in @('host','BlueprintFallback','Python')){
            $log=Get-Content -LiteralPath "$Output/$peer.log" -Raw
            Assert-UEPFocusedLog $log 'UEP_SESSION_ENTRY_SHUTDOWN_PASSED' -RequirePythonExit
            if($log -notmatch '(?s)UEP_SESSION_ENTRY_DIFFERENTIAL_PASSED.*Goodbye Python.*UEP_SESSION_ENTRY_SHUTDOWN_PASSED.*Log file closed'){throw 'Native entry peer shutdown ordering incomplete'}
        }
        return $processes
    }finally{
        if($null -ne $server){
            if(!$server.process.HasExited){'abort'|Set-Content -LiteralPath "$Output/host-stop.token" -Encoding utf8;$null=$server.process.WaitForExit(5000)}
            Stop-UEPValidationProcess $server;$processes.host=$server.result;$server.process.Dispose()
        }
        $processes|ConvertTo-Json -Depth 9|Set-Content -LiteralPath "$Output/owned-processes.json" -Encoding utf8
    }
}
