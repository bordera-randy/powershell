<#
.SYNOPSIS
    Audits mailbox delegation and permission assignments in Exchange Online.

.DESCRIPTION
    Retrieves Full Access, Send As, and Send on Behalf permissions for Exchange
    Online mailboxes. Highlights non-standard delegated permissions (excluding
    NT AUTHORITY\SELF) and provides a summary of mailboxes with delegated access.
    Exports results to JSON and/or CSV with logging.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Both).

.PARAMETER Identity
    Optional specific mailbox identity (UPN or alias) to audit. If omitted, all
    mailboxes are audited.

.EXAMPLE
    .\Audit-M365MailboxPermissions.ps1
    Audits permissions for all mailboxes with default settings.

.EXAMPLE
    .\Audit-M365MailboxPermissions.ps1 -Identity "user@contoso.com" -Format Json
    Audits permissions for a specific mailbox and exports as JSON.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Requires: ExchangeOnlineManagement
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Json","Csv","Both")]
    [string]$Format = "Both",

    [Parameter(Mandatory = $false)]
    [string]$Identity
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Audit-M365MailboxPermissions_$timestamp.log"

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

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Log "ExchangeOnlineManagement module not found. Install-Module -Name ExchangeOnlineManagement" "ERROR"
    exit 1
}

Write-Log "Starting mailbox permissions audit" "INFO"

try {
    # Get mailboxes to audit
    if ($Identity) {
        Write-Log "Auditing single mailbox: $Identity" "INFO"
        $mailboxes = @(Get-Mailbox -Identity $Identity -ErrorAction Stop)
    } else {
        Write-Log "Retrieving all mailboxes (this may take a while)" "INFO"
        $mailboxes = @(Get-Mailbox -ResultSize Unlimited -ErrorAction Stop)
    }

    Write-Log "Found $($mailboxes.Count) mailbox(es) to audit" "INFO"

    $permissionResults = @()
    $mailboxesWithDelegation = @{}
    $processed = 0

    foreach ($mailbox in $mailboxes) {
        $processed++
        if ($processed % 50 -eq 0) {
            Write-Log "Processing mailbox $processed of $($mailboxes.Count)" "INFO"
        }

        # Full Access permissions
        try {
            $fullAccess = Get-MailboxPermission -Identity $mailbox.Identity -ErrorAction Stop |
                          Where-Object { $_.IsInherited -eq $false -and $_.User -ne "NT AUTHORITY\SELF" }

            foreach ($perm in $fullAccess) {
                $permissionResults += [PSCustomObject]@{
                    Mailbox         = $mailbox.PrimarySmtpAddress
                    DisplayName     = $mailbox.DisplayName
                    PermissionType  = "Full Access"
                    GrantedTo       = $perm.User
                    AccessRights    = ($perm.AccessRights -join ", ")
                    IsInherited     = $perm.IsInherited
                    IsNonStandard   = $true
                }
                $mailboxesWithDelegation[$mailbox.PrimarySmtpAddress] = $true
                Write-Log "Non-standard Full Access on $($mailbox.PrimarySmtpAddress) granted to $($perm.User)" "WARN"
            }
        }
        catch {
            Write-Log "Failed to get Full Access for $($mailbox.PrimarySmtpAddress): $_" "ERROR"
        }

        # Send As permissions
        try {
            $sendAs = Get-RecipientPermission -Identity $mailbox.Identity -ErrorAction Stop |
                      Where-Object { $_.Trustee -ne "NT AUTHORITY\SELF" }

            foreach ($perm in $sendAs) {
                $permissionResults += [PSCustomObject]@{
                    Mailbox         = $mailbox.PrimarySmtpAddress
                    DisplayName     = $mailbox.DisplayName
                    PermissionType  = "Send As"
                    GrantedTo       = $perm.Trustee
                    AccessRights    = ($perm.AccessRights -join ", ")
                    IsInherited     = $false
                    IsNonStandard   = $true
                }
                $mailboxesWithDelegation[$mailbox.PrimarySmtpAddress] = $true
                Write-Log "Non-standard Send As on $($mailbox.PrimarySmtpAddress) granted to $($perm.Trustee)" "WARN"
            }
        }
        catch {
            Write-Log "Failed to get Send As for $($mailbox.PrimarySmtpAddress): $_" "ERROR"
        }

        # Send on Behalf permissions
        if ($mailbox.GrantSendOnBehalfTo.Count -gt 0) {
            foreach ($delegate in $mailbox.GrantSendOnBehalfTo) {
                $permissionResults += [PSCustomObject]@{
                    Mailbox         = $mailbox.PrimarySmtpAddress
                    DisplayName     = $mailbox.DisplayName
                    PermissionType  = "Send on Behalf"
                    GrantedTo       = $delegate
                    AccessRights    = "SendOnBehalf"
                    IsInherited     = $false
                    IsNonStandard   = $true
                }
                $mailboxesWithDelegation[$mailbox.PrimarySmtpAddress] = $true
                Write-Log "Non-standard Send on Behalf on $($mailbox.PrimarySmtpAddress) granted to $delegate" "WARN"
            }
        }
    }

    # Build summary
    $summary = [PSCustomObject]@{
        ReportGeneratedAt           = Get-Date
        TotalMailboxesAudited       = $mailboxes.Count
        MailboxesWithDelegation     = $mailboxesWithDelegation.Count
        TotalNonStandardPermissions = $permissionResults.Count
        FullAccessCount             = ($permissionResults | Where-Object { $_.PermissionType -eq "Full Access" }).Count
        SendAsCount                 = ($permissionResults | Where-Object { $_.PermissionType -eq "Send As" }).Count
        SendOnBehalfCount           = ($permissionResults | Where-Object { $_.PermissionType -eq "Send on Behalf" }).Count
    }

    Write-Log "Audit complete - $($mailboxes.Count) mailbox(es) audited, $($mailboxesWithDelegation.Count) with delegated access, $($permissionResults.Count) non-standard permission(s) found" "INFO"

    # Build full report object
    $report = [PSCustomObject]@{
        Summary     = $summary
        Permissions = $permissionResults
    }

    # Export results
    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "MailboxPermissions_$timestamp.json"
        $report | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }

    if ($Format -in @("Csv","Both")) {
        $csvPath = Join-Path $OutputDirectory "MailboxPermissions_$timestamp.csv"
        $permissionResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV to $csvPath" "INFO"
    }
}
catch {
    Write-Log "Failed to audit mailbox permissions: $_" "ERROR"
    throw
}

Write-Log "Mailbox permissions audit complete" "INFO"
