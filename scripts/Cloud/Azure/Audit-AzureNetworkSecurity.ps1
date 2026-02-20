<#
.SYNOPSIS
    Audits Network Security Groups and firewall rules.

.DESCRIPTION
    Retrieves all Azure Network Security Groups, lists their rules, and
    highlights dangerous configurations such as open inbound rules from the
    internet, unrestricted port ranges, and any-source/any-destination rules.
    Shows associated subnets and NICs, provides a summary of total NSGs, rules,
    and high-risk rules, and exports results to JSON and/or CSV with logging.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Both).

.PARAMETER SubscriptionId
    Target subscription ID. Uses current context subscription if not specified.

.PARAMETER HighlightOpenRules
    Highlight dangerous rules with color-coded console output.

.EXAMPLE
    .\Audit-AzureNetworkSecurity.ps1

.EXAMPLE
    .\Audit-AzureNetworkSecurity.ps1 -HighlightOpenRules -Format Json

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Requires: Az.Network
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Json","Csv","Both")]
    [string]$Format = "Both",

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [switch]$HighlightOpenRules
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Audit-AzureNetworkSecurity_$timestamp.log"

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

if (-not (Get-Module -ListAvailable -Name Az.Network)) {
    Write-Log "Az.Network module not found. Install-Module -Name Az -Scope CurrentUser" "ERROR"
    exit 1
}

$context = Get-AzContext
if (-not $context) {
    Write-Log "Not authenticated. Run Connect-AzAccount first." "ERROR"
    exit 1
}

if ($SubscriptionId) {
    Write-Log "Switching to subscription $SubscriptionId" "INFO"
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

$currentSub = (Get-AzContext).Subscription.Id
Write-Log "Auditing Network Security Groups for subscription $currentSub" "INFO"

try {
    $nsgs = Get-AzNetworkSecurityGroup
    $nsgCount = ($nsgs | Measure-Object).Count
    Write-Log "Found $nsgCount Network Security Groups" "INFO"

    $allRules = @()
    $highRiskRules = @()

    foreach ($nsg in $nsgs) {
        $associatedSubnets = ($nsg.Subnets | ForEach-Object { $_.Id }) -join "; "
        $associatedNics    = ($nsg.NetworkInterfaces | ForEach-Object { $_.Id }) -join "; "

        $rules = $nsg.SecurityRules + $nsg.DefaultSecurityRules

        foreach ($rule in $rules) {
            $isDangerous = $false
            $riskReasons = @()

            # Check for any source
            if ($rule.SourceAddressPrefix -eq "*" -or $rule.SourceAddressPrefix -eq "0.0.0.0/0" -or $rule.SourceAddressPrefix -eq "Internet") {
                if ($rule.Access -eq "Allow" -and $rule.Direction -eq "Inbound") {
                    $isDangerous = $true
                    $riskReasons += "Inbound allow from any/internet"
                }
            }

            # Check for any destination
            if ($rule.DestinationAddressPrefix -eq "*") {
                if ($rule.Access -eq "Allow") {
                    $isDangerous = $true
                    $riskReasons += "Any destination"
                }
            }

            # Check for unrestricted port range
            if ($rule.DestinationPortRange -eq "*" -or $rule.DestinationPortRange -eq "0-65535") {
                if ($rule.Access -eq "Allow") {
                    $isDangerous = $true
                    $riskReasons += "All ports open (0-65535)"
                }
            }

            $ruleEntry = [PSCustomObject]@{
                NSGName              = $nsg.Name
                ResourceGroup        = $nsg.ResourceGroupName
                RuleName             = $rule.Name
                Priority             = $rule.Priority
                Direction            = $rule.Direction
                Access               = $rule.Access
                Protocol             = $rule.Protocol
                SourceAddressPrefix  = $rule.SourceAddressPrefix
                SourcePortRange      = $rule.SourcePortRange
                DestAddressPrefix    = $rule.DestinationAddressPrefix
                DestPortRange        = $rule.DestinationPortRange
                IsDangerous          = $isDangerous
                RiskReasons          = ($riskReasons -join "; ")
                AssociatedSubnets    = $associatedSubnets
                AssociatedNICs       = $associatedNics
            }

            $allRules += $ruleEntry

            if ($isDangerous) {
                $highRiskRules += $ruleEntry
            }
        }
    }

    $totalRules    = ($allRules | Measure-Object).Count
    $highRiskCount = ($highRiskRules | Measure-Object).Count

    Write-Log "=== Summary ===" "INFO"
    Write-Log "Total NSGs: $nsgCount" "INFO"
    Write-Log "Total rules: $totalRules" "INFO"
    Write-Log "High-risk rules: $highRiskCount" "WARN"

    if ($HighlightOpenRules -and $highRiskCount -gt 0) {
        Write-Log "=== High-Risk Rules ===" "WARN"
        foreach ($rule in $highRiskRules) {
            $msg = "  [RISK] NSG: $($rule.NSGName) | Rule: $($rule.RuleName) | $($rule.Direction) $($rule.Access) | Ports: $($rule.DestPortRange) | Reason: $($rule.RiskReasons)"
            Write-Host $msg -ForegroundColor Red
            Write-Log $msg "WARN"
        }
    }

    $exportData = [PSCustomObject]@{
        CollectedAt    = Get-Date
        SubscriptionId = $currentSub
        Summary        = [PSCustomObject]@{
            TotalNSGs     = $nsgCount
            TotalRules    = $totalRules
            HighRiskRules = $highRiskCount
        }
        Rules = $allRules
    }

    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "AzureNetworkSecurity_$timestamp.json"
        $exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }

    if ($Format -in @("Csv","Both")) {
        $csvPath = Join-Path $OutputDirectory "AzureNetworkSecurity_$timestamp.csv"
        $allRules | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV to $csvPath" "INFO"
    }
}
catch {
    Write-Log "Failed to audit network security: $_" "ERROR"
    throw
}

Write-Log "Network security audit complete" "INFO"
