<#
.SYNOPSIS
    Service Manager GUI
    Interface for the ManageServices.ps1 script.
.DESCRIPTION
    Allows loading JSON configs, batch editing service states, saving changes,
    and invoking the underlying backup/restore script.
    Includes a "Compare & Plan" tab for diffing configurations.
#>

Add-Type -AssemblyName PresentationFramework

# XAML Definition
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:sys="clr-namespace:System;assembly=mscorlib"
        Title="Service Manager GUI v1.1" Height="700" Width="1000" Background="#1e1e1e" Foreground="White">
    <Window.Resources>
        <x:Array x:Key="StartTypeOptions" Type="sys:String">
            <sys:String>Automatic</sys:String>
            <sys:String>Manual</sys:String>
            <sys:String>Disabled</sys:String>
        </x:Array>
        <x:Array x:Key="StatusOptions" Type="sys:String">
            <sys:String>Running</sys:String>
            <sys:String>Stopped</sys:String>
        </x:Array>

        <ControlTemplate x:Key="ComboBoxToggleButton" TargetType="ToggleButton">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition />
                    <ColumnDefinition Width="20" />
                </Grid.ColumnDefinitions>
                <Border x:Name="Border" Grid.ColumnSpan="2" Background="#333333" BorderBrush="#555555" BorderThickness="1" />
                <Path x:Name="Arrow" Grid.Column="1" Fill="White" HorizontalAlignment="Center" VerticalAlignment="Center" Data="M 0 0 L 4 4 L 8 0 Z"/>
            </Grid>
        </ControlTemplate>

        <Style TargetType="ComboBox">
             <Setter Property="Foreground" Value="White"/>
             <Setter Property="Background" Value="#333333"/>
             <Setter Property="BorderBrush" Value="#555555"/>
             <Setter Property="Template">
                 <Setter.Value>
                     <ControlTemplate TargetType="ComboBox">
                         <Grid>
                             <ToggleButton Name="ToggleButton" Template="{StaticResource ComboBoxToggleButton}" Grid.Column="2" Focusable="false" IsChecked="{Binding Path=IsDropDownOpen,Mode=TwoWay,RelativeSource={RelativeSource TemplatedParent}}" ClickMode="Press"/>
                             <ContentPresenter Name="ContentSite" IsHitTestVisible="False"  Content="{TemplateBinding SelectionBoxItem}" Margin="6,3,23,3" VerticalAlignment="Center" HorizontalAlignment="Left" />
                             <Popup Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
                                 <Grid Name="DropDown" SnapsToDevicePixels="True" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                     <Border x:Name="DropDownBorder" Background="#333333" BorderThickness="1" BorderBrush="#555555"/>
                                     <ScrollViewer Margin="4,6,4,6" SnapsToDevicePixels="True">
                                         <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained" />
                                     </ScrollViewer>
                                 </Grid>
                             </Popup>
                         </Grid>
                     </ControlTemplate>
                 </Setter.Value>
             </Setter>
        </Style>
        <Style TargetType="ComboBoxItem">
             <Setter Property="Background" Value="#333333"/>
             <Setter Property="Foreground" Value="White"/>
        </Style>

        <Style TargetType="Button">
            <Setter Property="Background" Value="#333333"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#555555"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="3">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#505050"/>
                                <Setter Property="BorderBrush" Value="#007acc"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#202020"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="White"/>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="5"/>
        </Style>
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="#333333"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="5"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
            <Setter Property="BorderBrush" Value="#555555"/>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="Background" Value="#2d2d30"/>
            <Setter Property="Foreground" Value="#cccccc"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border Name="Border" Background="{TemplateBinding Background}" BorderBrush="#3e3e42" BorderThickness="1,1,1,0" Margin="2,0,2,0" Padding="12,6">
                            <ContentPresenter x:Name="ContentSite" VerticalAlignment="Center" HorizontalAlignment="Center" ContentSource="Header"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#1e1e1e"/>
                                <Setter TargetName="Border" Property="BorderBrush" Value="#007acc"/>
                                <Setter TargetName="Border" Property="BorderThickness" Value="0,2,0,0"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="False">
                                <Setter TargetName="Border" Property="Background" Value="#2d2d30"/>
                                <Setter Property="Foreground" Value="#999999"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#3e3e42"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Style for Diff Rows -->
        <Style x:Key="DiffRowStyle" TargetType="DataGridRow">
            <Style.Triggers>
                <DataTrigger Binding="{Binding IsChanged}" Value="True">
                    <Setter Property="Background" Value="#4d1f1f"/> <!-- Reddish tint for changes -->
                    <Setter Property="Foreground" Value="White"/>
                </DataTrigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <TabControl Background="#1e1e1e" BorderThickness="0">
        
        <!-- TAP 1: MANAGE (Original) -->
        <TabItem Header=" 🛠 Manage ">
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
        </TabItem>

        <!-- TAB 2: COMPARE & PLAN -->
        <TabItem Header=" ⚖ Compare &amp; Plan ">
            <Grid Margin="10">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Loaders -->
                <Grid Grid.Row="0" Margin="0,0,0,10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <GroupBox Header="1. Baseline (Current State)" Grid.Column="0">
                        <StackPanel Orientation="Horizontal">
                            <Button Name="btnLoadBase" Content="📂 Load Baseline"/>
                            <Label Name="lblBaseFile" Content="None" FontStyle="Italic"/>
                        </StackPanel>
                    </GroupBox>
                    
                    <GroupBox Header="2. Plan (Target Config)" Grid.Column="1">
                        <StackPanel Orientation="Horizontal">
                            <Button Name="btnLoadPlan" Content="📂 Load Plan"/>
                            <Label Name="lblPlanFile" Content="None" FontStyle="Italic"/>
                        </StackPanel>
                    </GroupBox>
                </Grid>

                <!-- Controls -->
                 <Grid Grid.Row="1" Margin="0,0,0,10">
                    <StackPanel Orientation="Horizontal">
                         <Button Name="btnRunCompare" Content="⟳ Refresh Comparison" Background="#007acc"/>
                         <CheckBox Name="chkShowDiffs" Content="Show Differences Only" VerticalAlignment="Center" Margin="10,0,0,0" Foreground="White" IsChecked="True"/>
                    </StackPanel>
                </Grid>

                <!-- Diff Grid -->
                <DataGrid Grid.Row="2" Name="dgDiff" AutoGenerateColumns="False" CanUserAddRows="False"
                          Background="#252526" RowBackground="#252526" AlternatingRowBackground="#2e2e2e"
                          Foreground="White" HeadersVisibility="Column" SelectionMode="Single"
                          RowStyle="{StaticResource DiffRowStyle}">
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="Name" Binding="{Binding Name}" IsReadOnly="True" Width="150"/>
                        
                        <!-- Baseline Columns (Read Only) -->
                        <DataGridTextColumn Header="Base Start" Binding="{Binding BaseStart}" IsReadOnly="True" Width="80" Foreground="Gray"/>
                        <DataGridTextColumn Header="Base Status" Binding="{Binding BaseStatus}" IsReadOnly="True" Width="80" Foreground="Gray"/>
                        
                        <!-- Plan Columns (Editable) -->
                        <DataGridTemplateColumn Header="PLAN Start" Width="100">
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <ComboBox ItemsSource="{StaticResource StartTypeOptions}" SelectedValue="{Binding PlanStart, UpdateSourceTrigger=PropertyChanged}" FontWeight="Bold"/>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                        <DataGridTemplateColumn Header="PLAN Status" Width="100">
                            <DataGridTemplateColumn.CellTemplate>
                                <DataTemplate>
                                    <ComboBox ItemsSource="{StaticResource StatusOptions}" SelectedValue="{Binding PlanStatus, UpdateSourceTrigger=PropertyChanged}" FontWeight="Bold"/>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                    </DataGrid.Columns>
                </DataGrid>

                <!-- Save Plan -->
                <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
                    <Button Name="btnSavePlan" Content="💾 Save PLAN As New Version..." Background="#2a9d8f"/>
                </StackPanel>
            </Grid>
        </TabItem>

    </TabControl>
