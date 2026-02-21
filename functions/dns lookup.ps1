<#
.SYNOPSIS
    Performs DNS lookups against public DNS servers.

.DESCRIPTION
    This script resolves DNS records using the API Ninjas DNS lookup service.
    It queries public DNS servers and returns DNS information for the specified domain.

.PARAMETER urllookup
    The domain name to look up (e.g., "google.com", "microsoft.com").

.EXAMPLE
    get-DNS -urllookup "google.com"
    Performs a DNS lookup for google.com.

.EXAMPLE
    get-DNS -urllookup "github.com"
    Performs a DNS lookup for github.com.

.NOTES
    Name: Get-DNS.ps1
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Date Created: 9/05/2023
    Version: 1.0
    Requires: Internet connection and API key from api-ninjas.com

.LINK
    https://api-ninjas.com/api/dnslookup
    https://docs.microsoft.com/en-us/powershell/azure/?view=azps-6.0.0
#>

function get-DNS {
    param (
        [Parameter(Mandatory=$true)]
        [string]$urllookup
    )
    
    # API endpoint for DNS lookup
    $uri = "https://api.api-ninjas.com/v1/dnslookup?domain=$urllookup"
    
    # Replace with your API key from api-ninjas.com
    $apikey = "YOUR_API_KEY_HERE"
    
    # Set up API request headers
    $header = @{
        Accept = "application/json"
        "X-Api-Key" = $apikey
    }
    
    # Make API request and parse JSON response
    $dnsprep = Invoke-WebRequest -Uri $uri -UseBasicParsing -Method Get -Headers $header | Select-Object -ExpandProperty Content
    
    # Convert and return DNS information
    $dnsprep | ConvertFrom-Json
}

# Example usage:
# get-DNS -urllookup "google.com"