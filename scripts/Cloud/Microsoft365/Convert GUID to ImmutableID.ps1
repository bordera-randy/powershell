<#
.SYNOPSIS
    Converts between GUID and ImmutableID formats for Azure AD synchronization.

.DESCRIPTION
    This script provides two functions to convert between ObjectGUID (from on-premises Active Directory)
    and ImmutableID (used in Azure AD) formats. These conversions are necessary when merging
    on-premises AD accounts with Azure AD accounts.
    
    - Convert-ImmutableID: Converts a Base64-encoded ImmutableID to GUID format
    - Convert-ObjectGUID: Converts a GUID to Base64-encoded ImmutableID format

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    
    Use Case: When synchronizing on-premises AD with Azure AD, you may need to match
    accounts by converting between these two identifier formats.
    
.LINK
    https://docs.microsoft.com/en-us/azure/active-directory/hybrid/plan-connect-design-concepts
    
.EXAMPLE
    Convert-ImmutableID -ImmutableID "bGl0dGxlIHN0cmluZw=="
    Converts the Base64-encoded ImmutableID to GUID format.

.EXAMPLE
    Convert-ObjectGUID -objectGUID "12345678-1234-1234-1234-123456789abc"
    Converts the GUID to Base64-encoded ImmutableID format.
#>

<#
.SYNOPSIS
    Converts ImmutableID to GUID format.

.DESCRIPTION
    Takes a Base64-encoded ImmutableID from Azure AD and converts it to standard GUID format.

.PARAMETER ImmutableID
    The Base64-encoded ImmutableID value from Azure AD.

.OUTPUTS
    System.Guid
    Returns the GUID representation of the ImmutableID.
#>
Function Convert-ImmutableID (
    [Parameter(Mandatory = $true)]
    [string]$ImmutableID
) { 
    # Convert Base64 string to GUID
    ([GUID][System.Convert]::FromBase64String($ImmutableID)).Guid
}

<#
.SYNOPSIS
    Converts ObjectGUID to ImmutableID format.

.DESCRIPTION
    Takes a GUID from on-premises Active Directory and converts it to Base64-encoded
    ImmutableID format used by Azure AD.

.PARAMETER ObjectGUID
    The GUID value from on-premises Active Directory.

.OUTPUTS
    System.String
    Returns the Base64-encoded ImmutableID string.
#>
Function Convert-ObjectGUID (
    [Parameter(Mandatory = $true)]
    [string]$ObjectGUID
) { 
    # Convert GUID to Base64-encoded ImmutableID
    [system.convert]::ToBase64String(([GUID]$ObjectGUID).ToByteArray())
}

# Example usage - replace with actual values
# Convert-ImmutableID -ImmutableID 'your-immutableid-here'
# Convert-ObjectGUID -objectGUID 'your-guid-here'