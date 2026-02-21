# PowerShell Style Guide

## Naming Conventions

-   Use approved verbs (Get-Verb)
-   PascalCase for functions
-   Descriptive parameter names

## Script Requirements

-   \#requires -Version 7.0
-   CmdletBinding()
-   SupportsShouldProcess when applicable

## Logging

-   Use Write-Verbose
-   Use Write-Warning
-   Use Write-Error
-   Avoid Write-Host unless UX specific

## Output

Return structured objects whenever possible.
