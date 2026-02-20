<#
.SYNOPSIS
    Manage Azure Storage Accounts
.DESCRIPTION
    This script provides functions to list, create, and manage Azure Storage Accounts.
    Requires Az PowerShell module.
.EXAMPLE
    .\Manage-StorageAccounts.ps1 -Action List
    .\Manage-StorageAccounts.ps1 -Action Create -StorageAccountName "mystorageacct" -ResourceGroupName "MyRG"
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("List","Create","Delete","Info","GetKeys")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Standard_LRS","Standard_GRS","Standard_RAGRS","Premium_LRS")]
    [string]$SkuName = "Standard_LRS"
)

# Check if Az module is installed
if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
    Write-Error "Az.Storage module is not installed. Install it using: Install-Module -Name Az -AllowClobber -Scope CurrentUser"
    exit 1
}

Import-Module Az.Storage -ErrorAction SilentlyContinue

function Get-StorageAccountList {
    Write-Host "Retrieving all Storage Accounts..." -ForegroundColor Cyan
    
    try {
        $storageAccounts = Get-AzStorageAccount
        
        if ($storageAccounts.Count -eq 0) {
            Write-Host "No Storage Accounts found." -ForegroundColor Yellow
            return
        }
        
        $storageAccounts | Format-Table StorageAccountName, ResourceGroupName, Location, Sku, @{
            Label="Status";Expression={$_.StatusOfPrimary}
        } -AutoSize
        
        Write-Host "`nTotal Storage Accounts: $($storageAccounts.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve Storage Accounts: $_"
    }
}

function New-StorageAccount {
    param($Name, $ResourceGroup, $Loc, $Sku)
    
    if (-not $Name -or -not $ResourceGroup) {
        Write-Error "StorageAccountName and ResourceGroupName are required for Create action."
        return
    }
    
    # Storage account names must be lowercase and alphanumeric
    $Name = $Name.ToLower() -replace '[^a-z0-9]', ''
    
    if ($Name.Length -lt 3 -or $Name.Length -gt 24) {
        Write-Error "Storage account name must be between 3 and 24 characters."
        return
    }
    
    Write-Host "Creating Storage Account '$Name' in resource group '$ResourceGroup'..." -ForegroundColor Cyan
    
    try {
        $storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroup `
                                               -Name $Name `
                                               -Location $Loc `
                                               -SkuName $Sku
        
        Write-Host "Storage Account created successfully!" -ForegroundColor Green
        $storageAccount | Format-List StorageAccountName, ResourceGroupName, Location, Sku, StatusOfPrimary
    }
    catch {
        Write-Error "Failed to create Storage Account: $_"
    }
}

function Remove-StorageAccount {
    param($Name, $ResourceGroup)
    
    if (-not $Name -or -not $ResourceGroup) {
        Write-Error "StorageAccountName and ResourceGroupName are required for Delete action."
        return
    }
    
    Write-Host "WARNING: This will delete Storage Account '$Name'!" -ForegroundColor Red
    $confirm = Read-Host "Type 'YES' to confirm deletion"
    
    if ($confirm -ne "YES") {
        Write-Host "Deletion cancelled." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Deleting Storage Account '$Name'..." -ForegroundColor Cyan
    
    try {
        Remove-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $Name -Force
        Write-Host "Storage Account deleted successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to delete Storage Account: $_"
    }
}

function Get-StorageAccountInfo {
    param($Name, $ResourceGroup)
    
    if (-not $Name -or -not $ResourceGroup) {
        Write-Error "StorageAccountName and ResourceGroupName are required for Info action."
        return
    }
    
    Write-Host "Getting information for Storage Account '$Name'..." -ForegroundColor Cyan
    
    try {
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $Name
        
        Write-Host "`nStorage Account Details:" -ForegroundColor Yellow
        Write-Host "  Name: $($storageAccount.StorageAccountName)"
        Write-Host "  Resource Group: $($storageAccount.ResourceGroupName)"
        Write-Host "  Location: $($storageAccount.Location)"
        Write-Host "  SKU: $($storageAccount.Sku.Name)"
        Write-Host "  Kind: $($storageAccount.Kind)"
        Write-Host "  Access Tier: $($storageAccount.AccessTier)"
        Write-Host "  Primary Status: $($storageAccount.StatusOfPrimary)"
        Write-Host "  Creation Time: $($storageAccount.CreationTime)"
    }
    catch {
        Write-Error "Failed to get Storage Account info: $_"
    }
}

function Get-StorageAccountKeys {
    param($Name, $ResourceGroup)
    
    if (-not $Name -or -not $ResourceGroup) {
        Write-Error "StorageAccountName and ResourceGroupName are required for GetKeys action."
        return
    }
    
    Write-Host "Retrieving access keys for Storage Account '$Name'..." -ForegroundColor Cyan
    
    try {
        $keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $Name
        
        Write-Host "`nStorage Account Keys:" -ForegroundColor Yellow
        $keys | Format-Table KeyName, Value, Permissions -AutoSize
        
        Write-Host "`nWARNING: Keep these keys secure!" -ForegroundColor Red
    }
    catch {
        Write-Error "Failed to retrieve Storage Account keys: $_"
    }
}

# Main execution
switch ($Action) {
    "List" { Get-StorageAccountList }
    "Create" { New-StorageAccount -Name $StorageAccountName -ResourceGroup $ResourceGroupName -Loc $Location -Sku $SkuName }
    "Delete" { Remove-StorageAccount -Name $StorageAccountName -ResourceGroup $ResourceGroupName }
    "Info" { Get-StorageAccountInfo -Name $StorageAccountName -ResourceGroup $ResourceGroupName }
    "GetKeys" { Get-StorageAccountKeys -Name $StorageAccountName -ResourceGroup $ResourceGroupName }
}
