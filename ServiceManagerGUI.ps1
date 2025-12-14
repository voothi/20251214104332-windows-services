<#
.SYNOPSIS
    Service Manager GUI
    Interface for the ManageServices.ps1 script.
.DESCRIPTION
    Unified Interface for managing and comparing Windows Service configurations.
    Allows loading a Baseline (System or File) and a Plan (File or Edit),
    comparing them, batch editing the Plan, and saving/restoring.
#>

Add-Type -AssemblyName PresentationFramework

# XAML Definition
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:sys="clr-namespace:System;assembly=mscorlib"
        Title="Service Manager GUI v1.1 - Unified Interface" Height="800" Width="1200" Background="#1e1e1e" Foreground="White">
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

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Loaders -->
            <RowDefinition Height="Auto"/> <!-- Batch Edit Plan -->
            <RowDefinition Height="*"/>    <!-- DataGrid -->
            <RowDefinition Height="Auto"/> <!-- Actions -->
        </Grid.RowDefinitions>

        <!-- 1. Configuration Loaders -->
        <Grid Grid.Row="0" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            
            <GroupBox Header="1. Baseline (Reference / Current System)" Grid.Column="0">
                <StackPanel Orientation="Horizontal">
                    <Button Name="btnLoadBaseSystem" Content="🖥 Load System State"/>
                    <Button Name="btnLoadBaseFile" Content="📂 Load From File"/>
                    <Label Name="lblBaseFile" Content="System State" FontStyle="Italic" VerticalAlignment="Center"/>
                </StackPanel>
            </GroupBox>
            
            <GroupBox Header="2. Plan (Target Configuration)" Grid.Column="1">
                <StackPanel Orientation="Horizontal">
                    <Button Name="btnCopyBaseToPlan" Content="📋 Copy Baseline"/>
                    <Button Name="btnLoadPlanFile" Content="📂 Load From File"/>
                    <Label Name="lblPlanFile" Content="Copy of Baseline" FontStyle="Italic" VerticalAlignment="Center"/>
                </StackPanel>
            </GroupBox>
        </Grid>

        <!-- 2. Batch Edit Plan -->
        <GroupBox Header="Batch Edit Plan" Grid.Row="1" Margin="0,0,0,10">
            <WrapPanel Orientation="Horizontal" VerticalAlignment="Center">
                <Label Content="Filter Name:"/>
                <TextBox Name="txtFilter" Width="150" Margin="5" Background="#333333" Foreground="White" BorderBrush="#555555"/>
                
                <Label Content="Set PLAN Start:" Margin="10,0,0,0"/>
                <ComboBox Name="cmbBatchStart" Width="100" Margin="5" ItemsSource="{StaticResource StartTypeOptions}"/>
                
                <Label Content="Set PLAN Status:" Margin="10,0,0,0"/>
                <ComboBox Name="cmbBatchStatus" Width="100" Margin="5" ItemsSource="{StaticResource StatusOptions}"/>
                
                <Button Name="btnApplyBatch" Content="Apply to Validated Rows" Background="#007acc"/>
                <Button Name="btnResetPlan" Content="Reset Plan to Baseline" Margin="10,0,0,0"/>
            </WrapPanel>
        </GroupBox>

        <!-- 3. Main DataGrid -->
        <DataGrid Grid.Row="2" Name="dgMain" AutoGenerateColumns="False" CanUserAddRows="False"
                  Background="#252526" RowBackground="#252526" AlternatingRowBackground="#2e2e2e"
                  Foreground="White" HeadersVisibility="Column" SelectionMode="Extended"
                  RowStyle="{StaticResource DiffRowStyle}">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Service Name" Binding="{Binding Name}" IsReadOnly="True" Width="200"/>
                <DataGridTextColumn Header="Display Name" Binding="{Binding DisplayName}" IsReadOnly="True" Width="200"/>
                
                <!-- Baseline Columns (Read Only) -->
                <DataGridTextColumn Header="Base Start" Binding="{Binding BaseStart}" IsReadOnly="True" Width="90" Foreground="#aaaaaa"/>
                <DataGridTextColumn Header="Base Status" Binding="{Binding BaseStatus}" IsReadOnly="True" Width="90" Foreground="#aaaaaa"/>
                
                <!-- Separator -->
                <DataGridTextColumn Header="||" IsReadOnly="True" Width="30" Foreground="#555555"/>

                <!-- Plan Columns (Editable) -->
                <DataGridTemplateColumn Header="PLAN Start" Width="110">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <ComboBox ItemsSource="{StaticResource StartTypeOptions}" SelectedValue="{Binding PlanStart, UpdateSourceTrigger=PropertyChanged}" FontWeight="Bold"/>
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                </DataGridTemplateColumn>
                <DataGridTemplateColumn Header="PLAN Status" Width="110">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <ComboBox ItemsSource="{StaticResource StatusOptions}" SelectedValue="{Binding PlanStatus, UpdateSourceTrigger=PropertyChanged}" FontWeight="Bold"/>
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                </DataGridTemplateColumn>
            </DataGrid.Columns>
        </DataGrid>

        <!-- 4. Actions -->
        <Grid Grid.Row="3" Margin="0,10,0,0">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <CheckBox Name="chkShowDiffs" Content="Show Differences Only" VerticalAlignment="Center" Margin="0,0,20,0" Foreground="White" IsChecked="True"/>
                <Button Name="btnExportSystem" Content="⬇ Export System State (Backup)" Background="#ca5100"/>
                <Button Name="btnSavePlan" Content="💾 Save Plan to File..." Background="#007acc" Margin="10,0,0,0"/>
                <Button Name="btnRestorePlan" Content="▶ Apply Plan to System" Background="#2d8a5e" Margin="10,0,0,0"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Left">
                <Label Name="lblStatus" Content="Ready." Foreground="Gray"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
