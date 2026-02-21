<#
.SYNOPSIS
    Tests network connectivity to a host and ports with logging.

.DESCRIPTION
    Uses Test-NetConnection to validate DNS resolution, ICMP reachability,
    and TCP port connectivity for one or more ports.

.PARAMETER TargetHost
    Hostname or IP to test.

.PARAMETER Port
    One or more ports to test (default: 80, 443).

.PARAMETER OutputDirectory
    Directory to write log files (default: <script>\logs).

.PARAMETER TimeoutSeconds
    Timeout in seconds for each test (default: 3).

.EXAMPLE
    .\Test-NetConnectionReport.ps1 -TargetHost "example.com" -Port 80,443

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetHost,

    [Parameter(Mandatory = $false)]
    [int[]]$Port = @(80, 443),

    [Parameter(Mandatory = $false)]
    [int]$TimeoutSeconds = 3,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs")
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Test-NetConnectionReport_$timestamp.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

Write-Log "Testing connectivity to $TargetHost" "INFO"

try {
    $results = @()
    foreach ($p in $Port) {
        Write-Log "Testing TCP port $p" "INFO"
        $test = Test-NetConnection -ComputerName $TargetHost -Port $p -WarningAction SilentlyContinue
        $results += [PSCustomObject]@{
            TargetHost = $TargetHost
            Port = $p
            PingSucceeded = $test.PingSucceeded
            RemoteAddress = $test.RemoteAddress
            TcpTestSucceeded = $test.TcpTestSucceeded
        }
        Start-Sleep -Milliseconds ($TimeoutSeconds * 100)
    }

    $results | Format-Table -AutoSize
    Write-Log "Connectivity tests complete" "INFO"
}
catch {
    Write-Log "Connectivity test failed: $_" "ERROR"
    throw
}
