<#
.SYNOPSIS
    Enhanced Start-Sleep function with visual progress bar.

.DESCRIPTION
    This function overrides the built-in Start-Sleep cmdlet to provide a visual
    progress bar during sleep/wait operations. Shows countdown timer and percentage
    completion, making it easier to track long-running delays.

.PARAMETER seconds
    The number of seconds to sleep/wait.

.OUTPUTS
    None. Displays a progress bar while sleeping.

.EXAMPLE
    Start-Sleep 30
    Sleeps for 30 seconds with a visual progress bar.

.EXAMPLE
    Start-Sleep 120
    Sleeps for 2 minutes with countdown progress indicator.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Note: This overrides the built-in Start-Sleep cmdlet when loaded.
    
.LINK
    Write-Progress
    Start-Sleep
#>
function Start-Sleep($seconds) {
    # Calculate the target completion time
    $doneDT = (Get-Date).AddSeconds($seconds)
    
    # Loop until the target time is reached
    while($doneDT -gt (Get-Date)) {
        # Calculate remaining seconds
        $secondsLeft = $doneDT.Subtract((Get-Date)).TotalSeconds
        
        # Calculate completion percentage
        $percent = ($seconds - $secondsLeft) / $seconds * 100
        
        # Display progress bar with countdown
        Write-Progress -Activity "Countdown" -Status "Sleeping..." -SecondsRemaining $secondsLeft -PercentComplete $percent
        
        # Sleep for 500ms between updates
        [System.Threading.Thread]::Sleep(500)
    }
    
    # Clear the progress bar when complete
    Write-Progress -Activity "Sleeping" -Status "Sleeping..." -SecondsRemaining 0 -Completed
}