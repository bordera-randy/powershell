<#
.SYNOPSIS
    Displays random color blocks and color information.
.DESCRIPTION
    This script generates random colors and displays them with their RGB
    and hex values. Creates a visual random color palette.
.PARAMETER Count
    Number of random colors to generate. Default is 10.
.EXAMPLE
    .\Get-RandomColor.ps1
.EXAMPLE
    .\Get-RandomColor.ps1 -Count 20
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Source: Inspired by https://stackoverflow.com/questions/20541456/list-of-all-colors-available-for-powershell
            and https://devblogs.microsoft.com/scripting/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 50)]
    [int]$Count = 10
)

$consoleColors = @(
    'Black', 'DarkBlue', 'DarkGreen', 'DarkCyan',
    'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray',
    'DarkGray', 'Blue', 'Green', 'Cyan',
    'Red', 'Magenta', 'Yellow', 'White'
)

Write-Host ""
Write-Host "  Random Color Generator" -ForegroundColor Green
Write-Host "  ======================" -ForegroundColor Green
Write-Host ""

for ($i = 1; $i -le $Count; $i++) {
    $color = $consoleColors | Get-Random
    $r = Get-Random -Minimum 0 -Maximum 256
    $g = Get-Random -Minimum 0 -Maximum 256
    $b = Get-Random -Minimum 0 -Maximum 256
    $hex = "#{0:X2}{1:X2}{2:X2}" -f $r, $g, $b

    Write-Host "  " -NoNewline
    Write-Host "████████" -NoNewline -ForegroundColor $color
    Write-Host "  Color $($i.ToString().PadLeft(2)): " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($color.PadRight(14))" -NoNewline -ForegroundColor $color
    Write-Host " | RGB($r,$g,$b) | $hex" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Generated $Count random color samples" -ForegroundColor DarkGray
Write-Host "  Console supports $($consoleColors.Count) named colors" -ForegroundColor DarkGray
Write-Host ""
