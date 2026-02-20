<#
.SYNOPSIS
    Exports and archives event logs.

.DESCRIPTION
    Exports specified Windows Event Logs to CSV and/or EVTX files for one or
    more computers. Optionally compresses the exported files into a zip archive.
    Shows progress during export and provides a summary of exported files with
    sizes.

.PARAMETER ComputerName
    Target computer name (default: localhost).

.PARAMETER LogName
    One or more event log names to export (default: Application, System, Security).

.PARAMETER Hours
    Number of hours of events to export (default: 24).

.PARAMETER OutputDirectory
    Directory to write exported files (default: ./logs).

.PARAMETER Format
    Output format: CSV, EVTX, or Both (default: CSV).

.PARAMETER CompressArchive
    Creates a zip archive of all exported files.

.EXAMPLE
    .\Export-EventLogs.ps1
    Exports the last 24 hours of Application, System, and Security logs to CSV.

.EXAMPLE
    .\Export-EventLogs.ps1 -LogName "Application","System" -Hours 48 -Format Both
    Exports last 48 hours of Application and System logs in both CSV and EVTX format.

.EXAMPLE
    .\Export-EventLogs.ps1 -CompressArchive -OutputDirectory "C:\Exports"
    Exports logs to CSV and creates a zip archive in the specified directory.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Requires: Administrator privileges for Security log export
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ComputerName = "localhost",

    [Parameter(Mandatory = $false)]
    [string[]]$LogName = @("Application", "System", "Security"),

    [Parameter(Mandatory = $false)]
    [int]$Hours = 24,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path "." "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("CSV", "EVTX", "Both")]
    [string]$Format = "CSV",

    [Parameter(Mandatory = $false)]
    [switch]$CompressArchive
)

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Event Log Export ===" -ForegroundColor Green
Write-Host "  Computer:  $ComputerName" -ForegroundColor Cyan
Write-Host "  Logs:      $($LogName -join ', ')" -ForegroundColor Cyan
Write-Host "  Hours:     $Hours" -ForegroundColor Cyan
Write-Host "  Format:    $Format" -ForegroundColor Cyan
Write-Host "  Output:    $OutputDirectory" -ForegroundColor Cyan
Write-Host "  Compress:  $(if ($CompressArchive) { 'Yes' } else { 'No' })" -ForegroundColor Cyan

# Create output directory if missing
if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    Write-Host "  Created output directory: $OutputDirectory" -ForegroundColor Gray
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$startTime = (Get-Date).AddHours(-$Hours)
$exportedFiles = @()
$totalLogs = $LogName.Count
$currentLog = 0

foreach ($log in $LogName) {
    $currentLog++
    $pct = [math]::Round(($currentLog / $totalLogs) * 100)
    Write-Progress -Activity "Exporting Event Logs" -Status "Processing $log ($currentLog of $totalLogs)" -PercentComplete $pct

    Write-Host "`nExporting $log log..." -ForegroundColor Cyan

    # --- CSV Export ---
    if ($Format -eq "CSV" -or $Format -eq "Both") {
        try {
            $csvPath = Join-Path $OutputDirectory "${ComputerName}_${log}_$timestamp.csv"

            $events = Get-WinEvent -ComputerName $ComputerName -FilterHashtable @{
                LogName   = $log
                StartTime = $startTime
            } -ErrorAction Stop

            if ($events -and $events.Count -gt 0) {
                $events | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
                    Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

                $fileSize = (Get-Item $csvPath).Length
                $fileSizeFormatted = if ($fileSize -ge 1MB) {
                    "{0:N2} MB" -f ($fileSize / 1MB)
                }
                else {
                    "{0:N2} KB" -f ($fileSize / 1KB)
                }

                Write-Host "  CSV: $csvPath ($fileSizeFormatted, $($events.Count) events)" -ForegroundColor Green

                $exportedFiles += [PSCustomObject]@{
                    LogName  = $log
                    Format   = "CSV"
                    FilePath = $csvPath
                    FileSize = $fileSizeFormatted
                    Events   = $events.Count
                }
            }
            else {
                Write-Host "  No events found in $log for the specified time range." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  Error exporting $log to CSV: $_" -ForegroundColor Red
        }
    }

    # --- EVTX Export ---
    if ($Format -eq "EVTX" -or $Format -eq "Both") {
        try {
            $evtxPath = Join-Path $OutputDirectory "${ComputerName}_${log}_$timestamp.evtx"

            # Use wevtutil to export the log
            $startTimeStr = $startTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")
            $query = "*[System[TimeCreated[@SystemTime>='$startTimeStr']]]"
            wevtutil epl $log $evtxPath /q:"$query" /ow:true 2>&1 | Out-Null

            if (Test-Path $evtxPath) {
                $fileSize = (Get-Item $evtxPath).Length
                $fileSizeFormatted = if ($fileSize -ge 1MB) {
                    "{0:N2} MB" -f ($fileSize / 1MB)
                }
                else {
                    "{0:N2} KB" -f ($fileSize / 1KB)
                }

                Write-Host "  EVTX: $evtxPath ($fileSizeFormatted)" -ForegroundColor Green

                $exportedFiles += [PSCustomObject]@{
                    LogName  = $log
                    Format   = "EVTX"
                    FilePath = $evtxPath
                    FileSize = $fileSizeFormatted
                    Events   = "N/A"
                }
            }
            else {
                Write-Host "  EVTX export produced no output for $log." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  Error exporting $log to EVTX: $_" -ForegroundColor Red
        }
    }
}

Write-Progress -Activity "Exporting Event Logs" -Completed

# --- Compress Archive ---
if ($CompressArchive -and $exportedFiles.Count -gt 0) {
    Write-Host "`nCompressing exported files..." -ForegroundColor Cyan

    try {
        $archivePath = Join-Path $OutputDirectory "${ComputerName}_EventLogs_$timestamp.zip"
        $filesToCompress = $exportedFiles | ForEach-Object { $_.FilePath }

        Compress-Archive -Path $filesToCompress -DestinationPath $archivePath -Force

        $archiveSize = (Get-Item $archivePath).Length
        $archiveSizeFormatted = if ($archiveSize -ge 1MB) {
            "{0:N2} MB" -f ($archiveSize / 1MB)
        }
        else {
            "{0:N2} KB" -f ($archiveSize / 1KB)
        }

        Write-Host "  Archive created: $archivePath ($archiveSizeFormatted)" -ForegroundColor Green
    }
    catch {
        Write-Host "  Error creating archive: $_" -ForegroundColor Red
    }
}

# --- Summary ---
Write-Host "`n=== Export Summary ===" -ForegroundColor Green
Write-Host "  Computer:       $ComputerName" -ForegroundColor Cyan
Write-Host "  Files exported: $($exportedFiles.Count)" -ForegroundColor Cyan

if ($exportedFiles.Count -gt 0) {
    Write-Host "`n  Exported Files:" -ForegroundColor Yellow
    foreach ($file in $exportedFiles) {
        Write-Host "    $($file.LogName) ($($file.Format)): $($file.FileSize)" -ForegroundColor White -NoNewline
        if ($file.Events -ne "N/A") {
            Write-Host " - $($file.Events) events" -ForegroundColor Gray
        }
        else {
            Write-Host "" 
        }
    }
}

Write-Host "`n=== Export Complete ===" -ForegroundColor Green
