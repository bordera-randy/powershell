<#
.SYNOPSIS
    Microsoft 365 Admin Center Quick Launcher (Multi-Tenant) - WPF/XAML
.DESCRIPTION
    WPF/XAML-based launcher with:
      - Directory (Tenant) ID and SharePoint tenant prefix inputs
      - Clear "Where to find" help + readable tooltips (no overlapping)
      - Search box in top-right
      - Section headers (Tenant Configuration, Admin Centers)
      - Button grid that auto-fills space (dynamic UniformGrid columns)
      - Iconography on buttons (Segoe MDL2 Assets glyphs)
      - Config persistence to %APPDATA%
      - Reset button clears fields + removes saved config
      - Close-to-tray (optional) with tray icon

.NOTES
    Author: PowerShell Utility Collection
    Version: 3.1
    Requirements: Windows PowerShell 5.1+, .NET Framework (WPF assemblies)
#>

[CmdletBinding()]
param()

# ----------------------------
# WPF Assemblies
# ----------------------------
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# ----------------------------
# Persistence
# ----------------------------
$AppRoot    = Join-Path $env:APPDATA "PowerShell-Utility\M365Launcher"
$ConfigPath = Join-Path $AppRoot "config.json"

function Ensure-AppRoot {
    if (-not (Test-Path $AppRoot)) { New-Item -Path $AppRoot -ItemType Directory -Force | Out-Null }
}

function Load-Config {
    Ensure-AppRoot
    if (Test-Path $ConfigPath) {
        try { return (Get-Content $ConfigPath -Raw | ConvertFrom-Json) }
        catch { return [pscustomobject]@{} }
    }
    [pscustomobject]@{}
}

function Save-Config([object]$cfg) {
    Ensure-AppRoot
    $cfg | ConvertTo-Json -Depth 6 | Set-Content -Path $ConfigPath -Encoding UTF8
}

function Remove-Config {
    if (Test-Path $ConfigPath) {
        try { Remove-Item $ConfigPath -Force -ErrorAction Stop | Out-Null } catch {}
    }
}

# ----------------------------
# Helpers
# ----------------------------
function Test-TenantId {
    param([string]$TenantId)
    $guid = [Guid]::Empty
    [Guid]::TryParse(($TenantId ?? "").Trim(), [ref]$guid)
}

function Normalize-TenantName {
    param([string]$TenantName)
    if ([string]::IsNullOrWhiteSpace($TenantName)) { return "" }
    $t = $TenantName.Trim()

    if ($t -match '^(?<name>[^.]+)\.onmicrosoft\.com$') { return $Matches['name'] }
    if ($t -match '^(?<name>[^.]+)-admin\.sharepoint\.com$') { return $Matches['name'] }
    $t
}

function Open-Url {
    param([Parameter(Mandatory)][string]$Url)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Url
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        $true
    } catch {
        $false
    }
}

function Get-SharePointAdminUrl {
    param([Parameter(Mandatory)][string]$TenantName)
    "https://$TenantName-admin.sharepoint.com"
}

function Get-EntraUrl {
    param([Parameter(Mandatory)][string]$TenantId)
    "https://entra.microsoft.com/#/tenant/$TenantId"
}

