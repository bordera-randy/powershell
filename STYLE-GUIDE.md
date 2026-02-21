# PowerShell Style Guide

## Table of Contents

- [Naming Conventions](#naming-conventions)
- [Script Requirements](#script-requirements)
- [Parameters](#parameters)
- [Logging and Output](#logging-and-output)
- [Error Handling](#error-handling)
- [API Calls](#api-calls)
- [Output](#output)
- [Example Script Template](#example-script-template)

## Naming Conventions

- Use approved verbs: run `Get-Verb` to see the full list
- Use `PascalCase` for functions and script names (e.g., `Get-SystemInfo`)
- Use descriptive parameter names (e.g., `-ComputerName`, not `-CN`)
- Script files: `Verb-Noun.ps1`

## Script Requirements

- `[CmdletBinding()]` is required on all scripts and functions
- Use `#Requires -Version 5.1` (or the minimum version your script needs)
- Use `SupportsShouldProcess` and `$PSCmdlet.ShouldProcess()` for any action that modifies state

## Parameters

- Declare all inputs in a `param()` block
- Use `[Parameter(Mandatory = $true)]` for required inputs
- Use validation attributes: `[ValidateSet(...)]`, `[ValidateRange(...)]`, `[ValidateNotNullOrEmpty()]`
- Provide defaults where sensible

## Logging and Output

- Use `Write-Verbose` for diagnostic output (visible with `-Verbose`)
- Use `Write-Warning` for non-critical issues
- Use `Write-Error` for errors
- `Write-Host` is acceptable only for interactive/UX-specific display scripts (e.g., `scripts/Fun/`)
- Do **not** use `Write-Host` in module functions or scripts intended for automation pipelines

## Error Handling

- Use `try/catch` for operations that may fail (network calls, file I/O, AD queries)
- API scripts must include a graceful fallback (see [CONTRIBUTING.md](CONTRIBUTING.md))
- Always include meaningful error messages

```powershell
try {
    $data = Invoke-RestMethod -Uri $uri -TimeoutSec 10
}
catch {
    Write-Error "Failed to reach API: $_"
    return
}
```

## API Calls

- Use `Invoke-RestMethod` (not `Invoke-WebRequest`) when consuming JSON APIs
- Always set `-TimeoutSec` to avoid indefinite hangs
- Include a built-in fallback array for offline scenarios
- Never hardcode API keys — use parameters or environment variables

## Output

- Return structured objects whenever possible:

```powershell
return [PSCustomObject]@{
    Name   = $name
    Status = $status
}
```

- Avoid writing directly to the pipeline in the middle of a function unless intentional

## Example Script Template

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Brief one-line description.
.DESCRIPTION
    Longer description of what the script does.
.PARAMETER ParameterName
    Description of the parameter.
.EXAMPLE
    .\Verb-Noun.ps1 -ParameterName Value
.NOTES
    Author: Your Name
    Version: 1.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ParameterName = "DefaultValue"
)

# Script logic here