</Window>
"@

# Helper implementation for Reading/Writing
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# --- Elements: Manage Tab ---
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

# --- Elements: Compare Tab ---
$btnLoadBase = $window.FindName("btnLoadBase")
$lblBaseFile = $window.FindName("lblBaseFile")
$btnLoadPlan = $window.FindName("btnLoadPlan")
$lblPlanFile = $window.FindName("lblPlanFile")
$btnRunCompare = $window.FindName("btnRunCompare")
$chkShowDiffs = $window.FindName("chkShowDiffs")
$dgDiff = $window.FindName("dgDiff")
$btnSavePlan = $window.FindName("btnSavePlan")

# Global State
$global:currentServices = @()
$global:currentFilePath = ""

$global:baseData = $null
$global:planData = $null
$global:diffList = @()

# ==========================================
# TAB 1: MANAGE LOGIC
# ==========================================

$btnLoadConfig.Add_Click({
        $dlg = New-Object Microsoft.Win32.OpenFileDialog
        $dlg.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
        $dlg.InitialDirectory = "$PSScriptRoot\configs"
        if ($dlg.ShowDialog() -eq $true) {
            try {
                $global:currentServices = Get-Content -Path $dlg.FileName -Raw | ConvertFrom-Json
                if (-not ($global:currentServices -is [array])) { $global:currentServices = @($global:currentServices) }
                $dgServices.ItemsSource = $global:currentServices
                $global:currentFilePath = $dlg.FileName
                $lblCurrentFile.Content = $dlg.FileName
            }
            catch { [System.Windows.MessageBox]::Show("Error: $_", "Error", 0, 16) }
        }
    })

