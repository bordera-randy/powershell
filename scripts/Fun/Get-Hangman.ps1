<#
.SYNOPSIS
    Play a game of Hangman in PowerShell.
.DESCRIPTION
    This script implements the classic Hangman word guessing game.
    Guess letters to reveal the hidden word before running out of
    attempts. Includes ASCII art gallows that build as you miss.
.PARAMETER Category
    Word category to use. Valid values: Tech, Animals, Countries, Random.
.EXAMPLE
    .\Get-Hangman.ps1
.EXAMPLE
    .\Get-Hangman.ps1 -Category Tech
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Source: Classic Hangman game, inspired by
            https://www.reddit.com/r/PowerShell/comments/4h203c/hangman_game/
            and https://rosettacode.org/wiki/Hangman
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Tech", "Animals", "Countries", "Random")]
    [string]$Category = "Random"
)

$wordLists = @{
    Tech      = @("POWERSHELL", "ALGORITHM", "KUBERNETES", "DATABASE", "FIREWALL",
                   "ENCRYPTION", "COMPILER", "FUNCTION", "VARIABLE", "PIPELINE")
    Animals   = @("ELEPHANT", "GIRAFFE", "PENGUIN", "DOLPHIN", "BUTTERFLY",
                   "KANGAROO", "CHEETAH", "OCTOPUS", "FLAMINGO", "CHAMELEON")
    Countries = @("AUSTRALIA", "BRAZIL", "CANADA", "GERMANY", "ICELAND",
                   "JAPAN", "MEXICO", "NORWAY", "PORTUGAL", "SWEDEN")
}

$hangmanStages = @(
    @"
  +---+
  |   |
      |
      |
      |
      |
========
"@,
    @"
  +---+
  |   |
  O   |
      |
      |
      |
========
"@,
    @"
  +---+
  |   |
  O   |
  |   |
      |
      |
========
"@,
    @"
  +---+
  |   |
  O   |
 /|   |
      |
      |
========
"@,
    @"
  +---+
  |   |
  O   |
 /|\  |
      |
      |
========
"@,
    @"
  +---+
  |   |
  O   |
 /|\  |
 /    |
      |
========
"@,
    @"
  +---+
  |   |
  O   |
 /|\  |
 / \  |
      |
========
"@
)

if ($Category -eq "Random") {
    $Category = @("Tech", "Animals", "Countries") | Get-Random
}

$word = ($wordLists[$Category] | Get-Random).ToUpper()
$guessedLetters = @()
$wrongGuesses = 0
$maxWrong = 6

Write-Host ""
Write-Host "  ╔══════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║           HANGMAN GAME           ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Category: $Category" -ForegroundColor Cyan
Write-Host ""

while ($wrongGuesses -lt $maxWrong) {
    # Display hangman
    Write-Host $hangmanStages[$wrongGuesses] -ForegroundColor Red

    # Display word progress
    $display = ""
    $solved = $true
    foreach ($char in $word.ToCharArray()) {
        if ($guessedLetters -contains $char) {
            $display += "$char "
        }
        else {
            $display += "_ "
            $solved = $false
        }
    }

    Write-Host "  Word: $display" -ForegroundColor Yellow
    Write-Host "  Guessed: $($guessedLetters -join ', ')" -ForegroundColor DarkGray
    Write-Host "  Remaining: $($maxWrong - $wrongGuesses) guesses" -ForegroundColor DarkGray
    Write-Host ""

    if ($solved) {
        Write-Host "  ╔══════════════════════════════════╗" -ForegroundColor Green
        Write-Host "  ║   Congratulations! You won!      ║" -ForegroundColor Green
        Write-Host "  ╚══════════════════════════════════╝" -ForegroundColor Green
        Write-Host "  The word was: $word" -ForegroundColor Cyan
        Write-Host ""
        return
    }

    $guess = (Read-Host "  Guess a letter").ToUpper()

    if ($guess.Length -ne 1 -or $guess -notmatch '[A-Z]') {
        Write-Host "  Please enter a single letter." -ForegroundColor Red
        continue
    }

    if ($guessedLetters -contains $guess) {
        Write-Host "  You already guessed '$guess'!" -ForegroundColor Yellow
        continue
    }

    $guessedLetters += $guess

    if ($word -notmatch $guess) {
        $wrongGuesses++
        Write-Host "  Wrong! '$guess' is not in the word." -ForegroundColor Red
    }
    else {
        Write-Host "  Correct! '$guess' is in the word!" -ForegroundColor Green
    }
    Write-Host ""
}

# Game over
Write-Host $hangmanStages[$maxWrong] -ForegroundColor Red
Write-Host ""
Write-Host "  ╔══════════════════════════════════╗" -ForegroundColor Red
Write-Host "  ║         GAME OVER!               ║" -ForegroundColor Red
Write-Host "  ╚══════════════════════════════════╝" -ForegroundColor Red
Write-Host "  The word was: $word" -ForegroundColor Yellow
Write-Host ""
