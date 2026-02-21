<#
.SYNOPSIS
    Set email and proxy addresses for Active Directory users.
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
#>
Import-Module ActiveDirectory
$users = Get-ADUser -Filter *
foreach ($user in $users)
{
$email = $user.samaccountname + '@domainName.com'
$newemail = "SMTP:"+$email
Set-ADUser $user -Add @{proxyAddresses = ($newemail)}
}