<#
.SYNOPSIS
    Displays a random fortune cookie message from an API.
.DESCRIPTION
    This script fetches and shows a random affirmation or fortune from the
    affirmations.dev API. Falls back to built-in fortunes if the API is
    unavailable.
.EXAMPLE
    .\Get-FortuneCookie.ps1
.NOTES
    Author: PowerShell Utility Collection
    Version: 2.0
    API: https://www.affirmations.dev/
#>

[CmdletBinding()]
param()

$fallbackFortunes = @(
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

# Try fetching a fortune from the affirmations API
$fortune = $null
try {
    $response = Invoke-RestMethod -Uri "https://www.affirmations.dev/" -TimeoutSec 10
    if ($response -and $response.affirmation) {
        $fortune = $response.affirmation
        Write-Verbose "Fetched fortune from affirmations.dev API."
    }
}
catch {
    Write-Verbose "Affirmations API unavailable, using built-in fortunes: $_"
}

if (-not $fortune) {
    $fortune = $fallbackFortunes | Get-Random
}

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
