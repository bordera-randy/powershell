<#
.SYNOPSIS
    Manage Azure Resource Groups
.DESCRIPTION
    This script provides functions to list, create, and delete Azure Resource Groups.
    Requires Az PowerShell module.
.EXAMPLE
    .\Manage-ResourceGroups.ps1 -Action List
    .\Manage-ResourceGroups.ps1 -Action Create -ResourceGroupName "MyRG" -Location "eastus"
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("List","Create","Delete","Info")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus"
)

# Check if Az module is installed
if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    Write-Error "Az.Resources module is not installed. Install it using: Install-Module -Name Az -AllowClobber -Scope CurrentUser"
    exit 1
}

Import-Module Az.Resources -ErrorAction SilentlyContinue

function Get-ResourceGroupList {
    Write-Host "Retrieving all Resource Groups..." -ForegroundColor Cyan
    
    try {
        $rgs = Get-AzResourceGroup
        
        if ($rgs.Count -eq 0) {
            Write-Host "No Resource Groups found." -ForegroundColor Yellow
            return
        }
        
        $rgs | Format-Table ResourceGroupName, Location, ProvisioningState, @{
            Label="Resources";
            Expression={(Get-AzResource -ResourceGroupName $_.ResourceGroupName).Count}
        } -AutoSize
        
        Write-Host "`nTotal Resource Groups: $($rgs.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve Resource Groups: $_"
    }
}

function New-ResourceGroup {
    param($Name, $Loc)
    
    if (-not $Name) {
        Write-Error "ResourceGroupName is required for Create action."
        return
    }
    
    Write-Host "Creating Resource Group '$Name' in location '$Loc'..." -ForegroundColor Cyan
    
    try {
        $rg = New-AzResourceGroup -Name $Name -Location $Loc
        Write-Host "Resource Group created successfully!" -ForegroundColor Green
        $rg | Format-List ResourceGroupName, Location, ProvisioningState
    }
    catch {
        Write-Error "Failed to create Resource Group: $_"
    }
}

function Remove-ResourceGroup {
    param($Name)
    
    if (-not $Name) {
        Write-Error "ResourceGroupName is required for Delete action."
        return
    }
    
    Write-Host "WARNING: This will delete Resource Group '$Name' and all its resources!" -ForegroundColor Red
    $confirm = Read-Host "Type 'YES' to confirm deletion"
    
    if ($confirm -ne "YES") {
        Write-Host "Deletion cancelled." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Deleting Resource Group '$Name'..." -ForegroundColor Cyan
    
    try {
        Remove-AzResourceGroup -Name $Name -Force
        Write-Host "Resource Group deleted successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to delete Resource Group: $_"
    }
}

function Get-ResourceGroupInfo {
    param($Name)
    
    if (-not $Name) {
        Write-Error "ResourceGroupName is required for Info action."
        return
    }
    
    Write-Host "Getting information for Resource Group '$Name'..." -ForegroundColor Cyan
    
    try {
        $rg = Get-AzResourceGroup -Name $Name
        $resources = Get-AzResource -ResourceGroupName $Name
        
        Write-Host "`nResource Group Details:" -ForegroundColor Yellow
        Write-Host "  Name: $($rg.ResourceGroupName)"
        Write-Host "  Location: $($rg.Location)"
        Write-Host "  Provisioning State: $($rg.ProvisioningState)"
        Write-Host "  Resource Count: $($resources.Count)"
        
        if ($resources.Count -gt 0) {
            Write-Host "`nResources in this group:" -ForegroundColor Yellow
            $resources | Format-Table Name, ResourceType, Location -AutoSize
        }
    }
    catch {
        Write-Error "Failed to get Resource Group info: $_"
    }
}

# Main execution
switch ($Action) {
    "List" { Get-ResourceGroupList }
    "Create" { New-ResourceGroup -Name $ResourceGroupName -Loc $Location }
    "Delete" { Remove-ResourceGroup -Name $ResourceGroupName }
    "Info" { Get-ResourceGroupInfo -Name $ResourceGroupName }
}