# ----------------------------
# Admin Centers
# ----------------------------
function Get-AdminCenters {
    @(
        # Core
        @{ Name="Microsoft 365 Admin Center"; Category="Core"; Color="#E67E22"; Notes="Primary admin portal"; StaticUrl="https://admin.microsoft.com"; Keywords="m365 admin center office365"; Icon="E713" } # GlobalNavButton
        @{ Name="Users"; Category="Core"; Color="#6B8E23"; Notes="Users blade"; StaticUrl="https://admin.microsoft.com/#/users"; Keywords="users accounts licensing"; Icon="E77B" } # Contact
        @{ Name="Licenses"; Category="Core"; Color="#2ECC71"; Notes="Licensing"; StaticUrl="https://admin.microsoft.com/#/licenses"; Keywords="licenses subscriptions"; Icon="E8D7" } # Permissions
        @{ Name="Billing"; Category="Core"; Color="#16A085"; Notes="Billing"; StaticUrl="https://admin.microsoft.com/#/billingaccounts"; Keywords="billing invoices payments"; Icon="E8C7" } # Money
        @{ Name="Domains"; Category="Core"; Color="#34495E"; Notes="Domains"; StaticUrl="https://admin.microsoft.com/#/domains"; Keywords="domains dns"; Icon="E774" } # World

        # Messaging
        @{ Name="Exchange Admin Center"; Category="Messaging"; Color="#0078D7"; Notes="Exchange Online"; StaticUrl="https://admin.exchange.microsoft.com"; Keywords="exchange mail exo"; Icon="E715" } # Mail
        @{ Name="Teams Admin Center"; Category="Messaging"; Color="#5695D2"; Notes="Teams"; StaticUrl="https://admin.teams.microsoft.com"; Keywords="teams voice calling"; Icon="E902" } # Video

        # Collaboration
        @{
            Name="SharePoint Admin Center"; Category="Collaboration"; Color="#00B0F0"; Notes="SharePoint admin"; Keywords="sharepoint sp sites"; Icon="E8A7" # Library
            UrlBuilder = {
                param($state)
                if ([string]::IsNullOrWhiteSpace($state.TenantName)) { "https://admin.microsoft.com/sharepoint" }
                else { Get-SharePointAdminUrl -TenantName $state.TenantName }
            }
        }
        @{
            Name="OneDrive Admin"; Category="Collaboration"; Color="#00CC99"; Notes="OneDrive settings"; Keywords="onedrive sync sharing"; Icon="E753" # Cloud
            UrlBuilder = {
                param($state)
                if ([string]::IsNullOrWhiteSpace($state.TenantName)) { "https://admin.microsoft.com/#/onedrive" }
                else { Get-SharePointAdminUrl -TenantName $state.TenantName }
            }
        }

        # Identity / Azure
        @{
            Name="Entra ID Admin Center"; Category="Identity"; Color="#9B59B6"; Notes="Entra ID"; Keywords="entra aad azuread identity conditional access"; Icon="E72E" # Shield
            UrlBuilder = {
                param($state)
                if (Test-TenantId $state.TenantId) { Get-EntraUrl -TenantId $state.TenantId }
                else { "https://entra.microsoft.com" }
            }
        }
        @{ Name="Azure Portal"; Category="Identity"; Color="#2980B9"; Notes="Azure"; StaticUrl="https://portal.azure.com"; Keywords="azure portal subscriptions"; Icon="E7AD" } # AzureLogo (approx)

        # Security & Compliance
        @{ Name="Microsoft Defender Portal"; Category="Security"; Color="#C0392B"; Notes="Defender"; StaticUrl="https://security.microsoft.com"; Keywords="defender security mde"; Icon="EA18" } # SecurityGroup
        @{ Name="Microsoft Purview Compliance"; Category="Security"; Color="#7848A9"; Notes="Purview"; StaticUrl="https://compliance.microsoft.com"; Keywords="purview compliance ediscovery retention"; Icon="E8EF" } # ComplianceAudit
        @{ Name="Microsoft 365 Defender (legacy)"; Category="Security"; Color="#8E44AD"; Notes="Legacy"; StaticUrl="https://security.microsoft.com/homepage"; Keywords="m365 defender portal"; Icon="EA18" }

        # Devices
        @{ Name="Intune / Endpoint Manager"; Category="Devices"; Color="#1ABC9C"; Notes="Endpoint"; StaticUrl="https://endpoint.microsoft.com"; Keywords="intune endpoint manager mdm"; Icon="E7F8" } # DeviceLaptop

        # Power Platform
        @{ Name="Power Platform Admin"; Category="Power"; Color="#2D89EF"; Notes="Power Platform"; StaticUrl="https://admin.powerplatform.microsoft.com"; Keywords="power platform"; Icon="E7C1" } # Puzzle
        @{ Name="Power BI Admin"; Category="Power"; Color="#F1C40F"; Notes="Power BI"; StaticUrl="https://app.powerbi.com/admin-portal"; Keywords="powerbi bi"; Icon="E9D2" } # BarChart
    )
}

# ----------------------------
# State
# ----------------------------
$cfg = Load-Config
$state = [pscustomobject]@{
    TenantId   = ($cfg.tenantId   | ForEach-Object { "$_" })
    TenantName = (Normalize-TenantName ($cfg.tenantName | ForEach-Object { "$_" }))
}

