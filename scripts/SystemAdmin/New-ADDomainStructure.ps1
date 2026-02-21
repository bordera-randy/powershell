<#
.SYNOPSIS
    Creates a new Active Directory domain structure including OUs, users, and groups.

.DESCRIPTION
    This script creates an Active Directory organizational structure from a JSON configuration
    file. It provisions OUs, security groups, and sample users in the correct order: OUs first,
    then groups, then users with group memberships. If no configuration file is supplied a
    built-in default structure (IT, HR, Finance, Sales, Marketing) is used.

.PARAMETER ConfigFile
    Path to a JSON configuration file that defines OUs, groups, and users.
    When omitted the script uses a built-in default structure.

.PARAMETER WhatIf
    Shows what changes would be made without actually creating any AD objects.

.EXAMPLE
    .\New-ADDomainStructure.ps1
    Creates the default domain structure.

.EXAMPLE
    .\New-ADDomainStructure.ps1 -ConfigFile "C:\Config\ad-structure.json"
    Creates a domain structure from the specified configuration file.

.EXAMPLE
    .\New-ADDomainStructure.ps1 -WhatIf
    Shows what the default structure creation would do without making changes.

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText',
    '',
    Justification = 'Password is generated in-memory for initial provisioning and never logged.'
)]
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile
)

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logDirectory = Join-Path $PSScriptRoot "logs"

if (-not (Test-Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path $logDirectory "New-ADDomainStructure_$timestamp.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $logFile -Value $line

    switch ($Level) {
        "INFO"  { Write-Host $line -ForegroundColor Cyan }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "ERROR" { Write-Host $line -ForegroundColor Red }
    }
}

# ---------------------------------------------------------------------------
# Default configuration
# ---------------------------------------------------------------------------
function Get-DefaultConfig {
    $domainDN = (Get-ADDomain).DistinguishedName

    return @{
        DomainDN = $domainDN
        OUs = @(
            @{ Name = "IT";        Path = $domainDN; Description = "Information Technology" }
            @{ Name = "HR";        Path = $domainDN; Description = "Human Resources" }
            @{ Name = "Finance";   Path = $domainDN; Description = "Finance Department" }
            @{ Name = "Sales";     Path = $domainDN; Description = "Sales Department" }
            @{ Name = "Marketing"; Path = $domainDN; Description = "Marketing Department" }
        )
        Groups = @(
            @{ Name = "IT-Staff";        OU = "IT";        Description = "IT Department Staff" }
            @{ Name = "IT-Admins";       OU = "IT";        Description = "IT Administrators" }
            @{ Name = "HR-Staff";        OU = "HR";        Description = "HR Department Staff" }
            @{ Name = "HR-Managers";     OU = "HR";        Description = "HR Managers" }
            @{ Name = "Finance-Staff";   OU = "Finance";   Description = "Finance Department Staff" }
            @{ Name = "Finance-Managers";OU = "Finance";   Description = "Finance Managers" }
            @{ Name = "Sales-Staff";     OU = "Sales";     Description = "Sales Department Staff" }
            @{ Name = "Sales-Managers";  OU = "Sales";     Description = "Sales Managers" }
            @{ Name = "Marketing-Staff"; OU = "Marketing"; Description = "Marketing Department Staff" }
            @{ Name = "Marketing-Managers"; OU = "Marketing"; Description = "Marketing Managers" }
        )
        Users = @(
            @{ FirstName = "John";  LastName = "Smith";   OU = "IT";        Title = "Systems Administrator"; Groups = @("IT-Staff","IT-Admins") }
            @{ FirstName = "Jane";  LastName = "Doe";     OU = "IT";        Title = "Network Engineer";      Groups = @("IT-Staff") }
            @{ FirstName = "Alice"; LastName = "Johnson"; OU = "HR";        Title = "HR Manager";            Groups = @("HR-Staff","HR-Managers") }
            @{ FirstName = "Bob";   LastName = "Williams";OU = "HR";        Title = "HR Specialist";         Groups = @("HR-Staff") }
            @{ FirstName = "Carol"; LastName = "Brown";   OU = "Finance";   Title = "Finance Manager";       Groups = @("Finance-Staff","Finance-Managers") }
            @{ FirstName = "Dave";  LastName = "Davis";   OU = "Finance";   Title = "Accountant";            Groups = @("Finance-Staff") }
            @{ FirstName = "Eve";   LastName = "Miller";  OU = "Sales";     Title = "Sales Manager";         Groups = @("Sales-Staff","Sales-Managers") }
            @{ FirstName = "Frank"; LastName = "Wilson";  OU = "Sales";     Title = "Sales Representative";  Groups = @("Sales-Staff") }
            @{ FirstName = "Grace"; LastName = "Moore";   OU = "Marketing"; Title = "Marketing Manager";     Groups = @("Marketing-Staff","Marketing-Managers") }
            @{ FirstName = "Hank";  LastName = "Taylor";  OU = "Marketing"; Title = "Content Specialist";    Groups = @("Marketing-Staff") }
        )
    }
}

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------
Write-Host "`n=== Active Directory Domain Structure Builder ===" -ForegroundColor Green
Write-Log "Starting AD domain structure creation"

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Log "ActiveDirectory module loaded"
}
catch {
    Write-Log "ActiveDirectory module is not available. $_" "ERROR"
    exit 1
}

# Load configuration
if ($ConfigFile) {
    if (-not (Test-Path $ConfigFile)) {
        Write-Log "Configuration file not found: $ConfigFile" "ERROR"
        exit 1
    }
    try {
        $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        Write-Log "Loaded configuration from $ConfigFile"
    }
    catch {
        Write-Log "Failed to parse configuration file: $_" "ERROR"
        exit 1
    }
}
else {
    Write-Log "No configuration file specified. Using built-in default structure."
    $config = Get-DefaultConfig
}

