<#
.SYNOPSIS
    Monitors system performance metrics in real-time.

.DESCRIPTION
    This script monitors key performance indicators including:
    - CPU usage
    - Memory usage
    - Disk I/O
    - Network utilization
    - Running processes
    - System uptime
    
    It can display continuous monitoring or save results to a log file.

.PARAMETER Interval
    Refresh interval in seconds (default: 5 seconds).

.PARAMETER Duration
    Duration to monitor in minutes (default: continuous until Ctrl+C).

.PARAMETER LogToFile
    Save monitoring data to a CSV file.

.PARAMETER TopProcesses
    Number of top processes to display by CPU usage (default: 10).

.PARAMETER ComputerName
    Remote computer name to monitor (default: local computer).

.EXAMPLE
    .\Monitor-Performance.ps1
    Continuously monitors local system performance with 5-second intervals.

.EXAMPLE
    .\Monitor-Performance.ps1 -Interval 10 -Duration 30
    Monitors for 30 minutes with 10-second refresh intervals.

.EXAMPLE
    .\Monitor-Performance.ps1 -LogToFile -TopProcesses 5
    Monitors and logs to CSV, showing top 5 processes.

.EXAMPLE
    .\Monitor-Performance.ps1 -ComputerName "Server01"
    Monitors remote computer Server01.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    
    Use Ctrl+C to stop continuous monitoring.
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Interval = 5,
    
    [Parameter(Mandatory=$false)]
    [int]$Duration = 0,  # 0 means continuous
    
    [Parameter(Mandatory=$false)]
    [switch]$LogToFile,
    
    [Parameter(Mandatory=$false)]
    [int]$TopProcesses = 10,
    
    [Parameter(Mandatory=$false)]
    [string]$ComputerName = $env:COMPUTERNAME
)

# Initialize log file if logging is enabled
$logPath = $null
if ($LogToFile) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logPath = "Performance_Monitor_${ComputerName}_${timestamp}.csv"
    Write-Host "Logging to: $logPath" -ForegroundColor Green
}

function Get-PerformanceMetrics {
    param($Computer)
    
    try {
        # Get CPU usage
        $cpuUsage = (Get-CimInstance -ComputerName $Computer -ClassName Win32_Processor -ErrorAction Stop | 
                     Measure-Object -Property LoadPercentage -Average).Average
        
        # Get memory usage
        $os = Get-CimInstance -ComputerName $Computer -ClassName Win32_OperatingSystem -ErrorAction Stop
        $totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedMemoryGB = [math]::Round($totalMemoryGB - $freeMemoryGB, 2)
        $memoryPercent = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 2)
        
        # Get disk usage for C: drive
        $disk = Get-CimInstance -ComputerName $Computer -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
        $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
        
        # Get network adapters
        $netAdapters = Get-CimInstance -ComputerName $Computer -ClassName Win32_PerfFormattedData_Tcpip_NetworkInterface -ErrorAction SilentlyContinue |
                       Where-Object { $_.BytesTotalPersec -gt 0 }
        
        $netBytesTotal = 0
        if ($netAdapters) {
            $netBytesTotal = ($netAdapters | Measure-Object -Property BytesTotalPersec -Sum).Sum
        }
        $netMBps = [math]::Round($netBytesTotal / 1MB, 2)
        
        # Return metrics object
        return [PSCustomObject]@{
            Timestamp = Get-Date
            Computer = $Computer
            CPUPercent = $cpuUsage
            MemoryUsedGB = $usedMemoryGB
            MemoryTotalGB = $totalMemoryGB
            MemoryPercent = $memoryPercent
            DiskFreePercent = $diskFreePercent
            NetworkMBps = $netMBps
        }
    }
    catch {
        Write-Error "Failed to get performance metrics: $_"
        return $null
    }
}

function Get-TopProcessesByCPU {
    param($Computer, $Count)
    
    try {
        if ($Computer -eq $env:COMPUTERNAME) {
            # Local computer
            $processes = Get-Process | 
                        Where-Object { $_.CPU -gt 0 } |
                        Sort-Object -Property CPU -Descending |
                        Select-Object -First $Count
        }
        else {
            # Remote computer
            $processes = Invoke-Command -ComputerName $Computer -ScriptBlock {
                Get-Process | 
                Where-Object { $_.CPU -gt 0 } |
                Sort-Object -Property CPU -Descending |
                Select-Object -First $using:Count ProcessName, Id, CPU, WorkingSet
            } -ErrorAction Stop
        }
        
        return $processes
    }
    catch {
        Write-Warning "Could not get process information: $_"
        return $null
    }
}

