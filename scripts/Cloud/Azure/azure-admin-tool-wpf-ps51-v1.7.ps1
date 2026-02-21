<#
.SYNOPSIS
    Azure Admin Dashboard Quick Launcher (Commercial) - WPF/XAML (PS 5.1 compatible)
.DESCRIPTION
    WPF/XAML-based Azure admin launcher with:
      - Tenant ID (optional) for Entra tenant-context links
      - Environment dropdown (Prod/Sandbox) with auto-swapped Subscription ID
      - Resource Group (optional) for RG-scoped deep links
      - Search box (top-right) to filter tiles
      - Favorites row (pin your top 6)
      - Clipboard copy buttons (Tenant/Sub/RG)
      - Section headers + iconography + 3D tile buttons
      - Config persistence to %APPDATA%
      - Reset button clears fields + removes saved config
      - Close-to-tray (optional) with tray icon

.NOTES
    Author: PowerShell Utility Collection
    Version: 1.7
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
# Small helpers (PS 5.1 safe)
# ----------------------------
function Nz {
    param([object]$Value, [string]$Default = "")
    if ($null -eq $Value) { return $Default }
    $s = [string]$Value
    if ([string]::IsNullOrWhiteSpace($s)) { return $Default }
    return $s
}

function Test-Guid {
    param([string]$Value)
    $g = [Guid]::Empty
    [Guid]::TryParse((Nz $Value).Trim(), [ref]$g)
}

function Open-Url {
    param([Parameter(Mandatory)][string]$Url)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Url
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Set-ClipboardText {
    param([string]$Text)
    try {
        if (-not [string]::IsNullOrWhiteSpace($Text)) {
            [System.Windows.Clipboard]::SetText($Text)
        }
    } catch {}
}

# ----------------------------
# Persistence
# ----------------------------
$AppRoot    = Join-Path $env:APPDATA "PowerShell-Utility\AzureLauncher"
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
    return [pscustomobject]@{}
}
function Save-Config([object]$cfg) {
    Ensure-AppRoot
    $cfg | ConvertTo-Json -Depth 8 | Set-Content -Path $ConfigPath -Encoding UTF8
}
function Remove-Config {
    if (Test-Path $ConfigPath) {
        try { Remove-Item $ConfigPath -Force -ErrorAction Stop | Out-Null } catch {}
    }
}

# ----------------------------
# State (config-backed)
# ----------------------------
$cfg = Load-Config

# Defaults
$defaultEnv = "Sandbox"
if (-not [string]::IsNullOrWhiteSpace((Nz $cfg.environment))) { $defaultEnv = (Nz $cfg.environment) }

$defaultFavorites = @(
    "Azure Portal Home",
    "Resource Groups",
    "Log Analytics Workspaces",
    "Key Vaults",
    "Cost Management",
    "Entra ID Admin Center"
)

$favs = @()
try {
    if ($cfg.favorites) {
        foreach ($x in $cfg.favorites) { if (-not [string]::IsNullOrWhiteSpace((Nz $x))) { $favs += (Nz $x) } }
    }
} catch {}
if ($favs.Count -lt 6) { $favs = $defaultFavorites }

$state = [pscustomobject]@{
    TenantId         = Nz $cfg.tenantId
    Environment      = $defaultEnv
    Subscriptions    = [pscustomobject]@{
        Prod    = Nz $cfg.subscriptions.Prod
        Sandbox = Nz $cfg.subscriptions.Sandbox
    }
    ResourceGroup    = Nz $cfg.resourceGroup
    Favorites        = $favs
}

# ----------------------------
# URL builders (Commercial)
# ----------------------------
function Get-EntraUrl {
    param([string]$TenantId)
    if (Test-Guid $TenantId) { return ("https://entra.microsoft.com/#/tenant/{0}" -f $TenantId) }
    return "https://entra.microsoft.com"
}

function Get-SubscriptionResourceUrl {
    param(
        [Parameter(Mandatory)][string]$SubscriptionId,
        [Parameter(Mandatory)][string]$ProviderType
    )
    return ("https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/{0}/scope/%2Fsubscriptions%2F{1}" -f
        [uri]::EscapeDataString($ProviderType), [uri]::EscapeDataString($SubscriptionId))
}

function Get-ResourceGroupsUrl {
    if (Test-Guid $script:state.Subscriptions.($script:state.Environment)) {
        $sid = $script:state.Subscriptions.($script:state.Environment)
        return ("https://portal.azure.com/#view/HubsExtension/BrowseResourceGroups/scope/%2Fsubscriptions%2F{0}" -f [uri]::EscapeDataString($sid))
    }
    return "https://portal.azure.com/#view/HubsExtension/BrowseResourceGroups"
}

function Get-ResourceGroupUrl {
    $sid = $script:state.Subscriptions.($script:state.Environment)
    if ((Test-Guid $sid) -and (-not [string]::IsNullOrWhiteSpace($script:state.ResourceGroup))) {
        $sub = [uri]::EscapeDataString($sid)
        $rg  = [uri]::EscapeDataString($script:state.ResourceGroup)
        return ("https://portal.azure.com/#@/resource/subscriptions/{0}/resourceGroups/{1}" -f $sub, $rg)
    }
    return Get-ResourceGroupsUrl
}

