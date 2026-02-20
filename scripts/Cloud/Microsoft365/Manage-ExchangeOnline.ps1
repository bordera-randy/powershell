<#
.SYNOPSIS
    Manage Exchange Online Mailboxes
.DESCRIPTION
    This script provides functions to manage Exchange Online mailboxes including listing, creating, and configuring mailboxes.
    Requires ExchangeOnlineManagement PowerShell module.
.EXAMPLE
    .\Manage-ExchangeOnline.ps1 -Action List
    .\Manage-ExchangeOnline.ps1 -Action Info -Identity "user@domain.com"
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("List","Info","GetMailboxStats","SetAutoReply","GetForwardingRules","ListDistributionGroups")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$Identity,
    
    [Parameter(Mandatory=$false)]
    [string]$AutoReplyMessage,
    
    [Parameter(Mandatory=$false)]
    [bool]$EnableAutoReply = $false
)

# Check if ExchangeOnlineManagement module is installed
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Error "ExchangeOnlineManagement module is not installed. Install it using: Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser"
    exit 1
}

Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue

function Get-MailboxList {
    Write-Host "Retrieving all mailboxes..." -ForegroundColor Cyan
    Write-Host "Note: This may take a while for large organizations." -ForegroundColor Yellow
    
    try {
        $mailboxes = Get-EXOMailbox -ResultSize 100
        
        if ($mailboxes.Count -eq 0) {
            Write-Host "No mailboxes found." -ForegroundColor Yellow
            return
        }
        
        $mailboxes | Format-Table DisplayName, PrimarySmtpAddress, UserPrincipalName, RecipientTypeDetails -AutoSize
        
        Write-Host "`nShowing first 100 mailboxes." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve mailboxes: $_"
        Write-Host "Make sure you're connected: Connect-ExchangeOnline" -ForegroundColor Yellow
    }
}

function Get-MailboxInfo {
    param($Id)
    
    if (-not $Id) {
        Write-Error "Identity is required for Info action."
        return
    }
    
    Write-Host "Getting information for mailbox '$Id'..." -ForegroundColor Cyan
    
    try {
        $mailbox = Get-EXOMailbox -Identity $Id
        
        Write-Host "`nMailbox Details:" -ForegroundColor Yellow
        Write-Host "  Display Name: $($mailbox.DisplayName)"
        Write-Host "  Primary SMTP: $($mailbox.PrimarySmtpAddress)"
        Write-Host "  User Principal Name: $($mailbox.UserPrincipalName)"
        Write-Host "  Recipient Type: $($mailbox.RecipientTypeDetails)"
        Write-Host "  Mailbox Database: $($mailbox.Database)"
        Write-Host "  Archive Status: $($mailbox.ArchiveStatus)"
        Write-Host "  Litigation Hold: $($mailbox.LitigationHoldEnabled)"
        
        # Get email addresses
        Write-Host "`nEmail Addresses:" -ForegroundColor Yellow
        $mailbox.EmailAddresses | ForEach-Object { Write-Host "  $_" }
    }
    catch {
        Write-Error "Failed to get mailbox info: $_"
    }
}

function Get-MailboxStatistics {
    param($Id)
    
    if (-not $Id) {
        Write-Error "Identity is required for GetMailboxStats action."
        return
    }
    
    Write-Host "Getting mailbox statistics for '$Id'..." -ForegroundColor Cyan
    
    try {
        $stats = Get-EXOMailboxStatistics -Identity $Id
        
        Write-Host "`nMailbox Statistics:" -ForegroundColor Yellow
        Write-Host "  Display Name: $($stats.DisplayName)"
        Write-Host "  Item Count: $($stats.ItemCount)"
        Write-Host "  Total Item Size: $($stats.TotalItemSize)"
        Write-Host "  Deleted Item Count: $($stats.DeletedItemCount)"
        Write-Host "  Total Deleted Item Size: $($stats.TotalDeletedItemSize)"
        Write-Host "  Last Logon Time: $($stats.LastLogonTime)"
        Write-Host "  Last Logoff Time: $($stats.LastLogoffTime)"
    }
    catch {
        Write-Error "Failed to get mailbox statistics: $_"
    }
}

function Set-MailboxAutoReply {
    param($Id, $Message, $Enable)
    
    if (-not $Id) {
        Write-Error "Identity is required for SetAutoReply action."
        return
    }
    
    if ($Enable) {
        if (-not $Message) {
            Write-Error "AutoReplyMessage is required when enabling auto-reply."
            return
        }
        
        Write-Host "Enabling auto-reply for '$Id'..." -ForegroundColor Cyan
        
        try {
            Set-MailboxAutoReplyConfiguration -Identity $Id `
                -AutoReplyState Enabled `
                -InternalMessage $Message `
                -ExternalMessage $Message
            
            Write-Host "Auto-reply enabled successfully!" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to enable auto-reply: $_"
        }
    }
    else {
        Write-Host "Disabling auto-reply for '$Id'..." -ForegroundColor Cyan
        
        try {
            Set-MailboxAutoReplyConfiguration -Identity $Id -AutoReplyState Disabled
            Write-Host "Auto-reply disabled successfully!" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to disable auto-reply: $_"
        }
    }
}

function Get-MailboxForwardingRules {
    param($Id)
    
    if (-not $Id) {
        Write-Error "Identity is required for GetForwardingRules action."
        return
    }
    
    Write-Host "Getting forwarding rules for '$Id'..." -ForegroundColor Cyan
    
    try {
        $rules = Get-InboxRule -Mailbox $Id | Where-Object { $_.ForwardTo -or $_.ForwardAsAttachmentTo }
        
        if ($rules.Count -eq 0) {
            Write-Host "No forwarding rules found." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nForwarding Rules:" -ForegroundColor Yellow
        $rules | Format-Table Name, Description, Enabled, ForwardTo, ForwardAsAttachmentTo -AutoSize
    }
    catch {
        Write-Error "Failed to get forwarding rules: $_"
    }
}

function Get-DistributionGroupList {
    Write-Host "Retrieving distribution groups..." -ForegroundColor Cyan
    
    try {
        $groups = Get-DistributionGroup -ResultSize 100
        
        if ($groups.Count -eq 0) {
            Write-Host "No distribution groups found." -ForegroundColor Yellow
            return
        }
        
        $groups | Format-Table DisplayName, PrimarySmtpAddress, GroupType, ManagedBy -AutoSize
        
        Write-Host "`nShowing first 100 distribution groups." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve distribution groups: $_"
    }
}

# Main execution
Write-Host "Note: Connect to Exchange Online first: Connect-ExchangeOnline" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    "List" { Get-MailboxList }
    "Info" { Get-MailboxInfo -Id $Identity }
    "GetMailboxStats" { Get-MailboxStatistics -Id $Identity }
    "SetAutoReply" { Set-MailboxAutoReply -Id $Identity -Message $AutoReplyMessage -Enable $EnableAutoReply }
    "GetForwardingRules" { Get-MailboxForwardingRules -Id $Identity }
    "ListDistributionGroups" { Get-DistributionGroupList }
}