# --- Step 1: Create OUs ---
Write-Host "`n--- Step 1: Creating Organizational Units ---" -ForegroundColor Yellow
$ouCount = 0

foreach ($ou in $config.OUs) {
    $ouDN = "OU=$($ou.Name),$($ou.Path)"
    try {
        if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue) {
            Write-Log "OU already exists: $ouDN" "WARN"
            continue
        }

        if ($PSCmdlet.ShouldProcess($ouDN, "Create Organizational Unit")) {
            New-ADOrganizationalUnit -Name $ou.Name -Path $ou.Path -Description $ou.Description -ErrorAction Stop
            Write-Log "Created OU: $ouDN"
            $ouCount++
        }
    }
    catch {
        Write-Log "Failed to create OU '$($ou.Name)': $_" "ERROR"
    }
}

Write-Host "  OUs processed: $ouCount created" -ForegroundColor Green

# --- Step 2: Create Security Groups ---
Write-Host "`n--- Step 2: Creating Security Groups ---" -ForegroundColor Yellow
$groupCount = 0

foreach ($group in $config.Groups) {
    $groupPath = "OU=$($group.OU),$($config.DomainDN)"
    try {
        if (Get-ADGroup -Filter "Name -eq '$($group.Name)'" -ErrorAction SilentlyContinue) {
            Write-Log "Group already exists: $($group.Name)" "WARN"
            continue
        }

        if ($PSCmdlet.ShouldProcess($group.Name, "Create Security Group")) {
            New-ADGroup -Name $group.Name -Path $groupPath -GroupScope Global `
                -GroupCategory Security -Description $group.Description -ErrorAction Stop
            Write-Log "Created group: $($group.Name) in $groupPath"
            $groupCount++
        }
    }
    catch {
        Write-Log "Failed to create group '$($group.Name)': $_" "ERROR"
    }
}

Write-Host "  Groups processed: $groupCount created" -ForegroundColor Green

# --- Step 3: Create Users ---
Write-Host "`n--- Step 3: Creating Users ---" -ForegroundColor Yellow
$userCount = 0

foreach ($user in $config.Users) {
    $samAccountName = "$($user.FirstName).$($user.LastName)".ToLower()
    $upn = "$samAccountName@$((Get-ADDomain).DNSRoot)"
    $userPath = "OU=$($user.OU),$($config.DomainDN)"

    try {
        if (Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue) {
            Write-Log "User already exists: $samAccountName" "WARN"
            continue
        }

        if ($PSCmdlet.ShouldProcess($samAccountName, "Create User")) {
            # Generate a random password for each user
            $randomBytes = New-Object byte[] 24
            ([System.Security.Cryptography.RandomNumberGenerator]::Create()).GetBytes($randomBytes)
            $base64 = [Convert]::ToBase64String($randomBytes)
            # Insert required complexity characters at random positions
            $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
            $posBytes = New-Object byte[] 3
            $rng.GetBytes($posBytes)
            $chars = $base64.ToCharArray()
            $positions = @($posBytes[0] % $chars.Length, $posBytes[1] % $chars.Length, $posBytes[2] % $chars.Length)
            $complexChars = @('!','@','#','$','%','^','&','*')
            $digits = @('2','3','4','5','6','7','8','9')
            $uppers = @('A','B','C','D','E','F','G','H','J','K','M','N')
            $pickBytes = New-Object byte[] 3
            $rng.GetBytes($pickBytes)
            $chars[$positions[0]] = $complexChars[$pickBytes[0] % $complexChars.Length]
            $chars[$positions[1]] = $digits[$pickBytes[1] % $digits.Length]
            $chars[$positions[2]] = $uppers[$pickBytes[2] % $uppers.Length]
            $randomPwd = -join $chars
            $password = ConvertTo-SecureString $randomPwd -AsPlainText -Force
            New-ADUser -Name "$($user.FirstName) $($user.LastName)" `
                -GivenName $user.FirstName -Surname $user.LastName `
                -SamAccountName $samAccountName -UserPrincipalName $upn `
                -Path $userPath -Title $user.Title -Department $user.OU `
                -AccountPassword $password -Enabled $true `
                -ChangePasswordAtLogon $true -ErrorAction Stop
            Write-Log "Created user: $samAccountName in $userPath"
            $userCount++
        }

        # Add user to groups
        foreach ($groupName in $user.Groups) {
            try {
                if ($PSCmdlet.ShouldProcess("$samAccountName -> $groupName", "Add to Group")) {
                    Add-ADGroupMember -Identity $groupName -Members $samAccountName -ErrorAction Stop
                    Write-Log "Added $samAccountName to group $groupName"
                }
            }
            catch {
                Write-Log "Failed to add $samAccountName to group '$groupName': $_" "ERROR"
            }
        }
    }
    catch {
        Write-Log "Failed to create user '$samAccountName': $_" "ERROR"
    }
}

Write-Host "  Users processed: $userCount created" -ForegroundColor Green

# --- Summary ---
Write-Host "`n=== Domain Structure Creation Complete ===" -ForegroundColor Green
Write-Host "  OUs created:    $ouCount" -ForegroundColor Cyan
Write-Host "  Groups created: $groupCount" -ForegroundColor Cyan
Write-Host "  Users created:  $userCount" -ForegroundColor Cyan
Write-Host "  Log file:       $logFile" -ForegroundColor Cyan
Write-Log "Domain structure creation complete. OUs=$ouCount Groups=$groupCount Users=$userCount"