# ----------------------------
# XAML UI (no overlapping text; search in top-right; section headers)
# ----------------------------
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Microsoft 365 Admin Centers (Multi-Tenant)"
        Height="820" Width="1040"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize"
        Background="#F0F5FA">
    <Window.Resources>
        <!-- 3D-ish tile button style -->
        <Style x:Key="TileButtonStyle" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border x:Name="Card"
                                    CornerRadius="12"
                                    Background="{TemplateBinding Background}"
                                    SnapsToDevicePixels="True">
                                <Border.Effect>
                                    <DropShadowEffect Color="#000000"
                                                      BlurRadius="14"
                                                      ShadowDepth="4"
                                                      Opacity="0.28"/>
                                </Border.Effect>

                                <!-- "Gloss" highlight -->
                                <Grid>
                                    <Border CornerRadius="12" Background="#000000" Opacity="0.08"/>
                                    <Border CornerRadius="12" Margin="1">
                                        <Border.Background>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#FFFFFF" Offset="0" />
                                                <GradientStop Color="#FFFFFF" Offset="0.35" />
                                                <GradientStop Color="#FFFFFF" Offset="1" />
                                            </LinearGradientBrush>
                                        </Border.Background>
                                        <Border.OpacityMask>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#FF000000" Offset="0" />
                                                <GradientStop Color="#26000000" Offset="0.35" />
                                                <GradientStop Color="#00000000" Offset="1" />
                                            </LinearGradientBrush>
                                        </Border.OpacityMask>
                                    </Border>

                                    <!-- Content -->
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
                                        <DropShadowEffect Color="#000000" BlurRadius="18" ShadowDepth="6" Opacity="0.34"/>
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
                                        <DropShadowEffect Color="#000000" BlurRadius="10" ShadowDepth="2" Opacity="0.22"/>
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
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Tenant Configuration -->
        <Border Grid.Row="0" Background="#FAFAFC" CornerRadius="12" Padding="14" BorderBrush="#E5E7EB" BorderThickness="1">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>  <!-- header line -->
                    <RowDefinition Height="10"/>
                    <RowDefinition Height="Auto"/>  <!-- tenant id line -->
                    <RowDefinition Height="Auto"/>  <!-- tenant id help line -->
                    <RowDefinition Height="10"/>
                    <RowDefinition Height="Auto"/>  <!-- tenant name line -->
                    <RowDefinition Height="Auto"/>  <!-- tenant name help line -->
                </Grid.RowDefinitions>

                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="230"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="92"/>
                    <ColumnDefinition Width="170"/>
                    <ColumnDefinition Width="44"/>
                    <ColumnDefinition Width="210"/>
                </Grid.ColumnDefinitions>

                <!-- Header row: section header + search right -->
                <StackPanel Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="3" Orientation="Vertical">
                    <TextBlock Text="Tenant Configuration" FontSize="12" FontWeight="Bold" Foreground="#6B7280"/>
                    <TextBlock Text="Microsoft 365 Administration Dashboard" FontSize="20" FontWeight="Bold" Foreground="#111827"/>
                </StackPanel>

                <DockPanel Grid.Row="0" Grid.Column="3" Grid.ColumnSpan="3" LastChildFill="True" Margin="8,0,0,0">
                    <StackPanel DockPanel.Dock="Right" Orientation="Vertical" HorizontalAlignment="Right">
                        <TextBlock Text="Search" FontSize="12" FontWeight="Bold" Foreground="#6B7280" HorizontalAlignment="Right"/>
                        <TextBox x:Name="txtSearch" Width="340" Height="28" Margin="0,4,0,0"/>
                    </StackPanel>
                </DockPanel>

                <!-- Reset button and Active Tenant badge -->
                <Button x:Name="btnReset" Grid.Row="0" Grid.Column="2" Content="Reset"
                        Margin="8,4,0,0" Padding="12,7"
                        Background="#777777" Foreground="White" BorderThickness="0"
                        FontWeight="Bold" HorizontalAlignment="Stretch" VerticalAlignment="Top"/>

                <Border Grid.Row="0" Grid.Column="3" Grid.ColumnSpan="3" Background="#E8F0FE" CornerRadius="10" Padding="10,8" Margin="8,0,0,0" VerticalAlignment="Bottom">
                    <StackPanel>
                        <TextBlock Text="Active Tenant" FontSize="12" FontWeight="Bold" Foreground="#193C78"/>
                        <TextBlock x:Name="lblCurrentTenant" Text="(not set)" FontWeight="Bold" Foreground="#193C78" TextTrimming="CharacterEllipsis"/>
                    </StackPanel>
                </Border>

                <!-- Tenant ID line -->
                <TextBlock Grid.Row="2" Grid.Column="0" Text="Directory (Tenant) ID:" FontWeight="SemiBold" VerticalAlignment="Center"/>
                <TextBox x:Name="txtTenantId" Grid.Row="2" Grid.Column="1" Height="28" Margin="0,2,0,2"/>

                <Button x:Name="btnCopyTenantId" Grid.Row="2" Grid.Column="2" Content="Copy" Margin="8,2,0,2" Padding="12,7" FontWeight="Bold"/>
                <TextBlock Grid.Row="2" Grid.Column="3" Margin="10,7,0,0">
                    <Hyperlink x:Name="lnkEntraOverview">Open Entra Overview</Hyperlink>
                </TextBlock>

                <Button x:Name="btnTenantIdHelp" Grid.Row="2" Grid.Column="4" Content="?" Margin="8,2,0,2"
                        Background="#3498DB" Foreground="White" BorderThickness="0" FontWeight="Bold"/>

                <TextBlock x:Name="lblTenantIdValid" Grid.Row="2" Grid.Column="5" Margin="0,2,0,2"
                           HorizontalAlignment="Right" VerticalAlignment="Center"
                           FontWeight="Bold" Foreground="#6B7280" Text="Not set"/>

                <!-- Tenant ID help -->
                <TextBlock Grid.Row="3" Grid.Column="1" Grid.ColumnSpan="5" Foreground="#6B7280" FontSize="12"
                           Text="Located in Entra ID → Overview → Directory (tenant) ID" TextWrapping="Wrap"/>

                <!-- Tenant Name line -->
                <TextBlock Grid.Row="5" Grid.Column="0" Text="SharePoint Tenant Prefix:" FontWeight="SemiBold" VerticalAlignment="Center"/>
                <TextBox x:Name="txtTenantName" Grid.Row="5" Grid.Column="1" Height="28" Margin="0,2,0,2"/>

                <Button x:Name="btnTenantNameHelp" Grid.Row="5" Grid.Column="2" Content="?" Margin="8,2,0,2"
                        Background="#3498DB" Foreground="White" BorderThickness="0" FontWeight="Bold"/>

                <TextBlock Grid.Row="5" Grid.Column="3" Grid.ColumnSpan="2" Margin="10,2,0,0" Foreground="#6B7280" FontSize="12" TextWrapping="Wrap">
                    Example: contoso (or contoso.onmicrosoft.com)
                </TextBlock>

                <Button x:Name="btnSetTenant" Grid.Row="5" Grid.Column="5" Content="Set Tenant"
                        Margin="8,2,0,2" Padding="12,7"
                        Background="#219653" Foreground="White" BorderThickness="0"
                        FontWeight="Bold"/>

                <!-- Tenant Name help -->
                <TextBlock Grid.Row="6" Grid.Column="1" Grid.ColumnSpan="4" Foreground="#6B7280" FontSize="12"
                           Text="Located in Microsoft 365 Admin Center → Settings → Domains → Initial domain" TextWrapping="Wrap"/>

                <TextBlock Grid.Row="6" Grid.Column="5" HorizontalAlignment="Right" Margin="0,0,0,0">
                    <Hyperlink x:Name="lnkDomains">Open Domains Page</Hyperlink>
                </TextBlock>

            </Grid>
        </Border>

        <!-- Admin Centers -->
        <Border Grid.Row="1" Background="#F0F5FA" CornerRadius="12" Padding="10" Margin="0,12,0,12">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Orientation="Vertical" Margin="4,0,4,8">
                    <TextBlock Text="Admin Centers" FontSize="12" FontWeight="Bold" Foreground="#6B7280"/>
                    <TextBlock Text="Click a tile to open the portal in your default browser" FontSize="13" Foreground="#374151"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" x:Name="svButtons" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <UniformGrid x:Name="ugButtons" Columns="4" Margin="2"/>
                </ScrollViewer>
            </Grid>
        </Border>

        <!-- Footer -->
        <Border Grid.Row="2" Background="#FAFAFC" CornerRadius="12" Padding="10" BorderBrush="#E5E7EB" BorderThickness="1">
            <DockPanel>
                <CheckBox x:Name="chkCloseToTray" Content="Close to tray" IsChecked="True" VerticalAlignment="Center"/>
                <TextBlock x:Name="lblStatus" DockPanel.Dock="Left" Margin="16,0,0,0" VerticalAlignment="Center" Foreground="#4B5563" Text="Status: Ready"/>
                <Button x:Name="btnExit" Content="Exit" DockPanel.Dock="Right" Width="90" FontWeight="Bold"/>
            </DockPanel>
        </Border>

    </Grid>
