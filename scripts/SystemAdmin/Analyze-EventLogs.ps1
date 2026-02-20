<#
.SYNOPSIS
    Analyze Windows Event Logs
.DESCRIPTION
    This script provides functions to search and analyze Windows Event Logs for errors, warnings, and specific events.
.EXAMPLE
    .\Analyze-EventLogs.ps1 -Action Errors -Hours 24
    .\Analyze-EventLogs.ps1 -Action Search -LogName "System" -EventID 1074
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Errors","Warnings","Search","Summary","ApplicationErrors","SystemErrors")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$ComputerName = $env:COMPUTERNAME,
    
    [Parameter(Mandatory=$false)]
    [string]$LogName = "Application",
    
    [Parameter(Mandatory=$false)]
    [int]$EventID,
    
    [Parameter(Mandatory=$false)]
    [int]$Hours = 24,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxEvents = 100
)

function Get-RecentErrors {
    param($Computer, $Hours, $MaxEvents)
    
    Write-Host "Retrieving errors from the last $Hours hours on $Computer..." -ForegroundColor Cyan
    
    try {
        $startTime = (Get-Date).AddHours(-$Hours)
        
        $errors = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
            LogName = 'Application', 'System'
            Level = 2  # Error
            StartTime = $startTime
        } -MaxEvents $MaxEvents -ErrorAction Stop
        
        if ($errors.Count -eq 0) {
            Write-Host "No errors found in the specified time period." -ForegroundColor Green
            return
        }
        
        Write-Host "`nRecent Errors (showing up to $MaxEvents):" -ForegroundColor Yellow
        
        $groupedErrors = $errors | Group-Object -Property Id | Sort-Object Count -Descending
        
        Write-Host "`nError Summary by Event ID:" -ForegroundColor Cyan
        $groupedErrors | Select-Object Count, Name, @{Name="Source";Expression={$_.Group[0].ProviderName}} | Format-Table -AutoSize
        
        Write-Host "`nDetailed Error Log:" -ForegroundColor Cyan
        $errors | Select-Object TimeCreated, Id, ProviderName, Message | Format-Table -AutoSize -Wrap
        
        Write-Host "`nTotal Errors: $($errors.Count)" -ForegroundColor Red
    }
    catch {
        Write-Error "Failed to retrieve errors: $_"
    }
}

function Get-RecentWarnings {
    param($Computer, $Hours, $MaxEvents)
    
    Write-Host "Retrieving warnings from the last $Hours hours on $Computer..." -ForegroundColor Cyan
    
    try {
        $startTime = (Get-Date).AddHours(-$Hours)
        
        $warnings = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
            LogName = 'Application', 'System'
            Level = 3  # Warning
            StartTime = $startTime
        } -MaxEvents $MaxEvents -ErrorAction Stop
        
        if ($warnings.Count -eq 0) {
            Write-Host "No warnings found in the specified time period." -ForegroundColor Green
            return
        }
        
        Write-Host "`nRecent Warnings (showing up to $MaxEvents):" -ForegroundColor Yellow
        
        $groupedWarnings = $warnings | Group-Object -Property Id | Sort-Object Count -Descending
        
        Write-Host "`nWarning Summary by Event ID:" -ForegroundColor Cyan
        $groupedWarnings | Select-Object Count, Name, @{Name="Source";Expression={$_.Group[0].ProviderName}} | Format-Table -AutoSize
        
        Write-Host "`nDetailed Warning Log:" -ForegroundColor Cyan
        $warnings | Select-Object TimeCreated, Id, ProviderName, Message | Format-Table -AutoSize -Wrap
        
        Write-Host "`nTotal Warnings: $($warnings.Count)" -ForegroundColor Yellow
    }
    catch {
        Write-Error "Failed to retrieve warnings: $_"
    }
}

