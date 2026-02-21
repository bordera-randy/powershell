<#
.SYNOPSIS
    Manage Office 365 Users
.DESCRIPTION
    This script provides functions to manage Office 365 users including creating, listing, and modifying users.
    Requires Microsoft.Graph PowerShell module.
.EXAMPLE
    .\Manage-O365Users.ps1 -Action List
    .\Manage-O365Users.ps1 -Action Create -UserPrincipalName "user@domain.com" -DisplayName "John Doe"
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("List","Info","Create","Disable","Enable","ResetPassword")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [string]$DisplayName,
    
    [Parameter(Mandatory=$false)]
    [string]$MailNickname
)

# Check if Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Write-Error "Microsoft.Graph.Users module is not installed. Install it using: Install-Module -Name Microsoft.Graph -Scope CurrentUser"
    exit 1
}

Import-Module Microsoft.Graph.Users -ErrorAction SilentlyContinue

function Get-O365UserList {
    Write-Host "Retrieving all Office 365 users..." -ForegroundColor Cyan
    
    try {
        $users = Get-MgUser -All -Property DisplayName,UserPrincipalName,Mail,AccountEnabled,UserType
        
        if ($users.Count -eq 0) {
            Write-Host "No users found." -ForegroundColor Yellow
            return
        }
        
        $users | Format-Table DisplayName, UserPrincipalName, Mail, AccountEnabled, UserType -AutoSize
        
        Write-Host "`nTotal Users: $($users.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve users: $_"
        Write-Host "Make sure you're connected: Connect-MgGraph -Scopes 'User.Read.All'" -ForegroundColor Yellow
    }
}

function Get-O365UserInfo {
    param($UPN)
    
    if (-not $UPN) {
        Write-Error "UserPrincipalName is required for Info action."
        return
    }
    
    Write-Host "Getting information for user '$UPN'..." -ForegroundColor Cyan
    
    try {
        $user = Get-MgUser -UserId $UPN -Property *
        
        Write-Host "`nUser Details:" -ForegroundColor Yellow
        Write-Host "  Display Name: $($user.DisplayName)"
        Write-Host "  User Principal Name: $($user.UserPrincipalName)"
        Write-Host "  Mail: $($user.Mail)"
        Write-Host "  Job Title: $($user.JobTitle)"
        Write-Host "  Department: $($user.Department)"
        Write-Host "  Office Location: $($user.OfficeLocation)"
        Write-Host "  Mobile Phone: $($user.MobilePhone)"
        Write-Host "  Account Enabled: $($user.AccountEnabled)"
        Write-Host "  User Type: $($user.UserType)"
        Write-Host "  Created: $($user.CreatedDateTime)"
    }
    catch {
        Write-Error "Failed to get user info: $_"
    }
}

function New-O365User {
    param($UPN, $DisplayName, $MailNickname)
    
    if (-not $UPN -or -not $DisplayName) {
        Write-Error "UserPrincipalName and DisplayName are required for Create action."
        return
    }
    
    if (-not $MailNickname) {
        $MailNickname = $UPN.Split('@')[0]
    }
    
    Write-Host "Creating user '$DisplayName' ($UPN)..." -ForegroundColor Cyan
    
    # Generate random password
    $PasswordProfile = @{
        Password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object {[char]$_})
        ForceChangePasswordNextSignIn = $true
    }
    
    try {
        $newUser = New-MgUser -UserPrincipalName $UPN `
                             -DisplayName $DisplayName `
                             -MailNickname $MailNickname `
                             -AccountEnabled $true `
                             -PasswordProfile $PasswordProfile
        
        Write-Host "User created successfully!" -ForegroundColor Green
        Write-Host "`nTemporary Password: $($PasswordProfile.Password)" -ForegroundColor Yellow
        Write-Host "User must change password on first sign-in." -ForegroundColor Yellow
        
        $newUser | Format-List DisplayName, UserPrincipalName, Id
    }
    catch {
        Write-Error "Failed to create user: $_"
    }
}

function Disable-O365User {
    param($UPN)
    
    if (-not $UPN) {
        Write-Error "UserPrincipalName is required for Disable action."
        return
    }
    
    Write-Host "Disabling user '$UPN'..." -ForegroundColor Cyan
    
    try {
        Update-MgUser -UserId $UPN -AccountEnabled:$false
        Write-Host "User disabled successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to disable user: $_"
    }
}

function Enable-O365User {
    param($UPN)
    
    if (-not $UPN) {
        Write-Error "UserPrincipalName is required for Enable action."
        return
    }
    
    Write-Host "Enabling user '$UPN'..." -ForegroundColor Cyan
    
    try {
        Update-MgUser -UserId $UPN -AccountEnabled:$true
        Write-Host "User enabled successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to enable user: $_"
    }
}

function Reset-O365UserPassword {
    param($UPN)
    
    if (-not $UPN) {
        Write-Error "UserPrincipalName is required for ResetPassword action."
        return
    }
    
    Write-Host "Resetting password for user '$UPN'..." -ForegroundColor Cyan
    
    # Generate random password
    $newPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object {[char]$_})
    
    $PasswordProfile = @{
        Password = $newPassword
        ForceChangePasswordNextSignIn = $true
    }
    
    try {
        Update-MgUser -UserId $UPN -PasswordProfile $PasswordProfile
        Write-Host "Password reset successfully!" -ForegroundColor Green
        Write-Host "`nTemporary Password: $newPassword" -ForegroundColor Yellow
        Write-Host "User must change password on next sign-in." -ForegroundColor Yellow
    }
    catch {
        Write-Error "Failed to reset password: $_"
    }
}

# Main execution
Write-Host "Note: Connect to Microsoft Graph first: Connect-MgGraph -Scopes 'User.ReadWrite.All'" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    "List" { Get-O365UserList }
    "Info" { Get-O365UserInfo -UPN $UserPrincipalName }
    "Create" { New-O365User -UPN $UserPrincipalName -DisplayName $DisplayName -MailNickname $MailNickname }
    "Disable" { Disable-O365User -UPN $UserPrincipalName }
    "Enable" { Enable-O365User -UPN $UserPrincipalName }
    "ResetPassword" { Reset-O365UserPassword -UPN $UserPrincipalName }
}
