<#
.SYNOPSIS
    Flips a virtual coin and displays the result.
.DESCRIPTION
    This script simulates flipping a coin with an ASCII art animation.
    Can flip multiple coins and track statistics.
.PARAMETER Flips
    Number of coins to flip. Default is 1.
.EXAMPLE
    .\Get-CoinFlip.ps1
.EXAMPLE
    .\Get-CoinFlip.ps1 -Flips 10
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Source: Inspired by https://devblogs.microsoft.com/scripting/
            and https://www.reddit.com/r/PowerShell/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]$Flips = 1
)

$heads = @"
    ┌──────────┐
   /    ____    \
  │   / HEAD \   │
  │  |   $    |  │
  │   \______/   │
   \            /
    └──────────┘
"@

$tails = @"
    ┌──────────┐
   /    ____    \
  │   / TAIL \   │
  │  |   ¢    |  │
  │   \______/   │
   \            /
    └──────────┘
"@

Write-Host ""
Write-Host "  Coin Flipper" -ForegroundColor Green
Write-Host "  ============" -ForegroundColor Green
Write-Host ""

$headCount = 0
$tailCount = 0

for ($i = 1; $i -le $Flips; $i++) {
    $result = Get-Random -Minimum 0 -Maximum 2

    if ($Flips -eq 1) {
        # Show animation for single flip
        $frames = @("  |", "  /", "  -", "  \", "  |", "  /", "  -")
        foreach ($frame in $frames) {
            Write-Host "`r$frame" -NoNewline -ForegroundColor Yellow
            Start-Sleep -Milliseconds 100
        }
        Write-Host ""
        Write-Host ""

        if ($result -eq 0) {
            Write-Host $heads -ForegroundColor Yellow
            Write-Host "  Result: HEADS!" -ForegroundColor Green
            $headCount++
        }
        else {
            Write-Host $tails -ForegroundColor Cyan
            Write-Host "  Result: TAILS!" -ForegroundColor Green
            $tailCount++
        }
    }
    else {
        if ($result -eq 0) {
            $headCount++
        }
        else {
            $tailCount++
        }
    }
}

if ($Flips -gt 1) {
    Write-Host "  Flipped $Flips coins:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Heads: $headCount ($([math]::Round($headCount / $Flips * 100, 1))%)" -ForegroundColor Yellow
    Write-Host "  Tails: $tailCount ($([math]::Round($tailCount / $Flips * 100, 1))%)" -ForegroundColor Cyan
}

Write-Host ""
