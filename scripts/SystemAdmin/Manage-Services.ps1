<#
.SYNOPSIS
    Manage Windows Services
.DESCRIPTION
    This script provides functions to list, start, stop, restart, and configure Windows services.
.EXAMPLE
    .\Manage-Services.ps1 -Action List
    .\Manage-Services.ps1 -Action Start -ServiceName "Spooler"
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("List","Info","Start","Stop","Restart","SetStartup","ListStopped")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$false)]
    [string]$ComputerName = $env:COMPUTERNAME,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Automatic","Manual","Disabled")]
    [string]$StartupType
)

function Get-ServiceList {
    param($Computer)
    
    Write-Host "Retrieving all services on $Computer..." -ForegroundColor Cyan
    
    try {
        $services = Get-Service -ComputerName $Computer | Sort-Object DisplayName
        
        Write-Host "`nServices Summary:" -ForegroundColor Yellow
        $running = ($services | Where-Object { $_.Status -eq "Running" }).Count
        $stopped = ($services | Where-Object { $_.Status -eq "Stopped" }).Count
        
        Write-Host "  Total Services: $($services.Count)"
        Write-Host "  Running: $running" -ForegroundColor Green
        Write-Host "  Stopped: $stopped" -ForegroundColor Red
        
        # Display all services
        Write-Host "`nAll Services:" -ForegroundColor Cyan
        $services | Format-Table Name, DisplayName, Status, StartType -AutoSize
    }
    catch {
        Write-Error "Failed to retrieve services: $_"
    }
}

function Get-ServiceInfo {
    param($Computer, $Name)
    
    if (-not $Name) {
        Write-Error "ServiceName is required for Info action."
        return
    }
    
    Write-Host "Getting information for service '$Name' on $Computer..." -ForegroundColor Cyan
    
    try {
        $service = Get-Service -Name $Name -ComputerName $Computer -ErrorAction Stop
        $serviceWMI = Get-CimInstance -ClassName Win32_Service -Filter "Name='$Name'" -ComputerName $Computer
        
        Write-Host "`nService Details:" -ForegroundColor Yellow
        Write-Host "  Name: $($service.Name)"
        Write-Host "  Display Name: $($service.DisplayName)"
        Write-Host "  Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Red" })
        Write-Host "  Start Type: $($service.StartType)"
        Write-Host "  Can Stop: $($service.CanStop)"
        Write-Host "  Can Pause: $($service.CanPauseAndContinue)"
        
        if ($serviceWMI) {
            Write-Host "  Path to Executable: $($serviceWMI.PathName)"
            Write-Host "  Start Name: $($serviceWMI.StartName)"
            Write-Host "  Process ID: $($serviceWMI.ProcessId)"
        }
        
        # Show dependent services
        $dependents = $service.DependentServices
        if ($dependents.Count -gt 0) {
            Write-Host "`nDependent Services:" -ForegroundColor Yellow
            $dependents | Format-Table Name, DisplayName, Status -AutoSize
        }
        
        # Show required services
        $required = $service.RequiredServices
        if ($required.Count -gt 0) {
            Write-Host "`nRequired Services:" -ForegroundColor Yellow
            $required | Format-Table Name, DisplayName, Status -AutoSize
        }
    }
    catch {
        Write-Error "Failed to get service info: $_"
    }
}

function Start-ServiceAction {
    param($Computer, $Name)
    
    if (-not $Name) {
        Write-Error "ServiceName is required for Start action."
        return
    }
    
    Write-Host "Starting service '$Name' on $Computer..." -ForegroundColor Cyan
    
    try {
        Start-Service -Name $Name -ErrorAction Stop
        Write-Host "Service started successfully!" -ForegroundColor Green
        
        # Wait a moment and check status
        Start-Sleep -Seconds 2
        $service = Get-Service -Name $Name
        Write-Host "Current Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Yellow" })
    }
    catch {
        Write-Error "Failed to start service: $_"
    }
}

