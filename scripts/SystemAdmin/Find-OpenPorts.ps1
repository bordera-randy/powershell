<#
.SYNOPSIS
    Finds all open ports on a server.

.DESCRIPTION
    Scans a range of TCP ports on a target computer using TcpClient connections.
    Supports scanning a custom port range, common/well-known ports only, or both.
    Identifies common service names for known ports, displays a progress bar during
    the scan, and color-codes results. Results can be exported to CSV.

.PARAMETER ComputerName
    Hostname or IP address to scan (default: localhost).

.PARAMETER PortRange
    Port range to scan in "start-end" format (default: "1-1024").

.PARAMETER CommonPortsOnly
    Scan only well-known ports (21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443,
    445, 993, 995, 1433, 3306, 3389, 5432, 5985, 8080, 8443).

.PARAMETER Timeout
    Connection timeout in milliseconds (default: 100).

.PARAMETER ExportPath
    File path for CSV export. When omitted, results are displayed only.

.EXAMPLE
    .\Find-OpenPorts.ps1
    Scans ports 1-1024 on localhost with 100ms timeout.

.EXAMPLE
    .\Find-OpenPorts.ps1 -ComputerName "192.168.1.10" -CommonPortsOnly
    Scans only well-known ports on the specified host.

.EXAMPLE
    .\Find-OpenPorts.ps1 -ComputerName "Server01" -PortRange "80-8080" -Timeout 200 -ExportPath "C:\Reports\ports.csv"
    Scans ports 80-8080 on Server01 with 200ms timeout and exports to CSV.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ComputerName = "localhost",

    [Parameter(Mandatory = $false)]
    [string]$PortRange = "1-1024",

    [Parameter(Mandatory = $false)]
    [switch]$CommonPortsOnly,

    [Parameter(Mandatory = $false)]
    [int]$Timeout = 100,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# Well-known port to service mapping
$serviceMap = @{
    20   = "FTP Data"
    21   = "FTP"
    22   = "SSH"
    23   = "Telnet"
    25   = "SMTP"
    53   = "DNS"
    67   = "DHCP Server"
    68   = "DHCP Client"
    80   = "HTTP"
    110  = "POP3"
    111  = "RPCBind"
    119  = "NNTP"
    123  = "NTP"
    135  = "MS RPC"
    137  = "NetBIOS Name"
    138  = "NetBIOS Datagram"
    139  = "NetBIOS Session"
    143  = "IMAP"
    161  = "SNMP"
    162  = "SNMP Trap"
    389  = "LDAP"
    443  = "HTTPS"
    445  = "SMB"
    465  = "SMTPS"
    514  = "Syslog"
    587  = "SMTP Submission"
    636  = "LDAPS"
    993  = "IMAPS"
    995  = "POP3S"
    1433 = "MSSQL"
    1521 = "Oracle DB"
    3306 = "MySQL"
    3389 = "RDP"
    5432 = "PostgreSQL"
    5900 = "VNC"
    5985 = "WinRM HTTP"
    5986 = "WinRM HTTPS"
    6379 = "Redis"
    8080 = "HTTP Proxy"
    8443 = "HTTPS Alt"
    9090 = "Prometheus"
    9200 = "Elasticsearch"
    27017 = "MongoDB"
}

$commonPorts = @(21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 1433, 3306, 3389, 5432, 5985, 8080, 8443)

# Determine ports to scan
if ($CommonPortsOnly) {
    $portsToScan = $commonPorts
}
else {
    $rangeParts = $PortRange -split '-'
    if ($rangeParts.Count -ne 2) {
        Write-Host "Invalid port range format. Use 'start-end' (e.g. '1-1024')." -ForegroundColor Red
        exit 1
    }
    $startPort = [int]$rangeParts[0]
    $endPort = [int]$rangeParts[1]
    if ($startPort -lt 1 -or $endPort -gt 65535 -or $startPort -gt $endPort) {
        Write-Host "Invalid port range. Ports must be between 1 and 65535." -ForegroundColor Red
        exit 1
    }
    $portsToScan = $startPort..$endPort
}

# Main execution
Write-Host "`n=== Open Port Scanner ===" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host "Target:  $ComputerName" -ForegroundColor White
Write-Host "Ports:   $(if ($CommonPortsOnly) { 'Common ports only' } else { $PortRange })" -ForegroundColor White
Write-Host "Timeout: ${Timeout}ms" -ForegroundColor White
Write-Host "Total ports to scan: $($portsToScan.Count)" -ForegroundColor White

$allResults = @()
$openCount = 0
$closedCount = 0
$totalPorts = $portsToScan.Count
$currentPort = 0

foreach ($port in $portsToScan) {
    $currentPort++
    $percentComplete = [math]::Round(($currentPort / $totalPorts) * 100)
    Write-Progress -Activity "Scanning $ComputerName" -Status "Port $port ($currentPort of $totalPorts)" -PercentComplete $percentComplete

    $status = "Closed"
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($ComputerName, $port, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne($Timeout, $false)

        if ($wait -and $tcpClient.Connected) {
            $status = "Open"
            $openCount++
        }
        else {
            $closedCount++
        }

        $tcpClient.Close()
    }
    catch {
        $closedCount++
    }

    $serviceName = if ($serviceMap.ContainsKey($port)) { $serviceMap[$port] } else { "Unknown" }

    if ($status -eq "Open") {
        $color = "Green"
        Write-Host "  Port $port ($serviceName): $status" -ForegroundColor $color

        $allResults += [PSCustomObject]@{
            ComputerName = $ComputerName
            Port         = $port
            Status       = $status
            Service      = $serviceName
        }
    }
}

Write-Progress -Activity "Scanning $ComputerName" -Completed

# Summary
Write-Host "`n=== Scan Summary ===" -ForegroundColor Green
Write-Host "  Target:       $ComputerName" -ForegroundColor Cyan
Write-Host "  Ports scanned: $totalPorts" -ForegroundColor White
Write-Host "  Open:          $openCount" -ForegroundColor Green
Write-Host "  Closed:        $closedCount" -ForegroundColor Red

if ($allResults.Count -gt 0) {
    Write-Host "`n  Open Ports:" -ForegroundColor Cyan
    foreach ($result in $allResults) {
        Write-Host "    $($result.Port)`t$($result.Service)" -ForegroundColor Green
    }
}
else {
    Write-Host "`n  No open ports found." -ForegroundColor Yellow
}

# Export
if ($ExportPath -and $allResults.Count -gt 0) {
    $exportDir = Split-Path -Path $ExportPath -Parent
    if ($exportDir -and -not (Test-Path $exportDir)) {
        New-Item -Path $exportDir -ItemType Directory -Force | Out-Null
    }
    $allResults | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "`n  Results exported to: $ExportPath" -ForegroundColor Green
}