function Search-EventLog {
    param($Computer, $LogName, $EventID, $Hours, $MaxEvents)
    
    if (-not $EventID) {
        Write-Error "EventID is required for Search action."
        return
    }
    
    Write-Host "Searching for Event ID $EventID in '$LogName' log on $Computer..." -ForegroundColor Cyan
    
    try {
        $startTime = (Get-Date).AddHours(-$Hours)
        
        $events = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
            LogName = $LogName
            Id = $EventID
            StartTime = $startTime
        } -MaxEvents $MaxEvents -ErrorAction Stop
        
        if ($events.Count -eq 0) {
            Write-Host "No events found with Event ID $EventID in the specified time period." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`nFound Events (showing up to $MaxEvents):" -ForegroundColor Green
        $events | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message | Format-List
        
        Write-Host "`nTotal Events Found: $($events.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to search event log: $_"
    }
}

function Get-EventLogSummary {
    param($Computer, $Hours)
    
    Write-Host "Generating event log summary for the last $Hours hours on $Computer..." -ForegroundColor Cyan
    
    try {
        $startTime = (Get-Date).AddHours(-$Hours)
        
        # Get all events
        $appEvents = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
            LogName = 'Application'
            StartTime = $startTime
        } -MaxEvents 10000 -ErrorAction SilentlyContinue
        
        $sysEvents = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
            LogName = 'System'
            StartTime = $startTime
        } -MaxEvents 10000 -ErrorAction SilentlyContinue
        
        $allEvents = $appEvents + $sysEvents
        
        Write-Host "`nEvent Log Summary:" -ForegroundColor Yellow
        Write-Host "Time Period: Last $Hours hours"
        Write-Host ""
        
        # Count by level
        $errors = ($allEvents | Where-Object { $_.Level -eq 2 }).Count
        $warnings = ($allEvents | Where-Object { $_.Level -eq 3 }).Count
        $info = ($allEvents | Where-Object { $_.Level -eq 4 }).Count
        
        Write-Host "By Severity:" -ForegroundColor Cyan
        Write-Host "  Errors: $errors" -ForegroundColor Red
        Write-Host "  Warnings: $warnings" -ForegroundColor Yellow
        Write-Host "  Informational: $info" -ForegroundColor Green
        Write-Host "  Total: $($allEvents.Count)"
        
        # Top error sources
        if ($errors -gt 0) {
            Write-Host "`nTop Error Sources:" -ForegroundColor Cyan
            $allEvents | Where-Object { $_.Level -eq 2 } | 
                Group-Object -Property ProviderName | 
                Sort-Object Count -Descending | 
                Select-Object -First 10 Count, Name | 
                Format-Table -AutoSize
        }
        
        # Top warning sources
        if ($warnings -gt 0) {
            Write-Host "`nTop Warning Sources:" -ForegroundColor Cyan
            $allEvents | Where-Object { $_.Level -eq 3 } | 
                Group-Object -Property ProviderName | 
                Sort-Object Count -Descending | 
                Select-Object -First 10 Count, Name | 
                Format-Table -AutoSize
        }
    }
    catch {
        Write-Error "Failed to generate summary: $_"
    }
}

function Get-ApplicationErrors {
    param($Computer, $Hours, $MaxEvents)
    
    Write-Host "Retrieving Application errors from the last $Hours hours on $Computer..." -ForegroundColor Cyan
    
    try {
        $startTime = (Get-Date).AddHours(-$Hours)
        
        $errors = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
            LogName = 'Application'
            Level = 2
            StartTime = $startTime
        } -MaxEvents $MaxEvents -ErrorAction Stop
        
        if ($errors.Count -eq 0) {
            Write-Host "No application errors found." -ForegroundColor Green
            return
        }
        
        Write-Host "`nApplication Errors:" -ForegroundColor Yellow
        $errors | Select-Object TimeCreated, Id, ProviderName, Message | Format-Table -AutoSize -Wrap
        
        Write-Host "`nTotal Application Errors: $($errors.Count)" -ForegroundColor Red
    }
    catch {
        Write-Error "Failed to retrieve application errors: $_"
    }
}

function Get-SystemErrors {
    param($Computer, $Hours, $MaxEvents)
    
    Write-Host "Retrieving System errors from the last $Hours hours on $Computer..." -ForegroundColor Cyan
    
    try {
        $startTime = (Get-Date).AddHours(-$Hours)
        
        $errors = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
            LogName = 'System'
            Level = 2
            StartTime = $startTime
        } -MaxEvents $MaxEvents -ErrorAction Stop
        
        if ($errors.Count -eq 0) {
            Write-Host "No system errors found." -ForegroundColor Green
            return
        }
        
        Write-Host "`nSystem Errors:" -ForegroundColor Yellow
        $errors | Select-Object TimeCreated, Id, ProviderName, Message | Format-Table -AutoSize -Wrap
        
        Write-Host "`nTotal System Errors: $($errors.Count)" -ForegroundColor Red
    }
    catch {
        Write-Error "Failed to retrieve system errors: $_"
    }
}

# Main execution
switch ($Action) {
    "Errors" { Get-RecentErrors -Computer $ComputerName -Hours $Hours -MaxEvents $MaxEvents }
    "Warnings" { Get-RecentWarnings -Computer $ComputerName -Hours $Hours -MaxEvents $MaxEvents }
    "Search" { Search-EventLog -Computer $ComputerName -LogName $LogName -EventID $EventID -Hours $Hours -MaxEvents $MaxEvents }
    "Summary" { Get-EventLogSummary -Computer $ComputerName -Hours $Hours }
    "ApplicationErrors" { Get-ApplicationErrors -Computer $ComputerName -Hours $Hours -MaxEvents $MaxEvents }
    "SystemErrors" { Get-SystemErrors -Computer $ComputerName -Hours $Hours -MaxEvents $MaxEvents }
}
