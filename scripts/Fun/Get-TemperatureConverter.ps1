<#
.SYNOPSIS
    Converts temperatures between Fahrenheit, Celsius, and Kelvin.
.DESCRIPTION
    This script converts temperature values between Fahrenheit, Celsius,
    and Kelvin scales. Displays all three scales with visual temperature
    indicators.
.PARAMETER Value
    The temperature value to convert. Default is 72.
.PARAMETER From
    The source temperature scale. Valid values: Fahrenheit, Celsius, Kelvin.
.EXAMPLE
    .\Get-TemperatureConverter.ps1 -Value 100 -From Celsius
.EXAMPLE
    .\Get-TemperatureConverter.ps1 -Value 72 -From Fahrenheit
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Source: Inspired by https://devblogs.microsoft.com/scripting/use-powershell-as-a-calculator/
            and https://www.powershellgallery.com/
#>

param(
    [Parameter(Mandatory = $false)]
    [double]$Value = 72,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Fahrenheit", "Celsius", "Kelvin")]
    [string]$From = "Fahrenheit"
)

function Convert-Temperature {
    param(
        [double]$Temp,
        [string]$Scale
    )

    $result = @{}

    switch ($Scale) {
        "Fahrenheit" {
            $result.Fahrenheit = $Temp
            $result.Celsius = [math]::Round(($Temp - 32) * 5 / 9, 2)
            $result.Kelvin = [math]::Round(($Temp - 32) * 5 / 9 + 273.15, 2)
        }
        "Celsius" {
            $result.Fahrenheit = [math]::Round(($Temp * 9 / 5) + 32, 2)
            $result.Celsius = $Temp
            $result.Kelvin = [math]::Round($Temp + 273.15, 2)
        }
        "Kelvin" {
            $result.Fahrenheit = [math]::Round(($Temp - 273.15) * 9 / 5 + 32, 2)
            $result.Celsius = [math]::Round($Temp - 273.15, 2)
            $result.Kelvin = $Temp
        }
    }

    return $result
}

function Get-TemperatureEmoji {
    param([double]$Celsius)

    if ($Celsius -le 0) { return "❄️  Freezing!" }
    elseif ($Celsius -le 10) { return "🌨️  Cold" }
    elseif ($Celsius -le 20) { return "🌤️  Cool" }
    elseif ($Celsius -le 30) { return "☀️  Warm" }
    elseif ($Celsius -le 40) { return "🔥 Hot!" }
    else { return "🌋 Extremely Hot!" }
}

Write-Host ""
Write-Host "  Temperature Converter" -ForegroundColor Green
Write-Host "  =====================" -ForegroundColor Green
Write-Host ""

$result = Convert-Temperature -Temp $Value -Scale $From

$thermometer = @"

      ___
     / | \
    |  |  |
    |  |  |
    |  |  |
    | --- |
    |(   )|
     \___/

"@

Write-Host $thermometer -ForegroundColor Red
Write-Host "  Input: $Value° $From" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ╔══════════════════════════════════╗" -ForegroundColor DarkGray
Write-Host "  ║  Fahrenheit:  $("$($result.Fahrenheit)°F".PadRight(19)) ║" -ForegroundColor DarkGray
Write-Host "  ║  Celsius:     $("$($result.Celsius)°C".PadRight(19)) ║" -ForegroundColor DarkGray
Write-Host "  ║  Kelvin:      $("$($result.Kelvin) K".PadRight(19)) ║" -ForegroundColor DarkGray
Write-Host "  ╚══════════════════════════════════╝" -ForegroundColor DarkGray
Write-Host ""

$feeling = Get-TemperatureEmoji -Celsius $result.Celsius
Write-Host "  $feeling" -ForegroundColor Yellow
Write-Host ""
