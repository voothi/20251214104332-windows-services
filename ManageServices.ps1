param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Export", "Restore")]
    [string]$Mode = "Export",

    [Parameter(Mandatory = $false)]
    [string[]]$ServiceNames,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

# Robustly handle ServiceNames if passed as a single comma-separated string
if ($ServiceNames.Count -eq 1 -and $ServiceNames[0] -match ',') {
    $ServiceNames = $ServiceNames[0] -split ',' | ForEach-Object { $_.Trim() }
}

# Function to get current date for filename
function Get-Timestamp {
    return Get-Date -Format "yyyyMMddHHmmss"
}

# --- Export Mode ---
if ($Mode -eq "Export") {
    # Determine output path
    if (-not $ConfigPath) {
        $outputDir = ".\out"
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir | Out-Null
        }
        $timestamp = Get-Timestamp
        $ConfigPath = "$outputDir\$timestamp-windows-services.json"
    }

    Write-Host "Exporting service states to '$ConfigPath'..." -ForegroundColor Cyan

    try {
        # Get services
        if ($ServiceNames) {
            Write-Host "Filtering for specific services: $($ServiceNames -join ', ')" -ForegroundColor Yellow
            $services = Get-Service -Name $ServiceNames -ErrorAction Stop
        }
        else {
            Write-Host "Exporting ALL services." -ForegroundColor Yellow
            $services = Get-Service
        }

        # Process and select properties
        $exportData = $services | Sort-Object DisplayName | ForEach-Object {
            $s = $_
            $name = $s.Name
            $baseStart = $s.StartType

            # Preserve the original logic for checking TriggerInfo for informational purposes
            # But for restoration, we primarily need the valid 'StartType' enum
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$name"
            $triggerPath = "$regPath\TriggerInfo"
            $isTriggerStart = $false
            if ($baseStart -ne "Disabled" -and (Test-Path $triggerPath)) {
                $isTriggerStart = $true
            }

            [PSCustomObject]@{
                Name        = $name
                DisplayName = $s.DisplayName
                Status      = $s.Status.ToString()
                StartType   = $baseStart.ToString()
                IsTrigger   = $isTriggerStart
            }
        }

        # Export to JSON
        $exportData | ConvertTo-Json -Depth 2 | Out-File -FilePath $ConfigPath -Encoding UTF8
        Write-Host "Success! Configuration saved to $ConfigPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to export services: $_"
    }
}

# --- Restore Mode ---
elseif ($Mode -eq "Restore") {
    if (-not $ConfigPath) {
        Write-Error "You must provide a -ConfigPath for Restore mode."
        exit
    }

    if (-not (Test-Path $ConfigPath)) {
        Write-Error "Config file not found: $ConfigPath"
        exit
    }

    Write-Host "Restoring service states from '$ConfigPath'..." -ForegroundColor Cyan

    try {
        $configData = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

        foreach ($item in $configData) {
            $serviceName = $item.Name
            $targetStartType = $item.StartType
            $targetStatus = $item.Status

            Write-Host "Processing Service: $serviceName" -NoNewline

            # Check if service exists
            if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
                $currentService = Get-Service -Name $serviceName
                
                # 1. Restore StartType
                if ($currentService.StartType -ne $targetStartType) {
                    Write-Host " | Changing StartType ($($currentService.StartType) -> $targetStartType)" -ForegroundColor Yellow -NoNewline
                    try {
                        Set-Service -Name $serviceName -StartupType $targetStartType -ErrorAction Stop
                    }
                    catch {
                        Write-Host " [ERROR Setting StartType]" -ForegroundColor Red -NoNewline
                    }
                }

                # 2. Restore Status
                if ($currentService.Status -ne $targetStatus) {
                    Write-Host " | Changing Status ($($currentService.Status) -> $targetStatus)" -ForegroundColor Magenta -NoNewline
                    try {
                        if ($targetStatus -eq "Running") {
                            Start-Service -Name $serviceName -ErrorAction Stop
                        }
                        elseif ($targetStatus -eq "Stopped") {
                            Stop-Service -Name $serviceName -ErrorAction Stop
                        }
                    }
                    catch {
                        Write-Host " [ERROR Changing Status]" -ForegroundColor Red -NoNewline
                    }
                }
                
                Write-Host " | Done"
            }
            else {
                Write-Host " | Service not found on this system." -ForegroundColor Red
            }
        }
        Write-Host "Restore operation completed." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to restore services from config: $_"
    }
}