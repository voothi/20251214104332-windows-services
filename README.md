# Service State Manager

A PowerShell tool to manage Windows Service configurations by exporting their states to JSON and restoring them when needed.

## Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
    - [Exporting Services (Unload)](#exporting-services-unload)
    - [Restoring Services (Load)](#restoring-services-load)
- [Release Notes](#release-notes)
- [License](#license)

## Features
-   **State Export**: configurations (StartType and Status) of services can be saved to a lightweight JSON file.
-   **Selective Backup**: Filter exports to specific services by name.
-   **State Restoration**: Apply stored configurations to the system, automatically adjusting Startup Types and Service Status.
-   **Editable Config**: JSON output is human-readable and editable, allowing for "offline" configuration changes.

[Back to Top](#table-of-contents)

## Prerequisites
-   **Windows 10/11**
-   **PowerShell 5.1 or newer**
-   **Administrator Privileges** are required for the `Restore` function to change service states.

[Back to Top](#table-of-contents)

## Usage

### Exporting Services (Unload)
Save the state of services to a JSON file.

**Command:**
```powershell
.\ManageServices.ps1 -Mode Export -ServiceNames 'Spooler', 'AudioSrv'
```

-   **-ServiceNames**: (Optional) List of service names to export. If omitted, ALL services are exported.
-   **Output**: A file named `TIMESTAMP-windows-services.json` in the `.\out` directory.

### GUI Interface (ServiceManagerGUI)
For a visual interface to manage configurations:

**Command:**
```powershell
.\ServiceManagerGUI.ps1
```

-   **Features**: Load JSON, Batch Edit (Select Multiple -> Apply), Save, and Restore.
-   **Note**: The "Restore" button will prompt for Administrator privileges to apply changes.

### Restoring Services (Load)
Apply a configuration from a JSON file.

**Command:**
```powershell
.\ManageServices.ps1 -Mode Restore -ConfigPath '.\out\ServicesConfig_20251214_110903.json'
```

-   **-ConfigPath**: (Required) Path to the JSON configuration file.
-   **Action**: The script will iterate through the file and apply changes to `StartType` and `Status` if they differ from the current system state.

[Back to Top](#table-of-contents)

## Release Notes
See [RELEASE_NOTES.md](release-notes.md).

## License
[MIT](LICENSE)

[Back to Top](#table-of-contents)
