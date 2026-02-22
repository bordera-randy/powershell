<# 
.SYNOPSIS
    Azure Admin Quick Launcher (Commercial) - Minimal
.DESCRIPTION
    WPF dashboard to quickly open common Azure Portal blades (Commercial cloud only).
    Minimal UI + search filter. Auto-detects Tenant/Sub via Azure CLI (az) if available.
.NOTES
    Version: 4.0
    Requires: Windows PowerShell 5.1+, .NET Framework, Azure CLI optional (for auto-detect)
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ----------------------------
# Load WPF assemblies
# ----------------------------
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ----------------------------
# Helpers
# ----------------------------
function Nz([object]$v, [string]$fallback = "") {
    if ($null -eq $v) { return $fallback }
    $s = [string]$v
    if ([string]::IsNullOrWhiteSpace($s)) { return $fallback }
    return $s
}
function Set-Status([string]$msg) {
    if ($script:lblStatus) { $script:lblStatus.Text = "Status: " + $msg }
}
function Try-StartProcess([string]$Url) {
    try {
        if ([string]::IsNullOrWhiteSpace($Url)) { throw "No URL" }
        Start-Process -FilePath $Url | Out-Null
        Set-Status ("Opened: " + $Url)
    } catch {
        Set-Status ("Open failed: " + $_.Exception.Message)
        [System.Windows.MessageBox]::Show(
            ("Failed to open URL:`n`n" + $Url + "`n`n" + $_.Exception.Message),
            "Open failed",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
}

# ----------------------------
# Azure CLI auto-detect (Commercial)
# ----------------------------
function Get-AzCliContext {
    $ctx = [ordered]@{
        AzPresent  = $false
        LoggedIn   = $false
        TenantId   = ""
        SubscriptionId = ""
        SubscriptionName = ""
        User = ""
        EnvironmentName = ""
        Raw = $null
    }

    try {
        $null = Get-Command az -ErrorAction Stop
        $ctx.AzPresent = $true
    } catch {
        return [pscustomobject]$ctx
    }

    try {
        $json = & az account show --only-show-errors 2>$null
        if ([string]::IsNullOrWhiteSpace($json)) { return [pscustomobject]$ctx }
        $obj = $json | ConvertFrom-Json
        $ctx.Raw = $obj
        $ctx.LoggedIn = $true
        $ctx.TenantId = Nz $obj.tenantId
        $ctx.SubscriptionId = Nz $obj.id
        $ctx.SubscriptionName = Nz $obj.name
        $ctx.User = Nz $obj.user.name
        $ctx.EnvironmentName = Nz $obj.environmentName
    } catch {
        # Not logged in or az returned error
    }

    return [pscustomobject]$ctx
}

# ----------------------------
# URL builder
# ----------------------------
function Get-AzureUrl {
    param(
        [Parameter(Mandatory=$true)][hashtable]$Center,
        [Parameter(Mandatory=$true)][pscustomobject]$Ctx
    )

    $base = "https://portal.azure.com"
    $path = Nz $Center.Path
    $type = Nz $Center.Type

    switch ($type) {
        "base" {
            if ([string]::IsNullOrWhiteSpace($path)) { return $base }
            if ($path.StartsWith("#")) { return $base + $path }
            return $base + "/" + $path.TrimStart("/")
        }
        "blade" {
            if ([string]::IsNullOrWhiteSpace($path)) { return $base }
            if ($path.StartsWith("#blade/")) { return $base + $path }
            return $base + "#blade/" + $path.TrimStart("/")
        }
        "resourceGroups" {
            if (-not [string]::IsNullOrWhiteSpace($Ctx.SubscriptionId)) {
                return $base + "#blade/HubsExtension/BrowseResourceGroups/subscriptionId/" + $Ctx.SubscriptionId
            }
            return $base + "#view/HubsExtension/BrowseResourceGroups"
        }
        "specificRG" {
            $rg = Nz $script:txtRG.Text
            if ([string]::IsNullOrWhiteSpace($rg)) {
                return (Get-AzureUrl -Center @{ Type="resourceGroups"; Path="" } -Ctx $Ctx)
            }
            if ([string]::IsNullOrWhiteSpace($Ctx.SubscriptionId)) {
                return (Get-AzureUrl -Center @{ Type="resourceGroups"; Path="" } -Ctx $Ctx)
            }
            $sid = $Ctx.SubscriptionId
            $encodedRg = [Uri]::EscapeDataString($rg)
            return $base + "#@/resource/subscriptions/$sid/resourceGroups/$encodedRg/overview"
        }
        default {
            $u = Nz $Center.Url
            if ($u -match '^https?://') { return $u }
            if ([string]::IsNullOrWhiteSpace($path)) { return $base }
            return $base + $path
        }
    }
}

# ----------------------------
# Centers (Commercial portal blades)
# ----------------------------
$Centers = @(
    @{ Name="Azure Portal Home"; Type="base"; Path=""; Keywords="portal home start"; Glyph="E7C5"; Bg="#2D7D9A" }
    @{ Name="Subscriptions"; Type="blade"; Path="Microsoft_Azure_Billing/SubscriptionsBlade"; Keywords="subscription billing"; Glyph="E8B4"; Bg="#1F8A8A" }
    @{ Name="Resource Groups"; Type="resourceGroups"; Path=""; Keywords="resource groups rg"; Glyph="E8F1"; Bg="#3C6FA3" }
    @{ Name="Specific Resource Group"; Type="specificRG"; Path=""; Keywords="resource group specific rg"; Glyph="E8F1"; Bg="#3A4A5B" }
    @{ Name="Cost Management"; Type="blade"; Path="Microsoft_Azure_CostManagement/Menu/overview"; Keywords="cost management"; Glyph="E9D2"; Bg="#1D9A7A" }
    @{ Name="Advisor"; Type="blade"; Path="Microsoft_Azure_ExpertRecommendations/AdvisorMenuBlade/overview"; Keywords="advisor recommendations"; Glyph="E7AD"; Bg="#D97A1D" }
    @{ Name="Monitor"; Type="blade"; Path="Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade"; Keywords="monitor metrics logs"; Glyph="E9D9"; Bg="#465564" }
    @{ Name="Activity Log"; Type="blade"; Path="Microsoft_Azure_Monitoring/ActivityLogBlade"; Keywords="activity log audit"; Glyph="E81C"; Bg="#8E44AD" }
    @{ Name="Log Analytics Workspaces"; Type="blade"; Path="Microsoft_Azure_Monitoring/LogAnalyticsBlade"; Keywords="log analytics law workspace"; Glyph="E9D0"; Bg="#2F2F2F" }
    @{ Name="Application Insights"; Type="blade"; Path="Microsoft_Azure_Monitoring/ApplicationInsightsBlade"; Keywords="app insights apm"; Glyph="E7B8"; Bg="#1278D3" }
    @{ Name="Alerts"; Type="blade"; Path="Microsoft_Azure_Monitoring/AlertsManagementBlade"; Keywords="alerts"; Glyph="EA39"; Bg="#C0392B" }
    @{ Name="Service Health"; Type="blade"; Path="Microsoft_Azure_ServiceHealth/ServiceHealthBrowseBlade"; Keywords="service health"; Glyph="E7BA"; Bg="#E39A18" }
    @{ Name="Key Vaults"; Type="blade"; Path="Microsoft_Azure_KeyVault/KeyVaultMenuBlade"; Keywords="key vault kv secrets certs"; Glyph="E72E"; Bg="#111827" }
    @{ Name="Access Control (IAM)"; Type="blade"; Path="Microsoft_Azure_AccessControl/IAMMenuBlade"; Keywords="iam rbac roles"; Glyph="E72E"; Bg="#6C5CE7" }
    @{ Name="Azure Policy"; Type="blade"; Path="Microsoft_Azure_Policy/PolicyMenuBlade/Overview"; Keywords="policy"; Glyph="E8FD"; Bg="#16A085" }
    @{ Name="Defender for Cloud"; Type="blade"; Path="Microsoft_Azure_Security/SecurityMenuBlade/overview"; Keywords="defender security cloud"; Glyph="E7FC"; Bg="#B03A2E" }
    @{ Name="Virtual Networks"; Type="blade"; Path="Microsoft_Azure_Network/VirtualNetworksMenuBlade"; Keywords="vnet networking"; Glyph="E774"; Bg="#0EA5C6" }
    @{ Name="Network Security Groups"; Type="blade"; Path="Microsoft_Azure_Network/NetworkSecurityGroupsMenuBlade"; Keywords="nsg"; Glyph="E7FC"; Bg="#0F7C8C" }
    @{ Name="Azure Firewall"; Type="blade"; Path="Microsoft_Azure_Firewall/FirewallMenuBlade"; Keywords="firewall"; Glyph="E7FC"; Bg="#A61B1B" }
    @{ Name="Application Gateways"; Type="blade"; Path="Microsoft_Azure_Network/ApplicationGatewaysMenuBlade"; Keywords="app gateway agw"; Glyph="E7F8"; Bg="#E67E22" }
    @{ Name="Private DNS Zones"; Type="blade"; Path="Microsoft_Azure_DNS/PrivateDnsZonesMenuBlade"; Keywords="private dns"; Glyph="E8D2"; Bg="#2ECC71" }
    @{ Name="Storage Accounts"; Type="blade"; Path="Microsoft_Azure_Storage/StorageMenuBlade"; Keywords="storage"; Glyph="E7C3"; Bg="#2AA4D6" }
    @{ Name="Virtual Machines"; Type="blade"; Path="Microsoft_Azure_Compute/VirtualMachinesMenuBlade"; Keywords="vm compute"; Glyph="E8CC"; Bg="#1D6F86" }
    @{ Name="App Services"; Type="blade"; Path="Microsoft_Azure_AppService/AppServicesMenuBlade"; Keywords="app services webapp"; Glyph="E71B"; Bg="#2E5FE3" }
    @{ Name="Function Apps"; Type="blade"; Path="Microsoft_Azure_Functions/FunctionAppsMenuBlade"; Keywords="functions"; Glyph="E8D4"; Bg="#6D3CE6" }
    @{ Name="AKS Clusters"; Type="blade"; Path="Microsoft_Azure_ContainerService/ContainerServiceMenuBlade"; Keywords="aks kubernetes"; Glyph="E7B8"; Bg="#1F4DD6" }
    @{ Name="Container Apps"; Type="blade"; Path="Microsoft_Azure_ContainerApps/ContainerAppsMenuBlade"; Keywords="container apps"; Glyph="E7B8"; Bg="#1D7C5C" }
)

# ----------------------------
# XAML (minimal + native-ish)
# ----------------------------
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Azure Administration Dashboard (Commercial)"
        Height="840" Width="1160"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize"
        Background="#F3F6FB">
    <Window.Resources>

        <Style TargetType="Menu">
            <Setter Property="Background" Value="#FAFAFC"/>
            <Setter Property="BorderBrush" Value="#E5E7EB"/>
            <Setter Property="BorderThickness" Value="0,0,0,1"/>
        </Style>

        <Style x:Key="TileButtonStyle" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="Height" Value="52"/>
            <Setter Property="Margin" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border x:Name="Card"
                                    CornerRadius="12"
                                    Background="{TemplateBinding Background}">
                                <Border.Effect>
                                    <DropShadowEffect Color="#000000" BlurRadius="14" ShadowDepth="4" Opacity="0.22"/>
                                </Border.Effect>

                                <Grid>
                                    <Border CornerRadius="12" Background="#000000" Opacity="0.08"/>
                                    <Border CornerRadius="12" Margin="1">
                                        <Border.Background>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#FFFFFF" Offset="0" />
                                                <GradientStop Color="#FFFFFF" Offset="0.25" />
                                                <GradientStop Color="#FFFFFF" Offset="1" />
                                            </LinearGradientBrush>
                                        </Border.Background>
                                        <Border.OpacityMask>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#FF000000" Offset="0" />
                                                <GradientStop Color="#22000000" Offset="0.25" />
                                                <GradientStop Color="#00000000" Offset="1" />
                                            </LinearGradientBrush>
                                        </Border.OpacityMask>
                                    </Border>

                                    <ContentPresenter HorizontalAlignment="Center"
                                                      VerticalAlignment="Center"
                                                      Margin="18,10"/>
                                </Grid>
                            </Border>
                        </Grid>

                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Card" Property="RenderTransformOrigin" Value="0.5,0.5"/>
                                <Setter TargetName="Card" Property="RenderTransform">
                                    <Setter.Value>
                                        <TranslateTransform Y="-1"/>
                                    </Setter.Value>
                                </Setter>
                                <Setter TargetName="Card" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#000000" BlurRadius="18" ShadowDepth="6" Opacity="0.28"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Card" Property="RenderTransformOrigin" Value="0.5,0.5"/>
                                <Setter TargetName="Card" Property="RenderTransform">
                                    <Setter.Value>
                                        <TranslateTransform Y="1"/>
                                    </Setter.Value>
                                </Setter>
                                <Setter TargetName="Card" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#000000" BlurRadius="10" ShadowDepth="2" Opacity="0.18"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Card" Property="Opacity" Value="0.55"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Menu Grid.Row="0" x:Name="MainMenu">
            <MenuItem Header="_File">
                <MenuItem x:Name="miExit" Header="E_xit"/>
            </MenuItem>
            <MenuItem Header="_Help">
                <MenuItem x:Name="miHowTo" Header="_How to use"/>
                <MenuItem x:Name="miAbout" Header="_About"/>
            </MenuItem>
        </Menu>

        <Border Grid.Row="1" Background="#FAFAFC" CornerRadius="12" Padding="12" BorderBrush="#E5E7EB" BorderThickness="1" Margin="0,10,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Orientation="Vertical">
                    <TextBlock Text="Azure Administration Dashboard" FontSize="20" FontWeight="Bold" Foreground="#111827"/>
                    <TextBlock x:Name="txtContext" Text="Context: (detecting...)" Foreground="#4B5563" FontSize="12" Margin="0,4,0,0"/>
                </StackPanel>

                <StackPanel Grid.Column="1" Orientation="Vertical" HorizontalAlignment="Right">
                    <TextBlock Text="Search" FontSize="12" FontWeight="Bold" Foreground="#6B7280" HorizontalAlignment="Right"/>
                    <TextBox x:Name="txtSearch" Width="300" Height="28" Margin="0,6,0,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <Border Grid.Row="2" Background="#FAFAFC" CornerRadius="12" Padding="10" BorderBrush="#E5E7EB" BorderThickness="1" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="180"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="92"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Orientation="Vertical">
                    <TextBlock Text="Optional" FontSize="12" FontWeight="Bold" Foreground="#6B7280"/>
                    <TextBlock Text="Resource Group" FontSize="14" FontWeight="Bold" Foreground="#111827"/>
                </StackPanel>

                <TextBox x:Name="txtRG" Grid.Column="1" Height="28" VerticalAlignment="Center" Margin="8,0,8,0"/>

                <Button x:Name="btnRgCopy" Grid.Column="2" Content="Copy" Padding="12,7" FontWeight="Bold"/>
            </Grid>
        </Border>

        <Border Grid.Row="3" Background="#F3F6FB" CornerRadius="12" Padding="6">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Orientation="Vertical" Margin="6,0,6,8">
                    <TextBlock Text="Azure Portals & Blades" FontSize="12" FontWeight="Bold" Foreground="#6B7280"/>
                    <TextBlock Text="Click a tile to open the portal in your default browser" FontSize="13" Foreground="#374151"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" x:Name="svButtons" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <UniformGrid x:Name="ugButtons" Columns="4" Margin="2"/>
                </ScrollViewer>
            </Grid>
        </Border>

        <Border Grid.Row="4" Background="#FAFAFC" CornerRadius="12" Padding="10" BorderBrush="#E5E7EB" BorderThickness="1" Margin="0,10,0,0">
            <DockPanel>
                <CheckBox x:Name="chkCloseToTray" Content="Close to tray" IsChecked="True" VerticalAlignment="Center"/>
                <TextBlock x:Name="lblStatus" DockPanel.Dock="Left" Margin="16,0,0,0" VerticalAlignment="Center" Foreground="#4B5563" Text="Status: Ready"/>
                <Button x:Name="btnExit" Content="Exit" DockPanel.Dock="Right" Width="90" FontWeight="Bold"/>
            </DockPanel>
        </Border>

    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$txtSearch      = $window.FindName("txtSearch")
$txtContext     = $window.FindName("txtContext")
$txtRG          = $window.FindName("txtRG")
$btnRgCopy      = $window.FindName("btnRgCopy")
$svButtons      = $window.FindName("svButtons")
$ugButtons      = $window.FindName("ugButtons")
$chkCloseToTray = $window.FindName("chkCloseToTray")
$lblStatus      = $window.FindName("lblStatus")
$btnExit        = $window.FindName("btnExit")
$miExit         = $window.FindName("miExit")
$miHowTo        = $window.FindName("miHowTo")
$miAbout        = $window.FindName("miAbout")

$txtSearch.ToolTip = "Type to filter tiles by name or keywords."
$txtRG.ToolTip     = "Optional: used by 'Specific Resource Group' tile (deep link)."
$btnRgCopy.ToolTip = "Copy Resource Group value to clipboard."

# Tray icon
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$notifyIcon.Text = "Azure Admin Dashboard"
$notifyIcon.Visible = $false

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$miTrayOpen = $trayMenu.Items.Add("Open")
$miTrayExit = $trayMenu.Items.Add("Exit")
$notifyIcon.ContextMenuStrip = $trayMenu

$miTrayOpen.add_Click({
    $window.Show()
    $window.WindowState = "Normal"
    $window.Activate() | Out-Null
})
$miTrayExit.add_Click({
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    $window.Close()
})
$notifyIcon.add_DoubleClick({
    $window.Show()
    $window.WindowState = "Normal"
    $window.Activate() | Out-Null
})

# Azure CLI context
$script:Ctx = Get-AzCliContext
if (-not $script:Ctx.AzPresent) {
    $txtContext.Text = "Context: Azure CLI not found (install 'az' for auto-detect)"
} elseif (-not $script:Ctx.LoggedIn) {
    $txtContext.Text = "Context: Azure CLI detected, not logged in (run: az login)"
} else {
    $shortSub = if ($script:Ctx.SubscriptionId.Length -gt 8) { $script:Ctx.SubscriptionId.Substring(0,8) + "…" } else { $script:Ctx.SubscriptionId }
    $user = Nz $script:Ctx.User "(unknown user)"
    $txtContext.Text = "Context: $user | $($script:Ctx.SubscriptionName) ($shortSub) | Tenant: $($script:Ctx.TenantId)"
}

function New-TileContent {
    param([string]$GlyphHex, [string]$Text)
    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Orientation = "Horizontal"
    $sp.HorizontalAlignment = "Center"
    $sp.VerticalAlignment   = "Center"

    $icon = New-Object System.Windows.Controls.TextBlock
    $icon.FontFamily = "Segoe MDL2 Assets"
    $icon.FontSize = 18
    $icon.Margin = "0,0,10,0"
    $icon.Text = [char]([Convert]::ToInt32($GlyphHex, 16))

    $label = New-Object System.Windows.Controls.TextBlock
    $label.FontSize = 13
    $label.Text = $Text
    $label.TextTrimming = "CharacterEllipsis"

    $sp.Children.Add($icon) | Out-Null
    $sp.Children.Add($label) | Out-Null
    return $sp
}

$script:TileButtons = New-Object System.Collections.Generic.List[object]

function Build-Buttons {
    $ugButtons.Children.Clear()
    $script:TileButtons.Clear()

    foreach ($c in $Centers) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $window.FindResource("TileButtonStyle")
        $btn.Background = $c.Bg
        $btn.Content = New-TileContent -GlyphHex $c.Glyph -Text $c.Name
        $btn.Tag = @{ Center = $c }

        $btn.Add_Click({
            $center = $this.Tag.Center
            $url = Get-AzureUrl -Center $center -Ctx $script:Ctx
            Try-StartProcess -Url $url
        })

        $script:TileButtons.Add($btn) | Out-Null
        $ugButtons.Children.Add($btn) | Out-Null
    }
}

function Apply-Filter {
    $q = (Nz $txtSearch.Text).Trim().ToLowerInvariant()
    foreach ($b in $script:TileButtons) {
        $entry = $b.Tag.Center
        $hay = ("{0} {1}" -f (Nz $entry.Name), (Nz $entry.Keywords)).ToLowerInvariant()
        if ($q.Length -eq 0 -or $hay -like ("*" + $q + "*")) {
            $b.Visibility = "Visible"
        } else {
            $b.Visibility = "Collapsed"
        }
    }
}

function Recalc-Columns {
    try {
        $w = [Math]::Max(420, $svButtons.ActualWidth)
        $cols = [int][Math]::Floor(($w - 20) / 270)
        if ($cols -lt 2) { $cols = 2 }
        if ($cols -gt 6) { $cols = 6 }
        $ugButtons.Columns = $cols
    } catch { }
}

Build-Buttons
Apply-Filter
Recalc-Columns

function Show-HelpWindow {
    $msg = @"
Azure Admin Quick Launcher (Commercial)

What it does
- Opens common Azure portal blades in your default browser.
- Provides a search box to filter tiles.
- Auto-detects tenant/subscription via Azure CLI when available.

Azure CLI auto-detect
- Install Azure CLI: https://aka.ms/azure-cli
- Sign in: az login
- The launcher uses: az account show

Resource Group field (optional)
- Only used by the tile: ""Specific Resource Group""
- If set and subscription is known, the launcher deep-links to RG overview.
"@

    [System.Windows.MessageBox]::Show(
        $msg,
        "How to use",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    ) | Out-Null
}

function Show-AboutWindow {
    $msg = @"
Azure Admin Quick Launcher (Commercial)
Version: 4.0

Minimal WPF launcher for common Azure Portal blades.
Commercial cloud only.

Tip: Convert to EXE with PS2EXE for easy distribution.
"@

    [System.Windows.MessageBox]::Show(
        $msg,
        "About",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    ) | Out-Null
}

$txtSearch.Add_TextChanged({ Apply-Filter })
$svButtons.Add_SizeChanged({ Recalc-Columns })

$btnRgCopy.Add_Click({
    Set-Clipboard -Value (Nz $txtRG.Text)
    Set-Status "Resource Group copied"
})

$miExit.Add_Click({ $window.Close() })
$miHowTo.Add_Click({ Show-HelpWindow })
$miAbout.Add_Click({ Show-AboutWindow })
$btnExit.Add_Click({ $window.Close() })

$window.Add_Closing({
    param($sender, $e)
    if ($chkCloseToTray.IsChecked -eq $true) {
        $e.Cancel = $true
        $window.Hide()
        $notifyIcon.Visible = $true
        Set-Status "Minimized to tray"
    } else {
        $notifyIcon.Visible = $false
        $notifyIcon.Dispose()
    }
})

$window.Add_Closed({
    try {
        $notifyIcon.Visible = $false
        $notifyIcon.Dispose()
    } catch {}
})

$null = $window.ShowDialog()
