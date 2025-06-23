If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit	
}

Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml

$BG      = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(45,45,48))
$FG      = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(204,204,204))
$InputBG = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(62,62,66))
$Accent  = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(17,63,93))

# Helper to style
function Set-Common($ctrl) {
  $ctrl.Foreground = $FG
  $ctrl.Margin     = [System.Windows.Thickness]::new(5)
}

function Update-ListBox {
    $lstApps.Items.Clear()
    $prop = Get-ItemPropertyValue $regPath ExclusionList -ErrorAction SilentlyContinue
    if ($prop) {
        $prop | ForEach-Object { $lstApps.Items.Add($_) | Out-Null }
    }
}

$template = @"
<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button">
  <Border Name="border" Background="{TemplateBinding Background}" 
          CornerRadius="2" BorderThickness="{TemplateBinding BorderThickness}" 
          BorderBrush="{TemplateBinding BorderBrush}"
          SnapsToDevicePixels="True">
    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
  </Border>
  <ControlTemplate.Triggers>
    <Trigger Property="IsMouseOver" Value="True">
      <Setter TargetName="border" Property="Background" Value="#2567A1"/>
    </Trigger>
    <Trigger Property="IsPressed" Value="True">
      <Setter TargetName="border" Property="Background" Value="#6293B4"/>
    </Trigger>
  </ControlTemplate.Triggers>
</ControlTemplate>
"@ 

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$template)
$tmpl = [Windows.Markup.XamlReader]::Load($reader)

# Main window
$win = [Windows.Window]::new()
$win.Title               = "FTH Manager"
$win.Width               = 410
$win.Height              = 280
$win.WindowStartupLocation = 'CenterScreen'
$win.ResizeMode          = 'NoResize'
$win.Background          = $BG
$win.Foreground          = $FG

# Layout grid
$grid = [Windows.Controls.Grid]::new()
for ($i = 0; $i -lt 4; $i++) {
  $rd = [Windows.Controls.RowDefinition]::new()
  $rd.Height = if ($i -eq 0) { [Windows.GridLength]::Auto } else { [Windows.GridLength]::Auto }
  $grid.RowDefinitions.Add($rd) | Out-Null
}
$win.Content = $grid

$panel0 = [Windows.Controls.StackPanel]::new()
$panel0.Orientation = 'Horizontal'
[Windows.Controls.Grid]::SetRow($panel0,0) 

$lblApp = [Windows.Controls.TextBlock]::new()
$lblApp.Text  = "App Name (e.g. myapp.exe):"
$lblApp.Width = 150
Set-Common $lblApp

$txtApp = [Windows.Controls.TextBox]::new()
$txtApp.Background = $InputBG
$txtApp.Width = 140
Set-Common $txtApp


$btnExclude = [Windows.Controls.Button]::new()
$btnExclude.Content    = "Exclude"
Set-Common $btnExclude

$btnExclude.Padding = [Windows.Thickness]::new(20, 6, 20, 6)
$btnExclude.MinWidth = 75
$btnExclude.Background = $Accent
$btnExclude.Template = $tmpl

$panel0.Children.Add($lblApp) | Out-Null
$panel0.Children.Add($txtApp) | Out-Null
$panel0.Children.Add($btnExclude) | Out-Null
$grid.Children.Add($panel0) | Out-Null

$panel1 = [Windows.Controls.StackPanel]::new()
$panel1.Orientation = 'Horizontal'
[Windows.Controls.Grid]::SetRow($panel1,1)

$lblFTH = [Windows.Controls.TextBlock]::new()
$lblFTH.Text  = "Enable Fault-Tolerant Heap:"
$lblFTH.Width = 150
Set-Common $lblFTH

$chkFTH = [Windows.Controls.CheckBox]::new()
Set-Common $chkFTH

$panel1.Children.Add($lblFTH) | Out-Null
$panel1.Children.Add($chkFTH) | Out-Null
$grid.Children.Add($panel1) | Out-Null


$panelList = [Windows.Controls.StackPanel]::new()
$panelList.Orientation = 'Vertical'
$panelList.Margin = [Windows.Thickness]::new(5)
[Windows.Controls.Grid]::SetRow($panelList,3)
$grid.Children.Add($panelList) | Out-Null

