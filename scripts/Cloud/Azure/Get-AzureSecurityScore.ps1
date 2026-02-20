<#
.SYNOPSIS
    Gets Azure Secure Score and security recommendations.

.DESCRIPTION
    Retrieves Azure Security Center secure score, security tasks, and security
    assessments. Lists recommendations grouped by severity (High, Medium, Low)
    with color-coded console output and exports results to JSON and/or CSV
    with logging.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Json).

.PARAMETER SubscriptionId
    Target subscription ID. Uses current context subscription if not specified.

.EXAMPLE
    .\Get-AzureSecurityScore.ps1

.EXAMPLE
    .\Get-AzureSecurityScore.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000" -Format Both

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Requires: Az.Security
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Json","Csv","Both")]
    [string]$Format = "Json",

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Get-AzureSecurityScore_$timestamp.log"

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

if (-not (Get-Module -ListAvailable -Name Az.Security)) {
    Write-Log "Az.Security module not found. Install-Module -Name Az -Scope CurrentUser" "ERROR"
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
Write-Log "Collecting security score for subscription $currentSub" "INFO"

try {
    # Retrieve security tasks (recommendations)
    Write-Log "Retrieving security tasks" "INFO"
    $securityTasks = Get-AzSecurityTask

    # Retrieve security assessments
    Write-Log "Retrieving security assessments" "INFO"
    $assessments = Get-AzSecurityAssessment

    $recommendations = foreach ($assessment in $assessments) {
        $severity = $assessment.Status.Severity
        if (-not $severity) { $severity = "Unknown" }

        [PSCustomObject]@{
            Name             = $assessment.DisplayName
            Severity         = $severity
            Status           = $assessment.Status.Code
            Description      = $assessment.Status.Description
            ResourceId       = $assessment.Id
            Category         = $assessment.Status.Cause
        }
    }

    # Group by severity
    $highSeverity   = $recommendations | Where-Object { $_.Severity -eq "High" }
    $mediumSeverity = $recommendations | Where-Object { $_.Severity -eq "Medium" }
    $lowSeverity    = $recommendations | Where-Object { $_.Severity -eq "Low" }

    $highCount   = ($highSeverity | Measure-Object).Count
    $mediumCount = ($mediumSeverity | Measure-Object).Count
    $lowCount    = ($lowSeverity | Measure-Object).Count
    $totalCount  = ($recommendations | Measure-Object).Count

    # Color-coded output
    Write-Log "=== Security Recommendations Summary ===" "INFO"
    Write-Host "  High severity:   $highCount" -ForegroundColor Red
    Write-Host "  Medium severity: $mediumCount" -ForegroundColor Yellow
    Write-Host "  Low severity:    $lowCount" -ForegroundColor Green
    Write-Host "  Total:           $totalCount"
    Write-Log "High: $highCount, Medium: $mediumCount, Low: $lowCount, Total: $totalCount" "INFO"

    if ($highCount -gt 0) {
        Write-Log "=== High Severity Recommendations ===" "WARN"
        foreach ($rec in $highSeverity) {
            Write-Host "  [HIGH] $($rec.Name) - $($rec.Status)" -ForegroundColor Red
            Write-Log "  [HIGH] $($rec.Name) - Status: $($rec.Status)" "WARN"
        }
    }

    if ($mediumCount -gt 0) {
        Write-Log "=== Medium Severity Recommendations ===" "INFO"
        foreach ($rec in $mediumSeverity) {
            Write-Host "  [MEDIUM] $($rec.Name) - $($rec.Status)" -ForegroundColor Yellow
            Write-Log "  [MEDIUM] $($rec.Name) - Status: $($rec.Status)" "INFO"
        }
    }

    if ($lowCount -gt 0) {
        Write-Log "=== Low Severity Recommendations ===" "INFO"
        foreach ($rec in $lowSeverity) {
            Write-Host "  [LOW] $($rec.Name) - $($rec.Status)" -ForegroundColor Green
            Write-Log "  [LOW] $($rec.Name) - Status: $($rec.Status)" "INFO"
        }
    }

    # Security tasks summary
    $taskCount = ($securityTasks | Measure-Object).Count
    Write-Log "Security tasks found: $taskCount" "INFO"

    $exportData = [PSCustomObject]@{
        CollectedAt    = Get-Date
        SubscriptionId = $currentSub
        Summary        = [PSCustomObject]@{
            TotalRecommendations  = $totalCount
            HighSeverity          = $highCount
            MediumSeverity        = $mediumCount
            LowSeverity           = $lowCount
            SecurityTasks         = $taskCount
        }
        Recommendations = $recommendations
    }

    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "AzureSecurityScore_$timestamp.json"
        $exportData | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }

    if ($Format -in @("Csv","Both")) {
        $csvPath = Join-Path $OutputDirectory "AzureSecurityScore_$timestamp.csv"
        $recommendations | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV to $csvPath" "INFO"
    }
}
catch {
    Write-Log "Failed to retrieve security score: $_" "ERROR"
    throw
}

Write-Log "Security score collection complete" "INFO"