# ----------------------------
# Tiles
# ----------------------------
function Get-AzureCenters {
    @(
        # Core
        @{ Name="Azure Portal Home"; Category="Core"; Color="#2980B9"; Notes="Azure Portal (Commercial)"; StaticUrl="https://portal.azure.com"; Keywords="azure portal home"; Icon="E7AD" }
        @{ Name="Subscriptions"; Category="Core"; Color="#1F7A8C"; Notes="Subscriptions blade"; StaticUrl="https://portal.azure.com/#view/Microsoft_Azure_Billing/SubscriptionsBlade"; Keywords="subscriptions billing"; Icon="E8D7" }
        @{ Name="Resource Groups"; Category="Core"; Color="#3A6EA5"; Notes="Resource groups (scoped if Subscription ID provided)"; Keywords="resource groups rg"; Icon="E8A7"
           UrlBuilder = { param($s) Get-ResourceGroupsUrl } }
        @{ Name="Specific Resource Group"; Category="Core"; Color="#2C3E50"; Notes="Opens RG (requires Subscription ID + Resource Group for exact deep link)"; Keywords="resource group open"; Icon="E8A7"
           UrlBuilder = { param($s) Get-ResourceGroupUrl } }
        @{ Name="Cost Management"; Category="Core"; Color="#16A085"; Notes="Cost Management + Billing"; StaticUrl="https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/overview"; Keywords="cost management billing spend"; Icon="E8C7" }
        @{ Name="Advisor"; Category="Core"; Color="#E67E22"; Notes="Azure Advisor"; StaticUrl="https://portal.azure.com/#view/Microsoft_Azure_ExpertRecommendations/AdvisorMenuBlade/~/overview"; Keywords="advisor recommendations"; Icon="E9D9" }
        @{ Name="Monitor"; Category="Ops"; Color="#34495E"; Notes="Azure Monitor"; StaticUrl="https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade"; Keywords="monitor metrics logs"; Icon="E9F9" }
        @{ Name="Activity Log"; Category="Ops"; Color="#8E44AD"; Notes="Activity Log"; StaticUrl="https://portal.azure.com/#view/Microsoft_Azure_ActivityLog/ActivityLogBlade"; Keywords="activity log audit"; Icon="E81C" }

        # Identity / Governance
        @{ Name="Entra ID Admin Center"; Category="Identity"; Color="#9B59B6"; Notes="Tenant-context if Tenant ID provided"; Keywords="entra aad azuread identity"; Icon="E72E"
           UrlBuilder = { param($s) Get-EntraUrl -TenantId $s.TenantId } }
        @{ Name="Access Control (IAM)"; Category="Governance"; Color="#6C5CE7"; Notes="IAM for subscriptions/resources"; StaticUrl="https://portal.azure.com/#view/Microsoft_Azure_AccessControl/IAMMenuBlade/~/RoleAssignments"; Keywords="rbac iam roles"; Icon="E8D7" }
        @{ Name="Azure Policy"; Category="Governance"; Color="#00B894"; Notes="Policy"; StaticUrl="https://portal.azure.com/#view/Microsoft_Azure_Policy/PolicyMenuBlade/~/Overview"; Keywords="policy governance"; Icon="E8EF" }
        @{ Name="Defender for Cloud"; Category="Security"; Color="#C0392B"; Notes="Microsoft Defender for Cloud"; StaticUrl="https://portal.azure.com/#view/Microsoft_Azure_Security/SecurityMenuBlade/~/overview"; Keywords="defender cloud security posture"; Icon="EA18" }

        # Ops / Observability
        @{ Name="Log Analytics Workspaces"; Category="Ops"; Color="#2D3436"; Notes="Workspaces"; StaticUrl="https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.OperationalInsights%2Fworkspaces"; Keywords="log analytics law"; Icon="E9F9" }
        @{ Name="Application Insights"; Category="Ops"; Color="#0984E3"; Notes="App Insights"; StaticUrl="https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Insights%2Fcomponents"; Keywords="app insights apm"; Icon="E9D2" }
        @{ Name="Alerts"; Category="Ops"; Color="#D63031"; Notes="Alerts"; StaticUrl="https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AlertsManagementBlade"; Keywords="alerts monitor"; Icon="EA39" }
        @{ Name="Service Health"; Category="Ops"; Color="#F39C12"; Notes="Service Health"; StaticUrl="https://portal.azure.com/#view/Microsoft_Azure_Health/ServiceHealthBlade"; Keywords="service health outages"; Icon="E95A" }
        @{ Name="Resource Graph Explorer"; Category="Ops"; Color="#636E72"; Notes="Azure Resource Graph"; StaticUrl="https://portal.azure.com/#view/HubsExtension/ArgQueryBlade"; Keywords="resource graph arg query"; Icon="E8D2" }

        # Compute / Apps
        @{ Name="Virtual Machines"; Category="Compute"; Color="#0E7490"; Notes="VMs (scoped if Subscription ID provided)"; Keywords="vms compute"; Icon="E7F8"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.Compute/virtualMachines" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Compute%2FvirtualMachines" }
           } }
        @{ Name="App Services"; Category="Apps"; Color="#2563EB"; Notes="App Service"; Keywords="app service webapp"; Icon="E7C3"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.Web/sites" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Web%2Fsites" }
           } }
        @{ Name="Function Apps"; Category="Apps"; Color="#7C3AED"; Notes="Functions"; Keywords="functions function app"; Icon="E946"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.Web/sites" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Web%2Fsites" }
           } }
        @{ Name="AKS Clusters"; Category="Containers"; Color="#1D4ED8"; Notes="AKS"; Keywords="aks kubernetes"; Icon="E8B7"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.ContainerService/managedClusters" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.ContainerService%2FmanagedClusters" }
           } }
        @{ Name="Container Apps"; Category="Containers"; Color="#0F766E"; Notes="Container Apps"; Keywords="container apps"; Icon="E8B7"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.App/containerApps" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.App%2FcontainerApps" }
           } }

        # Network
        @{ Name="Virtual Networks"; Category="Network"; Color="#00B0F0"; Notes="VNets"; Keywords="vnet networking"; Icon="E968"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.Network/virtualNetworks" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Network%2FvirtualNetworks" }
           } }
        @{ Name="Network Security Groups"; Category="Network"; Color="#0891B2"; Notes="NSGs"; Keywords="nsg security group"; Icon="E72E"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.Network/networkSecurityGroups" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Network%2FnetworkSecurityGroups" }
           } }
        @{ Name="Azure Firewall"; Category="Network"; Color="#B91C1C"; Notes="Firewall"; Keywords="azure firewall"; Icon="E814"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.Network/azureFirewalls" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Network%2FazureFirewalls" }
           } }
        @{ Name="Application Gateways"; Category="Network"; Color="#F97316"; Notes="App Gateway"; Keywords="application gateway agw"; Icon="E968"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.Network/applicationGateways" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Network%2FapplicationGateways" }
           } }
        @{ Name="Private DNS Zones"; Category="Network"; Color="#10B981"; Notes="Private DNS"; Keywords="private dns"; Icon="E774"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.Network/privateDnsZones" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Network%2FprivateDnsZones" }
           } }

        # Data / Secrets
        @{ Name="Storage Accounts"; Category="Data"; Color="#0EA5E9"; Notes="Storage"; Keywords="storage accounts"; Icon="E7C3"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.Storage/storageAccounts" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Storage%2FstorageAccounts" }
           } }
        @{ Name="Key Vaults"; Category="Data"; Color="#111827"; Notes="Key Vault"; Keywords="key vault secrets keys"; Icon="E8D7"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.KeyVault/vaults" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.KeyVault%2Fvaults" }
           } }
        @{ Name="SQL Servers"; Category="Data"; Color="#334155"; Notes="SQL Servers"; Keywords="sql server database"; Icon="E8A5"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.Sql/servers" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.Sql%2Fservers" }
           } }
        @{ Name="Cosmos DB"; Category="Data"; Color="#7F1D1D"; Notes="Cosmos DB"; Keywords="cosmos db"; Icon="E9F9"
           UrlBuilder = { param($s)
                $sid = $s.Subscriptions.($s.Environment)
                if (Test-Guid $sid) { Get-SubscriptionResourceUrl -SubscriptionId $sid -ProviderType "Microsoft.DocumentDB/databaseAccounts" }
                else { "https://portal.azure.com/#view/HubsExtension/BrowseResourceType/resourceType/Microsoft.DocumentDB%2FdatabaseAccounts" }
           } }
    )
}