function Show-PerformanceDisplay {
    param($Metrics, $Processes)
    
    # Clear screen for clean display
    Clear-Host
    
    # Header
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          PERFORMANCE MONITOR                             ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Computer: $($Metrics.Computer)" -ForegroundColor Cyan
    Write-Host "  Time: $($Metrics.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    Write-Host ""
    
    # CPU
    $cpuColor = if ($Metrics.CPUPercent -gt 80) { "Red" } elseif ($Metrics.CPUPercent -gt 60) { "Yellow" } else { "Green" }
    Write-Host "  CPU Usage:     " -NoNewline -ForegroundColor White
    Write-Host "$($Metrics.CPUPercent)%" -ForegroundColor $cpuColor
    Write-Host "  $(Get-PerformanceBar -Percent $Metrics.CPUPercent)" -ForegroundColor $cpuColor
    
    # Memory
    $memColor = if ($Metrics.MemoryPercent -gt 90) { "Red" } elseif ($Metrics.MemoryPercent -gt 75) { "Yellow" } else { "Green" }
    Write-Host ""
    Write-Host "  Memory Usage:  " -NoNewline -ForegroundColor White
    Write-Host "$($Metrics.MemoryUsedGB) GB / $($Metrics.MemoryTotalGB) GB ($($Metrics.MemoryPercent)%)" -ForegroundColor $memColor
    Write-Host "  $(Get-PerformanceBar -Percent $Metrics.MemoryPercent)" -ForegroundColor $memColor
    
    # Disk
    $diskColor = if ($Metrics.DiskFreePercent -lt 15) { "Red" } elseif ($Metrics.DiskFreePercent -lt 30) { "Yellow" } else { "Green" }
    Write-Host ""
    Write-Host "  Disk Free (C:):" -NoNewline -ForegroundColor White
    Write-Host " $($Metrics.DiskFreePercent)%" -ForegroundColor $diskColor
    
    # Network
    Write-Host ""
    Write-Host "  Network:       " -NoNewline -ForegroundColor White
    Write-Host "$($Metrics.NetworkMBps) MB/s" -ForegroundColor Cyan
    
    # Top Processes
    if ($Processes) {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║          TOP PROCESSES BY CPU                            ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        
        $Processes | ForEach-Object {
            $cpuTime = if ($_.CPU) { [math]::Round($_.CPU, 2) } else { 0 }
            $memMB = if ($_.WorkingSet) { [math]::Round($_.WorkingSet / 1MB, 0) } else { 0 }
            Write-Host "  $($_.ProcessName.PadRight(25)) " -NoNewline -ForegroundColor White
            Write-Host "CPU: $($cpuTime.ToString().PadLeft(8))s  " -NoNewline -ForegroundColor Yellow
            Write-Host "Mem: $($memMB.ToString().PadLeft(6)) MB" -ForegroundColor Cyan
        }
    }
    
    Write-Host ""
    Write-Host "Press Ctrl+C to stop monitoring..." -ForegroundColor DarkGray
}

function Get-PerformanceBar {
    param($Percent)
    
    $barLength = 40
    $filledLength = [math]::Round(($Percent / 100) * $barLength)
    $bar = "█" * $filledLength + "░" * ($barLength - $filledLength)
    return "[$bar] "
}

# Main execution loop
Write-Host ""
Write-Host "Starting performance monitoring..." -ForegroundColor Green
Write-Host "Computer: $ComputerName" -ForegroundColor Cyan
Write-Host "Interval: $Interval seconds" -ForegroundColor Cyan
if ($Duration -gt 0) {
    Write-Host "Duration: $Duration minutes" -ForegroundColor Cyan
}
else {
    Write-Host "Duration: Continuous (press Ctrl+C to stop)" -ForegroundColor Cyan
}
Write-Host ""
Start-Sleep -Seconds 2

$startTime = Get-Date
$iteration = 0

try {
    while ($true) {
        $iteration++
        
        # Get metrics
        $metrics = Get-PerformanceMetrics -Computer $ComputerName
        
        if ($metrics) {
            # Get top processes
            $topProcs = Get-TopProcessesByCPU -Computer $ComputerName -Count $TopProcesses
            
            # Display
            Show-PerformanceDisplay -Metrics $metrics -Processes $topProcs
            
            # Log to file if enabled
            if ($LogToFile -and $logPath) {
                $metrics | Export-Csv -Path $logPath -NoTypeInformation -Append
            }
        }
        
        # Check duration
        if ($Duration -gt 0) {
            $elapsedMinutes = ((Get-Date) - $startTime).TotalMinutes
            if ($elapsedMinutes -ge $Duration) {
                Write-Host ""
                Write-Host "Monitoring duration completed." -ForegroundColor Green
                break
            }
        }
        
        # Wait for next interval
        Start-Sleep -Seconds $Interval
    }
}
catch {
    Write-Host ""
    Write-Host "Monitoring stopped." -ForegroundColor Yellow
}

# Final message
Write-Host ""
Write-Host "Performance monitoring completed." -ForegroundColor Green
if ($LogToFile -and $logPath) {
    Write-Host "Log saved to: $logPath" -ForegroundColor Green
}
Write-Host ""