"@

# Load Assembly and Window
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get Controls
$dgMain = $window.FindName("dgMain")
$btnLoadBaseSystem = $window.FindName("btnLoadBaseSystem")
$btnLoadBaseFile = $window.FindName("btnLoadBaseFile")
$btnCopyBaseToPlan = $window.FindName("btnCopyBaseToPlan")
$btnLoadPlanFile = $window.FindName("btnLoadPlanFile")
$lblBaseFile = $window.FindName("lblBaseFile")
$lblPlanFile = $window.FindName("lblPlanFile")
$txtFilter = $window.FindName("txtFilter")
$cmbBatchStart = $window.FindName("cmbBatchStart")
$cmbBatchStatus = $window.FindName("cmbBatchStatus")
$btnApplyBatch = $window.FindName("btnApplyBatch")
$btnResetPlan = $window.FindName("btnResetPlan")
$chkShowDiffs = $window.FindName("chkShowDiffs")
$btnExportSystem = $window.FindName("btnExportSystem")
$btnSavePlan = $window.FindName("btnSavePlan")
$btnRestorePlan = $window.FindName("btnRestorePlan")
$lblStatus = $window.FindName("lblStatus")

# Global State
$global:baseData = @() # Array of objects { Name, StartType, Status, DisplayName, IsTrigger }
$global:planData = @() # Array of objects { Name, StartType, Status ... }
$global:gridRows = @() # The unified row objects binding to the Grid

# --- Logic Functions ---

function Update-GridRows {
    if ($null -eq $global:baseData) { return }
    
    # Map Plan Data for lookup
    $planMap = @{}
    if ($global:planData) {
        foreach ($p in $global:planData) { $planMap[$p.Name] = $p }
    }

    $newRows = @()

    foreach ($b in $global:baseData) {
        # Check Filter
        if ($txtFilter.Text.Length -gt 0 -and 
            ($b.Name -notmatch $txtFilter.Text) -and 
            ($b.DisplayName -notmatch $txtFilter.Text)) {
            continue
        }

        # Determine Plan values (Default to Base if missing)
        $p = $planMap[$b.Name]
        $pStart = if ($p) { $p.StartType } else { $b.StartType }
        $pStatus = if ($p) { $p.Status } else { $b.Status }

        # Diff Check
        $isChanged = ($b.StartType -ne $pStart) -or ($b.Status -ne $pStatus)
        if ($chkShowDiffs.IsChecked -and -not $isChanged) { continue }

        $row = New-Object PSObject
        $row | Add-Member -MemberType NoteProperty -Name "Name" -Value $b.Name
        $row | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $b.DisplayName
        $row | Add-Member -MemberType NoteProperty -Name "BaseStart" -Value $b.StartType
        $row | Add-Member -MemberType NoteProperty -Name "BaseStatus" -Value $b.Status
        $row | Add-Member -MemberType NoteProperty -Name "PlanStart" -Value $pStart
        $row | Add-Member -MemberType NoteProperty -Name "PlanStatus" -Value $pStatus
        $row | Add-Member -MemberType NoteProperty -Name "IsChanged" -Value $isChanged
        # Hidden ref to original object properties if needed
        $row | Add-Member -MemberType NoteProperty -Name "IsTrigger" -Value $b.IsTrigger

        $newRows += $row
    }
    
    $global:gridRows = $newRows
    $dgMain.ItemsSource = $global:gridRows
    $lblStatus.Content = "Showing $($newRows.Count) services."
}

