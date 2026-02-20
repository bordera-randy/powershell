<#
.SYNOPSIS
    Generates a comprehensive report of all mailbox permissions in Exchange Online.

.DESCRIPTION
    This script connects to Exchange Online and retrieves all mailbox permissions,
    excluding inherited permissions and system accounts. It produces a CSV report
    showing who has access to which mailboxes and what permissions they have.
    
    The report includes:
    - Mailbox identity and email address
    - User with permissions
    - User's department and job title
    - Access rights granted

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Requires: Exchange Online PowerShell module
    
    Prerequisites:
    - Exchange Online PowerShell access
    - Appropriate admin permissions
    
.EXAMPLE
    Run this script to generate a mailbox permissions report.
    The report will be saved to c:\temp\mailboxpermissionsreport.csv

.LINK
    https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell
#>

# Prompt for credentials to connect to Exchange Online
$UserCredential = Get-Credential

# Establish connection to Exchange Online
$Session = New-PSSession -ConfigurationName Microsoft.Exchange `
                         -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
                         -Credential $UserCredential `
                         -Authentication Basic `
                         -AllowRedirection

# Import the Exchange Online session
Import-PSSession $Session -AllowClobber

<#
.SYNOPSIS
    Retrieves all mailbox permissions across the organization.

.DESCRIPTION
    This function queries all mailboxes and their permissions, filtering out
    inherited permissions and system accounts to focus on explicitly granted access.
#>
function Get-AllMailboxPermissions {
    # Get all mailboxes in the organization
    $allMailboxes = Get-Mailbox -ResultSize Unlimited | Sort-Object Identity

    if ($allMailboxes.Count -eq 0) {
        Write-Warning "No mailboxes found."
        return
    }
    
    # Process each mailbox
    foreach ($box in $allMailboxes) {
        # Get non-inherited permissions for the mailbox
        # Exclude inherited permissions, SELF, and system SID accounts
        $perms = $box | Get-MailboxPermission |
                        Where-Object { 
                            $_.IsInherited -eq $false -and 
                            $_.User.ToString() -ne "NT AUTHORITY\SELF" -and 
                            $_.User.ToString() -notmatch '^S-1-' 
                        } |
                        Sort-Object User

        # Process each permission entry
        foreach ($prm in $perms) {
            # Get user details
            $user = Get-Recipient -Identity $($prm.User.ToString()) -ErrorAction SilentlyContinue
            
            # Skip inactive (deleted) users
            if ($user -and $user.DisplayName) { 
                # Create output object with permission details
                $props = [ordered]@{
                    "Mailbox Identity"       = "$($box.Identity)"
                    "Mailbox Name"           = "$($box.DisplayName)"
                    "Mailbox Email Address"  = "$($box.PrimarySmtpAddress)"
                    "User"                   = $user.DisplayName
                    "User Email Address"     = $user.PrimarySmtpAddress
                    "Department"             = $user.Department
                    "Job Title"              = $user.Title
                    "AccessRights"           = "$($prm.AccessRights -join ', ')"
                }
                New-Object PsObject -Property $props
            }
        }
    }
}

# Clear the console for clean output
Clear-Host

Write-Host "Generating mailbox permissions report..." -ForegroundColor Cyan
Write-Host "This may take several minutes depending on mailbox count..." -ForegroundColor Yellow

# Generate the report and export to CSV
Get-AllMailboxPermissions | Export-Csv -NoTypeInformation c:\temp\mailboxpermissionsreport.csv

Write-Host "Report generated successfully!" -ForegroundColor Green
Write-Host "Location: c:\temp\mailboxpermissionsreport.csv" -ForegroundColor Green




