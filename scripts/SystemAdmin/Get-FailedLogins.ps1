<#
.SYNOPSIS
    Searches for failed login attempts in Windows security event logs.

.DESCRIPTION
    This script queries the Security event log for failed logon events (Event ID 4625)
    and Kerberos pre-authentication failures (Event ID 4771). It displays account names,
    source IP addresses, failure reasons, and timestamps. Results are grouped by account
    and source IP to identify top offenders, with high-frequency failures highlighted.
    Results can be exported to CSV.

.PARAMETER ComputerName
    The computer name to query (default: localhost).

.PARAMETER Hours
    Number of hours to look back in the event log (default: 24).

.PARAMETER TopN
    Number of top offending accounts and IPs to display (default: 20).

.PARAMETER ExportPath
    File path for CSV export. When omitted results are displayed only.

.EXAMPLE
    .\Get-FailedLogins.ps1
    Shows failed logins from the last 24 hours on the local computer.

.EXAMPLE
    .\Get-FailedLogins.ps1 -ComputerName "DC01" -Hours 48
    Shows failed logins from the last 48 hours on DC01.

.EXAMPLE
    .\Get-FailedLogins.ps1 -Hours 72 -TopN 10 -ExportPath "C:\Reports\failed.csv"
    Shows top 10 offenders from last 72 hours and exports all events to CSV.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ComputerName = "localhost",

    [Parameter(Mandatory = $false)]
    [int]$Hours = 24,

    [Parameter(Mandatory = $false)]
    [int]$TopN = 20,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# ---------------------------------------------------------------------------
# Failure reason lookup
# ---------------------------------------------------------------------------
$failureReasons = @{
    "0xC0000064" = "User name does not exist"
    "0xC000006A" = "Incorrect password"
    "0xC0000234" = "Account locked out"
    "0xC0000072" = "Account disabled"
    "0xC000006F" = "Logon outside authorized hours"
    "0xC0000070" = "Unauthorized workstation"
    "0xC0000071" = "Expired password"
    "0xC0000193" = "Account expired"
    "0xC0000224" = "Password must change at next logon"
    "0xC0000225" = "Windows bug - not a risk"
    "0xC000015B" = "Logon type not granted"
}

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Verbose "`n=== Failed Login Audit ==="
Write-Verbose "  Computer: $ComputerName"
Write-Verbose "  Time range: Last $Hours hour(s)"
Write-Verbose "  Top N: $TopN"

$startTime = (Get-Date).AddHours(-$Hours)
$allResults = @()

# --- Query Event ID 4625 (Failed Logon) ---
Write-Verbose "`nQuerying Event ID 4625 (Failed Logon)..."

