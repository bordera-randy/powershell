<#
.SYNOPSIS
    Tests SSH/SFTP server connectivity and reads the SSH banner.

.DESCRIPTION
    Uses TCP to connect to port 22 (or specified port) and reads the server banner
    for quick validation that SSH/SFTP is reachable.

.PARAMETER Host
    Target host or IP.

.PARAMETER Port
    SSH port (default: 22).

.PARAMETER TimeoutSeconds
    Connection timeout in seconds (default: 5).

.PARAMETER OutputDirectory
    Directory to write log files (default: <script>\logs).

.EXAMPLE
    .\Test-SftpConnection.ps1 -Host "sftp.example.com"

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Host,

    [Parameter(Mandatory = $false)]
    [int]$Port = 22,

    [Parameter(Mandatory = $false)]
    [int]$TimeoutSeconds = 5,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs")
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Test-SftpConnection_$timestamp.log"

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

Write-Log "Testing SSH/SFTP connectivity to $Host:$Port" "INFO"

try {
    $client = New-Object System.Net.Sockets.TcpClient
    $async = $client.BeginConnect($Host, $Port, $null, $null)

    if (-not $async.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds($TimeoutSeconds))) {
        $client.Close()
        Write-Log "Connection timed out" "ERROR"
        exit 1
    }

    $client.EndConnect($async)
    Write-Log "TCP connection established" "INFO"

    $stream = $client.GetStream()
    $buffer = New-Object byte[] 256
    $read = $stream.Read($buffer, 0, $buffer.Length)
    $banner = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $read).Trim()

    if ($banner) {
        Write-Log "SSH banner: $banner" "INFO"
    } else {
        Write-Log "No banner received" "WARN"
    }

    $stream.Close()
    $client.Close()
    Write-Log "Connection test completed" "INFO"
}
catch {
    Write-Log "Connection test failed: $_" "ERROR"
    throw
}
