<#
.SYNOPSIS
    Audits group memberships across the Active Directory domain.

.DESCRIPTION
    This script enumerates AD groups and their members, with optional nested group
    resolution. It highlights empty groups and groups with excessive membership counts,
    helping administrators identify security and hygiene issues. Results can be exported
    to CSV or JSON.

.PARAMETER GroupName
    Name or wildcard pattern for groups to audit (e.g., "Domain*" or "IT-Staff").
    Defaults to all groups ("*").

.PARAMETER IncludeNested
    Recursively resolve nested group memberships to show all effective members.

.PARAMETER SearchBase
    Distinguished name of the OU to search for groups.
    Defaults to the domain root.

.PARAMETER OutputPath
    Directory for export files (default: <script>\logs).

.PARAMETER ExportFormat
    Export format: CSV, JSON, or Both. When omitted results are displayed only.

.PARAMETER ExcessiveThreshold
    Member count above which a group is flagged as having excessive membership (default: 50).

.EXAMPLE
    .\Audit-GroupMemberships.ps1
    Audits all groups in the domain.

.EXAMPLE
    .\Audit-GroupMemberships.ps1 -GroupName "Domain Admins" -IncludeNested
    Audits the Domain Admins group with nested membership resolution.

.EXAMPLE
    .\Audit-GroupMemberships.ps1 -GroupName "Sales*" -ExportFormat CSV
    Audits all groups matching "Sales*" and exports to CSV.

.EXAMPLE
    .\Audit-GroupMemberships.ps1 -IncludeNested -ExcessiveThreshold 25 -ExportFormat Both
    Full audit with nested resolution, flags groups with more than 25 members.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$GroupName = "*",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeNested,

    [Parameter(Mandatory = $false)]
    [string]$SearchBase,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("CSV","JSON","Both")]
    [string]$ExportFormat,

    [Parameter(Mandatory = $false)]
    [int]$ExcessiveThreshold = 50
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputPath "Audit-GroupMemberships_$timestamp.log"

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
Write-Host "`n=== Active Directory Group Membership Audit ===" -ForegroundColor Green
Write-Log "Starting group membership audit (Pattern: $GroupName)"

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

# Retrieve groups
Write-Host "`nRetrieving groups matching '$GroupName'..." -ForegroundColor Yellow

