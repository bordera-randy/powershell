<#
.SYNOPSIS
    Searches error logs across servers for specific patterns.

.DESCRIPTION
    Searches both Windows Event Logs and text-based log files on one or more
    computers. For event logs, searches Application and System logs for error
    entries. For file-based logs, uses Select-String with configurable context
    lines. Results are grouped by source with matching text highlighted.

.PARAMETER ComputerName
    One or more computer names to query (default: localhost).

.PARAMETER LogPath
    One or more file paths to text-based log files to search.

.PARAMETER Pattern
    Regex pattern to search for in log entries.

.PARAMETER Hours
    Number of hours to look back in the event log (default: 24).

.PARAMETER Context
    Number of lines of context to show around each match (default: 2).

.PARAMETER ExportPath
    File path for CSV export. When omitted results are displayed only.

.EXAMPLE
    .\Search-ErrorLogs.ps1 -Pattern "OutOfMemory"
    Searches event logs on localhost for OutOfMemory errors in the last 24 hours.

.EXAMPLE
    .\Search-ErrorLogs.ps1 -ComputerName "Server01" -Pattern "timeout" -Hours 48
    Searches for timeout errors on Server01 over the last 48 hours.

.EXAMPLE
    .\Search-ErrorLogs.ps1 -LogPath "C:\Logs\app.log","C:\Logs\web.log" -Pattern "Exception" -Context 5
    Searches text log files for Exception with 5 lines of context.

.EXAMPLE
    .\Search-ErrorLogs.ps1 -Pattern "error" -ExportPath "C:\Reports\errors.csv"
    Searches event logs and exports results to CSV.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$ComputerName = @("localhost"),

    [Parameter(Mandatory = $false)]
    [string[]]$LogPath,

    [Parameter(Mandatory = $true)]
    [string]$Pattern,

    [Parameter(Mandatory = $false)]
    [int]$Hours = 24,

    [Parameter(Mandatory = $false)]
    [int]$Context = 2,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Error Log Search ===" -ForegroundColor Green
Write-Host "  Pattern:   $Pattern" -ForegroundColor Cyan
Write-Host "  Hours:     $Hours" -ForegroundColor Cyan
Write-Host "  Context:   $Context line(s)" -ForegroundColor Cyan
Write-Host "  Target(s): $($ComputerName -join ', ')" -ForegroundColor Cyan
if ($LogPath) {
    Write-Host "  Log files: $($LogPath -join ', ')" -ForegroundColor Cyan
}

$startTime = (Get-Date).AddHours(-$Hours)
$allResults = @()

