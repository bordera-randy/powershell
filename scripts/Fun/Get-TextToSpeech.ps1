<#
.SYNOPSIS
    Converts text to speech using the Windows Speech Synthesizer.
.DESCRIPTION
    This script uses the .NET SpeechSynthesizer to read text aloud.
    Supports configurable voice, rate, and volume settings.
.PARAMETER Text
    The text to speak. Default is a greeting message.
.PARAMETER Rate
    Speech rate from -10 (slowest) to 10 (fastest). Default is 0.
.PARAMETER Volume
    Volume from 0 to 100. Default is 100.
.EXAMPLE
    .\Get-TextToSpeech.ps1 -Text "Hello from PowerShell!"
.EXAMPLE
    .\Get-TextToSpeech.ps1 -Text "Slow speech" -Rate -3
.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
    Source: Inspired by https://devblogs.microsoft.com/scripting/use-powershell-to-make-your-computer-talk/
            and https://learn.microsoft.com/en-us/dotnet/api/system.speech.synthesis.speechsynthesizer
    Requires: Windows with .NET Framework (System.Speech assembly)
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Text = "Hello! I am PowerShell, and I can talk!",

    [Parameter(Mandatory = $false)]
    [ValidateRange(-10, 10)]
    [int]$Rate = 0,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 100)]
    [int]$Volume = 100
)

Write-Host ""
Write-Host "  Text to Speech" -ForegroundColor Green
Write-Host "  ==============" -ForegroundColor Green
Write-Host ""

try {
    Add-Type -AssemblyName System.Speech -ErrorAction Stop

    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synth.Rate = $Rate
    $synth.Volume = $Volume

    Write-Host "  Speaking: " -NoNewline -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Yellow
    Write-Host "  Rate: $Rate | Volume: $Volume" -ForegroundColor DarkGray
    Write-Host ""

    $synth.Speak($Text)

    Write-Host "  Done speaking." -ForegroundColor Green
    $synth.Dispose()
}
catch {
    Write-Host "  Text-to-Speech requires Windows with System.Speech assembly." -ForegroundColor Yellow
    Write-Host "  On non-Windows systems, the text would be:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  '$Text'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  To install on Windows, ensure .NET Framework is available." -ForegroundColor DarkGray
}

Write-Host ""
