<#
.SYNOPSIS
    Monitor Disk Space
.DESCRIPTION
    This script monitors disk space on local or remote computers and provides alerts when space is low.
.EXAMPLE
    .\Monitor-DiskSpace.ps1
    .\Monitor-DiskSpace.ps1 -ComputerName "Server01" -ThresholdPercent 20
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$false)]
    [string[]]$ComputerName = @($env:COMPUTERNAME),
    
    [Parameter(Mandatory=$false)]
    [int]$ThresholdPercent = 15,
    
    [Parameter(Mandatory=$false)]
    [switch]$EmailAlert
)

function Get-DiskSpaceInfo {
    param($Computer, $Threshold)
    
    Write-Host "`nChecking disk space on $Computer..." -ForegroundColor Cyan
    
    try {
        $disks = Get-CimInstance -ComputerName $Computer -ClassName Win32_LogicalDisk -Filter "DriveType=3"
        
        $diskInfo = $disks | ForEach-Object {
            $percentFree = [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
            $sizeGB = [math]::Round($_.Size / 1GB, 2)
            $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
            $usedGB = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
            
            [PSCustomObject]@{
                ComputerName = $Computer
                Drive = $_.DeviceID
                Label = $_.VolumeName
                TotalSize_GB = $sizeGB
                UsedSpace_GB = $usedGB
                FreeSpace_GB = $freeGB
                PercentFree = $percentFree
                Status = if ($percentFree -lt $Threshold) { "LOW" } elseif ($percentFree -lt 30) { "WARNING" } else { "OK" }
            }
        }
        
        # Display results with color coding
        foreach ($disk in $diskInfo) {
            $color = switch ($disk.Status) {
                "LOW" { "Red" }
                "WARNING" { "Yellow" }
                "OK" { "Green" }
            }
            
            Write-Host "`n$($disk.Drive) - $($disk.Label)" -ForegroundColor White
            Write-Host "  Total: $($disk.TotalSize_GB) GB" -ForegroundColor White
            Write-Host "  Used:  $($disk.UsedSpace_GB) GB" -ForegroundColor White
            Write-Host "  Free:  $($disk.FreeSpace_GB) GB ($($disk.PercentFree)%)" -ForegroundColor White
            Write-Host "  Status: $($disk.Status)" -ForegroundColor $color
        }
        
        # Show summary
        $lowDisks = $diskInfo | Where-Object { $_.Status -eq "LOW" }
        $warningDisks = $diskInfo | Where-Object { $_.Status -eq "WARNING" }
        
        Write-Host "`nSummary:" -ForegroundColor Cyan
        Write-Host "  Total Disks: $($diskInfo.Count)"
        Write-Host "  OK: $(($diskInfo | Where-Object { $_.Status -eq 'OK' }).Count)" -ForegroundColor Green
        Write-Host "  Warning: $($warningDisks.Count)" -ForegroundColor Yellow
        Write-Host "  Low: $($lowDisks.Count)" -ForegroundColor Red
        
        return $diskInfo
    }
    catch {
        Write-Error "Failed to get disk information from $Computer: $_"
        return $null
    }
}

function Send-DiskSpaceAlert {
    param($DiskData)
    
    $lowDisks = $DiskData | Where-Object { $_.Status -eq "LOW" }
    
    if ($lowDisks.Count -eq 0) {
        Write-Host "`nNo disks with low space detected." -ForegroundColor Green
        return
    }
    
    Write-Host "`nALERT: Low disk space detected on the following:" -ForegroundColor Red
    $lowDisks | Format-Table ComputerName, Drive, FreeSpace_GB, PercentFree, Status -AutoSize
    
    # In a production environment, you would send an email here
    Write-Host "`nEmail alert would be sent here in production." -ForegroundColor Yellow
    Write-Host "Configure email settings in the script to enable email alerts." -ForegroundColor Yellow
}

# Main execution
Write-Host "Disk Space Monitor" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "Threshold: $ThresholdPercent%" -ForegroundColor White

$allDiskInfo = @()

foreach ($computer in $ComputerName) {
    $diskInfo = Get-DiskSpaceInfo -Computer $computer -Threshold $ThresholdPercent
    if ($diskInfo) {
        $allDiskInfo += $diskInfo
    }
}

# Check for alerts
if ($EmailAlert -and $allDiskInfo.Count -gt 0) {
    Send-DiskSpaceAlert -DiskData $allDiskInfo
}

# Export to CSV option
Write-Host "`nWould you like to export results to CSV? (Y/N): " -ForegroundColor Cyan -NoNewline
$exportChoice = Read-Host

if ($exportChoice -eq "Y" -or $exportChoice -eq "y") {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $exportPath = "DiskSpace_Report_$timestamp.csv"
    $allDiskInfo | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "Results exported to: $exportPath" -ForegroundColor Green
}
