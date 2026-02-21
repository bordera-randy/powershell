
<#
.SYNOPSIS
    Force modern authentication on Outlook clients.
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
#>
# Force modern authentication on Outlook 2013
reg add HKCU\SOFTWARE\Microsoft\Office\15.0\Common\Identity /t REG_DWORD /v EnableADAL /d 1 /f
reg add HKCU\SOFTWARE\Microsoft\Office\15.0\Common\Identity /t REG_DWORD /v Version /d 1 /f


