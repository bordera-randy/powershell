<#
.SYNOPSIS
    Generates a random team name for hackathons or projects.
.DESCRIPTION
    This script generates creative and fun team names by combining
    adjectives with tech-related nouns. Great for hackathons, sprint
    teams, or project codenames.
.PARAMETER Count
    Number of team names to generate. Default is 5.
.PARAMETER Style
    Naming style. Valid values: Tech, Epic, Funny, Random.
.EXAMPLE
    .\Get-TeamNameGenerator.ps1
.EXAMPLE
    .\Get-TeamNameGenerator.ps1 -Count 10 -Style Epic
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://www.reddit.com/r/PowerShell/
            and https://namelix.com/ naming patterns
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 20)]
    [int]$Count = 5,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Tech", "Epic", "Funny", "Random")]
    [string]$Style = "Random"
)

$techAdjectives = @("Quantum", "Digital", "Binary", "Neural", "Cloud", "Cyber",
                     "Virtual", "Agile", "Atomic", "Dynamic", "Infinite", "Turbo")
$techNouns = @("Coders", "Hackers", "Debuggers", "Deployers", "Builders",
               "Architects", "Engineers", "Ninjas", "Wizards", "Pirates")

$epicAdjectives = @("Legendary", "Supreme", "Mighty", "Fearless", "Unstoppable",
                     "Blazing", "Thunder", "Iron", "Shadow", "Phoenix", "Storm", "Dragon")
$epicNouns = @("Warriors", "Knights", "Champions", "Titans", "Legends",
               "Guardians", "Avengers", "Crusaders", "Sentinels", "Defenders")

$funnyAdjectives = @("Caffeinated", "Sleepless", "Confused", "Accidental",
                      "Reluctant", "Chaotic", "Procrastinating", "Overtime",
                      "Undocumented", "Deprecated", "Legacy", "Spaghetti")
$funnyNouns = @("Developers", "Interns", "Stackoverflowers", "Googlers",
                "Debuggers", "Coffee Drinkers", "Typo Makers", "Bug Creators",
                "Merge Conflicters", "Script Kiddies")

function Get-TeamName {
    param([string]$NameStyle)

    switch ($NameStyle) {
        "Tech" {
            $adj = $techAdjectives | Get-Random
            $noun = $techNouns | Get-Random
        }
        "Epic" {
            $adj = $epicAdjectives | Get-Random
            $noun = $epicNouns | Get-Random
        }
        "Funny" {
            $adj = $funnyAdjectives | Get-Random
            $noun = $funnyNouns | Get-Random
        }
    }
    return "$adj $noun"
}

Write-Host ""
Write-Host "  Team Name Generator" -ForegroundColor Green
Write-Host "  ===================" -ForegroundColor Green
Write-Host ""

if ($Style -eq "Random") {
    $styles = @("Tech", "Epic", "Funny")
}
else {
    $styles = @($Style)
}

Write-Host "  Generated Team Names:" -ForegroundColor Cyan
Write-Host ""

for ($i = 1; $i -le $Count; $i++) {
    $currentStyle = $styles | Get-Random
    $name = Get-TeamName -NameStyle $currentStyle

    $color = switch ($currentStyle) {
        "Tech"  { "Cyan" }
        "Epic"  { "Yellow" }
        "Funny" { "Magenta" }
    }

    Write-Host "    $($i.ToString().PadLeft(2)). " -NoNewline -ForegroundColor DarkGray
    Write-Host $name -ForegroundColor $color
}

Write-Host ""
Write-Host "  Style: $Style" -ForegroundColor DarkGray
Write-Host ""
