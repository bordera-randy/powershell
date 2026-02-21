<#
.SYNOPSIS
    Finds local administrator group members on one or more servers.

.DESCRIPTION
    This script enumerates members of the local Administrators group on specified
    computers. It identifies each member's type (User/Group), source (Local/Domain),
    and SID. Domain accounts in the local admin group are highlighted as potential
    security concerns. Results can be exported to CSV.

.PARAMETER ComputerName
    One or more computer names to audit (default: localhost).

.PARAMETER ExportPath
    File path for CSV export. When omitted results are displayed only.

.EXAMPLE
    .\Audit-LocalAdmins.ps1
    Lists local administrator members on the local computer.

.EXAMPLE
    .\Audit-LocalAdmins.ps1 -ComputerName "SERVER01","SERVER02"
    Audits local admin group on multiple servers.

.EXAMPLE
    .\Audit-LocalAdmins.ps1 -ComputerName "SERVER01" -ExportPath "C:\Reports\admins.csv"
    Audits SERVER01 and exports results to CSV.

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
    [string]$ExportPath
)

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Local Administrator Group Audit ===" -ForegroundColor Green
Write-Host "  Target computers: $($ComputerName -join ', ')" -ForegroundColor Cyan

$allResults = @()

foreach ($computer in $ComputerName) {
    Write-Host "`n--- $computer ---" -ForegroundColor Yellow

    try {
        $members = @()

        if ($computer -eq "localhost" -or $computer -eq $env:COMPUTERNAME) {
            # Local computer - try Get-LocalGroupMember first
            try {
                $localMembers = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop

                foreach ($member in $localMembers) {
                    $source = if ($member.PrincipalSource) { $member.PrincipalSource.ToString() } else {
                        if ($member.Name -match "^$env:COMPUTERNAME\\") { "Local" } else { "Domain" }
                    }

                    $members += [PSCustomObject]@{
                        ComputerName = $computer
                        UserName     = $member.Name
                        Type         = $member.ObjectClass
                        Source       = $source
                        SID          = $member.SID.Value
                    }
                }
            }
            catch {
                Write-Host "  Get-LocalGroupMember not available, falling back to net localgroup" -ForegroundColor Yellow
                $output = net localgroup Administrators 2>&1
                $inMembers = $false

                foreach ($line in $output) {
                    if ($line -match "^-+$") { $inMembers = $true; continue }
                    if ($line -match "^The command completed") { $inMembers = $false; continue }
                    if ($inMembers -and $line.Trim()) {
                        $name = $line.Trim()
                        $source = if ($name -match "\\") { "Domain" } else { "Local" }
                        $type = "User"

                        $members += [PSCustomObject]@{
                            ComputerName = $computer
                            UserName     = $name
                            Type         = $type
                            Source       = $source
                            SID          = "N/A"
                        }
                    }
                }
            }
        }
        else {
            # Remote computer - use Invoke-Command with Get-LocalGroupMember or net localgroup
            try {
                $remoteMembers = Invoke-Command -ComputerName $computer -ScriptBlock {
                    try {
                        $results = @()
                        $localMembers = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
                        foreach ($m in $localMembers) {
                            $src = if ($m.PrincipalSource) { $m.PrincipalSource.ToString() } else {
                                if ($m.Name -match "^$env:COMPUTERNAME\\") { "Local" } else { "Domain" }
                            }
                            $results += [PSCustomObject]@{
                                UserName = $m.Name
                                Type     = $m.ObjectClass
                                Source   = $src
                                SID      = $m.SID.Value
                            }
                        }
                        return $results
                    }
                    catch {
                        $results = @()
                        $output = net localgroup Administrators 2>&1
                        $inMembers = $false
                        foreach ($line in $output) {
                            if ($line -match "^-+$") { $inMembers = $true; continue }
                            if ($line -match "^The command completed") { $inMembers = $false; continue }
                            if ($inMembers -and $line.Trim()) {
                                $name = $line.Trim()
                                $src = if ($name -match "\\") { "Domain" } else { "Local" }
                                $results += [PSCustomObject]@{
                                    UserName = $name
                                    Type     = "User"
                                    Source   = $src
                                    SID      = "N/A"
                                }
                            }
                        }
                        return $results
                    }
                } -ErrorAction Stop

                foreach ($rm in $remoteMembers) {
                    $members += [PSCustomObject]@{
                        ComputerName = $computer
                        UserName     = $rm.UserName
                        Type         = $rm.Type
                        Source       = $rm.Source
                        SID          = $rm.SID
                    }
                }
            }
            catch {
                Write-Host "  Failed to connect to $computer`: $_" -ForegroundColor Red
                continue
            }
        }

        if ($members.Count -eq 0) {
            Write-Host "  No members found in Administrators group." -ForegroundColor Yellow
            continue
        }

        Write-Host "  Members found: $($members.Count)" -ForegroundColor Cyan

        foreach ($member in $members) {
            $nameColor = if ($member.Source -eq "Domain") { "Yellow" } else { "White" }
            $sourceTag = if ($member.Source -eq "Domain") { " [DOMAIN]" } else { "" }

            Write-Host "    $($member.UserName)" -ForegroundColor $nameColor -NoNewline
            Write-Host " | Type: $($member.Type)" -ForegroundColor Gray -NoNewline
            Write-Host " | Source: $($member.Source)$sourceTag" -ForegroundColor $nameColor -NoNewline
            Write-Host " | SID: $($member.SID)" -ForegroundColor Gray
        }

        $domainCount = ($members | Where-Object { $_.Source -eq "Domain" }).Count
        if ($domainCount -gt 0) {
            Write-Host "  ** $domainCount domain account(s) in local Administrators group **" -ForegroundColor Yellow
        }

        $allResults += $members
    }
    catch {
        Write-Host "  Error auditing $computer`: $_" -ForegroundColor Red
    }
}

# --- Summary ---
Write-Host "`n=== Audit Summary ===" -ForegroundColor Green
Write-Host "  Computers audited:      $($ComputerName.Count)" -ForegroundColor Cyan
Write-Host "  Total admin members:    $($allResults.Count)" -ForegroundColor Cyan

$totalDomain = ($allResults | Where-Object { $_.Source -eq "Domain" }).Count
$totalLocal  = ($allResults | Where-Object { $_.Source -eq "Local" }).Count
Write-Host "  Local accounts:         $totalLocal" -ForegroundColor Green
Write-Host "  Domain accounts:        $totalDomain" -ForegroundColor Yellow

$perComputer = $allResults | Group-Object -Property ComputerName
foreach ($group in $perComputer) {
    Write-Host "    $($group.Name): $($group.Count) member(s)" -ForegroundColor Cyan
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
