<#
.SYNOPSIS
    Generates a comprehensive Microsoft 365 license usage report.

.DESCRIPTION
    Retrieves all subscribed license SKUs and per-user license assignments using
    Microsoft Graph. Maps SKU part numbers to friendly display names, calculates
    utilization percentages, highlights over-allocated licenses, and exports the
    results to JSON and/or CSV with logging.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Both).

.EXAMPLE
    .\Get-M365LicenseReport.ps1
    Generates a license report with default settings and exports as both JSON and CSV.

.EXAMPLE
    .\Get-M365LicenseReport.ps1 -Format Csv -OutputDirectory "C:\Reports"
    Generates a CSV-only license report in the specified directory.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Requires: Microsoft.Graph
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Json","Csv","Both")]
    [string]$Format = "Both"
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Get-M365LicenseReport_$timestamp.log"

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

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Log "Microsoft.Graph module not found. Install-Module -Name Microsoft.Graph" "ERROR"
    exit 1
}

if (-not (Get-MgContext)) {
    Write-Log "Not connected to Microsoft Graph. Run Connect-MgGraph first." "ERROR"
    exit 1
}

# Map common SKU part numbers to friendly names
$skuFriendlyNames = @{
    "ENTERPRISEPACK"          = "Office 365 E3"
    "ENTERPRISEPREMIUM"       = "Office 365 E5"
    "STANDARDPACK"            = "Office 365 E1"
    "SPE_E3"                  = "Microsoft 365 E3"
    "SPE_E5"                  = "Microsoft 365 E5"
    "SPE_F1"                  = "Microsoft 365 F3"
    "FLOW_FREE"               = "Power Automate Free"
    "POWER_BI_STANDARD"       = "Power BI (Free)"
    "POWER_BI_PRO"            = "Power BI Pro"
    "EXCHANGESTANDARD"        = "Exchange Online (Plan 1)"
    "EXCHANGEENTERPRISE"      = "Exchange Online (Plan 2)"
    "EMS"                     = "Enterprise Mobility + Security E3"
    "EMSPREMIUM"              = "Enterprise Mobility + Security E5"
    "PROJECTPREMIUM"          = "Project Plan 5"
    "VISIOCLIENT"             = "Visio Plan 2"
    "ATP_ENTERPRISE"          = "Microsoft Defender for Office 365 (Plan 1)"
    "TEAMS_EXPLORATORY"       = "Microsoft Teams Exploratory"
    "MICROSOFT_BUSINESS_CENTER" = "Microsoft Business Center"
    "AAD_PREMIUM"             = "Azure AD Premium P1"
    "AAD_PREMIUM_P2"          = "Azure AD Premium P2"
    "STREAM"                  = "Microsoft Stream"
    "INTUNE_A"                = "Microsoft Intune"
    "O365_BUSINESS_PREMIUM"   = "Microsoft 365 Business Standard"
    "O365_BUSINESS_ESSENTIALS" = "Microsoft 365 Business Basic"
    "SMB_BUSINESS_PREMIUM"    = "Microsoft 365 Business Premium"
    "RIGHTSMANAGEMENT"        = "Azure Information Protection Plan 1"
    "MCOSTANDARD"             = "Skype for Business Online (Plan 2)"
    "SHAREPOINTSTANDARD"      = "SharePoint Online (Plan 1)"
    "SHAREPOINTENTERPRISE"    = "SharePoint Online (Plan 2)"
    "WINDOWS_STORE"           = "Windows Store for Business"
    "POWERAPPS_VIRAL"         = "Power Apps Plan 2 Trial"
    "DESKLESSPACK"            = "Office 365 F3"
    "ENTERPRISEWITHSCAL"      = "Office 365 E4"
    "DEVELOPERPACK"           = "Office 365 E3 Developer"
    "TEAMS_COMMERCIAL_TRIAL"  = "Microsoft Teams Commercial Cloud Trial"
}

Write-Log "Starting Microsoft 365 license usage report" "INFO"

