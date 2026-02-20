<#
.SYNOPSIS
    Displays a large digital clock in the console.
.DESCRIPTION
    This script shows the current time as a large digital clock using
    ASCII art digits. Updates every second for the specified duration.
.PARAMETER Duration
    How many seconds to display the clock. Default is 30.
.PARAMETER ShowDate
    Include the date below the time display.
.EXAMPLE
    .\Get-DigitalClock.ps1
.EXAMPLE
    .\Get-DigitalClock.ps1 -Duration 60 -ShowDate
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://www.reddit.com/r/PowerShell/comments/3zg3h3/ascii_clock/
            and https://devblogs.microsoft.com/scripting/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 300)]
    [int]$Duration = 30,

    [Parameter(Mandatory = $false)]
    [switch]$ShowDate
)

$digits = @{
    '0' = @(" ██████ ", "██    ██", "██    ██", "██    ██", " ██████ ")
    '1' = @("   ██   ", "  ███   ", "   ██   ", "   ██   ", " ██████ ")
    '2' = @(" ██████ ", "      ██", " ██████ ", "██      ", " ██████ ")
    '3' = @(" ██████ ", "      ██", " ██████ ", "      ██", " ██████ ")
    '4' = @("██    ██", "██    ██", " ██████ ", "      ██", "      ██")
    '5' = @(" ██████ ", "██      ", " ██████ ", "      ██", " ██████ ")
    '6' = @(" ██████ ", "██      ", " ██████ ", "██    ██", " ██████ ")
    '7' = @(" ██████ ", "      ██", "    ██  ", "   ██   ", "   ██   ")
    '8' = @(" ██████ ", "██    ██", " ██████ ", "██    ██", " ██████ ")
    '9' = @(" ██████ ", "██    ██", " ██████ ", "      ██", " ██████ ")
    ':' = @("        ", "   ██   ", "        ", "   ██   ", "        ")
}

Write-Host ""
Write-Host "  Digital Clock - Press Ctrl+C to stop" -ForegroundColor Green
Write-Host ""

for ($t = 0; $t -lt $Duration; $t++) {
    $now = Get-Date
    $timeStr = $now.ToString("HH:mm:ss")

    # Move cursor up to overwrite previous display
    if ($t -gt 0) {
        [Console]::SetCursorPosition(0, [Console]::CursorTop - 7)
    }

    Write-Host ""
    for ($row = 0; $row -lt 5; $row++) {
        $line = "  "
        foreach ($char in $timeStr.ToCharArray()) {
            $charKey = [string]$char
            if ($charKey -eq ':') {
                # Blink the colon every other second
                if ($now.Second % 2 -eq 0) {
                    $line += $digits[$charKey][$row]
                }
                else {
                    $line += "        "
                }
            }
            elseif ($digits.ContainsKey($charKey)) {
                $line += $digits[$charKey][$row]
            }
            $line += " "
        }
        Write-Host $line -ForegroundColor Cyan
    }

    if ($ShowDate) {
        Write-Host ""
        Write-Host "  $($now.ToString('dddd, MMMM dd, yyyy'))" -ForegroundColor Yellow
    }
    else {
        Write-Host ""
    }

    if ($t -lt $Duration - 1) {
        Start-Sleep -Seconds 1
    }
}

Write-Host ""
