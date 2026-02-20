<#
.SYNOPSIS
    Finds stale and inactive Active Directory accounts.

.DESCRIPTION
    This script identifies user accounts (and optionally computer accounts) that have
    not logged in within a specified number of days. It displays account name, last
    logon date, days since last logon, password last set, account status, and OU.
    Accounts that have never logged in are highlighted. A summary with counts grouped
    by OU is provided. Results can be exported to CSV.

.PARAMETER DaysInactive
    Number of days since last logon to consider an account stale (default: 90).

.PARAMETER IncludeComputers
    Include computer accounts in the search.

.PARAMETER IncludeDisabled
    Include disabled accounts in the results.

.PARAMETER SearchBase
    Distinguished name of the OU to search (e.g., "OU=Users,DC=contoso,DC=com").
    Defaults to the domain root.

.PARAMETER ExportPath
    File path for CSV export. When omitted results are displayed only.

.EXAMPLE
    .\Find-StaleAccounts.ps1
    Finds user accounts inactive for 90+ days.

.EXAMPLE
    .\Find-StaleAccounts.ps1 -DaysInactive 60 -IncludeComputers
    Finds user and computer accounts inactive for 60+ days.

.EXAMPLE
    .\Find-StaleAccounts.ps1 -DaysInactive 120 -IncludeDisabled -ExportPath "C:\Reports\stale.csv"
    Finds stale accounts including disabled ones and exports to CSV.

.EXAMPLE
    .\Find-StaleAccounts.ps1 -SearchBase "OU=Staff,DC=contoso,DC=com" -DaysInactive 30
    Searches only the Staff OU for accounts inactive 30+ days.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$DaysInactive = 90,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeComputers,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeDisabled,

    [Parameter(Mandatory = $false)]
    [string]$SearchBase,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Stale Account Audit ===" -ForegroundColor Green
Write-Host "  Inactivity threshold: $DaysInactive day(s)" -ForegroundColor Cyan
Write-Host "  Include computers:    $IncludeComputers" -ForegroundColor Cyan
Write-Host "  Include disabled:     $IncludeDisabled" -ForegroundColor Cyan

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Host "  ActiveDirectory module loaded" -ForegroundColor Cyan
}
catch {
    Write-Host "  ERROR: ActiveDirectory module is not available. $_" -ForegroundColor Red
    exit 1
}

# Determine search base
if (-not $SearchBase) {
    $SearchBase = (Get-ADDomain).DistinguishedName
    Write-Host "  SearchBase: $SearchBase (domain root)" -ForegroundColor Cyan
}
else {
    Write-Host "  SearchBase: $SearchBase" -ForegroundColor Cyan
}

$cutoffDate = (Get-Date).AddDays(-$DaysInactive)
$allResults = @()
$neverLoggedIn = 0

# ---------------------------------------------------------------------------
# Query user accounts
# ---------------------------------------------------------------------------
Write-Host "`n--- Searching User Accounts ---" -ForegroundColor Yellow

try {
    $userFilter = if ($IncludeDisabled) { "*" } else { "Enabled -eq `$true" }

    $users = Get-ADUser -Filter $userFilter -SearchBase $SearchBase `
        -Properties LastLogonDate, PasswordLastSet, Enabled, WhenCreated, DistinguishedName `
        -ErrorAction Stop

    $staleUsers = $users | Where-Object {
        (-not $_.LastLogonDate) -or ($_.LastLogonDate -lt $cutoffDate)
    }

    Write-Host "  Total users checked: $($users.Count)" -ForegroundColor Cyan
    Write-Host "  Stale users found:   $($staleUsers.Count)" -ForegroundColor $(if ($staleUsers.Count -gt 0) { "Yellow" } else { "Green" })

    foreach ($user in $staleUsers) {
        $daysSinceLogon = if ($user.LastLogonDate) {
            [math]::Round(((Get-Date) - $user.LastLogonDate).TotalDays)
        } else { $null }

        $ou = ($user.DistinguishedName -split ",", 2)[1]

        $result = [PSCustomObject]@{
            AccountType    = "User"
            Name           = $user.SamAccountName
            DisplayName    = $user.Name
            LastLogonDate  = $user.LastLogonDate
            DaysSinceLogon = $daysSinceLogon
            PasswordLastSet = $user.PasswordLastSet
            AccountStatus  = if ($user.Enabled) { "Enabled" } else { "Disabled" }
            WhenCreated    = $user.WhenCreated
            OU             = $ou
        }

        $allResults += $result

        # Color-coded display
        if (-not $user.LastLogonDate) {
            $neverLoggedIn++
            Write-Host "    $($user.SamAccountName)" -ForegroundColor Red -NoNewline
            Write-Host " | NEVER LOGGED IN" -ForegroundColor Red -NoNewline
            Write-Host " | Created: $($user.WhenCreated.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
        }
        else {
            $color = if ($daysSinceLogon -ge 180) { "Red" }
                     elseif ($daysSinceLogon -ge 90) { "Yellow" }
                     else { "White" }
            Write-Host "    $($user.SamAccountName)" -ForegroundColor $color -NoNewline
            Write-Host " | Last logon: $($user.LastLogonDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray -NoNewline
            Write-Host " | $daysSinceLogon day(s) ago" -ForegroundColor $color
        }
    }
}
catch {
    Write-Host "  Error querying user accounts: $_" -ForegroundColor Red
}

