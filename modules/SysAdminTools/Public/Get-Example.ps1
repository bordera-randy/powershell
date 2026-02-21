
function Get-Example {
<#
.SYNOPSIS
Example function.
.DESCRIPTION
Returns example object.
.EXAMPLE
Get-Example
#>
[CmdletBinding()]
param()
[pscustomobject]@{
    Name = "Example"
    Status = "OK"
}
}
