<#
.SYNOPSIS
    Generates a random string of characters.

.DESCRIPTION
    This function creates a random string by selecting random characters from a provided
    character set. Useful for generating passwords, test data, or random identifiers.

.PARAMETER length
    The length of the random string to generate.

.PARAMETER characters
    The character set to use for generating the random string. 
    Can be any string or array of characters.

.OUTPUTS
    System.String
    Returns a randomly generated string of the specified length.

.EXAMPLE
    Get-RandomCharacters -length 10 -characters "abcdefghijklmnopqrstuvwxyz"
    Returns a 10-character random lowercase string.

.EXAMPLE
    Get-RandomCharacters -length 16 -characters "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    Returns a 16-character random alphanumeric string (uppercase).

.EXAMPLE
    $chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    Get-RandomCharacters -length 8 -characters $chars
    Returns an 8-character random string of special characters.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    
.LINK
    Get-Random
#>
function Get-RandomCharacters($length, $characters) {
    # Generate an array of random indices based on the character set
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    
    # Set output field separator to empty string for clean concatenation
    $private:ofs=""
    
    # Return the randomly selected characters as a string
    return [String]$characters[$random]
}