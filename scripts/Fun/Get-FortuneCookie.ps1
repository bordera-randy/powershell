<#
.SYNOPSIS
    Displays a random fortune cookie message.
.DESCRIPTION
    This script shows a random fortune cookie message with ASCII art of a
    fortune cookie. Includes a collection of classic fortune cookie sayings.
.EXAMPLE
    .\Get-FortuneCookie.ps1
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by the Unix 'fortune' command
            https://en.wikipedia.org/wiki/Fortune_(Unix)
            and https://github.com/shlomif/fortune-mod
#>

$fortunes = @(
    "A journey of a thousand miles begins with a single step.",
    "Good things come to those who wait... but better things come to those who code.",
    "You will find great success in your next deployment.",
    "A smooth sea never made a skilled sailor.",
    "The best time to plant a tree was 20 years ago. The second best time is now.",
    "Your code will compile on the first try today.",
    "An unexpected reboot will teach you the value of saving your work.",
    "Today is a good day to refactor.",
    "The bug you seek is closer than you think.",
    "A wise programmer writes code that even a junior can understand.",
    "Documentation is a love letter to your future self.",
    "Your pull request will be approved without changes.",
    "The answer you seek is in the logs.",
    "Patience is the key to debugging.",
    "Help will always be given to those who ask for it... on Stack Overflow.",
    "You will discover a useful PowerShell cmdlet today.",
    "A clean commit history brings peace of mind.",
    "The pipeline that runs green brings joy to the team.",
    "You will automate something tedious this week.",
    "Your backups will save you when you least expect it."
)

$cookie = @"

    _________
   /         \
  /  FORTUNE  \
 |   COOKIE    |
  \           /
   \_________/
     |     |
     |_____|

"@

Write-Host ""
Write-Host $cookie -ForegroundColor Yellow

$fortune = $fortunes | Get-Random

Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║                                                      ║" -ForegroundColor Cyan

$words = $fortune -split " "
$line = " "
foreach ($word in $words) {
    if (($line + " " + $word).Length -gt 53) {
        Write-Host "  ║ $($line.PadRight(54))║" -ForegroundColor Cyan
        $line = " $word"
    }
    else {
        $line += " $word"
    }
}
if ($line.Trim().Length -gt 0) {
    Write-Host "  ║ $($line.PadRight(54))║" -ForegroundColor Cyan
}

Write-Host "  ║                                                      ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
