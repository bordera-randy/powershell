<#
.SYNOPSIS
    Display random inspirational or tech quotes from the ZenQuotes API.
.DESCRIPTION
    This script fetches and displays a random inspirational quote from the
    ZenQuotes API (https://zenquotes.io/). Falls back to built-in quotes
    if the API is unavailable.
.PARAMETER Category
    Category filter for built-in quotes when API is unavailable.
    Valid values: All, Tech, Inspirational, Funny. Default: All.
.EXAMPLE
    .\Get-RandomQuote.ps1
.EXAMPLE
    .\Get-RandomQuote.ps1 -Category Tech
.NOTES
    Author: PowerShell Utility Collection
    Version: 2.0
    API: https://zenquotes.io/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Tech", "Inspirational", "Funny")]
    [string]$Category = "All"
)

$techQuotes = @(
    @{ Quote = "Any fool can write code that a computer can understand. Good programmers write code that humans can understand."; Author = "Martin Fowler" },
    @{ Quote = "First, solve the problem. Then, write the code."; Author = "John Johnson" },
    @{ Quote = "Code is like humor. When you have to explain it, it's bad."; Author = "Cory House" },
    @{ Quote = "Make it work, make it right, make it fast."; Author = "Kent Beck" },
    @{ Quote = "The best error message is the one that never shows up."; Author = "Thomas Fuchs" }
)

$inspirationalQuotes = @(
    @{ Quote = "The only way to do great work is to love what you do."; Author = "Steve Jobs" },
    @{ Quote = "Innovation distinguishes between a leader and a follower."; Author = "Steve Jobs" },
    @{ Quote = "The best way to predict the future is to invent it."; Author = "Alan Kay" },
    @{ Quote = "Stay hungry, stay foolish."; Author = "Steve Jobs" },
    @{ Quote = "Simplicity is the ultimate sophistication."; Author = "Leonardo da Vinci" }
)

$funnyQuotes = @(
    @{ Quote = "There are only two hard things in Computer Science: cache invalidation and naming things."; Author = "Phil Karlton" },
    @{ Quote = "Walking on water and developing software from a specification are easy if both are frozen."; Author = "Edward V. Berard" },
    @{ Quote = "Always code as if the guy who ends up maintaining your code will be a violent psychopath who knows where you live."; Author = "John Woods" },
    @{ Quote = "It works on my machine."; Author = "Every Developer Ever" },
    @{ Quote = "99 little bugs in the code, 99 bugs in the code. Patch one down, compile it around, 117 bugs in the code."; Author = "Anonymous" }
)

function Show-Quote {
    param($QuoteObj)

    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan

    $words = $QuoteObj.Quote -split " "
    $line = "  "

    foreach ($word in $words) {
        if (($line + $word).Length -gt 73) {
            Write-Host "║ $($line.PadRight(73)) ║" -ForegroundColor Cyan
            $line = "  $word"
        }
        else {
            $line += " $word"
        }
    }

    if ($line.Trim().Length -gt 0) {
        Write-Host "║ $($line.PadRight(73)) ║" -ForegroundColor Cyan
    }

    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "║ $("- " + $QuoteObj.Author)".PadRight(76) + "║" -ForegroundColor Yellow
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Header
Write-Host ""
Write-Host "  ██████╗ ██╗   ██╗ ██████╗ ████████╗███████╗" -ForegroundColor Green
Write-Host " ██╔═══██╗██║   ██║██╔═══██╗╚══██╔══╝██╔════╝" -ForegroundColor Green
Write-Host " ██║   ██║██║   ██║██║   ██║   ██║   █████╗  " -ForegroundColor Green
Write-Host " ██║▄▄ ██║██║   ██║██║   ██║   ██║   ██╔══╝  " -ForegroundColor Green
Write-Host " ╚██████╔╝╚██████╔╝╚██████╔╝   ██║   ███████╗" -ForegroundColor Green
Write-Host "  ╚══▀▀═╝  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝" -ForegroundColor Green
Write-Host ""
Write-Host " ╔═╗╔═╗  ╔╦╗╦ ╦╔═╗  ╔╦╗╔═╗╦ ╦" -ForegroundColor Magenta
Write-Host " ║ ║╠╣    ║ ╠═╣║╣    ║║╠═╣╚╦╝" -ForegroundColor Magenta
Write-Host " ╚═╝╚     ╩ ╩ ╩╚═╝  ═╩╝╩ ╩ ╩ " -ForegroundColor Magenta
Write-Host ""

# Try ZenQuotes API first
$quoteObj = $null
try {
    $response = Invoke-RestMethod -Uri "https://zenquotes.io/api/random" -TimeoutSec 10
    if ($response -and $response[0].q -and $response[0].a) {
        $quoteObj = @{ Quote = $response[0].q; Author = $response[0].a }
        Write-Verbose "Fetched quote from ZenQuotes API."
    }
}
catch {
    Write-Verbose "ZenQuotes API unavailable, using built-in quotes: $_"
}

# Fall back to built-in quotes
if (-not $quoteObj) {
    $allQuotes = switch ($Category) {
        "Tech"          { $techQuotes }
        "Inspirational" { $inspirationalQuotes }
        "Funny"         { $funnyQuotes }
        default         { $techQuotes + $inspirationalQuotes + $funnyQuotes }
    }
    $quoteObj = $allQuotes | Get-Random
}

Show-Quote -QuoteObj $quoteObj

Write-Host "Category: $Category" -ForegroundColor DarkGray
Write-Host ""
