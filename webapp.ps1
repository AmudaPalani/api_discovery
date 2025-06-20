# Ensure you're connected to Azure PowerShell
Connect-AzAccount
 
# Get all subscriptions
$subscriptions = Get-AzSubscription
 
# Create an empty array to store results
$results = @()
 
foreach ($sub in $subscriptions) {
    Write-Host "Switching to subscription: $($sub.Name)"
    Set-AzContext -SubscriptionId $sub.Id
 
    # Get all web apps in this subscription
    $webApps = Get-AzWebApp
 
    foreach ($app in $webApps) {
        Write-Host "Checking app: $($app.Name)"        $subnetResourceId = $null
        $outboundIPs = ""
        $inboundIPs = ""
        $vnetName = ""
        $subnetName = ""
        $vnetIntegrationType = "None"
        $vnetIntegrationStatus = "Not Configured"
        $vnetRouteAllEnabled = $false
        $vnetSwiftSupported = $false
        $vnetCertThumbprint = ""
        $vnetDnsServers = ""
        $vnetSubscriptionId = ""
        $vnetResourceGroup = ""

        # First try via PowerShell (Regional VNet Integration)
        try {
            $appDetails = Get-AzWebApp -ResourceGroup $app.ResourceGroup -Name $app.Name
            $subnetResourceId = $appDetails.SiteConfig.VirtualNetworkSubnetId
            
            # Get additional VNet integration details
            if ($appDetails.SiteConfig.VnetRouteAllEnabled) {
                $vnetRouteAllEnabled = $appDetails.SiteConfig.VnetRouteAllEnabled
            }
            
            # Check if Swift connection is supported
            if ($appDetails.SiteConfig.SwiftSupported) {
                $vnetSwiftSupported = $appDetails.SiteConfig.SwiftSupported
            }
            
            # Get VNet integration status
            if ($subnetResourceId) {
                $vnetIntegrationType = "Regional"
                $vnetIntegrationStatus = "Configured"
            }
        } catch {}        # If still null, try using Azure CLI (legacy/gateway-required)
        if (-not $subnetResourceId) {
            try {
                $cliOutput = az webapp vnet-integration list --name $app.Name --resource-group $app.ResourceGroup --only-show-errors | ConvertFrom-Json
                if ($cliOutput -and $cliOutput.subnetResourceId) {
                    $subnetResourceId = $cliOutput.subnetResourceId
                    $vnetIntegrationType = "Gateway-Required"
                    $vnetIntegrationStatus = "Configured (Legacy)"
                    
                    # Extract additional info from CLI output
                    if ($cliOutput.certThumbprint) {
                        $vnetCertThumbprint = $cliOutput.certThumbprint
                    }
                    if ($cliOutput.dnsServers) {
                        $vnetDnsServers = $cliOutput.dnsServers -join ", "
                    }
                } elseif ($cliOutput -is [System.Collections.IEnumerable]) {
                    foreach ($item in $cliOutput) {
                        if ($item.subnetResourceId) {
                            $subnetResourceId = $item.subnetResourceId
                            $vnetIntegrationType = "Gateway-Required"
                            $vnetIntegrationStatus = "Configured (Legacy)"
                            
                            if ($item.certThumbprint) {
                                $vnetCertThumbprint = $item.certThumbprint
                            }
                            if ($item.dnsServers) {
                                $vnetDnsServers = $item.dnsServers -join ", "
                            }
                            break
                        }
                    }
                }
            } catch {
                Write-Host "az CLI failed for $($app.Name)"
            }
        }        # Extract VNet and Subnet names and additional details
        if ($subnetResourceId) {
            $resourceIdParts = $subnetResourceId -split "/"
            $vnetSubscriptionId = $resourceIdParts[2]
            $vnetResourceGroup = $resourceIdParts[4]
            $vnetName = $resourceIdParts[8]
            $subnetName = $resourceIdParts[10]
            
            # Get additional VNet details if possible
            try {
                $vnetDetails = Get-AzVirtualNetwork -ResourceGroupName $vnetResourceGroup -Name $vnetName -ErrorAction SilentlyContinue
                if ($vnetDetails -and $vnetDetails.DhcpOptions.DnsServers) {
                    $vnetDnsServers = $vnetDetails.DhcpOptions.DnsServers -join ", "
                }
            } catch {
                # Ignore errors if VNet is in different subscription or access denied
            }
        }
 
        # Get outbound/inbound IPs
        try {
            $outboundIPs = $app.OutboundIpAddresses -join ", "
            $inboundIPs = $app.PossibleInboundIpAddresses -join ", "
        } catch {}        # Add to results with comprehensive VNet integration info
        $results += [PSCustomObject]@{
            SubscriptionName         = $sub.Name
            SubscriptionId          = $sub.Id
            Name                    = $app.Name
            ResourceGroup           = $app.ResourceGroup
            Location                = $app.Location
            DefaultHostName         = $app.DefaultHostName
            OutboundIPs             = $outboundIPs
            InboundIPs              = $inboundIPs
            VNetIntegrationStatus   = $vnetIntegrationStatus
            VNetIntegrationType     = $vnetIntegrationType
            SubnetResourceId        = $subnetResourceId
            VNetName                = $vnetName
            SubnetName              = $subnetName
            VNetSubscriptionId      = $vnetSubscriptionId
            VNetResourceGroup       = $vnetResourceGroup
            VNetRouteAllEnabled     = $vnetRouteAllEnabled
            VNetSwiftSupported      = $vnetSwiftSupported
            VNetCertThumbprint      = $vnetCertThumbprint
            VNetDnsServers          = $vnetDnsServers
        }
    } # closes foreach app
}     # closes foreach subscription
 
# Export results
$exportPath = "$HOME\webapp-network-info-all-subs.csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation
 
Write-Host "Export complete: $exportPath"
