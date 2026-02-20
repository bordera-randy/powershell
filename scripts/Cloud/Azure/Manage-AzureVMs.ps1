<#
.SYNOPSIS
    Manage Azure Virtual Machines
.DESCRIPTION
    This script provides functions to list, start, stop, and restart Azure VMs.
    Requires Az PowerShell module.
.EXAMPLE
    .\Manage-AzureVMs.ps1 -Action List
    .\Manage-AzureVMs.ps1 -Action Start -ResourceGroupName "MyRG" -VMName "MyVM"
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("List","Start","Stop","Restart","Status")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$VMName
)

# Check if Az module is installed
if (-not (Get-Module -ListAvailable -Name Az.Compute)) {
    Write-Error "Az.Compute module is not installed. Install it using: Install-Module -Name Az -AllowClobber -Scope CurrentUser"
    exit 1
}

# Import required modules
Import-Module Az.Compute -ErrorAction SilentlyContinue

function Get-AzureVMList {
    Write-Host "Retrieving all Azure VMs..." -ForegroundColor Cyan
    
    try {
        $vms = Get-AzVM
        
        if ($vms.Count -eq 0) {
            Write-Host "No VMs found in the current subscription." -ForegroundColor Yellow
            return
        }
        
        $vms | Format-Table Name, ResourceGroupName, Location, @{Label="Status";Expression={
            $vmStatus = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Status
            $vmStatus.Statuses[1].DisplayStatus
        }} -AutoSize
        
        Write-Host "`nTotal VMs: $($vms.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve VMs: $_"
    }
}

function Start-AzureVM {
    param($ResourceGroup, $Name)
    
    if (-not $ResourceGroup -or -not $Name) {
        Write-Error "ResourceGroupName and VMName are required for Start action."
        return
    }
    
    Write-Host "Starting VM '$Name' in resource group '$ResourceGroup'..." -ForegroundColor Cyan
    
    try {
        Start-AzVM -ResourceGroupName $ResourceGroup -Name $Name -NoWait
        Write-Host "VM start command sent successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to start VM: $_"
    }
}

function Stop-AzureVM {
    param($ResourceGroup, $Name)
    
    if (-not $ResourceGroup -or -not $Name) {
        Write-Error "ResourceGroupName and VMName are required for Stop action."
        return
    }
    
    Write-Host "Stopping VM '$Name' in resource group '$ResourceGroup'..." -ForegroundColor Cyan
    
    try {
        Stop-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Force -NoWait
        Write-Host "VM stop command sent successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to stop VM: $_"
    }
}

function Restart-AzureVM {
    param($ResourceGroup, $Name)
    
    if (-not $ResourceGroup -or -not $Name) {
        Write-Error "ResourceGroupName and VMName are required for Restart action."
        return
    }
    
    Write-Host "Restarting VM '$Name' in resource group '$ResourceGroup'..." -ForegroundColor Cyan
    
    try {
        Restart-AzVM -ResourceGroupName $ResourceGroup -Name $Name -NoWait
        Write-Host "VM restart command sent successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to restart VM: $_"
    }
}

function Get-AzureVMStatus {
    param($ResourceGroup, $Name)
    
    if (-not $ResourceGroup -or -not $Name) {
        Write-Error "ResourceGroupName and VMName are required for Status action."
        return
    }
    
    Write-Host "Getting status for VM '$Name' in resource group '$ResourceGroup'..." -ForegroundColor Cyan
    
    try {
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
        
        Write-Host "`nVM Details:" -ForegroundColor Yellow
        Write-Host "  Name: $($vm.Name)"
        Write-Host "  Resource Group: $($vm.ResourceGroupName)"
        Write-Host "  Location: $($vm.Location)"
        Write-Host "  VM Size: $($vm.HardwareProfile.VmSize)"
        Write-Host "`nPower State: $($vm.Statuses[1].DisplayStatus)" -ForegroundColor $(
            if ($vm.Statuses[1].DisplayStatus -like "*running*") { "Green" } else { "Yellow" }
        )
    }
    catch {
        Write-Error "Failed to get VM status: $_"
    }
}

# Main execution
switch ($Action) {
    "List" { Get-AzureVMList }
    "Start" { Start-AzureVM -ResourceGroup $ResourceGroupName -Name $VMName }
    "Stop" { Stop-AzureVM -ResourceGroup $ResourceGroupName -Name $VMName }
    "Restart" { Restart-AzureVM -ResourceGroup $ResourceGroupName -Name $VMName }
    "Status" { Get-AzureVMStatus -ResourceGroup $ResourceGroupName -Name $VMName }
}
