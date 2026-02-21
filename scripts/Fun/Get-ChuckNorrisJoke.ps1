<#
.SYNOPSIS
    Displays random Chuck Norris jokes fetched from the Chuck Norris API.
.DESCRIPTION
    This script fetches and displays a random Chuck Norris joke from the
    chucknorris.io API. Falls back to built-in jokes if the API is unavailable.
    Great for lightening the mood during long coding sessions.
.PARAMETER Category
    Optional joke category. Use Get-ChuckNorrisJoke.ps1 -ListCategories to see
    available categories. Defaults to a random joke with no category filter.
.PARAMETER ListCategories
    List all available joke categories from the API.
.EXAMPLE
    .\Get-ChuckNorrisJoke.ps1
.EXAMPLE
    .\Get-ChuckNorrisJoke.ps1 -Category dev
.EXAMPLE
    .\Get-ChuckNorrisJoke.ps1 -ListCategories
.NOTES
    Author: PowerShell Utility Collection
    Version: 2.0
    API: https://api.chucknorris.io/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Category,

    [Parameter(Mandatory = $false)]
    [switch]$ListCategories
)

$fallbackJokes = @(
    "Chuck Norris can solve the halting problem... by staring at the code until it behaves.",
    "Chuck Norris doesn't use version control. The code is too afraid to change.",
    "Chuck Norris can write infinite loops that finish in under 2 seconds.",
    "When Chuck Norris throws an exception, nothing can catch it.",
    "Chuck Norris doesn't need a debugger. Bugs confess on their own.",
    "Chuck Norris doesn't need sudo. The computer does what he says.",
    "Chuck Norris's commit messages are just periods. The code explains itself.",
    "The cloud is just Chuck Norris's personal computer."
)

$ascii = @"

         ___
        /   \
       | o o |
       |  >  |
        \___/
       /|   |\
      / |   | \
         | |
        _| |_
       |_____|

    CHUCK NORRIS
      APPROVED
"@

function Show-Joke {
    param([string]$JokeText)

    Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║                                                              ║" -ForegroundColor Yellow

    $words = $JokeText -split " "
    $line = " "
    foreach ($word in $words) {
        if (($line + " " + $word).Length -gt 61) {
            Write-Host "  ║ $($line.PadRight(60))║" -ForegroundColor Yellow
            $line = " $word"
        }
        else {
            $line += " $word"
        }
    }
    if ($line.Trim().Length -gt 0) {
        Write-Host "  ║ $($line.PadRight(60))║" -ForegroundColor Yellow
    }

    Write-Host "  ║                                                              ║" -ForegroundColor Yellow
    Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
}

# List categories mode
if ($ListCategories) {
    try {
        $categories = Invoke-RestMethod -Uri "https://api.chucknorris.io/jokes/categories" -TimeoutSec 10
        Write-Host ""
        Write-Host "  Available Chuck Norris joke categories:" -ForegroundColor Cyan
        $categories | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
        Write-Host ""
    }
    catch {
        Write-Warning "Could not reach the Chuck Norris API: $_"
    }
    return
}

Write-Host ""
Write-Host $ascii -ForegroundColor Red
Write-Host ""

# Fetch joke from API
$joke = $null
try {
    $uri = if ($Category) {
        "https://api.chucknorris.io/jokes/random?category=$Category"
    }
    else {
        "https://api.chucknorris.io/jokes/random"
    }
    $response = Invoke-RestMethod -Uri $uri -TimeoutSec 10
    $joke = $response.value
    Write-Verbose "Fetched joke from chucknorris.io API."
}
catch {
    Write-Verbose "API unavailable, using built-in jokes: $_"
}

if (-not $joke) {
    $joke = $fallbackJokes | Get-Random
}

Show-Joke -JokeText $joke
