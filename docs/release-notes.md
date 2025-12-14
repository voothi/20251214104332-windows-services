# Release Notes

## v1.0.2

### Features
-   **Export Mode**: Added ability to export service states (StartType, Status) to JSON.
-   **Restore Mode**: Added ability to restore service states from JSON configuration files.
-   **Filtering**: implemented `-ServiceNames` parameter to target specific services during export.
-   **State Management**: Script now accurately manages `Set-Service` for Startup Types and `Start/Stop-Service` for running status.

### Changes
-   Renamed script from `ListServices.ps1` to `ManageServices.ps1` to reflect expanded capabilities.
-   Output format changed from textual table to structured JSON.
