# System Administration Scripts

This directory contains PowerShell scripts for Windows system administration tasks.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Available Scripts](#available-scripts)
  - [Monitor-DiskSpace.ps1](#monitor-diskspaceps1)
  - [Manage-Services.ps1](#manage-servicesps1)
  - [Analyze-EventLogs.ps1](#analyze-eventlogsps1)
  - [Test-NetConnectionReport.ps1](#test-netconnectionreportps1)
  - [Test-SftpConnection.ps1](#test-sftpconnectionps1)
  - [Invoke-RestApi.ps1](#invoke-restapips1)
  - [Discover-OnPremEnvironment.ps1](#discover-onpremenvironmentps1)
  - [New-ADDomainStructure.ps1](#new-addomainstructureps1)
  - [Find-AdminUsers.ps1](#find-adminusersps1)
  - [Audit-ADPermissions.ps1](#audit-adpermissionsps1)
  - [Export-ADUsers.ps1](#export-adusersps1)
  - [Audit-GroupMemberships.ps1](#audit-groupmembershipsps1)
  - [Find-SharedFolders.ps1](#find-sharedfoldersps1)
  - [Find-OpenPorts.ps1](#find-openportsps1)
  - [Get-NetworkInventory.ps1](#get-networkinventoryps1)
  - [Test-DNSResolution.ps1](#test-dnsresolutionps1)
  - [Audit-LocalAdmins.ps1](#audit-localadminsps1)
  - [Audit-FilePermissions.ps1](#audit-filepermissionsps1)
  - [Get-FailedLogins.ps1](#get-failedloginsps1)
  - [Audit-InstalledSoftware.ps1](#audit-installedsoftwareps1)
  - [Find-StaleAccounts.ps1](#find-staleaccountsps1)
  - [Get-PatchStatus.ps1](#get-patchstatusps1)
  - [Install-WindowsUpdates.ps1](#install-windowsupdatesps1)
  - [Get-RebootPending.ps1](#get-rebootpendingps1)
  - [Search-ErrorLogs.ps1](#search-errorlogsps1)
  - [Export-EventLogs.ps1](#export-eventlogsps1)
  - [Collect-SystemInventory.ps1](#collect-systeminventoryps1)
  - [Backup-EventLogs.ps1](#backup-eventlogsps1)
  - [Cleanup-DiskSpace.ps1](#cleanup-diskspaceps1)
  - [Monitor-Performance.ps1](#monitor-performanceps1)
- [Common Administrative Tasks](#common-administrative-tasks)
  - [Daily Health Check](#daily-health-check)
  - [Service Troubleshooting](#service-troubleshooting)
  - [Disk Space Management](#disk-space-management)
  - [Event Log Analysis](#event-log-analysis)
- [Best Practices](#best-practices)
- [Scheduling Scripts](#scheduling-scripts)
- [Remote Management](#remote-management)
- [Common Issues](#common-issues)
- [Security Considerations](#security-considerations)
- [Additional Resources](#additional-resources)

## Prerequisites

- PowerShell 5.1+ (included with Windows)
- Administrator privileges for most operations
- Windows operating system

## Available Scripts

### Monitor-DiskSpace.ps1

Monitor disk space on local or remote computers and get alerts for low disk space.

**Features:**
- Check disk space on multiple computers
- Set custom threshold for alerts
- Color-coded status indicators
- Export results to CSV
- Summary of disk health

**Usage:**
```powershell
# Monitor local computer with default threshold (15%)
.\Monitor-DiskSpace.ps1

# Monitor with custom threshold
.\Monitor-DiskSpace.ps1 -ThresholdPercent 20

# Monitor remote computer
.\Monitor-DiskSpace.ps1 -ComputerName "Server01" -ThresholdPercent 10

# Monitor multiple computers
.\Monitor-DiskSpace.ps1 -ComputerName "Server01","Server02","Server03"

# Enable email alerts (configure email settings in script first)
.\Monitor-DiskSpace.ps1 -EmailAlert
```

**Parameters:**
- `-ComputerName`: Array of computer names to check (default: local computer)
- `-ThresholdPercent`: Percentage of free space to trigger low alert (default: 15)
- `-EmailAlert`: Enable email alerts for low disk space

### Manage-Services.ps1

Comprehensive Windows service management script.

**Features:**
- List all services with summary
- Get detailed service information
- Start/stop/restart services
- Configure service startup type
- List stopped automatic services
- Show dependent and required services

**Usage:**
```powershell
# List all services
.\Manage-Services.ps1 -Action List

# Get detailed info about a service
.\Manage-Services.ps1 -Action Info -ServiceName "Spooler"

# Start a service
.\Manage-Services.ps1 -Action Start -ServiceName "Spooler"

# Stop a service
.\Manage-Services.ps1 -Action Stop -ServiceName "Spooler"

# Restart a service
.\Manage-Services.ps1 -Action Restart -ServiceName "Spooler"

# Set startup type
.\Manage-Services.ps1 -Action SetStartup -ServiceName "Spooler" -StartupType "Automatic"

# List stopped automatic services
.\Manage-Services.ps1 -Action ListStopped

# Manage services on remote computer
.\Manage-Services.ps1 -Action List -ComputerName "Server01"
```

**Parameters:**
- `-Action`: List, Info, Start, Stop, Restart, SetStartup, ListStopped
- `-ServiceName`: Name of the service
- `-ComputerName`: Remote computer name (default: local computer)
- `-StartupType`: Automatic, Manual, or Disabled (for SetStartup action)

### Analyze-EventLogs.ps1

Analyze Windows Event Logs for errors, warnings, and specific events.

**Features:**
- Search for errors and warnings
- Search by Event ID
- Filter by time range
- Generate event log summary
- Group events by source
- Detailed event information

**Usage:**
```powershell
# Get errors from last 24 hours
.\Analyze-EventLogs.ps1 -Action Errors -Hours 24

# Get warnings from last 48 hours
.\Analyze-EventLogs.ps1 -Action Warnings -Hours 48

# Search for specific Event ID
.\Analyze-EventLogs.ps1 -Action Search -LogName "System" -EventID 1074 -Hours 24

# Generate event log summary
.\Analyze-EventLogs.ps1 -Action Summary -Hours 24

# Get application errors only
.\Analyze-EventLogs.ps1 -Action ApplicationErrors -Hours 24
```

### Test-NetConnectionReport.ps1

Tests network connectivity to a host and common ports.

**Features:**
- DNS resolution and ICMP reachability
- TCP port checks for multiple ports
- Console progress and log file

**Usage:**
```powershell
# Test common web ports
.\Test-NetConnectionReport.ps1 -TargetHost "example.com"

# Test custom ports
.\Test-NetConnectionReport.ps1 -TargetHost "server01" -Port 22,3389
```

### Test-SftpConnection.ps1

Tests SSH/SFTP connectivity and reads SSH banner.

**Features:**
- TCP connection to SSH port
- Reads SSH banner for validation
- Console progress and log file

**Usage:**
```powershell
# Test SFTP connectivity
.\Test-SftpConnection.ps1 -Host "sftp.example.com"
```

### Invoke-RestApi.ps1

Executes REST API calls with logging.

**Features:**
- Supports GET/POST/PUT/PATCH/DELETE
- Optional JSON body and headers
- Optional response file output

**Usage:**
```powershell
# Simple GET
.\Invoke-RestApi.ps1 -Method GET -Uri "https://api.github.com/repos/bordera-randy/PowerShell-Utility"

# POST with JSON
.\Invoke-RestApi.ps1 -Method POST -Uri "https://api.example.com/items" -Body '{"name":"test"}'
```

### Discover-OnPremEnvironment.ps1

Discovers on-prem environment details and exports results.

**Features:**
- OS, hardware, disk, and network inventory
- Optional Active Directory details
- JSON/CSV export with logs

**Usage:**
```powershell
# Basic discovery
.\Discover-OnPremEnvironment.ps1

# Include running services
.\Discover-OnPremEnvironment.ps1 -IncludeServices -Format Both
```

### New-ADDomainStructure.ps1

Creates an Active Directory organizational structure from a JSON configuration file including OUs, security groups, and users.

**Features:**
- Provisions OUs, security groups, and users in the correct dependency order
- Built-in default structure (IT, HR, Finance, Sales, Marketing) when no config supplied
- WhatIf support to preview changes without modifying AD
- Logging to file with color-coded console output

**Usage:**
```powershell
# Create default domain structure
.\New-ADDomainStructure.ps1

# Create from custom JSON config
.\New-ADDomainStructure.ps1 -ConfigFile "C:\Config\ad-structure.json"

# Preview changes without creating objects
.\New-ADDomainStructure.ps1 -WhatIf
```

**Parameters:**
- `-ConfigFile`: Path to a JSON configuration file defining OUs, groups, and users
- `-WhatIf`: Preview changes without creating any AD objects

### Find-AdminUsers.ps1

Finds all admin and privileged users across the Active Directory domain.

**Features:**
- Enumerates Domain Admins, Enterprise Admins, Schema Admins, and other privileged groups
- Color-coded display of account status and password policy
- Identifies disabled admin accounts and non-expiring passwords
- Export to CSV, JSON, or both

**Usage:**
```powershell
# List all privileged users
.\Find-AdminUsers.ps1

# Include service accounts and export to CSV
.\Find-AdminUsers.ps1 -IncludeServiceAccounts -ExportFormat CSV

# Query a specific domain controller
.\Find-AdminUsers.ps1 -ComputerName "DC01" -ExportFormat Both
```

**Parameters:**
- `-ComputerName`: Domain controller to query (default: localhost)
- `-IncludeServiceAccounts`: Include service accounts (svc-* and computer accounts)
- `-OutputPath`: Directory for export files
- `-ExportFormat`: CSV, JSON, or Both

### Audit-ADPermissions.ps1

Audits Active Directory permissions and ACLs on Organizational Units.

**Features:**
- Reports explicit and inherited ACEs on AD OUs
- Identifies non-default and custom permissions for privilege drift detection
- Recursive audit of child OUs
- Color-coded output highlighting Deny rules and custom entries

**Usage:**
```powershell
# Audit domain root permissions
.\Audit-ADPermissions.ps1

# Audit a specific OU recursively
.\Audit-ADPermissions.ps1 -SearchBase "OU=IT,DC=contoso,DC=com" -Recurse

# Full audit with inherited permissions exported to CSV
.\Audit-ADPermissions.ps1 -Recurse -IncludeInherited -ExportFormat CSV
```

**Parameters:**
- `-SearchBase`: Distinguished name of the OU to audit (default: domain root)
- `-Recurse`: Include child OUs
- `-IncludeInherited`: Include inherited permissions
- `-OutputPath`: Directory for export files
- `-ExportFormat`: CSV, JSON, or Both

### Export-ADUsers.ps1

Exports all Active Directory users with comprehensive details to CSV or JSON.

**Features:**
- Exports name, email, department, title, manager, last logon, password status, and more
- Filter by enabled users, all users, or custom AD filter
- Resolves manager display names
- Summary of stale, disabled, and non-expiring password accounts

**Usage:**
```powershell
# Export all enabled users to CSV
.\Export-ADUsers.ps1

# Export all users in both formats
.\Export-ADUsers.ps1 -Filter "*" -Format Both -OutputPath "C:\Reports"

# Export users from a specific OU
.\Export-ADUsers.ps1 -SearchBase "OU=Sales,DC=contoso,DC=com" -Format JSON
```

**Parameters:**
- `-SearchBase`: Distinguished name of the OU to search (default: domain root)
- `-Filter`: User filter — "Enabled" (default), "*" for all, or custom AD filter string
- `-OutputPath`: Directory for export files
- `-Format`: CSV, JSON, or Both (default: CSV)

### Audit-GroupMemberships.ps1

Audits group memberships across the Active Directory domain.

**Features:**
- Enumerates group members with optional nested group resolution
- Highlights empty groups and groups with excessive membership
- Color-coded member display by type (user, group, computer)
- Configurable excessive membership threshold

**Usage:**
```powershell
# Audit all groups
.\Audit-GroupMemberships.ps1

# Audit Domain Admins with nested resolution
.\Audit-GroupMemberships.ps1 -GroupName "Domain Admins" -IncludeNested

# Audit matching groups and export
.\Audit-GroupMemberships.ps1 -GroupName "Sales*" -ExportFormat CSV
```

**Parameters:**
- `-GroupName`: Name or wildcard pattern for groups to audit (default: *)
- `-IncludeNested`: Recursively resolve nested memberships
- `-SearchBase`: Distinguished name of the OU to search
- `-OutputPath`: Directory for export files
- `-ExportFormat`: CSV, JSON, or Both
- `-ExcessiveThreshold`: Member count to flag as excessive (default: 50)

### Find-SharedFolders.ps1

Finds all shared folders on local or remote computers.

**Features:**
- Enumerates SMB shares with Get-SmbShare or WMI fallback
- Displays share name, path, type, and permissions
- Highlights administrative shares separately
- Optional CSV export

**Usage:**
```powershell
# List shares on localhost
.\Find-SharedFolders.ps1

# Scan multiple servers including admin shares
.\Find-SharedFolders.ps1 -ComputerName "Server01","Server02" -IncludeAdminShares

# Export results to CSV
.\Find-SharedFolders.ps1 -ExportPath "C:\Reports\shares.csv"
```

**Parameters:**
- `-ComputerName`: One or more computer names (default: localhost)
- `-IncludeAdminShares`: Include administrative shares (names ending with $)
- `-ExportPath`: File path for CSV export

### Find-OpenPorts.ps1

Scans for open TCP ports on a target computer.

**Features:**
- Custom port range or common/well-known ports only scanning
- Identifies service names for known ports
- Progress bar and color-coded results
- Configurable connection timeout

**Usage:**
```powershell
# Scan ports 1-1024 on localhost
.\Find-OpenPorts.ps1

# Scan well-known ports on a remote host
.\Find-OpenPorts.ps1 -ComputerName "192.168.1.10" -CommonPortsOnly

# Scan custom range and export
.\Find-OpenPorts.ps1 -ComputerName "Server01" -PortRange "80-8080" -ExportPath "C:\Reports\ports.csv"
```

**Parameters:**
- `-ComputerName`: Hostname or IP to scan (default: localhost)
- `-PortRange`: Port range in "start-end" format (default: "1-1024")
- `-CommonPortsOnly`: Scan only well-known ports
- `-Timeout`: Connection timeout in milliseconds (default: 100)
- `-ExportPath`: File path for CSV export

### Get-NetworkInventory.ps1

Discovers devices and services on a network subnet by pinging each address.

**Features:**
- Pings a subnet range to identify online hosts
- Optional reverse DNS resolution
- Checks common TCP ports on responsive hosts
- Progress bar with color-coded online/offline status

**Usage:**
```powershell
# Scan a full subnet
.\Get-NetworkInventory.ps1 -Subnet "192.168.1"

# Scan a smaller range with DNS resolution
.\Get-NetworkInventory.ps1 -Subnet "10.0.0" -StartRange 1 -EndRange 50 -ResolveDNS

# Export results to CSV
.\Get-NetworkInventory.ps1 -Subnet "192.168.1" -ExportPath "C:\Reports\inventory.csv"
```

**Parameters:**
- `-Subnet`: First three octets of the subnet (e.g., "192.168.1")
- `-StartRange`: First host octet to scan (default: 1)
- `-EndRange`: Last host octet to scan (default: 254)
- `-ResolveDNS`: Attempt reverse DNS resolution
- `-ExportPath`: File path for CSV export

### Test-DNSResolution.ps1

Tests DNS resolution across multiple DNS servers and compares results.

**Features:**
- Resolves domains against multiple DNS servers simultaneously
- Supports A, AAAA, MX, CNAME, NS, and TXT record types
- Identifies discrepancies between server responses
- Color-coded consistent/discrepant results

**Usage:**
```powershell
# Compare DNS resolution across servers
.\Test-DNSResolution.ps1 -DomainName "example.com" -DNSServer "8.8.8.8","1.1.1.1"

# Query MX records for multiple domains
.\Test-DNSResolution.ps1 -DomainName "example.com","contoso.com" -DNSServer "8.8.8.8" -RecordType MX
```

**Parameters:**
- `-DomainName`: One or more domain names to resolve
- `-DNSServer`: One or more DNS server IPs or hostnames to query
- `-RecordType`: DNS record type — A, AAAA, MX, CNAME, NS, TXT (default: A)
- `-ExportPath`: File path for CSV export

### Audit-LocalAdmins.ps1

Finds local administrator group members on one or more servers.

**Features:**
- Enumerates members of the local Administrators group
- Identifies member type (User/Group), source (Local/Domain), and SID
- Highlights domain accounts in local admin groups
- Remote computer support via PowerShell remoting

**Usage:**
```powershell
# Audit local computer
.\Audit-LocalAdmins.ps1

# Audit multiple servers
.\Audit-LocalAdmins.ps1 -ComputerName "SERVER01","SERVER02"

# Export results to CSV
.\Audit-LocalAdmins.ps1 -ComputerName "SERVER01" -ExportPath "C:\Reports\admins.csv"
```

**Parameters:**
- `-ComputerName`: One or more computer names (default: localhost)
- `-ExportPath`: File path for CSV export

### Audit-FilePermissions.ps1

Audits NTFS file and folder permissions on a specified path.

**Features:**
- Enumerates NTFS ACEs with identity, access rights, and inheritance info
- Highlights Deny rules and broad access (Everyone, Authenticated Users)
- Recursive subfolder audit with configurable depth
- Summary of Allow/Deny/Inherited/Explicit counts

**Usage:**
```powershell
# Audit a single folder
.\Audit-FilePermissions.ps1 -Path "C:\Shared"

# Audit recursively with limited depth
.\Audit-FilePermissions.ps1 -Path "C:\Data" -Recurse -Depth 2

# Export results to CSV
.\Audit-FilePermissions.ps1 -Path "D:\Projects" -Recurse -ExportPath "C:\Reports\perms.csv"
```

**Parameters:**
- `-Path`: Folder path to audit
- `-Recurse`: Recursively audit subfolders
- `-Depth`: Maximum recursion depth (default: 3)
- `-ExportPath`: File path for CSV export

### Get-FailedLogins.ps1

Searches for failed login attempts in Windows security event logs.

**Features:**
- Queries Event ID 4625 (Failed Logon) and 4771 (Kerberos pre-auth failures)
- Displays account names, source IPs, failure reasons, and timestamps
- Groups results by top offending accounts and source IPs
- High-frequency failure highlighting

**Usage:**
```powershell
# Show failed logins from last 24 hours
.\Get-FailedLogins.ps1

# Query a domain controller for the last 48 hours
.\Get-FailedLogins.ps1 -ComputerName "DC01" -Hours 48

# Export results to CSV
.\Get-FailedLogins.ps1 -Hours 72 -TopN 10 -ExportPath "C:\Reports\failed.csv"
```

**Parameters:**
- `-ComputerName`: Computer name to query (default: localhost)
- `-Hours`: Hours to look back (default: 24)
- `-TopN`: Number of top offenders to display (default: 20)
- `-ExportPath`: File path for CSV export

### Audit-InstalledSoftware.ps1

Audits installed software across one or more machines using registry data.

**Features:**
- Reads both 32-bit and 64-bit registry uninstall keys
- Displays name, version, publisher, install date, and estimated size
- Optional wildcard filter for software names
- Summary grouped by publisher

**Usage:**
```powershell
# List all installed software locally
.\Audit-InstalledSoftware.ps1

# Audit multiple servers
.\Audit-InstalledSoftware.ps1 -ComputerName "SERVER01","SERVER02"

# Filter and export
.\Audit-InstalledSoftware.ps1 -Filter "*Office*" -ExportPath "C:\Reports\software.csv"
```

**Parameters:**
- `-ComputerName`: One or more computer names (default: localhost)
- `-Filter`: Wildcard pattern to filter software names
- `-ExportPath`: File path for CSV export

### Find-StaleAccounts.ps1

Finds stale and inactive Active Directory accounts.

**Features:**
- Identifies user (and optionally computer) accounts inactive beyond a threshold
- Highlights accounts that have never logged in
- Summary grouped by OU with enabled/disabled breakdown
- Configurable inactivity threshold

**Usage:**
```powershell
# Find users inactive for 90+ days
.\Find-StaleAccounts.ps1

# Include computer accounts with 60-day threshold
.\Find-StaleAccounts.ps1 -DaysInactive 60 -IncludeComputers

# Export results to CSV
.\Find-StaleAccounts.ps1 -DaysInactive 120 -IncludeDisabled -ExportPath "C:\Reports\stale.csv"
```

**Parameters:**
- `-DaysInactive`: Days since last logon to consider stale (default: 90)
- `-IncludeComputers`: Include computer accounts
- `-IncludeDisabled`: Include disabled accounts
- `-SearchBase`: Distinguished name of the OU to search
- `-ExportPath`: File path for CSV export

### Get-PatchStatus.ps1

Checks Windows Update patch status on one or more computers.

**Features:**
- Queries installed hotfixes via Get-HotFix
- Color-coded summary based on days since last patch
- Filters recent patches within a configurable window
- Shows KB article, description, install date, and installed by

**Usage:**
```powershell
# Check local patch status (last 30 days)
.\Get-PatchStatus.ps1

# Check multiple servers with 60-day window
.\Get-PatchStatus.ps1 -ComputerName "Server01","Server02" -DaysBack 60

# Export to CSV
.\Get-PatchStatus.ps1 -ExportPath "C:\Reports\patches.csv"
```

**Parameters:**
- `-ComputerName`: One or more computer names (default: localhost)
- `-DaysBack`: Days to look back for installed patches (default: 30)
- `-ExportPath`: File path for CSV export

### Install-WindowsUpdates.ps1

Installs pending Windows updates using the Windows Update COM API.

**Features:**
- Searches, downloads, and installs pending updates
- Filter by category: Security, Critical, or All
- WhatIf support to preview updates without installing
- Optional automatic reboot after installation

**Usage:**
```powershell
# Install pending Security updates
.\Install-WindowsUpdates.ps1

# Install all updates and reboot if needed
.\Install-WindowsUpdates.ps1 -Category All -RebootIfNeeded

# Preview which updates would be installed
.\Install-WindowsUpdates.ps1 -WhatIf
```

**Parameters:**
- `-ComputerName`: Target computer name (default: localhost)
- `-Category`: Security, Critical, or All (default: Security)
- `-RebootIfNeeded`: Automatically reboot after installation if required
- `-WhatIf`: Preview changes without installing

### Get-RebootPending.ps1

Checks if servers need a reboot by querying multiple reboot-pending indicators.

**Features:**
- Checks Component Based Servicing, Windows Update, Pending File Rename, SCCM Client, and pending computer rename
- Color-coded status per server
- Summary of servers needing reboot with trigger sources
- Optional CSV export

**Usage:**
```powershell
# Check local computer
.\Get-RebootPending.ps1

# Check multiple servers
.\Get-RebootPending.ps1 -ComputerName "Server01","Server02","Server03"

# Export results
.\Get-RebootPending.ps1 -ComputerName "Server01" -ExportPath "C:\Reports\reboot.csv"
```

**Parameters:**
- `-ComputerName`: One or more computer names (default: localhost)
- `-ExportPath`: File path for CSV export

### Search-ErrorLogs.ps1

Searches error logs across servers for specific patterns.

**Features:**
- Searches both Windows Event Logs and text-based log files
- Regex pattern matching with configurable context lines
- Groups event log results by source with highlighted matches
- Supports remote computer searches

**Usage:**
```powershell
# Search event logs for a pattern
.\Search-ErrorLogs.ps1 -Pattern "OutOfMemory"

# Search remote server with longer time range
.\Search-ErrorLogs.ps1 -ComputerName "Server01" -Pattern "timeout" -Hours 48

# Search text log files with context
.\Search-ErrorLogs.ps1 -LogPath "C:\Logs\app.log" -Pattern "Exception" -Context 5
```

**Parameters:**
- `-ComputerName`: One or more computer names (default: localhost)
- `-LogPath`: One or more text-based log file paths to search
- `-Pattern`: Regex pattern to search for
- `-Hours`: Hours to look back in event logs (default: 24)
- `-Context`: Lines of context around each match (default: 2)
- `-ExportPath`: File path for CSV export

### Export-EventLogs.ps1

Exports and archives Windows Event Logs to CSV and/or EVTX files.

**Features:**
- Exports Application, System, and Security logs by default
- CSV and EVTX format support
- Optional zip archive of exported files
- Progress bar with file size reporting

**Usage:**
```powershell
# Export last 24 hours to CSV
.\Export-EventLogs.ps1

# Export specific logs in both formats
.\Export-EventLogs.ps1 -LogName "Application","System" -Hours 48 -Format Both

# Export and compress
.\Export-EventLogs.ps1 -CompressArchive -OutputDirectory "C:\Exports"
```

**Parameters:**
- `-ComputerName`: Target computer name (default: localhost)
- `-LogName`: Event log names to export (default: Application, System, Security)
- `-Hours`: Hours of events to export (default: 24)
- `-OutputDirectory`: Directory for exported files
- `-Format`: CSV, EVTX, or Both (default: CSV)
- `-CompressArchive`: Create a zip archive of exported files

# Get system errors only
.\Analyze-EventLogs.ps1 -Action SystemErrors -Hours 24

# Get more events (default is 100)
.\Analyze-EventLogs.ps1 -Action Errors -Hours 24 -MaxEvents 500

# Analyze remote computer
.\Analyze-EventLogs.ps1 -Action Errors -ComputerName "Server01" -Hours 24
```

**Parameters:**
- `-Action`: Errors, Warnings, Search, Summary, ApplicationErrors, SystemErrors
- `-ComputerName`: Computer name to analyze (default: local)
- `-LogName`: Event log name (default: "Application")
- `-EventID`: Specific Event ID to search for
- `-Hours`: Time range to analyze (default: 24 hours)
- `-MaxEvents`: Maximum events to retrieve (default: 100)

### Collect-SystemInventory.ps1

Collect system inventory details and export to JSON/CSV.

**Features:**
- OS, hardware, CPU, memory, disk, and network inventory
- Optional installed update collection
- JSON and CSV output options
- Console progress and log file

**Usage:**
```powershell
# Local inventory (JSON)
.\Collect-SystemInventory.ps1

# CSV + JSON with updates
.\Collect-SystemInventory.ps1 -Format Both -IncludeUpdates

# Remote inventory
.\Collect-SystemInventory.ps1 -ComputerName "Server01","Server02" -Format Csv
```

**Parameters:**
- `-ComputerName`: One or more computer names (default: local computer)
- `-OutputDirectory`: Output and log directory
- `-Format`: Json, Csv, or Both
- `-IncludeUpdates`: Include installed hotfixes

### Backup-EventLogs.ps1

Export event logs to EVTX and recent entries to CSV.

**Features:**
- Exports System/Application/Security logs by default
- CSV export for recent entries (last N days)
- Console progress and log file

**Usage:**
```powershell
# Export default logs (last 7 days)
.\Backup-EventLogs.ps1

# Export specific logs and days
.\Backup-EventLogs.ps1 -LogName System,Application -Days 3
```

**Parameters:**
- `-LogName`: Log names to export
- `-Days`: Number of days for CSV export
- `-ComputerName`: Target computer name
- `-OutputDirectory`: Output and log directory

### Cleanup-DiskSpace.ps1

Performs cleanup operations to free up disk space on Windows servers and workstations.

**Features:**
- Clears Windows Update cache
- Empties Recycle Bin
- Clears temporary files from system and user temp directories
- Clears Windows Error Reporting files
- Cleans IIS logs (if applicable)
- Shows before and after disk space comparison
- WhatIf support to preview changes

**Usage:**
```powershell
# Perform all cleanup operations
.\Cleanup-DiskSpace.ps1

# Only clear Windows Update cache and temp files
.\Cleanup-DiskSpace.ps1 -ClearWindowsUpdate -ClearTemp

# Preview what would be cleaned without making changes
.\Cleanup-DiskSpace.ps1 -WhatIf

# Clear IIS logs older than 7 days
.\Cleanup-DiskSpace.ps1 -ClearIISLogs -IISLogDays 7
```

**Parameters:**
- `-ClearWindowsUpdate`: Clear Windows Update download cache
- `-ClearRecycleBin`: Empty the Recycle Bin for all drives
- `-ClearTemp`: Clear temporary files from system and user temp directories
- `-ClearIISLogs`: Clear IIS log files older than specified days
- `-IISLogDays`: Number of days to keep IIS logs (default: 30)
- `-WhatIf`: Preview changes without performing cleanup

### Monitor-Performance.ps1

Monitors system performance metrics in real-time.

**Features:**
- CPU usage monitoring
- Memory usage tracking
- Disk I/O statistics
- Network utilization
- Top running processes by CPU usage
- System uptime display
- Optional CSV logging

**Usage:**
```powershell
# Continuously monitor local system (5-second intervals)
.\Monitor-Performance.ps1

# Monitor for 30 minutes with 10-second intervals
.\Monitor-Performance.ps1 -Interval 10 -Duration 30

# Monitor and log to CSV, showing top 5 processes
.\Monitor-Performance.ps1 -LogToFile -TopProcesses 5

# Monitor a remote computer
.\Monitor-Performance.ps1 -ComputerName "Server01"
```

**Parameters:**
- `-Interval`: Refresh interval in seconds (default: 5)
- `-Duration`: Duration to monitor in minutes (default: continuous until Ctrl+C)
- `-LogToFile`: Save monitoring data to a CSV file
- `-TopProcesses`: Number of top processes to display (default: 10)
- `-ComputerName`: Remote computer name to monitor (default: local)

## Common Administrative Tasks

### Daily Health Check

```powershell
# Quick system health check
.\Monitor-DiskSpace.ps1
.\Manage-Services.ps1 -Action ListStopped
.\Analyze-EventLogs.ps1 -Action Summary -Hours 24
```

### Service Troubleshooting

```powershell
# Check if a service is running
.\Manage-Services.ps1 -Action Info -ServiceName "ServiceName"

# Check event logs for service issues
.\Analyze-EventLogs.ps1 -Action Search -LogName "System" -EventID 7036 -Hours 24

# Restart problematic service
.\Manage-Services.ps1 -Action Restart -ServiceName "ServiceName"
```

### Disk Space Management

```powershell
# Check all servers for low disk space
$servers = "Server01","Server02","Server03"
foreach ($server in $servers) {
    .\Monitor-DiskSpace.ps1 -ComputerName $server -ThresholdPercent 20
}
```

### Event Log Analysis

```powershell
# Check for critical errors across logs
.\Analyze-EventLogs.ps1 -Action Errors -Hours 24

# Look for specific error patterns
.\Analyze-EventLogs.ps1 -Action Search -LogName "Application" -EventID 1000 -Hours 168
```

## Best Practices

1. **Run as Administrator**: Many operations require elevated privileges
2. **Test on non-critical systems first**: Always test scripts in a safe environment
3. **Regular monitoring**: Schedule these scripts to run regularly
4. **Document changes**: Keep track of service changes and their reasons
5. **Backup before changes**: Create system restore points before making significant changes
6. **Review logs regularly**: Don't wait for problems to appear
7. **Use remote management carefully**: Ensure you have proper permissions

## Scheduling Scripts

Use Windows Task Scheduler to run these scripts automatically:

```powershell
# Example: Schedule daily disk space check
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Monitor-DiskSpace.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 8am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Daily Disk Space Check" -Description "Monitor disk space daily"
```

## Remote Management

To manage remote computers:

1. **Enable PowerShell Remoting:**
```powershell
# On remote computer
Enable-PSRemoting -Force

# Test connection
Test-WSMan -ComputerName "RemoteComputer"
```

2. **Configure Firewall:**
```powershell
# Allow PowerShell remoting through firewall
Enable-NetFirewallRule -Name "WINRM-HTTP-In-TCP"
```

3. **Use appropriate credentials:**
```powershell
# Run script with alternate credentials
$cred = Get-Credential
Invoke-Command -ComputerName "Server01" -Credential $cred -ScriptBlock { 
    # Your commands here
}
```

## Common Issues

**Issue**: "Access denied"
```
Solution: Run PowerShell as Administrator
```

**Issue**: "Remote computer not accessible"
```powershell
# Solution: Enable PowerShell Remoting
Enable-PSRemoting -Force

# Check firewall rules
Get-NetFirewallRule -Name "WINRM*"
```

**Issue**: "Service cannot be stopped because it has dependent services"
```
Solution: The script will show you dependent services and ask for confirmation
```

**Issue**: "Event log is full"
```powershell
# Clear event log (backup first!)
Get-EventLog -LogName Application | Export-Csv "AppLog_Backup.csv"
Clear-EventLog -LogName Application
```

## Security Considerations

1. **Use least privilege**: Don't run as admin unless necessary
2. **Audit changes**: Log all service and configuration changes
3. **Restrict remote access**: Only allow from trusted networks
4. **Use encrypted connections**: Enable HTTPS for PowerShell remoting
5. **Monitor script execution**: Track who runs these scripts and when

## Additional Resources

- [Windows Event Log Documentation](https://docs.microsoft.com/en-us/windows/win32/eventlog/event-logging)
- [Windows Services Guide](https://docs.microsoft.com/en-us/windows/win32/services/services)
- [PowerShell Remoting](https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/running-remote-commands)
- [Task Scheduler](https://docs.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page)
