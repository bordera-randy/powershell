<#
.SYNOPSIS
    Installs pending Windows updates.

.DESCRIPTION
    Uses the Windows Update COM object (Microsoft.Update.Session) to search for,
    download, and install pending updates. Supports filtering by category
    (Security, Critical, or All). Shows available updates before installation and
    prompts for confirmation. Displays a progress bar during download and install.
    All actions are logged to the console.

    WARNING: This script modifies system state by installing updates and
    optionally rebooting. It should be thoroughly tested in a non-production
    environment before use on production servers.

.PARAMETER ComputerName
    Target computer name (default: localhost).

.PARAMETER Category
    Update category filter: Security, Critical, or All (default: Security).

.PARAMETER RebootIfNeeded
    Automatically reboot the computer after installation if a reboot is required.

.PARAMETER WhatIf
    Show what updates would be installed without actually installing them.

.EXAMPLE
    .\Install-WindowsUpdates.ps1
    Searches for and installs pending Security updates on the local computer.

.EXAMPLE
    .\Install-WindowsUpdates.ps1 -Category All -RebootIfNeeded
    Installs all pending updates and reboots if needed.

.EXAMPLE
    .\Install-WindowsUpdates.ps1 -WhatIf
    Shows which Security updates would be installed without making changes.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Requires: Administrator privileges
    WARNING: Test in a non-production environment before deploying to production servers.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$ComputerName = "localhost",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Security", "Critical", "All")]
    [string]$Category = "Security",

    [Parameter(Mandatory = $false)]
    [switch]$RebootIfNeeded
)

