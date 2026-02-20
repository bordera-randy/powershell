<#
.SYNOPSIS
    Displays random Chuck Norris-style programming jokes.
.DESCRIPTION
    This script displays random Chuck Norris-style jokes with a
    programming/tech twist. Great for lightening the mood during
    long coding sessions.
.EXAMPLE
    .\Get-ChuckNorrisJoke.ps1
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Jokes inspired by https://api.chucknorris.io/
            and https://www.reddit.com/r/ProgrammerHumor/
#>

$jokes = @(
    "Chuck Norris can solve the halting problem... by staring at the code until it behaves.",
    "Chuck Norris doesn't use version control. The code is too afraid to change.",
    "Chuck Norris can write infinite loops that finish in under 2 seconds.",
    "When Chuck Norris throws an exception, nothing can catch it.",
    "Chuck Norris doesn't need a debugger. Bugs confess on their own.",
    "Chuck Norris can delete the Recycle Bin.",
    "Chuck Norris's code compiles itself out of fear.",
    "Chuck Norris doesn't use try-catch. Nothing dares to throw an exception at him.",
    "Chuck Norris can access private methods from public scope.",
    "When Chuck Norris does a Git push, the remote always accepts.",
    "Chuck Norris doesn't need sudo. The computer does what he says.",
    "Chuck Norris can read from /dev/null.",
    "Chuck Norris's keyboard doesn't have a Ctrl key because nothing controls Chuck Norris.",
    "Chuck Norris can unit test an entire application with a single assert.",
    "When Chuck Norris runs PowerShell, it runs away.",
    "Chuck Norris doesn't deploy to production. Production deploys to Chuck Norris.",
    "Chuck Norris's commit messages are just periods. The code explains itself.",
    "Chuck Norris can binary search an unsorted array.",
    "Chuck Norris can make a class that is both abstract and final.",
    "The cloud is just Chuck Norris's personal computer."
)

$ascii = @"

         ___
        /   \
       | o o |
       |  >  |
        \___/
       /|   |\
      / |   | \
         | |
        _| |_
       |_____|

    CHUCK NORRIS
      APPROVED
"@

Write-Host ""
Write-Host $ascii -ForegroundColor Red
Write-Host ""

$joke = $jokes | Get-Random

Write-Host "  ╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "  ║                                                              ║" -ForegroundColor Yellow

$words = $joke -split " "
$line = " "
foreach ($word in $words) {
    if (($line + " " + $word).Length -gt 61) {
        Write-Host "  ║ $($line.PadRight(60))║" -ForegroundColor Yellow
        $line = " $word"
    }
    else {
        $line += " $word"
    }
}
if ($line.Trim().Length -gt 0) {
    Write-Host "  ║ $($line.PadRight(60))║" -ForegroundColor Yellow
}

Write-Host "  ║                                                              ║" -ForegroundColor Yellow
Write-Host "  ╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""
