# Getting Started

## Prereqs
- PowerShell 7+
- Git

## Clone
```bash
git clone https://github.com/<YOUR_GITHUB_ORG_OR_USER>/powershell-sysadmin-scripts.git
cd powershell-sysadmin-scripts
```

## Run a script
```powershell
./scripts/Networking/Some-Script.ps1 -Verbose
```

## Import the module
```powershell
Import-Module ./modules/SysAdminTools/SysAdminTools.psd1 -Force
Get-Command -Module SysAdminTools
```

## Build docs (PlatyPS)
```powershell
./build.ps1 -Task Docs
```

This generates:
- Markdown help under `docs/help/SysAdminTools`
- Compiled help XML under `docs/help/SysAdminTools/en-US`
