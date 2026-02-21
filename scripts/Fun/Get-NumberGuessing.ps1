<#
.SYNOPSIS
    Play a number guessing game.
.DESCRIPTION
    This script implements a number guessing game where the computer picks
    a random number and you try to guess it. Provides hints (higher/lower)
    and tracks the number of guesses.
.PARAMETER Max
    The maximum number the computer can pick. Default is 100.
.EXAMPLE
    .\Get-NumberGuessing.ps1
.EXAMPLE
    .\Get-NumberGuessing.ps1 -Max 1000
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Source: Classic number guessing game, inspired by
            https://www.reddit.com/r/PowerShell/comments/3p1jba/powershell_number_guessing_game/
            and https://devblogs.microsoft.com/scripting/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(10, 10000)]
    [int]$Max = 100
)

Write-Host ""
Write-Host "  Number Guessing Game" -ForegroundColor Green
Write-Host "  ====================" -ForegroundColor Green
Write-Host ""
Write-Host "  I'm thinking of a number between 1 and $Max." -ForegroundColor Cyan
Write-Host "  Try to guess it!" -ForegroundColor Cyan
Write-Host ""

$secret = Get-Random -Minimum 1 -Maximum ($Max + 1)
$guesses = 0
$maxGuesses = [math]::Ceiling([math]::Log2($Max)) + 1
$guessed = $false

Write-Host "  Hint: You should be able to guess it in $maxGuesses tries or fewer." -ForegroundColor DarkGray
Write-Host ""

while (-not $guessed) {
    $input = Read-Host "  Enter your guess"

    if (-not ($input -match '^\d+$')) {
        Write-Host "  Please enter a valid number." -ForegroundColor Red
        continue
    }

    $guess = [int]$input
    $guesses++

    if ($guess -lt $secret) {
        Write-Host "  ↑ Higher! Try a bigger number." -ForegroundColor Yellow
    }
    elseif ($guess -gt $secret) {
        Write-Host "  ↓ Lower! Try a smaller number." -ForegroundColor Yellow
    }
    else {
        $guessed = $true
        Write-Host ""
        Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "  ║                                      ║" -ForegroundColor Green
        Write-Host "  ║   Congratulations! You got it!       ║" -ForegroundColor Green
        Write-Host "  ║                                      ║" -ForegroundColor Green
        Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "  The number was: $secret" -ForegroundColor Cyan
        Write-Host "  Number of guesses: $guesses" -ForegroundColor Cyan

        if ($guesses -le $maxGuesses) {
            Write-Host "  Excellent! You found it efficiently!" -ForegroundColor Green
        }
        elseif ($guesses -le $maxGuesses * 2) {
            Write-Host "  Good job!" -ForegroundColor Yellow
        }
        else {
            Write-Host "  Try using binary search next time!" -ForegroundColor Red
        }
    }
}
Write-Host ""
