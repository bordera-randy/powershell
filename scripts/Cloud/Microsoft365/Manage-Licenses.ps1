<#
.SYNOPSIS
    Manage Office 365 user licenses.

.DESCRIPTION
    This script provides comprehensive Office 365 license management capabilities:
    - List all available license SKUs
    - View license usage and available units
    - Assign licenses to users
    - Remove licenses from users
    - View user license assignments
    - Generate license reports
    
    Uses Microsoft Graph PowerShell module.

.PARAMETER Action
    The license operation to perform: ListSKUs, GetUsage, AssignLicense, RemoveLicense, GetUserLicenses, or GenerateReport.

.PARAMETER UserPrincipalName
    The UPN of the user for license operations.

.PARAMETER SKUId
    The SKU ID of the license to assign or remove.

.PARAMETER SKUPartNumber
    The SKU part number (friendly name) like "ENTERPRISEPACK" for Office 365 E3.

.EXAMPLE
    .\Manage-Licenses.ps1 -Action ListSKUs
    Lists all available license SKUs in the tenant.

.EXAMPLE
    .\Manage-Licenses.ps1 -Action GetUsage
    Shows license usage summary with available and consumed units.

.EXAMPLE
    .\Manage-Licenses.ps1 -Action AssignLicense -UserPrincipalName "user@contoso.com" -SKUPartNumber "ENTERPRISEPACK"
    Assigns Office 365 E3 license to the user.

.EXAMPLE
    .\Manage-Licenses.ps1 -Action GetUserLicenses -UserPrincipalName "user@contoso.com"
    Shows all licenses assigned to a specific user.

.EXAMPLE
    .\Manage-Licenses.ps1 -Action GenerateReport
    Generates a comprehensive license usage report.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Requires: Microsoft.Graph.Users and Microsoft.Graph.Identity.DirectoryManagement modules
    
    Prerequisites:
    - Install-Module -Name Microsoft.Graph -Scope CurrentUser
    - Connect-MgGraph -Scopes "User.ReadWrite.All","Organization.Read.All"
    
    Common SKU Part Numbers:
    - ENTERPRISEPACK: Office 365 E3
    - ENTERPRISEPREMIUM: Office 365 E5
    - SPE_E3: Microsoft 365 E3
    - SPE_E5: Microsoft 365 E5
    - STANDARDPACK: Office 365 E1
    - POWER_BI_STANDARD: Power BI (free)
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("ListSKUs","GetUsage","AssignLicense","RemoveLicense","GetUserLicenses","GenerateReport")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [string]$SKUId,
    
    [Parameter(Mandatory=$false)]
    [string]$SKUPartNumber
)

# Check if Microsoft.Graph modules are installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Write-Error "Microsoft.Graph.Users module is not installed. Install it using: Install-Module -Name Microsoft.Graph -Scope CurrentUser"
    exit 1
}

# Import required modules
Import-Module Microsoft.Graph.Users -ErrorAction SilentlyContinue
Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction SilentlyContinue