try {
    $events4625 = Get-WinEvent -ComputerName $ComputerName -FilterHashtable @{
        LogName   = 'Security'
        Id        = 4625
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    if ($events4625) {
        Write-Verbose "  Found $($events4625.Count) event(s)"

        foreach ($event in $events4625) {
            $xml = [xml]$event.ToXml()
            $data = @{}
            foreach ($d in $xml.Event.EventData.Data) {
                $data[$d.Name] = $d.'#text'
            }

            $accountName  = $data['TargetUserName']
            $domain       = $data['TargetDomainName']
            $sourceIP     = $data['IpAddress']
            $statusCode   = $data['Status']
            $subStatus    = $data['SubStatus']
            $failReason   = if ($failureReasons[$subStatus]) { $failureReasons[$subStatus] }
                            elseif ($failureReasons[$statusCode]) { $failureReasons[$statusCode] }
                            else { "$statusCode / $subStatus" }

            $allResults += [PSCustomObject]@{
                TimeStamp    = $event.TimeCreated
                EventID      = 4625
                AccountName  = "$domain\$accountName"
                SourceIP     = $sourceIP
                FailureReason = $failReason
                StatusCode   = $statusCode
                SubStatus    = $subStatus
                ComputerName = $ComputerName
            }
        }
    }
    else {
        Write-Verbose "  No Event 4625 entries found."
    }
}
catch {
    Write-Verbose "  Error querying Event 4625: $_"
}

# --- Query Event ID 4771 (Kerberos Pre-Auth Failed) ---
Write-Verbose "`nQuerying Event ID 4771 (Kerberos Pre-Auth Failed)..."

try {
    $events4771 = Get-WinEvent -ComputerName $ComputerName -FilterHashtable @{
        LogName   = 'Security'
        Id        = 4771
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    if ($events4771) {
        Write-Verbose "  Found $($events4771.Count) event(s)"

        foreach ($event in $events4771) {
            $xml = [xml]$event.ToXml()
            $data = @{}
            foreach ($d in $xml.Event.EventData.Data) {
                $data[$d.Name] = $d.'#text'
            }

            $accountName = $data['TargetUserName']
            $sourceIP    = $data['IpAddress']
            if ($sourceIP -and $sourceIP.StartsWith("::ffff:")) {
                $sourceIP = $sourceIP.Substring(7)
            }
            $statusCode  = $data['Status']
            $failReason  = "Kerberos pre-auth failed (status: $statusCode)"

            $allResults += [PSCustomObject]@{
                TimeStamp     = $event.TimeCreated
                EventID       = 4771
                AccountName   = $accountName
                SourceIP      = $sourceIP
                FailureReason = $failReason
                StatusCode    = $statusCode
                SubStatus     = $null
                ComputerName  = $ComputerName
            }
        }
    }
    else {
        Write-Verbose "  No Event 4771 entries found."
    }
}
catch {
    Write-Verbose "  Error querying Event 4771: $_"
}

# --- Display results ---
if ($allResults.Count -eq 0) {
    Write-Verbose "`n  No failed login events found in the specified time range."
    Write-Verbose "`n=== Audit Complete ==="
    exit 0
}

Write-Verbose "`n--- Recent Failed Logins ---"

$sortedEvents = $allResults | Sort-Object TimeStamp -Descending | Select-Object -First 50
foreach ($evt in $sortedEvents) {
    Write-Verbose "  $($evt.TimeStamp.ToString('yyyy-MM-dd HH:mm:ss')) | $($evt.AccountName) | $($evt.SourceIP) | $($evt.FailureReason)"
}

# --- Top offending accounts ---
Write-Verbose "`n--- Top $TopN Offending Accounts ---"

$byAccount = $allResults | Group-Object -Property AccountName | Sort-Object Count -Descending | Select-Object -First $TopN

foreach ($group in $byAccount) {
    Write-Verbose "  $($group.Name): $($group.Count) failure(s)"
}

# --- Top offending IPs ---
Write-Verbose "`n--- Top $TopN Offending Source IPs ---"

$byIP = $allResults | Where-Object { $_.SourceIP -and $_.SourceIP -ne "-" } |
    Group-Object -Property SourceIP | Sort-Object Count -Descending | Select-Object -First $TopN

foreach ($group in $byIP) {
    Write-Verbose "  $($group.Name): $($group.Count) failure(s)"
}

# --- Summary ---
Write-Verbose "`n=== Failed Login Summary ==="
Write-Verbose "  Total failed logon events:  $($allResults.Count)"
Write-Verbose "  Event 4625 count:           $(($allResults | Where-Object { $_.EventID -eq 4625 }).Count)"
Write-Verbose "  Event 4771 count:           $(($allResults | Where-Object { $_.EventID -eq 4771 }).Count)"
Write-Verbose "  Unique accounts targeted:   $($byAccount.Count)"
Write-Verbose "  Unique source IPs:          $($byIP.Count)"

$highFrequencyAccounts = ($byAccount | Where-Object { $_.Count -ge 100 }).Count
if ($highFrequencyAccounts -gt 0) {
    Write-Verbose "  HIGH-FREQUENCY accounts (>=100): $highFrequencyAccounts"
}

# --- Export ---
if ($ExportPath -and $allResults.Count -gt 0) {
    try {
        $exportDir = Split-Path -Path $ExportPath -Parent
        if ($exportDir -and -not (Test-Path $exportDir)) {
            New-Item -Path $exportDir -ItemType Directory -Force | Out-Null
        }
        $allResults | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
        Write-Verbose "`n  CSV exported: $ExportPath"
    }
    catch {
        Write-Verbose "`n  Failed to export CSV: $_"
    }
}

Write-Verbose "`n=== Audit Complete ==="