function Stop-ServiceAction {
    param($Computer, $Name)
    
    if (-not $Name) {
        Write-Error "ServiceName is required for Stop action."
        return
    }
    
    Write-Host "Stopping service '$Name' on $Computer..." -ForegroundColor Cyan
    
    try {
        # Check for dependent services
        $service = Get-Service -Name $Name
        $dependents = $service.DependentServices | Where-Object { $_.Status -eq "Running" }
        
        if ($dependents.Count -gt 0) {
            Write-Host "WARNING: The following services depend on '$Name' and are running:" -ForegroundColor Yellow
            $dependents | Format-Table Name, DisplayName -AutoSize
            
            $confirm = Read-Host "Stop dependent services? (Y/N)"
            if ($confirm -ne "Y" -and $confirm -ne "y") {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
                return
            }
            
            # Stop dependent services first
            foreach ($dep in $dependents) {
                Write-Host "Stopping dependent service: $($dep.Name)..." -ForegroundColor Yellow
                Stop-Service -Name $dep.Name -Force
            }
        }
        
        Stop-Service -Name $Name -Force -ErrorAction Stop
        Write-Host "Service stopped successfully!" -ForegroundColor Green
        
        # Wait a moment and check status
        Start-Sleep -Seconds 2
        $service = Get-Service -Name $Name
        Write-Host "Current Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Stopped") { "Green" } else { "Yellow" })
    }
    catch {
        Write-Error "Failed to stop service: $_"
    }
}

function Restart-ServiceAction {
    param($Computer, $Name)
    
    if (-not $Name) {
        Write-Error "ServiceName is required for Restart action."
        return
    }
    
    Write-Host "Restarting service '$Name' on $Computer..." -ForegroundColor Cyan
    
    try {
        Restart-Service -Name $Name -Force -ErrorAction Stop
        Write-Host "Service restarted successfully!" -ForegroundColor Green
        
        # Wait a moment and check status
        Start-Sleep -Seconds 2
        $service = Get-Service -Name $Name
        Write-Host "Current Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Yellow" })
    }
    catch {
        Write-Error "Failed to restart service: $_"
    }
}

function Set-ServiceStartupType {
    param($Computer, $Name, $Type)
    
    if (-not $Name -or -not $Type) {
        Write-Error "ServiceName and StartupType are required for SetStartup action."
        return
    }
    
    Write-Host "Setting startup type for service '$Name' to '$Type'..." -ForegroundColor Cyan
    
    try {
        Set-Service -Name $Name -StartupType $Type -ErrorAction Stop
        Write-Host "Startup type changed successfully!" -ForegroundColor Green
        
        $service = Get-Service -Name $Name
        Write-Host "Current Startup Type: $($service.StartType)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set startup type: $_"
    }
}

function Get-StoppedServiceList {
    param($Computer)
    
    Write-Host "Retrieving stopped services on $Computer..." -ForegroundColor Cyan
    
    try {
        $services = Get-Service -ComputerName $Computer | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }
        
        if ($services.Count -eq 0) {
            Write-Host "No automatic services are currently stopped." -ForegroundColor Green
            return
        }
        
        Write-Host "`nAutomatic services that are stopped:" -ForegroundColor Yellow
        $services | Format-Table Name, DisplayName, Status, StartType -AutoSize
        
        Write-Host "`nTotal: $($services.Count)" -ForegroundColor Yellow
    }
    catch {
        Write-Error "Failed to retrieve stopped services: $_"
    }
}

# Main execution
switch ($Action) {
    "List" { Get-ServiceList -Computer $ComputerName }
    "Info" { Get-ServiceInfo -Computer $ComputerName -Name $ServiceName }
    "Start" { Start-ServiceAction -Computer $ComputerName -Name $ServiceName }
    "Stop" { Stop-ServiceAction -Computer $ComputerName -Name $ServiceName }
    "Restart" { Restart-ServiceAction -Computer $ComputerName -Name $ServiceName }
    "SetStartup" { Set-ServiceStartupType -Computer $ComputerName -Name $ServiceName -Type $StartupType }
    "ListStopped" { Get-StoppedServiceList -Computer $ComputerName }
}
