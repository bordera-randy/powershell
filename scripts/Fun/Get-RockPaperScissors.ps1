<#
.SYNOPSIS
    Play Rock, Paper, Scissors against the computer.
.DESCRIPTION
    This script lets you play the classic Rock, Paper, Scissors game
    against a computer opponent. Tracks wins, losses, and ties.
.PARAMETER Choice
    Your choice: Rock, Paper, or Scissors.
.PARAMETER Rounds
    Number of rounds to play. Default is 1.
.EXAMPLE
    .\Get-RockPaperScissors.ps1 -Choice Rock
.EXAMPLE
    .\Get-RockPaperScissors.ps1 -Choice Paper -Rounds 5
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://www.reddit.com/r/PowerShell/comments/86kf5e/
            and https://devblogs.microsoft.com/scripting/powershell-games/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Rock", "Paper", "Scissors")]
    [string]$Choice,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 20)]
    [int]$Rounds = 1
)

$art = @{
    Rock     = @"
    _______
---'   ____)
      (_____)
      (_____)
      (____)
---.__(___)
"@
    Paper    = @"
     _______
---'    ____)____
           ______)
          _______)
         _______)
---.__________)
"@
    Scissors = @"
    _______
---'   ____)____
          ______)
       __________)
      (____)
---.__(___)
"@
}

$options = @("Rock", "Paper", "Scissors")

Write-Host ""
Write-Host "  Rock, Paper, Scissors!" -ForegroundColor Green
Write-Host "  ======================" -ForegroundColor Green
Write-Host ""

$wins = 0; $losses = 0; $ties = 0

for ($round = 1; $round -le $Rounds; $round++) {
    if ($Rounds -gt 1) {
        Write-Host "  --- Round $round of $Rounds ---" -ForegroundColor Cyan
    }

    $playerChoice = if ($Choice) { $Choice } else {
        $options | Get-Random
    }

    $computerChoice = $options | Get-Random

    Write-Host ""
    Write-Host "  You chose: $playerChoice" -ForegroundColor Yellow
    Write-Host $art[$playerChoice] -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Computer chose: $computerChoice" -ForegroundColor Magenta
    Write-Host $art[$computerChoice] -ForegroundColor Magenta

    if ($playerChoice -eq $computerChoice) {
        Write-Host "  Result: It's a TIE!" -ForegroundColor DarkYellow
        $ties++
    }
    elseif (
        ($playerChoice -eq "Rock" -and $computerChoice -eq "Scissors") -or
        ($playerChoice -eq "Paper" -and $computerChoice -eq "Rock") -or
        ($playerChoice -eq "Scissors" -and $computerChoice -eq "Paper")
    ) {
        Write-Host "  Result: You WIN!" -ForegroundColor Green
        $wins++
    }
    else {
        Write-Host "  Result: You LOSE!" -ForegroundColor Red
        $losses++
    }
    Write-Host ""
}

if ($Rounds -gt 1) {
    Write-Host "  ═══════════════════════" -ForegroundColor Cyan
    Write-Host "  Final Score:" -ForegroundColor Cyan
    Write-Host "    Wins:   $wins" -ForegroundColor Green
    Write-Host "    Losses: $losses" -ForegroundColor Red
    Write-Host "    Ties:   $ties" -ForegroundColor Yellow
    Write-Host ""
}