$btnExportNew.Add_Click({
        $outDir = "$PSScriptRoot\exports"
        if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\ManageServices.ps1`" -Mode Export -ConfigPath `"$outDir\$(Get-Date -Format 'yyyyMMddHHmmss')-windows-services.json`"" -Wait
        [System.Windows.MessageBox]::Show("Export complete. Check 'exports' folder.", "Info", 0, 64)
    })

$txtFilter.Add_TextChanged({
        if ($global:currentServices) {
            $filter = $txtFilter.Text
            if ([string]::IsNullOrWhiteSpace($filter)) { $dgServices.ItemsSource = $global:currentServices }
            else { $dgServices.ItemsSource = $global:currentServices | Where-Object { $_.Name -match $filter -or $_.DisplayName -match $filter } }
        }
    })

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

$btnSaveConfig.Add_Click({
        $dlg = New-Object Microsoft.Win32.SaveFileDialog
        $dlg.Filter = "JSON Files (*.json)|*.json"
        $dlg.FileName = "modified-config.json"
        $dlg.InitialDirectory = "$PSScriptRoot\configs"
        if ($dlg.ShowDialog() -eq $true) {
            try {
                $global:currentServices | ConvertTo-Json -Depth 2 | Set-Content -Path $dlg.FileName -Encoding UTF8
                $global:currentFilePath = $dlg.FileName
                $lblCurrentFile.Content = $dlg.FileName
                [System.Windows.MessageBox]::Show("Saved!", "Success", 0, 64)
            }
            catch { [System.Windows.MessageBox]::Show("Error: $_", "Error", 0, 16) }
        }
    })

$btnRestore.Add_Click({
        if (-not $global:currentFilePath) {
            [System.Windows.MessageBox]::Show("Save or load a file first.", "Warning", 0, 48)
            return
        }
        if ([System.Windows.MessageBox]::Show("RESTORE this configuration?`n(Requires Admin)", "Confirm", 4, 32) -eq 'Yes') {
            Start-Process powershell -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$PSScriptRoot\ManageServices.ps1`" -Mode Restore -ConfigPath `"$global:currentFilePath`"" -Verb RunAs
        }
    })

# ==========================================
# TAB 2: COMPARE LOGIC
# ==========================================

