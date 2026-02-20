# Cloud Administration Scripts

This directory groups cloud administration and management scripts by platform. These scripts help automate common tasks across Azure and Microsoft 365 environments, including resource management, auditing, reporting, and tenant discovery.

## Table of Contents

- [Subfolders](#subfolders)
- [Getting Started](#getting-started)
- [Usage](#usage)

## Subfolders

| Folder | Description |
|--------|-------------|
| [Azure](./Azure/) | Azure resource management, security auditing, VM operations, storage, RBAC, and network scripts |
| [Microsoft 365](./Microsoft365/) | Microsoft 365 user management, Exchange Online, Teams, SharePoint, licensing, and role auditing |

## Getting Started

Each subfolder contains its own README with prerequisites, available scripts, and detailed usage examples. Start with the platform you need:

- **Azure administrators** → [Azure README](./Azure/README.md)
- **Microsoft 365 administrators** → [Microsoft 365 README](./Microsoft365/README.md)

## Usage

```powershell
# Example: list Azure VMs
cd .\scripts\Cloud\Azure
.\Manage-AzureVMs.ps1 -Action List

# Example: list Microsoft 365 users
cd .\scripts\Cloud\Microsoft365
.\Manage-O365Users.ps1 -Action List
```
