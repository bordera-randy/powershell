<#
.SYNOPSIS
    Discovers Azure tenant and subscription details.

.DESCRIPTION
    Retrieves tenant and subscription information using Az.Accounts and exports
    results to JSON and CSV with logging.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Json).

.EXAMPLE
    .\Discover-AzureTenant.ps1

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Requires: Az.Accounts
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
$logFile = Join-Path $OutputDirectory "Discover-AzureTenant_$timestamp.log"

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

if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Log "Az.Accounts module not found. Install-Module -Name Az -Scope CurrentUser" "ERROR"
    exit 1
}

$context = Get-AzContext
if (-not $context) {
    Write-Log "Not authenticated. Run Connect-AzAccount first." "ERROR"
    exit 1
}

Write-Log "Collecting Azure tenant details" "INFO"

try {
    $tenant = Get-AzTenant | Select-Object Id, TenantId, Domain, DefaultDomain
    $subscriptions = Get-AzSubscription | Select-Object Name, Id, State, TenantId

    $result = [PSCustomObject]@{
        CollectedAt = Get-Date
        Tenant = $tenant
        Subscriptions = $subscriptions
    }

    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "AzureTenant_$timestamp.json"
        $result | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }

    if ($Format -in @("Csv","Both")) {
        $csvPath = Join-Path $OutputDirectory "AzureSubscriptions_$timestamp.csv"
        $subscriptions | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV to $csvPath" "INFO"
    }
}
catch {
    Write-Log "Failed to discover tenant: $_" "ERROR"
    throw
}

Write-Log "Tenant discovery complete" "INFO"
