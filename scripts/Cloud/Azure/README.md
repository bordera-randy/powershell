# Azure Management Scripts

This directory contains PowerShell scripts for managing Microsoft Azure resources.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Available Scripts](#available-scripts)
  - [Manage-AzureVMs.ps1](#manage-azurevmsps1)
  - [Manage-ResourceGroups.ps1](#manage-resourcegroupsps1)
  - [Manage-StorageAccounts.ps1](#manage-storageaccountsps1)
  - [Manage-VMBackup.ps1](#manage-vmbackupps1)
  - [Audit-AzureRoleAssignments.ps1](#audit-azureroleassignmentsps1)
  - [Discover-AzureTenant.ps1](#discover-azuretenantps1)
  - [Tag-AzureResources.ps1](#tag-azureresourcesps1)
  - [Audit-AzureADUsers.ps1](#audit-azureadusersps1)
  - [Get-AzureSecurityScore.ps1](#get-azuresecurityscoreps1)
  - [Audit-AzureNetworkSecurity.ps1](#audit-azurenetworksecurityps1)
- [Authentication](#authentication)
- [Common Parameters](#common-parameters)
- [Best Practices](#best-practices)
- [Common Issues](#common-issues)
- [Additional Resources](#additional-resources)

## Prerequisites

- PowerShell 7+ (recommended)
- Az PowerShell module: `Install-Module -Name Az -Scope CurrentUser`
- Azure account with appropriate permissions
- Authenticated Azure session: `Connect-AzAccount`

## Available Scripts

### Manage-AzureVMs.ps1

Manage Azure Virtual Machines with ease.

**Features:**
- List all VMs in your subscription
- Start VMs
- Stop VMs  
- Restart VMs
- Get detailed VM status

**Usage:**
```powershell
# List all VMs
.\Manage-AzureVMs.ps1 -Action List

# Start a VM
.\Manage-AzureVMs.ps1 -Action Start -ResourceGroupName "MyRG" -VMName "MyVM"

# Stop a VM
.\Manage-AzureVMs.ps1 -Action Stop -ResourceGroupName "MyRG" -VMName "MyVM"

# Restart a VM
.\Manage-AzureVMs.ps1 -Action Restart -ResourceGroupName "MyRG" -VMName "MyVM"

# Get VM status
.\Manage-AzureVMs.ps1 -Action Status -ResourceGroupName "MyRG" -VMName "MyVM"
```

### Manage-ResourceGroups.ps1

Manage Azure Resource Groups.

**Features:**
- List all resource groups
- Create new resource groups
- Delete resource groups
- Get detailed resource group information

**Usage:**
```powershell
# List all resource groups
.\Manage-ResourceGroups.ps1 -Action List

# Create a resource group
.\Manage-ResourceGroups.ps1 -Action Create -ResourceGroupName "NewRG" -Location "eastus"

# Get resource group info
.\Manage-ResourceGroups.ps1 -Action Info -ResourceGroupName "MyRG"

# Delete a resource group (requires confirmation)
.\Manage-ResourceGroups.ps1 -Action Delete -ResourceGroupName "OldRG"
```

### Manage-StorageAccounts.ps1

Manage Azure Storage Accounts.

**Features:**
- List all storage accounts
- Create new storage accounts
- Delete storage accounts
- Get storage account information
- Retrieve storage account keys

**Usage:**
```powershell
# List all storage accounts
.\Manage-StorageAccounts.ps1 -Action List

# Create a storage account
.\Manage-StorageAccounts.ps1 -Action Create -StorageAccountName "mystorageacct" -ResourceGroupName "MyRG" -Location "eastus"

# Get storage account info
.\Manage-StorageAccounts.ps1 -Action Info -StorageAccountName "mystorageacct" -ResourceGroupName "MyRG"

# Get storage account keys
.\Manage-StorageAccounts.ps1 -Action GetKeys -StorageAccountName "mystorageacct" -ResourceGroupName "MyRG"

# Delete a storage account
.\Manage-StorageAccounts.ps1 -Action Delete -StorageAccountName "oldstorageacct" -ResourceGroupName "MyRG"
```

### Manage-VMBackup.ps1

Manage Azure Virtual Machine backups and recovery using Azure Backup service.

**Features:**
- Enable backup for VMs with a specified policy
- Trigger on-demand backups
- List all protected VMs and their backup status
- View available recovery points
- Restore VMs from backups
- List Recovery Services vaults

**Usage:**
```powershell
# List all protected VMs and backup status
.\Manage-VMBackup.ps1 -Action List

# Enable backup for a VM
.\Manage-VMBackup.ps1 -Action Enable -ResourceGroupName "MyRG" -VMName "MyVM" -VaultName "MyVault" -PolicyName "DefaultPolicy"

# Trigger an on-demand backup
.\Manage-VMBackup.ps1 -Action Backup -ResourceGroupName "MyRG" -VMName "MyVM" -VaultName "MyVault"

# List available recovery points
.\Manage-VMBackup.ps1 -Action GetRecoveryPoints -ResourceGroupName "MyRG" -VMName "MyVM" -VaultName "MyVault"

# List Recovery Services vaults
.\Manage-VMBackup.ps1 -Action GetVaults
```

**Parameters:**
- `-Action`: Enable, Backup, List, GetRecoveryPoints, Restore, or GetVaults
- `-ResourceGroupName`: Resource group containing the VM
- `-VMName`: Name of the virtual machine
- `-VaultName`: Name of the Recovery Services vault
- `-PolicyName`: Backup policy name (required when enabling backup)

### Audit-AzureRoleAssignments.ps1

Audit Azure role assignments at subscription or resource group scope.

**Features:**
- Subscription or resource group scope auditing
- CSV and JSON export options
- Console progress and log file

**Usage:**
```powershell
# Subscription scope audit
.\Audit-AzureRoleAssignments.ps1

# Resource group scope audit
.\Audit-AzureRoleAssignments.ps1 -ResourceGroupName "Prod-RG" -Format Both
```

**Parameters:**
- `-ResourceGroupName`: Target resource group
- `-Scope`: Custom scope (overrides ResourceGroupName)
- `-OutputDirectory`: Output and log directory
- `-Format`: Csv, Json, or Both

### Discover-AzureTenant.ps1

Discovers Azure tenant and subscription details.

**Features:**
- Tenant and subscription inventory
- JSON/CSV export with logs

**Usage:**
```powershell
# Tenant discovery
.\Discover-AzureTenant.ps1

# Export CSV and JSON
.\Discover-AzureTenant.ps1 -Format Both
```

### Tag-AzureResources.ps1

Apply tags to resources in a resource group.

**Features:**
- Merge new tags with existing tags
- Optional resource type filter
- Optional tagging of the resource group itself
- Console progress and log file

**Usage:**
```powershell
# Tag all resources in a resource group
.\Tag-AzureResources.ps1 -ResourceGroupName "Prod-RG" -Tags @{ Environment = "Prod"; Owner = "IT" }

# Tag only storage accounts
.\Tag-AzureResources.ps1 -ResourceGroupName "Dev-RG" -ResourceType "Microsoft.Storage/storageAccounts" -Tags @{ Environment = "Dev" }

# Tag resources and the resource group
.\Tag-AzureResources.ps1 -ResourceGroupName "Prod-RG" -Tags @{ Environment = "Prod" } -IncludeResourceGroup
```

**Parameters:**
- `-ResourceGroupName`: Target resource group
- `-Tags`: Hashtable of tags
- `-ResourceType`: Optional resource type filter
- `-IncludeResourceGroup`: Apply tags to the resource group

### Audit-AzureADUsers.ps1

Audits Azure AD (Entra ID) users and sign-in activity.

**Features:**
- Retrieves all Azure AD users via Microsoft Graph
- Identifies inactive users based on last sign-in date
- Reports on guest accounts, disabled accounts, and license status
- JSON and CSV export with logging

**Usage:**
```powershell
# Audit with default settings (30-day inactivity threshold)
.\Audit-AzureADUsers.ps1

# Include guests with 60-day threshold, export as JSON
.\Audit-AzureADUsers.ps1 -IncludeGuests -DaysInactive 60 -Format Json
```

**Parameters:**
- `-OutputDirectory`: Directory for output and log files
- `-Format`: Json, Csv, or Both (default: Both)
- `-IncludeGuests`: Include guest (external) accounts
- `-DaysInactive`: Days without sign-in to consider inactive (default: 30)

### Get-AzureSecurityScore.ps1

Gets Azure Secure Score and security recommendations.

**Features:**
- Retrieves Security Center secure score and assessments
- Groups recommendations by severity (High, Medium, Low)
- Color-coded console output for severity levels
- JSON and CSV export with logging

**Usage:**
```powershell
# Get security score for current subscription
.\Get-AzureSecurityScore.ps1

# Target a specific subscription and export both formats
.\Get-AzureSecurityScore.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000" -Format Both
```

**Parameters:**
- `-OutputDirectory`: Directory for output and log files
- `-Format`: Json, Csv, or Both (default: Json)
- `-SubscriptionId`: Target subscription ID (default: current context)

### Audit-AzureNetworkSecurity.ps1

Audits Network Security Groups and firewall rules across a subscription.

**Features:**
- Lists all NSG rules with associated subnets and NICs
- Flags dangerous rules (open inbound from internet, unrestricted ports)
- Color-coded high-risk rule highlighting
- Summary of total NSGs, rules, and high-risk findings

**Usage:**
```powershell
# Audit NSGs in current subscription
.\Audit-AzureNetworkSecurity.ps1

# Highlight open rules and export as JSON
.\Audit-AzureNetworkSecurity.ps1 -HighlightOpenRules -Format Json
```

**Parameters:**
- `-OutputDirectory`: Directory for output and log files
- `-Format`: Json, Csv, or Both (default: Both)
- `-SubscriptionId`: Target subscription ID (default: current context)
- `-HighlightOpenRules`: Highlight dangerous rules in console output

## Authentication

Before using these scripts, authenticate to Azure:

```powershell
# Interactive login
Connect-AzAccount

# Login with specific tenant
Connect-AzAccount -Tenant "your-tenant-id"

# Login with service principal
$credential = Get-Credential
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant "your-tenant-id"

# Verify connection
Get-AzContext
```

## Common Parameters

Most scripts support these common patterns:
- Use `-ResourceGroupName` to specify the resource group
- Use `-Location` to specify the Azure region (e.g., "eastus", "westus2", "northeurope")
- All actions are case-insensitive

## Best Practices

1. **Always test in non-production first**: Use a test subscription or resource group
2. **Review before deletion**: Scripts will prompt for confirmation before destructive actions
3. **Use appropriate permissions**: Ensure your account has the necessary RBAC roles
4. **Monitor costs**: Be aware of the costs associated with resources you create
5. **Tag your resources**: Consider adding tags for better organization

## Common Issues

**Issue**: "Az module not found"
```powershell
# Solution: Install the Az module
Install-Module -Name Az -Repository PSGallery -Scope CurrentUser -AllowClobber -Force
```

**Issue**: "Not authenticated to Azure"
```powershell
# Solution: Connect to Azure
Connect-AzAccount
```

**Issue**: "Insufficient permissions"
```
Solution: Ensure your account has the necessary role assignments (e.g., Contributor, Owner)
```

## Additional Resources

- [Azure PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/azure/)
- [Azure RBAC Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/)
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
