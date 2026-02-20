<#
.SYNOPSIS
    Displays a random motivational poster with ASCII art border.
.DESCRIPTION
    This script creates motivational poster-style displays with quotes
    and decorative ASCII art frames. Perfect for adding to your
    PowerShell profile or sharing with team members.
.PARAMETER Theme
    The theme of the poster. Valid values: Success, Teamwork, Coding, Random.
.EXAMPLE
    .\Get-MotivationalPoster.ps1
.EXAMPLE
    .\Get-MotivationalPoster.ps1 -Theme Coding
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://devblogs.microsoft.com/scripting/
            and https://www.reddit.com/r/PowerShell/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Success", "Teamwork", "Coding", "Random")]
    [string]$Theme = "Random"
)

$successPosters = @(
    @{
        Title   = "SUCCESS"
        Quote   = "Success is not final, failure is not fatal: it is the courage to continue that counts."
        Author  = "Winston Churchill"
    },
    @{
        Title   = "PERSISTENCE"
        Quote   = "It does not matter how slowly you go as long as you do not stop."
        Author  = "Confucius"
    },
    @{
        Title   = "EXCELLENCE"
        Quote   = "We are what we repeatedly do. Excellence, then, is not an act, but a habit."
        Author  = "Aristotle"
    }
)

$teamworkPosters = @(
    @{
        Title   = "TEAMWORK"
        Quote   = "Alone we can do so little; together we can do so much."
        Author  = "Helen Keller"
    },
    @{
        Title   = "COLLABORATION"
        Quote   = "If you want to go fast, go alone. If you want to go far, go together."
        Author  = "African Proverb"
    },
    @{
        Title   = "UNITY"
        Quote   = "Coming together is a beginning, staying together is progress, working together is success."
        Author  = "Henry Ford"
    }
)

$codingPosters = @(
    @{
        Title   = "CLEAN CODE"
        Quote   = "Any fool can write code that a computer can understand. Good programmers write code that humans can understand."
        Author  = "Martin Fowler"
    },
    @{
        Title   = "DEBUGGING"
        Quote   = "The most effective debugging tool is still careful thought, coupled with judiciously placed print statements."
        Author  = "Brian Kernighan"
    },
    @{
        Title   = "SIMPLICITY"
        Quote   = "Simplicity is the soul of efficiency."
        Author  = "Austin Freeman"
    }
)

if ($Theme -eq "Random") {
    $Theme = @("Success", "Teamwork", "Coding") | Get-Random
}

$posters = switch ($Theme) {
    "Success"  { $successPosters }
    "Teamwork" { $teamworkPosters }
    "Coding"   { $codingPosters }
}

$poster = $posters | Get-Random
$width = 60

Write-Host ""
Write-Host "  ╔$('═' * $width)╗" -ForegroundColor DarkCyan
Write-Host "  ║$(' ' * $width)║" -ForegroundColor DarkCyan

# Center the title
$titlePad = [math]::Max(0, ($width - $poster.Title.Length) / 2)
$titleLine = (' ' * [math]::Floor($titlePad)) + $poster.Title + (' ' * [math]::Ceiling($titlePad))
if ($titleLine.Length -gt $width) { $titleLine = $titleLine.Substring(0, $width) }
Write-Host "  ║$($titleLine.PadRight($width))║" -ForegroundColor Yellow

Write-Host "  ║$(' ' * $width)║" -ForegroundColor DarkCyan
Write-Host "  ║$('─' * $width)║" -ForegroundColor DarkCyan
Write-Host "  ║$(' ' * $width)║" -ForegroundColor DarkCyan

# Word wrap the quote
$words = $poster.Quote -split " "
$line = "   "
foreach ($word in $words) {
    if (($line + " " + $word).Length -gt ($width - 4)) {
        $paddedLine = $line.PadRight($width)
        Write-Host "  ║$paddedLine║" -ForegroundColor Cyan
        $line = "   $word"
    }
    else {
        $line += " $word"
    }
}
if ($line.Trim().Length -gt 0) {
    Write-Host "  ║$($line.PadRight($width))║" -ForegroundColor Cyan
}

Write-Host "  ║$(' ' * $width)║" -ForegroundColor DarkCyan

$authorLine = "    - $($poster.Author)"
Write-Host "  ║$($authorLine.PadRight($width))║" -ForegroundColor DarkGray

Write-Host "  ║$(' ' * $width)║" -ForegroundColor DarkCyan
Write-Host "  ╚$('═' * $width)╝" -ForegroundColor DarkCyan
Write-Host ""
