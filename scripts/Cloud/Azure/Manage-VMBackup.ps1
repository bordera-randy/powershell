<#
.SYNOPSIS
    Manage Azure Virtual Machine backups and recovery.

.DESCRIPTION
    This script provides functionality to manage Azure VM backups using Azure Backup service:
    - Enable backup for VMs
    - Trigger on-demand backups
    - List backup status
    - View recovery points
    - Restore VMs from backups
    
    Requires Az.RecoveryServices PowerShell module.

.PARAMETER Action
    The backup operation to perform: Enable, Backup, List, GetRecoveryPoints, or Restore.

.PARAMETER ResourceGroupName
    The resource group containing the VM.

.PARAMETER VMName
    The name of the virtual machine.

.PARAMETER VaultName
    The name of the Recovery Services vault (required for backup operations).

.PARAMETER PolicyName
    The backup policy name (required when enabling backup).

.EXAMPLE
    .\Manage-VMBackup.ps1 -Action List
    Lists all protected VMs and their backup status.

.EXAMPLE
    .\Manage-VMBackup.ps1 -Action Enable -ResourceGroupName "MyRG" -VMName "MyVM" -VaultName "MyVault" -PolicyName "DefaultPolicy"
    Enables backup for a VM with the specified policy.

.EXAMPLE
    .\Manage-VMBackup.ps1 -Action Backup -ResourceGroupName "MyRG" -VMName "MyVM" -VaultName "MyVault"
    Triggers an on-demand backup for the VM.

.EXAMPLE
    .\Manage-VMBackup.ps1 -Action GetRecoveryPoints -ResourceGroupName "MyRG" -VMName "MyVM" -VaultName "MyVault"
    Lists available recovery points for the VM.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Requires: Az.RecoveryServices module
    
    Prerequisites:
    - Install-Module -Name Az.RecoveryServices
    - Connect-AzAccount
    - Appropriate Azure permissions (Backup Contributor role or higher)
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Enable","Backup","List","GetRecoveryPoints","Restore","GetVaults")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$VMName,
    
    [Parameter(Mandatory=$false)]
    [string]$VaultName,
    
    [Parameter(Mandatory=$false)]
    [string]$PolicyName = "DefaultPolicy"
)

# Check if Az.RecoveryServices module is installed
if (-not (Get-Module -ListAvailable -Name Az.RecoveryServices)) {
    Write-Error "Az.RecoveryServices module is not installed. Install it using: Install-Module -Name Az.RecoveryServices -Scope CurrentUser"
    exit 1
}

# Import required modules
Import-Module Az.RecoveryServices -ErrorAction SilentlyContinue
Import-Module Az.Compute -ErrorAction SilentlyContinue

