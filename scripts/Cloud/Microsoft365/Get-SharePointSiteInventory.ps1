<#
.SYNOPSIS
    Inventories all SharePoint Online sites with storage and activity details.

.DESCRIPTION
    Retrieves all SharePoint Online sites including URL, title, owner, storage
    used/allocated, last content modified date, template type, and sharing
    capability. Highlights large sites (over 50% storage used) and inactive
    sites (no activity in the last 90 days). Exports results to JSON and/or
    CSV with logging.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Both).

.PARAMETER IncludePersonalSites
    When specified, includes OneDrive for Business personal sites in the inventory.

.EXAMPLE
    .\Get-SharePointSiteInventory.ps1
    Inventories all SharePoint sites excluding personal sites.

.EXAMPLE
    .\Get-SharePointSiteInventory.ps1 -IncludePersonalSites -Format Csv
    Inventories all sites including personal sites and exports as CSV.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Requires: Microsoft.Online.SharePoint.PowerShell or PnP.PowerShell
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Json","Csv","Both")]
    [string]$Format = "Both",

    [Parameter(Mandatory = $false)]
    [switch]$IncludePersonalSites
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Get-SharePointSiteInventory_$timestamp.log"

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

# Detect available module
$usePnP = $false
if (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell) {
    Write-Log "Using Microsoft.Online.SharePoint.PowerShell module" "INFO"
} elseif (Get-Module -ListAvailable -Name PnP.PowerShell) {
    $usePnP = $true
    Write-Log "Using PnP.PowerShell module" "INFO"
} else {
    Write-Log "No supported SharePoint module found. Install Microsoft.Online.SharePoint.PowerShell or PnP.PowerShell" "ERROR"
    exit 1
}

Write-Log "Starting SharePoint Online site inventory" "INFO"

try {
    $sites = @()
    $inactiveThreshold = (Get-Date).AddDays(-90)

    if ($usePnP) {
        Write-Log "Retrieving sites via PnP.PowerShell" "INFO"
        if ($IncludePersonalSites) {
            $rawSites = Get-PnPTenantSite -IncludeOneDriveSites -ErrorAction Stop
        } else {
            $rawSites = Get-PnPTenantSite -ErrorAction Stop
        }

        foreach ($site in $rawSites) {
            $storageUsedMB   = [math]::Round($site.StorageUsageCurrent, 2)
            $storageAllocMB  = $site.StorageMaximumLevel
            $storagePct      = if ($storageAllocMB -gt 0) {
                [math]::Round(($storageUsedMB / $storageAllocMB) * 100, 2)
            } else { 0 }

            $isLarge    = $storagePct -gt 50
            $isInactive = $site.LastContentModifiedDate -lt $inactiveThreshold

            $sites += [PSCustomObject]@{
                Url                = $site.Url
                Title              = $site.Title
                Owner              = $site.Owner
                StorageUsedMB      = $storageUsedMB
                StorageAllocatedMB = $storageAllocMB
                StorageUsedPercent = $storagePct
                LastModified       = $site.LastContentModifiedDate
                Template           = $site.Template
                SharingCapability  = $site.SharingCapability
                IsLargeSite        = $isLarge
                IsInactive         = $isInactive
            }

            if ($isLarge) {
                Write-Log "Large site: $($site.Url) - $storagePct% storage used" "WARN"
            }
            if ($isInactive) {
                Write-Log "Inactive site: $($site.Url) - last modified $($site.LastContentModifiedDate)" "WARN"
            }
        }
    } else {
        Write-Log "Retrieving sites via Microsoft.Online.SharePoint.PowerShell" "INFO"
        if ($IncludePersonalSites) {
            $rawSites = Get-SPOSite -Limit All -IncludePersonalSite $true -ErrorAction Stop
        } else {
            $rawSites = Get-SPOSite -Limit All -ErrorAction Stop
        }

        foreach ($site in $rawSites) {
            $storageUsedMB   = [math]::Round($site.StorageUsageCurrent, 2)
            $storageAllocMB  = $site.StorageQuota
            $storagePct      = if ($storageAllocMB -gt 0) {
                [math]::Round(($storageUsedMB / $storageAllocMB) * 100, 2)
            } else { 0 }

            $isLarge    = $storagePct -gt 50
            $isInactive = $site.LastContentModifiedDate -lt $inactiveThreshold

            $sites += [PSCustomObject]@{
                Url                = $site.Url
                Title              = $site.Title
                Owner              = $site.Owner
                StorageUsedMB      = $storageUsedMB
                StorageAllocatedMB = $storageAllocMB
                StorageUsedPercent = $storagePct
                LastModified       = $site.LastContentModifiedDate
                Template           = $site.Template
                SharingCapability  = $site.SharingCapability
                IsLargeSite        = $isLarge
                IsInactive         = $isInactive
            }

            if ($isLarge) {
                Write-Log "Large site: $($site.Url) - $storagePct% storage used" "WARN"
            }
            if ($isInactive) {
                Write-Log "Inactive site: $($site.Url) - last modified $($site.LastContentModifiedDate)" "WARN"
            }
        }
    }

    Write-Log "Retrieved $($sites.Count) site(s)" "INFO"

    # Build summary
    $totalStorageUsedMB = ($sites | Measure-Object -Property StorageUsedMB -Sum).Sum
    $largeSites    = ($sites | Where-Object { $_.IsLargeSite }).Count
    $inactiveSites = ($sites | Where-Object { $_.IsInactive }).Count

    $summary = [PSCustomObject]@{
        ReportGeneratedAt       = Get-Date
        TotalSites              = $sites.Count
        TotalStorageUsedMB      = [math]::Round($totalStorageUsedMB, 2)
        TotalStorageUsedGB      = [math]::Round($totalStorageUsedMB / 1024, 2)
        LargeSites              = $largeSites
        InactiveSites           = $inactiveSites
        IncludedPersonalSites   = [bool]$IncludePersonalSites
    }

    Write-Log "Summary - Total Sites: $($sites.Count) | Storage Used: $([math]::Round($totalStorageUsedMB / 1024, 2)) GB | Large: $largeSites | Inactive: $inactiveSites" "INFO"

    # Build full report object
    $report = [PSCustomObject]@{
        Summary = $summary
        Sites   = $sites
    }

    # Export results
    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "SharePointSiteInventory_$timestamp.json"
        $report | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }

    if ($Format -in @("Csv","Both")) {
        $csvPath = Join-Path $OutputDirectory "SharePointSiteInventory_$timestamp.csv"
        $sites | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV to $csvPath" "INFO"
    }
}
catch {
    Write-Log "Failed to inventory SharePoint sites: $_" "ERROR"
    throw
}

Write-Log "SharePoint site inventory complete" "INFO"
