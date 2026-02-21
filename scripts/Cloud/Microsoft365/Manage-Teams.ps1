<#
.SYNOPSIS
    Manage Microsoft Teams
.DESCRIPTION
    This script provides functions to manage Microsoft Teams including listing, creating, and managing teams.
    Requires Microsoft.Graph PowerShell module.
.EXAMPLE
    .\Manage-Teams.ps1 -Action List
    .\Manage-Teams.ps1 -Action Create -TeamName "Project Team" -Description "Team for project collaboration"
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("List","Info","Create","AddMember","RemoveMember","ListMembers")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$TeamName,
    
    [Parameter(Mandatory=$false)]
    [string]$TeamId,
    
    [Parameter(Mandatory=$false)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName
)

# Check if Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Teams)) {
    Write-Error "Microsoft.Graph.Teams module is not installed. Install it using: Install-Module -Name Microsoft.Graph -Scope CurrentUser"
    exit 1
}

Import-Module Microsoft.Graph.Teams -ErrorAction SilentlyContinue

function Get-TeamList {
    Write-Host "Retrieving all Teams..." -ForegroundColor Cyan
    
    try {
        $teams = Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All
        
        if ($teams.Count -eq 0) {
            Write-Host "No teams found." -ForegroundColor Yellow
            return
        }
        
        $teams | Format-Table DisplayName, Id, Description, Mail -AutoSize
        
        Write-Host "`nTotal Teams: $($teams.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve teams: $_"
        Write-Host "Make sure you're connected: Connect-MgGraph -Scopes 'Team.ReadBasic.All'" -ForegroundColor Yellow
    }
}

function Get-TeamInfo {
    param($Id)
    
    if (-not $Id) {
        Write-Error "TeamId is required for Info action."
        return
    }
    
    Write-Host "Getting information for team '$Id'..." -ForegroundColor Cyan
    
    try {
        $team = Get-MgTeam -TeamId $Id
        
        Write-Host "`nTeam Details:" -ForegroundColor Yellow
        Write-Host "  Display Name: $($team.DisplayName)"
        Write-Host "  Description: $($team.Description)"
        Write-Host "  Team ID: $($team.Id)"
        Write-Host "  Visibility: $($team.Visibility)"
        Write-Host "  Web URL: $($team.WebUrl)"
        
        # Get channels
        $channels = Get-MgTeamChannel -TeamId $Id
        Write-Host "`nChannels ($($channels.Count)):" -ForegroundColor Yellow
        $channels | Format-Table DisplayName, Description, MembershipType
    }
    catch {
        Write-Error "Failed to get team info: $_"
    }
}

function New-Team {
    param($Name, $Desc)
    
    if (-not $Name) {
        Write-Error "TeamName is required for Create action."
        return
    }
    
    Write-Host "Creating team '$Name'..." -ForegroundColor Cyan
    
    try {
        $teamParams = @{
            "DisplayName" = $Name
            "Description" = $Desc
            "AdditionalProperties" = @{
                "template@odata.bind" = "https://graph.microsoft.com/v1.0/teamsTemplates('standard')"
            }
        }
        
        $newTeam = New-MgTeam -BodyParameter $teamParams
        
        Write-Host "Team created successfully!" -ForegroundColor Green
        $newTeam | Format-List DisplayName, Id, Description
    }
    catch {
        Write-Error "Failed to create team: $_"
    }
}

function Add-TeamMember {
    param($Id, $UPN)
    
    if (-not $Id -or -not $UPN) {
        Write-Error "TeamId and UserPrincipalName are required for AddMember action."
        return
    }
    
    Write-Host "Adding user '$UPN' to team..." -ForegroundColor Cyan
    
    try {
        $user = Get-MgUser -UserId $UPN
        
        $memberParams = @{
            "@odata.type" = "#microsoft.graph.aadUserConversationMember"
            "roles" = @()
            "user@odata.bind" = "https://graph.microsoft.com/v1.0/users('$($user.Id)')"
        }
        
        New-MgTeamMember -TeamId $Id -BodyParameter $memberParams
        
        Write-Host "User added to team successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to add user to team: $_"
    }
}

function Remove-TeamMember {
    param($Id, $UPN)
    
    if (-not $Id -or -not $UPN) {
        Write-Error "TeamId and UserPrincipalName are required for RemoveMember action."
        return
    }
    
    Write-Host "Removing user '$UPN' from team..." -ForegroundColor Cyan
    
    try {
        $user = Get-MgUser -UserId $UPN
        $members = Get-MgTeamMember -TeamId $Id
        $memberToRemove = $members | Where-Object { $_.DisplayName -eq $user.DisplayName }
        
        if ($memberToRemove) {
            Remove-MgTeamMember -TeamId $Id -ConversationMemberId $memberToRemove.Id
            Write-Host "User removed from team successfully!" -ForegroundColor Green
        } else {
            Write-Host "User not found in team." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Failed to remove user from team: $_"
    }
}

function Get-TeamMemberList {
    param($Id)
    
    if (-not $Id) {
        Write-Error "TeamId is required for ListMembers action."
        return
    }
    
    Write-Host "Retrieving members for team..." -ForegroundColor Cyan
    
    try {
        $members = Get-MgTeamMember -TeamId $Id
        
        if ($members.Count -eq 0) {
            Write-Host "No members found." -ForegroundColor Yellow
            return
        }
        
        $members | Format-Table DisplayName, Email, Roles -AutoSize
        
        Write-Host "`nTotal Members: $($members.Count)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve team members: $_"
    }
}

# Main execution
Write-Host "Note: Connect to Microsoft Graph first: Connect-MgGraph -Scopes 'Team.ReadBasic.All','TeamMember.ReadWrite.All'" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    "List" { Get-TeamList }
    "Info" { Get-TeamInfo -Id $TeamId }
    "Create" { New-Team -Name $TeamName -Desc $Description }
    "AddMember" { Add-TeamMember -Id $TeamId -UPN $UserPrincipalName }
    "RemoveMember" { Remove-TeamMember -Id $TeamId -UPN $UserPrincipalName }
    "ListMembers" { Get-TeamMemberList -Id $TeamId }
}
