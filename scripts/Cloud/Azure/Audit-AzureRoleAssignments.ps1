<#
.SYNOPSIS
    Audits Azure role assignments and exports results.

.DESCRIPTION
    Lists Azure role assignments at subscription or resource group scope and exports
    results to CSV/JSON with logging.

.PARAMETER ResourceGroupName
    Limit audit to a specific resource group.

.PARAMETER Scope
    Provide a custom scope (e.g., /subscriptions/<id>/resourceGroups/<rg>). Overrides ResourceGroupName.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Csv, Json, or Both (default: Csv).

.EXAMPLE
    .\Audit-AzureRoleAssignments.ps1

.EXAMPLE
    .\Audit-AzureRoleAssignments.ps1 -ResourceGroupName "Prod-RG" -Format Both

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Requires: Az.Accounts, Az.Resources
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$Scope,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Csv","Json","Both")]
    [string]$Format = "Csv"
)

# Create output directory if missing
if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Audit-AzureRoleAssignments_$timestamp.log"

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

# Validate Az modules
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Log "Az.Accounts module not found. Install-Module -Name Az -Scope CurrentUser" "ERROR"
    exit 1
}

if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    Write-Log "Az.Resources module not found. Install-Module -Name Az -Scope CurrentUser" "ERROR"
    exit 1
}

$context = Get-AzContext
if (-not $context) {
    Write-Log "Not authenticated. Run Connect-AzAccount first." "ERROR"
    exit 1
}

$subscriptionId = $context.Subscription.Id

if ($Scope) {
    $targetScope = $Scope
} elseif ($ResourceGroupName) {
    $targetScope = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName"
} else {
    $targetScope = "/subscriptions/$subscriptionId"
}

Write-Log "Collecting role assignments for scope: $targetScope" "INFO"

try {
    $assignments = Get-AzRoleAssignment -Scope $targetScope | Select-Object 
        RoleDefinitionName,
        PrincipalName,
        DisplayName,
        ObjectType,
        Scope,
        SignInName,
        ObjectId

    if ($Format -in @("Csv","Both")) {
        $csvPath = Join-Path $OutputDirectory "RoleAssignments_$timestamp.csv"
        $assignments | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV to $csvPath" "INFO"
    }

    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "RoleAssignments_$timestamp.json"
        $assignments | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }
}
catch {
    Write-Log "Failed to collect role assignments. $_" "ERROR"
    exit 1
}

Write-Log "Role assignment audit complete" "INFO"
