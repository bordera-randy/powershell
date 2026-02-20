<#
.SYNOPSIS
    Displays random Star Wars quotes with ASCII art.
.DESCRIPTION
    This script shows memorable quotes from the Star Wars franchise
    along with ASCII art characters. A must-have for any Jedi developer.
.PARAMETER Character
    Filter quotes by character. Valid values: Yoda, Vader, Obi-Wan, All.
.EXAMPLE
    .\Get-StarWarsQuote.ps1
.EXAMPLE
    .\Get-StarWarsQuote.ps1 -Character Yoda
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Star Wars quotes from https://www.starwars.com/news/15-star-wars-quotes-to-use-in-everyday-life
            and ASCII art inspired by https://www.asciiart.eu/movies/star-wars
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Yoda", "Vader", "Obi-Wan", "All")]
    [string]$Character = "All"
)

$yodaQuotes = @(
    @{ Quote = "Do. Or do not. There is no try."; Character = "Yoda" },
    @{ Quote = "Fear is the path to the dark side. Fear leads to anger, anger leads to hate, hate leads to suffering."; Character = "Yoda" },
    @{ Quote = "The greatest teacher, failure is."; Character = "Yoda" },
    @{ Quote = "In a dark place we find ourselves, and a little more knowledge lights our way."; Character = "Yoda" },
    @{ Quote = "Patience you must have, my young Padawan."; Character = "Yoda" },
    @{ Quote = "Always pass on what you have learned."; Character = "Yoda" }
)

$vaderQuotes = @(
    @{ Quote = "I find your lack of faith disturbing."; Character = "Darth Vader" },
    @{ Quote = "The force is strong with this one."; Character = "Darth Vader" },
    @{ Quote = "You don't know the power of the dark side."; Character = "Darth Vader" },
    @{ Quote = "Be careful not to choke on your aspirations."; Character = "Darth Vader" },
    @{ Quote = "I am altering the deal. Pray I don't alter it any further."; Character = "Darth Vader" }
)

$obiWanQuotes = @(
    @{ Quote = "The Force will be with you. Always."; Character = "Obi-Wan Kenobi" },
    @{ Quote = "In my experience, there's no such thing as luck."; Character = "Obi-Wan Kenobi" },
    @{ Quote = "You were the chosen one!"; Character = "Obi-Wan Kenobi" },
    @{ Quote = "Hello there."; Character = "Obi-Wan Kenobi" },
    @{ Quote = "These aren't the droids you're looking for."; Character = "Obi-Wan Kenobi" },
    @{ Quote = "Use the Force, Luke."; Character = "Obi-Wan Kenobi" }
)

$yodaArt = @"

       ____
      /    \
     | ^  ^ |
      \ -- /
     __||||__
    |  ____  |
    | |    | |
    |_|    |_|

"@

$vaderArt = @"

       .--.
      |o  o|
      |/  \|
     /|    |\
    /_|____|_\
      | || |
      |_||_|

"@

$obiWanArt = @"

       .---.
      /     \
     | () () |
      \  ^  /
       '---'
      /|   |\
     / |   | \

"@

Write-Host ""
Write-Host "  ╔══════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "  ║      STAR WARS QUOTES            ║" -ForegroundColor Yellow
Write-Host "  ╚══════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""

$allQuotes = @()
switch ($Character) {
    "Yoda"    { $allQuotes = $yodaQuotes }
    "Vader"   { $allQuotes = $vaderQuotes }
    "Obi-Wan" { $allQuotes = $obiWanQuotes }
    "All"     { $allQuotes = $yodaQuotes + $vaderQuotes + $obiWanQuotes }
}

$selected = $allQuotes | Get-Random

# Show appropriate ASCII art
switch -Wildcard ($selected.Character) {
    "Yoda"          { Write-Host $yodaArt -ForegroundColor Green }
    "Darth Vader"   { Write-Host $vaderArt -ForegroundColor Red }
    "Obi-Wan*"      { Write-Host $obiWanArt -ForegroundColor Cyan }
}

Write-Host "  `"$($selected.Quote)`"" -ForegroundColor Yellow
Write-Host "    - $($selected.Character)" -ForegroundColor DarkGray
Write-Host ""
