# Office 365 Management Scripts

This directory contains PowerShell scripts for managing Microsoft 365/Office 365 services.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Available Scripts](#available-scripts)
  - [Manage-O365Users.ps1](#manage-o365usersps1)
  - [Manage-Teams.ps1](#manage-teamsps1)
  - [Manage-ExchangeOnline.ps1](#manage-exchangeonlineps1)
  - [Discover-M365Tenant.ps1](#discover-m365tenantps1)
  - [Get-M365LicenseReport.ps1](#get-m365licensereportps1)
  - [Audit-M365MailboxPermissions.ps1](#audit-m365mailboxpermissionsps1)
  - [Get-SharePointSiteInventory.ps1](#get-sharepointsiteinventoryps1)
  - [Audit-M365AdminRoles.ps1](#audit-m365adminrolesps1)
- [Authentication](#authentication)
  - [Microsoft Graph](#microsoft-graph)
  - [Exchange Online](#exchange-online)
- [Required Permissions](#required-permissions)
- [Best Practices](#best-practices)
- [Common Issues](#common-issues)
- [Security Considerations](#security-considerations)
- [Additional Resources](#additional-resources)

## Prerequisites

- PowerShell 7+ (recommended)
- Microsoft.Graph module: `Install-Module -Name Microsoft.Graph -Scope CurrentUser`
- ExchangeOnlineManagement module: `Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser`
- Microsoft 365 account with appropriate admin permissions

## Available Scripts

### Manage-O365Users.ps1

Manage Office 365 users using Microsoft Graph API.

**Prerequisites:**
- Microsoft.Graph.Users module
- Connected to Microsoft Graph: `Connect-MgGraph -Scopes "User.ReadWrite.All"`

**Features:**
- List all users
- Get detailed user information
- Create new users
- Enable/disable user accounts
- Reset user passwords

**Usage:**
```powershell
# Connect first
Connect-MgGraph -Scopes "User.ReadWrite.All"

# List all users
.\Manage-O365Users.ps1 -Action List

# Get user info
.\Manage-O365Users.ps1 -Action Info -UserPrincipalName "user@contoso.com"

# Create a new user
.\Manage-O365Users.ps1 -Action Create -UserPrincipalName "john@contoso.com" -DisplayName "John Doe"

# Disable a user
.\Manage-O365Users.ps1 -Action Disable -UserPrincipalName "user@contoso.com"

# Enable a user
.\Manage-O365Users.ps1 -Action Enable -UserPrincipalName "user@contoso.com"

# Reset password
.\Manage-O365Users.ps1 -Action ResetPassword -UserPrincipalName "user@contoso.com"
```

### Manage-Teams.ps1

Manage Microsoft Teams and team membership.

**Prerequisites:**
- Microsoft.Graph.Teams module
- Connected to Microsoft Graph: `Connect-MgGraph -Scopes "Team.ReadBasic.All","TeamMember.ReadWrite.All"`

**Features:**
- List all teams
- Get team information and channels
- Create new teams
- Add/remove team members
- List team members

**Usage:**
```powershell
# Connect first
Connect-MgGraph -Scopes "Team.ReadBasic.All","TeamMember.ReadWrite.All"

# List all teams
.\Manage-Teams.ps1 -Action List

# Get team info
.\Manage-Teams.ps1 -Action Info -TeamId "team-id-here"

# Create a new team
.\Manage-Teams.ps1 -Action Create -TeamName "Project Team" -Description "Team for project collaboration"

# Add a member
.\Manage-Teams.ps1 -Action AddMember -TeamId "team-id" -UserPrincipalName "user@contoso.com"

# Remove a member
.\Manage-Teams.ps1 -Action RemoveMember -TeamId "team-id" -UserPrincipalName "user@contoso.com"

# List members
.\Manage-Teams.ps1 -Action ListMembers -TeamId "team-id"
```

### Manage-ExchangeOnline.ps1

Manage Exchange Online mailboxes and settings.

**Prerequisites:**
- ExchangeOnlineManagement module
- Connected to Exchange Online: `Connect-ExchangeOnline`

**Features:**
- List mailboxes
- Get mailbox information
- Get mailbox statistics
- Set automatic replies (out of office)
- Get forwarding rules
- List distribution groups

**Usage:**
```powershell
# Connect first
Connect-ExchangeOnline

# List mailboxes (first 100)
.\Manage-ExchangeOnline.ps1 -Action List

# Get mailbox info
.\Manage-ExchangeOnline.ps1 -Action Info -Identity "user@contoso.com"

# Get mailbox statistics
.\Manage-ExchangeOnline.ps1 -Action GetMailboxStats -Identity "user@contoso.com"
```

### Discover-M365Tenant.ps1

Discovers Microsoft 365 tenant details.

**Prerequisites:**
- Microsoft.Graph module
- Connected to Microsoft Graph: `Connect-MgGraph`

**Features:**
- Organization details
- Verified domains
- Subscribed SKUs
- JSON/CSV export with logs

**Usage:**
```powershell
# Tenant discovery
Connect-MgGraph -Scopes "Organization.Read.All","Domain.Read.All"
.\Discover-M365Tenant.ps1

# Export JSON and CSV
.\Discover-M365Tenant.ps1 -Format Both
```

### Get-M365LicenseReport.ps1

Generates a comprehensive Microsoft 365 license usage report.

**Prerequisites:**
- Microsoft.Graph module
- Connected to Microsoft Graph: `Connect-MgGraph -Scopes "User.Read.All","Organization.Read.All"`

**Features:**
- Maps SKU part numbers to friendly display names
- Calculates per-SKU utilization percentages
- Highlights over-allocated licenses
- Per-user license assignment breakdown

**Usage:**
```powershell
# Generate license report (JSON and CSV)
.\Get-M365LicenseReport.ps1

# CSV-only report in a specific directory
.\Get-M365LicenseReport.ps1 -Format Csv -OutputDirectory "C:\Reports"
```

**Parameters:**
- `-OutputDirectory`: Directory for output and log files
- `-Format`: Json, Csv, or Both (default: Both)

### Audit-M365MailboxPermissions.ps1

Audits mailbox delegation and permission assignments in Exchange Online.

**Prerequisites:**
- ExchangeOnlineManagement module
- Connected to Exchange Online: `Connect-ExchangeOnline`

**Features:**
- Retrieves Full Access, Send As, and Send on Behalf permissions
- Highlights non-standard delegated permissions
- Audit a single mailbox or all mailboxes
- Summary of mailboxes with delegated access

**Usage:**
```powershell
# Audit all mailboxes
.\Audit-M365MailboxPermissions.ps1

# Audit a specific mailbox
.\Audit-M365MailboxPermissions.ps1 -Identity "user@contoso.com" -Format Json
```

**Parameters:**
- `-OutputDirectory`: Directory for output and log files
- `-Format`: Json, Csv, or Both (default: Both)
- `-Identity`: Specific mailbox UPN or alias (default: all mailboxes)

### Get-SharePointSiteInventory.ps1

Inventories all SharePoint Online sites with storage and activity details.

**Prerequisites:**
- Microsoft.Online.SharePoint.PowerShell or PnP.PowerShell module

**Features:**
- Reports URL, title, owner, storage used/allocated, and sharing capability
- Highlights large sites (>50% storage) and inactive sites (>90 days)
- Optional inclusion of OneDrive personal sites
- JSON and CSV export with logging

**Usage:**
```powershell
# Inventory all SharePoint sites
.\Get-SharePointSiteInventory.ps1

# Include personal sites, export as CSV
.\Get-SharePointSiteInventory.ps1 -IncludePersonalSites -Format Csv
```

**Parameters:**
- `-OutputDirectory`: Directory for output and log files
- `-Format`: Json, Csv, or Both (default: Both)
- `-IncludePersonalSites`: Include OneDrive personal sites

### Audit-M365AdminRoles.ps1

Audits Microsoft 365 admin role assignments.

**Prerequisites:**
- Microsoft.Graph module
- Connected to Microsoft Graph: `Connect-MgGraph -Scopes "RoleManagement.Read.All","UserAuthenticationMethod.Read.All"`

**Features:**
- Lists all directory roles and their members via Microsoft Graph
- Highlights Global Administrator assignments
- Checks MFA registration status for admin users
- Identifies users holding multiple admin roles

**Usage:**
```powershell
# Audit all admin role assignments
.\Audit-M365AdminRoles.ps1

# Include group-based assignments, export as JSON
.\Audit-M365AdminRoles.ps1 -IncludeGroupAssignments -Format Json
```

**Parameters:**
- `-OutputDirectory`: Directory for output and log files
- `-Format`: Json, Csv, or Both (default: Both)
- `-IncludeGroupAssignments`: Include group-based role assignments

# Enable auto-reply
.\Manage-ExchangeOnline.ps1 -Action SetAutoReply -Identity "user@contoso.com" -AutoReplyMessage "I'm out of office" -EnableAutoReply $true

# Disable auto-reply
.\Manage-ExchangeOnline.ps1 -Action SetAutoReply -Identity "user@contoso.com" -EnableAutoReply $false

# Get forwarding rules
.\Manage-ExchangeOnline.ps1 -Action GetForwardingRules -Identity "user@contoso.com"

# List distribution groups
.\Manage-ExchangeOnline.ps1 -Action ListDistributionGroups
```

## Authentication

### Microsoft Graph

```powershell
# Interactive login
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All"

# See required scopes for each operation in script documentation
Get-Help .\Manage-O365Users.ps1 -Full

# Verify connection
Get-MgContext

# Disconnect
Disconnect-MgGraph
```

### Exchange Online

```powershell
# Interactive login
Connect-ExchangeOnline

# With specific user
Connect-ExchangeOnline -UserPrincipalName admin@contoso.com

# Verify connection
Get-ConnectionInformation

# Disconnect
Disconnect-ExchangeOnline
```

## Required Permissions

### For User Management
- User.ReadWrite.All (for creating/modifying users)
- User.Read.All (for reading user information)

### For Teams Management
- Team.ReadBasic.All (for reading teams)
- TeamMember.ReadWrite.All (for managing team members)
- Group.ReadWrite.All (for creating teams)

### For Exchange Online
- Exchange Administrator role or higher
- Global Administrator for full access

## Best Practices

1. **Use least privilege principle**: Only request the scopes you need
2. **Test with test users**: Always test user management scripts with test accounts first
3. **Document changes**: Keep track of administrative changes
4. **Regular password resets**: Enforce password policies and regular resets
5. **Monitor privileged accounts**: Keep an eye on admin accounts
6. **Use MFA**: Ensure Multi-Factor Authentication is enabled
7. **Review licenses**: Check license assignments before creating users

## Common Issues

**Issue**: "Connect-MgGraph command not found"
```powershell
# Solution: Install the Microsoft.Graph module
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
```

**Issue**: "Insufficient privileges to complete the operation"
```powershell
# Solution: Connect with appropriate scopes
Disconnect-MgGraph
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All"
```

**Issue**: "Cannot access Exchange Online"
```powershell
# Solution: Install and connect to Exchange Online
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser
Connect-ExchangeOnline
```

**Issue**: "User already exists"
```
Solution: Check if the user already exists before creating. Use Get-MgUser to verify.
```

## Security Considerations

1. **Store credentials securely**: Never hardcode credentials in scripts
2. **Use managed identities**: When running automated scripts in Azure
3. **Audit logs**: Regularly review audit logs for administrative actions
4. **Conditional Access**: Configure conditional access policies
5. **Privileged Identity Management**: Use PIM for time-limited admin access

## Additional Resources

- [Microsoft Graph PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/microsoftgraph/)
- [Exchange Online PowerShell](https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell)
- [Microsoft 365 Admin Center](https://admin.microsoft.com/)
- [Microsoft Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer)
- [Microsoft 365 Compliance Center](https://compliance.microsoft.com/)