foreach ($computer in $ComputerName) {
    # ------------------------------------------------------------------
    # Search Windows Event Logs (Application and System)
    # ------------------------------------------------------------------
    foreach ($logName in @('Application', 'System')) {
        Write-Host "`nSearching $logName event log on $computer..." -ForegroundColor Cyan

        try {
            $events = Get-WinEvent -ComputerName $computer -FilterHashtable @{
                LogName   = $logName
                Level     = 2  # Error
                StartTime = $startTime
            } -ErrorAction SilentlyContinue

            if (-not $events) {
                Write-Host "  No error events found in $logName." -ForegroundColor Gray
                continue
            }

            $matchedEvents = $events | Where-Object {
                $_.Message -match $Pattern -or $_.ProviderName -match $Pattern
            }

            if (-not $matchedEvents -or $matchedEvents.Count -eq 0) {
                Write-Host "  No events matching pattern '$Pattern' in $logName." -ForegroundColor Gray
                continue
            }

            Write-Host "  Found $($matchedEvents.Count) matching event(s)" -ForegroundColor Yellow

            # Group by source
            $grouped = $matchedEvents | Group-Object -Property ProviderName | Sort-Object Count -Descending
            foreach ($group in $grouped) {
                Write-Host "`n  --- Source: $($group.Name) ($($group.Count) match(es)) ---" -ForegroundColor Yellow
                foreach ($evt in ($group.Group | Select-Object -First 10)) {
                    Write-Host "    $($evt.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray -NoNewline
                    Write-Host " [ID: $($evt.Id)]" -ForegroundColor White

                    # Highlight matching text in message
                    $msgLines = ($evt.Message -split "`n") | Select-Object -First 5
                    foreach ($line in $msgLines) {
                        if ($line -match $Pattern) {
                            Write-Host "      $line" -ForegroundColor Red
                        }
                        else {
                            Write-Host "      $line" -ForegroundColor Gray
                        }
                    }
                }
            }

            # Collect results
            foreach ($evt in $matchedEvents) {
                $allResults += [PSCustomObject]@{
                    ComputerName = $computer
                    Source       = "EventLog:$logName"
                    Provider     = $evt.ProviderName
                    EventID      = $evt.Id
                    TimeCreated  = $evt.TimeCreated
                    Message      = ($evt.Message -replace "`r`n", " " -replace "`n", " ")
                    MatchPattern = $Pattern
                }
            }
        }
        catch {
            Write-Host "  Error searching $logName on $computer`: $_" -ForegroundColor Red
        }
    }

    # ------------------------------------------------------------------
    # Search text-based log files
    # ------------------------------------------------------------------
    if ($LogPath) {
        foreach ($path in $LogPath) {
            Write-Host "`nSearching file: $path on $computer..." -ForegroundColor Cyan

            try {
                $fullPath = if ($computer -eq "localhost" -or $computer -eq $env:COMPUTERNAME) {
                    $path
                }
                else {
                    # Convert local path to UNC for remote access
                    "\\$computer\" + ($path -replace ':', '$')
                }

                if (-not (Test-Path $fullPath)) {
                    Write-Host "  File not found: $fullPath" -ForegroundColor Yellow
                    continue
                }

                $matches = Select-String -Path $fullPath -Pattern $Pattern -Context $Context -ErrorAction Stop

                if (-not $matches -or $matches.Count -eq 0) {
                    Write-Host "  No matches found in $path." -ForegroundColor Gray
                    continue
                }

                Write-Host "  Found $($matches.Count) match(es)" -ForegroundColor Yellow

                foreach ($match in $matches) {
                    Write-Host "`n    Line $($match.LineNumber):" -ForegroundColor White

                    # Pre-context
                    if ($match.Context.PreContext) {
                        foreach ($preLine in $match.Context.PreContext) {
                            Write-Host "      $preLine" -ForegroundColor Gray
                        }
                    }

                    # Matched line (highlighted)
                    Write-Host "    > $($match.Line)" -ForegroundColor Red

                    # Post-context
                    if ($match.Context.PostContext) {
                        foreach ($postLine in $match.Context.PostContext) {
                            Write-Host "      $postLine" -ForegroundColor Gray
                        }
                    }
                }

                # Collect results
                foreach ($match in $matches) {
                    $allResults += [PSCustomObject]@{
                        ComputerName = $computer
                        Source       = "File:$path"
                        Provider     = (Split-Path $path -Leaf)
                        EventID      = $null
                        TimeCreated  = (Get-Item $fullPath).LastWriteTime
                        Message      = $match.Line
                        MatchPattern = $Pattern
                    }
                }
            }
            catch {
                Write-Host "  Error searching $path on $computer`: $_" -ForegroundColor Red
            }
        }
    }
}

# --- Summary ---
Write-Host "`n=== Search Summary ===" -ForegroundColor Green
Write-Host "  Total matches: $($allResults.Count)" -ForegroundColor Cyan

if ($allResults.Count -gt 0) {
    $bySource = $allResults | Group-Object -Property Source | Sort-Object Count -Descending
    Write-Host "`n  Matches by source:" -ForegroundColor Yellow
    foreach ($group in $bySource) {
        Write-Host "    $($group.Name): $($group.Count)" -ForegroundColor White
    }
}

# --- Export ---
if ($ExportPath -and $allResults.Count -gt 0) {
    try {
        $exportDir = Split-Path -Path $ExportPath -Parent
        if ($exportDir -and -not (Test-Path $exportDir)) {
            New-Item -Path $exportDir -ItemType Directory -Force | Out-Null
        }
        $allResults | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
        Write-Host "`n  CSV exported: $ExportPath" -ForegroundColor Green
    }
    catch {
        Write-Host "`n  Failed to export CSV: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Search Complete ===" -ForegroundColor Green
