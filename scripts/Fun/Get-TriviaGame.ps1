<#
.SYNOPSIS
    A fun trivia quiz game in PowerShell.
.DESCRIPTION
    This script presents trivia questions from various categories and
    tracks your score. Questions cover technology, science, and general
    knowledge topics.
.PARAMETER Questions
    Number of questions to ask. Default is 5.
.EXAMPLE
    .\Get-TriviaGame.ps1
.EXAMPLE
    .\Get-TriviaGame.ps1 -Questions 10
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://opentdb.com/ (Open Trivia Database)
            and https://www.reddit.com/r/PowerShell/comments/6r1kz8/trivia_game/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 20)]
    [int]$Questions = 5
)

$triviaQuestions = @(
    @{
        Question = "What does CPU stand for?"
        Options  = @("Central Processing Unit", "Computer Personal Unit", "Central Program Utility", "Core Processing Unit")
        Answer   = 0
    },
    @{
        Question = "In what year was PowerShell first released?"
        Options  = @("2004", "2006", "2008", "2010")
        Answer   = 1
    },
    @{
        Question = "What does RAM stand for?"
        Options  = @("Read Access Memory", "Random Access Memory", "Rapid Access Module", "Run Access Memory")
        Answer   = 1
    },
    @{
        Question = "Who created the Linux kernel?"
        Options  = @("Bill Gates", "Steve Jobs", "Linus Torvalds", "Dennis Ritchie")
        Answer   = 2
    },
    @{
        Question = "What does HTML stand for?"
        Options  = @("Hyper Text Markup Language", "High Tech Modern Language", "Hyper Transfer Markup Language", "Home Tool Markup Language")
        Answer   = 0
    },
    @{
        Question = "Which company developed C#?"
        Options  = @("Google", "Apple", "Microsoft", "Oracle")
        Answer   = 2
    },
    @{
        Question = "What is the default port for HTTPS?"
        Options  = @("80", "8080", "443", "8443")
        Answer   = 2
    },
    @{
        Question = "What does DNS stand for?"
        Options  = @("Digital Network Service", "Domain Name System", "Data Network Standard", "Dynamic Name Server")
        Answer   = 1
    },
    @{
        Question = "Which language is known as the 'mother of all languages'?"
        Options  = @("Python", "Java", "C", "FORTRAN")
        Answer   = 2
    },
    @{
        Question = "What does GUI stand for?"
        Options  = @("General User Interface", "Graphical User Interface", "Global Unified Input", "Graphical Universal Integration")
        Answer   = 1
    },
    @{
        Question = "How many bits are in a byte?"
        Options  = @("4", "8", "16", "32")
        Answer   = 1
    },
    @{
        Question = "What does API stand for?"
        Options  = @("Application Programming Interface", "Applied Program Integration", "Automated Process Instruction", "Application Process Interface")
        Answer   = 0
    },
    @{
        Question = "Which company originally developed Java?"
        Options  = @("Microsoft", "Apple", "Sun Microsystems", "IBM")
        Answer   = 2
    },
    @{
        Question = "What does SSH stand for?"
        Options  = @("Secure Shell", "System Shell", "Safe Server Host", "Secure System Host")
        Answer   = 0
    },
    @{
        Question = "What is the largest unit of digital storage listed here?"
        Options  = @("Gigabyte", "Terabyte", "Petabyte", "Exabyte")
        Answer   = 3
    }
)

Write-Host ""
Write-Host "  ╔══════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║        TRIVIA QUIZ GAME          ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

$selectedQuestions = $triviaQuestions | Get-Random -Count ([Math]::Min($Questions, $triviaQuestions.Count))
$score = 0
$questionNum = 0

foreach ($q in $selectedQuestions) {
    $questionNum++
    Write-Host "  Question $questionNum of $($selectedQuestions.Count):" -ForegroundColor Cyan
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
Write-Host "  Final Score: $score / $($selectedQuestions.Count)" -ForegroundColor Cyan

$percent = [math]::Round(($score / $selectedQuestions.Count) * 100)
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