</Window>
"@

# Load XAML
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Named controls
$txtTenantId       = $window.FindName("txtTenantId")
$txtTenantName     = $window.FindName("txtTenantName")
$txtSearch         = $window.FindName("txtSearch")
$lblCurrentTenant  = $window.FindName("lblCurrentTenant")
$lblTenantIdValid  = $window.FindName("lblTenantIdValid")
$lblStatus         = $window.FindName("lblStatus")
$btnCopyTenantId   = $window.FindName("btnCopyTenantId")
$btnTenantIdHelp   = $window.FindName("btnTenantIdHelp")
$btnTenantNameHelp = $window.FindName("btnTenantNameHelp")
$btnSetTenant      = $window.FindName("btnSetTenant")
$btnReset          = $window.FindName("btnReset")
$btnExit           = $window.FindName("btnExit")
$chkCloseToTray    = $window.FindName("chkCloseToTray")
$lnkEntraOverview  = $window.FindName("lnkEntraOverview")
$lnkDomains        = $window.FindName("lnkDomains")
$svButtons         = $window.FindName("svButtons")
$ugButtons         = $window.FindName("ugButtons")

# Apply initial state
$txtTenantId.Text   = ($state.TenantId ?? "")
$txtTenantName.Text = ($state.TenantName ?? "")

