# PowerShell SysAdmin Scripts

Welcome 👋

This repo contains **production-ready PowerShell** scripts and a reusable module (`SysAdminTools`) for common sysadmin tasks.

## Quick links
- **Scripts:** see `/scripts`
- **Module:** see `/modules/SysAdminTools`
- **Help:** generated with **PlatyPS** into `/docs/help`

## Typical workflow
1. Write or update a function in `modules/SysAdminTools/Public/`
2. Run tests + lint
3. Regenerate docs

```powershell
./build.ps1 -Task Docs
```

## Safety conventions
- Destructive actions should support `-WhatIf` / `-Confirm`
- No secrets in code or logs
- Prefer structured output (objects)
