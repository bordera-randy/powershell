<#
.SYNOPSIS
    Display Random Quotes
.DESCRIPTION
    This script displays random inspirational and tech quotes.
.EXAMPLE
    .\Get-RandomQuote.ps1
    .\Get-RandomQuote.ps1 -Category Tech
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("All","Tech","Inspirational","Funny")]
    [string]$Category = "All"
)

$techQuotes = @(
    @{
        Quote = "Any fool can write code that a computer can understand. Good programmers write code that humans can understand."
        Author = "Martin Fowler"
    },
    @{
        Quote = "First, solve the problem. Then, write the code."
        Author = "John Johnson"
    },
    @{
        Quote = "Code is like humor. When you have to explain it, it's bad."
        Author = "Cory House"
    },
    @{
        Quote = "Make it work, make it right, make it fast."
        Author = "Kent Beck"
    },
    @{
        Quote = "The best error message is the one that never shows up."
        Author = "Thomas Fuchs"
    },
    @{
        Quote = "Programming isn't about what you know; it's about what you can figure out."
        Author = "Chris Pine"
    },
    @{
        Quote = "The most disastrous thing that you can ever learn is your first programming language."
        Author = "Alan Kay"
    },
    @{
        Quote = "In programming, the hard part isn't solving problems, but deciding what problems to solve."
        Author = "Paul Graham"
    }
)

$inspirationalQuotes = @(
    @{
        Quote = "The only way to do great work is to love what you do."
        Author = "Steve Jobs"
    },
    @{
        Quote = "Innovation distinguishes between a leader and a follower."
        Author = "Steve Jobs"
    },
    @{
        Quote = "Your time is limited, don't waste it living someone else's life."
        Author = "Steve Jobs"
    },
    @{
        Quote = "The best way to predict the future is to invent it."
        Author = "Alan Kay"
    },
    @{
        Quote = "Stay hungry, stay foolish."
        Author = "Steve Jobs"
    },
    @{
        Quote = "Simplicity is the ultimate sophistication."
        Author = "Leonardo da Vinci"
    },
    @{
        Quote = "The function of good software is to make the complex appear to be simple."
        Author = "Grady Booch"
    }
)

$funnyQuotes = @(
    @{
        Quote = "There are only two hard things in Computer Science: cache invalidation and naming things."
        Author = "Phil Karlton"
    },
    @{
        Quote = "Walking on water and developing software from a specification are easy if both are frozen."
        Author = "Edward V. Berard"
    },
    @{
        Quote = "Always code as if the guy who ends up maintaining your code will be a violent psychopath who knows where you live."
        Author = "John Woods"
    },
    @{
        Quote = "It works on my machine."
        Author = "Every Developer Ever"
    },
    @{
        Quote = "I'm not a great programmer; I'm just a good programmer with great habits."
        Author = "Kent Beck"
    },
    @{
        Quote = "99 little bugs in the code, 99 bugs in the code. Patch one down, compile it around, 117 bugs in the code."
        Author = "Anonymous"
    },
    @{
        Quote = "Debugging is twice as hard as writing the code in the first place."
        Author = "Brian Kernighan"
    }
)

function Show-Quote {
    param($QuoteObj)
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                           ║" -ForegroundColor Cyan
    
    # Word wrap the quote
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

# Main execution
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

$allQuotes = @()

switch ($Category) {
    "Tech" { $allQuotes = $techQuotes }
    "Inspirational" { $allQuotes = $inspirationalQuotes }
    "Funny" { $allQuotes = $funnyQuotes }
    "All" { $allQuotes = $techQuotes + $inspirationalQuotes + $funnyQuotes }
}

$randomQuote = $allQuotes | Get-Random

Show-Quote -QuoteObj $randomQuote

Write-Host "Category: $Category" -ForegroundColor DarkGray
Write-Host ""
