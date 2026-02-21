<#
.SYNOPSIS
    Audits Active Directory permissions and ACLs on Organizational Units.

.DESCRIPTION
    This script retrieves and reports Access Control Lists (ACLs) on Active Directory
    organizational units and objects. It identifies non-default and custom permissions,
    helping administrators detect privilege drift and unauthorized delegation. Results
    can be exported to CSV.

.PARAMETER SearchBase
    Distinguished name of the OU to audit (e.g., "OU=IT,DC=contoso,DC=com").
    Defaults to the domain root.

.PARAMETER Recurse
    Include child OUs in the audit.

.PARAMETER IncludeInherited
    Include inherited permissions in the report. By default only explicit (non-inherited)
    permissions are shown.

.PARAMETER OutputPath
    Directory for export files (default: <script>\logs).

.PARAMETER ExportFormat
    Export format: CSV, JSON, or Both. When omitted results are displayed only.

.EXAMPLE
    .\Audit-ADPermissions.ps1
    Audits permissions on the domain root OU.

.EXAMPLE
    .\Audit-ADPermissions.ps1 -SearchBase "OU=IT,DC=contoso,DC=com" -Recurse
    Audits permissions on the IT OU and all child OUs.

.EXAMPLE
    .\Audit-ADPermissions.ps1 -Recurse -IncludeInherited -ExportFormat CSV
    Full audit with inherited permissions exported to CSV.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SearchBase,

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeInherited,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("CSV","JSON","Both")]
    [string]$ExportFormat
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputPath "Audit-ADPermissions_$timestamp.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $logFile -Value $line

    switch ($Level) {
        "INFO"  { Write-Host $line -ForegroundColor Cyan }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "ERROR" { Write-Host $line -ForegroundColor Red }
    }
}

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Active Directory Permissions Audit ===" -ForegroundColor Green
Write-Log "Starting AD permissions audit"

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Log "ActiveDirectory module loaded"
}
catch {
    Write-Log "ActiveDirectory module is not available. $_" "ERROR"
    exit 1
}

# Determine search base
if (-not $SearchBase) {
    $SearchBase = (Get-ADDomain).DistinguishedName
    Write-Log "No SearchBase specified. Using domain root: $SearchBase"
}

# Collect target OUs
try {
    $targetOUs = @()
    $targetOUs += Get-ADOrganizationalUnit -Identity $SearchBase -ErrorAction Stop

    if ($Recurse) {
        $targetOUs = Get-ADOrganizationalUnit -Filter * -SearchBase $SearchBase -SearchScope Subtree -ErrorAction Stop
        Write-Log "Recursive search enabled. Found $($targetOUs.Count) OUs under $SearchBase"
    }
    else {
        Write-Log "Auditing single OU: $SearchBase"
    }
}
catch {
    Write-Log "Failed to retrieve OUs from '$SearchBase': $_" "ERROR"
    exit 1
}

# Well-known SIDs to identify default/built-in permissions
$defaultIdentities = @(
    "NT AUTHORITY\SYSTEM",
    "NT AUTHORITY\SELF",
    "NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS",
    "BUILTIN\Administrators",
    "BUILTIN\Account Operators",
    "BUILTIN\Pre-Windows 2000 Compatible Access"
)

$allResults = @()

foreach ($ou in $targetOUs) {
    Write-Host "`n--- Auditing: $($ou.DistinguishedName) ---" -ForegroundColor Yellow

    try {
        $adPath = "AD:\$($ou.DistinguishedName)"
        $acl = Get-Acl -Path $adPath -ErrorAction Stop
        $accessRules = $acl.Access

        if (-not $IncludeInherited) {
            $accessRules = $accessRules | Where-Object { -not $_.IsInherited }
        }

        if ($accessRules.Count -eq 0) {
            Write-Host "  No matching ACEs found." -ForegroundColor Green
            Write-Log "No matching ACEs on $($ou.DistinguishedName)"
            continue
        }

        Write-Host "  ACEs found: $($accessRules.Count)" -ForegroundColor Cyan

        foreach ($ace in $accessRules) {
            $identity = $ace.IdentityReference.ToString()
            $isDefault = $defaultIdentities -contains $identity

            $result = [PSCustomObject]@{
                OU                = $ou.DistinguishedName
                IdentityReference = $identity
                AccessControlType = $ace.AccessControlType.ToString()
                ActiveDirectoryRights = $ace.ActiveDirectoryRights.ToString()
                InheritanceType   = $ace.InheritanceType.ToString()
                IsInherited       = $ace.IsInherited
                IsDefaultEntry    = $isDefault
                ObjectType        = $ace.ObjectType.ToString()
                InheritedObjectType = $ace.InheritedObjectType.ToString()
            }

            $allResults += $result

            # Color-coded display
            if ($ace.AccessControlType -eq "Deny") {
                $color = "Red"
            }
            elseif ($isDefault) {
                $color = "Gray"
            }
            else {
                $color = "Yellow"
            }

            Write-Host "    $identity" -ForegroundColor $color -NoNewline
            Write-Host " | $($ace.AccessControlType)" -ForegroundColor $color -NoNewline
            Write-Host " | $($ace.ActiveDirectoryRights)" -ForegroundColor White -NoNewline
            Write-Host " | Inherited: $($ace.IsInherited)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Log "Failed to read ACL on '$($ou.DistinguishedName)': $_" "ERROR"
    }
}

# --- Summary ---
Write-Host "`n=== Permissions Audit Summary ===" -ForegroundColor Green
Write-Host "  OUs audited:          $($targetOUs.Count)" -ForegroundColor Cyan
Write-Host "  Total ACEs found:     $($allResults.Count)" -ForegroundColor Cyan

$customACEs = $allResults | Where-Object { -not $_.IsDefaultEntry }
Write-Host "  Custom/non-default:   $($customACEs.Count)" -ForegroundColor Yellow

$denyACEs = $allResults | Where-Object { $_.AccessControlType -eq "Deny" }
if ($denyACEs.Count -gt 0) {
    Write-Host "  Deny ACEs:            $($denyACEs.Count)" -ForegroundColor Red
}

$explicitACEs = $allResults | Where-Object { -not $_.IsInherited }
Write-Host "  Explicit (non-inherited): $($explicitACEs.Count)" -ForegroundColor Cyan

# --- Export ---
if ($ExportFormat -and $allResults.Count -gt 0) {
    if ($ExportFormat -in @("CSV","Both")) {
        $csvPath = Join-Path $OutputPath "ADPermissions_$timestamp.csv"
        $allResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Exported CSV to $csvPath"
        Write-Host "  CSV exported: $csvPath" -ForegroundColor Cyan
    }
    if ($ExportFormat -in @("JSON","Both")) {
        $jsonPath = Join-Path $OutputPath "ADPermissions_$timestamp.json"
        $allResults | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Exported JSON to $jsonPath"
        Write-Host "  JSON exported: $jsonPath" -ForegroundColor Cyan
    }
}

Write-Host "  Log file: $logFile" -ForegroundColor Cyan
Write-Log "Permissions audit complete. Total ACEs=$($allResults.Count)"
