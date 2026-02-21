# PowerShell Utility Scripts

A curated collection of PowerShell scripts for system administrators and cloud engineers.
These scripts focus on repeatable tasks, clear output, and safe defaults.

## Table of Contents

- [PowerShell Utility Scripts](#powershell-utility-scripts)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
  - [Repository Structure](#repository-structure)
  - [Installation](#installation)
  - [Script Categories](#script-categories)
    - [Cloud Scripts](#cloud-scripts)
    - [System Administration Scripts](#system-administration-scripts)
    - [Fun Scripts](#fun-scripts)
    - [Functions](#functions)
  - [Logging](#logging)
  - [Usage Examples](#usage-examples)
  - [Contributing](#contributing)
  - [License](#license)

## About

This repository provides practical PowerShell automation for:

- Azure and Microsoft 365 administration
- Windows system management
- Reporting and auditing
- Everyday admin utilities

Scripts include comment-based help, console progress messages, and log files where appropriate.

## Repository Structure

```
PowerShell/
├── scripts/
│   ├── Cloud/
│   │   ├── Azure/          # Azure VM, storage, RBAC, security, and network auditing
│   │   └── Microsoft365/   # M365 user, license, mailbox, SharePoint, and role management
│   ├── SystemAdmin/        # AD management, network scanning, patching, auditing, and event logs
│   └── Fun/
├── functions/
├── about.md
└── README.md
```

## Installation

```powershell
# Clone the repository
git clone https://github.com/bordera-randy/PowerShell.git

# Navigate to the project directory
cd PowerShell

# Set execution policy if needed (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Script Categories

### Cloud Scripts

- **Azure**: `scripts/Cloud/Azure/`
- **Microsoft 365**: `scripts/Cloud/Microsoft365/`

See the folder READMEs for full lists and usage:
- `scripts/Cloud/README.md`
- `scripts/Cloud/Azure/README.md`
- `scripts/Cloud/Microsoft365/README.md`

### System Administration Scripts

Location: `scripts/SystemAdmin/`

### Fun Scripts

Location: `scripts/Fun/`

### Functions

Reusable helper functions and utilities:

- `functions/`

## Logging

Many scripts create logs under their local `logs/` folder. Logs are ignored by git.

## Usage Examples

```powershell
# Run a script
cd .\scripts\SystemAdmin
.\Monitor-DiskSpace.ps1

# Azure script example
cd .\scripts\Cloud\Azure
Connect-AzAccount
.\Manage-AzureVMs.ps1 -Action List

# Get help for a script
Get-Help .\Manage-AzureVMs.ps1 -Full
```

## Contributing

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes.
4. Test your scripts thoroughly.
5. Commit your changes (`git commit -m 'Add some feature'`).
6. Push to the branch (`git push origin feature-branch`).
7. Open a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
