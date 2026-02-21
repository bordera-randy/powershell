<#
.SYNOPSIS
    Displays a colorful calendar for the current or specified month.
.DESCRIPTION
    This script shows a nicely formatted calendar with the current day
    highlighted. Supports viewing any month and year.
.PARAMETER Month
    The month to display (1-12). Default is the current month.
.PARAMETER Year
    The year to display. Default is the current year.
.EXAMPLE
    .\Get-Calendar.ps1
.EXAMPLE
    .\Get-Calendar.ps1 -Month 12 -Year 2025
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Source: Inspired by the Unix 'cal' command
            https://en.wikipedia.org/wiki/Cal_(Unix)
            and https://devblogs.microsoft.com/scripting/use-powershell-to-display-a-calendar/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 12)]
    [int]$Month = (Get-Date).Month,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1900, 2100)]
    [int]$Year = (Get-Date).Year
)

$today = Get-Date
$firstDay = Get-Date -Year $Year -Month $Month -Day 1
$daysInMonth = [DateTime]::DaysInMonth($Year, $Month)
$monthName = $firstDay.ToString("MMMM")
$startDayOfWeek = [int]$firstDay.DayOfWeek

Write-Host ""
Write-Host "  ╔════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║  $("$monthName $Year".PadRight(24))  ║" -ForegroundColor Cyan
Write-Host "  ╠════════════════════════════╣" -ForegroundColor Cyan
Write-Host "  ║  Su  Mo  Tu  We  Th  Fr  Sa  ║" -ForegroundColor Yellow
Write-Host "  ╠════════════════════════════╣" -ForegroundColor Cyan

$line = "  ║  "

# Add spaces for days before the first day
for ($i = 0; $i -lt $startDayOfWeek; $i++) {
    $line += "    "
}

for ($day = 1; $day -le $daysInMonth; $day++) {
    $isToday = ($day -eq $today.Day -and $Month -eq $today.Month -and $Year -eq $today.Year)

    if ($isToday) {
        $dayStr = "[{0,2}]" -f $day
    }
    else {
        $dayStr = " {0,2} " -f $day
    }

    $line += $dayStr

    $dayOfWeek = ([int](Get-Date -Year $Year -Month $Month -Day $day).DayOfWeek)

    if ($dayOfWeek -eq 6 -or $day -eq $daysInMonth) {
        # Pad remaining spaces if last line
        if ($day -eq $daysInMonth -and $dayOfWeek -ne 6) {
            for ($j = $dayOfWeek + 1; $j -le 6; $j++) {
                $line += "    "
            }
        }
        Write-Host $line -ForegroundColor White
        $line = "  ║  "
    }
}

Write-Host "  ╚════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($Month -eq $today.Month -and $Year -eq $today.Year) {
    Write-Host "  Today is $($today.ToString('dddd, MMMM dd, yyyy'))" -ForegroundColor Green
    Write-Host ""
}