function Update-DiffGrid {
    if ($null -eq $global:baseData -or $null -eq $global:planData) { return }

    # Create a hashtable for quick lookup of PLAN data
    $planMap = @{}
    foreach ($p in $global:planData) { $planMap[$p.Name] = $p }

    $diffRows = @()

    foreach ($b in $global:baseData) {
        $p = $planMap[$b.Name]
        if ($null -eq $p) {
            # Service missing in Plan, skip or indicate missing
            continue 
        }

        # Compare keys
        $bStart = $b.StartType
        $pStart = $p.StartType
        $bStatus = $b.Status
        $pStatus = $p.Status

        $isChanged = ($bStart -ne $pStart) -or ($bStatus -ne $pStatus)

        # Create row object
        $row = New-Object PSObject
        $row | Add-Member -MemberType NoteProperty -Name "Name" -Value $b.Name
        $row | Add-Member -MemberType NoteProperty -Name "BaseStart" -Value $bStart
        $row | Add-Member -MemberType NoteProperty -Name "BaseStatus" -Value $bStatus
        
        # PLAN properties must be direct references to the Plan object to allow editing? 
        # Actually DataGrid editing updates the bound object. We should bind to a wrapper that syncs back or just use the wrapper.
        # Simple approach: Create a wrapper property that updates the underlying plan object on set? 
        # Too complex for quick script. 
        # Alternative: The "PlanStart" and "PlanStatus" are just strings. We save this $diffRows list as the new plan. 
        # Correct. We will export the DG source as the new plan.
        
        $row | Add-Member -MemberType NoteProperty -Name "PlanStart" -Value $pStart
        $row | Add-Member -MemberType NoteProperty -Name "PlanStatus" -Value $pStatus
        $row | Add-Member -MemberType NoteProperty -Name "IsChanged" -Value $isChanged
        # Keep detailed info for saving later
        $row | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $b.DisplayName
        $row | Add-Member -MemberType NoteProperty -Name "IsTrigger" -Value $b.IsTrigger 

        $diffRows += $row
    }

    $global:diffList = $diffRows

    # Filter View
    if ($chkShowDiffs.IsChecked) {
        $dgDiff.ItemsSource = $global:diffList | Where-Object { $_.IsChanged -eq $true }
    }
    else {
        $dgDiff.ItemsSource = $global:diffList
    }
}

$btnLoadBase.Add_Click({
        $dlg = New-Object Microsoft.Win32.OpenFileDialog
        $dlg.Title = "Select BASELINE Config (e.g. System Export)"
        $dlg.InitialDirectory = "$PSScriptRoot\exports"
        if ($dlg.ShowDialog() -eq $true) {
            try {
                $global:baseData = Get-Content -Path $dlg.FileName -Raw | ConvertFrom-Json
                if (-not ($global:baseData -is [array])) { $global:baseData = @($global:baseData) }
                $lblBaseFile.Content = $dlg.SafeFileName
                Update-DiffGrid
            }
            catch { [System.Windows.MessageBox]::Show("Error: $_", "Error", 0, 16) }
        }
    })

$btnLoadPlan.Add_Click({
        $dlg = New-Object Microsoft.Win32.OpenFileDialog
        $dlg.Title = "Select PLAN Config (e.g. Reference)"
        $dlg.InitialDirectory = "$PSScriptRoot\configs"
        if ($dlg.ShowDialog() -eq $true) {
            try {
                $global:planData = Get-Content -Path $dlg.FileName -Raw | ConvertFrom-Json
                if (-not ($global:planData -is [array])) { $global:planData = @($global:planData) }
                $lblPlanFile.Content = $dlg.SafeFileName
                Update-DiffGrid
            }
            catch { [System.Windows.MessageBox]::Show("Error: $_", "Error", 0, 16) }
        }
    })

$btnRunCompare.Add_Click({
        Update-DiffGrid
    })

$chkShowDiffs.Add_Checked({ Update-DiffGrid })
$chkShowDiffs.Add_Unchecked({ Update-DiffGrid })

$btnSavePlan.Add_Click({
        if ($null -eq $global:diffList -or $global:diffList.Count -eq 0) { return }

        $dlg = New-Object Microsoft.Win32.SaveFileDialog
        $dlg.Title = "Save New Plan Version"
        $dlg.FileName = "$(Get-Date -Format 'yyyyMMddHHmm')-new-plan.json"
        $dlg.InitialDirectory = "$PSScriptRoot\configs"
    
        if ($dlg.ShowDialog() -eq $true) {
            # Reconstruct standard JSON format from the Diff rows
            $finalExport = @()
            foreach ($row in $global:diffList) {
                $item = [PSCustomObject]@{
                    Name        = $row.Name
                    DisplayName = $row.DisplayName
                    Status      = $row.PlanStatus
                    StartType   = $row.PlanStart
                    IsTrigger   = $row.IsTrigger
                }
                $finalExport += $item
            }
        
            try {
                $finalExport | ConvertTo-Json -Depth 2 | Set-Content -Path $dlg.FileName -Encoding UTF8
                [System.Windows.MessageBox]::Show("Plan saved successfully!", "Success", 0, 64)
            }
            catch { [System.Windows.MessageBox]::Show("Error saving: $_", "Error", 0, 16) }
        }
    })

$window.ShowDialog() | Out-Null
