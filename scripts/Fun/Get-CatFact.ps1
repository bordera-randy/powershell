<#
.SYNOPSIS
    Fetches a random cat fact from the Cat Fact API.
.DESCRIPTION
    This script retrieves an interesting cat fact from the catfact.ninja API
    and displays it with ASCII art. Falls back to built-in facts if the
    API is unavailable.
.EXAMPLE
    .\Get-CatFact.ps1
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    API: https://catfact.ninja/
#>

[CmdletBinding()]
param()

$fallbackFacts = @(
    "Cats sleep 12-16 hours per day.",
    "A group of cats is called a clowder.",
    "Cats can rotate their ears 180 degrees.",
    "Cats have 32 muscles that control the outer ear.",
    "A cat's nose print is unique, like a human fingerprint.",
    "Cats can jump up to six times their length.",
    "The average cat has 244 bones in its body.",
    "Cats have a third eyelid called the nictitating membrane.",
    "A cat's purr vibrates at a frequency of 25 to 150 Hz.",
    "Cats can make over 100 different sounds."
)

$catArt = @"

    /\     /\
   (  o   o  )
   =( Y )=
    )   (
   (_)-(_)

    MEOW!
"@

Write-Host ""
Write-Host $catArt -ForegroundColor Magenta

$fact = $null
try {
    $response = Invoke-RestMethod -Uri "https://catfact.ninja/fact" -TimeoutSec 10
    if ($response -and $response.fact) {
        $fact = $response.fact
        Write-Verbose "Fetched cat fact from catfact.ninja API."
    }
}
catch {
    Write-Verbose "catfact.ninja API unavailable, using built-in facts: $_"
}

if (-not $fact) {
    $fact = $fallbackFacts | Get-Random
}

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "  ║                    CAT FACT OF THE DAY                      ║" -ForegroundColor Yellow
Write-Host "  ╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
Write-Host "  ║                                                              ║" -ForegroundColor Yellow

$words = $fact -split " "
$line = " "
foreach ($word in $words) {
    if (($line + " " + $word).Length -gt 61) {
        Write-Host "  ║ $($line.PadRight(60))║" -ForegroundColor White
        $line = " $word"
    }
    else {
        $line += " $word"
    }
}
if ($line.Trim().Length -gt 0) {
    Write-Host "  ║ $($line.PadRight(60))║" -ForegroundColor White
}

Write-Host "  ║                                                              ║" -ForegroundColor Yellow
Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Source: catfact.ninja" -ForegroundColor DarkGray
Write-Host ""
