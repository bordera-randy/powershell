<#
.SYNOPSIS
    Audits Azure AD (Entra ID) users and sign-in activity.

.DESCRIPTION
    Retrieves all Azure AD users via Microsoft Graph and reports on sign-in
    activity, guest accounts, disabled accounts, and MFA status. Identifies
    inactive users who have not signed in within a configurable number of days
    and exports results to JSON and/or CSV with logging.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Both).

.PARAMETER IncludeGuests
    Include guest (external) accounts in the audit.

.PARAMETER DaysInactive
    Number of days without sign-in to consider a user inactive (default: 30).

.EXAMPLE
    .\Audit-AzureADUsers.ps1

.EXAMPLE
    .\Audit-AzureADUsers.ps1 -IncludeGuests -DaysInactive 60 -Format Json

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Requires: Microsoft.Graph
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Json","Csv","Both")]
    [string]$Format = "Both",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeGuests,

    [Parameter(Mandatory = $false)]
    [int]$DaysInactive = 30
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Audit-AzureADUsers_$timestamp.log"

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

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Log "Microsoft.Graph module not found. Install-Module -Name Microsoft.Graph -Scope CurrentUser" "ERROR"
    exit 1
}

$context = Get-MgContext
if (-not $context) {
    Write-Log "Not authenticated. Run Connect-MgGraph first." "ERROR"
    exit 1
}

Write-Log "Starting Azure AD user audit (DaysInactive=$DaysInactive, IncludeGuests=$IncludeGuests)" "INFO"

try {
    $inactiveThreshold = (Get-Date).AddDays(-$DaysInactive)

    $properties = @(
        "DisplayName"
        "UserPrincipalName"
        "AccountEnabled"
        "UserType"
        "CreatedDateTime"
        "SignInActivity"
        "AssignedLicenses"
        "Department"
        "JobTitle"
    )

    Write-Log "Retrieving users from Microsoft Graph" "INFO"
    $users = Get-MgUser -All -Property $properties | Select-Object $properties

    if (-not $IncludeGuests) {
        $users = $users | Where-Object { $_.UserType -ne "Guest" }
        Write-Log "Filtered out guest accounts" "INFO"
    }

    Write-Log "Processing $($users.Count) users" "INFO"

    $auditResults = foreach ($user in $users) {
        $lastSignIn = $user.SignInActivity.LastSignInDateTime
        $isInactive = $false
        if ($lastSignIn) {
            $isInactive = ([datetime]$lastSignIn) -lt $inactiveThreshold
        } else {
            $isInactive = $true
        }

        $hasLicenses = ($user.AssignedLicenses | Measure-Object).Count -gt 0

        [PSCustomObject]@{
            DisplayName        = $user.DisplayName
            UserPrincipalName  = $user.UserPrincipalName
            AccountEnabled     = $user.AccountEnabled
            UserType           = $user.UserType
            CreatedDateTime    = $user.CreatedDateTime
            LastSignInDateTime = $lastSignIn
            IsInactive         = $isInactive
            HasLicenses        = $hasLicenses
            Department         = $user.Department
            JobTitle           = $user.JobTitle
        }
    }

    # Summary statistics
    $totalUsers      = ($auditResults | Measure-Object).Count
    $activeUsers     = ($auditResults | Where-Object { -not $_.IsInactive } | Measure-Object).Count
    $inactiveUsers   = ($auditResults | Where-Object { $_.IsInactive } | Measure-Object).Count
    $guestAccounts   = ($auditResults | Where-Object { $_.UserType -eq "Guest" } | Measure-Object).Count
    $disabledAccounts = ($auditResults | Where-Object { -not $_.AccountEnabled } | Measure-Object).Count

    Write-Log "=== Summary ===" "INFO"
    Write-Log "Total users: $totalUsers" "INFO"
    Write-Log "Active users: $activeUsers" "INFO"
    Write-Log "Inactive users (>$DaysInactive days): $inactiveUsers" "WARN"
    Write-Log "Guest accounts: $guestAccounts" "INFO"
    Write-Log "Disabled accounts: $disabledAccounts" "WARN"

    $exportData = [PSCustomObject]@{
        CollectedAt = Get-Date
        DaysInactiveThreshold = $DaysInactive
        Summary = [PSCustomObject]@{
            TotalUsers       = $totalUsers
            ActiveUsers      = $activeUsers
            InactiveUsers    = $inactiveUsers
            GuestAccounts    = $guestAccounts
            DisabledAccounts = $disabledAccounts
        }
        Users = $auditResults
    }

    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "AzureADUsers_$timestamp.json"
        $exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }

    if ($Format -in @("Csv","Both")) {
        $csvPath = Join-Path $OutputDirectory "AzureADUsers_$timestamp.csv"
        $auditResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV to $csvPath" "INFO"
    }
}
catch {
    Write-Log "Failed to audit Azure AD users: $_" "ERROR"
    throw
}

Write-Log "Azure AD user audit complete" "INFO"
