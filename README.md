# API Discovery Script for Azure Arc Servers

This PowerShell script automatically discovers and tests API endpoints on Azure Arc-connected servers that are tagged with `ServerType:api_discovery`.

## Overview

The `api_discovery.ps1` script connects to Azure and Microsoft Graph, identifies Arc-connected servers with specific tags, and performs comprehensive API endpoint discovery by:

- Testing network connectivity to each server
- Checking for API-related services
- Scanning common API ports (39 different ports)
- Testing HTTP endpoints for responses
- Identifying potential API interfaces

## Prerequisites

### Required Modules
The script automatically installs required modules:
```powershell
# These modules are auto-installed by the script
Install-Module -Name Az.ConnectedMachine -AllowClobber -Force
```

### Required Permissions
- **Azure Account**: Access to read Arc-connected machines
- **Microsoft Graph**: `Device.ReadWrite.All` scope
- **Network Access**: Ability to connect to target Arc servers

## Server Tagging Requirements

The script looks for Arc-connected servers with the following tag:
- **Tag Name**: `ServerType`
- **Tag Value**: `api_discovery`

### Adding Tags to Arc Servers

#### Using Azure Portal
1. Navigate to Azure Arc > Servers
2. Select your server
3. Go to Tags section
4. Add tag: `ServerType` = `api_discovery`

#### Using PowerShell
```powershell
# Add tag to an Arc server
$resourceGroup = "YourResourceGroup"
$serverName = "YourArcServer"

$tags = @{
    "ServerType" = "api_discovery"
}

Update-AzConnectedMachine -ResourceGroupName $resourceGroup -Name $serverName -Tag $tags
```

#### Using Azure CLI
```bash
# Add tag to an Arc server
az connectedmachine update \
  --resource-group "YourResourceGroup" \
  --name "YourArcServer" \
  --set tags.ServerType=api_discovery
```

## Usage

### Basic Usage
```powershell
# Run the script with default settings
.\api_discovery.ps1
```

The script will:
1. Automatically install the Az.ConnectedMachine module if needed
2. Prompt for Azure authentication
3. Prompt for Microsoft Graph authentication
4. Discover tagged Arc servers
5. Test each server for API endpoints

### What the Script Tests

#### Services Checked
The script checks for these API-related services:
- **Web Servers**: IIS (W3SVC), Apache, nginx
- **Application Servers**: Tomcat, Jetty, WebLogic, WebSphere
- **.NET Services**: Kestrel, IIS Express
- **Node.js**: Node applications
- **Python Services**: Gunicorn, uWSGI, Django, Flask, FastAPI
- **API Documentation**: Swagger/OpenAPI services

#### Ports Scanned (39 total ports)
The script tests these ports for API endpoints:
- **Standard Web**: 80, 443
- **Alternative Web**: 8080, 8443
- **Development**: 3000, 5000, 8000, 9000
- **Alternative Ports**: 8081, 8082, 8083, 8084, 8085, 9080, 9443
- **Framework Specific**: 5001, 5002 (ASP.NET Core), 3001 (Node.js), 4000, 4200 (Angular)
- **Enterprise**: 7000, 7001, 7002 (WebLogic), 8888, 9999
- **Additional Services**: 6000, 6001, 8090, 8091, 8092, 9090, 9091
- **Specialized**: 3030 (Grafana), 8787 (RStudio), 8786 (Shiny)
- **Big Data**: 8020 (Hadoop NameNode), 8088 (ResourceManager), 9200 (Elasticsearch)
- **Monitoring**: 5601 (Kibana), 8086 (InfluxDB)

## Output Interpretation

### Color-Coded Results
- ✅ **Green**: Successful connections and running services
- ⚠️ **Yellow**: Warnings or non-standard HTTP responses  
- ❌ **Red**: Failed connections or stopped services
- 🌐 **Cyan**: Open ports and discovered services

### Example Output
```
Processing server: WebServer01
Checking WebServer01...
  ✅ Server is reachable
  🌐 Service W3SVC is running
  ❌ Service nginx is not running
  🌐 Port 80 is open
  ✅ HTTP response from port 80: 200
  🌐 Port 443 is open
  ✅ HTTP response from port 443: 200
  ❌ Port 8080 is closed
```

