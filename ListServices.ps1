# Get the current date and time for a unique filename
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFile = ".\Windows11_Services_$timestamp.txt"

Write-Host "Reading Windows 11 Services and checking Registry for Triggers..." -ForegroundColor Cyan

# Get all services, sort them by DisplayName (like services.msc), and process each one
$servicesList = Get-Service | Sort-Object DisplayName | ForEach-Object {
    
    # Get basic properties
    $name = $_.Name
    $displayName = $_.DisplayName
    $status = $_.Status
    $baseStartType = $_.StartType # Automatic, Manual, or Disabled

    # Registry path where service config is stored
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$name"
    $triggerPath = "$regPath\TriggerInfo"
    
    # Default label is what Get-Service reports
    $finalStartType = "$baseStartType"

    # Check Registry to see if it's a "Trigger Start" service
    # We wrap this in try/catch in case of permission issues (though read is usually fine)
    try {
        if ($baseStartType -ne "Disabled") {
            if (Test-Path $triggerPath) {
                $finalStartType = "$baseStartType (Trigger Start)"
            }
        }
    }
    catch {
        # If we can't read the registry, keep the default StartType
    }

    # Create a custom object with the requested columns
    [PSCustomObject]@{
        Status        = $status
        Name          = $name
        DisplayName   = $displayName
        "Startup Type" = $finalStartType
    }
}

# Output to text file
$servicesList | Format-Table -AutoSize | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Done! The list has been saved to: $outputFile" -ForegroundColor Green