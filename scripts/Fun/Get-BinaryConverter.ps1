<#
.SYNOPSIS
    Converts text to binary representation and vice versa.
.DESCRIPTION
    This script converts plain text to its binary (base-2) representation
    and can also decode binary back to text. Shows each character's
    ASCII value and binary equivalent.
.PARAMETER Text
    The text to convert to binary.
.PARAMETER Binary
    A binary string to convert back to text. Use spaces between bytes.
.PARAMETER ShowTable
    Show a detailed conversion table with ASCII values.
.EXAMPLE
    .\Get-BinaryConverter.ps1 -Text "Hello"
.EXAMPLE
    .\Get-BinaryConverter.ps1 -Binary "01001000 01101001"
.EXAMPLE
    .\Get-BinaryConverter.ps1 -Text "PowerShell" -ShowTable
.NOTES
    Author: PowerShell Utility Collection
    Version: 1.0
    Source: Inspired by https://www.rapidtables.com/convert/number/ascii-to-binary.html
            and https://devblogs.microsoft.com/scripting/
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Text,

    [Parameter(Mandatory = $false)]
    [string]$Binary,

    [Parameter(Mandatory = $false)]
    [switch]$ShowTable
)

function ConvertTo-BinaryString {
    param([string]$InputText)

    $result = @()
    foreach ($char in $InputText.ToCharArray()) {
        $ascii = [int][char]$char
        $bin = [Convert]::ToString($ascii, 2).PadLeft(8, '0')
        $result += @{
            Char   = $char
            ASCII  = $ascii
            Binary = $bin
        }
    }
    return $result
}

function ConvertFrom-BinaryString {
    param([string]$InputBinary)

    $bytes = $InputBinary.Trim() -split '\s+'
    $result = ""
    foreach ($byte in $bytes) {
        $byte = $byte.Trim()
        if ($byte.Length -eq 8 -and $byte -match '^[01]+$') {
            $ascii = [Convert]::ToInt32($byte, 2)
            $result += [char]$ascii
        }
    }
    return $result
}

Write-Host ""
Write-Host "  Binary Converter" -ForegroundColor Green
Write-Host "  ================" -ForegroundColor Green
Write-Host ""

if ($Text) {
    $converted = ConvertTo-BinaryString -InputText $Text
    $binaryStr = ($converted | ForEach-Object { $_.Binary }) -join ' '

    Write-Host "  Text:   $Text" -ForegroundColor Cyan
    Write-Host "  Binary: $binaryStr" -ForegroundColor Yellow
    Write-Host ""

    if ($ShowTable) {
        Write-Host "  ┌──────┬───────┬──────────┐" -ForegroundColor DarkGray
        Write-Host "  │ Char │ ASCII │  Binary   │" -ForegroundColor DarkGray
        Write-Host "  ├──────┼───────┼──────────┤" -ForegroundColor DarkGray
        foreach ($item in $converted) {
            $charDisplay = if ($item.Char -eq ' ') { 'SPC' } else { " $($item.Char) " }
            Write-Host "  │ $($charDisplay.PadRight(4)) │  $($item.ASCII.ToString().PadLeft(3))  │ $($item.Binary) │" -ForegroundColor White
        }
        Write-Host "  └──────┴───────┴──────────┘" -ForegroundColor DarkGray
        Write-Host ""
    }
}
elseif ($Binary) {
    $decoded = ConvertFrom-BinaryString -InputBinary $Binary
    Write-Host "  Binary: $Binary" -ForegroundColor Yellow
    Write-Host "  Text:   $decoded" -ForegroundColor Cyan
}
else {
    # Demo
    $demoText = "Hi!"
    $converted = ConvertTo-BinaryString -InputText $demoText
    $binaryStr = ($converted | ForEach-Object { $_.Binary }) -join ' '

    Write-Host "  Demo: '$demoText' in binary" -ForegroundColor Cyan
    Write-Host "  Binary: $binaryStr" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Usage:" -ForegroundColor DarkGray
    Write-Host "    .\Get-BinaryConverter.ps1 -Text 'Hello World'" -ForegroundColor DarkGray
    Write-Host "    .\Get-BinaryConverter.ps1 -Binary '01001000 01101001'" -ForegroundColor DarkGray
    Write-Host "    .\Get-BinaryConverter.ps1 -Text 'ABC' -ShowTable" -ForegroundColor DarkGray
}

Write-Host ""
