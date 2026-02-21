<#
.SYNOPSIS
    Retrieves and displays a weather forecast using the wttr.in API.
.DESCRIPTION
    This script queries the wttr.in API to retrieve and display a weather
    forecast for a specified location. Uses the open-source wttr.in service
    which provides weather data without requiring an API key.
.PARAMETER Location
    The location to get weather for. Can be a city name, airport code,
    coordinates, or a geographic landmark. Defaults to auto-detection.
.PARAMETER Days
    Number of forecast days to show (1-3). Default is 1.
.EXAMPLE
    .\Get-WeatherForecast.ps1
.EXAMPLE
    .\Get-WeatherForecast.ps1 -Location "New York"
.EXAMPLE
    .\Get-WeatherForecast.ps1 -Location "London" -Days 3
.OUTPUTS
    [PSCustomObject] with current conditions and forecast data.
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    API: https://wttr.in/
    No API key required.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Location = "",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3)]
    [int]$Days = 1
)

$weatherCodes = @{
    113 = "Sunny"; 116 = "Partly Cloudy"; 119 = "Cloudy"; 122 = "Overcast"
    143 = "Mist"; 176 = "Patchy Rain"; 179 = "Patchy Snow"; 182 = "Patchy Sleet"
    185 = "Patchy Freezing Drizzle"; 200 = "Thundery Outbreaks"; 227 = "Blowing Snow"
    230 = "Blizzard"; 248 = "Fog"; 260 = "Freezing Fog"; 263 = "Light Drizzle"
    266 = "Light Drizzle"; 281 = "Freezing Drizzle"; 284 = "Heavy Freezing Drizzle"
    293 = "Light Rain"; 296 = "Light Rain"; 299 = "Moderate Rain"; 302 = "Moderate Rain"
    305 = "Heavy Rain"; 308 = "Heavy Rain"; 311 = "Light Freezing Rain"
    314 = "Moderate Freezing Rain"; 317 = "Light Sleet"; 320 = "Moderate/Heavy Sleet"
    323 = "Light Snow"; 326 = "Light Snow"; 329 = "Moderate Snow"; 332 = "Moderate Snow"
    335 = "Blizzard"; 338 = "Blizzard"; 350 = "Ice Pellets"; 353 = "Light Rain Shower"
    356 = "Moderate Rain Shower"; 359 = "Torrential Rain Shower"; 362 = "Light Sleet Shower"
    365 = "Moderate Sleet Shower"; 368 = "Light Snow Shower"; 371 = "Heavy Snow Shower"
    374 = "Light Ice Pellet Shower"; 377 = "Moderate Ice Pellet Shower"; 386 = "Thundery Rain"
    389 = "Moderate/Heavy Thundery Rain"; 392 = "Thundery Snow"; 395 = "Blizzard/Thunder"
}

Write-Host ""
Write-Host "  ┌──────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │           Weather Forecast               │" -ForegroundColor Cyan
Write-Host "  └──────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

$encodedLocation = if ($Location) { [System.Uri]::EscapeDataString($Location) } else { "" }
$uri = "https://wttr.in/$($encodedLocation)?format=j1"

try {
    $data = Invoke-RestMethod -Uri $uri -TimeoutSec 15

    $nearest = $data.nearest_area[0]
    $areaName = $nearest.areaName[0].value
    $country  = $nearest.country[0].value
    $current  = $data.current_condition[0]

    $condition = if ($weatherCodes[[int]$current.weatherCode]) { $weatherCodes[[int]$current.weatherCode] } else { $current.weatherDesc[0].value }

    Write-Host "  Location  : $areaName, $country" -ForegroundColor White
    Write-Host "  Condition : $condition" -ForegroundColor Yellow
    Write-Host "  Temp (C)  : $($current.temp_C) °C" -ForegroundColor White
    Write-Host "  Temp (F)  : $($current.temp_F) °F" -ForegroundColor White
    Write-Host "  Feels Like: $($current.FeelsLikeC) °C / $($current.FeelsLikeF) °F" -ForegroundColor White
    Write-Host "  Humidity  : $($current.humidity)%" -ForegroundColor White
    Write-Host "  Wind      : $($current.windspeedKmph) km/h $($current.winddir16Point)" -ForegroundColor White
    Write-Host "  Visibility: $($current.visibility) km" -ForegroundColor White
    Write-Host "  UV Index  : $($current.uvIndex)" -ForegroundColor White
    Write-Host ""

    if ($Days -gt 1) {
        Write-Host "  Forecast:" -ForegroundColor Cyan
        $forecastDays = $data.weather | Select-Object -First $Days
        foreach ($day in $forecastDays) {
            $dayCondition = if ($weatherCodes[[int]$day.hourly[4].weatherCode]) { $weatherCodes[[int]$day.hourly[4].weatherCode] } else { $day.hourly[4].weatherDesc[0].value }
            Write-Host ""
            Write-Host "    $($day.date)" -ForegroundColor Yellow
            Write-Host "    High: $($day.maxtempC) °C / $($day.maxtempF) °F   Low: $($day.mintempC) °C / $($day.mintempF) °F" -ForegroundColor White
            Write-Host "    Condition: $dayCondition" -ForegroundColor White
            Write-Host "    Sunrise: $($day.astronomy[0].sunrise)  Sunset: $($day.astronomy[0].sunset)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    return [PSCustomObject]@{
        Location    = "$areaName, $country"
        Condition   = $condition
        TempC       = $current.temp_C
        TempF       = $current.temp_F
        Humidity    = $current.humidity
        WindKmph    = $current.windspeedKmph
        WindDir     = $current.winddir16Point
        Visibility  = $current.visibility
        UVIndex     = $current.uvIndex
    }
}
catch {
    Write-Error "Failed to retrieve weather data: $_"
    Write-Host "  Try specifying a location: .\Get-WeatherForecast.ps1 -Location 'New York'" -ForegroundColor Yellow
}
