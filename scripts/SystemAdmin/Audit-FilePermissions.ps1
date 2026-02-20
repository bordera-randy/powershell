<#
.SYNOPSIS
    Audits NTFS file and folder permissions.

.DESCRIPTION
    This script enumerates NTFS permissions on a specified folder path using Get-Acl.
    It displays the identity, access rights, access type (Allow/Deny), and whether
    the permission is inherited. Deny rules and broad permissions granted to Everyone
    or Authenticated Users are highlighted. Results can be exported to CSV.

.PARAMETER Path
    The folder path to audit for NTFS permissions.

.PARAMETER Recurse
    Recursively audit subfolders.

.PARAMETER Depth
    Maximum recursion depth when -Recurse is specified (default: 3).

.PARAMETER ExportPath
    File path for CSV export. When omitted results are displayed only.

.EXAMPLE
    .\Audit-FilePermissions.ps1 -Path "C:\Shared"
    Audits permissions on the C:\Shared folder only.

.EXAMPLE
    .\Audit-FilePermissions.ps1 -Path "C:\Data" -Recurse -Depth 2
    Audits permissions on C:\Data and subfolders up to 2 levels deep.

.EXAMPLE
    .\Audit-FilePermissions.ps1 -Path "D:\Projects" -Recurse -ExportPath "C:\Reports\perms.csv"
    Audits permissions recursively and exports to CSV.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [int]$Depth = 3,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== NTFS Permission Audit ===" -ForegroundColor Green
Write-Host "  Target path: $Path" -ForegroundColor Cyan
Write-Host "  Recurse: $Recurse | Max depth: $Depth" -ForegroundColor Cyan

if (-not (Test-Path $Path)) {
    Write-Host "  ERROR: Path '$Path' does not exist." -ForegroundColor Red
    exit 1
}

# Build list of paths to audit
$pathsToAudit = @($Path)

if ($Recurse) {
    try {
        $childItems = Get-ChildItem -Path $Path -Directory -Recurse -Depth $Depth -ErrorAction SilentlyContinue
        $pathsToAudit += $childItems.FullName
        Write-Host "  Folders to audit: $($pathsToAudit.Count)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "  Warning: Some folders could not be enumerated: $_" -ForegroundColor Yellow
    }
}

$allResults = @()
$denyCount = 0
$broadAccessCount = 0
$allowCount = 0
$inheritedCount = 0
$explicitCount = 0

foreach ($auditPath in $pathsToAudit) {
    try {
        $acl = Get-Acl -Path $auditPath -ErrorAction Stop

        foreach ($ace in $acl.Access) {
            $identity     = $ace.IdentityReference.ToString()
            $accessRights = $ace.FileSystemRights.ToString()
            $accessType   = $ace.AccessControlType.ToString()
            $isInherited  = $ace.IsInherited

            $result = [PSCustomObject]@{
                Path         = $auditPath
                Identity     = $identity
                AccessRights = $accessRights
                AccessType   = $accessType
                IsInherited  = $isInherited
            }

            $allResults += $result

            # Track counts
            if ($accessType -eq "Allow") { $allowCount++ } else { $denyCount++ }
            if ($isInherited) { $inheritedCount++ } else { $explicitCount++ }

            $isBroadAccess = $identity -match "Everyone|Authenticated Users|BUILTIN\\Users"
            if ($isBroadAccess) { $broadAccessCount++ }

            # Color-coded display
            $isDeny = ($accessType -eq "Deny")

            if ($isDeny) {
                Write-Host "    [DENY] " -ForegroundColor Red -NoNewline
                Write-Host "$auditPath" -ForegroundColor Red -NoNewline
                Write-Host " | $identity | $accessRights" -ForegroundColor Red
            }
            elseif ($isBroadAccess) {
                Write-Host "    [BROAD] " -ForegroundColor Yellow -NoNewline
                Write-Host "$auditPath" -ForegroundColor Yellow -NoNewline
                Write-Host " | $identity | $accessRights" -ForegroundColor Yellow
            }
            else {
                $inheritTag = if ($isInherited) { "(inherited)" } else { "(explicit)" }
                Write-Host "    $auditPath" -ForegroundColor White -NoNewline
                Write-Host " | $identity | $accessRights | $accessType $inheritTag" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-Host "    Could not read ACL for '$auditPath': $_" -ForegroundColor Red
    }
}

# --- Summary ---
Write-Host "`n=== Permission Audit Summary ===" -ForegroundColor Green
Write-Host "  Folders audited:      $($pathsToAudit.Count)" -ForegroundColor Cyan
Write-Host "  Total ACE entries:    $($allResults.Count)" -ForegroundColor Cyan
Write-Host "  Allow rules:          $allowCount" -ForegroundColor Green
Write-Host "  Deny rules:           $denyCount" -ForegroundColor $(if ($denyCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Inherited:            $inheritedCount" -ForegroundColor Cyan
Write-Host "  Explicit:             $explicitCount" -ForegroundColor Cyan
Write-Host "  Broad access entries: $broadAccessCount" -ForegroundColor $(if ($broadAccessCount -gt 0) { "Yellow" } else { "Green" })

if ($denyCount -gt 0) {
    Write-Host "  ** $denyCount Deny rule(s) found - review recommended **" -ForegroundColor Red
}
if ($broadAccessCount -gt 0) {
    Write-Host "  ** $broadAccessCount broad access entry/entries (Everyone/Authenticated Users) found **" -ForegroundColor Yellow
}

# --- Export ---
if ($ExportPath -and $allResults.Count -gt 0) {
    try {
        $exportDir = Split-Path -Path $ExportPath -Parent
        if ($exportDir -and -not (Test-Path $exportDir)) {
            New-Item -Path $exportDir -ItemType Directory -Force | Out-Null
        }
        $allResults | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
        Write-Host "`n  CSV exported: $ExportPath" -ForegroundColor Green
    }
    catch {
        Write-Host "`n  Failed to export CSV: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Audit Complete ===" -ForegroundColor Green
