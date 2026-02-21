<#
.SYNOPSIS
    Audits Microsoft 365 admin role assignments.

.DESCRIPTION
    Retrieves all directory role assignments using Microsoft Graph, listing each
    admin role with its members. Shows role name, member display name, UPN, and
    member type. Highlights Global Administrator assignments and accounts without
    MFA enabled. Provides a summary of total roles, total assignments, and users
    holding multiple admin roles. Exports results to JSON and/or CSV with logging.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Both).

.PARAMETER IncludeGroupAssignments
    When specified, includes group-based role assignments in addition to direct
    user assignments.

.EXAMPLE
    .\Audit-M365AdminRoles.ps1
    Audits all admin role assignments with default settings.

.EXAMPLE
    .\Audit-M365AdminRoles.ps1 -IncludeGroupAssignments -Format Json
    Audits admin roles including group assignments and exports as JSON.

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
    [string]$Format = "Both",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeGroupAssignments
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Audit-M365AdminRoles_$timestamp.log"

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

Write-Log "Starting Microsoft 365 admin role audit" "INFO"

try {
    # Retrieve all activated directory roles
    Write-Log "Retrieving directory roles" "INFO"
    $roles = Get-MgDirectoryRole -All -ErrorAction Stop

    Write-Log "Found $($roles.Count) active directory role(s)" "INFO"

    $roleAssignments = @()
    $userRoleMap = @{}

    foreach ($role in $roles) {
        Write-Log "Processing role: $($role.DisplayName)" "INFO"

        $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All -ErrorAction Stop

        foreach ($member in $members) {
            $memberType = $member.AdditionalProperties.'@odata.type' -replace '#microsoft.graph.', ''

            # Skip group assignments unless requested
            if ($memberType -eq 'group' -and -not $IncludeGroupAssignments) {
                continue
            }

            $displayName = $member.AdditionalProperties.displayName
            $upn = $member.AdditionalProperties.userPrincipalName

            $entry = [PSCustomObject]@{
                RoleName        = $role.DisplayName
                RoleId          = $role.Id
                MemberDisplayName = $displayName
                MemberUPN       = $upn
                MemberId        = $member.Id
                MemberType      = $memberType
                AssignmentType  = "Direct"
                IsGlobalAdmin   = $role.DisplayName -eq "Global Administrator"
            }

            $roleAssignments += $entry

            # Track users with multiple roles
            if ($memberType -eq 'user' -and $upn) {
                if (-not $userRoleMap.ContainsKey($upn)) {
                    $userRoleMap[$upn] = @()
                }
                $userRoleMap[$upn] += $role.DisplayName
            }

            if ($role.DisplayName -eq "Global Administrator") {
                Write-Log "Global Administrator: $displayName ($upn)" "WARN"
            }
        }
    }

    Write-Log "Collected $($roleAssignments.Count) role assignment(s)" "INFO"

    # Check MFA status for admin users
    Write-Log "Checking MFA registration for admin users" "INFO"
    $usersWithoutMFA = @()

    $adminUPNs = $userRoleMap.Keys | Sort-Object -Unique
    foreach ($upn in $adminUPNs) {
        try {
            $authMethods = Get-MgUserAuthenticationMethod -UserId $upn -ErrorAction Stop
            # A user with only the password method has no MFA
            $hasMFA = ($authMethods | Where-Object {
                $_.AdditionalProperties.'@odata.type' -ne '#microsoft.graph.passwordAuthenticationMethod'
            }).Count -gt 0

            if (-not $hasMFA) {
                $usersWithoutMFA += $upn
                Write-Log "Admin without MFA: $upn (Roles: $($userRoleMap[$upn] -join ', '))" "WARN"
            }
        }
        catch {
            Write-Log "Could not check MFA for $upn - $_" "WARN"
        }
    }

    # Identify users with multiple admin roles
    $multiRoleUsers = $userRoleMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
    foreach ($user in $multiRoleUsers) {
        Write-Log "Multiple roles: $($user.Key) has $($user.Value.Count) role(s): $($user.Value -join ', ')" "INFO"
    }

    # Build summary
    $globalAdminCount = ($roleAssignments | Where-Object { $_.IsGlobalAdmin }).Count

    $summary = [PSCustomObject]@{
        ReportGeneratedAt       = Get-Date
        TotalRoles              = $roles.Count
        TotalAssignments        = $roleAssignments.Count
        GlobalAdminAssignments  = $globalAdminCount
        UniqueAdminUsers        = $adminUPNs.Count
        UsersWithMultipleRoles  = @($multiRoleUsers).Count
        AdminsWithoutMFA        = $usersWithoutMFA.Count
        IncludedGroupAssignments = [bool]$IncludeGroupAssignments
    }

    Write-Log "Summary - Roles: $($roles.Count) | Assignments: $($roleAssignments.Count) | Global Admins: $globalAdminCount | Without MFA: $($usersWithoutMFA.Count)" "INFO"

    # Build full report object
    $report = [PSCustomObject]@{
        Summary             = $summary
        RoleAssignments     = $roleAssignments
        UsersWithoutMFA     = $usersWithoutMFA
        MultiRoleUsers      = @($multiRoleUsers | ForEach-Object {
            [PSCustomObject]@{
                UserPrincipalName = $_.Key
                RoleCount         = $_.Value.Count
                Roles             = ($_.Value -join "; ")
            }
        })
    }

    # Export results
    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "M365AdminRoles_$timestamp.json"
        $report | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }

    if ($Format -in @("Csv","Both")) {
        $csvPath = Join-Path $OutputDirectory "M365AdminRoles_$timestamp.csv"
        $roleAssignments | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV to $csvPath" "INFO"
    }
}
catch {
    Write-Log "Failed to audit admin roles: $_" "ERROR"
    throw
}

Write-Log "Admin role audit complete" "INFO"
