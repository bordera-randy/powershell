<#
.SYNOPSIS
    Displays text with decorative word art borders.
.DESCRIPTION
    This script creates word art with various decorative border styles.
    Useful for creating eye-catching headers and banners in console output.
.PARAMETER Text
    The text to display. Default is "PowerShell".
.PARAMETER BorderStyle
    The border style to use. Valid values: Double, Single, Stars, Hash, Rounded.
.EXAMPLE
    .\Get-WordArt.ps1 -Text "Hello World"
.EXAMPLE
    .\Get-WordArt.ps1 -Text "DevOps" -BorderStyle Stars
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://devblogs.microsoft.com/scripting/use-ascii-art-in-powershell/
            and https://www.asciiart.eu/text-art
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Text = "PowerShell",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Double", "Single", "Stars", "Hash", "Rounded")]
    [string]$BorderStyle = "Double"
)

$borders = @{
    Double = @{
        TL = "╔"; TR = "╗"; BL = "╚"; BR = "╝"
        H  = "═"; V  = "║"
    }
    Single = @{
        TL = "┌"; TR = "┐"; BL = "└"; BR = "┘"
        H  = "─"; V  = "│"
    }
    Stars = @{
        TL = "*"; TR = "*"; BL = "*"; BR = "*"
        H  = "*"; V  = "*"
    }
    Hash = @{
        TL = "#"; TR = "#"; BL = "#"; BR = "#"
        H  = "#"; V  = "#"
    }
    Rounded = @{
        TL = "╭"; TR = "╮"; BL = "╰"; BR = "╯"
        H  = "─"; V  = "│"
    }
}

$b = $borders[$BorderStyle]
$padding = 4
$innerWidth = $Text.Length + ($padding * 2)

Write-Host ""

# Top border
$topLine = "  $($b.TL)$($b.H * $innerWidth)$($b.TR)"
Write-Host $topLine -ForegroundColor Cyan

# Empty line
$emptyLine = "  $($b.V)$(' ' * $innerWidth)$($b.V)"
Write-Host $emptyLine -ForegroundColor Cyan

# Text line
$textLine = "  $($b.V)$(' ' * $padding)$Text$(' ' * $padding)$($b.V)"
Write-Host $textLine -ForegroundColor Yellow

# Empty line
Write-Host $emptyLine -ForegroundColor Cyan

# Bottom border
$botLine = "  $($b.BL)$($b.H * $innerWidth)$($b.BR)"
Write-Host $botLine -ForegroundColor Cyan

Write-Host ""
Write-Host "  Style: $BorderStyle" -ForegroundColor DarkGray
Write-Host ""
