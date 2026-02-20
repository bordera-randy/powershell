<#
.SYNOPSIS
    Exports Windows Event Logs to EVTX and CSV with logging.

.DESCRIPTION
    Exports specified event logs to EVTX files and also exports recent entries
    (last N days) to CSV for quick analysis.

.PARAMETER LogName
    One or more log names to export (default: System, Application, Security).

.PARAMETER Days
    Number of days of events to export to CSV (default: 7).

.PARAMETER ComputerName
    Target computer name (default: local computer).

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.EXAMPLE
    .\Backup-EventLogs.ps1

.EXAMPLE
    .\Backup-EventLogs.ps1 -LogName System,Application -Days 3

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Requires: Administrator privileges for some logs (e.g., Security)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$LogName = @("System","Application","Security"),

    [Parameter(Mandatory = $false)]
    [int]$Days = 7,

    [Parameter(Mandatory = $false)]
    [string]$ComputerName = $env:COMPUTERNAME,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs")
)

# Create output directory if missing
if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Backup-EventLogs_$timestamp.log"

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

Write-Log "Starting event log export for $ComputerName" "INFO"
$startTime = (Get-Date).AddDays(-$Days)

foreach ($log in $LogName) {
    try {
        Write-Log "Exporting EVTX for $log" "INFO"
        $evtxPath = Join-Path $OutputDirectory "${ComputerName}_${log}_$timestamp.evtx"

        # Export the full log using wevtutil (handles large logs efficiently)
        wevtutil epl $log $evtxPath /ow:true
        Write-Log "Saved EVTX to $evtxPath" "INFO"

        Write-Log "Exporting last $Days days of $log to CSV" "INFO"
        $csvPath = Join-Path $OutputDirectory "${ComputerName}_${log}_$timestamp.csv"
        $events = Get-WinEvent -ComputerName $ComputerName -FilterHashtable @{ LogName = $log; StartTime = $startTime }
        $events | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
            Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV to $csvPath" "INFO"
    }
    catch {
        Write-Log "Failed to export $log. $_" "ERROR"
    }
}

Write-Log "Event log export complete" "INFO"
