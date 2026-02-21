<#
.SYNOPSIS
    Checks if servers need a reboot.

.DESCRIPTION
    Queries multiple reboot-pending indicators on one or more computers to
    determine whether a restart is required. Checks Component Based Servicing,
    Windows Update, Pending File Rename Operations, SCCM Client, and pending
    computer rename. Results are color-coded and a summary of servers needing
    a reboot is displayed.

.PARAMETER ComputerName
    One or more computer names to query (default: localhost).

.PARAMETER ExportPath
    File path for CSV export. When omitted results are displayed only.

.EXAMPLE
    .\Get-RebootPending.ps1
    Checks the local computer for pending reboot indicators.

.EXAMPLE
    .\Get-RebootPending.ps1 -ComputerName "Server01","Server02","Server03"
    Checks multiple servers for pending reboots.

.EXAMPLE
    .\Get-RebootPending.ps1 -ComputerName "Server01" -ExportPath "C:\Reports\reboot.csv"
    Checks Server01 and exports results to CSV.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$ComputerName = @("localhost"),

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# ---------------------------------------------------------------------------
# Helper: check reboot indicators on a single computer
# ---------------------------------------------------------------------------
function Test-RebootPending {
    param([string]$Computer)

    $result = [PSCustomObject]@{
        ComputerName              = $Computer
        ComponentBasedServicing   = $false
        WindowsUpdate             = $false
        PendingFileRename         = $false
        SCCMClient                = $false
        PendingComputerRename     = $false
        RebootPending             = $false
        TriggerSource             = @()
        CheckedAt                 = Get-Date
    }

    try {
        # Component Based Servicing
        try {
            $cbsKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
            $cbs = $cbsKey.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')
            if ($cbs) {
                $result.ComponentBasedServicing = $true
                $result.TriggerSource += "Component Based Servicing"
                $cbs.Close()
            }
            $cbsKey.Close()
        }
        catch {
            Write-Verbose "  CBS check failed on $Computer`: $_"
        }

        # Windows Update
        try {
            $wuKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
            $wu = $wuKey.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
            if ($wu) {
                $result.WindowsUpdate = $true
                $result.TriggerSource += "Windows Update"
                $wu.Close()
            }
            $wuKey.Close()
        }
        catch {
            Write-Verbose "  WU check failed on $Computer`: $_"
        }

        # Pending File Rename Operations
        try {
            $pfrKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
            $pfr = $pfrKey.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager')
            if ($pfr) {
                $pfrValue = $pfr.GetValue('PendingFileRenameOperations')
                if ($pfrValue) {
                    $result.PendingFileRename = $true
                    $result.TriggerSource += "Pending File Rename"
                }
                $pfr.Close()
            }
            $pfrKey.Close()
        }
        catch {
            Write-Verbose "  PFR check failed on $Computer`: $_"
        }

        # SCCM Client (WMI)
        try {
            $sccm = Invoke-CimMethod -ComputerName $Computer -Namespace 'root\ccm\ClientSDK' `
                -ClassName CCM_ClientUtilities -MethodName DetermineIfRebootPending -ErrorAction Stop
            if ($sccm.RebootPending -or $sccm.IsHardRebootPending) {
                $result.SCCMClient = $true
                $result.TriggerSource += "SCCM Client"
            }
        }
        catch {
            Write-Verbose "  SCCM check not available on $Computer`: $_"
        }

        # Pending Computer Rename
        try {
            $renKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
            $activeNameKey = $renKey.OpenSubKey('SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName')
            $pendingNameKey = $renKey.OpenSubKey('SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName')
            if ($activeNameKey -and $pendingNameKey) {
                $activeName = $activeNameKey.GetValue('ComputerName')
                $pendingName = $pendingNameKey.GetValue('ComputerName')
                if ($activeName -ne $pendingName) {
                    $result.PendingComputerRename = $true
                    $result.TriggerSource += "Pending Computer Rename"
                }
                $activeNameKey.Close()
                $pendingNameKey.Close()
            }
            $renKey.Close()
        }
        catch {
            Write-Verbose "  Computer rename check failed on $Computer`: $_"
        }

        # Determine overall status
        $result.RebootPending = $result.ComponentBasedServicing -or
                                $result.WindowsUpdate -or
                                $result.PendingFileRename -or
                                $result.SCCMClient -or
                                $result.PendingComputerRename
        $result.TriggerSource = $result.TriggerSource -join '; '
    }
    catch {
        Write-Host "  Error checking $Computer`: $_" -ForegroundColor Red
    }

    return $result
}

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Reboot Pending Check ===" -ForegroundColor Green
Write-Host "  Target(s): $($ComputerName -join ', ')" -ForegroundColor Cyan

$allResults = @()

foreach ($computer in $ComputerName) {
    Write-Host "`nChecking $computer..." -ForegroundColor Cyan

    $result = Test-RebootPending -Computer $computer
    $allResults += $result

    $statusColor = if ($result.RebootPending) { "Red" } else { "Green" }
    $statusText  = if ($result.RebootPending) { "REBOOT PENDING" } else { "No reboot needed" }

    Write-Host "  Status: $statusText" -ForegroundColor $statusColor

    if ($result.RebootPending) {
        Write-Host "  Triggered by: $($result.TriggerSource)" -ForegroundColor Yellow
        Write-Host "    Component Based Servicing : $($result.ComponentBasedServicing)" -ForegroundColor White
        Write-Host "    Windows Update            : $($result.WindowsUpdate)" -ForegroundColor White
        Write-Host "    Pending File Rename       : $($result.PendingFileRename)" -ForegroundColor White
        Write-Host "    SCCM Client               : $($result.SCCMClient)" -ForegroundColor White
        Write-Host "    Pending Computer Rename   : $($result.PendingComputerRename)" -ForegroundColor White
    }

    Write-Host "  Checked at: $($result.CheckedAt.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
}

# --- Summary ---
$pendingCount = ($allResults | Where-Object { $_.RebootPending }).Count
$okCount      = ($allResults | Where-Object { -not $_.RebootPending }).Count

Write-Host "`n=== Reboot Pending Summary ===" -ForegroundColor Green
Write-Host "  Total servers checked: $($allResults.Count)" -ForegroundColor Cyan
Write-Host "  Reboot pending:       $pendingCount" -ForegroundColor $(if ($pendingCount -gt 0) { "Red" } else { "Green" })
Write-Host "  No reboot needed:     $okCount" -ForegroundColor Green

if ($pendingCount -gt 0) {
    Write-Host "`n  Servers needing reboot:" -ForegroundColor Yellow
    $allResults | Where-Object { $_.RebootPending } | ForEach-Object {
        Write-Host "    - $($_.ComputerName) ($($_.TriggerSource))" -ForegroundColor Red
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

Write-Host "`n=== Check Complete ===" -ForegroundColor Green