# ----------------------------
# XAML UI
# ----------------------------
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Azure Administration Dashboard (Commercial)"
        Height="900" Width="1140"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize"
        Background="#F0F5FA">
    <Window.Resources>
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
                                    CornerRadius="10"
                                    Background="{TemplateBinding Background}"
                                    SnapsToDevicePixels="True">
                                <Border.Effect>
                                    <DropShadowEffect Color="#000000"
                                                      BlurRadius="12"
                                                      ShadowDepth="3"
                                                      Opacity="0.28"/>
                                </Border.Effect>

                                <Grid>
                                    <Border CornerRadius="10" Background="#000000" Opacity="0.08"/>
                                    <Border CornerRadius="10" Margin="1">
                                        <Border.Background>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#FFFFFF" Offset="0" />
                                                <GradientStop Color="#FFFFFF" Offset="0.32" />
                                                <GradientStop Color="#FFFFFF" Offset="1" />
                                            </LinearGradientBrush>
                                        </Border.Background>
                                        <Border.OpacityMask>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#FF000000" Offset="0" />
                                                <GradientStop Color="#22000000" Offset="0.32" />
                                                <GradientStop Color="#00000000" Offset="1" />
                                            </LinearGradientBrush>
                                        </Border.OpacityMask>
                                    </Border>

                                    <ContentPresenter HorizontalAlignment="Center"
                                                      VerticalAlignment="Center"
                                                      Margin="14,8"/>
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
                                        <DropShadowEffect Color="#000000" BlurRadius="14" ShadowDepth="4" Opacity="0.34"/>
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

        <!-- Compact (favorites) tile style -->
        <Style x:Key="FavButtonStyle" TargetType="Button" BasedOn="{StaticResource TileButtonStyle}">
            <Setter Property="Height" Value="40"/>
            <Setter Property="Margin" Value="5"/>
        </Style>
    </Window.Resources>

    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Configuration -->
        <Border Grid.Row="0" Background="#FAFAFC" CornerRadius="10" Padding="14" BorderBrush="#E5E7EB" BorderThickness="1">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="10"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="10"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="230"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="92"/>
                    <ColumnDefinition Width="92"/>
                    <ColumnDefinition Width="260"/>
                    <ColumnDefinition Width="92"/>
                </Grid.ColumnDefinitions>

                <!-- Header + search -->
                <StackPanel Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="3" Orientation="Vertical">
                    <TextBlock Text="Configuration" FontSize="12" FontWeight="Bold" Foreground="#6B7280"/>
                    <TextBlock Text="Azure Administration Dashboard" FontSize="20" FontWeight="Bold" Foreground="#111827"/>
                </StackPanel>

                <StackPanel Grid.Row="0" Grid.Column="4" Grid.ColumnSpan="2" Orientation="Vertical" HorizontalAlignment="Right">
                    <TextBlock Text="Search" FontSize="12" FontWeight="Bold" Foreground="#6B7280" HorizontalAlignment="Right"/>
                    <TextBox x:Name="txtSearch" Width="320" Height="28" Margin="0,4,0,0" HorizontalAlignment="Right"/>
                </StackPanel>

                <Button x:Name="btnReset" Grid.Row="0" Grid.Column="2" Content="Reset"
                        Margin="8,4,0,0" Padding="12,7"
                        Background="#777777" Foreground="White" BorderThickness="0"
                        FontWeight="Bold" HorizontalAlignment="Stretch" VerticalAlignment="Top"/>

                <!-- Tenant ID -->
                <TextBlock Grid.Row="2" Grid.Column="0" Text="Directory (Tenant) ID (optional):" FontWeight="SemiBold" VerticalAlignment="Center"/>
                <TextBox x:Name="txtTenantId" Grid.Row="2" Grid.Column="1" Height="28" Margin="0,2,0,2"/>

                <Button x:Name="btnTenantCopy" Grid.Row="2" Grid.Column="2" Content="Copy" Margin="8,2,0,2" Padding="12,7" FontWeight="Bold"/>
                <Button x:Name="btnTenantHelp" Grid.Row="2" Grid.Column="3" Content="?" Margin="8,2,0,2"
                        Background="#3498DB" Foreground="White" BorderThickness="0" FontWeight="Bold"/>

                <TextBlock Grid.Row="3" Grid.Column="1" Grid.ColumnSpan="5" Foreground="#6B7280" FontSize="12"
                           Text="Entra ID → Overview → Directory (tenant) ID (used for tenant-context Entra links)" TextWrapping="Wrap"/>

                <!-- Environment + Subscription -->
                <TextBlock Grid.Row="5" Grid.Column="0" Text="Environment:" FontWeight="SemiBold" VerticalAlignment="Center"/>
                <ComboBox x:Name="cmbEnv" Grid.Row="5" Grid.Column="1" Height="28" Margin="0,2,0,2" SelectedIndex="0">
                    <ComboBoxItem Content="Sandbox"/>
                    <ComboBoxItem Content="Prod"/>
                </ComboBox><TextBlock Grid.Row="5" Grid.Column="2" Text="Subscription ID:" FontWeight="SemiBold" VerticalAlignment="Center" Margin="8,0,0,0"/>
                <TextBox x:Name="txtSubscriptionId" Grid.Row="5" Grid.Column="3" Height="28" Margin="8,2,0,2"/>

                <Button x:Name="btnSubCopy" Grid.Row="5" Grid.Column="5" Content="Copy" Margin="8,2,0,2" Padding="12,7" FontWeight="Bold" VerticalAlignment="Top"/>

                <Button x:Name="btnSave" Grid.Row="5" Grid.Column="2" Grid.ColumnSpan="2" Content="Save"
                        Margin="8,2,0,2" Padding="12,7"
                        Background="#219653" Foreground="White" BorderThickness="0"
                        FontWeight="Bold" HorizontalAlignment="Right" Width="90"/>

                <!-- Resource Group (optional) -->
                <TextBlock Grid.Row="6" Grid.Column="0" Text="Resource Group (optional):" FontWeight="SemiBold" VerticalAlignment="Center"/>
                <TextBox x:Name="txtResourceGroup" Grid.Row="6" Grid.Column="1" Height="28" Margin="0,4,0,0"/>
                <Button x:Name="btnRgCopy" Grid.Row="6" Grid.Column="2" Content="Copy" Margin="8,4,0,0" Padding="12,7" FontWeight="Bold"/>
                <TextBlock Grid.Row="6" Grid.Column="3" Grid.ColumnSpan="3" Foreground="#6B7280" FontSize="12" Margin="8,6,0,0"
                           Text="Optional. Used for deep-linking to a specific resource group (requires Subscription ID)." TextWrapping="Wrap"/>

            </Grid>
        </Border>

        <!-- Tiles -->
        <Border Grid.Row="1" Background="#F0F5FA" CornerRadius="10" Padding="10" Margin="0,12,0,12">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="10"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Orientation="Vertical" Margin="4,0,4,8">
                    <TextBlock Text="Azure Portals &amp; Blades" FontSize="12" FontWeight="Bold" Foreground="#6B7280"/>
                    <TextBlock Text="Click a tile to open the portal in your default browser" FontSize="13" Foreground="#374151"/>
                </StackPanel>

                <StackPanel Grid.Row="1" Orientation="Vertical" Margin="4,0,4,8">
                    <TextBlock Text="Favorites" FontSize="12" FontWeight="Bold" Foreground="#6B7280"/>
                    <TextBlock Text="Pinned tiles (top 6). Edit in config.json later (favorites array)." FontSize="12" Foreground="#6B7280"/>
                </StackPanel>

                <UniformGrid Grid.Row="3" x:Name="ugFavs" Columns="6" Margin="0,0,0,6"/>

                <ScrollViewer Grid.Row="4" x:Name="svButtons" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <UniformGrid x:Name="ugButtons" Columns="4" Margin="2"/>
                </ScrollViewer>
            </Grid>
        </Border>

        <!-- Footer -->
        <Border Grid.Row="2" Background="#FAFAFC" CornerRadius="10" Padding="10" BorderBrush="#E5E7EB" BorderThickness="1">
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
try {
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    $msg = "Failed to load XAML. This usually means invalid XML (common: unescaped & as &amp;).`n`n$($_.Exception.Message)"
    try { [System.Windows.MessageBox]::Show($msg, "XAML Load Error", "OK", "Error") | Out-Null } catch {}
    Write-Error $msg
    return
}