# ----------------------------
# Tooltips (readable)
# ----------------------------
function New-ReadableToolTip {
    param([string]$Text)
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.TextWrapping = "Wrap"
    $tb.MaxWidth = 420
    $tb.Margin = "8"
    $tb
}

$txtTenantId.ToolTip = (New-ReadableToolTip "Directory (Tenant) ID in Entra ID Overview. Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
$txtTenantName.ToolTip = (New-ReadableToolTip "SharePoint tenant prefix from Initial domain. Example: contoso.onmicrosoft.com → enter: contoso")
$btnSetTenant.ToolTip = (New-ReadableToolTip "Save tenant inputs locally so tenant-aware links (SharePoint/OneDrive/Entra) can open correctly.")
$btnReset.ToolTip = (New-ReadableToolTip "Clears all fields and removes the saved config in %APPDATA%\PowerShell-Utility\M365Launcher\config.json")
$txtSearch.ToolTip = (New-ReadableToolTip "Type to filter the tiles by name/keywords.")

# ----------------------------
# Tray icon
# ----------------------------
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$notifyIcon.Text = "M365 Launcher"
$notifyIcon.Visible = $true

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$miShow = $trayMenu.Items.Add("Show")
$miHide = $trayMenu.Items.Add("Hide")
$trayMenu.Items.Add("-") | Out-Null
$miExit = $trayMenu.Items.Add("Exit")
$notifyIcon.ContextMenuStrip = $trayMenu

$miShow.Add_Click({ $window.Show(); $window.Activate() })
$miHide.Add_Click({ $window.Hide() })
$miExit.Add_Click({
    $notifyIcon.Visible = $false
    $window.Tag = "ForceExit"
    $window.Close()
})
$notifyIcon.Add_DoubleClick({ $window.Show(); $window.Activate() })

# ----------------------------
# UI Logic
# ----------------------------
$centers = Get-AdminCenters
$buttonMap = New-Object System.Collections.Generic.List[object]

function Resolve-CenterUrl {
    param($center)
    if ($null -eq $center) { return $null }
    if ($center.ContainsKey("StaticUrl")) { return [string]$center.StaticUrl }
    if ($center.ContainsKey("UrlBuilder")) { return & $center.UrlBuilder $state }
    $null
}

function Invoke-Center {
    param([Parameter(Mandatory)]$center)

    $name = [string]$center.Name
    $url  = Resolve-CenterUrl -center $center

    if (-not $url) {
        $lblStatus.Text = "Status: No URL for: $name"
        return
    }

    if ($center.Category -eq "Identity" -and -not (Test-TenantId $state.TenantId)) {
        [System.Windows.MessageBox]::Show(
            "Enter a valid Directory (Tenant) ID (GUID) to open tenant-context Entra links.",
            "Tenant ID required",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }

    $lblStatus.Text = "Status: Opening $name ..."
    if (-not (Open-Url -Url $url)) {
        $lblStatus.Text = "Status: Failed to open $name"
        [System.Windows.MessageBox]::Show("Could not open:`n$url", "Launch failed", "OK", "Error") | Out-Null
    } else {
        $lblStatus.Text = "Status: Opened $name"
    }
}

function Set-TenantUiState {
    $tid = ($txtTenantId.Text ?? "").Trim()
    $tname = Normalize-TenantName ($txtTenantName.Text ?? "")

    $isEmpty = [string]::IsNullOrWhiteSpace($tid)
    $isValid = (-not $isEmpty) -and (Test-TenantId $tid)

    if ($isEmpty) {
        $txtTenantId.Background = [System.Windows.Media.Brushes]::White
        $lblTenantIdValid.Text = "Not set"
        $lblTenantIdValid.Foreground = [System.Windows.Media.Brushes]::Gray
    } elseif ($isValid) {
        $txtTenantId.Background = (New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#EBFFEB")))
        $lblTenantIdValid.Text = "Valid ✅"
        $lblTenantIdValid.Foreground = (New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#19783C")))
    } else {
        $txtTenantId.Background = (New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#FFEBEB")))
        $lblTenantIdValid.Text = "Invalid ❌"
        $lblTenantIdValid.Foreground = (New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#A02828")))
    }

    $badgeId = if ($isValid) { $tid } else { "(not set)" }
    $badgeName = if (-not [string]::IsNullOrWhiteSpace($tname)) { $tname } else { "(no tenant prefix)" }
    $lblCurrentTenant.Text = "$badgeName  |  $badgeId"
}

function Apply-Filter {
    $q = ($txtSearch.Text ?? "").Trim().ToLowerInvariant()
    foreach ($entry in $buttonMap) {
        $b = $entry.Button
        $hay = ("{0} {1}" -f $entry.Name, $entry.Keywords).ToLowerInvariant()
        $b.Visibility = if ($q.Length -eq 0 -or $hay -like "*$q*") { "Visible" } else { "Collapsed" }
    }
}

function Recalc-Columns {
    # Auto-calc columns to fill width and reduce empty space
    # Tile width approx 230 incl margins; clamp 2..8
    $w = [Math]::Max(380, $svButtons.ActualWidth)
    $cols = [int][Math]::Floor(($w - 20) / 240)
    if ($cols -lt 2) { $cols = 2 }
    if ($cols -gt 8) { $cols = 8 }
    $ugButtons.Columns = $cols
}

function New-TileContent {
    param(
        [Parameter(Mandatory)][string]$Glyph,
        [Parameter(Mandatory)][string]$Text
    )

    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Orientation = "Horizontal"
    $sp.HorizontalAlignment = "Center"
    $sp.VerticalAlignment = "Center"

    $icon = New-Object System.Windows.Controls.TextBlock
    $icon.FontFamily = "Segoe MDL2 Assets"
    $icon.Text = [char]([Convert]::ToInt32($Glyph, 16))
    $icon.FontSize = 18
    $icon.Margin = "0,0,10,0"
    $icon.VerticalAlignment = "Center"

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = $Text
    $lbl.FontWeight = "SemiBold"
    $lbl.VerticalAlignment = "Center"
    $lbl.TextTrimming = "CharacterEllipsis"

    $sp.Children.Add($icon) | Out-Null
    $sp.Children.Add($lbl) | Out-Null
    $sp
}

function Build-Buttons {
    $ugButtons.Children.Clear()
    $buttonMap.Clear()

    foreach ($center in $centers) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $window.FindResource("TileButtonStyle")
        $btn.Tag = $center
        $btn.Height = 54
        $btn.Margin = "8"
        $btn.Foreground = [System.Windows.Media.Brushes]::White
        $btn.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($center.Color))
        $btn.BorderThickness = "0"
        $btn.Cursor = "Hand"

        $glyph = if ($center.ContainsKey("Icon") -and $center.Icon) { [string]$center.Icon } else { "E8A7" }
        $btn.Content = (New-TileContent -Glyph $glyph -Text $center.Name)

        # Readable tooltip per tile
        $tipText = if ($center.ContainsKey("Notes") -and $center.Notes) {
            "{0}`n{1}" -f $center.Notes, (Resolve-CenterUrl -center $center)
        } else {
            (Resolve-CenterUrl -center $center)
        }
        $btn.ToolTip = (New-ReadableToolTip $tipText)

        $btn.Add_Click({
            if ($null -eq $this.Tag) { return }
            Invoke-Center -center $this.Tag
        })

        $ugButtons.Children.Add($btn) | Out-Null

        $buttonMap.Add([pscustomobject]@{
            Button   = $btn
            Name     = $center.Name
            Keywords = ($center.Keywords ?? "")
        }) | Out-Null
    }

    Recalc-Columns
}

# ----------------------------
# Events
# ----------------------------
$txtTenantId.Add_TextChanged({ Set-TenantUiState })
$txtTenantName.Add_LostFocus({
    $txtTenantName.Text = Normalize-TenantName ($txtTenantName.Text ?? "")
    Set-TenantUiState
})

$txtSearch.Add_TextChanged({ Apply-Filter })

$btnCopyTenantId.Add_Click({
    $t = ($txtTenantId.Text ?? "").Trim()
    if ($t) { [System.Windows.Clipboard]::SetText($t) }
})

$btnSetTenant.Add_Click({
    $tid = ($txtTenantId.Text ?? "").Trim()
    $tname = Normalize-TenantName ($txtTenantName.Text ?? "")

    if (-not [string]::IsNullOrWhiteSpace($tid) -and -not (Test-TenantId $tid)) {
        [System.Windows.MessageBox]::Show("Directory (Tenant) ID must be a valid GUID.", "Invalid Tenant ID", "OK", "Warning") | Out-Null
        return
    }

    $state.TenantId = $tid
    $state.TenantName = $tname
    Save-Config ([pscustomobject]@{ tenantId = $state.TenantId; tenantName = $state.TenantName })

    # Rebuild tile tooltips (SharePoint/OneDrive/Entra URLs become tenant-aware)
    Build-Buttons
    Apply-Filter

    $lblStatus.Text = "Status: Tenant saved"
    Set-TenantUiState
})

$btnReset.Add_Click({
    $txtTenantId.Text = ""
    $txtTenantName.Text = ""
    $txtSearch.Text = ""

    $state.TenantId = ""
    $state.TenantName = ""

    Remove-Config

    Build-Buttons
    Apply-Filter
    Set-TenantUiState

    $lblStatus.Text = "Status: Reset complete"
})

$btnTenantIdHelp.Add_Click({
    [System.Windows.MessageBox]::Show(
@"
To find your Directory (Tenant) ID:

1) Go to https://entra.microsoft.com
2) Click: Overview
3) Copy: Directory (tenant) ID

Format:
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
"@,
        "Where to Find Tenant ID",
        "OK",
        "Information"
    ) | Out-Null
})

$btnTenantNameHelp.Add_Click({
    [System.Windows.MessageBox]::Show(
@"
To find your SharePoint tenant prefix:

1) Go to https://admin.microsoft.com
2) Settings → Domains
3) Find the Initial domain (example):
   contoso.onmicrosoft.com

Use only the first part:
   contoso

This builds:
https://contoso-admin.sharepoint.com
"@,
        "Where to Find SharePoint Tenant Prefix",
        "OK",
        "Information"
    ) | Out-Null
})

$lnkEntraOverview.Add_Click({ Open-Url "https://entra.microsoft.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/Overview" | Out-Null })
$lnkDomains.Add_Click({ Open-Url "https://admin.microsoft.com/#/domains" | Out-Null })

$btnExit.Add_Click({
    $notifyIcon.Visible = $false
    $window.Tag = "ForceExit"
    $window.Close()
})

$window.Add_SizeChanged({ Recalc-Columns })

$window.Add_Closing({
    if ($window.Tag -eq "ForceExit") { return }

    if ($chkCloseToTray.IsChecked) {
        $_.Cancel = $true
        $window.Hide()
        $notifyIcon.BalloonTipTitle = "M365 Launcher"
        $notifyIcon.BalloonTipText  = "Still running in the system tray."
        $notifyIcon.ShowBalloonTip(1200)
    } else {
        $notifyIcon.Visible = $false
    }
})

# ----------------------------
# Init
# ----------------------------
Build-Buttons
Set-TenantUiState
Apply-Filter

# Show window
$null = $window.ShowDialog()

# Cleanup
$notifyIcon.Visible = $false
$notifyIcon.Dispose()
