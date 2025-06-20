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
        Write-Host "Checking app: $($app.Name)"
 
        $subnetResourceId = $null
        $outboundIPs = ""
        $inboundIPs = ""
        $vnetName = ""
        $subnetName = ""
 
        # First try via PowerShell (Regional VNet Integration)
        try {
            $appDetails = Get-AzWebApp -ResourceGroup $app.ResourceGroup -Name $app.Name
            $subnetResourceId = $appDetails.SiteConfig.VirtualNetworkSubnetId
        } catch {}
 
        # If still null, try using Azure CLI (legacy/gateway-required)
        if (-not $subnetResourceId) {
            try {
                $cliOutput = az webapp vnet-integration list --name $app.Name --resource-group $app.ResourceGroup --only-show-errors | ConvertFrom-Json
                if ($cliOutput -and $cliOutput.subnetResourceId) {
                    $subnetResourceId = $cliOutput.subnetResourceId
                } elseif ($cliOutput -is [System.Collections.IEnumerable]) {
                    foreach ($item in $cliOutput) {
                        if ($item.subnetResourceId) {
                            $subnetResourceId = $item.subnetResourceId
                            break
                        }
                    }
                }
            } catch {
                Write-Host "az CLI failed for $($app.Name)"
            }
        }
 
        # Extract VNet and Subnet names
        if ($subnetResourceId) {
            $vnetName = ($subnetResourceId -split "/")[10]
            $subnetName = ($subnetResourceId -split "/")[12]
        }
 
        # Get outbound/inbound IPs
        try {
            $outboundIPs = $app.OutboundIpAddresses -join ", "
            $inboundIPs = $app.PossibleInboundIpAddresses -join ", "
        } catch {}
 
        # Add to results
        $results += [PSCustomObject]@{
            SubscriptionName  = $sub.Name
            SubscriptionId    = $sub.Id
            Name              = $app.Name
            ResourceGroup     = $app.ResourceGroup
            Location          = $app.Location
            DefaultHostName   = $app.DefaultHostName
            OutboundIPs       = $outboundIPs
            InboundIPs        = $inboundIPs
            SubnetResourceId  = $subnetResourceId
            VNetName          = $vnetName
            SubnetName        = $subnetName
        }
    } # closes foreach app
}     # closes foreach subscription
 
# Export results
$exportPath = "$HOME\webapp-network-info-all-subs.csv"
$results | Export-Csv -Path $exportPath -NoTypeInformation
 
Write-Host "Export complete: $exportPath"
