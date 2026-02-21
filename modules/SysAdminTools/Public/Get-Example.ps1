
function Get-Example {
<#
.SYNOPSIS
Example function.
.DESCRIPTION
Returns example object.
.EXAMPLE
Get-Example
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
#>
[CmdletBinding()]
param()
[pscustomobject]@{
    Name = "Example"
    Status = "OK"
}
}
