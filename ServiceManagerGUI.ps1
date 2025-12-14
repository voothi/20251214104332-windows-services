<#
.SYNOPSIS
    Service Manager GUI
    Interface for the ManageServices.ps1 script.
.DESCRIPTION
    Allows loading JSON configs, batch editing service states, saving changes,
    and invoking the underlying backup/restore script.
#>

Add-Type -AssemblyName PresentationFramework

# XAML Definition
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Service Manager GUI" Height="600" Width="900" Background="#1e1e1e" Foreground="White">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#333333"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="White"/>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="5"/>
        </Style>
    </Window.Resources>

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Top Bar: Load/Export -->
        <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Left" Margin="0,0,0,10">
            <Button Name="btnLoadConfig" Content="📂 Load Config File"/>
            <Button Name="btnExportNew" Content="⬇ Export New from System"/>
            <Label Name="lblCurrentFile" Content="No file loaded" VerticalAlignment="Center" FontStyle="Italic"/>
        </StackPanel>

        <!-- Search / Filter -->
        <Grid Grid.Row="1" Margin="0,0,0,10">
             <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Label Grid.Column="0" Content="Filter Services:"/>
            <TextBox Grid.Column="1" Name="txtFilter" Height="25" VerticalContentAlignment="Center"/>
        </Grid>

        <!-- Main Datagrid -->
        <DataGrid Grid.Row="2" Name="dgServices" AutoGenerateColumns="False" CanUserAddRows="False"
                  Background="#252526" RowBackground="#252526" AlternatingRowBackground="#2e2e2e"
                  Foreground="White" HeadersVisibility="Column" SelectionMode="Extended">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Name" Binding="{Binding Name}" IsReadOnly="True" Width="150"/>
                <DataGridTextColumn Header="Display Name" Binding="{Binding DisplayName}" IsReadOnly="True" Width="*"/>
                <DataGridTextColumn Header="Start Type" Binding="{Binding StartType}" Width="100"/>
                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="100"/>
            </DataGrid.Columns>
        </DataGrid>

        <!-- Action Panel (Batch Edit) -->
        <GroupBox Grid.Row="3" Header="Batch Edit Selected Services">
            <StackPanel Orientation="Horizontal" Margin="5">
                <Label Content="Set StartType:"/>
                <ComboBox Name="cmbStartType" Width="100" Margin="5">
                    <ComboBoxItem Content="-- No Change --" IsSelected="True"/>
                    <ComboBoxItem Content="Automatic"/>
                    <ComboBoxItem Content="Manual"/>
                    <ComboBoxItem Content="Disabled"/>
                </ComboBox>

                <Label Content="Set Status:"/>
                <ComboBox Name="cmbStatus" Width="100" Margin="5">
                    <ComboBoxItem Content="-- No Change --" IsSelected="True"/>
                    <ComboBoxItem Content="Running"/>
                    <ComboBoxItem Content="Stopped"/>
                </ComboBox>

                <Button Name="btnApplyEdit" Content="Apply to Selected" Background="#007acc"/>
            </StackPanel>
        </GroupBox>

        <!-- Bottom Bar: Save/Restore -->
        <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
            <Button Name="btnSaveConfig" Content="💾 Save Config As..."/>
            <Button Name="btnRestore" Content="🚀 RESTORE CONFIGURATION" Background="#2a9d8f" FontWeight="Bold"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Helper implementation for Reading/Writing
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Connect Elements by Name
$btnLoadConfig = $window.FindName("btnLoadConfig")
$btnExportNew = $window.FindName("btnExportNew")
$lblCurrentFile = $window.FindName("lblCurrentFile")
$dgServices = $window.FindName("dgServices")
$txtFilter = $window.FindName("txtFilter")
$btnApplyEdit = $window.FindName("btnApplyEdit")
$cmbStartType = $window.FindName("cmbStartType")
$cmbStatus = $window.FindName("cmbStatus")
$btnSaveConfig = $window.FindName("btnSaveConfig")
$btnRestore = $window.FindName("btnRestore")