# Controls
$txtTenantId       = $window.FindName("txtTenantId")
$txtSubscriptionId = $window.FindName("txtSubscriptionId")
$txtResourceGroup  = $window.FindName("txtResourceGroup")
$txtSearch         = $window.FindName("txtSearch")
$cmbEnv            = $window.FindName("cmbEnv")
$btnSave           = $window.FindName("btnSave")
$btnReset          = $window.FindName("btnReset")
$btnExit           = $window.FindName("btnExit")
$btnTenantHelp     = $window.FindName("btnTenantHelp")
$btnTenantCopy     = $window.FindName("btnTenantCopy")
$btnSubCopy        = $window.FindName("btnSubCopy")
$btnRgCopy         = $window.FindName("btnRgCopy")
$chkCloseToTray    = $window.FindName("chkCloseToTray")
$lblStatus         = $window.FindName("lblStatus")
$svButtons         = $window.FindName("svButtons")
$ugButtons         = $window.FindName("ugButtons")
$ugFavs            = $window.FindName("ugFavs")

# Initial state
$txtTenantId.Text = Nz $state.TenantId
$txtResourceGroup.Text = Nz $state.ResourceGroup

# Set env selection
if ($state.Environment -eq "Prod") { $cmbEnv.SelectedIndex = 1 } else { $cmbEnv.SelectedIndex = 0 }

