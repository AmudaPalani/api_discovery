# API Discovery Script for Azure Arc Servers

This PowerShell script automatically discovers and tests API endpoints on Azure Arc-connected servers that are tagged with `ServerType:api_discovery`.

## Overview

The `api_discovery.ps1` script connects to Azure and Microsoft Graph, identifies Arc-connected servers with specific tags, and performs comprehensive API endpoint discovery by:

- Testing network connectivity to each server
- Checking for API-related services
- Scanning common API ports
- Testing HTTP endpoints for responses
- Identifying potential API interfaces

## Prerequisites

### Required Modules
```powershell
# Install required Azure and Microsoft Graph modules
Install-Module Az.Accounts -Force
Install-Module Az.ConnectedMachine -Force
Install-Module Microsoft.Graph -Force
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
1. Prompt for Azure authentication
2. Prompt for Microsoft Graph authentication
3. Discover tagged Arc servers
4. Test each server for API endpoints

### What the Script Tests

#### Services Checked
- **Web Servers**: IIS (W3SVC), Apache, nginx
- **Application Servers**: Tomcat, Jetty, WebLogic, WebSphere
- **.NET Services**: Kestrel, IIS Express
- **Development Servers**: Node.js applications
- **Python Services**: Gunicorn, uWSGI, Django, Flask, FastAPI
- **API Documentation**: Swagger/OpenAPI services

#### Ports Scanned
The script tests the following ports for API endpoints:
- **Standard Web**: 80, 443
- **Alternative Web**: 8080, 8443
- **Development**: 3000, 5000, 8000, 9000
- **Alternative Ports**: 8081-8085, 9080, 9443
- **Framework Specific**: 5001-5002 (ASP.NET Core), 3001 (Node.js alt), 4000, 4200 (Angular)
- **Enterprise**: 7000-7002 (WebLogic), 8888, 9999
- **Additional Services**: 6000-6001, 8090-8092, 9090-9091
- **Specialized**: 3030 (Grafana alt), 8787 (RStudio), 8786 (Shiny)
- **Big Data**: 8020 (Hadoop NameNode), 8088 (ResourceManager), 9200 (Elasticsearch)
- **Monitoring**: 5601 (Kibana), 8086 (InfluxDB)

#### API Path Patterns
The script checks for common API paths:
- `/api`, `/api/v1`, `/api/v2`, `/api/v3`
- `/rest`, `/rest/api`, `/restapi`
- `/swagger`, `/swagger-ui`, `/swagger/ui`
- `/docs`, `/documentation`
- `/graphql`
- `/health`, `/status`, `/ping`, `/version`, `/info`
- `/metrics`, `/actuator`, `/actuator/health`
- `/management`, `/admin`

## Output Interpretation

### Color-Coded Results
- 🟢 **Green**: Successful connections and running services
- 🟡 **Yellow**: Warnings or non-standard responses
- 🔴 **Red**: Failed connections or stopped services
- 🔵 **Cyan**: General information and discovered services

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

## Troubleshooting

### Common Issues

#### No Arc Servers Found
```
No Arc servers found with the tag ServerType:api_discovery
```
**Solution**: Ensure your Arc servers are properly tagged with `ServerType:api_discovery`

#### Authentication Issues
**Problem**: Script fails to connect to Azure or Microsoft Graph
**Solutions**:
- Ensure you have the required permissions
- Try running `Connect-AzAccount` manually first
- Verify your account has access to the subscription containing Arc servers

#### Network Connectivity Issues
**Problem**: Cannot reach Arc servers
**Solutions**:
- Verify network connectivity between the machine running the script and Arc servers
- Check firewall rules
- Ensure Arc servers are online and accessible

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
    80, 443, 8080, # existing ports
    9876, 5432     # add your custom ports
)
```

### Adding Custom Services
Edit the `$APIRelatedServices` array:
```powershell
$APIRelatedServices = @(
    "W3SVC",           # existing services
    "YourCustomAPI*"   # add your custom service pattern
)
```

### Adding Custom API Paths
Edit the `$APIPathPatterns` array:
```powershell
$APIPathPatterns = @(
    "/api",              # existing paths
    "/your-custom-api"   # add your custom API path
)
```

## Security Considerations

1. **Credentials**: The script requires Azure and Microsoft Graph authentication
2. **Network Access**: Ensure the script runs from a secure, authorized location
3. **Logging**: Monitor script execution for security compliance
4. **Permissions**: Use principle of least privilege for the executing account

## Best Practices

1. **Tagging Strategy**: Use consistent tagging across your Arc servers
2. **Regular Execution**: Run the script regularly to maintain an up-to-date API inventory
3. **Documentation**: Document discovered APIs and their purposes
4. **Monitoring**: Set up alerts for new or changed API endpoints
5. **Security Review**: Regularly review discovered APIs for security compliance

## Related Scripts

This repository contains additional scripts for more advanced scenarios:
- `Check-ArcServerAPIs.ps1` - Comprehensive API discovery with detailed reporting
- `Quick-ArcAPICheck.ps1` - Quick API testing for specific servers
- `Check-ArcServerAPIs-ServicePrincipal.ps1` - Service principal-based authentication
- `Setup-ServicePrincipal.ps1` - Automated service principal setup

## Support

For issues or questions about this script:
1. Check the troubleshooting section above
2. Review the Azure Arc and Microsoft Graph documentation
3. Ensure all prerequisites are met
4. Verify network connectivity and permissions