# ---------------------------------------------------------------------------
# Helper: log actions to console
# ---------------------------------------------------------------------------
function Write-UpdateLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
        "SUCCESS" { "Green" }
        default   { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Windows Update Installation ===" -ForegroundColor Green
Write-Host "  WARNING: This script installs updates and may reboot the system." -ForegroundColor Red
Write-Host "  WARNING: Test in a non-production environment first.`n" -ForegroundColor Red
Write-Host "  Target:   $ComputerName" -ForegroundColor Cyan
Write-Host "  Category: $Category" -ForegroundColor Cyan
Write-Host "  Reboot:   $(if ($RebootIfNeeded) { 'Yes' } else { 'No' })" -ForegroundColor Cyan
Write-Host "  WhatIf:   $(if ($WhatIfPreference) { 'Yes' } else { 'No' })" -ForegroundColor Cyan

try {
    # Create Windows Update session
    Write-UpdateLog "Creating Windows Update session..."
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    # Search for pending updates
    Write-UpdateLog "Searching for pending updates (this may take a few minutes)..."
    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")

    if ($searchResult.Updates.Count -eq 0) {
        Write-UpdateLog "No pending updates found." "SUCCESS"
        Write-Host "`n=== Update Complete ===" -ForegroundColor Green
        exit 0
    }

    # Filter by category
    $filteredUpdates = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($update in $searchResult.Updates) {
        $include = $false
        switch ($Category) {
            "All" { $include = $true }
            "Security" {
                foreach ($cat in $update.Categories) {
                    if ($cat.Name -match "Security") { $include = $true; break }
                }
            }
            "Critical" {
                foreach ($cat in $update.Categories) {
                    if ($cat.Name -match "Critical") { $include = $true; break }
                }
            }
        }
        if ($include) {
            $filteredUpdates.Add($update) | Out-Null
        }
    }

    if ($filteredUpdates.Count -eq 0) {
        Write-UpdateLog "No updates matching category '$Category' found." "SUCCESS"
        Write-Host "`n=== Update Complete ===" -ForegroundColor Green
        exit 0
    }

    # Display available updates
    Write-Host "`n--- Available Updates ($($filteredUpdates.Count)) ---" -ForegroundColor Yellow
    $index = 1
    foreach ($update in $filteredUpdates) {
        $severity = if ($update.MsrcSeverity) { $update.MsrcSeverity } else { "N/A" }
        $size = [math]::Round($update.MaxDownloadSize / 1MB, 2)
        $severityColor = switch ($severity) {
            "Critical"  { "Red" }
            "Important" { "Yellow" }
            default     { "White" }
        }
        Write-Host "  [$index] " -ForegroundColor White -NoNewline
        Write-Host "$($update.Title)" -ForegroundColor White -NoNewline
        Write-Host " | Severity: $severity" -ForegroundColor $severityColor -NoNewline
        Write-Host " | Size: ${size} MB" -ForegroundColor Gray
        $index++
    }

    # WhatIf - stop here
    if ($WhatIfPreference) {
        Write-UpdateLog "WhatIf mode - no changes will be made." "WARN"
        Write-Host "`n=== Update Complete (WhatIf) ===" -ForegroundColor Green
        exit 0
    }

    # Prompt for confirmation
    Write-Host "`nProceed with installation of $($filteredUpdates.Count) update(s)? (Y/N): " -ForegroundColor Cyan -NoNewline
    $confirm = Read-Host
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-UpdateLog "Installation cancelled by user." "WARN"
        Write-Host "`n=== Update Cancelled ===" -ForegroundColor Yellow
        exit 0
    }

    # Accept EULAs
    foreach ($update in $filteredUpdates) {
        if (-not $update.EulaAccepted) {
            $update.AcceptEula()
        }
    }

    # Download updates
    Write-UpdateLog "Downloading updates..."
    $downloader = $updateSession.CreateUpdateDownloader()
    $downloader.Updates = $filteredUpdates

    $totalUpdates = $filteredUpdates.Count
    for ($i = 0; $i -lt $totalUpdates; $i++) {
        $pct = [math]::Round((($i + 1) / $totalUpdates) * 100)
        Write-Progress -Activity "Downloading Updates" -Status "$($i + 1) of $totalUpdates" -PercentComplete $pct
    }

    $downloadResult = $downloader.Download()
    Write-Progress -Activity "Downloading Updates" -Completed

    if ($downloadResult.ResultCode -eq 2) {
        Write-UpdateLog "All updates downloaded successfully." "SUCCESS"
    }
    else {
        Write-UpdateLog "Download completed with result code: $($downloadResult.ResultCode)" "WARN"
    }

    # Install updates
    Write-UpdateLog "Installing updates..."
    $installer = $updateSession.CreateUpdateInstaller()
    $installer.Updates = $filteredUpdates

    for ($i = 0; $i -lt $totalUpdates; $i++) {
        $pct = [math]::Round((($i + 1) / $totalUpdates) * 100)
        Write-Progress -Activity "Installing Updates" -Status "$($i + 1) of $totalUpdates" -PercentComplete $pct
    }

    $installResult = $installer.Install()
    Write-Progress -Activity "Installing Updates" -Completed

    # Display results
    Write-Host "`n--- Installation Results ---" -ForegroundColor Yellow
    for ($i = 0; $i -lt $filteredUpdates.Count; $i++) {
        $resultCode = $installResult.GetUpdateResult($i).ResultCode
        $resultText = switch ($resultCode) {
            0 { "Not Started" }
            1 { "In Progress" }
            2 { "Succeeded" }
            3 { "Succeeded With Errors" }
            4 { "Failed" }
            5 { "Aborted" }
            default { "Unknown ($resultCode)" }
        }
        $resultColor = if ($resultCode -eq 2) { "Green" } elseif ($resultCode -le 3) { "Yellow" } else { "Red" }
        Write-Host "  $($filteredUpdates.Item($i).Title): $resultText" -ForegroundColor $resultColor
    }

    Write-UpdateLog "Installation result code: $($installResult.ResultCode)"

    # Handle reboot
    if ($installResult.RebootRequired) {
        if ($RebootIfNeeded) {
            Write-UpdateLog "Reboot required. Rebooting in 30 seconds..." "WARN"
            shutdown /r /t 30 /c "Rebooting after Windows Update installation"
        }
        else {
            Write-Host "`n  A reboot is required to complete the installation." -ForegroundColor Yellow
            Write-Host "  Use -RebootIfNeeded to automatically reboot." -ForegroundColor Yellow
        }
    }
    else {
        Write-UpdateLog "No reboot required." "SUCCESS"
    }
}
catch {
    Write-UpdateLog "Error during update process: $_" "ERROR"
}

Write-Host "`n=== Update Complete ===" -ForegroundColor Green
