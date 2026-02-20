<#
.SYNOPSIS
    Displays the PowerShell console color palette.
.DESCRIPTION
    This script shows all available console colors in both foreground and
    background combinations. Useful for choosing colors for your scripts
    and understanding what color options are available.
.PARAMETER ShowBackground
    When specified, also shows background color combinations.
.EXAMPLE
    .\Get-ColorPalette.ps1
.EXAMPLE
    .\Get-ColorPalette.ps1 -ShowBackground
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://devblogs.microsoft.com/scripting/colorful-powershell/
            and https://stackoverflow.com/questions/20541456/list-of-all-colors-available-for-powershell
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$ShowBackground
)

$colors = @(
    'Black', 'DarkBlue', 'DarkGreen', 'DarkCyan',
    'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray',
    'DarkGray', 'Blue', 'Green', 'Cyan',
    'Red', 'Magenta', 'Yellow', 'White'
)

Write-Host ""
Write-Host "  PowerShell Color Palette" -ForegroundColor Green
Write-Host "  ========================" -ForegroundColor Green
Write-Host ""

Write-Host "  Foreground Colors:" -ForegroundColor Cyan
Write-Host "  ------------------" -ForegroundColor Cyan
Write-Host ""

foreach ($color in $colors) {
    Write-Host "  ██████ " -NoNewline -ForegroundColor $color
    Write-Host " $($color.PadRight(15))" -ForegroundColor $color
}

Write-Host ""

if ($ShowBackground) {
    Write-Host "  Background Color Grid:" -ForegroundColor Cyan
    Write-Host "  ----------------------" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  " -NoNewline
    Write-Host "BG \ FG".PadRight(14) -NoNewline -ForegroundColor Yellow
    foreach ($fg in $colors) {
        Write-Host $fg.Substring(0, [Math]::Min(4, $fg.Length)).PadRight(6) -NoNewline -ForegroundColor Yellow
    }
    Write-Host ""

    foreach ($bg in $colors) {
        Write-Host "  $($bg.PadRight(14))" -NoNewline -ForegroundColor Yellow
        foreach ($fg in $colors) {
            Write-Host " Text " -NoNewline -ForegroundColor $fg -BackgroundColor $bg
        }
        Write-Host ""
    }
}

Write-Host ""
Write-Host "  Total colors available: $($colors.Count)" -ForegroundColor DarkGray
Write-Host ""
