# Reusable process helpers; loading this file has no build or launch side effects.
function Start-UEPValidationProcess {
    param([string]$Executable, [string[]]$Arguments, [string]$WorkingDirectory, [string]$LogPrefix, [string]$Name,
          [hashtable]$Environment=@{})
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $Executable
    $info.WorkingDirectory = $WorkingDirectory
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    foreach ($key in $Environment.Keys) { $info.Environment[$key]=[string]$Environment[$key] }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    if (!$process.Start()) { throw "Unable to start $Name" }
    return @{ process=$process; stdout=$process.StandardOutput.ReadToEndAsync(); stderr=$process.StandardError.ReadToEndAsync()
        name=$Name; log_prefix=$LogPrefix; arguments=$Arguments; executable=$Executable
        stopwatch=[Diagnostics.Stopwatch]::StartNew(); result=$null; environment_names=@($Environment.Keys) }
}

function Complete-UEPValidationProcess {
    param([hashtable]$Handle)
    if ($null -ne $Handle.result) { return $Handle.result }
    if (!$Handle.process.HasExited) { throw "Process is still running: $($Handle.name)" }
    $Handle.process.WaitForExit()
    $Handle.stdout.GetAwaiter().GetResult() | Set-Content -LiteralPath ($Handle.log_prefix + '-stdout.log') -Encoding utf8
    $Handle.stderr.GetAwaiter().GetResult() | Set-Content -LiteralPath ($Handle.log_prefix + '-stderr.log') -Encoding utf8
    $Handle.result = @{exit_code=$Handle.process.ExitCode; pid=$Handle.process.Id
        name=$Handle.name; executable=$Handle.executable; arguments=$Handle.arguments
        duration_seconds=[math]::Round($Handle.stopwatch.Elapsed.TotalSeconds,3)
        stdout=($Handle.log_prefix + '-stdout.log'); stderr=($Handle.log_prefix + '-stderr.log')
        environment_names=$Handle.environment_names}
    return $Handle.result
}

function Stop-UEPValidationProcess {
    param([hashtable]$Handle)
    if ($null -eq $Handle) { return }
    if (!$Handle.process.HasExited) { $Handle.process.Kill($true); $Handle.process.WaitForExit() }
    $null = Complete-UEPValidationProcess $Handle
}

function Invoke-UEPValidationProcess {
    param([string]$Executable, [string[]]$Arguments, [string]$WorkingDirectory,
          [string]$LogPrefix, [string]$Name, [int]$TimeoutSeconds=240, [hashtable]$Environment=@{})
    $handle = Start-UEPValidationProcess $Executable $Arguments $WorkingDirectory $LogPrefix $Name $Environment
    try {
        if (!$handle.process.WaitForExit($TimeoutSeconds * 1000)) { throw "$Name timed out" }
        $result = Complete-UEPValidationProcess $handle
        if ($result.exit_code -ne 0) { throw "$Name exited $($result.exit_code); $LogPrefix" }
        return $result
    }
    finally { Stop-UEPValidationProcess $handle; $handle.process.Dispose() }
}
