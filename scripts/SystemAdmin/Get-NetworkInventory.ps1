<#
.SYNOPSIS
    Discovers devices and services on a network subnet.

.DESCRIPTION
    Scans a subnet IP range by pinging each address to identify online hosts.
    Optionally resolves DNS hostnames and checks common TCP ports on responsive
    hosts. Displays results with color-coded online/offline status and a progress
    bar during scanning. Results can be exported to CSV.

.PARAMETER Subnet
    The first three octets of the subnet to scan (e.g. "192.168.1").

.PARAMETER StartRange
    First host octet to scan (default: 1).

.PARAMETER EndRange
    Last host octet to scan (default: 254).

.PARAMETER ResolveDNS
    Attempt reverse DNS resolution for each responding host.

.PARAMETER ExportPath
    File path for CSV export. When omitted, results are displayed only.

.EXAMPLE
    .\Get-NetworkInventory.ps1 -Subnet "192.168.1"
    Pings 192.168.1.1 through 192.168.1.254.

.EXAMPLE
    .\Get-NetworkInventory.ps1 -Subnet "10.0.0" -StartRange 1 -EndRange 50 -ResolveDNS
    Scans a smaller range with DNS resolution.

.EXAMPLE
    .\Get-NetworkInventory.ps1 -Subnet "192.168.1" -ExportPath "C:\Reports\inventory.csv"
    Scans the subnet and exports results to CSV.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Subnet,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 254)]
    [int]$StartRange = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 254)]
    [int]$EndRange = 254,

    [Parameter(Mandatory = $false)]
    [switch]$ResolveDNS,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# Common ports to check on online hosts
$commonPorts = @{
    22   = "SSH"
    80   = "HTTP"
    135  = "RPC"
    139  = "NetBIOS"
    443  = "HTTPS"
    445  = "SMB"
    3389 = "RDP"
    5985 = "WinRM"
}

function Test-TcpPort {
    param(
        [string]$IP,
        [int]$Port,
        [int]$TimeoutMs = 150
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($IP, $Port, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        $result = $wait -and $tcpClient.Connected
        $tcpClient.Close()
        return $result
    }
    catch {
        return $false
    }
}

# Validate range
if ($StartRange -gt $EndRange) {
    Write-Host "StartRange ($StartRange) must be less than or equal to EndRange ($EndRange)." -ForegroundColor Red
    exit 1
}

# Main execution
Write-Host "`n=== Network Inventory Discovery ===" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host "Subnet:    $Subnet.x" -ForegroundColor White
Write-Host "Range:     $StartRange - $EndRange" -ForegroundColor White
Write-Host "DNS Resolve: $ResolveDNS" -ForegroundColor White

$totalIPs = $EndRange - $StartRange + 1
$currentIP = 0
$allResults = @()
$onlineCount = 0
$offlineCount = 0

Write-Host "`nScanning $totalIPs addresses...`n" -ForegroundColor Cyan

foreach ($i in $StartRange..$EndRange) {
    $currentIP++
    $ipAddress = "$Subnet.$i"
    $percentComplete = [math]::Round(($currentIP / $totalIPs) * 100)
    Write-Progress -Activity "Scanning Network" -Status "$ipAddress ($currentIP of $totalIPs)" -PercentComplete $percentComplete

    # Ping test
    $pingResult = $false
    try {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $reply = $ping.Send($ipAddress, 500)
        $pingResult = $reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success
        $responseTime = if ($pingResult) { $reply.RoundtripTime } else { $null }
        $ping.Dispose()
    }
    catch {
        $pingResult = $false
        $responseTime = $null
    }

    if ($pingResult) {
        $onlineCount++
        $status = "Online"

        # DNS resolution
        $hostname = ""
        if ($ResolveDNS) {
            try {
                $dnsResult = [System.Net.Dns]::GetHostEntry($ipAddress)
                $hostname = $dnsResult.HostName
            }
            catch {
                $hostname = "Unable to resolve"
            }
        }

        # Port scan on online hosts
        $openPorts = @()
        foreach ($port in $commonPorts.Keys | Sort-Object) {
            if (Test-TcpPort -IP $ipAddress -Port $port) {
                $openPorts += "$port/$($commonPorts[$port])"
            }
        }
        $openPortsStr = if ($openPorts.Count -gt 0) { $openPorts -join ", " } else { "None detected" }

        # Display
        Write-Host "  $ipAddress" -ForegroundColor Green -NoNewline
        Write-Host " - Online" -ForegroundColor Green -NoNewline
        Write-Host " (${responseTime}ms)" -ForegroundColor White -NoNewline
        if ($ResolveDNS -and $hostname) {
            Write-Host " [$hostname]" -ForegroundColor Cyan -NoNewline
        }
        Write-Host ""
        if ($openPorts.Count -gt 0) {
            Write-Host "    Open ports: $openPortsStr" -ForegroundColor Yellow
        }

        $allResults += [PSCustomObject]@{
            IPAddress    = $ipAddress
            Status       = $status
            ResponseTime = $responseTime
            Hostname     = $hostname
            OpenPorts    = $openPortsStr
        }
    }
    else {
        $offlineCount++
    }
}

Write-Progress -Activity "Scanning Network" -Completed

# Summary
Write-Host "`n=== Discovery Summary ===" -ForegroundColor Green
Write-Host "  Subnet scanned:   $Subnet.$StartRange - $Subnet.$EndRange" -ForegroundColor Cyan
Write-Host "  Total IPs scanned: $totalIPs" -ForegroundColor White
Write-Host "  Online:            $onlineCount" -ForegroundColor Green
Write-Host "  Offline:           $offlineCount" -ForegroundColor Red

if ($allResults.Count -gt 0) {
    Write-Host "`n  Discovered Devices:" -ForegroundColor Cyan
    foreach ($device in $allResults) {
        $hostInfo = if ($device.Hostname) { " ($($device.Hostname))" } else { "" }
        Write-Host "    $($device.IPAddress)$hostInfo" -ForegroundColor Green
    }
}
else {
    Write-Host "`n  No online devices found in the specified range." -ForegroundColor Yellow
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