# Set subscription field based on env
function Get-SelectedEnv {
    $item = $cmbEnv.SelectedItem
    if ($null -eq $item) { return "Sandbox" }
    $c = $item.Content
    if ($c -eq "Prod") { return "Prod" }
    return "Sandbox"
}

function Sync-SubscriptionTextFromEnv {
    $envName = Get-SelectedEnv
    $script:state.Environment = $envName
    $sid = Nz $script:state.Subscriptions.$envName
    $txtSubscriptionId.Text = $sid
}

Sync-SubscriptionTextFromEnv

# Tooltips (readable)
function New-ReadableToolTip {
    param([string]$Text)
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.TextWrapping = "Wrap"
    $tb.MaxWidth = 460
    $tb.Margin = "8"
    return $tb
}
$txtTenantId.ToolTip = (New-ReadableToolTip "Optional. Used for tenant-context Entra links. Find in Entra ID → Overview → Directory (tenant) ID.")
$cmbEnv.ToolTip = (New-ReadableToolTip "Switch environment. Subscription ID auto-swaps between Prod/Sandbox.")
$txtSubscriptionId.ToolTip = (New-ReadableToolTip "Subscription ID for the selected environment. Edit it and click Save to persist.")
$txtResourceGroup.ToolTip = (New-ReadableToolTip "Optional. If provided with Subscription ID, 'Specific Resource Group' opens directly to that RG.")
$txtSearch.ToolTip = (New-ReadableToolTip "Type to filter tiles by name/keywords.")

# Tray icon
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$notifyIcon.Text = "Azure Launcher"
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

# Centers + button map
$centers = Get-AzureCenters
$buttonMap = New-Object System.Collections.Generic.List[object]
$favButtons = New-Object System.Collections.Generic.List[object]

function Resolve-CenterUrl {
    param($center)
    if ($null -eq $center) { return $null }
    if ($center.ContainsKey("StaticUrl")) { return [string]$center.StaticUrl }
    if ($center.ContainsKey("UrlBuilder")) { return & $center.UrlBuilder $script:state }
    return $null
}

