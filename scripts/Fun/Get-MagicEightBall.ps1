<#
.SYNOPSIS
    Simulates a Magic 8-Ball that answers your yes/no questions.
.DESCRIPTION
    This script simulates the classic Magic 8-Ball toy. Ask it a
    yes/no question and receive a random mystical answer.
.PARAMETER Question
    The yes/no question to ask the Magic 8-Ball.
.EXAMPLE
    .\Get-MagicEightBall.ps1 -Question "Will I get a raise?"
.EXAMPLE
    .\Get-MagicEightBall.ps1
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://en.wikipedia.org/wiki/Magic_8-ball
            and https://www.reddit.com/r/PowerShell/comments/5bj39l/magic_8ball/
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Question = "Will today be a good day?"
)

$answers = @(
    @{ Text = "It is certain."; Type = "Positive" },
    @{ Text = "It is decidedly so."; Type = "Positive" },
    @{ Text = "Without a doubt."; Type = "Positive" },
    @{ Text = "Yes, definitely."; Type = "Positive" },
    @{ Text = "You may rely on it."; Type = "Positive" },
    @{ Text = "As I see it, yes."; Type = "Positive" },
    @{ Text = "Most likely."; Type = "Positive" },
    @{ Text = "Outlook good."; Type = "Positive" },
    @{ Text = "Yes."; Type = "Positive" },
    @{ Text = "Signs point to yes."; Type = "Positive" },
    @{ Text = "Reply hazy, try again."; Type = "Neutral" },
    @{ Text = "Ask again later."; Type = "Neutral" },
    @{ Text = "Better not tell you now."; Type = "Neutral" },
    @{ Text = "Cannot predict now."; Type = "Neutral" },
    @{ Text = "Concentrate and ask again."; Type = "Neutral" },
    @{ Text = "Don't count on it."; Type = "Negative" },
    @{ Text = "My reply is no."; Type = "Negative" },
    @{ Text = "My sources say no."; Type = "Negative" },
    @{ Text = "Outlook not so good."; Type = "Negative" },
    @{ Text = "Very doubtful."; Type = "Negative" }
)

$ball = @"

        ___________
       /     8     \
      /             \
     |    .-----.    |
     |   /       \   |
     |  |  MAGIC  |  |
     |  |  8-BALL |  |
     |   \       /   |
     |    '-----'    |
      \             /
       \___________/

"@

Write-Host ""
Write-Host $ball -ForegroundColor DarkBlue
Write-Host "  Question: $Question" -ForegroundColor Cyan
Write-Host ""

# Simulate "thinking"
Write-Host "  Consulting the mystical orb" -NoNewline -ForegroundColor DarkMagenta
for ($i = 0; $i -lt 3; $i++) {
    Start-Sleep -Milliseconds 500
    Write-Host "." -NoNewline -ForegroundColor DarkMagenta
}
Write-Host ""
Write-Host ""

$answer = $answers | Get-Random
$color = switch ($answer.Type) {
    "Positive" { "Green" }
    "Neutral"  { "Yellow" }
    "Negative" { "Red" }
}

Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor $color
Write-Host "  ║                                      ║" -ForegroundColor $color
Write-Host "  ║  $($answer.Text.PadRight(34))  ║" -ForegroundColor $color
Write-Host "  ║                                      ║" -ForegroundColor $color
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor $color
Write-Host ""
