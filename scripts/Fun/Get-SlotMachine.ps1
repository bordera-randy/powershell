<#
.SYNOPSIS
    Simulates a slot machine game in the console.
.DESCRIPTION
    This script creates a simple slot machine game with ASCII art reels.
    Match symbols to win! Features multiple symbol types and a jackpot
    for three matching symbols.
.PARAMETER Spins
    Number of times to spin. Default is 1.
.EXAMPLE
    .\Get-SlotMachine.ps1
.EXAMPLE
    .\Get-SlotMachine.ps1 -Spins 5
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Source: Inspired by https://www.reddit.com/r/PowerShell/comments/8z8fc4/slot_machine/
            and https://rosettacode.org/wiki/Slot_machine
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 20)]
    [int]$Spins = 1
)

$symbols = @("🍒", "🍋", "🔔", "⭐", "💎", "7️⃣")
$textSymbols = @("CHR", "LMN", "BEL", "STR", "DIA", "777")

Write-Host ""
Write-Host "  ╔══════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "  ║       SLOT MACHINE               ║" -ForegroundColor Yellow
Write-Host "  ║    ═══════════════════            ║" -ForegroundColor Yellow
Write-Host "  ╚══════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""

$totalWins = 0
$totalSpins = 0

for ($spin = 1; $spin -le $Spins; $spin++) {
    $totalSpins++

    # Generate three random reels
    $reel1 = Get-Random -Minimum 0 -Maximum $textSymbols.Count
    $reel2 = Get-Random -Minimum 0 -Maximum $textSymbols.Count
    $reel3 = Get-Random -Minimum 0 -Maximum $textSymbols.Count

    $s1 = $textSymbols[$reel1]
    $s2 = $textSymbols[$reel2]
    $s3 = $textSymbols[$reel3]

    # Animate the spin
    if ($Spins -eq 1) {
        for ($frame = 0; $frame -lt 8; $frame++) {
            $r1 = $textSymbols[(Get-Random -Minimum 0 -Maximum $textSymbols.Count)]
            $r2 = $textSymbols[(Get-Random -Minimum 0 -Maximum $textSymbols.Count)]
            $r3 = $textSymbols[(Get-Random -Minimum 0 -Maximum $textSymbols.Count)]
            Write-Host "`r  ┃ $r1 ┃ $r2 ┃ $r3 ┃" -NoNewline -ForegroundColor White
            Start-Sleep -Milliseconds 150
        }
    }

    # Display final result
    Write-Host ""
    Write-Host "  ┏━━━━━┳━━━━━┳━━━━━┓" -ForegroundColor Yellow
    Write-Host "  ┃ $s1 ┃ $s2 ┃ $s3 ┃" -ForegroundColor White
    Write-Host "  ┗━━━━━┻━━━━━┻━━━━━┛" -ForegroundColor Yellow

    # Check for wins
    if ($reel1 -eq $reel2 -and $reel2 -eq $reel3) {
        if ($s1 -eq "777") {
            Write-Host "  *** JACKPOT! Triple 7s! ***" -ForegroundColor Red
        }
        else {
            Write-Host "  *** THREE OF A KIND! ***" -ForegroundColor Green
        }
        $totalWins++
    }
    elseif ($reel1 -eq $reel2 -or $reel2 -eq $reel3 -or $reel1 -eq $reel3) {
        Write-Host "  ** Two matching! Small win! **" -ForegroundColor Yellow
        $totalWins++
    }
    else {
        Write-Host "  No match. Try again!" -ForegroundColor DarkGray
    }
    Write-Host ""
}

if ($Spins -gt 1) {
    Write-Host "  ═══════════════════════" -ForegroundColor Cyan
    Write-Host "  Total Spins: $totalSpins" -ForegroundColor Cyan
    Write-Host "  Wins: $totalWins" -ForegroundColor Green
    Write-Host "  Win Rate: $([math]::Round($totalWins / $totalSpins * 100, 1))%" -ForegroundColor Yellow
    Write-Host ""
}
