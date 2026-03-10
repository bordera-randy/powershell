<#
.SYNOPSIS
Converts a PFX certificate file to PEM format.

.DESCRIPTION
This script provides functionality to convert PFX (PKCS#12) certificate files to PEM (Privacy Enhanced Mail) format, which is commonly used in various applications and systems.

.PARAMETER InputPath
The file path to the source PFX certificate file.

.PARAMETER OutputPath
The file path where the converted PEM certificate will be saved.

.EXAMPLE
.\convert-to-pem.ps1 -InputPath "C:\certs\certificate.pfx" -OutputPath "C:\certs\certificate.pem"

.NOTES
Author: 
Date Created: 
This script may require OpenSSL or similar tools to be installed on the system.

.LINK

#>


[string]$PfxFilePath = "PATH-TO-PFX-FILE"
[string]$PfxPassword = $null 

 $datestamp = Get-Date -Format "yyyy-MM-dd"
 $LogDir = Split-Path -Path $PfxFilePath
 $LogFilePath = "$LogDir\$datestamp-convert-to-pem.log"

# Create log directory if it doesn't exist
$LogDir = Split-Path -Path $LogFilePath
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir 
}

# Function to write to log and console
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $LogFilePath -Value $logMessage
}

Write-Log "Starting PFX to PEM conversion..."
Write-Log "PFX File: $PfxFilePath"

try {
    # Validate PFX file exists
    if (-not (Test-Path $PfxFilePath)) {
        throw "PFX file not found: $PfxFilePath"
    }
    Write-Log "PFX file validated"

    # Convert PFX to PEM using OpenSSL
    $cert = "openssl pkcs12 -in `"$PfxFilePath`" -clcerts -nokeys -out `"$logDir\public.pem`" -password pass:`"$PfxPassword`""
    Invoke-Expression $cert

    $privatekey = "openssl pkcs12 -in `"$PfxFilePath`" -nocerts -nodes -out `"$logDir\key.pem`" -password pass:`"$PfxPassword`""
    Invoke-Expression $privatekey

    $x509Cmd = "openssl x509 -in `"$logDir\public.pem`" -out `"$logDir\x509.pem`" -outform PEM"
    Invoke-Expression $x509Cmd

Clear-Host

    if (Test-Path "$LogDir\public.pem") {
        Write-Log "✓ Certificate file created successfully" 
        Write-Host "✓ Certificate file created successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Certificate file was not created" -ForegroundColor Red
        throw "✗ Certificate file was not created"
    }
    if (Test-Path "$LogDir\key.pem") {
        Write-Log "✓ Private key file created successfully" 
        Write-Host "✓ Private key file created successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Private key file was not created" -ForegroundColor Red
        throw "✗ Private key file was not created"
    }
    if (Test-Path "$logdir\x509.pem") {
        Write-Log "✓ X.509 certificate file created successfully" 
        Write-Host "✓ X.509 certificate file created successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ X.509 certificate file was not created" -ForegroundColor Red
        throw "✗ X.509 certificate file was not created"
    }

    # Validate certificates using OpenSSL
    Write-Host "Validating certificates with OpenSSL..." -ForegroundColor Yellow
    $validateCmd = "openssl x509 -in `"$logDir\x509.pem`" -text -noout"
    $output = & cmd /c $validateCmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "✓ Certificate validation passed" 
        Write-Host "✓ Certificate validation passed" -ForegroundColor Green
    } else {
        Write-Log "⚠ Certificate validation warning: $output" 
        Write-Host "⚠ Certificate validation: $output" -ForegroundColor Yellow
    }

    Write-Log "✓ Conversion and validation completed successfully" 
    Write-Host "✓ All conversions completed successfully!" -ForegroundColor Green
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" 
    Write-Host "✗ Conversion failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

