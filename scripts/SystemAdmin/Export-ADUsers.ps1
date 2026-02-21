<#
.SYNOPSIS
    Exports all Active Directory users with comprehensive details.

.DESCRIPTION
    This script queries Active Directory for user accounts and exports detailed properties
    including Name, SamAccountName, Email, Department, Title, Manager, LastLogonDate,
    PasswordLastSet, AccountEnabled, PasswordNeverExpires, WhenCreated, and
    DistinguishedName. Supports CSV, JSON, or both export formats.

.PARAMETER SearchBase
    Distinguished name of the OU to search (e.g., "OU=IT,DC=contoso,DC=com").
    Defaults to the domain root.

.PARAMETER Filter
    User filter preset or AD filter string. Use "Enabled" for enabled users only (default),
    "*" for all users, or a custom AD filter string (e.g., "Department -eq 'Sales'").

.PARAMETER OutputPath
    Directory for export files (default: <script>\logs).

.PARAMETER Format
    Export format: CSV, JSON, or Both (default: CSV).

.EXAMPLE
    .\Export-ADUsers.ps1
    Exports all enabled users to CSV in the default logs directory.

.EXAMPLE
    .\Export-ADUsers.ps1 -Format Both -OutputPath "C:\Reports"
    Exports all enabled users in both CSV and JSON formats to C:\Reports.

.EXAMPLE
    .\Export-ADUsers.ps1 -SearchBase "OU=Sales,DC=contoso,DC=com" -Format JSON
    Exports enabled users from the Sales OU to JSON.

.EXAMPLE
    .\Export-ADUsers.ps1 -Filter "*" -Format CSV
    Exports all users (enabled and disabled) to CSV.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SearchBase,

    [Parameter(Mandatory = $false)]
    [string]$Filter = "Enabled",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("CSV","JSON","Both")]
    [string]$Format = "CSV"
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputPath "Export-ADUsers_$timestamp.log"

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
Write-Host "`n=== Active Directory User Export ===" -ForegroundColor Green
Write-Log "Starting AD user export"

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Log "ActiveDirectory module loaded"
}
catch {
    Write-Log "ActiveDirectory module is not available. $_" "ERROR"
    exit 1
}

# Build AD filter
if ($Filter -eq "Enabled") {
    $adFilter = "Enabled -eq `$true"
    Write-Log "Filter: enabled users only"
}
elseif ($Filter -eq "*") {
    $adFilter = "*"
    Write-Log "Filter: all users"
}
else {
    $adFilter = $Filter
    Write-Log "Filter: $Filter"
}

# Determine search base
if (-not $SearchBase) {
    $SearchBase = (Get-ADDomain).DistinguishedName
    Write-Log "No SearchBase specified. Using domain root: $SearchBase"
}
else {
    Write-Log "SearchBase: $SearchBase"
}

# Properties to retrieve
$properties = @(
    "DisplayName",
    "SamAccountName",
    "EmailAddress",
    "Department",
    "Title",
    "Manager",
    "LastLogonDate",
    "PasswordLastSet",
    "Enabled",
    "PasswordNeverExpires",
    "WhenCreated",
    "DistinguishedName",
    "GivenName",
    "Surname",
    "Description"
)

# Retrieve users
Write-Host "`nRetrieving users from $SearchBase..." -ForegroundColor Yellow

try {
    $users = Get-ADUser -Filter $adFilter -SearchBase $SearchBase -Properties $properties -ErrorAction Stop

    if ($users.Count -eq 0) {
        Write-Host "No users found matching the specified criteria." -ForegroundColor Yellow
        Write-Log "No users found" "WARN"
        exit 0
    }

    Write-Host "  Users found: $($users.Count)" -ForegroundColor Green
    Write-Log "Retrieved $($users.Count) users"
}
catch {
    Write-Log "Failed to retrieve users: $_" "ERROR"
    exit 1
}

# Build export objects
$exportData = foreach ($user in $users) {
    # Resolve manager display name
    $managerName = $null
    if ($user.Manager) {
        try {
            $managerName = (Get-ADUser -Identity $user.Manager -Properties DisplayName -ErrorAction SilentlyContinue).DisplayName
        }
        catch {
            $managerName = $user.Manager
        }
    }

    [PSCustomObject]@{
        Name                 = $user.DisplayName
        GivenName            = $user.GivenName
        Surname              = $user.Surname
        SamAccountName       = $user.SamAccountName
        Email                = $user.EmailAddress
        Department           = $user.Department
        Title                = $user.Title
        Manager              = $managerName
        LastLogonDate        = $user.LastLogonDate
        PasswordLastSet      = $user.PasswordLastSet
        AccountEnabled       = $user.Enabled
        PasswordNeverExpires = $user.PasswordNeverExpires
        WhenCreated          = $user.WhenCreated
        Description          = $user.Description
        DistinguishedName    = $user.DistinguishedName
    }
}

# Display summary
Write-Host "`n--- User Summary ---" -ForegroundColor Yellow

$enabledCount  = ($exportData | Where-Object { $_.AccountEnabled }).Count
$disabledCount = ($exportData | Where-Object { -not $_.AccountEnabled }).Count
$neverExpires  = ($exportData | Where-Object { $_.PasswordNeverExpires }).Count

Write-Host "  Enabled accounts:           $enabledCount" -ForegroundColor Green
Write-Host "  Disabled accounts:          $disabledCount" -ForegroundColor Red
Write-Host "  Password never expires:     $neverExpires" -ForegroundColor Yellow

$neverLoggedOn = ($exportData | Where-Object { -not $_.LastLogonDate }).Count
if ($neverLoggedOn -gt 0) {
    Write-Host "  Never logged on:            $neverLoggedOn" -ForegroundColor Yellow
}

$staleThreshold = (Get-Date).AddDays(-90)
$staleAccounts = ($exportData | Where-Object { $_.LastLogonDate -and $_.LastLogonDate -lt $staleThreshold }).Count
if ($staleAccounts -gt 0) {
    Write-Host "  Stale (no logon > 90 days): $staleAccounts" -ForegroundColor Red
}

# --- Export ---
Write-Host "`n--- Exporting ---" -ForegroundColor Yellow

if ($Format -in @("CSV","Both")) {
    $csvPath = Join-Path $OutputPath "ADUsers_$timestamp.csv"
    $exportData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Log "Exported CSV to $csvPath"
    Write-Host "  CSV exported: $csvPath" -ForegroundColor Green
}

if ($Format -in @("JSON","Both")) {
    $jsonPath = Join-Path $OutputPath "ADUsers_$timestamp.json"
    $exportData | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-Log "Exported JSON to $jsonPath"
    Write-Host "  JSON exported: $jsonPath" -ForegroundColor Green
}

Write-Host "`n=== Export Complete ===" -ForegroundColor Green
Write-Host "  Total users exported: $($exportData.Count)" -ForegroundColor Cyan
Write-Host "  Log file: $logFile" -ForegroundColor Cyan
Write-Log "User export complete. Total=$($exportData.Count)"
