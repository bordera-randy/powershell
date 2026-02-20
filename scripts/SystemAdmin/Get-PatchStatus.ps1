<#
.SYNOPSIS
    Checks Windows Update / patch status on servers.

.DESCRIPTION
    Queries installed hotfixes using Get-HotFix and reports patch status for one
    or more computers. Shows KB article, description, installed date, and installed
    by. Highlights servers that have not been patched recently and provides a
    color-coded summary based on the number of days since the last patch.

.PARAMETER ComputerName
    One or more computer names to query (default: localhost).

.PARAMETER DaysBack
    Number of days to look back for installed patches (default: 30).

.PARAMETER ExportPath
    File path for CSV export. When omitted results are displayed only.

.EXAMPLE
    .\Get-PatchStatus.ps1
    Shows patches installed in the last 30 days on the local computer.

.EXAMPLE
    .\Get-PatchStatus.ps1 -ComputerName "Server01","Server02" -DaysBack 60
    Shows patches installed in the last 60 days on Server01 and Server02.

.EXAMPLE
    .\Get-PatchStatus.ps1 -ExportPath "C:\Reports\patches.csv"
    Exports patch status to CSV.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$ComputerName = @("localhost"),

    [Parameter(Mandatory = $false)]
    [int]$DaysBack = 30,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Patch Status Report ===" -ForegroundColor Green
Write-Host "  Time range: Last $DaysBack day(s)" -ForegroundColor Cyan
Write-Host "  Target(s):  $($ComputerName -join ', ')" -ForegroundColor Cyan

$cutoffDate = (Get-Date).AddDays(-$DaysBack)
$allResults = @()

foreach ($computer in $ComputerName) {
    Write-Host "`nChecking patch status on $computer..." -ForegroundColor Cyan

    try {
        $hotfixes = Get-HotFix -ComputerName $computer -ErrorAction Stop |
            Sort-Object -Property InstalledOn -Descending -ErrorAction SilentlyContinue

        if (-not $hotfixes -or $hotfixes.Count -eq 0) {
            Write-Host "  No hotfixes found on $computer." -ForegroundColor Yellow
            continue
        }

        # Determine last patch date
        $lastPatchDate = ($hotfixes | Where-Object { $_.InstalledOn } |
            Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn
        $daysSinceLastPatch = if ($lastPatchDate) { ((Get-Date) - $lastPatchDate).Days } else { -1 }

        # Color code based on days since last patch
        $statusColor = if ($daysSinceLastPatch -gt 60) { "Red" }
                       elseif ($daysSinceLastPatch -gt 30) { "Yellow" }
                       else { "Green" }

        # Filter to patches within the DaysBack window
        $recentPatches = $hotfixes | Where-Object {
            $_.InstalledOn -and $_.InstalledOn -ge $cutoffDate
        }

        Write-Host "`n  --- Patches installed in last $DaysBack day(s) ---" -ForegroundColor Yellow
        if ($recentPatches) {
            foreach ($patch in $recentPatches) {
                $patchAge = ((Get-Date) - $patch.InstalledOn).Days
                $patchColor = if ($patchAge -gt 30) { "Yellow" } else { "White" }

                Write-Host "  $($patch.HotFixID)" -ForegroundColor $patchColor -NoNewline
                Write-Host " | $($patch.Description)" -ForegroundColor White -NoNewline
                Write-Host " | Installed: $($patch.InstalledOn.ToString('yyyy-MM-dd'))" -ForegroundColor Gray -NoNewline
                Write-Host " | By: $($patch.InstalledBy)" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "  No patches installed in the last $DaysBack day(s)." -ForegroundColor Yellow
        }

        # Build result objects for all hotfixes
        foreach ($patch in $hotfixes) {
            $allResults += [PSCustomObject]@{
                ComputerName    = $computer
                HotFixID        = $patch.HotFixID
                Description     = $patch.Description
                InstalledOn     = $patch.InstalledOn
                InstalledBy     = $patch.InstalledBy
                DaysSinceInstall = if ($patch.InstalledOn) { ((Get-Date) - $patch.InstalledOn).Days } else { $null }
            }
        }

        # Summary for this computer
        Write-Host "`n  Summary for $computer" -ForegroundColor Cyan
        Write-Host "    Total patches:        $($hotfixes.Count)" -ForegroundColor White
        Write-Host "    Last patch date:      $(if ($lastPatchDate) { $lastPatchDate.ToString('yyyy-MM-dd') } else { 'Unknown' })" -ForegroundColor White
        Write-Host "    Days since last patch: $daysSinceLastPatch" -ForegroundColor $statusColor
    }
    catch {
        Write-Host "  Error querying $computer`: $_" -ForegroundColor Red
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

Write-Host "`n=== Patch Status Complete ===" -ForegroundColor Green
