<#
.SYNOPSIS
    Converts various string representations to Boolean values.

.DESCRIPTION
    This function converts common string representations of true/false values 
    into proper Boolean types. It recognizes multiple formats including:
    - "yes"/"no", "y"/"n"
    - "true"/"false", "t"/"f"
    - "1"/"0"
    
    This is useful for parsing user input or configuration files.

.PARAMETER value
    The string value to convert to Boolean. Accepts values from pipeline.

.OUTPUTS
    System.Boolean
    Returns $true or $false based on the input value.

.EXAMPLE
    ConvertTo-Boolean "yes"
    Returns: $true

.EXAMPLE
    ConvertTo-Boolean "n"
    Returns: $false

.EXAMPLE
    "true" | ConvertTo-Boolean
    Returns: $true (demonstrates pipeline input)

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    
.LINK
    about_Type_Conversion
#>
function ConvertTo-Boolean {
    param
    (
      [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
      [string]$value
    )
    
    # Convert various string representations to Boolean
    switch ($value)
    {
      "y" { return $true; }
      "yes" { return $true; }
      "true" { return $true; }
      "t" { return $true; }
      1 { return $true; }
      "n" { return $false; }
      "no" { return $false; }
      "false" { return $false; }
      "f" { return $false; } 
      0 { return $false; }
    }
}
  