function Get-LicenseSKUs {
    <#
    .SYNOPSIS
        Lists all available license SKUs in the tenant.
    #>
    Write-Host "Retrieving available license SKUs..." -ForegroundColor Cyan
    
    try {
        $skus = Get-MgSubscribedSku -ErrorAction Stop
        
        if ($skus.Count -eq 0) {
            Write-Host "No license SKUs found in the tenant." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nAvailable License SKUs:" -ForegroundColor Green
        Write-Host ""
        
        foreach ($sku in $skus) {
            Write-Host "  SKU Part Number: " -NoNewline -ForegroundColor Yellow
            Write-Host $sku.SkuPartNumber -ForegroundColor White
            Write-Host "  SKU ID:          " -NoNewline -ForegroundColor Yellow
            Write-Host $sku.SkuId -ForegroundColor White
            Write-Host "  Enabled:         " -NoNewline -ForegroundColor Yellow
            Write-Host "$($sku.PrepaidUnits.Enabled) units" -ForegroundColor White
            Write-Host "  Consumed:        " -NoNewline -ForegroundColor Yellow
            Write-Host "$($sku.ConsumedUnits) units" -ForegroundColor White
            Write-Host "  Available:       " -NoNewline -ForegroundColor Yellow
            $available = $sku.PrepaidUnits.Enabled - $sku.ConsumedUnits
            $color = if ($available -lt 10) { "Red" } elseif ($available -lt 50) { "Yellow" } else { "Green" }
            Write-Host "$available units" -ForegroundColor $color
            Write-Host ""
        }
        
        Write-Host "Total SKUs: $($skus.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve license SKUs: $_"
        Write-Host "Make sure you're connected: Connect-MgGraph -Scopes 'Organization.Read.All'" -ForegroundColor Yellow
    }
}

function Get-LicenseUsage {
    <#
    .SYNOPSIS
        Shows license usage summary across all SKUs.
    #>
    Write-Host "Generating license usage summary..." -ForegroundColor Cyan
    
    try {
        $skus = Get-MgSubscribedSku -ErrorAction Stop
        
        if ($skus.Count -eq 0) {
            Write-Host "No license SKUs found." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nLicense Usage Summary:" -ForegroundColor Green
        Write-Host ""
        
        $totalEnabled = 0
        $totalConsumed = 0
        
        $usageData = @()
        
        foreach ($sku in $skus) {
            $available = $sku.PrepaidUnits.Enabled - $sku.ConsumedUnits
            $percentUsed = if ($sku.PrepaidUnits.Enabled -gt 0) { 
                [math]::Round(($sku.ConsumedUnits / $sku.PrepaidUnits.Enabled) * 100, 2) 
            } else { 0 }
            
            $totalEnabled += $sku.PrepaidUnits.Enabled
            $totalConsumed += $sku.ConsumedUnits
            
            $usageData += [PSCustomObject]@{
                SKU = $sku.SkuPartNumber
                Enabled = $sku.PrepaidUnits.Enabled
                Consumed = $sku.ConsumedUnits
                Available = $available
                PercentUsed = $percentUsed
            }
        }
        
        # Display table
        $usageData | Format-Table SKU, Enabled, Consumed, Available, @{Label="Usage %";Expression={$_.PercentUsed}} -AutoSize
        
        # Summary
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║          TOTAL SUMMARY                                   ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Total Licenses Enabled:  " -NoNewline -ForegroundColor White
        Write-Host $totalEnabled -ForegroundColor Green
        Write-Host "  Total Licenses Consumed: " -NoNewline -ForegroundColor White
        Write-Host $totalConsumed -ForegroundColor Yellow
        Write-Host "  Total Licenses Available:" -NoNewline -ForegroundColor White
        Write-Host ($totalEnabled - $totalConsumed) -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Error "Failed to get license usage: $_"
    }
}

function Add-UserLicense {
    <#
    .SYNOPSIS
        Assigns a license to a user.
    #>
    param($UPN, $SKU)
    
    if (-not $UPN) {
        Write-Error "UserPrincipalName is required for AssignLicense action."
        return
    }
    
    if (-not $SKU) {
        Write-Error "SKUPartNumber or SKUId is required for AssignLicense action."
        return
    }
    
    Write-Host "Assigning license to user '$UPN'..." -ForegroundColor Cyan
    
    try {
        # Get SKU details
        $skus = Get-MgSubscribedSku -ErrorAction Stop
        $targetSKU = $skus | Where-Object { $_.SkuPartNumber -eq $SKU -or $_.SkuId -eq $SKU }
        
        if (-not $targetSKU) {
            Write-Error "SKU '$SKU' not found. Use -Action ListSKUs to see available licenses."
            return
        }
        
        # Check available licenses
        $available = $targetSKU.PrepaidUnits.Enabled - $targetSKU.ConsumedUnits
        if ($available -le 0) {
            Write-Error "No available licenses for SKU '$($targetSKU.SkuPartNumber)'. All $($targetSKU.PrepaidUnits.Enabled) licenses are in use."
            return
        }
        
        # Assign license
        $addLicenses = @{
            SkuId = $targetSKU.SkuId
        }
        
        Set-MgUserLicense -UserId $UPN -AddLicenses @($addLicenses) -RemoveLicenses @() -ErrorAction Stop
        
        Write-Host "License assigned successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  User:    $UPN" -ForegroundColor White
        Write-Host "  License: $($targetSKU.SkuPartNumber)" -ForegroundColor White
        Write-Host "  SKU ID:  $($targetSKU.SkuId)" -ForegroundColor White
        Write-Host ""
    }
    catch {
        Write-Error "Failed to assign license: $_"
    }
}

function Remove-UserLicense {
    <#
    .SYNOPSIS
        Removes a license from a user.
    #>
    param($UPN, $SKU)
    
    if (-not $UPN) {
        Write-Error "UserPrincipalName is required for RemoveLicense action."
        return
    }
    
    if (-not $SKU) {
        Write-Error "SKUPartNumber or SKUId is required for RemoveLicense action."
        return
    }
    
    Write-Host "Removing license from user '$UPN'..." -ForegroundColor Cyan
    
    try {
        # Get SKU details
        $skus = Get-MgSubscribedSku -ErrorAction Stop
        $targetSKU = $skus | Where-Object { $_.SkuPartNumber -eq $SKU -or $_.SkuId -eq $SKU }
        
        if (-not $targetSKU) {
            Write-Error "SKU '$SKU' not found."
            return
        }
        
        # Remove license
        Set-MgUserLicense -UserId $UPN -AddLicenses @() -RemoveLicenses @($targetSKU.SkuId) -ErrorAction Stop
        
        Write-Host "License removed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  User:    $UPN" -ForegroundColor White
        Write-Host "  License: $($targetSKU.SkuPartNumber)" -ForegroundColor White
        Write-Host ""
    }
    catch {
        Write-Error "Failed to remove license: $_"
    }
}

function Get-UserLicenseInfo {
    <#
    .SYNOPSIS
        Gets all licenses assigned to a user.
    #>
    param($UPN)
    
    if (-not $UPN) {
        Write-Error "UserPrincipalName is required for GetUserLicenses action."
        return
    }
    
    Write-Host "Retrieving licenses for user '$UPN'..." -ForegroundColor Cyan
    
    try {
        $user = Get-MgUser -UserId $UPN -Property AssignedLicenses,DisplayName,UserPrincipalName -ErrorAction Stop
        
        if ($user.AssignedLicenses.Count -eq 0) {
            Write-Host "`nNo licenses assigned to user '$UPN'." -ForegroundColor Yellow
            return
        }
        
        # Get all SKUs for reference
        $skus = Get-MgSubscribedSku -ErrorAction Stop
        
        Write-Host "`nLicenses for $($user.DisplayName) ($($user.UserPrincipalName)):" -ForegroundColor Green
        Write-Host ""
        
        foreach ($license in $user.AssignedLicenses) {
            $sku = $skus | Where-Object { $_.SkuId -eq $license.SkuId }
            if ($sku) {
                Write-Host "  • $($sku.SkuPartNumber)" -ForegroundColor White
                Write-Host "    SKU ID: $($sku.SkuId)" -ForegroundColor DarkGray
                if ($license.DisabledPlans.Count -gt 0) {
                    Write-Host "    Disabled Plans: $($license.DisabledPlans.Count)" -ForegroundColor Yellow
                }
            }
            Write-Host ""
        }
        
        Write-Host "Total Licenses: $($user.AssignedLicenses.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to get user licenses: $_"
    }
}

function New-LicenseReport {
    <#
    .SYNOPSIS
        Generates a comprehensive license report and exports to CSV.
    #>
    Write-Host "Generating comprehensive license report..." -ForegroundColor Cyan
    Write-Host "This may take a few minutes..." -ForegroundColor Yellow
    
    try {
        # Get all users with licenses
        $users = Get-MgUser -All -Property DisplayName,UserPrincipalName,AssignedLicenses -ErrorAction Stop |
                 Where-Object { $_.AssignedLicenses.Count -gt 0 }
        
        # Get all SKUs
        $skus = Get-MgSubscribedSku -ErrorAction Stop
        
        $report = @()
        
        foreach ($user in $users) {
            foreach ($license in $user.AssignedLicenses) {
                $sku = $skus | Where-Object { $_.SkuId -eq $license.SkuId }
                
                $report += [PSCustomObject]@{
                    DisplayName = $user.DisplayName
                    UserPrincipalName = $user.UserPrincipalName
                    LicenseName = $sku.SkuPartNumber
                    SKUId = $sku.SkuId
                    DisabledPlansCount = $license.DisabledPlans.Count
                }
            }
        }
        
        # Export to CSV
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportPath = "LicenseReport_$timestamp.csv"
        $report | Export-Csv -Path $reportPath -NoTypeInformation
        
        Write-Host "`nReport generated successfully!" -ForegroundColor Green
        Write-Host "File: $reportPath" -ForegroundColor White
        Write-Host ""
        Write-Host "Summary:" -ForegroundColor Cyan
        Write-Host "  Licensed Users: $($users.Count)" -ForegroundColor White
        Write-Host "  Total License Assignments: $($report.Count)" -ForegroundColor White
        Write-Host ""
        
        # Show top licenses
        $topLicenses = $report | Group-Object -Property LicenseName | Sort-Object Count -Descending | Select-Object -First 5
        Write-Host "Top 5 Licenses:" -ForegroundColor Cyan
        foreach ($lic in $topLicenses) {
            Write-Host "  $($lic.Name): $($lic.Count) users" -ForegroundColor White
        }
    }
    catch {
        Write-Error "Failed to generate report: $_"
    }
}

# Main execution
Write-Host ""
Write-Host "Office 365 License Management" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Connect to Microsoft Graph first:" -ForegroundColor Cyan
Write-Host "Connect-MgGraph -Scopes 'User.ReadWrite.All','Organization.Read.All'" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    "ListSKUs" { Get-LicenseSKUs }
    "GetUsage" { Get-LicenseUsage }
    "AssignLicense" { Add-UserLicense -UPN $UserPrincipalName -SKU ($SKUPartNumber ?? $SKUId) }
    "RemoveLicense" { Remove-UserLicense -UPN $UserPrincipalName -SKU ($SKUPartNumber ?? $SKUId) }
    "GetUserLicenses" { Get-UserLicenseInfo -UPN $UserPrincipalName }
    "GenerateReport" { New-LicenseReport }
}

Write-Host ""
