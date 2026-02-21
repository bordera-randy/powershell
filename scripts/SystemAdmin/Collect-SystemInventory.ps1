<#
.SYNOPSIS
    Collects system inventory details and exports results.

.DESCRIPTION
    Gathers OS, hardware, CPU, memory, disk, and network details and exports the results
    to JSON and/or CSV. Optionally includes installed hotfixes.

.PARAMETER ComputerName
    One or more computer names to query (default: local computer).

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Json).

.PARAMETER IncludeUpdates
    Include installed hotfixes (may be slow on remote systems).

.EXAMPLE
    .\Collect-SystemInventory.ps1

.EXAMPLE
    .\Collect-SystemInventory.ps1 -ComputerName "Server01" -Format Both -IncludeUpdates

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$ComputerName = $env:COMPUTERNAME,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Json","Csv","Both")]
    [string]$Format = "Json",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeUpdates
)

# Create output directory if missing
if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Collect-SystemInventory_$timestamp.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

Write-Log "Starting system inventory collection" "INFO"

foreach ($computer in $ComputerName) {
    Write-Log "Collecting inventory for $computer" "INFO"

    try {
        # Core system details
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $computer
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $computer
        $cpu = Get-CimInstance -ClassName Win32_Processor -ComputerName $computer
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $computer -Filter "DriveType=3"
        $nics = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ComputerName $computer -Filter "IPEnabled=TRUE"

        # Optional updates
        $updates = $null
        if ($IncludeUpdates) {
            Write-Log "Collecting installed updates for $computer" "INFO"
            $updates = Get-HotFix -ComputerName $computer | Select-Object HotFixID, Description, InstalledOn
        }

        # Build inventory object
        $inventory = [PSCustomObject]@{
            ComputerName = $computer
            CollectedAt  = Get-Date
            OS           = [PSCustomObject]@{
                Caption      = $os.Caption
                Version      = $os.Version
                BuildNumber  = $os.BuildNumber
                InstallDate  = $os.InstallDate
                LastBootUp   = $os.LastBootUpTime
            }
            Hardware     = [PSCustomObject]@{
                Manufacturer = $cs.Manufacturer
                Model        = $cs.Model
                TotalMemoryGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            }
            CPU          = $cpu | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
            Disks        = $disks | Select-Object DeviceID, VolumeName, @{n="SizeGB";e={[math]::Round($_.Size/1GB,2)}}, @{n="FreeGB";e={[math]::Round($_.FreeSpace/1GB,2)}}, @{n="FreePercent";e={[math]::Round(($_.FreeSpace/$_.Size)*100,2)}}
            Network      = $nics | Select-Object Description, IPAddress, DefaultIPGateway, DNSServerSearchOrder, MACAddress
            Updates      = $updates
        }

        # Export JSON
        if ($Format -in @("Json","Both")) {
            $jsonPath = Join-Path $OutputDirectory "${computer}_Inventory_$timestamp.json"
            $inventory | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
            Write-Log "Saved JSON inventory to $jsonPath" "INFO"
        }

        # Export CSV summary
        if ($Format -in @("Csv","Both")) {
            $csvPath = Join-Path $OutputDirectory "${computer}_InventorySummary_$timestamp.csv"
            $summary = [PSCustomObject]@{
                ComputerName   = $computer
                OS             = $os.Caption
                OSVersion      = $os.Version
                LastBootUp     = $os.LastBootUpTime
                Manufacturer   = $cs.Manufacturer
                Model          = $cs.Model
                TotalMemoryGB  = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
                CPU            = $cpu[0].Name
                Cores          = $cpu[0].NumberOfCores
                LogicalCPU     = $cpu[0].NumberOfLogicalProcessors
                DiskCount      = $disks.Count
                DiskFreeGB     = [math]::Round(($disks.FreeSpace | Measure-Object -Sum).Sum / 1GB, 2)
                DiskTotalGB    = [math]::Round(($disks.Size | Measure-Object -Sum).Sum / 1GB, 2)
            }
            $summary | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Write-Log "Saved CSV summary to $csvPath" "INFO"
        }
    }
    catch {
        Write-Log "Failed to collect inventory for $computer. $_" "ERROR"
    }
}

Write-Log "Inventory collection complete" "INFO"
