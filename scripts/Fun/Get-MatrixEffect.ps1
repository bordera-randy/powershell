<#
.SYNOPSIS
    Displays a Matrix-style falling text animation in the console.
.DESCRIPTION
    This script creates a Matrix digital rain effect in the PowerShell console
    using random characters falling down the screen. Press Ctrl+C to stop.
.PARAMETER Duration
    Duration in seconds to run the animation. Default is 30.
.PARAMETER Speed
    Speed of the animation in milliseconds between frames. Default is 50.
.EXAMPLE
    .\Get-MatrixEffect.ps1
.EXAMPLE
    .\Get-MatrixEffect.ps1 -Duration 60 -Speed 30
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://www.powershellgallery.com/ and
            https://github.com/guyrleech/Microsoft-PowerShell/blob/master/dvdscreensaver.ps1
#>

param(
    [Parameter(Mandatory = $false)]
    [int]$Duration = 30,

    [Parameter(Mandatory = $false)]
    [int]$Speed = 50
)

$chars = 'abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:,.<>?'
$width = $Host.UI.RawUI.WindowSize.Width
$height = $Host.UI.RawUI.WindowSize.Height

# Initialize column positions
$columns = @{}
for ($i = 0; $i -lt $width; $i++) {
    $columns[$i] = @{
        Position = Get-Random -Minimum 0 -Maximum $height
        Speed    = Get-Random -Minimum 1 -Maximum 4
        Active   = (Get-Random -Minimum 0 -Maximum 3) -eq 0
    }
}

$originalBg = $Host.UI.RawUI.BackgroundColor
$Host.UI.RawUI.BackgroundColor = 'Black'
Clear-Host

Write-Host "Matrix Effect - Press Ctrl+C to stop" -ForegroundColor DarkGreen
Start-Sleep -Seconds 1
Clear-Host

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    while ($stopwatch.Elapsed.TotalSeconds -lt $Duration) {
        for ($col = 0; $col -lt $width; $col++) {
            if ($columns[$col].Active) {
                $row = $columns[$col].Position
                if ($row -lt $height -and $row -ge 0) {
                    $char = $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
                    $cursorPos = $Host.UI.RawUI.NewBufferCellArray(1, 1, [System.Management.Automation.Host.BufferCell]::new(' ', 'Green', 'Black', 'Complete'))
                    try {
                        [Console]::SetCursorPosition($col, $row)
                        Write-Host $char -NoNewline -ForegroundColor Green
                    }
                    catch { }
                }

                $columns[$col].Position += $columns[$col].Speed

                if ($columns[$col].Position -ge $height) {
                    $columns[$col].Position = 0
                    $columns[$col].Speed = Get-Random -Minimum 1 -Maximum 4
                    $columns[$col].Active = (Get-Random -Minimum 0 -Maximum 3) -ne 0
                }
            }
            else {
                $columns[$col].Active = (Get-Random -Minimum 0 -Maximum 20) -eq 0
            }
        }

        Start-Sleep -Milliseconds $Speed
    }
}
finally {
    $Host.UI.RawUI.BackgroundColor = $originalBg
    Clear-Host
    Write-Host "Matrix effect ended." -ForegroundColor Green
}
