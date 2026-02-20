<#
.SYNOPSIS
    Example of using System.Diagnostics.Stopwatch for timing operations.

.DESCRIPTION
    This script demonstrates how to use the .NET Stopwatch class to measure
    elapsed time during script execution. It's useful for performance monitoring,
    timing long-running operations, or implementing delays with progress tracking.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    
.LINK
    System.Diagnostics.Stopwatch

.EXAMPLE
    Run this script to see a 10-second timer with second-by-second updates.
#>

# Create and start a new stopwatch
$stopwatch = [system.diagnostics.stopwatch]::StartNew()

# Run a loop for 10 seconds
while ($stopwatch.Elapsed.TotalSeconds -lt 10) {
    ## Do some work here
    
    ## Wait for a specific interval
    Start-Sleep -Seconds 1
    
    ## Check the elapsed time and round to nearest second
    $totalSecs = [math]::Round($stopwatch.Elapsed.TotalSeconds, 0)
    
    ## Display elapsed time
    Write-Host "Elapsed: $totalSecs seconds"
}

# Stop the stopwatch when done
$stopwatch.Stop()
Write-Host "Timer completed!" -ForegroundColor Green