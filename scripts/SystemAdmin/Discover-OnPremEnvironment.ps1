<#
.SYNOPSIS
    Discovers on-premises environment details and exports results.

.DESCRIPTION
    Collects OS, hardware, network, services, and (when available) Active Directory
    domain/forest information. Exports to JSON and CSV with logging.

.PARAMETER OutputDirectory
    Directory to write output and log files (default: <script>\logs).

.PARAMETER Format
    Output format: Json, Csv, or Both (default: Json).

.PARAMETER IncludeServices
    Include running services list in output.

.EXAMPLE
    .\Discover-OnPremEnvironment.ps1

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("Json","Csv","Both")]
    [string]$Format = "Json",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeServices
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Discover-OnPremEnvironment_$timestamp.log"

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

Write-Log "Starting on-prem environment discovery" "INFO"

try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    $nics = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE"

    $services = $null
    if ($IncludeServices) {
        Write-Log "Collecting running services" "INFO"
        $services = Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object Name, DisplayName, StartType
    }

    $adInfo = $null
    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        try {
            Import-Module ActiveDirectory -ErrorAction Stop
            $domain = Get-ADDomain
            $forest = Get-ADForest
            $adInfo = [PSCustomObject]@{
                DomainName = $domain.DNSRoot
                ForestName = $forest.Name
                DomainMode = $domain.DomainMode
                ForestMode = $forest.ForestMode
            }
        }
        catch {
            Write-Log "Active Directory module found but query failed: $_" "WARN"
        }
    } else {
        Write-Log "Active Directory module not found. Skipping AD details." "WARN"
    }

    $result = [PSCustomObject]@{
        CollectedAt = Get-Date
        OS = [PSCustomObject]@{
            Caption = $os.Caption
            Version = $os.Version
            BuildNumber = $os.BuildNumber
            LastBootUp = $os.LastBootUpTime
        }
        Hardware = [PSCustomObject]@{
            Manufacturer = $cs.Manufacturer
            Model = $cs.Model
            TotalMemoryGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        }
        Disks = $disks | Select-Object DeviceID, VolumeName, @{n="SizeGB";e={[math]::Round($_.Size/1GB,2)}}, @{n="FreeGB";e={[math]::Round($_.FreeSpace/1GB,2)}}
        Network = $nics | Select-Object Description, IPAddress, DefaultIPGateway, DNSServerSearchOrder, MACAddress
        ActiveDirectory = $adInfo
        Services = $services
    }

    if ($Format -in @("Json","Both")) {
        $jsonPath = Join-Path $OutputDirectory "OnPremEnvironment_$timestamp.json"
        $result | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
        Write-Log "Saved JSON to $jsonPath" "INFO"
    }

    if ($Format -in @("Csv","Both")) {
        $csvPath = Join-Path $OutputDirectory "OnPremEnvironment_Summary_$timestamp.csv"
        $summary = [PSCustomObject]@{
            Hostname = $env:COMPUTERNAME
            OS = $os.Caption
            OSVersion = $os.Version
            LastBootUp = $os.LastBootUpTime
            Manufacturer = $cs.Manufacturer
            Model = $cs.Model
            TotalMemoryGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            DiskCount = $disks.Count
        }
        $summary | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Saved CSV summary to $csvPath" "INFO"
    }
}
catch {
    Write-Log "Discovery failed: $_" "ERROR"
    throw
}

Write-Log "Discovery complete" "INFO"