# Global State
$global:currentServices = @()
$global:currentFilePath = ""

# --- Event Handlers ---

# Load Config
$btnLoadConfig.Add_Click({
        $dlg = New-Object Microsoft.Win32.OpenFileDialog
        $dlg.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
        $dlg.InitialDirectory = "$PSScriptRoot\out"
        if ($dlg.ShowDialog() -eq $true) {
            try {
                $global:currentServices = Get-Content -Path $dlg.FileName -Raw | ConvertFrom-Json
                # Ensure it's an array even if 1 item
                if (-not ($global:currentServices -is [array])) { $global:currentServices = @($global:currentServices) }
            
                $dgServices.ItemsSource = $global:currentServices
                $global:currentFilePath = $dlg.FileName
                $lblCurrentFile.Content = $dlg.FileName
            }
            catch {
                [System.Windows.MessageBox]::Show("Error loading file: $_", "Error", 0, 16)
            }
        }
    })

# Export New (Runs script)
$btnExportNew.Add_Click({
        $outDir = "$PSScriptRoot\out"
        if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
    
        # Run the script in a new window
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\ManageServices.ps1`" -Mode Export" -Wait
    
        [System.Windows.MessageBox]::Show("Export complete. Please load the new file from the 'out' directory.", "Info", 0, 64)
    })

# Filter Text Change
$txtFilter.Add_TextChanged({
        if ($global:currentServices) {
            $filter = $txtFilter.Text
            if ([string]::IsNullOrWhiteSpace($filter)) {
                $dgServices.ItemsSource = $global:currentServices
            }
            else {
                $dgServices.ItemsSource = $global:currentServices | Where-Object { $_.Name -match $filter -or $_.DisplayName -match $filter }
            }
        }
    })

# Apply Batch Edit
$btnApplyEdit.Add_Click({
        $selected = $dgServices.SelectedItems
        if ($selected.Count -eq 0) { return }

        $newStart = $cmbStartType.Text
        $newStatus = $cmbStatus.Text
    
        foreach ($item in $selected) {
            if ($newStart -ne "-- No Change --") { $item.StartType = $newStart }
            if ($newStatus -ne "-- No Change --") { $item.Status = $newStatus }
        }
        $dgServices.Items.Refresh()
    })

# Save Config
$btnSaveConfig.Add_Click({
        $dlg = New-Object Microsoft.Win32.SaveFileDialog
        $dlg.Filter = "JSON Files (*.json)|*.json"
        $dlg.FileName = "ModifiedConfig.json"
        $dlg.InitialDirectory = "$PSScriptRoot\out"
    
        if ($dlg.ShowDialog() -eq $true) {
            try {
                $jsonContent = $global:currentServices | ConvertTo-Json -Depth 2
                $jsonContent | Set-Content -Path $dlg.FileName -Encoding UTF8
                $global:currentFilePath = $dlg.FileName
                $lblCurrentFile.Content = $dlg.FileName
                [System.Windows.MessageBox]::Show("File saved successfully!", "Success", 0, 64)
            }
            catch {
                [System.Windows.MessageBox]::Show("Error saving file: $_", "Error", 0, 16)
            }
        }
    })

# Restore Config
$btnRestore.Add_Click({
        if (-not $global:currentFilePath) {
            [System.Windows.MessageBox]::Show("Please save or load a file first.", "Warning", 0, 48)
            return
        }

        $result = [System.Windows.MessageBox]::Show("Are you sure you want to RESTORE this configuration?`nRunning services may be stopped.", "Confirm Restore", 4, 32)
        if ($result -eq 'Yes') {
            Start-Process powershell -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$PSScriptRoot\ManageServices.ps1`" -Mode Restore -ConfigPath `"$global:currentFilePath`"" -Verb RunAs
        }
    })

# Show Window
$window.ShowDialog() | Out-Null
