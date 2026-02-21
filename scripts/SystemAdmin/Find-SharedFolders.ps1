<#
.SYNOPSIS
    Finds all shared folders on local or remote computers.

.DESCRIPTION
    Enumerates SMB shares on one or more computers using Get-SmbShare or the WMI
    Win32_Share class as a fallback. Displays share name, path, description, share
    type, and permissions with color-coded output. Administrative shares (ending in $)
    are highlighted separately. Results can be exported to CSV.

.PARAMETER ComputerName
    One or more computer names to query (default: localhost).

.PARAMETER IncludeAdminShares
    Include administrative shares whose names end with $.

.PARAMETER ExportPath
    File path for CSV export. When omitted, results are displayed only.

.EXAMPLE
    .\Find-SharedFolders.ps1
    Lists non-admin shares on the local computer.

.EXAMPLE
    .\Find-SharedFolders.ps1 -ComputerName "Server01","Server02" -IncludeAdminShares
    Lists all shares including admin shares on the specified servers.

.EXAMPLE
    .\Find-SharedFolders.ps1 -ExportPath "C:\Reports\shares.csv"
    Lists shares on localhost and exports results to CSV.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$ComputerName = @("localhost"),

    [Parameter(Mandatory = $false)]
    [switch]$IncludeAdminShares,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

function Get-ShareType {
    param([uint32]$Type)

    switch ($Type) {
        0          { "Disk Drive" }
        1          { "Print Queue" }
        2          { "Device" }
        3          { "IPC" }
        2147483648 { "Disk Drive (Admin)" }
        2147483649 { "Print Queue (Admin)" }
        2147483650 { "Device (Admin)" }
        2147483651 { "IPC (Admin)" }
        default    { "Unknown ($Type)" }
    }
}

function Get-SharePermissions {
    param(
        [string]$Computer,
        [string]$ShareName
    )

    try {
        $permissions = @()
        $secDescriptor = Get-CimInstance -ComputerName $Computer -ClassName Win32_LogicalShareSecuritySetting -Filter "Name='$ShareName'" -ErrorAction Stop
        $secInfo = Invoke-CimMethod -InputObject $secDescriptor -MethodName GetSecurityDescriptor -ErrorAction Stop

        if ($secInfo.ReturnValue -eq 0 -and $secInfo.Descriptor.DACL) {
            foreach ($ace in $secInfo.Descriptor.DACL) {
                $accessType = switch ($ace.AceType) {
                    0 { "Allow" }
                    1 { "Deny" }
                    default { "Other" }
                }
                $accessMask = switch ($ace.AccessMask) {
                    2032127   { "Full Control" }
                    1245631   { "Change" }
                    1179817   { "Read" }
                    default   { "Custom ($($ace.AccessMask))" }
                }
                $trustee = "$($ace.Trustee.Domain)\$($ace.Trustee.Name)"
                $permissions += "$trustee - $accessType - $accessMask"
            }
        }
        return ($permissions -join "; ")
    }
    catch {
        return "Unable to retrieve"
    }
}

# Main execution
Write-Host "`n=== Shared Folder Discovery ===" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "Computers to scan: $($ComputerName -join ', ')" -ForegroundColor White
Write-Host "Include admin shares: $IncludeAdminShares" -ForegroundColor White

$allResults = @()

foreach ($computer in $ComputerName) {
    Write-Host "`n--- Scanning: $computer ---" -ForegroundColor Cyan

    try {
        # Try Get-SmbShare first, fall back to WMI
        $shares = $null
        try {
            if ($computer -eq "localhost" -or $computer -eq $env:COMPUTERNAME) {
                $shares = Get-SmbShare -ErrorAction Stop | ForEach-Object {
                    [PSCustomObject]@{
                        Name        = $_.Name
                        Path        = $_.Path
                        Description = $_.Description
                        TypeCode    = $_.ShareType
                        TypeName    = $_.ShareType.ToString()
                        IsAdmin     = $_.Name -match '\$$'
                    }
                }
            }
            else {
                $shares = Invoke-Command -ComputerName $computer -ScriptBlock { Get-SmbShare } -ErrorAction Stop | ForEach-Object {
                    [PSCustomObject]@{
                        Name        = $_.Name
                        Path        = $_.Path
                        Description = $_.Description
                        TypeCode    = $_.ShareType
                        TypeName    = $_.ShareType.ToString()
                        IsAdmin     = $_.Name -match '\$$'
                    }
                }
            }
        }
        catch {
            Write-Host "  Get-SmbShare unavailable, using WMI fallback..." -ForegroundColor Yellow
            $wmiShares = Get-CimInstance -ComputerName $computer -ClassName Win32_Share -ErrorAction Stop
            $shares = $wmiShares | ForEach-Object {
                [PSCustomObject]@{
                    Name        = $_.Name
                    Path        = $_.Path
                    Description = $_.Description
                    TypeCode    = $_.Type
                    TypeName    = Get-ShareType -Type $_.Type
                    IsAdmin     = $_.Name -match '\$$'
                }
            }
        }

        if (-not $IncludeAdminShares) {
            $shares = $shares | Where-Object { -not $_.IsAdmin }
        }

        if ($shares.Count -eq 0) {
            Write-Host "  No shares found." -ForegroundColor Yellow
            continue
        }

        foreach ($share in $shares) {
            $permissions = Get-SharePermissions -Computer $computer -ShareName $share.Name
            $color = if ($share.IsAdmin) { "Magenta" } else { "White" }

            Write-Host "`n  Share: $($share.Name)" -ForegroundColor $color
            Write-Host "    Path:        $($share.Path)" -ForegroundColor White
            Write-Host "    Description: $($share.Description)" -ForegroundColor White
            Write-Host "    Type:        $($share.TypeName)" -ForegroundColor White
            Write-Host "    Permissions: $permissions" -ForegroundColor White

            if ($share.IsAdmin) {
                Write-Host "    [Administrative Share]" -ForegroundColor Magenta
            }

            $allResults += [PSCustomObject]@{
                ComputerName = $computer
                ShareName    = $share.Name
                Path         = $share.Path
                Description  = $share.Description
                ShareType    = $share.TypeName
                IsAdminShare = $share.IsAdmin
                Permissions  = $permissions
            }
        }

        # Per-computer summary
        $totalShares = ($shares | Measure-Object).Count
        $adminCount = ($shares | Where-Object { $_.IsAdmin } | Measure-Object).Count
        $standardCount = $totalShares - $adminCount

        Write-Host "`n  Total shares on ${computer}: $totalShares" -ForegroundColor Cyan
        Write-Host "    Standard: $standardCount" -ForegroundColor Green
        if ($IncludeAdminShares) {
            Write-Host "    Administrative: $adminCount" -ForegroundColor Magenta
        }
    }
    catch {
        Write-Host "  Failed to enumerate shares on ${computer}: $_" -ForegroundColor Red
    }
}

# Overall summary
Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "  Computers scanned: $($ComputerName.Count)" -ForegroundColor Cyan
Write-Host "  Total shares found: $($allResults.Count)" -ForegroundColor Cyan

$perComputer = $allResults | Group-Object ComputerName
foreach ($group in $perComputer) {
    Write-Host "    $($group.Name): $($group.Count) shares" -ForegroundColor White
}

# Export
if ($ExportPath -and $allResults.Count -gt 0) {
    $exportDir = Split-Path -Path $ExportPath -Parent
    if ($exportDir -and -not (Test-Path $exportDir)) {
        New-Item -Path $exportDir -ItemType Directory -Force | Out-Null
    }
    $allResults | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "`n  Results exported to: $ExportPath" -ForegroundColor Green
}