function Invoke-Center {
    param([Parameter(Mandatory)]$center)
    $name = [string]$center.Name
    $url  = Resolve-CenterUrl -center $center

    if ([string]::IsNullOrWhiteSpace($url)) {
        $lblStatus.Text = "Status: No URL for $name"
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

function Apply-Filter {
    $q = (Nz $txtSearch.Text).Trim().ToLowerInvariant()

    foreach ($entry in $buttonMap) {
        $b = $entry.Button
        $hay = ("{0} {1}" -f $entry.Name, $entry.Keywords).ToLowerInvariant()
        if ($q.Length -eq 0 -or $hay -like "*$q*") { $b.Visibility = "Visible" } else { $b.Visibility = "Collapsed" }
    }

    # Favorites: hide any favorite that doesn't match search (keeps UX consistent)
    foreach ($entry in $favButtons) {
        $b = $entry.Button
        $hay = ("{0} {1}" -f $entry.Name, $entry.Keywords).ToLowerInvariant()
        if ($q.Length -eq 0 -or $hay -like "*$q*") { $b.Visibility = "Visible" } else { $b.Visibility = "Collapsed" }
    }
}

function Recalc-Columns {
    $w = [Math]::Max(420, $svButtons.ActualWidth)
    $cols = [int][Math]::Floor(($w - 20) / 240)
    if ($cols -lt 2) { $cols = 2 }
    if ($cols -gt 8) { $cols = 8 }
    $ugButtons.Columns = $cols
}

function New-TileContent {
    param([string]$GlyphHex, [string]$Text, [int]$FontSize = 18)
    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Orientation = "Horizontal"
    $sp.HorizontalAlignment = "Center"
    $sp.VerticalAlignment = "Center"

    $icon = New-Object System.Windows.Controls.TextBlock
    $icon.FontFamily = "Segoe MDL2 Assets"
    $icon.Text = [char]([Convert]::ToInt32($GlyphHex, 16))
    $icon.FontSize = $FontSize
    $icon.Margin = "0,0,10,0"
    $icon.VerticalAlignment = "Center"

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = $Text
    $lbl.FontWeight = "SemiBold"
    $lbl.VerticalAlignment = "Center"
    $lbl.TextTrimming = "CharacterEllipsis"

    $sp.Children.Add($icon) | Out-Null
    $sp.Children.Add($lbl) | Out-Null
    return $sp
}

function Get-IsFavorite {
    param([string]$Name)
    foreach ($n in $script:state.Favorites) {
        if ((Nz $n) -eq $Name) { return $true }
    }
    return $false
}

function Normalize-Favorites {
    # Ensure non-empty strings, unique, max 6
    $seen = @{}
    $out = @()
    foreach ($n in $script:state.Favorites) {
        $x = (Nz $n).Trim()
        if ([string]::IsNullOrWhiteSpace($x)) { continue }
        if (-not $seen.ContainsKey($x)) {
            $seen[$x] = $true
            $out += $x
        }
    }
    if ($out.Count -gt 6) { $out = $out[0..5] }
    while ($out.Count -lt 6) { $out += "" }
    $script:state.Favorites = $out
}


function Fade-Opacity {
    param(
        [Parameter(Mandatory=$true)] [System.Windows.UIElement]$Element,
        [Parameter(Mandatory=$true)] [double]$To,
        [int]$Milliseconds = 140
    )
    try {
        $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $anim.To = $To
        $anim.Duration = (New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds($Milliseconds)))
        $anim.AccelerationRatio = 0.2
        $anim.DecelerationRatio = 0.8
        $Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
    } catch {
        # Fallback if animation fails
        $Element.Opacity = $To
    }
}

function Set-StarVisual {
    param(
        [Parameter(Mandatory=$true)] $StarButton,
        [Parameter(Mandatory=$true)] [bool]$IsFav
    )
    # Avoid Unicode encoding issues in PS5.1 by using explicit chars
    $filled = [char]0x2605   # ★
    $empty  = [char]0x2606   # ☆

    if ($IsFav) {
        $StarButton.Content = $filled
        $StarButton.Foreground = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(245, 201, 66)))  # subtle gold
        $StarButton.Opacity = 1
    } else {
        $StarButton.Content = $empty
        $StarButton.Foreground = [System.Windows.Media.Brushes]::White
        # keep hidden unless hovered
        if ($StarButton.Opacity -gt 0) { $StarButton.Opacity = 0 }
    }
}

function New-PinContextMenu {
    param([string]$CenterName)

    $cm = New-Object System.Windows.Controls.ContextMenu
    $mi = New-Object System.Windows.Controls.MenuItem
    $mi.Tag = $CenterName
    $mi.Header = "Pin to Favorites"
    $mi.Add_Click({
        param($sender,$args)
        Toggle-Favorite -Name ([string]$sender.Tag)
    })
    $cm.Items.Add($mi) | Out-Null

    $cm.Add_Opened({
        # Update header to reflect current state
        $name = [string]$mi.Tag
        if (Get-IsFavorite -Name $name) { $mi.Header = "Unpin from Favorites" } else { $mi.Header = "Pin to Favorites" }
    })

    return $cm
}

function Toggle-Favorite {
    param([string]$Name)

    $cur = @()
    foreach ($n in $script:state.Favorites) { $cur += (Nz $n) }

    $exists = $false
    foreach ($n in $cur) { if ($n -eq $Name) { $exists = $true; break } }

    if ($exists) {
        $script:state.Favorites = @($cur | Where-Object { $_ -ne $Name })
        $lblStatus.Text = "Status: Unpinned '$Name'"
    } else {
        $script:state.Favorites = @($Name) + $cur
        $lblStatus.Text = "Status: Pinned '$Name'"
    }

    Normalize-Favorites
    Persist-State

    # Rebuild favorites and refresh all star icons
    Build-Favorites
    Update-AllStarIcons
    Apply-Filter
}

function New-StarButton {
    param([string]$CenterName)

    $b = New-Object System.Windows.Controls.Button
    $b.Width = 22
    $b.Height = 22
    $b.HorizontalAlignment = "Right"
    $b.VerticalAlignment = "Top"
    $b.Margin = "0"
    $b.Padding = "0"
    $b.Background = [System.Windows.Media.Brushes]::Transparent
    $b.BorderThickness = "0"
    $b.Cursor = "Hand"
    $b.Tag = $CenterName
    $b.ToolTip = (New-ReadableToolTip "Pin/unpin this tile to Favorites")

    # Render star reliably on PS5.1
    $b.FontFamily = (New-Object System.Windows.Media.FontFamily("Segoe UI Symbol"))
    $b.FontSize = 16
    $b.FontWeight = "Bold"
    $b.Opacity = 0

    Set-StarVisual -StarButton $b -IsFav (Get-IsFavorite -Name $CenterName)
$b.Add_Click({
        param($sender,$args)
        # prevent parent tile click
        if ($args -and $args.PSObject.Properties.Match("Handled").Count -gt 0) { $args.Handled = $true }
        Toggle-Favorite -Name ([string]$sender.Tag)
    })

    return $b
}

