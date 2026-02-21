<#
.SYNOPSIS
    Retrieves public IP address information using the ipinfo.io API.
.DESCRIPTION
    This script queries the ipinfo.io API to retrieve details about the
    current public IP address, including geolocation, ISP, and timezone
    information. Optionally accepts a specific IP address to look up.
.PARAMETER IPAddress
    The IP address to look up. Defaults to the current machine's public IP.
.PARAMETER Token
    Optional API token for ipinfo.io to increase the rate limit.
.EXAMPLE
    .\Get-PublicIPInfo.ps1
.EXAMPLE
    .\Get-PublicIPInfo.ps1 -IPAddress 8.8.8.8
.EXAMPLE
    .\Get-PublicIPInfo.ps1 -Token "your_token_here"
.OUTPUTS
    [PSCustomObject] with IP, Hostname, City, Region, Country, Location,
    Org, Timezone, and Postal fields.
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    API: https://ipinfo.io/
    Rate limit: 50,000 requests/month (free tier without token)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$IPAddress,

    [Parameter(Mandatory = $false)]
    [string]$Token
)

$uri = if ($IPAddress) {
    "https://ipinfo.io/$IPAddress/json"
}
else {
    "https://ipinfo.io/json"
}

if ($Token) {
    $uri += "?token=$Token"
}

Write-Host ""
Write-Host "  ┌──────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │         Public IP Information            │" -ForegroundColor Cyan
Write-Host "  └──────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

try {
    $info = Invoke-RestMethod -Uri $uri -TimeoutSec 15

    $result = [PSCustomObject]@{
        IP       = $info.ip
        Hostname = $info.hostname
        City     = $info.city
        Region   = $info.region
        Country  = $info.country
        Location = $info.loc
        Org      = $info.org
        Timezone = $info.timezone
        Postal   = $info.postal
    }

    $fields = @(
        @{ Label = "IP Address"; Value = $result.IP },
        @{ Label = "Hostname";   Value = $result.Hostname },
        @{ Label = "City";       Value = $result.City },
        @{ Label = "Region";     Value = $result.Region },
        @{ Label = "Country";    Value = $result.Country },
        @{ Label = "Lat/Lon";    Value = $result.Location },
        @{ Label = "ISP/Org";    Value = $result.Org },
        @{ Label = "Timezone";   Value = $result.Timezone },
        @{ Label = "Postal";     Value = $result.Postal }
    )

    foreach ($field in $fields) {
        if ($field.Value) {
            $label = $field.Label.PadRight(12)
            Write-Host "  $label : $($field.Value)" -ForegroundColor White
        }
    }

    Write-Host ""
    return $result
}
catch {
    Write-Error "Failed to retrieve IP information: $_"
}