try {
    # Retrieve all subscribed SKUs
    Write-Log "Retrieving subscribed SKUs" "INFO"
    $skus = Get-MgSubscribedSku -ErrorAction Stop

    $licenseData = @()
    $totalLicenses = 0
    $totalAssigned = 0
    $overAllocated = @()

    foreach ($sku in $skus) {
        $enabled   = $sku.PrepaidUnits.Enabled
        $consumed  = $sku.ConsumedUnits
        $available = $enabled - $consumed
        $utilization = if ($enabled -gt 0) {
            [math]::Round(($consumed / $enabled) * 100, 2)
        } else { 0 }

        $friendly = if ($skuFriendlyNames.ContainsKey($sku.SkuPartNumber)) {
            $skuFriendlyNames[$sku.SkuPartNumber]
        } else {
            $sku.SkuPartNumber
        }

        $entry = [PSCustomObject]@{
            SkuPartNumber   = $sku.SkuPartNumber
            FriendlyName    = $friendly
            SkuId           = $sku.SkuId
            TotalLicenses   = $enabled
            AssignedLicenses = $consumed
            AvailableLicenses = $available
            UtilizationPercent = $utilization
            OverAllocated   = $available -lt 0
        }

        $licenseData += $entry
        $totalLicenses += $enabled
        $totalAssigned += $consumed

        if ($available -lt 0) {
            $overAllocated += $entry
            Write-Log "OVER-ALLOCATED: $($sku.SkuPartNumber) ($friendly) - $([math]::Abs($available)) licenses over limit" "WARN"
        }
    }

    Write-Log "Retrieved $($skus.Count) SKUs" "INFO"

    # Retrieve per-user license assignments
    Write-Log "Retrieving per-user license assignments (this may take a while)" "INFO"
    $users = Get-MgUser -All -Property DisplayName, UserPrincipalName, AssignedLicenses -ErrorAction Stop |
             Where-Object { $_.AssignedLicenses.Count -gt 0 }

    $userLicenseData = @()
    foreach ($user in $users) {
        foreach ($license in $user.AssignedLicenses) {
            $sku = $skus | Where-Object { $_.SkuId -eq $license.SkuId }
            $friendly = if ($sku -and $skuFriendlyNames.ContainsKey($sku.SkuPartNumber)) {
                $skuFriendlyNames[$sku.SkuPartNumber]
            } elseif ($sku) {
                $sku.SkuPartNumber
            } else {
                "Unknown"
            }

            $userLicenseData += [PSCustomObject]@{
                DisplayName       = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                SkuPartNumber     = if ($sku) { $sku.SkuPartNumber } else { "Unknown" }
                FriendlyName      = $friendly
                SkuId             = $license.SkuId
                DisabledPlans     = $license.DisabledPlans.Count
            }
        }
    }

    Write-Log "Processed $($users.Count) licensed users with $($userLicenseData.Count) total assignments" "INFO"

    # Build summary
    $overallUtilization = if ($totalLicenses -gt 0) {
        [math]::Round(($totalAssigned / $totalLicenses) * 100, 2)
    } else { 0 }

    $summary = [PSCustomObject]@{
        ReportGeneratedAt      = Get-Date
        TotalSKUs              = $skus.Count
        TotalLicenses          = $totalLicenses
        TotalAssigned          = $totalAssigned
        TotalAvailable         = $totalLicenses - $totalAssigned
        OverallUtilizationPct  = $overallUtilization
        OverAllocatedSKUs      = $overAllocated.Count
        LicensedUsers          = $users.Count
        TotalAssignments       = $userLicenseData.Count
    }

    Write-Log "Summary - Total Licenses: $totalLicenses | Assigned: $totalAssigned | Utilization: $overallUtilization%" "INFO"
    if ($overAllocated.Count -gt 0) {
        Write-Log "$($overAllocated.Count) SKU(s) are over-allocated" "WARN"
    }

    # Build full report object
    $report = [PSCustomObject]@{
        Summary          = $summary
        LicenseSKUs      = $licenseData
        UserAssignments  = $userLicenseData
        OverAllocated    = $overAllocated
    }

    # Export results
    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "M365LicenseReport_$timestamp.json"
        $report | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }

    if ($Format -in @("Csv","Both")) {
        $csvSkuPath = Join-Path $OutputDirectory "M365LicenseReport_SKUs_$timestamp.csv"
        $licenseData | Export-Csv -Path $csvSkuPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved SKU CSV to $csvSkuPath" "INFO"

        $csvUserPath = Join-Path $OutputDirectory "M365LicenseReport_Users_$timestamp.csv"
        $userLicenseData | Export-Csv -Path $csvUserPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved User CSV to $csvUserPath" "INFO"
    }
}
catch {
    Write-Log "Failed to generate license report: $_" "ERROR"
    throw
}

Write-Log "License report complete" "INFO"
