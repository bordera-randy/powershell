<#
.SYNOPSIS
    Performs cleanup operations to free up disk space on Windows servers and workstations.

.DESCRIPTION
    This script performs various cleanup operations to reclaim disk space:
    - Clears Windows Update cache
    - Empties Recycle Bin
    - Clears temporary files
    - Clears Windows Error Reporting files
    - Cleans IIS logs (if applicable)
    - Clears system and user temp directories
    - Shows before and after disk space comparison

.PARAMETER ClearWindowsUpdate
    Clear Windows Update download cache.

.PARAMETER ClearRecycleBin
    Empty the Recycle Bin for all drives.

.PARAMETER ClearTemp
    Clear temporary files from system and user temp directories.

.PARAMETER ClearIISLogs
    Clear IIS log files older than specified days.

.PARAMETER IISLogDays
    Number of days to keep IIS logs (default: 30 days).

.PARAMETER WhatIf
    Shows what would be cleaned without actually performing the cleanup.

.EXAMPLE
    .\Cleanup-DiskSpace.ps1
    Performs all cleanup operations with default settings.

.EXAMPLE
    .\Cleanup-DiskSpace.ps1 -ClearWindowsUpdate -ClearTemp
    Only clears Windows Update cache and temp files.

.EXAMPLE
    .\Cleanup-DiskSpace.ps1 -WhatIf
    Shows what would be cleaned without making changes.

.EXAMPLE
    .\Cleanup-DiskSpace.ps1 -ClearIISLogs -IISLogDays 7
    Clears IIS logs older than 7 days.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Requires: Administrator privileges
    
    CAUTION: This script deletes files. Use -WhatIf first to preview changes.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [switch]$ClearWindowsUpdate,
    
    [Parameter(Mandatory=$false)]
    [switch]$ClearRecycleBin,
    
    [Parameter(Mandatory=$false)]
    [switch]$ClearTemp,
    
    [Parameter(Mandatory=$false)]
    [switch]$ClearIISLogs,
    
    [Parameter(Mandatory=$false)]
    [int]$IISLogDays = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# Require administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script requires administrator privileges. Please run as Administrator."
    exit 1
}

# If no specific cleanup is selected, do all
$doAll = -not ($ClearWindowsUpdate -or $ClearRecycleBin -or $ClearTemp -or $ClearIISLogs)

function Get-DiskSpace {
    # Get disk space for C: drive
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    return [PSCustomObject]@{
        TotalGB = [math]::Round($disk.Size / 1GB, 2)
        FreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        UsedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
        PercentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
    }
}

