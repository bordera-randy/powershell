<#
.SYNOPSIS
    Converts text to Morse code and vice versa.
.DESCRIPTION
    This script converts plain text to Morse code representation using dots
    and dashes. Can also convert Morse code back to text.
.PARAMETER Text
    The text to convert to Morse code.
.PARAMETER MorseCode
    Morse code string to convert back to text. Use spaces between letters
    and ' / ' between words.
.EXAMPLE
    .\Get-MorseCode.ps1 -Text "Hello World"
.EXAMPLE
    .\Get-MorseCode.ps1 -MorseCode ".... . .-.. .-.. --- / .-- --- .-. .-.. -.."
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Morse code reference from https://en.wikipedia.org/wiki/Morse_code
            and inspired by https://www.powershellgallery.com/
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Text,

    [Parameter(Mandatory = $false)]
    [string]$MorseCode
)

$morseMap = @{
    'A' = '.-';    'B' = '-...';  'C' = '-.-.';  'D' = '-..';
    'E' = '.';     'F' = '..-.';  'G' = '--.';   'H' = '....';
    'I' = '..';    'J' = '.---';  'K' = '-.-';   'L' = '.-..';
    'M' = '--';    'N' = '-.';    'O' = '---';   'P' = '.--.';
    'Q' = '--.-';  'R' = '.-.';   'S' = '...';   'T' = '-';
    'U' = '..-';   'V' = '...-';  'W' = '.--';   'X' = '-..-';
    'Y' = '-.--';  'Z' = '--..';
    '0' = '-----'; '1' = '.----'; '2' = '..---'; '3' = '...--';
    '4' = '....-'; '5' = '.....'; '6' = '-....'; '7' = '--...';
    '8' = '---..'; '9' = '----.';
    '.' = '.-.-.-'; ',' = '--..--'; '?' = '..--..'; '!' = '-.-.--';
    ' ' = '/'
}

# Create reverse map
$reverseMorse = @{}
foreach ($key in $morseMap.Keys) {
    $reverseMorse[$morseMap[$key]] = $key
}

function ConvertTo-Morse {
    param([string]$InputText)

    $result = ""
    foreach ($char in $InputText.ToUpper().ToCharArray()) {
        $charStr = [string]$char
        if ($morseMap.ContainsKey($charStr)) {
            $result += $morseMap[$charStr] + " "
        }
    }
    return $result.TrimEnd()
}

function ConvertFrom-Morse {
    param([string]$InputMorse)

    $result = ""
    $words = $InputMorse -split ' / '
    foreach ($word in $words) {
        $letters = $word.Trim() -split ' '
        foreach ($letter in $letters) {
            if ($reverseMorse.ContainsKey($letter)) {
                $result += $reverseMorse[$letter]
            }
        }
        $result += " "
    }
    return $result.TrimEnd()
}

Write-Host ""
Write-Host "  Morse Code Converter" -ForegroundColor Green
Write-Host "  ====================" -ForegroundColor Green
Write-Host ""

if ($Text) {
    $morse = ConvertTo-Morse -InputText $Text
    Write-Host "  Input:  $Text" -ForegroundColor Cyan
    Write-Host "  Morse:  $morse" -ForegroundColor Yellow
}
elseif ($MorseCode) {
    $text = ConvertFrom-Morse -InputMorse $MorseCode
    Write-Host "  Morse:  $MorseCode" -ForegroundColor Yellow
    Write-Host "  Text:   $text" -ForegroundColor Cyan
}
else {
    # Default demo
    $demoText = "SOS"
    $morse = ConvertTo-Morse -InputText $demoText
    Write-Host "  Demo: '$demoText' in Morse code" -ForegroundColor Cyan
    Write-Host "  Morse: $morse" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Usage:" -ForegroundColor DarkGray
    Write-Host "    .\Get-MorseCode.ps1 -Text 'Hello'" -ForegroundColor DarkGray
    Write-Host "    .\Get-MorseCode.ps1 -MorseCode '.... . .-.. .-.. ---'" -ForegroundColor DarkGray
}

Write-Host ""
