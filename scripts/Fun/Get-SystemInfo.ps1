<#
.SYNOPSIS
    Display System Information
.DESCRIPTION
    This script displays comprehensive system information in a colorful and organized format.
.EXAMPLE
    .\Get-SystemInfo.ps1
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Detailed
)

function Show-Banner {
    $banner = @"
 
 ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗
 ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║
 ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║
 ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║
 ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║
 ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝
           ██╗███╗   ██╗███████╗ ██████╗             
           ██║████╗  ██║██╔════╝██╔═══██╗            
           ██║██╔██╗ ██║█████╗  ██║   ██║            
           ██║██║╚██╗██║██╔══╝  ██║   ██║            
           ██║██║ ╚████║██║     ╚██████╔╝            
           ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝             
 
"@
    Write-Host $banner -ForegroundColor Cyan
}

function Get-ComputerInfo {
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              COMPUTER INFORMATION                        ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    
    Write-Host "  Computer Name:     " -NoNewline -ForegroundColor Yellow
    Write-Host $env:COMPUTERNAME -ForegroundColor White
    
    Write-Host "  Domain:            " -NoNewline -ForegroundColor Yellow
    Write-Host $cs.Domain -ForegroundColor White
    
    Write-Host "  Manufacturer:      " -NoNewline -ForegroundColor Yellow
    Write-Host $cs.Manufacturer -ForegroundColor White
    
    Write-Host "  Model:             " -NoNewline -ForegroundColor Yellow
    Write-Host $cs.Model -ForegroundColor White
    
    Write-Host "  Total RAM:         " -NoNewline -ForegroundColor Yellow
    Write-Host "$([math]::Round($cs.TotalPhysicalMemory / 1GB, 2)) GB" -ForegroundColor White
    
    Write-Host ""
}

function Get-OSInfo {
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              OPERATING SYSTEM                            ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    
    Write-Host "  OS Name:           " -NoNewline -ForegroundColor Yellow
    Write-Host $os.Caption -ForegroundColor White
    
    Write-Host "  Version:           " -NoNewline -ForegroundColor Yellow
    Write-Host $os.Version -ForegroundColor White
    
    Write-Host "  Architecture:      " -NoNewline -ForegroundColor Yellow
    Write-Host $os.OSArchitecture -ForegroundColor White
    
    Write-Host "  Install Date:      " -NoNewline -ForegroundColor Yellow
    Write-Host $os.InstallDate -ForegroundColor White
    
    Write-Host "  Last Boot:         " -NoNewline -ForegroundColor Yellow
    Write-Host $os.LastBootUpTime -ForegroundColor White
    
    $uptime = (Get-Date) - $os.LastBootUpTime
    Write-Host "  Uptime:            " -NoNewline -ForegroundColor Yellow
    Write-Host "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes" -ForegroundColor White
    
    Write-Host ""
}

function Get-CPUInfo {
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              PROCESSOR                                   ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    $cpu = Get-CimInstance -ClassName Win32_Processor
    
    Write-Host "  Name:              " -NoNewline -ForegroundColor Yellow
    Write-Host $cpu.Name -ForegroundColor White
    
    Write-Host "  Cores:             " -NoNewline -ForegroundColor Yellow
    Write-Host $cpu.NumberOfCores -ForegroundColor White
    
    Write-Host "  Logical Processors:" -NoNewline -ForegroundColor Yellow
    Write-Host $cpu.NumberOfLogicalProcessors -ForegroundColor White
    
    Write-Host "  Max Speed:         " -NoNewline -ForegroundColor Yellow
    Write-Host "$($cpu.MaxClockSpeed) MHz" -ForegroundColor White
    
    Write-Host ""
}

function Get-DiskInfo {
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              DISK INFORMATION                            ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    
    foreach ($disk in $disks) {
        $percentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
        $color = if ($percentFree -lt 15) { "Red" } elseif ($percentFree -lt 30) { "Yellow" } else { "Green" }
        
        Write-Host "  Drive $($disk.DeviceID)" -ForegroundColor Cyan
        Write-Host "    Label:           " -NoNewline -ForegroundColor Yellow
        Write-Host $disk.VolumeName -ForegroundColor White
        
        Write-Host "    Total Size:      " -NoNewline -ForegroundColor Yellow
        Write-Host "$([math]::Round($disk.Size / 1GB, 2)) GB" -ForegroundColor White
        
        Write-Host "    Free Space:      " -NoNewline -ForegroundColor Yellow
        Write-Host "$([math]::Round($disk.FreeSpace / 1GB, 2)) GB" -ForegroundColor $color
        
        Write-Host "    Percent Free:    " -NoNewline -ForegroundColor Yellow
        Write-Host "$percentFree%" -ForegroundColor $color
        
        Write-Host ""
    }
}

function Get-NetworkInfo {
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              NETWORK ADAPTERS                            ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    foreach ($adapter in $adapters) {
        Write-Host "  $($adapter.Name)" -ForegroundColor Cyan
        Write-Host "    Status:          " -NoNewline -ForegroundColor Yellow
        Write-Host $adapter.Status -ForegroundColor Green
        
        Write-Host "    Link Speed:      " -NoNewline -ForegroundColor Yellow
        Write-Host $adapter.LinkSpeed -ForegroundColor White
        
        Write-Host "    MAC Address:     " -NoNewline -ForegroundColor Yellow
        Write-Host $adapter.MacAddress -ForegroundColor White
        
        # Get IP configuration
        $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($ipConfig) {
            Write-Host "    IP Address:      " -NoNewline -ForegroundColor Yellow
            Write-Host $ipConfig.IPAddress -ForegroundColor White
        }
        
        Write-Host ""
    }
}

function Get-DetailedInfo {
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              ADDITIONAL DETAILS                          ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    # PowerShell version
    Write-Host "  PowerShell:        " -NoNewline -ForegroundColor Yellow
    Write-Host $PSVersionTable.PSVersion -ForegroundColor White
    
    # .NET version
    Write-Host "  .NET CLR:          " -NoNewline -ForegroundColor Yellow
    Write-Host $PSVersionTable.CLRVersion -ForegroundColor White
    
    # Current user
    Write-Host "  Current User:      " -NoNewline -ForegroundColor Yellow
    Write-Host "$env:USERDOMAIN\$env:USERNAME" -ForegroundColor White
    
    # Windows Defender status
    try {
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defender) {
            Write-Host "  Antivirus:         " -NoNewline -ForegroundColor Yellow
            $avStatus = if ($defender.RealTimeProtectionEnabled) { "Enabled" } else { "Disabled" }
            $avColor = if ($defender.RealTimeProtectionEnabled) { "Green" } else { "Red" }
            Write-Host "Windows Defender ($avStatus)" -ForegroundColor $avColor
        }
    }
    catch {
        # Defender cmdlet not available
    }
    
    Write-Host ""
}

# Main execution
Clear-Host
Show-Banner

Get-ComputerInfo
Get-OSInfo
Get-CPUInfo
Get-DiskInfo
Get-NetworkInfo

if ($Detailed) {
    Get-DetailedInfo
}

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              END OF REPORT                               ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
