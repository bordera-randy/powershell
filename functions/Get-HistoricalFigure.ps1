<#
.SYNOPSIS
    Retrieves information about historical figures from API Ninjas.

.DESCRIPTION
    This function queries the API Ninjas historical figures database to retrieve 
    biographical information about historical personalities. It displays the name, 
    title, and detailed information about the queried figure.

.PARAMETER name
    The name of the historical figure to look up (e.g., "Abraham Lincoln", "Marie Curie").

.EXAMPLE
    get-historicalfigure -name "Albert Einstein"
    Retrieves and displays information about Albert Einstein.

.EXAMPLE
    get-historicalfigure -name "Marie Curie"
    Retrieves and displays information about Marie Curie.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Requires: Internet connection and API key from api-ninjas.com
    
.LINK
    https://api-ninjas.com/api/historicalfigures
#>

function get-historicalfigure {
    param (
        [Parameter(Mandatory=$true)]
        [string]$name
    )
    
    # API endpoint for historical figures
    $uri = "https://api.api-ninjas.com/v1/historicalfigures?name=$name"
    
    # Replace with your API key from api-ninjas.com
    $apikey = "YOUR_API_KEY_HERE"
    
    # Set up API request headers
    $header = @{
        Accept = "application/json"
        "X-Api-Key" = $apikey
    }
    
    # Make API request and parse JSON response
    $prep = Invoke-WebRequest -Uri $uri -UseBasicParsing -Method Get -Headers $header | Select-Object -ExpandProperty Content
    $final = $prep | ConvertFrom-Json
    
    # Extract detailed information
    $info = $final | Select-Object -ExpandProperty info

    # Display results with formatted output
    Write-Host -ForegroundColor DarkMagenta "Historical Figure: $name"
    Write-Host ""
    $final.name
    $final.Title
    $($info | Format-List)
}