function Update-AllStarIcons {
    foreach ($entry in $buttonMap) {
        if ($null -ne $entry.StarButton) {
            Set-StarVisual -StarButton $entry.StarButton -IsFav (Get-IsFavorite -Name $entry.Name)
        }
    }
    foreach ($entry in $favButtons) {
        if ($null -ne $entry.StarButton) {
            Set-StarVisual -StarButton $entry.StarButton -IsFav $true
        }
    }
}

function Build-Favorites {
    $ugFavs.Children.Clear()
    $favButtons.Clear()

    # Ensure exactly 6 pins
    $pins = @()
    foreach ($n in $script:state.Favorites) { if (-not [string]::IsNullOrWhiteSpace((Nz $n))) { $pins += (Nz $n) } }
    while ($pins.Count -lt 6) { $pins += "" }
    if ($pins.Count -gt 6) { $pins = $pins[0..5] }

    foreach ($pinName in $pins) {
        $center = $null
        foreach ($c in $centers) { if ($c.Name -eq $pinName) { $center = $c; break } }

        if ($null -eq $center) {
            # placeholder button
            $ph = New-Object System.Windows.Controls.Button
            $ph.Style = $window.FindResource("FavButtonStyle")
            $ph.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#9CA3AF"))
            $ph.Content = (New-TileContent -GlyphHex "E711" -Text "Pin…" -FontSize 14)
            $ph.ToolTip = (New-ReadableToolTip "Edit favorites in config.json (favorites array).")
            $ph.IsEnabled = $false
            $ugFavs.Children.Add($ph) | Out-Null
            continue
        }

        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $window.FindResource("FavButtonStyle")
        $btn.Tag = $center
        $btn.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($center.Color))

        $glyph = "E8A7"
        if ($center.ContainsKey("Icon") -and -not [string]::IsNullOrWhiteSpace([string]$center.Icon)) { $glyph = [string]$center.Icon }
        $grid = New-Object System.Windows.Controls.Grid
        $grid.Margin = "0"

        # Main content (centered)
        $main = (New-TileContent -GlyphHex $glyph -Text $center.Name -FontSize 15)
        $grid.Children.Add($main) | Out-Null

        # Star overlay (top-right corner)
        $star = (New-StarButton -CenterName $center.Name)
        $star.HorizontalAlignment = "Right"
        $star.VerticalAlignment   = "Top"
        $star.Margin              = "6"
        $star.Width               = 22
        $star.Height              = 22
        $grid.Children.Add($star) | Out-Null

        $btn.Content = $grid

        # Right-click pin/unpin
        $btn.ContextMenu = (New-PinContextMenu -CenterName $center.Name)
        $star.ContextMenu = $btn.ContextMenu

        # Star hover (animated)
        $btn.Add_MouseEnter({
            # On hover: show (fade in) even if not favorited
            Fade-Opacity -Element $star -To 1 -Milliseconds 140
        })
        $btn.Add_MouseLeave({
            # On leave: hide (fade out) only if not favorited
            if (-not (Get-IsFavorite -Name $center.Name)) {
                Fade-Opacity -Element $star -To 0 -Milliseconds 140
            }
        })

        $tip = $center.Notes
        $u = Resolve-CenterUrl -center $center
        if (-not [string]::IsNullOrWhiteSpace($u)) {
            if (-not [string]::IsNullOrWhiteSpace($tip)) { $tip = ("{0}`n{1}" -f $tip, $u) } else { $tip = $u }
        }
        $btn.ToolTip = (New-ReadableToolTip $tip)

        $btn.Add_Click({
            if ($null -eq $this.Tag) { return }
            Invoke-Center -center $this.Tag
        })

        $ugFavs.Children.Add($btn) | Out-Null
        $favButtons.Add([pscustomobject]@{ Button=$btn; Name=$center.Name; Keywords=(Nz $center.Keywords); StarButton=$star }) | Out-Null
    }
}

function Build-Buttons {
    $ugButtons.Children.Clear()
    $buttonMap.Clear()

    foreach ($center in $centers) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $window.FindResource("TileButtonStyle")
        $btn.Tag = $center
        $btn.Height = 46
        $btn.Margin = "6"
        $btn.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($center.Color))

        $glyph = "E8A7"
        if ($center.ContainsKey("Icon") -and -not [string]::IsNullOrWhiteSpace([string]$center.Icon)) { $glyph = [string]$center.Icon }
        $grid = New-Object System.Windows.Controls.Grid
        $grid.Margin = "0"

        # Main content (centered)
        $main = (New-TileContent -GlyphHex $glyph -Text $center.Name -FontSize 15)
        $grid.Children.Add($main) | Out-Null

        # Star overlay (top-right corner)
        $star = (New-StarButton -CenterName $center.Name)
        $star.HorizontalAlignment = "Right"
        $star.VerticalAlignment   = "Top"
        $star.Margin              = "6"
        $star.Width               = 22
        $star.Height              = 22
        $grid.Children.Add($star) | Out-Null

        $btn.Content = $grid

        # Star hover (animated)
        $btn.Add_MouseEnter({
            # On hover: show (fade in) even if not favorited
            Fade-Opacity -Element $star -To 1 -Milliseconds 140
        })
        $btn.Add_MouseLeave({
            # On leave: hide (fade out) only if not favorited
            if (-not (Get-IsFavorite -Name $center.Name)) {
                Fade-Opacity -Element $star -To 0 -Milliseconds 140
            }
        })

        $tip = $center.Notes
        $u = Resolve-CenterUrl -center $center
        if (-not [string]::IsNullOrWhiteSpace($u)) {
            if (-not [string]::IsNullOrWhiteSpace($tip)) { $tip = ("{0}`n{1}" -f $tip, $u) } else { $tip = $u }
        }
        $btn.ToolTip = (New-ReadableToolTip $tip)

        $btn.Add_Click({
            if ($null -eq $this.Tag) { return }
            Invoke-Center -center $this.Tag
        })

        $ugButtons.Children.Add($btn) | Out-Null
        $buttonMap.Add([pscustomobject]@{ Button=$btn; Name=$center.Name; Keywords=(Nz $center.Keywords); StarButton=$star }) | Out-Null
    }

    Recalc-Columns
}

