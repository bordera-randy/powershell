<#
.SYNOPSIS
    Applies tags to Azure resources in a resource group.

.DESCRIPTION
    Merges provided tags with existing tags for resources in a resource group.
    Supports optional resource type filtering and tagging the resource group itself.
    Logs progress and outputs console messages during processing.

.PARAMETER ResourceGroupName
    Resource group to target.

.PARAMETER Tags
    Hashtable of tags to apply (e.g., @{ Environment = "Prod"; Owner = "IT" }).

.PARAMETER ResourceType
    Optional resource type filter (e.g., "Microsoft.Compute/virtualMachines").

.PARAMETER IncludeResourceGroup
    Also apply tags to the resource group itself.

.PARAMETER OutputDirectory
    Directory to write log files (default: <script>\logs).

.EXAMPLE
    .\Tag-AzureResources.ps1 -ResourceGroupName "Prod-RG" -Tags @{ Environment = "Prod"; Owner = "IT" }

.EXAMPLE
    .\Tag-AzureResources.ps1 -ResourceGroupName "Dev-RG" -ResourceType "Microsoft.Storage/storageAccounts" -Tags @{ Environment = "Dev" }

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Requires: Az.Resources
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [hashtable]$Tags,

    [Parameter(Mandatory = $false)]
    [string]$ResourceType,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs")
)

# Create output directory if missing
if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Tag-AzureResources_$timestamp.log"

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

if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    Write-Log "Az.Resources module not found. Install-Module -Name Az -Scope CurrentUser" "ERROR"
    exit 1
}

$context = Get-AzContext
if (-not $context) {
    Write-Log "Not authenticated. Run Connect-AzAccount first." "ERROR"
    exit 1
}

Write-Log "Starting tag update in resource group: $ResourceGroupName" "INFO"

try {
    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName

    if ($ResourceType) {
        $resources = $resources | Where-Object { $_.ResourceType -eq $ResourceType }
        Write-Log "Filtering resources by type: $ResourceType" "INFO"
    }

    foreach ($resource in $resources) {
        # Merge provided tags with existing tags
        $mergedTags = @{}
        if ($resource.Tags) {
            foreach ($entry in $resource.Tags.GetEnumerator()) {
                $mergedTags[$entry.Key] = $entry.Value
            }
        }
        foreach ($entry in $Tags.GetEnumerator()) {
            $mergedTags[$entry.Key] = $entry.Value
        }

        if ($PSCmdlet.ShouldProcess($resource.Name, "Update tags")) {
            Update-AzTag -ResourceId $resource.ResourceId -Tag $mergedTags -Operation Merge | Out-Null
            Write-Log "Updated tags for $($resource.Name)" "INFO"
        }
    }

    if ($IncludeResourceGroup) {
        # Merge and apply tags to the resource group itself
        $rg = Get-AzResourceGroup -Name $ResourceGroupName
        $rgTags = @{}
        if ($rg.Tags) {
            foreach ($entry in $rg.Tags.GetEnumerator()) {
                $rgTags[$entry.Key] = $entry.Value
            }
        }
        foreach ($entry in $Tags.GetEnumerator()) {
            $rgTags[$entry.Key] = $entry.Value
        }

        if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Update resource group tags")) {
            Set-AzResourceGroup -Name $ResourceGroupName -Tag $rgTags | Out-Null
            Write-Log "Updated tags for resource group $ResourceGroupName" "INFO"
        }
    }
}
catch {
    Write-Log "Failed to update tags. $_" "ERROR"
    exit 1
}

Write-Log "Tag update completed" "INFO"
