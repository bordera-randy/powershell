# Contributing Guidelines

## Table of Contents

- [Branching Strategy](#branching-strategy)
- [Pull Request Checklist](#pull-request-checklist)
- [Code Style](#code-style)
- [Writing New Scripts](#writing-new-scripts)
- [API-Powered Scripts](#api-powered-scripts)
- [Documentation](#documentation)
- [Testing](#testing)

## Branching Strategy

- `main` → stable
- `feature/*` → new features
- `fix/*` → bug fixes

## Pull Request Checklist

- Code passes PSScriptAnalyzer
- Pester tests added or updated
- Help documentation included
- No secrets committed
- README updated if new scripts added

## Code Style

- Use `[CmdletBinding()]`
- Use `Verb-Noun` naming convention (run `Get-Verb` for approved verbs)
- Comment-based help is required for all scripts
- Use `#Requires -Version 5.1` or later where applicable

## Writing New Scripts

1. Start with comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`)
2. Add `[CmdletBinding()]` to every script
3. Use `param()` block for all inputs
4. Use `Write-Verbose` for diagnostic output, not `Write-Host`
5. Return structured `[PSCustomObject]` when producing data output
6. Validate parameters with `[ValidateSet(...)]`, `[ValidateRange(...)]`, etc.
7. Include a meaningful `.NOTES` block with Author and Version

## API-Powered Scripts

Scripts that call external APIs should follow this pattern:

```powershell
# Try the API first
$result = $null
try {
    $result = Invoke-RestMethod -Uri "https://api.example.com/endpoint" -TimeoutSec 10
}
catch {
    Write-Verbose "API unavailable, using built-in fallback: $_"
}

# Fall back gracefully
if (-not $result) {
    $result = $fallbackData | Get-Random
}
```

- Always include a fallback array of built-in data
- Use `-TimeoutSec 10` to avoid hanging
- Use `Write-Verbose` (not `Write-Warning`) for API failure messages
- Never expose API keys in source code — document in the `.NOTES` block if a key is needed

## Documentation

- Each script directory must have a `README.md`
- README must include a Table of Contents
- Every script must have a section in its directory README
- Include usage examples that can be copy-pasted directly

## Testing

- Tests live in `tests/`
- Use [Pester](https://pester.dev/) for all tests
- Run `Invoke-Pester` before submitting a PR
- New module functions require Pester tests
