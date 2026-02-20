<#
.SYNOPSIS
    Audits installed software across one or more machines.

.DESCRIPTION
    This script reads installed software information from both 32-bit and 64-bit
    registry uninstall keys. It displays software name, version, publisher, install
    date, install location, and estimated size. Results include a summary with total
    count and grouping by publisher. An optional wildcard filter can limit results
    to matching software names. Results can be exported to CSV.

.PARAMETER ComputerName
    One or more computer names to audit (default: localhost).

.PARAMETER Filter
    Wildcard pattern to filter software names (e.g., "Microsoft*" or "*Office*").

.PARAMETER ExportPath
    File path for CSV export. When omitted results are displayed only.

.EXAMPLE
    .\Audit-InstalledSoftware.ps1
    Lists all installed software on the local computer.

.EXAMPLE
    .\Audit-InstalledSoftware.ps1 -ComputerName "SERVER01","SERVER02"
    Lists installed software on multiple servers.

.EXAMPLE
    .\Audit-InstalledSoftware.ps1 -Filter "*Office*" -ExportPath "C:\Reports\software.csv"
    Lists software matching *Office* and exports to CSV.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$ComputerName = @("localhost"),

    [Parameter(Mandatory = $false)]
    [string]$Filter,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# ---------------------------------------------------------------------------
# Registry paths for installed software
# ---------------------------------------------------------------------------
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Installed Software Audit ===" -ForegroundColor Green
Write-Host "  Target computers: $($ComputerName -join ', ')" -ForegroundColor Cyan
if ($Filter) {
    Write-Host "  Filter: $Filter" -ForegroundColor Cyan
}

$allResults = @()

foreach ($computer in $ComputerName) {
    Write-Host "`n--- $computer ---" -ForegroundColor Yellow

    try {
        $software = @()

        if ($computer -eq "localhost" -or $computer -eq $env:COMPUTERNAME) {
            # Local computer
            foreach ($regPath in $registryPaths) {
                try {
                    $items = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue |
                        Where-Object { $_.DisplayName }
                    $software += $items
                }
                catch {
                    Write-Host "  Warning: Could not read $regPath" -ForegroundColor Yellow
                }
            }
        }
        else {
            # Remote computer
            try {
                $software = Invoke-Command -ComputerName $computer -ScriptBlock {
                    param($paths)
                    $results = @()
                    foreach ($regPath in $paths) {
                        try {
                            $items = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue |
                                Where-Object { $_.DisplayName }
                            $results += $items
                        }
                        catch { }
                    }
                    return $results
                } -ArgumentList (,$registryPaths) -ErrorAction Stop
            }
            catch {
                Write-Host "  Failed to connect to $computer`: $_" -ForegroundColor Red
                continue
            }
        }

        # Filter by name if specified
        if ($Filter) {
            $software = $software | Where-Object { $_.DisplayName -like $Filter }
        }

        # Remove duplicates by DisplayName + DisplayVersion
        $software = $software | Sort-Object DisplayName, DisplayVersion -Unique

        if ($software.Count -eq 0) {
            Write-Host "  No software found." -ForegroundColor Yellow
            continue
        }

        Write-Host "  Software found: $($software.Count)" -ForegroundColor Cyan

        foreach ($app in ($software | Sort-Object DisplayName)) {
            $sizeDisplay = if ($app.EstimatedSize) {
                "{0:N1} MB" -f ($app.EstimatedSize / 1024)
            } else { "N/A" }

            $installDate = if ($app.InstallDate) { $app.InstallDate } else { "N/A" }

            $result = [PSCustomObject]@{
                ComputerName    = $computer
                Name            = $app.DisplayName
                Version         = $app.DisplayVersion
                Publisher       = $app.Publisher
                InstallDate     = $installDate
                InstallLocation = $app.InstallLocation
                EstimatedSize   = $sizeDisplay
            }

            $allResults += $result

            Write-Host "    $($app.DisplayName)" -ForegroundColor White -NoNewline
            Write-Host " | v$($app.DisplayVersion)" -ForegroundColor Gray -NoNewline
            Write-Host " | $($app.Publisher)" -ForegroundColor Cyan -NoNewline
            Write-Host " | $sizeDisplay" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  Error auditing $computer`: $_" -ForegroundColor Red
    }
}

# --- Summary ---
Write-Host "`n=== Software Audit Summary ===" -ForegroundColor Green
Write-Host "  Computers audited:  $($ComputerName.Count)" -ForegroundColor Cyan
Write-Host "  Total software:     $($allResults.Count)" -ForegroundColor Cyan

Write-Host "`n  Top Publishers:" -ForegroundColor Yellow
$byPublisher = $allResults | Where-Object { $_.Publisher } |
    Group-Object -Property Publisher | Sort-Object Count -Descending | Select-Object -First 15

foreach ($group in $byPublisher) {
    Write-Host "    $($group.Name): $($group.Count) application(s)" -ForegroundColor Cyan
}

$perComputer = $allResults | Group-Object -Property ComputerName
Write-Host "`n  Per Computer:" -ForegroundColor Yellow
foreach ($group in $perComputer) {
    Write-Host "    $($group.Name): $($group.Count) application(s)" -ForegroundColor Cyan
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

Write-Host "`n=== Audit Complete ===" -ForegroundColor Green
