<#
.SYNOPSIS
    Displays ASCII art weather scenes in the console.
.DESCRIPTION
    This script shows various ASCII art weather scenes including sunny, rainy,
    cloudy, snowy, and stormy conditions. Optionally picks a random weather scene.
.PARAMETER Weather
    The weather condition to display. Valid values: Sunny, Rainy, Cloudy, Snowy, Stormy, Random.
.EXAMPLE
    .\Get-WeatherArt.ps1
.EXAMPLE
    .\Get-WeatherArt.ps1 -Weather Snowy
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: ASCII art inspired by https://www.asciiart.eu/nature/weather
            and https://github.com/chubin/wttr.in
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Sunny", "Rainy", "Cloudy", "Snowy", "Stormy", "Random")]
    [string]$Weather = "Random"
)

function Show-Sunny {
    $art = @"

        \   |   /
         .---.
    --- (     ) ---
         '---'
        /   |   \

    Temperature: 78°F / 26°C
    Humidity: 45%
    Wind: 5 mph

    Have a wonderful sunny day!
"@
    Write-Host $art -ForegroundColor Yellow
}

function Show-Rainy {
    $art = @"

         .---.
        (     )
       (_______)
        ' ' ' '
       ' ' ' '
        ' ' ' '

    Temperature: 58°F / 14°C
    Humidity: 85%
    Wind: 12 mph

    Don't forget your umbrella!
"@
    Write-Host $art -ForegroundColor Cyan
}

function Show-Cloudy {
    $art = @"

            .---.
      .----(     )
     (      )---'
      '----'
        .---.
       (     )
        '---'

    Temperature: 65°F / 18°C
    Humidity: 60%
    Wind: 8 mph

    A nice overcast day.
"@
    Write-Host $art -ForegroundColor Gray
}

function Show-Snowy {
    $art = @"

         .---.
        (     )
       (_______)
        *  *  *
       *  *  *
        *  *  *
       *  *  *

    Temperature: 28°F / -2°C
    Humidity: 70%
    Wind: 15 mph

    Bundle up, it's snowing!
"@
    Write-Host $art -ForegroundColor White
}

function Show-Stormy {
    $art = @"

         .---.
        (     )
       (_______)
        /  /  /
       /  /  /
         _
        | |
        | |
       _|_|_

    Temperature: 52°F / 11°C
    Humidity: 95%
    Wind: 35 mph

    Stay safe indoors!
"@
    Write-Host $art -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "  Weather Display" -ForegroundColor Green
Write-Host "  ===============" -ForegroundColor Green
Write-Host ""

if ($Weather -eq "Random") {
    $Weather = @("Sunny", "Rainy", "Cloudy", "Snowy", "Stormy") | Get-Random
}

Write-Host "  Current Conditions: $Weather" -ForegroundColor Cyan
Write-Host ""

switch ($Weather) {
    "Sunny"  { Show-Sunny }
    "Rainy"  { Show-Rainy }
    "Cloudy" { Show-Cloudy }
    "Snowy"  { Show-Snowy }
    "Stormy" { Show-Stormy }
}

Write-Host ""