try {
    $groups = Get-ADGroup -Filter "Name -like '$GroupName'" -SearchBase $SearchBase `
        -Properties Description, GroupScope, GroupCategory, WhenCreated, ManagedBy -ErrorAction Stop

    if ($groups.Count -eq 0) {
        Write-Host "No groups found matching '$GroupName'." -ForegroundColor Yellow
        Write-Log "No groups found" "WARN"
        exit 0
    }

    Write-Host "  Groups found: $($groups.Count)" -ForegroundColor Green
    Write-Log "Found $($groups.Count) groups"
}
catch {
    Write-Log "Failed to retrieve groups: $_" "ERROR"
    exit 1
}

$allResults = @()
$emptyGroups = @()
$excessiveGroups = @()

foreach ($group in $groups) {
    Write-Host "`n--- $($group.Name) ---" -ForegroundColor Yellow
    Write-Host "  Scope: $($group.GroupScope) | Category: $($group.GroupCategory)" -ForegroundColor Gray

    try {
        # Get members (recursive or direct)
        if ($IncludeNested) {
            $members = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive -ErrorAction Stop
        }
        else {
            $members = Get-ADGroupMember -Identity $group.DistinguishedName -ErrorAction Stop
        }

        $memberCount = @($members).Count

        # Check for empty groups
        if ($memberCount -eq 0) {
            Write-Host "  Members: 0 (EMPTY)" -ForegroundColor Red
            $emptyGroups += $group.Name
            Write-Log "Group '$($group.Name)' is empty" "WARN"

            $allResults += [PSCustomObject]@{
                GroupName       = $group.Name
                GroupScope      = $group.GroupScope.ToString()
                GroupCategory   = $group.GroupCategory.ToString()
                Description     = $group.Description
                WhenCreated     = $group.WhenCreated
                MemberCount     = 0
                MemberName      = $null
                MemberSamAccount = $null
                MemberType      = $null
                MemberEnabled   = $null
                IsEmpty         = $true
                IsExcessive     = $false
            }
            continue
        }

        # Check for excessive membership
        $isExcessive = $memberCount -gt $ExcessiveThreshold
        if ($isExcessive) {
            Write-Host "  Members: $memberCount (EXCESSIVE - exceeds $ExcessiveThreshold)" -ForegroundColor Red
            $excessiveGroups += $group.Name
            Write-Log "Group '$($group.Name)' has excessive membership ($memberCount)" "WARN"
        }
        else {
            Write-Host "  Members: $memberCount" -ForegroundColor Green
        }

        foreach ($member in $members) {
            $memberEnabled = $null
            if ($member.objectClass -eq "user") {
                try {
                    $adUser = Get-ADUser -Identity $member.SID -Properties Enabled -ErrorAction SilentlyContinue
                    $memberEnabled = $adUser.Enabled
                }
                catch {
                    Write-Verbose "Failed to resolve Enabled for member '$($member.SID)': $_"
                }
            }

            $result = [PSCustomObject]@{
                GroupName        = $group.Name
                GroupScope       = $group.GroupScope.ToString()
                GroupCategory    = $group.GroupCategory.ToString()
                Description      = $group.Description
                WhenCreated      = $group.WhenCreated
                MemberCount      = $memberCount
                MemberName       = $member.Name
                MemberSamAccount = $member.SamAccountName
                MemberType       = $member.objectClass
                MemberEnabled    = $memberEnabled
                IsEmpty          = $false
                IsExcessive      = $isExcessive
            }

            $allResults += $result

            # Color-coded member display
            $memberColor = switch ($member.objectClass) {
                "user"     { if ($memberEnabled -eq $false) { "Red" } else { "White" } }
                "group"    { "Cyan" }
                "computer" { "Gray" }
                default    { "White" }
            }

            Write-Host "    $($member.SamAccountName)" -ForegroundColor $memberColor -NoNewline
            Write-Host " [$($member.objectClass)]" -ForegroundColor Gray -NoNewline
            if ($member.objectClass -eq "user" -and $memberEnabled -eq $false) {
                Write-Host " (DISABLED)" -ForegroundColor Red
            }
            else {
                Write-Host ""
            }
        }
    }
    catch {
        Write-Log "Failed to get members of '$($group.Name)': $_" "ERROR"
    }
}

# --- Summary ---
Write-Host "`n=== Group Membership Audit Summary ===" -ForegroundColor Green
Write-Host "  Groups audited:         $($groups.Count)" -ForegroundColor Cyan
Write-Host "  Total membership entries: $($allResults.Count)" -ForegroundColor Cyan

if ($emptyGroups.Count -gt 0) {
    Write-Host "  Empty groups ($($emptyGroups.Count)):" -ForegroundColor Red
    foreach ($eg in $emptyGroups) {
        Write-Host "    - $eg" -ForegroundColor Red
    }
}
else {
    Write-Host "  Empty groups: 0" -ForegroundColor Green
}

if ($excessiveGroups.Count -gt 0) {
    Write-Host "  Excessive membership groups ($($excessiveGroups.Count)):" -ForegroundColor Yellow
    foreach ($xg in $excessiveGroups) {
        Write-Host "    - $xg" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  Excessive membership groups: 0" -ForegroundColor Green
}

# --- Export ---
if ($ExportFormat -and $allResults.Count -gt 0) {
    if ($ExportFormat -in @("CSV","Both")) {
        $csvPath = Join-Path $OutputPath "GroupMemberships_$timestamp.csv"
        $allResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Exported CSV to $csvPath"
        Write-Host "  CSV exported: $csvPath" -ForegroundColor Cyan
    }
    if ($ExportFormat -in @("JSON","Both")) {
        $jsonPath = Join-Path $OutputPath "GroupMemberships_$timestamp.json"
        $allResults | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Exported JSON to $jsonPath"
        Write-Host "  JSON exported: $jsonPath" -ForegroundColor Cyan
    }
}

Write-Host "  Log file: $logFile" -ForegroundColor Cyan
Write-Log "Group membership audit complete. Groups=$($groups.Count) Entries=$($allResults.Count)"