function Load-SystemState {
    $script = "$PSScriptRoot\ManageServices.ps1"
    # Call script in Export mode but capture output directly (requires modification or careful parsing)
    # Actually, simpler is just to call the script to export to a temp file, then read it.
    $tempFile = "$PSScriptRoot\exports\temp_system_state.json"
    
    # Ensure export dir
    if (!(Test-Path "$PSScriptRoot\exports")) { New-Item -ItemType Directory -Path "$PSScriptRoot\exports" | Out-Null }
    
    # Run ManageServices.ps1 -Mode Export -Path $tempFile
    # We use Start-Process -Wait to ensure it finishes
    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$script`" -Mode Export -Path `"$tempFile`"" -PassThru -NoNewWindow -Wait
    
    if (Test-Path $tempFile) {
        $json = Get-Content $tempFile -Raw | ConvertFrom-Json
        $global:baseData = $json
        $lblBaseFile.Content = "System State (Live)"
        # Default Plan to Copy of Base
        $global:planData = $global:baseData | Select-Object * 
        $lblPlanFile.Content = "Copy of System State"
        
        Update-GridRows
        Remove-Item $tempFile -Force
    }
    else {
        [System.Windows.MessageBox]::Show("Failed to load system state.", "Error", 0, 16)
    }
}

function Load-File-Base {
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
    $dlg.InitialDirectory = "$PSScriptRoot\configs"
    if ($dlg.ShowDialog() -eq $true) {
        try {
            $json = Get-Content $dlg.FileName -Raw | ConvertFrom-Json
            $global:baseData = $json
            $lblBaseFile.Content = Split-Path $dlg.FileName -Leaf
            
            # If Plan is empty, set Plan to Base
            if ($global:planData.Count -eq 0) {
                $global:planData = $global:baseData | Select-Object *
                $lblPlanFile.Content = "Copy of $($lblBaseFile.Content)"
            }
            Update-GridRows
        }
        catch { [System.Windows.MessageBox]::Show("Error loading file: $_", "Error", 0, 16) }
    }
}

function Load-File-Plan {
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
    $dlg.InitialDirectory = "$PSScriptRoot\configs"
    if ($dlg.ShowDialog() -eq $true) {
        try {
            $json = Get-Content $dlg.FileName -Raw | ConvertFrom-Json
            $global:planData = $json
            $lblPlanFile.Content = Split-Path $dlg.FileName -Leaf
            Update-GridRows
        }
        catch { [System.Windows.MessageBox]::Show("Error loading file: $_", "Error", 0, 16) }
    }
}

function Copy-BaseToPlan {
    if ($global:baseData) {
        $global:planData = $global:baseData | Select-Object *
        $lblPlanFile.Content = "Copy of $($lblBaseFile.Content)"
        Update-GridRows
    }
}

# --- Event Handlers ---

$btnLoadBaseSystem.Add_Click({ Load-SystemState })
$btnLoadBaseFile.Add_Click({ Load-File-Base })
$btnLoadPlanFile.Add_Click({ Load-File-Plan })
$btnCopyBaseToPlan.Add_Click({ Copy-BaseToPlan })
$btnResetPlan.Add_Click({ Copy-BaseToPlan })

$txtFilter.Add_TextChanged({ Update-GridRows })
$chkShowDiffs.Add_Checked({ Update-GridRows })
$chkShowDiffs.Add_Unchecked({ Update-GridRows })

