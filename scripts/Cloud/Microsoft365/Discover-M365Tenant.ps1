<#
.SYNOPSIS
    Discovers Microsoft 365 tenant details and exports results.

.DESCRIPTION
    Retrieves organization details, verified domains, and subscribed SKUs using
    Microsoft Graph. Exports results to JSON and CSV with logging.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Json).

.EXAMPLE
    .\Discover-M365Tenant.ps1

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
    [string]$Format = "Json"
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Discover-M365Tenant_$timestamp.log"

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

Write-Log "Collecting Microsoft 365 tenant details" "INFO"

try {
    $org = Get-MgOrganization | Select-Object Id, DisplayName, TenantType, CreatedDateTime, VerifiedDomains
    $domains = Get-MgDomain | Select-Object Id, IsVerified, IsDefault, IsInitial
    $skus = Get-MgSubscribedSku | Select-Object SkuPartNumber, ConsumedUnits, PrepaidUnits

    $result = [PSCustomObject]@{
        CollectedAt = Get-Date
        Organization = $org
        Domains = $domains
        SubscribedSkus = $skus
    }

    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "M365Tenant_$timestamp.json"
        $result | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }

    if ($Format -in @("Csv","Both")) {
        $csvPath = Join-Path $OutputDirectory "M365Tenant_Domains_$timestamp.csv"
        $domains | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV to $csvPath" "INFO"
    }
}
catch {
    Write-Log "Failed to discover tenant: $_" "ERROR"
    throw
}

Write-Log "Tenant discovery complete" "INFO"
