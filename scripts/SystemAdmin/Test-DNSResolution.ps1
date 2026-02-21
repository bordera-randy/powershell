<#
.SYNOPSIS
    Tests DNS resolution across multiple DNS servers.

.DESCRIPTION
    Resolves one or more domain names against one or more DNS servers, compares the
    results, and identifies discrepancies. Supports A, AAAA, MX, CNAME, NS, and TXT
    record types. Results are color-coded to highlight matching and mismatching
    responses. Results can be exported to CSV.

.PARAMETER DomainName
    One or more domain names to resolve.

.PARAMETER DNSServer
    One or more DNS server IP addresses or hostnames to query against.

.PARAMETER RecordType
    DNS record type to query (default: A). Valid values: A, AAAA, MX, CNAME, NS, TXT.

.PARAMETER ExportPath
    File path for CSV export. When omitted, results are displayed only.

.EXAMPLE
    .\Test-DNSResolution.ps1 -DomainName "example.com" -DNSServer "8.8.8.8","1.1.1.1"
    Resolves example.com against Google and Cloudflare DNS.

.EXAMPLE
    .\Test-DNSResolution.ps1 -DomainName "example.com","contoso.com" -DNSServer "8.8.8.8" -RecordType MX
    Queries MX records for two domains against Google DNS.

.EXAMPLE
    .\Test-DNSResolution.ps1 -DomainName "example.com" -DNSServer "8.8.8.8","1.1.1.1" -ExportPath "C:\Reports\dns.csv"
    Resolves and exports the comparison to CSV.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$DomainName,

    [Parameter(Mandatory = $true)]
    [string[]]$DNSServer,

    [Parameter(Mandatory = $false)]
    [ValidateSet("A", "AAAA", "MX", "CNAME", "NS", "TXT")]
    [string]$RecordType = "A",

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

function Resolve-DnsQuery {
    param(
        [string]$Domain,
        [string]$Server,
        [string]$Type
    )

    try {
        $result = Resolve-DnsName -Name $Domain -Server $Server -Type $Type -DnsOnly -ErrorAction Stop

        $records = switch ($Type) {
            "A"     { ($result | Where-Object { $_.QueryType -eq "A" }).IPAddress }
            "AAAA"  { ($result | Where-Object { $_.QueryType -eq "AAAA" }).IPAddress }
            "MX"    { ($result | Where-Object { $_.QueryType -eq "MX" }) | ForEach-Object { "$($_.Preference) $($_.NameExchange)" } }
            "CNAME" { ($result | Where-Object { $_.QueryType -eq "CNAME" }).NameHost }
            "NS"    { ($result | Where-Object { $_.QueryType -eq "NS" }).NameHost }
            "TXT"   { ($result | Where-Object { $_.QueryType -eq "TXT" }).Strings }
        }

        if ($records) {
            return ($records | Sort-Object) -join "; "
        }
        else {
            return "No records found"
        }
    }
    catch {
        return "Error: $($_.Exception.Message)"
    }
}

# Main execution
Write-Host "`n=== DNS Resolution Test ===" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host "Domains:     $($DomainName -join ', ')" -ForegroundColor White
Write-Host "DNS Servers: $($DNSServer -join ', ')" -ForegroundColor White
Write-Host "Record Type: $RecordType" -ForegroundColor White

$allResults = @()
$matchCount = 0
$mismatchCount = 0
$totalQueries = $DomainName.Count * $DNSServer.Count
$currentQuery = 0

foreach ($domain in $DomainName) {
    Write-Host "`n--- $domain ($RecordType) ---" -ForegroundColor Cyan

    $domainResults = @()

    foreach ($server in $DNSServer) {
        $currentQuery++
        $percentComplete = [math]::Round(($currentQuery / $totalQueries) * 100)
        Write-Progress -Activity "Resolving DNS" -Status "$domain via $server" -PercentComplete $percentComplete

        $resolvedValue = Resolve-DnsQuery -Domain $domain -Server $server -Type $RecordType

        $domainResults += [PSCustomObject]@{
            DomainName   = $domain
            DNSServer    = $server
            RecordType   = $RecordType
            Result       = $resolvedValue
            Status       = ""
        }

        $isError = $resolvedValue -like "Error:*"
        $color = if ($isError) { "Red" } else { "White" }
        Write-Host "  Server $server : $resolvedValue" -ForegroundColor $color
    }

    # Compare results across servers for this domain
    $uniqueResults = $domainResults | Where-Object { $_.Result -notlike "Error:*" } | Select-Object -ExpandProperty Result -Unique
    $isConsistent = ($uniqueResults | Measure-Object).Count -le 1

    foreach ($dr in $domainResults) {
        if ($dr.Result -like "Error:*") {
            $dr.Status = "Error"
        }
        elseif ($isConsistent) {
            $dr.Status = "Match"
        }
        else {
            $dr.Status = "Mismatch"
        }
    }

    if ($isConsistent) {
        $matchCount++
        Write-Host "  Result: CONSISTENT" -ForegroundColor Green
    }
    else {
        $mismatchCount++
        Write-Host "  Result: DISCREPANCY DETECTED" -ForegroundColor Red
        Write-Host "  Different responses received from DNS servers:" -ForegroundColor Yellow
        foreach ($dr in $domainResults) {
            $statusColor = switch ($dr.Status) {
                "Match"    { "Green" }
                "Mismatch" { "Red" }
                "Error"    { "Red" }
            }
            Write-Host "    $($dr.DNSServer): $($dr.Result)" -ForegroundColor $statusColor
        }
    }

    $allResults += $domainResults
}

Write-Progress -Activity "Resolving DNS" -Completed

# Summary
Write-Host "`n=== DNS Resolution Summary ===" -ForegroundColor Green
Write-Host "  Domains tested:      $($DomainName.Count)" -ForegroundColor Cyan
Write-Host "  DNS servers used:    $($DNSServer.Count)" -ForegroundColor Cyan
Write-Host "  Total queries:       $totalQueries" -ForegroundColor White
Write-Host "  Consistent domains:  $matchCount" -ForegroundColor Green
Write-Host "  Discrepant domains:  $mismatchCount" -ForegroundColor $(if ($mismatchCount -gt 0) { "Red" } else { "Green" })

$errorResults = $allResults | Where-Object { $_.Status -eq "Error" }
if ($errorResults.Count -gt 0) {
    Write-Host "  Errors encountered:  $($errorResults.Count)" -ForegroundColor Red
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