$lstApps = [Windows.Controls.ListBox]::new()
$lstApps.Height = 120
$lstApps.Background = $InputBG
$lstApps.Foreground = $FG
$lstApps.Margin = [Windows.Thickness]::new(0, 0, 0, 5)  
$panelList.Children.Add($lstApps) | Out-Null

$panel2 = [Windows.Controls.StackPanel]::new()
$panel2.HorizontalAlignment = 'Right'
[Windows.Controls.Grid]::SetRow($panel2,4)
$panel2.Margin = [System.Windows.Thickness]::new(5,155,5,5)

$btnClose = [Windows.Controls.Button]::new()
$btnClose.Content    = "Close"

$btnClose.Background = $Accent
Set-Common $btnClose

$btnClose.Padding = [Windows.Thickness]::new(20, 10, 20, 10)
$btnClose.MinWidth = 70
$btnClose.Template = $tmpl

$panel2.Children.Add($btnClose) | Out-Null
$grid.Children.Add($panel2) | Out-Null

$regPath = 'HKLM:\SOFTWARE\Microsoft\FTH'
#if (-not (Test-Path $regPath)) { New-Item $regPath | Out-Null }

# Init toggle state
try {
  $v = Get-ItemPropertyValue $regPath Enabled -ErrorAction Stop
  $chkFTH.IsChecked = $v -ne 0
} catch {
  $chkFTH.IsChecked = $true
}

$btnRemove = [Windows.Controls.Button]::new()
$btnRemove.Content = "Remove Selected"
$btnRemove.Padding = [Windows.Thickness]::new(12, 6, 12, 6)
$btnRemove.HorizontalAlignment = 'Left'
$btnRemove.MinWidth = 110
$btnRemove.MinHeight = 15
$btnRemove.Foreground = $FG
$btnRemove.Background = $Accent
$btnRemove.BorderThickness = [Windows.Thickness]::new(1)
$btnRemove.Template = $tmpl
Set-Common $btnRemove
$panelList.Children.Add($btnRemove) | Out-Null


# Event handlers
$chkFTH.Add_Checked({
  Set-ItemProperty $regPath Enabled 1 -Type DWord -Force
  [Windows.MessageBox]::Show('FTH enabled',"Success", 'OK', 'Information')
})
$chkFTH.Add_Unchecked({
  Set-ItemProperty $regPath Enabled 0 -Type DWord -Force
  Start-Process rundll32.exe -ArgumentList 'fthsvc.dll, FthSysprepSpecialize'
  [Windows.MessageBox]::Show('FTH disabled',"Success", 'OK', 'Information')
})

$btnExclude.Add_Click({
  $app = $txtApp.Text.Trim().ToLower()
  if (-not $app) {
    [Windows.MessageBox]::Show('Please enter an application name first.','Warning', 'OK', 'Warning') 
    return
  }
  $prop = Get-ItemPropertyValue $regPath ExclusionList -ErrorAction SilentlyContinue
  $list = if ($prop) { $prop } else { @() }
  if ($list -contains $app) {
    [Windows.MessageBox]::Show("$app is already excluded.","Warning", 'OK', 'Warning')
  } else {
    Set-ItemProperty $regPath ExclusionList ($list + $app) -Type MultiString -Force
    [Windows.MessageBox]::Show("$app added to exclusion list.","Success", 'OK', 'Information')
    Update-ListBox
  }
})

$btnRemove.Add_Click({
    $selected = $lstApps.SelectedItem
    if (-not $selected) {
        [Windows.MessageBox]::Show("Please select an app to remove.", "Warning", 'OK', 'Warning')
        return
    }

    $prop = Get-ItemPropertyValue $regPath ExclusionList -ErrorAction SilentlyContinue
    $list = if ($prop) { $prop } else { @() }

    $updated = $list | Where-Object { $_ -ne $selected }

    Set-ItemProperty -Path $regPath -Name ExclusionList -Value $updated -Type MultiString -Force
    [Windows.MessageBox]::Show("Removed $selected from exclusion list.", "Success", 'OK', 'Information')
    Update-ListBox
})


$lstApps.Add_KeyDown({
    param($sender, $e)
    if ($e.Key -eq [Windows.Input.Key]::Delete) {
        $btnRemove.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
    }
})


$btnClose.Add_Click({ $win.Close() })

Update-ListBox

[void]$win.ShowDialog()