function Get-BackupVaults {
    <#
    .SYNOPSIS
        Lists all Recovery Services vaults in the subscription.
    #>
    Write-Host "Retrieving Recovery Services vaults..." -ForegroundColor Cyan
    
    try {
        $vaults = Get-AzRecoveryServicesVault
        
        if ($vaults.Count -eq 0) {
            Write-Host "No Recovery Services vaults found in the subscription." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nRecovery Services Vaults:" -ForegroundColor Green
        $vaults | Format-Table Name, ResourceGroupName, Location, @{Label="Type";Expression={$_.Properties.ProvisioningState}} -AutoSize
        
        Write-Host "`nTotal Vaults: $($vaults.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve vaults: $_"
    }
}

function Enable-VMBackup {
    <#
    .SYNOPSIS
        Enables backup for an Azure VM.
    #>
    param($RG, $VM, $Vault, $Policy)
    
    if (-not $RG -or -not $VM -or -not $Vault -or -not $Policy) {
        Write-Error "ResourceGroupName, VMName, VaultName, and PolicyName are required for Enable action."
        return
    }
    
    Write-Host "Enabling backup for VM '$VM' in resource group '$RG'..." -ForegroundColor Cyan
    
    try {
        # Get the vault
        $vault = Get-AzRecoveryServicesVault -Name $Vault -ResourceGroupName $RG -ErrorAction Stop
        Set-AzRecoveryServicesVaultContext -Vault $vault
        
        # Get the backup policy
        $pol = Get-AzRecoveryServicesBackupProtectionPolicy -Name $Policy -ErrorAction Stop
        
        # Enable backup
        Enable-AzRecoveryServicesBackupProtection `
            -ResourceGroupName $RG `
            -Name $VM `
            -Policy $pol `
            -ErrorAction Stop
        
        Write-Host "Backup enabled successfully for VM '$VM'!" -ForegroundColor Green
        Write-Host "Policy: $Policy" -ForegroundColor White
    }
    catch {
        Write-Error "Failed to enable backup: $_"
    }
}

function Start-VMBackup {
    <#
    .SYNOPSIS
        Triggers an on-demand backup for a VM.
    #>
    param($RG, $VM, $Vault)
    
    if (-not $RG -or -not $VM -or -not $Vault) {
        Write-Error "ResourceGroupName, VMName, and VaultName are required for Backup action."
        return
    }
    
    Write-Host "Starting on-demand backup for VM '$VM'..." -ForegroundColor Cyan
    
    try {
        # Get the vault and set context
        $vault = Get-AzRecoveryServicesVault -Name $Vault -ResourceGroupName $RG -ErrorAction Stop
        Set-AzRecoveryServicesVaultContext -Vault $vault
        
        # Get backup item
        $namedContainer = Get-AzRecoveryServicesBackupContainer `
            -ContainerType "AzureVM" `
            -Status "Registered" `
            -FriendlyName $VM `
            -ErrorAction Stop
        
        $item = Get-AzRecoveryServicesBackupItem `
            -Container $namedContainer `
            -WorkloadType "AzureVM" `
            -ErrorAction Stop
        
        # Trigger backup
        $job = Backup-AzRecoveryServicesBackupItem `
            -Item $item `
            -ExpiryDateTimeUTC (Get-Date).AddDays(30) `
            -ErrorAction Stop
        
        Write-Host "Backup job started successfully!" -ForegroundColor Green
        Write-Host "Job ID: $($job.JobId)" -ForegroundColor White
        Write-Host "`nUse Get-AzRecoveryServicesBackupJob to monitor progress." -ForegroundColor Yellow
    }
    catch {
        Write-Error "Failed to start backup: $_"
    }
}

function Get-ProtectedVMs {
    <#
    .SYNOPSIS
        Lists all protected VMs and their backup status.
    #>
    Write-Host "Retrieving protected VMs..." -ForegroundColor Cyan
    
    try {
        # Get all vaults
        $vaults = Get-AzRecoveryServicesVault
        
        if ($vaults.Count -eq 0) {
            Write-Host "No Recovery Services vaults found." -ForegroundColor Yellow
            return
        }
        
        $allItems = @()
        
        foreach ($vault in $vaults) {
            Set-AzRecoveryServicesVaultContext -Vault $vault
            
            $containers = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -Status "Registered"
            
            foreach ($container in $containers) {
                $items = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType "AzureVM"
                
                foreach ($item in $items) {
                    $allItems += [PSCustomObject]@{
                        VMName = $item.FriendlyName
                        ProtectionStatus = $item.ProtectionStatus
                        LastBackupTime = $item.LastBackupTime
                        VaultName = $vault.Name
                        ResourceGroup = $vault.ResourceGroupName
                    }
                }
            }
        }
        
        if ($allItems.Count -eq 0) {
            Write-Host "No protected VMs found." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nProtected Virtual Machines:" -ForegroundColor Green
        $allItems | Format-Table VMName, ProtectionStatus, LastBackupTime, VaultName, ResourceGroup -AutoSize
        
        Write-Host "`nTotal Protected VMs: $($allItems.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve protected VMs: $_"
    }
}

function Get-VMRecoveryPoints {
    <#
    .SYNOPSIS
        Lists recovery points for a VM.
    #>
    param($RG, $VM, $Vault)
    
    if (-not $RG -or -not $VM -or -not $Vault) {
        Write-Error "ResourceGroupName, VMName, and VaultName are required for GetRecoveryPoints action."
        return
    }
    
    Write-Host "Retrieving recovery points for VM '$VM'..." -ForegroundColor Cyan
    
    try {
        # Get the vault and set context
        $vault = Get-AzRecoveryServicesVault -Name $Vault -ResourceGroupName $RG -ErrorAction Stop
        Set-AzRecoveryServicesVaultContext -Vault $vault
        
        # Get backup item
        $namedContainer = Get-AzRecoveryServicesBackupContainer `
            -ContainerType "AzureVM" `
            -Status "Registered" `
            -FriendlyName $VM `
            -ErrorAction Stop
        
        $item = Get-AzRecoveryServicesBackupItem `
            -Container $namedContainer `
            -WorkloadType "AzureVM" `
            -ErrorAction Stop
        
        # Get recovery points
        $recoveryPoints = Get-AzRecoveryServicesBackupRecoveryPoint `
            -Item $item `
            -ErrorAction Stop
        
        if ($recoveryPoints.Count -eq 0) {
            Write-Host "No recovery points found for VM '$VM'." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nRecovery Points for VM '$VM':" -ForegroundColor Green
        $recoveryPoints | Format-Table RecoveryPointTime, RecoveryPointType, @{Label="ID";Expression={$_.RecoveryPointId.Substring(0,40) + "..."}} -AutoSize
        
        Write-Host "`nTotal Recovery Points: $($recoveryPoints.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve recovery points: $_"
    }
}

# Main execution
Write-Host ""
Write-Host "Azure VM Backup Management" -ForegroundColor Green
Write-Host "==========================" -ForegroundColor Green
Write-Host ""

switch ($Action) {
    "GetVaults" { Get-BackupVaults }
    "Enable" { Enable-VMBackup -RG $ResourceGroupName -VM $VMName -Vault $VaultName -Policy $PolicyName }
    "Backup" { Start-VMBackup -RG $ResourceGroupName -VM $VMName -Vault $VaultName }
    "List" { Get-ProtectedVMs }
    "GetRecoveryPoints" { Get-VMRecoveryPoints -RG $ResourceGroupName -VM $VMName -Vault $VaultName }
    "Restore" { 
        Write-Host "Restore functionality requires additional parameters and interactive configuration." -ForegroundColor Yellow
        Write-Host "Please refer to Azure documentation for VM restore procedures:" -ForegroundColor Yellow
        Write-Host "https://docs.microsoft.com/en-us/azure/backup/backup-azure-arm-restore-vms" -ForegroundColor Cyan
    }
}

Write-Host ""
