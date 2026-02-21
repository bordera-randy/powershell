<#
.SYNOPSIS
    Demonstrates various progress bar styles and animations.
.DESCRIPTION
    This script showcases different progress bar styles that can be used
    in PowerShell scripts, including classic bars, spinners, and block-style
    progress indicators.
.PARAMETER Style
    The progress bar style to demo. Valid values: Classic, Blocks, Dots, Spinner, All.
.PARAMETER Duration
    Duration of the demo in seconds. Default is 5.
.EXAMPLE
    .\Get-ProgressBarDemo.ps1
.EXAMPLE
    .\Get-ProgressBarDemo.ps1 -Style Blocks -Duration 10
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Source: Inspired by https://www.reddit.com/r/PowerShell/comments/7kd1yy/progress_bar_examples/
            and https://devblogs.microsoft.com/scripting/use-powershell-to-create-progress-bars/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Classic", "Blocks", "Dots", "Spinner", "All")]
    [string]$Style = "All",

    [Parameter(Mandatory = $false)]
    [ValidateRange(2, 30)]
    [int]$Duration = 5
)

function Show-ClassicBar {
    param([int]$Seconds)
    Write-Host "  Classic Progress Bar:" -ForegroundColor Cyan
    $steps = $Seconds * 10
    for ($i = 0; $i -le $steps; $i++) {
        $percent = [math]::Round(($i / $steps) * 100)
        $filled = [math]::Round($percent / 2)
        $empty = 50 - $filled
        $bar = "[" + ("█" * $filled) + ("░" * $empty) + "]"
        Write-Host "`r  $bar $percent%" -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds 100
    }
    Write-Host ""
    Write-Host "  Complete!" -ForegroundColor Green
    Write-Host ""
}

function Show-BlocksBar {
    param([int]$Seconds)
    Write-Host "  Block Progress Bar:" -ForegroundColor Cyan
    $steps = $Seconds * 10
    $blocks = @("░", "▒", "▓", "█")
    for ($i = 0; $i -le $steps; $i++) {
        $percent = [math]::Round(($i / $steps) * 100)
        $filled = [math]::Round($percent / 5)
        $bar = ""
        for ($j = 0; $j -lt 20; $j++) {
            if ($j -lt $filled) {
                $bar += "█"
            }
            elseif ($j -eq $filled) {
                $blockIdx = ($i % 4)
                $bar += $blocks[$blockIdx]
            }
            else {
                $bar += " "
            }
        }
        Write-Host "`r  |$bar| $percent%" -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds 100
    }
    Write-Host ""
    Write-Host "  Complete!" -ForegroundColor Green
    Write-Host ""
}

function Show-DotsBar {
    param([int]$Seconds)
    Write-Host "  Dots Progress:" -ForegroundColor Cyan
    $steps = $Seconds * 5
    for ($i = 0; $i -le $steps; $i++) {
        $percent = [math]::Round(($i / $steps) * 100)
        $dots = "●" * [math]::Round($i / 2) + "○" * [math]::Round(($steps - $i) / 2)
        Write-Host "`r  $dots $percent%" -NoNewline -ForegroundColor Magenta
        Start-Sleep -Milliseconds 200
    }
    Write-Host ""
    Write-Host "  Complete!" -ForegroundColor Green
    Write-Host ""
}

function Show-SpinnerBar {
    param([int]$Seconds)
    Write-Host "  Spinner:" -ForegroundColor Cyan
    $spinChars = @("|", "/", "-", "\")
    $steps = $Seconds * 10
    for ($i = 0; $i -le $steps; $i++) {
        $percent = [math]::Round(($i / $steps) * 100)
        $spinner = $spinChars[$i % 4]
        Write-Host "`r  $spinner Loading... $percent%" -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 100
    }
    Write-Host ""
    Write-Host "  Complete!" -ForegroundColor Green
    Write-Host ""
}

Write-Host ""
Write-Host "  Progress Bar Demos" -ForegroundColor Green
Write-Host "  ==================" -ForegroundColor Green
Write-Host ""

switch ($Style) {
    "Classic" { Show-ClassicBar -Seconds $Duration }
    "Blocks"  { Show-BlocksBar -Seconds $Duration }
    "Dots"    { Show-DotsBar -Seconds $Duration }
    "Spinner" { Show-SpinnerBar -Seconds $Duration }
    "All" {
        Show-ClassicBar -Seconds ([math]::Max(2, [math]::Floor($Duration / 4)))
        Show-BlocksBar -Seconds ([math]::Max(2, [math]::Floor($Duration / 4)))
        Show-DotsBar -Seconds ([math]::Max(2, [math]::Floor($Duration / 4)))
        Show-SpinnerBar -Seconds ([math]::Max(2, [math]::Floor($Duration / 4)))
    }
}