# ---------------------------------------------------------------------------
# Query computer accounts (optional)
# ---------------------------------------------------------------------------
if ($IncludeComputers) {
    Write-Host "`n--- Searching Computer Accounts ---" -ForegroundColor Yellow

    try {
        $compFilter = if ($IncludeDisabled) { "*" } else { "Enabled -eq `$true" }

        $computers = Get-ADComputer -Filter $compFilter -SearchBase $SearchBase `
            -Properties LastLogonDate, PasswordLastSet, Enabled, WhenCreated, DistinguishedName `
            -ErrorAction Stop

        $staleComputers = $computers | Where-Object {
            (-not $_.LastLogonDate) -or ($_.LastLogonDate -lt $cutoffDate)
        }

        Write-Host "  Total computers checked: $($computers.Count)" -ForegroundColor Cyan
        Write-Host "  Stale computers found:   $($staleComputers.Count)" -ForegroundColor $(if ($staleComputers.Count -gt 0) { "Yellow" } else { "Green" })

        foreach ($comp in $staleComputers) {
            $daysSinceLogon = if ($comp.LastLogonDate) {
                [math]::Round(((Get-Date) - $comp.LastLogonDate).TotalDays)
            } else { $null }

            $ou = ($comp.DistinguishedName -split ",", 2)[1]

            $result = [PSCustomObject]@{
                AccountType     = "Computer"
                Name            = $comp.SamAccountName
                DisplayName     = $comp.Name
                LastLogonDate   = $comp.LastLogonDate
                DaysSinceLogon  = $daysSinceLogon
                PasswordLastSet = $comp.PasswordLastSet
                AccountStatus   = if ($comp.Enabled) { "Enabled" } else { "Disabled" }
                WhenCreated     = $comp.WhenCreated
                OU              = $ou
            }

            $allResults += $result

            if (-not $comp.LastLogonDate) {
                $neverLoggedIn++
                Write-Host "    $($comp.Name)" -ForegroundColor Red -NoNewline
                Write-Host " | NEVER LOGGED IN" -ForegroundColor Red -NoNewline
                Write-Host " | Created: $($comp.WhenCreated.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
            }
            else {
                $color = if ($daysSinceLogon -ge 180) { "Red" }
                         elseif ($daysSinceLogon -ge 90) { "Yellow" }
                         else { "White" }
                Write-Host "    $($comp.Name)" -ForegroundColor $color -NoNewline
                Write-Host " | Last logon: $($comp.LastLogonDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray -NoNewline
                Write-Host " | $daysSinceLogon day(s) ago" -ForegroundColor $color
            }
        }
    }
    catch {
        Write-Host "  Error querying computer accounts: $_" -ForegroundColor Red
    }
}

# --- Summary ---
Write-Host "`n=== Stale Account Summary ===" -ForegroundColor Green
Write-Host "  Total stale accounts:  $($allResults.Count)" -ForegroundColor Cyan

$staleUserCount = ($allResults | Where-Object { $_.AccountType -eq "User" }).Count
$staleCompCount = ($allResults | Where-Object { $_.AccountType -eq "Computer" }).Count
Write-Host "  Stale users:           $staleUserCount" -ForegroundColor Cyan
if ($IncludeComputers) {
    Write-Host "  Stale computers:       $staleCompCount" -ForegroundColor Cyan
}

Write-Host "  Never logged in:       $neverLoggedIn" -ForegroundColor $(if ($neverLoggedIn -gt 0) { "Red" } else { "Green" })

$enabledStale = ($allResults | Where-Object { $_.AccountStatus -eq "Enabled" }).Count
$disabledStale = ($allResults | Where-Object { $_.AccountStatus -eq "Disabled" }).Count
Write-Host "  Enabled (stale):       $enabledStale" -ForegroundColor Yellow
Write-Host "  Disabled (stale):      $disabledStale" -ForegroundColor Gray

# Counts by OU
Write-Host "`n  Stale Accounts by OU:" -ForegroundColor Yellow
$byOU = $allResults | Group-Object -Property OU | Sort-Object Count -Descending

foreach ($group in $byOU) {
    Write-Host "    $($group.Name): $($group.Count) account(s)" -ForegroundColor Cyan
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