### Sample Output File
See `sample_output.txt` for a complete example of what the script produces when run against multiple Arc servers with different configurations.

## Script Workflow

1. **Module Installation**: Automatically installs Az.ConnectedMachine if not present
2. **Authentication**: Connects to Azure and Microsoft Graph
3. **Server Discovery**: Finds Arc servers tagged with `ServerType:api_discovery`
4. **Connectivity Test**: Pings each server to verify reachability
5. **Service Check**: Tests for API-related services on each server
6. **Port Scanning**: Tests all 39 configured ports on each server
7. **HTTP Testing**: Attempts HTTP requests to open ports
8. **Results Display**: Shows color-coded results for each finding

## Troubleshooting

### Common Issues

#### No Arc Servers Found
```
No Arc servers found with the tag ServerType:api_discovery
```
**Solution**: Ensure your Arc servers are properly tagged with `ServerType:api_discovery`

#### Module Installation Issues
**Problem**: Script fails to install Az.ConnectedMachine module
**Solutions**:
- Run PowerShell as Administrator
- Manually install: `Install-Module -Name Az.ConnectedMachine -AllowClobber -Force`
- Check internet connectivity and PowerShell Gallery access

#### Authentication Issues
**Problem**: Script fails to connect to Azure or Microsoft Graph
**Solutions**:
- Ensure you have the required permissions
- Try running `Connect-AzAccount` manually first
- Verify your account has access to the subscription containing Arc servers
- Check if MFA is properly configured

#### Network Connectivity Issues
**Problem**: Cannot reach Arc servers (❌ Cannot reach ServerName)
**Solutions**:
- Verify network connectivity between the machine running the script and Arc servers
- Check firewall rules and security groups
- Ensure Arc servers are online and accessible
- Verify DNS resolution for server names

#### Service Detection Issues
**Problem**: Services not detected correctly
**Solutions**:
- The script checks services by name patterns - some custom services may not be detected
- Services may be running under different names on different operating systems
- Consider customizing the `$APIRelatedServices` array for your environment

## Customization

### Adding Custom Ports
Edit the `$portsToScan` array in the script:
```powershell
$portsToScan = @(
    80, 443, 8080, 8443, 3000, 5000, 8000, 9000,  # existing ports
    8081, 8082, 8083, 8084, 8085, 9080, 9443,
    5001, 5002, 3001, 4000, 7000, 7001, 7002,
    8888, 9999, 6000, 6001, 8090, 8091, 8092,
    9090, 9091, 3030, 4200, 8787, 8786,
    8020, 8088, 9200, 5601, 8086,
    9876, 5432     # add your custom ports here
)
```

### Adding Custom Services
Edit the `$APIRelatedServices` array in the script:
```powershell
$APIRelatedServices = @(
    "W3SVC",           # IIS
    "Apache*",         # Apache variants  
    "nginx",           # Nginx
    # ... existing services ...
    "YourCustomAPI*"   # add your custom service pattern
)
```

## Files in This Repository

- **`api_discovery.ps1`** - Main API discovery script
- **`sample_output.txt`** - Example output showing what the script produces
- **`README.md`** - This documentation file

## Security Considerations

1. **Credentials**: The script requires Azure and Microsoft Graph authentication
2. **Network Access**: Ensure the script runs from a secure, authorized location
3. **Logging**: Monitor script execution for security compliance
4. **Permissions**: Use principle of least privilege for the executing account
5. **Port Scanning**: Be aware that port scanning may trigger security alerts

## Best Practices

1. **Tagging Strategy**: Use consistent tagging across your Arc servers
2. **Regular Execution**: Run the script regularly to maintain an up-to-date API inventory
3. **Documentation**: Document discovered APIs and their purposes
4. **Monitoring**: Set up alerts for new or changed API endpoints
5. **Security Review**: Regularly review discovered APIs for security compliance
6. **Network Policies**: Ensure proper firewall and network segmentation

## Support

For issues or questions about this script:
1. Check the troubleshooting section above
2. Review the Azure Arc and Microsoft Graph documentation
3. Ensure all prerequisites are met
4. Verify network connectivity and permissions
5. Check the sample output file for expected results
