<#
.SYNOPSIS
    A simple typing speed test in PowerShell.
.DESCRIPTION
    This script measures your typing speed by presenting a sentence and
    timing how fast you type it. Reports words per minute and accuracy.
.EXAMPLE
    .\Get-TypingTest.ps1
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://www.reddit.com/r/PowerShell/comments/gkmyij/
            and https://monkeytype.com/ concept adapted for PowerShell
#>

$sentences = @(
    "The quick brown fox jumps over the lazy dog.",
    "PowerShell is a powerful scripting language for automation.",
    "A journey of a thousand scripts begins with a single cmdlet.",
    "To be or not to be that is the question.",
    "All that glitters is not gold but some of it is PowerShell.",
    "In the beginning was the command line and it was good.",
    "The best way to predict the future is to automate it.",
    "Keep calm and write PowerShell scripts.",
    "Life is short use PowerShell to automate the boring stuff.",
    "Code is poetry written in the language of logic."
)

Write-Host ""
Write-Host "  Typing Speed Test" -ForegroundColor Green
Write-Host "  =================" -ForegroundColor Green
Write-Host ""

$sentence = $sentences | Get-Random

Write-Host "  Type the following sentence:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  $sentence" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Press Enter when ready, then type the sentence and press Enter again." -ForegroundColor DarkGray

Read-Host

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$typed = Read-Host "  Type here"
$stopwatch.Stop()

$elapsed = $stopwatch.Elapsed.TotalSeconds
$wordCount = ($sentence -split '\s+').Count
$wpm = [math]::Round(($wordCount / $elapsed) * 60, 1)

# Calculate accuracy
$correctChars = 0
$maxLen = [Math]::Max($sentence.Length, $typed.Length)
for ($i = 0; $i -lt [Math]::Min($sentence.Length, $typed.Length); $i++) {
    if ($sentence[$i] -eq $typed[$i]) {
        $correctChars++
    }
}
$accuracy = [math]::Round(($correctChars / $sentence.Length) * 100, 1)

Write-Host ""
Write-Host "  ╔══════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║         RESULTS                  ║" -ForegroundColor Cyan
Write-Host "  ╠══════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "  ║  Time:     $("{0:N1}" -f $elapsed) seconds".PadRight(34) + "║" -ForegroundColor Cyan
Write-Host "  ║  Speed:    $wpm WPM".PadRight(34) + "║" -ForegroundColor Cyan
Write-Host "  ║  Accuracy: $accuracy%".PadRight(34) + "║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($wpm -gt 60) {
    Write-Host "  Excellent typing speed!" -ForegroundColor Green
}
elseif ($wpm -gt 40) {
    Write-Host "  Good typing speed!" -ForegroundColor Yellow
}
else {
    Write-Host "  Keep practicing!" -ForegroundColor Red
}
Write-Host ""
