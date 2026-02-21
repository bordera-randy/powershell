<#
.SYNOPSIS
    Executes a REST API call with logging and optional output capture.

.DESCRIPTION
    Wraps Invoke-RestMethod with common parameters and logs request details,
    response status, and output location. Supports JSON payloads and file output.

.PARAMETER Method
    HTTP method: GET, POST, PUT, PATCH, DELETE.

.PARAMETER Uri
    Target endpoint URI.

.PARAMETER Headers
    Hashtable of headers to include (e.g., @{ Authorization = "Bearer <token>" }).

.PARAMETER Body
    Request body as string (JSON recommended for APIs).

.PARAMETER ContentType
    Content-Type header for the request body (default: application/json).

.PARAMETER OutFile
    Optional file to save the raw response.

.PARAMETER OutputDirectory
    Directory to write log files (default: <script>\logs).

.EXAMPLE
    .\Invoke-RestApi.ps1 -Method GET -Uri "https://api.github.com/repos/bordera-randy/PowerShell-Utility"

.EXAMPLE
    .\Invoke-RestApi.ps1 -Method POST -Uri "https://api.example.com/items" -Body '{"name":"test"}'

.NOTES
    Author: Randy Bordeaux
    GitHub: https://github.com/bordera-randy
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("GET","POST","PUT","PATCH","DELETE")]
    [string]$Method,

    [Parameter(Mandatory = $true)]
    [string]$Uri,

    [Parameter(Mandatory = $false)]
    [hashtable]$Headers,

    [Parameter(Mandatory = $false)]
    [string]$Body,

    [Parameter(Mandatory = $false)]
    [string]$ContentType = "application/json",

    [Parameter(Mandatory = $false)]
    [string]$OutFile,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "logs")
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputDirectory "Invoke-RestApi_$timestamp.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

Write-Log "Starting REST call: $Method $Uri" "INFO"

try {
    $params = @{ Method = $Method; Uri = $Uri; ErrorAction = "Stop" }
    if ($Headers) { $params.Headers = $Headers }
    if ($Body) {
        $params.Body = $Body
        $params.ContentType = $ContentType
    }

    $response = Invoke-RestMethod @params

    if ($OutFile) {
        $response | Out-File -FilePath $OutFile -Encoding UTF8
        Write-Log "Response saved to $OutFile" "INFO"
    }

    Write-Log "REST call completed successfully" "INFO"
    $response
}
catch {
    Write-Log "REST call failed: $_" "ERROR"
    throw
}