function Persist-State {
    $out = [pscustomobject]@{
        tenantId = $script:state.TenantId
        environment = $script:state.Environment
        subscriptions = [pscustomobject]@{
            Prod    = $script:state.Subscriptions.Prod
            Sandbox = $script:state.Subscriptions.Sandbox
        }
        resourceGroup = $script:state.ResourceGroup
        favorites = $script:state.Favorites
    }
    Save-Config $out
}

# ----------------------------
# Events
# ----------------------------
$txtSearch.Add_TextChanged({ Apply-Filter })
$window.Add_SizeChanged({ Recalc-Columns })

$cmbEnv.Add_SelectionChanged({
    $envName = Get-SelectedEnv
    $script:state.Environment = $envName
    Sync-SubscriptionTextFromEnv

    Build-Favorites
    Build-Buttons
    Update-AllStarIcons
    Apply-Filter

    $lblStatus.Text = "Status: Environment set to $envName"
})

$btnTenantHelp.Add_Click({
    [System.Windows.MessageBox]::Show(
@"
Tenant ID (Directory (tenant) ID):
1) Go to https://entra.microsoft.com
2) Overview
3) Copy Directory (tenant) ID

This is optional (only used for tenant-context Entra links).
"@,
        "Where to Find Tenant ID",
        "OK",
        "Information"
    ) | Out-Null
})

$btnTenantCopy.Add_Click({ Set-ClipboardText -Text (Nz $txtTenantId.Text).Trim(); $lblStatus.Text = "Status: Tenant ID copied" })
$btnSubCopy.Add_Click({ Set-ClipboardText -Text (Nz $txtSubscriptionId.Text).Trim(); $lblStatus.Text = "Status: Subscription ID copied" })
$btnRgCopy.Add_Click({ Set-ClipboardText -Text (Nz $txtResourceGroup.Text).Trim(); $lblStatus.Text = "Status: Resource Group copied" })

$btnSave.Add_Click({
    $tid = (Nz $txtTenantId.Text).Trim()
    $envName = Get-SelectedEnv
    $sid = (Nz $txtSubscriptionId.Text).Trim()
    $rg  = (Nz $txtResourceGroup.Text).Trim()

    if (-not [string]::IsNullOrWhiteSpace($tid) -and -not (Test-Guid $tid)) {
        [System.Windows.MessageBox]::Show("Tenant ID must be a valid GUID.", "Invalid Tenant ID", "OK", "Warning") | Out-Null
        return
    }
    if (-not [string]::IsNullOrWhiteSpace($sid) -and -not (Test-Guid $sid)) {
        [System.Windows.MessageBox]::Show("Subscription ID must be a valid GUID.", "Invalid Subscription ID", "OK", "Warning") | Out-Null
        return
    }

    $script:state.TenantId = $tid
    $script:state.Environment = $envName
    $script:state.Subscriptions.$envName = $sid
    $script:state.ResourceGroup = $rg

    Persist-State

    Build-Favorites
    Build-Buttons
    Update-AllStarIcons
    Apply-Filter

    $lblStatus.Text = "Status: Saved configuration"
})

$btnReset.Add_Click({
    $txtTenantId.Text = ""
    $txtResourceGroup.Text = ""
    $txtSearch.Text = ""

    $script:state.TenantId = ""
    $script:state.ResourceGroup = ""
    $script:state.Environment = "Sandbox"
    $script:state.Subscriptions.Prod = ""
    $script:state.Subscriptions.Sandbox = ""
    $script:state.Favorites = $defaultFavorites

    Remove-Config

    $cmbEnv.SelectedIndex = 0
    Sync-SubscriptionTextFromEnv

    Build-Favorites
    Build-Buttons
    Update-AllStarIcons
    Apply-Filter

    $lblStatus.Text = "Status: Reset complete"
})

$btnExit.Add_Click({
    $notifyIcon.Visible = $false
    $window.Tag = "ForceExit"
    $window.Close()
})

$window.Add_Closing({
    if ($window.Tag -eq "ForceExit") { return }

    if ($chkCloseToTray.IsChecked) {
        $_.Cancel = $true
        $window.Hide()
        $notifyIcon.BalloonTipTitle = "Azure Launcher"
        $notifyIcon.BalloonTipText  = "Still running in the system tray."
        $notifyIcon.ShowBalloonTip(1200)
    } else {
        $notifyIcon.Visible = $false
    }
})

# ----------------------------
# Init
# ----------------------------
Build-Favorites
Build-Buttons
Update-AllStarIcons
Apply-Filter

# Show
$null = $window.ShowDialog()

# Cleanup
$notifyIcon.Visible = $false
$notifyIcon.Dispose()
