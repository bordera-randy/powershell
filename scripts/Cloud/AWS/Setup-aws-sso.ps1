<#
.SYNOPSIS
  Bootstraps a Windows workstation for AWS + Terraform administration and installs aws-azure-login
  using Edge/Chrome (skipping Puppeteer's bundled Chromium download).
  Logs all actions to C:\Temp\aws-terraform-bootstrap.log
.DESCRIPTION
  This script performs the following steps:
   - Verifies admin rights
   - Installs core tools via winget (Node LTS, Git, AWS CLI v2, Terraform, VS Code, Docker Desktop)
   - (Optional) Installs kubectl, Helm, and AWS Session Manager Plugin
   - Sets PUPPETEER env vars to skip Chromium download and use an existing browser
   - Installs aws-azure-login globally via npm
   - Verifies commands are available

.NOTES
  - Run in an elevated PowerShell (Run as Administrator).
  - You may need to close/reopen PowerShell after installs for PATH refresh.
  - If your org blocks winget, install those tools via your software center and rerun from "Step 3".
#>

# ===============================
# CONFIG
# ===============================
$LogPath = "C:\Temp\aws-terraform-bootstrap.log"

# Ensure log directory exists
if (-not (Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
}

Start-Transcript -Path $LogPath -Append

try {

    Write-Host "==== Starting AWS/Terraform Bootstrap ====" -ForegroundColor Cyan

    # -------------------------------
    # Admin Check
    # -------------------------------
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "This script must be run as Administrator."
    }

    # -------------------------------
    # Install Core Toolchain
    # -------------------------------
    Write-Host "Installing core tools via winget..."

    winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
    winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements
    winget install -e --id Amazon.AWSCLI --accept-package-agreements --accept-source-agreements
    winget install -e --id Hashicorp.Terraform --accept-package-agreements --accept-source-agreements
    winget install -e --id Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements
    winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements

    # Optional tools
    winget install -e --id Kubernetes.kubectl --accept-package-agreements --accept-source-agreements
    winget install -e --id Helm.Helm --accept-package-agreements --accept-source-agreements
    winget install -e --id Amazon.SessionManagerPlugin --accept-package-agreements --accept-source-agreements

    # Refresh PATH
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [Environment]::GetEnvironmentVariable("Path", "User")

    Write-Host "Verifying installations..."

    node -v
    npm -v
    git --version
    aws --version
    terraform -version

    # -------------------------------
    # Configure Puppeteer
    # -------------------------------
    Write-Host "Configuring Puppeteer to use existing browser..."

    $edge1   = "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe"
    $edge2   = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
    $chrome1 = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
    $chrome2 = "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"

    $browser = @($edge1,$edge2,$chrome1,$chrome2) |
               Where-Object { Test-Path $_ } |
               Select-Object -First 1

    if (-not $browser) {
        throw "No Edge or Chrome installation found."
    }

    Write-Host "Using browser: $browser"

    [Environment]::SetEnvironmentVariable("PUPPETEER_SKIP_DOWNLOAD","true","Machine")
    [Environment]::SetEnvironmentVariable("PUPPETEER_EXECUTABLE_PATH",$browser,"Machine")

    $env:PUPPETEER_SKIP_DOWNLOAD="true"
    $env:PUPPETEER_EXECUTABLE_PATH=$browser

    # -------------------------------
    # Install aws-azure-login
    # -------------------------------
    Write-Host "Installing aws-azure-login..."

    npm uninstall -g aws-azure-login -ErrorAction SilentlyContinue
    npm cache verify
    npm install -g aws-azure-login

    aws-azure-login --help

    Write-Host "==== Bootstrap Completed Successfully ====" -ForegroundColor Green
    Write-Host "Next Step: Run 'aws-azure-login --mode=gui'" -ForegroundColor Yellow

}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    Stop-Transcript
}