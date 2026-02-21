<#
.SYNOPSIS
    Generates a random developer excuse from the Excuser API.
.DESCRIPTION
    This script fetches and displays a humorous developer excuse from the
    Excuser API (https://excuser-three.vercel.app/). Falls back to built-in
    excuses if the API is unavailable.
    Categories include excuses for being late, missing deadlines, and
    explaining bugs in your code.
.PARAMETER Category
    Category of excuse. Valid values: Late, Deadline, Bug, Random.
    When the API is used, this parameter is not sent to the API.
.EXAMPLE
    .\Get-Excuse.ps1
.EXAMPLE
    .\Get-Excuse.ps1 -Category Bug
.NOTES
    Author: PowerShell Utility Collection
    Version: 2.0
    API: https://excuser-three.vercel.app/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Late", "Deadline", "Bug", "Random")]
    [string]$Category = "Random"
)

$lateExcuses = @(
    "My code was compiling.",
    "I was resolving a merge conflict in my alarm clock.",
    "My home lab needed an emergency patch.",
    "I was stuck in an infinite loop on my commute.",
    "My container wouldn't start this morning.",
    "I was debugging my coffee maker's firmware.",
    "Git was rebasing my morning routine.",
    "My VPN was routing me through every country first."
)

$deadlineExcuses = @(
    "The requirements changed during the sprint.",
    "I was waiting for the API documentation to be updated.",
    "The dependency I needed was deprecated yesterday.",
    "It works on my machine, just not in production yet.",
    "I found a critical security vulnerability that needed fixing first.",
    "The cloud region went down and I lost my dev environment.",
    "I was pair programming with my rubber duck and we disagreed.",
    "Stack Overflow was down for maintenance."
)

$bugExcuses = @(
    "That's not a bug, it's an undocumented feature.",
    "It must be a race condition caused by cosmic rays.",
    "The previous developer left that there intentionally.",
    "It worked in testing. The users are holding it wrong.",
    "That edge case wasn't in the requirements.",
    "The framework update broke backward compatibility.",
    "It's a known issue with a workaround in the wiki.",
    "The compiler optimized away the correct behavior."
)

if ($Category -eq "Random") {
    $Category = @("Late", "Deadline", "Bug") | Get-Random
}

# Try fetching an excuse from the Excuser API
$excuse = $null
try {
    $response = Invoke-RestMethod -Uri "https://excuser-three.vercel.app/v1/excuse" -TimeoutSec 10
    if ($response -and $response[0].excuse) {
        $excuse = $response[0].excuse
        Write-Verbose "Fetched excuse from Excuser API."
    }
}
catch {
    Write-Verbose "Excuser API unavailable, using built-in excuses: $_"
}

if (-not $excuse) {
    $excuses = switch ($Category) {
        "Late"     { $lateExcuses }
        "Deadline" { $deadlineExcuses }
        "Bug"      { $bugExcuses }
    }
    $excuse = $excuses | Get-Random
}

$icon = switch ($Category) {
    "Late"     { "⏰" }
    "Deadline" { "📅" }
    "Bug"      { "🐛" }
}

Write-Host ""
Write-Host "  Developer Excuse Generator" -ForegroundColor Green
Write-Host "  ==========================" -ForegroundColor Green
Write-Host ""
Write-Host "  Category: $icon $Category" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "  ║                                                          ║" -ForegroundColor Yellow

$words = $excuse -split " "
$line = "  "
foreach ($word in $words) {
    if (($line + " " + $word).Length -gt 57) {
        Write-Host "  ║ $($line.PadRight(56))║" -ForegroundColor Yellow
        $line = "  $word"
    }
    else {
        $line += " $word"
    }
}
if ($line.Trim().Length -gt 0) {
    Write-Host "  ║ $($line.PadRight(56))║" -ForegroundColor Yellow
}

Write-Host "  ║                                                          ║" -ForegroundColor Yellow
Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Disclaimer: Use at your own risk!" -ForegroundColor DarkGray
Write-Host ""
