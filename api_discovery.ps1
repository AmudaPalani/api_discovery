# Connect to Azure and Microsoft Graph
Connect-AzAccount
Connect-MgGraph -Scopes "Device.ReadWrite.All"

Install-Module -Name Az.ConnectedMachine -AllowClobber -Force

# Get all Azure arc servers with the tag ServerType:api_discovery
$vms = Get-AzConnectedMachine | Where-Object { $_.Tags["ServerType"] -eq "api_discovery" }

if ($vms.Count -eq 0) {
    Write-Host "No Arc servers found with the tag ServerType:api_discovery" -ForegroundColor Yellow
    return
}

# Define services that commonly host APIs
$APIRelatedServices = @(
    "W3SVC",           # IIS
    "Apache*",         # Apache variants
    "nginx",           # Nginx
    "Tomcat*",         # Apache Tomcat
    "Jetty*",          # Eclipse Jetty
    "WebLogic*",       # Oracle WebLogic
    "WebSphere*",      # IBM WebSphere
    "*Kestrel*",       # ASP.NET Core Kestrel
    "*IISExpress*",    # IIS Express
    "*node*",          # Node.js applications
    "*gunicorn*",      # Gunicorn WSGI server
    "*uwsgi*",         # uWSGI server
    "*django*",        # Django applications
    "*flask*",         # Flask applications
    "*fastapi*",       # FastAPI applications
    "*swagger*",       # Swagger/OpenAPI
)
# Function to check if a service is running
function Is-ServiceRunning {
    param (
        [string]$ServiceName
    )
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    return $service -and $service.Status -eq 'Running'
}
# Function to check if a port is open
function Is-PortOpen {
    param (
        [string]$ServerName,
        [int]$Port
    )
    try {
        $tcpTest = Test-NetConnection -ComputerName $ServerName -Port $Port -InformationLevel Quiet
        return $tcpTest.TcpTestSucceeded
    }
    catch {
        return $false
    }
}
function Test-APIEndpoints {
    param (
        [string]$ServerName,
        [int[]]$Ports
    )
    
    Write-Host "Checking $ServerName..." -ForegroundColor Yellow
    
    # Test basic connectivity
    $pingResult = Test-Connection -ComputerName $ServerName -Count 1 -Quiet
    if (-not $pingResult) {
        Write-Host "  ❌ Cannot reach $ServerName" -ForegroundColor Red
        return
    }
    
    Write-Host "  ✅ Server is reachable" -ForegroundColor Green
    
    # Check services and ports
    foreach ($service in $APIRelatedServices) {
        if (Is-ServiceRunning -ServiceName $service) {
            Write-Host "  🌐 Service $service is running" -ForegroundColor Cyan
        } else {
            Write-Host "  ❌ Service $service is not running" -ForegroundColor Red
        }
    }
    
    foreach ($port in $Ports) {
        if (Is-PortOpen -ServerName $ServerName -Port $port) {
            Write-Host "  🌐 Port $port is open" -ForegroundColor Cyan
            
            # Quick HTTP test
            try {
                $response = Invoke-WebRequest -Uri "http://$ServerName:$port" -UseBasicParsing -TimeoutSec 5
                if ($response.StatusCode -eq 200) {
                    Write-Host "  ✅ HTTP response from port $port: $($response.StatusCode)" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠️ HTTP response from port $port: $($response.StatusCode)" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "  ❌ Failed to connect to port $port: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "  ❌ Port $port is closed" -ForegroundColor Red
        }
    }
}

# Main script execution
foreach ($vm in $vms) {
    $serverName = $vm.Name
    Write-Host "Processing server: $serverName" -ForegroundColor Cyan
    
    # Define ports to scan
    $portsToScan = @(
        80, 443, 8080, 8443, 3000, 5000, 8000, 9000,
        8081, 8082, 8083, 8084, 8085, 9080, 9443,
        5001, 5002, 3001, 4000, 7000, 7001, 7002,
        8888, 9999, 6000, 6001, 8090, 8091, 8092,
        9090, 9091, 3030, 4200, 8787, 8786,
        8020, 8088, 9200, 5601, 8086,
        # Add more ports as needed
    )
    
    # Test API endpoints
    Test-APIEndpoints -ServerName $serverName -Ports $portsToScan
}
     

