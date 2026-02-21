
<#
.SYNOPSIS
    Retrieves trivia questions from API Ninjas trivia API.

.DESCRIPTION
    This function fetches trivia questions from the API Ninjas service based on the specified category.
    It displays both the question and answer in color-coded format for easy readability.
    Requires a valid API key from api-ninjas.com.

.PARAMETER category
    The trivia category to query. Valid categories include:
    - artliterature
    - language
    - sciencenature
    - general
    - fooddrink
    - peopleplaces
    - geography
    - historyholidays
    - entertainment
    - toysgames
    - music
    - mathematics
    - religionmythology
    - sportsleisure

.EXAMPLE
    get-trivia -category "sciencenature"
    Retrieves a trivia question from the science and nature category.

.EXAMPLE
    get-trivia -category "general"
    Retrieves a general trivia question.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Requires: Internet connection and API key from api-ninjas.com
    
.LINK
    https://api-ninjas.com/api/trivia
#>

function get-trivia {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("artliterature","language","sciencenature","general","fooddrink",
                     "peopleplaces","geography","historyholidays","entertainment",
                     "toysgames","music","mathematics","religionmythology","sportsleisure")]
        [string]$category
    )
    
    # API endpoint for trivia questions
    $uri = "https://api.api-ninjas.com/v1/trivia?category=$category"
    
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
    
    # Display question in green and answer in red
    Write-Host -ForegroundColor Green $final.question
    Write-Host -ForegroundColor Red $final.answer
}
