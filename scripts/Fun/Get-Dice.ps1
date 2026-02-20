<#
.SYNOPSIS
    Rolls virtual dice and displays the results.
.DESCRIPTION
    This script simulates rolling dice with ASCII art representations.
    Supports rolling multiple dice with configurable number of sides.
.PARAMETER Count
    Number of dice to roll. Default is 2.
.PARAMETER Sides
    Number of sides on each die. Default is 6.
.EXAMPLE
    .\Get-Dice.ps1
.EXAMPLE
    .\Get-Dice.ps1 -Count 3 -Sides 20
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://devblogs.microsoft.com/scripting/weekend-scripter-dice-roller/
            and https://www.powershellgallery.com/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$Count = 2,

    [Parameter(Mandatory = $false)]
    [ValidateSet(4, 6, 8, 10, 12, 20)]
    [int]$Sides = 6
)

$diceFaces = @{
    1 = @(
        "┌─────────┐",
        "│         │",
        "│    ●    │",
        "│         │",
        "└─────────┘"
    )
    2 = @(
        "┌─────────┐",
        "│ ●       │",
        "│         │",
        "│       ● │",
        "└─────────┘"
    )
    3 = @(
        "┌─────────┐",
        "│ ●       │",
        "│    ●    │",
        "│       ● │",
        "└─────────┘"
    )
    4 = @(
        "┌─────────┐",
        "│ ●     ● │",
        "│         │",
        "│ ●     ● │",
        "└─────────┘"
    )
    5 = @(
        "┌─────────┐",
        "│ ●     ● │",
        "│    ●    │",
        "│ ●     ● │",
        "└─────────┘"
    )
    6 = @(
        "┌─────────┐",
        "│ ●     ● │",
        "│ ●     ● │",
        "│ ●     ● │",
        "└─────────┘"
    )
}

Write-Host ""
Write-Host "  🎲 Dice Roller" -ForegroundColor Green
Write-Host "  ==============" -ForegroundColor Green
Write-Host ""
Write-Host "  Rolling $Count d$Sides..." -ForegroundColor Cyan
Write-Host ""

$results = @()
for ($i = 0; $i -lt $Count; $i++) {
    $roll = Get-Random -Minimum 1 -Maximum ($Sides + 1)
    $results += $roll

    if ($Sides -eq 6 -and $diceFaces.ContainsKey($roll)) {
        foreach ($line in $diceFaces[$roll]) {
            Write-Host "    $line" -ForegroundColor White
        }
        Write-Host ""
    }
    else {
        Write-Host "    Die $($i + 1): [ $roll ]" -ForegroundColor Yellow
    }
}

$total = ($results | Measure-Object -Sum).Sum
Write-Host "  ─────────────────────" -ForegroundColor DarkGray
Write-Host "  Results: $($results -join ', ')" -ForegroundColor Yellow
Write-Host "  Total:   $total" -ForegroundColor Green
Write-Host ""