function Clear-WindowsUpdateCache {
    Write-Host "`nClearing Windows Update cache..." -ForegroundColor Cyan
    
    # Stop Windows Update service
    $wuauserv = Get-Service -Name wuauserv
    if ($wuauserv.Status -eq 'Running') {
        Write-Host "  Stopping Windows Update service..." -ForegroundColor Yellow
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    
    # Clear download folder
    $updatePath = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $updatePath) {
        try {
            $itemCount = (Get-ChildItem -Path $updatePath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count
            if ($PSCmdlet.ShouldProcess("$updatePath ($itemCount items)", "Delete")) {
                Remove-Item -Path "$updatePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  Cleared Windows Update cache ($itemCount items)" -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "  Could not clear some Windows Update files: $_"
        }
    }
    
    # Restart service
    if ($wuauserv.Status -eq 'Stopped') {
        Write-Host "  Starting Windows Update service..." -ForegroundColor Yellow
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    }
}

function Clear-RecycleBinAll {
    Write-Host "`nEmptying Recycle Bin..." -ForegroundColor Cyan
    
    try {
        if ($PSCmdlet.ShouldProcess("All Recycle Bins", "Empty")) {
            # Get Recycle Bin size before clearing
            $shell = New-Object -ComObject Shell.Application
            $recycleBin = $shell.Namespace(0x0a)
            $size = ($recycleBin.Items() | Measure-Object -Property Size -Sum).Sum
            
            Clear-RecycleBin -Force -ErrorAction Stop
            Write-Host "  Recycle Bin emptied (freed $([math]::Round($size / 1MB, 2)) MB)" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "  Could not empty Recycle Bin: $_"
    }
}

function Clear-TempFiles {
    Write-Host "`nClearing temporary files..." -ForegroundColor Cyan
    
    # System temp directory
    $tempPaths = @(
        "C:\Windows\Temp",
        $env:TEMP,
        "C:\Windows\Prefetch"
    )
    
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            try {
                $itemCount = (Get-ChildItem -Path $path -File -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count
                if ($itemCount -gt 0) {
                    if ($PSCmdlet.ShouldProcess("$path ($itemCount items)", "Delete")) {
                        Get-ChildItem -Path $path -File -Recurse -Force -ErrorAction SilentlyContinue | 
                            Remove-Item -Force -ErrorAction SilentlyContinue
                        Write-Host "  Cleared $path ($itemCount items)" -ForegroundColor Green
                    }
                }
            }
            catch {
                Write-Warning "  Could not clear all files in $path : $_"
            }
        }
    }
    
    # Windows Error Reporting
    $werPath = "C:\ProgramData\Microsoft\Windows\WER"
    if (Test-Path $werPath) {
        try {
            if ($PSCmdlet.ShouldProcess("$werPath", "Delete error reports")) {
                Remove-Item -Path "$werPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  Cleared Windows Error Reporting files" -ForegroundColor Green
            }
        }
        catch {
            Write-Warning "  Could not clear Windows Error Reporting files: $_"
        }
    }
}

function Clear-IISLogFiles {
    param($Days)
    
    Write-Host "`nClearing IIS log files older than $Days days..." -ForegroundColor Cyan
    
    $iisLogPath = "C:\inetpub\logs\LogFiles"
    if (-not (Test-Path $iisLogPath)) {
        Write-Host "  IIS logs directory not found - skipping" -ForegroundColor Yellow
        return
    }
    
    $cutoffDate = (Get-Date).AddDays(-$Days)
    
    try {
        $oldLogs = Get-ChildItem -Path $iisLogPath -Recurse -File -ErrorAction SilentlyContinue | 
                   Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        if ($oldLogs) {
            $totalSize = ($oldLogs | Measure-Object -Property Length -Sum).Sum / 1MB
            if ($PSCmdlet.ShouldProcess("$($oldLogs.Count) IIS log files ($([math]::Round($totalSize, 2)) MB)", "Delete")) {
                $oldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Host "  Deleted $($oldLogs.Count) old IIS log files ($([math]::Round($totalSize, 2)) MB freed)" -ForegroundColor Green
            }
        }
        else {
            Write-Host "  No IIS logs older than $Days days found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning "  Could not clear IIS logs: $_"
    }
}

# Main execution
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          DISK SPACE CLEANUP UTILITY                      ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Get initial disk space
Write-Host "Getting initial disk space..." -ForegroundColor Cyan
$beforeSpace = Get-DiskSpace
Write-Host "  C:\ Drive Before Cleanup:" -ForegroundColor White
Write-Host "    Total: $($beforeSpace.TotalGB) GB" -ForegroundColor White
Write-Host "    Used:  $($beforeSpace.UsedGB) GB" -ForegroundColor White
Write-Host "    Free:  $($beforeSpace.FreeGB) GB ($($beforeSpace.PercentFree)%)" -ForegroundColor White

# Perform cleanup operations
if ($doAll -or $ClearWindowsUpdate) {
    Clear-WindowsUpdateCache
}

if ($doAll -or $ClearRecycleBin) {
    Clear-RecycleBinAll
}

if ($doAll -or $ClearTemp) {
    Clear-TempFiles
}

if ($ClearIISLogs) {
    Clear-IISLogFiles -Days $IISLogDays
}

# Get final disk space
Write-Host "`nGetting final disk space..." -ForegroundColor Cyan
Start-Sleep -Seconds 2  # Allow time for file system to update
$afterSpace = Get-DiskSpace
$freedSpace = [math]::Round($afterSpace.FreeGB - $beforeSpace.FreeGB, 2)

Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          CLEANUP SUMMARY                                 ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  C:\ Drive After Cleanup:" -ForegroundColor White
Write-Host "    Total: $($afterSpace.TotalGB) GB" -ForegroundColor White
Write-Host "    Used:  $($afterSpace.UsedGB) GB" -ForegroundColor White
Write-Host "    Free:  $($afterSpace.FreeGB) GB ($($afterSpace.PercentFree)%)" -ForegroundColor White
Write-Host ""
Write-Host "  Space Freed: $freedSpace GB" -ForegroundColor $(if ($freedSpace -gt 0) { "Green" } else { "Yellow" })
Write-Host ""
