<#
.SYNOPSIS
    Displays a visual countdown timer in the console.
.DESCRIPTION
    This script shows a colorful countdown timer with large ASCII numbers.
    It can count down from a specified number of seconds and plays a
    completion message when finished.
.PARAMETER Seconds
    Number of seconds to count down from. Default is 10.
.PARAMETER Message
    Message to display when the countdown completes. Default is "Time's up!".
.EXAMPLE
    .\Get-Countdown.ps1
.EXAMPLE
    .\Get-Countdown.ps1 -Seconds 60 -Message "Meeting starts now!"
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://community.spiceworks.com/topic/post/6350583
            and https://devblogs.microsoft.com/scripting/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3600)]
    [int]$Seconds = 10,

    [Parameter(Mandatory = $false)]
    [string]$Message = "Time's up!"
)

$digits = @{
    '0' = @(
        " ███ ",
        "█   █",
        "█   █",
        "█   █",
        " ███ "
    )
    '1' = @(
        "  █  ",
        " ██  ",
        "  █  ",
        "  █  ",
        " ███ "
    )
    '2' = @(
        " ███ ",
        "█   █",
        "  ██ ",
        " █   ",
        "█████"
    )
    '3' = @(
        " ███ ",
        "█   █",
        "  ██ ",
        "█   █",
        " ███ "
    )
    '4' = @(
        "█   █",
        "█   █",
        "█████",
        "    █",
        "    █"
    )
    '5' = @(
        "█████",
        "█    ",
        "████ ",
        "    █",
        "████ "
    )
    '6' = @(
        " ███ ",
        "█    ",
        "████ ",
        "█   █",
        " ███ "
    )
    '7' = @(
        "█████",
        "    █",
        "   █ ",
        "  █  ",
        "  █  "
    )
    '8' = @(
        " ███ ",
        "█   █",
        " ███ ",
        "█   █",
        " ███ "
    )
    '9' = @(
        " ███ ",
        "█   █",
        " ████",
        "    █",
        " ███ "
    )
    ':' = @(
        "     ",
        "  █  ",
        "     ",
        "  █  ",
        "     "
    )
}

function Show-BigNumber {
    param([string]$NumberString)

    for ($row = 0; $row -lt 5; $row++) {
        $line = ""
        foreach ($char in $NumberString.ToCharArray()) {
            if ($digits.ContainsKey([string]$char)) {
                $line += $digits[[string]$char][$row] + "  "
            }
        }
        $color = if ($NumberString -match '^\d+$' -and [int]$NumberString -le 3) { "Red" }
                 elseif ($NumberString -match '^\d+$' -and [int]$NumberString -le 5) { "Yellow" }
                 else { "Green" }
        Write-Host "    $line" -ForegroundColor $color
    }
}

Write-Host ""
Write-Host "  Countdown Timer" -ForegroundColor Cyan
Write-Host "  ===============" -ForegroundColor Cyan
Write-Host ""

for ($i = $Seconds; $i -ge 0; $i--) {
    Clear-Host
    Write-Host ""
    Write-Host "  Countdown Timer" -ForegroundColor Cyan
    Write-Host "  ===============" -ForegroundColor Cyan
    Write-Host ""

    if ($i -ge 60) {
        $min = [math]::Floor($i / 60)
        $sec = $i % 60
        $display = "{0}:{1:D2}" -f $min, $sec
    }
    else {
        $display = "$i"
    }

    Show-BigNumber -NumberString $display
    Write-Host ""

    if ($i -gt 0) {
        Start-Sleep -Seconds 1
    }
}

Write-Host ""
Write-Host "  *** $Message ***" -ForegroundColor Yellow
Write-Host ""

# Try to play a beep sound
try {
    [Console]::Beep(800, 200)
    [Console]::Beep(800, 200)
    [Console]::Beep(800, 400)
}
catch {
    # Beep not supported on all platforms
}
