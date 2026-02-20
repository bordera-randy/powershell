<#
.SYNOPSIS
    Scrambles the characters in a string randomly.

.DESCRIPTION
    This function takes an input string and randomly rearranges its characters.
    Useful for generating anagrams, obfuscating text, or creating test data.

.PARAMETER inputString
    The string to scramble.

.OUTPUTS
    System.String
    Returns the input string with characters in random order.

.EXAMPLE
    Scramble-String "hello"
    Returns: "olleh" (or any other random arrangement)

.EXAMPLE
    Scramble-String "PowerShell"
    Returns: "hlSorePwle" (or any other random arrangement)

.EXAMPLE
    $text = "The quick brown fox"
    Scramble-String $text
    Returns the text with all characters randomly rearranged.

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    
.LINK
    Get-Random
#>
function Scramble-String([string]$inputString){
    # Convert string to character array
    $characterArray = $inputString.ToCharArray()
    
    # Randomly reorder the characters
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length
    
    # Join the scrambled characters back into a string
    $outputString = -join $scrambledStringArray
    
    # Return the scrambled string
    return $outputString 
}