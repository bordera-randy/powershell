<#
.SYNOPSIS
    Collection of joke-fetching functions from various APIs.

.DESCRIPTION
    This script provides three functions to retrieve jokes from different sources:
    - get-chuck: Fetches Chuck Norris jokes
    - get-dadjoke: Fetches dad jokes
    - get-joke: Fetches random jokes from API Ninjas
    
    All functions display jokes in popup windows for entertainment purposes.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Requires: Internet connection, Windows Presentation Framework (for popup windows)
    
.LINK
    https://api.chucknorris.io
    https://icanhazdadjoke.com
    https://api-ninjas.com/api/jokes
#>

<#
.SYNOPSIS
    Retrieves a random Chuck Norris joke.

.DESCRIPTION
    Fetches a random Chuck Norris joke from the Chuck Norris API and displays it in a message box.

.EXAMPLE
    get-chuck
    Displays a Chuck Norris joke in a popup window.
#>
function get-chuck {
    # Fetch joke from Chuck Norris API
    $jokeprep = Invoke-WebRequest -Uri 'https://api.chucknorris.io/jokes/random' -UseBasicParsing -Method Get | Select-Object -ExpandProperty Content
    $joke = $jokeprep | ConvertFrom-Json
    
    # Load Windows Presentation Framework for message box
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    
    # Configure message box appearance
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageIcon = [System.Windows.MessageBoxImage]::Error
    $MessageBody = "$($joke.value)"
    $MessageTitle = "Chuck Norris Joke!!"
    
    # Display joke in popup window
    $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
    # Load Windows Presentation Framework for message box
    Add-Type -AssemblyName PresentationCore,PresentationFramework

    # Configure message box appearance
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageIcon = [System.Windows.MessageBoxImage]::Information
    $MessageBody = "$($joke.joke)"
    $MessageTitle = "Random Joke"

    # Display joke in popup window
    [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
}

<#
.SYNOPSIS
    Retrieves a random dad joke.

.DESCRIPTION
    Fetches a random dad joke from icanhazdadjoke.com and displays it in a message box.

.EXAMPLE
    get-dadjoke
    Displays a dad joke in a popup window.
#>
function get-dadjoke {
    # Set up headers for JSON response
    $header = @{
        Accept = "application/json"
        "Content-Type" = "application/json"
    }
    
    # Fetch joke from icanhazdadjoke API
    $jokeprep = Invoke-WebRequest -Uri 'https://icanhazdadjoke.com/' -UseBasicParsing -Method Get -Headers $header | Select-Object -ExpandProperty Content
    $joke = $jokeprep | ConvertFrom-Json
    
    # Load Windows Presentation Framework for message box
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    
    # Configure message box appearance
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageIcon = [System.Windows.MessageBoxImage]::Error
    $MessageBody = "$($joke.joke)"
    $MessageTitle = "Dad Joke"
    
    # Display joke in popup window
    $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
}

<#
.SYNOPSIS
    Retrieves a random joke from API Ninjas.

.DESCRIPTION
    Fetches a random joke from the API Ninjas service and outputs it to the console.
    Requires a valid API key from api-ninjas.com.

.EXAMPLE
    get-joke
    Displays a random joke in the console.
    
.NOTES
    Requires: API key from api-ninjas.com
#>
function get-joke {
    # API endpoint for jokes
    $uri = "https://api.api-ninjas.com/v1/jokes?format=json"
    
    # Replace with your API key from api-ninjas.com
    $apikey = "YOUR_API_KEY_HERE"
    
    # Set up API request headers
    $header = @{
        Accept = "application/json"
        "X-Api-Key" = $apikey
    }
    
    # Fetch joke from API Ninjas
    $jokeprep = Invoke-WebRequest -Uri $uri -UseBasicParsing -Method Get -Headers $header | Select-Object -ExpandProperty Content
    $joke = $jokeprep | ConvertFrom-Json
    
    # Output joke to console
    Write-Output $joke.joke 
}
