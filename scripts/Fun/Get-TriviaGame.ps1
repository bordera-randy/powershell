<#
.SYNOPSIS
    A fun trivia quiz game powered by the Open Trivia Database API.
.DESCRIPTION
    This script presents trivia questions fetched from the Open Trivia
    Database API (https://opentdb.com/). Falls back to built-in questions
    if the API is unavailable. Questions cover technology, science, and
    general knowledge topics.
.PARAMETER Questions
    Number of questions to ask. Default is 5 (max 20).
.PARAMETER Category
    Trivia category ID from opentdb.com. Common values:
      18 = Computers, 17 = Science & Nature, 9 = General Knowledge.
    Defaults to Computers (18).
.EXAMPLE
    .\Get-TriviaGame.ps1
.EXAMPLE
    .\Get-TriviaGame.ps1 -Questions 10
.EXAMPLE
    .\Get-TriviaGame.ps1 -Questions 5 -Category 9
.NOTES
    Author: PowerShell Utility Collection
    Version: 2.0
    API: https://opentdb.com/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 20)]
    [int]$Questions = 5,

    [Parameter(Mandatory = $false)]
    [int]$Category = 18
)

$builtInQuestions = @(
    @{ Question = "What does CPU stand for?"; Options = @("Central Processing Unit", "Computer Personal Unit", "Central Program Utility", "Core Processing Unit"); Answer = 0 },
    @{ Question = "In what year was PowerShell first released?"; Options = @("2004", "2006", "2008", "2010"); Answer = 1 },
    @{ Question = "What does RAM stand for?"; Options = @("Read Access Memory", "Random Access Memory", "Rapid Access Module", "Run Access Memory"); Answer = 1 },
    @{ Question = "Who created the Linux kernel?"; Options = @("Bill Gates", "Steve Jobs", "Linus Torvalds", "Dennis Ritchie"); Answer = 2 },
    @{ Question = "What does HTML stand for?"; Options = @("Hyper Text Markup Language", "High Tech Modern Language", "Hyper Transfer Markup Language", "Home Tool Markup Language"); Answer = 0 },
    @{ Question = "Which company developed C#?"; Options = @("Google", "Apple", "Microsoft", "Oracle"); Answer = 2 },
    @{ Question = "What is the default port for HTTPS?"; Options = @("80", "8080", "443", "8443"); Answer = 2 },
    @{ Question = "What does DNS stand for?"; Options = @("Digital Network Service", "Domain Name System", "Data Network Standard", "Dynamic Name Server"); Answer = 1 },
    @{ Question = "Which language is known as the 'mother of all languages'?"; Options = @("Python", "Java", "C", "FORTRAN"); Answer = 2 },
    @{ Question = "What does GUI stand for?"; Options = @("General User Interface", "Graphical User Interface", "Global Unified Input", "Graphical Universal Integration"); Answer = 1 },
    @{ Question = "How many bits are in a byte?"; Options = @("4", "8", "16", "32"); Answer = 1 },
    @{ Question = "What does API stand for?"; Options = @("Application Programming Interface", "Applied Program Integration", "Automated Process Instruction", "Application Process Interface"); Answer = 0 },
    @{ Question = "Which company originally developed Java?"; Options = @("Microsoft", "Apple", "Sun Microsystems", "IBM"); Answer = 2 },
    @{ Question = "What does SSH stand for?"; Options = @("Secure Shell", "System Shell", "Safe Server Host", "Secure System Host"); Answer = 0 },
    @{ Question = "What is the largest unit of digital storage listed here?"; Options = @("Gigabyte", "Terabyte", "Petabyte", "Exabyte"); Answer = 3 }
)

function ConvertFrom-HtmlEncoded {
    param([string]$Text)
    try {
        return [System.Web.HttpUtility]::HtmlDecode($Text)
    }
    catch {
        return $Text -replace '&amp;', '&' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&quot;', '"' -replace '&#039;', "'"
    }
}

Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "  ╔══════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║        TRIVIA QUIZ GAME          ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Try fetching questions from Open Trivia Database
$triviaQuestions = $null
try {
    $uri = "https://opentdb.com/api.php?amount=$Questions&category=$Category&type=multiple"
    $response = Invoke-RestMethod -Uri $uri -TimeoutSec 10
    if ($response.response_code -eq 0 -and $response.results.Count -gt 0) {
        $triviaQuestions = $response.results | ForEach-Object {
            $q = $_
            $allAnswers = @($q.correct_answer) + $q.incorrect_answers | Sort-Object { Get-Random }
            $correctIndex = [array]::IndexOf($allAnswers, $q.correct_answer)
            @{
                Question = ConvertFrom-HtmlEncoded $q.question
                Options  = $allAnswers | ForEach-Object { ConvertFrom-HtmlEncoded $_ }
                Answer   = $correctIndex
            }
        }
        Write-Verbose "Loaded $($triviaQuestions.Count) questions from Open Trivia Database."
    }
}
catch {
    Write-Verbose "Open Trivia Database unavailable, using built-in questions: $_"
}

if (-not $triviaQuestions) {
    $triviaQuestions = $builtInQuestions | Get-Random -Count ([Math]::Min($Questions, $builtInQuestions.Count))
}

$score = 0
$questionNum = 0

foreach ($q in $triviaQuestions) {
    $questionNum++
    Write-Host "  Question $questionNum of $($triviaQuestions.Count):" -ForegroundColor Cyan
    Write-Host "  $($q.Question)" -ForegroundColor Yellow
    Write-Host ""

    for ($i = 0; $i -lt $q.Options.Count; $i++) {
        Write-Host "    $($i + 1). $($q.Options[$i])" -ForegroundColor White
    }
    Write-Host ""

    $answer = Read-Host "  Your answer (1-$($q.Options.Count))"

    if ($answer -match '^\d+$' -and ([int]$answer - 1) -eq $q.Answer) {
        Write-Host "  ✓ Correct!" -ForegroundColor Green
        $score++
    }
    else {
        Write-Host "  ✗ Wrong! The answer was: $($q.Options[$q.Answer])" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "  ═══════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Final Score: $score / $($triviaQuestions.Count)" -ForegroundColor Cyan

$percent = [math]::Round(($score / $triviaQuestions.Count) * 100)
if ($percent -ge 80) {
    Write-Host "  Excellent! You're a tech genius!" -ForegroundColor Green
}
elseif ($percent -ge 60) {
    Write-Host "  Good job! You know your stuff!" -ForegroundColor Yellow
}
else {
    Write-Host "  Keep learning! You'll get there!" -ForegroundColor Red
}
Write-Host ""