$btnApplyBatch.Add_Click({
        # Apply batch to the CURRENTLY VIEWED ROWS (filtered/diffed)
        if ($null -eq $global:gridRows) { return }
    
        $startVal = $cmbBatchStart.SelectedValue
        $statusVal = $cmbBatchStatus.SelectedValue
    
        if (-not $startVal -and -not $statusVal) { return }
    
        # We need to update the Source of Truth ($global:planData)
        # Accessing via Name map for speed
        $planMap = @{}
        foreach ($p in $global:planData) { $planMap[$p.Name] = $p }
    
        foreach ($row in $global:gridRows) {
            # Update Row (Visual)
            if ($startVal) { $row.PlanStart = $startVal }
            if ($statusVal) { $row.PlanStatus = $statusVal }
        
            # Update Source (Data)
            if ($planMap.ContainsKey($row.Name)) {
                $pObj = $planMap[$row.Name]
                if ($startVal) { $pObj.StartType = $startVal }
                if ($statusVal) { $pObj.Status = $statusVal }
            }
            else {
                # If mapping missing (e.g. Plan didn't have this service), we should add it?
                # For now, simplistic approach: assuming Plan was init as Copy of Base
            }
        }
    
        # Refresh to trigger Diff highlights
        Update-GridRows
        [System.Windows.MessageBox]::Show("Batch applied to visible rows.", "Info", 0, 64)
    })

$btnSavePlan.Add_Click({
        $dlg = New-Object Microsoft.Win32.SaveFileDialog
        $dlg.Title = "Save Plan"
        $dlg.FileName = "$(Get-Date -Format 'yyyyMMddHHmm')-plan.json"
        $dlg.InitialDirectory = "$PSScriptRoot\configs"
    
        if ($dlg.ShowDialog() -eq $true) {
            # Construct Export from GridRows (Visual State is closest to User Intent)
            # OR better, reconstruct from PlanData? 
            # Actually, user edited the GridRows. We need to sync GridRows back to PlanData properly or just save GridRows.
            # Since GridRows might be filtered, we should probably stick to saving Valid PlanData.
            # BUT, the user edited the GRID ROWS directly in the UI. 
            # The TwoWay binding updates the PROPERTIES on the PSObjects in $global:gridRows.
            # We need to make sure we capture those.
        
            # Strategy: Iterate Global Base Data. If name exists in GridRows, take GridRow value. Else take Base Value (or Plan Value).
            # Let's simplify: User wants to save what they see as the "Plan".
        
            # Sync GridChanges back to PlanData map
            $planMap = @{}
            foreach ($p in $global:planData) { $planMap[$p.Name] = $p }

            # Sync from GridRows (which might be a subset)
            foreach ($row in $global:gridRows) {
                if ($planMap[$row.Name]) {
                    $planMap[$row.Name].StartType = $row.PlanStart
                    $planMap[$row.Name].Status = $row.PlanStatus
                }
            }
        
            # Output is PlanData
            $finalList = $global:planData 
        
            try {
                $finalList | ConvertTo-Json -Depth 2 | Set-Content -Path $dlg.FileName -Encoding UTF8
                [System.Windows.MessageBox]::Show("Plan saved!", "Success", 0, 64)
            }
            catch { [System.Windows.MessageBox]::Show("Error saving: $_", "Error", 0, 16) }
        }
    })

$btnRestorePlan.Add_Click({
        # We need to save the PLAN to a temp file, then run ManageServices.ps1 -Mode Restore
        $tempPlan = "$PSScriptRoot\exports\temp_restore_plan.json"
    
        # Sync GridChanges back to PlanData (same as Save)
        $planMap = @{}
        foreach ($p in $global:planData) { $planMap[$p.Name] = $p }
        foreach ($row in $global:gridRows) {
            if ($planMap[$row.Name]) {
                $planMap[$row.Name].StartType = $row.PlanStart
                $planMap[$row.Name].Status = $row.PlanStatus
            }
        }
    
        $global:planData | ConvertTo-Json -Depth 2 | Set-Content -Path $tempPlan -Encoding UTF8
    
        $result = [System.Windows.MessageBox]::Show("Are you sure you want to APPLY this plan to the system?`nThis will change service states requiring Admin privileges.", "Confirm Apply", 4, 32)
        if ($result -eq 'Yes') {
            $script = "$PSScriptRoot\ManageServices.ps1"
            Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$script`" -Mode Restore -Path `"$tempPlan`"" -Verb RunAs
        }
    })

$btnExportSystem.Add_Click({
        $dlg = New-Object Microsoft.Win32.SaveFileDialog
        $dlg.Title = "Export System State"
        $dlg.FileName = "$(Get-Date -Format 'yyyyMMddHHmmss')-windows-services.json"
        $dlg.InitialDirectory = "$PSScriptRoot\exports"
    
        if ($dlg.ShowDialog() -eq $true) {
            $script = "$PSScriptRoot\ManageServices.ps1"
            Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$script`" -Mode Export -Path `"$dlg.FileName`"" -PassThru
        }
    })

# Initial Load
Load-SystemState

$window.ShowDialog() | Out-Null
