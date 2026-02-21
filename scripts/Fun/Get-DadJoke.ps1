<#
.SYNOPSIS
    Fetches and displays a random dad joke from the icanhazdadjoke API.
.DESCRIPTION
    This script retrieves a random dad joke from the icanhazdadjoke.com API
    and displays it with a fun ASCII art header. Falls back to built-in
    jokes if the API is unavailable.
.PARAMETER Search
    Search term to find jokes related to a specific topic.
.EXAMPLE
    .\Get-DadJoke.ps1
.EXAMPLE
    .\Get-DadJoke.ps1 -Search "dog"
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    API: https://icanhazdadjoke.com/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Search
)

$fallbackJokes = @(
    "Why don't scientists trust atoms? Because they make up everything!",
    "I told my wife she was drawing her eyebrows too high. She looked surprised.",
    "Why did the scarecrow win an award? Because he was outstanding in his field.",
    "I used to play piano by ear. Now I use my hands.",
    "What do you call cheese that isn't yours? Nacho cheese.",
    "Why can't a bicycle stand on its own? Because it's two-tired.",
    "I'm reading a book about anti-gravity. It's impossible to put down.",
    "Did you hear about the claustrophobic astronaut? He just needed a little space.",
    "Why do programmers prefer dark mode? Because light attracts bugs.",
    "How many programmers does it take to change a light bulb? None, that's a hardware problem."
)

$header = @"

    (._.)
     oo)  DAD JOKE TIME
    / \/
   (  )
   /\_)\

"@

Write-Host ""
Write-Host $header -ForegroundColor Yellow

$joke = $null
try {
    $headers = @{ Accept = "application/json" }
    if ($Search) {
        $encodedSearch = [System.Uri]::EscapeDataString($Search)
        $response = Invoke-RestMethod -Uri "https://icanhazdadjoke.com/search?term=$encodedSearch&limit=1" `
            -Headers $headers -TimeoutSec 10
        if ($response.results -and $response.results.Count -gt 0) {
            $joke = ($response.results | Get-Random).joke
        }
        else {
            Write-Warning "No dad jokes found for '$Search'. Showing a random one instead."
        }
    }
    if (-not $joke) {
        $response = Invoke-RestMethod -Uri "https://icanhazdadjoke.com/" -Headers $headers -TimeoutSec 10
        $joke = $response.joke
    }
    Write-Verbose "Fetched joke from icanhazdadjoke.com API."
}
catch {
    Write-Verbose "icanhazdadjoke API unavailable, using built-in jokes: $_"
}

if (-not $joke) {
    $joke = $fallbackJokes | Get-Random
}

Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║                                                              ║" -ForegroundColor Cyan

$words = $joke -split " "
$line = " "
foreach ($word in $words) {
    if (($line + " " + $word).Length -gt 61) {
        Write-Host "  ║ $($line.PadRight(60))║" -ForegroundColor Cyan
        $line = " $word"
    }
    else {
        $line += " $word"
    }
}
if ($line.Trim().Length -gt 0) {
    Write-Host "  ║ $($line.PadRight(60))║" -ForegroundColor Cyan
}

Write-Host "  ║                                                              ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  *ba dum tss*" -ForegroundColor DarkGray
Write-Host ""
