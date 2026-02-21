<#
.SYNOPSIS
    Generates and displays a random ASCII maze.
.DESCRIPTION
    This script generates a random maze of configurable size using ASCII
    characters. The maze is created using a recursive backtracker algorithm.
.PARAMETER Width
    Width of the maze in cells. Default is 15.
.PARAMETER Height
    Height of the maze in cells. Default is 10.
.EXAMPLE
    .\Get-Maze.ps1
.EXAMPLE
    .\Get-Maze.ps1 -Width 20 -Height 12
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Source: Maze generation algorithm inspired by
            https://en.wikipedia.org/wiki/Maze_generation_algorithm
            and https://www.reddit.com/r/PowerShell/comments/5nfwbr/maze_generator/
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(5, 30)]
    [int]$Width = 15,

    [Parameter(Mandatory = $false)]
    [ValidateRange(5, 20)]
    [int]$Height = 10
)

# Initialize the grid (each cell tracks which walls are removed)
$grid = New-Object 'int[,]' $Height, $Width
$visited = New-Object 'bool[,]' $Height, $Width

# Directions: 0=North, 1=East, 2=South, 3=West
$dx = @(0, 1, 0, -1)
$dy = @(-1, 0, 1, 0)
$wallBit = @(1, 2, 4, 8)
$oppositeBit = @(4, 8, 1, 2)

function Carve-Maze {
    param([int]$x, [int]$y)

    $visited[$y, $x] = $true
    $directions = 0..3 | Get-Random -Count 4

    foreach ($dir in $directions) {
        $nx = $x + $dx[$dir]
        $ny = $y + $dy[$dir]

        if ($nx -ge 0 -and $nx -lt $Width -and $ny -ge 0 -and $ny -lt $Height -and -not $visited[$ny, $nx]) {
            $grid[$y, $x] = $grid[$y, $x] -bor $wallBit[$dir]
            $grid[$ny, $nx] = $grid[$ny, $nx] -bor $oppositeBit[$dir]
            Carve-Maze -x $nx -y $ny
        }
    }
}

Write-Host ""
Write-Host "  Maze Generator" -ForegroundColor Green
Write-Host "  ==============" -ForegroundColor Green
Write-Host "  Size: ${Width}x${Height}" -ForegroundColor DarkGray
Write-Host ""

# Generate the maze starting from top-left
Carve-Maze -x 0 -y 0

# Render the maze
$topLine = "  +"
for ($x = 0; $x -lt $Width; $x++) {
    if ($x -eq 0) {
        $topLine += "   +"  # Entrance
    }
    else {
        $topLine += "---+"
    }
}
Write-Host $topLine -ForegroundColor Cyan

for ($y = 0; $y -lt $Height; $y++) {
    $midLine = "  |"
    $botLine = "  +"

    for ($x = 0; $x -lt $Width; $x++) {
        # East wall
        if ($grid[$y, $x] -band 2) {
            $midLine += "    "
        }
        else {
            $midLine += "   |"
        }

        # South wall
        if ($grid[$y, $x] -band 4) {
            $botLine += "   +"
        }
        else {
            if ($y -eq $Height - 1 -and $x -eq $Width - 1) {
                $botLine += "   +"  # Exit
            }
            else {
                $botLine += "---+"
            }
        }
    }

    Write-Host $midLine -ForegroundColor Cyan
    Write-Host $botLine -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  Start: Top-left | Exit: Bottom-right" -ForegroundColor Yellow
Write-Host ""
