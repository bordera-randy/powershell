<#
.SYNOPSIS
    Finds all admin and privileged users across the Active Directory domain.

.DESCRIPTION
    This script enumerates membership of privileged AD groups such as Domain Admins,
    Enterprise Admins, Schema Admins, Administrators, Account Operators, Backup Operators,
    and Server Operators. Results are displayed with color coding and can be exported to
    CSV or JSON.

.PARAMETER ComputerName
    Domain controller to query (default: localhost).

.PARAMETER IncludeServiceAccounts
    Include service accounts (accounts whose name starts with svc- or ends with $).

.PARAMETER OutputPath
    Directory for export files (default: <script>\logs).

.PARAMETER ExportFormat
    Export format: CSV, JSON, or Both. When omitted results are displayed only.

.EXAMPLE
    .\Find-AdminUsers.ps1
    Lists all privileged users on the local domain.

.EXAMPLE
    .\Find-AdminUsers.ps1 -IncludeServiceAccounts -ExportFormat CSV
    Lists privileged users including service accounts and exports to CSV.

.EXAMPLE
    .\Find-AdminUsers.ps1 -ComputerName "DC01" -ExportFormat Both
    Queries DC01 and exports results in both CSV and JSON formats.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ComputerName = "localhost",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeServiceAccounts,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("CSV","JSON","Both")]
    [string]$ExportFormat
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputPath "Find-AdminUsers_$timestamp.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $logFile -Value $line

    switch ($Level) {
        "INFO"  { Write-Host $line -ForegroundColor Cyan }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "ERROR" { Write-Host $line -ForegroundColor Red }
    }
}

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Active Directory Privileged User Audit ===" -ForegroundColor Green
Write-Log "Starting privileged user audit on $ComputerName"

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Log "ActiveDirectory module loaded"
}
catch {
    Write-Log "ActiveDirectory module is not available. $_" "ERROR"
    exit 1
}

$privilegedGroups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Administrators",
    "Account Operators",
    "Backup Operators",
    "Server Operators"
)

$allResults = @()

foreach ($groupName in $privilegedGroups) {
    Write-Host "`n--- Checking group: $groupName ---" -ForegroundColor Yellow

    try {
        $members = Get-ADGroupMember -Identity $groupName -Server $ComputerName -Recursive -ErrorAction Stop

        if (-not $IncludeServiceAccounts) {
            $members = $members | Where-Object {
                $_.SamAccountName -notlike "svc-*" -and $_.SamAccountName -notlike "*$"
            }
        }

        if ($members.Count -eq 0) {
            Write-Host "  No members found." -ForegroundColor Green
            Write-Log "Group '$groupName' has no matching members"
            continue
        }

        Write-Host "  Members found: $($members.Count)" -ForegroundColor Cyan

        foreach ($member in $members) {
            if ($member.objectClass -ne "user") {
                Write-Log "Skipping non-user member '$($member.SamAccountName)' (type: $($member.objectClass))" "WARN"
                continue
            }

            try {
                $userDetail = Get-ADUser -Identity $member.SID -Server $ComputerName `
                    -Properties DisplayName, EmailAddress, Enabled, LastLogonDate, `
                    PasswordLastSet, PasswordNeverExpires, WhenCreated, Description `
                    -ErrorAction Stop

                $result = [PSCustomObject]@{
                    GroupName            = $groupName
                    SamAccountName       = $userDetail.SamAccountName
                    DisplayName          = $userDetail.DisplayName
                    EmailAddress         = $userDetail.EmailAddress
                    Enabled              = $userDetail.Enabled
                    LastLogonDate        = $userDetail.LastLogonDate
                    PasswordLastSet      = $userDetail.PasswordLastSet
                    PasswordNeverExpires = $userDetail.PasswordNeverExpires
                    WhenCreated          = $userDetail.WhenCreated
                    Description          = $userDetail.Description
                    ObjectClass          = $member.objectClass
                }

                $allResults += $result

                # Color-coded display
                $statusColor = if ($userDetail.Enabled) { "Green" } else { "Red" }
                $pwdColor = if ($userDetail.PasswordNeverExpires) { "Red" } else { "Green" }

                Write-Host "    $($userDetail.SamAccountName)" -ForegroundColor White -NoNewline
                Write-Host " | Enabled: $($userDetail.Enabled)" -ForegroundColor $statusColor -NoNewline
                Write-Host " | PwdNeverExpires: $($userDetail.PasswordNeverExpires)" -ForegroundColor $pwdColor
            }
            catch {
                Write-Log "Could not retrieve details for $($member.SamAccountName): $_" "WARN"
            }
        }
    }
    catch {
        Write-Log "Failed to query group '$groupName': $_" "ERROR"
    }
}

# --- Summary ---
Write-Host "`n=== Audit Summary ===" -ForegroundColor Green
Write-Host "  Total privileged accounts found: $($allResults.Count)" -ForegroundColor Cyan

$uniqueUsers = $allResults | Select-Object -Property SamAccountName -Unique
Write-Host "  Unique users: $($uniqueUsers.Count)" -ForegroundColor Cyan

$disabledAdmins = $allResults | Where-Object { -not $_.Enabled } | Select-Object -Property SamAccountName -Unique
if ($disabledAdmins.Count -gt 0) {
    Write-Host "  Disabled admin accounts: $($disabledAdmins.Count)" -ForegroundColor Red
}

$neverExpires = $allResults | Where-Object { $_.PasswordNeverExpires } | Select-Object -Property SamAccountName -Unique
if ($neverExpires.Count -gt 0) {
    Write-Host "  Accounts with non-expiring passwords: $($neverExpires.Count)" -ForegroundColor Yellow
}

# --- Export ---
if ($ExportFormat -and $allResults.Count -gt 0) {
    if ($ExportFormat -in @("CSV","Both")) {
        $csvPath = Join-Path $OutputPath "AdminUsers_$timestamp.csv"
        $allResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Exported CSV to $csvPath"
        Write-Host "  CSV exported: $csvPath" -ForegroundColor Cyan
    }
    if ($ExportFormat -in @("JSON","Both")) {
        $jsonPath = Join-Path $OutputPath "AdminUsers_$timestamp.json"
        $allResults | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Exported JSON to $jsonPath"
        Write-Host "  JSON exported: $jsonPath" -ForegroundColor Cyan
    }
}

Write-Host "  Log file: $logFile" -ForegroundColor Cyan
Write-Log "Privileged user audit complete. Total=$($allResults.Count)"
