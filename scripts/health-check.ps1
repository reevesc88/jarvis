#!/usr/bin/env pwsh
# Jarvis Health Check and Verification Utility
# Monitors application health and performs comprehensive diagnostics

param(
    [string]$Url = "http://localhost:1337",
    [int]$Timeout = 30,
    [switch]$Continuous,
    [int]$Interval = 60,
    [switch]$Verbose,
    [switch]$LogToFile,
    [string]$LogPath = "logs/health-check.log"
)

$ErrorActionPreference = "Continue"

# Color output functions
function Write-Success($message) { Write-Host "✅ $message" -ForegroundColor Green }
function Write-Error($message) { Write-Host "❌ $message" -ForegroundColor Red }
function Write-Warning($message) { Write-Host "⚠️  $message" -ForegroundColor Yellow }
function Write-Info($message) { Write-Host "ℹ️  $message" -ForegroundColor Cyan }
function Write-Debug($message) { if ($Verbose) { Write-Host "🔍 $message" -ForegroundColor Gray } }
function Write-Header($message) {
    Write-Host "`n🩺 $message" -ForegroundColor Magenta
    Write-Host ("=" * ($message.Length + 4)) -ForegroundColor Magenta
}

# Logging function
function Write-Log($message, $level = "INFO") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$level] $message"
    
    if ($LogToFile) {
        if (-not (Test-Path (Split-Path $LogPath -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $LogPath -Parent) -Force | Out-Null
        }
        Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
    }
    
    Write-Debug $logEntry
}

# Health check results
$script:HealthResults = @{
    Timestamp = Get-Date
    Url = $Url
    Overall = $true
    Checks = @{}
    Metrics = @{}
    Errors = @()
    Warnings = @()
}

# Individual health check functions
function Test-WebServerHealth {
    Write-Debug "Testing web server health..."
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $Timeout -UseBasicParsing -ErrorAction Stop
        
        $script:HealthResults.Checks["WebServer"] = @{
            Status = "Healthy"
            StatusCode = $response.StatusCode
            ResponseTime = $null
            ContentLength = $response.Content.Length
        }
        
        Write-Success "Web server is responding (HTTP $($response.StatusCode))"
        Write-Log "Web server health check passed" "INFO"
        return $true
        
    } catch {
        $script:HealthResults.Checks["WebServer"] = @{
            Status = "Unhealthy"
            Error = $_.Exception.Message
        }
        
        Write-Error "Web server is not responding: $($_.Exception.Message)"
        Write-Log "Web server health check failed: $($_.Exception.Message)" "ERROR"
        $script:HealthResults.Overall = $false
        $script:HealthResults.Errors += "Web server not responding"
        return $false
    }
}

function Test-WebSocketHealth {
    Write-Debug "Testing WebSocket health..."
    
    try {
        # Parse URL to get WebSocket endpoint
        $uri = [System.Uri]$Url
        $wsUrl = "ws://$($uri.Host):$($uri.Port)/socket.io/?EIO=4&transport=websocket"
        
        # Simple WebSocket connection test (basic check)
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectTask = $tcpClient.ConnectAsync($uri.Host, $uri.Port)
        $connectResult = $connectTask.Wait(5000)
        
        if ($connectResult -and $tcpClient.Connected) {
            $tcpClient.Close()
            
            $script:HealthResults.Checks["WebSocket"] = @{
                Status = "Healthy"
                Port = $uri.Port
            }
            
            Write-Success "WebSocket port is accessible"
            Write-Log "WebSocket health check passed" "INFO"
            return $true
        } else {
            throw "Connection timeout or refused"
        }
        
    } catch {
        $script:HealthResults.Checks["WebSocket"] = @{
            Status = "Warning"
            Error = $_.Exception.Message
        }
        
        Write-Warning "WebSocket connection test failed: $($_.Exception.Message)"
        Write-Log "WebSocket health check warning: $($_.Exception.Message)" "WARN"
        $script:HealthResults.Warnings += "WebSocket connection issues"
        return $false
    }
}

function Test-ProcessHealth {
    Write-Debug "Testing process health..."
    
    try {
        # Look for Node.js processes that might be running Jarvis
        $nodeProcesses = Get-Process | Where-Object { 
            $_.ProcessName -eq "node" -and 
            $_.CommandLine -like "*webpack*" -or 
            $_.CommandLine -like "*jarvis*"
        }
        
        if ($nodeProcesses.Count -gt 0) {
            $script:HealthResults.Checks["Process"] = @{
                Status = "Healthy"
                ProcessCount = $nodeProcesses.Count
                Processes = @()
            }
            
            foreach ($proc in $nodeProcesses) {
                $processInfo = @{
                    PID = $proc.Id
                    CPU = $proc.CPU
                    Memory = [math]::Round($proc.WorkingSet / 1MB, 2)
                    StartTime = $proc.StartTime
                }
                
                $script:HealthResults.Checks["Process"].Processes += $processInfo
                Write-Success "Jarvis process found (PID: $($proc.Id), Memory: $($processInfo.Memory) MB)"
            }
            
            Write-Log "Process health check passed - $($nodeProcesses.Count) processes found" "INFO"
            return $true
            
        } else {
            $script:HealthResults.Checks["Process"] = @{
                Status = "Unhealthy"
                ProcessCount = 0
            }
            
            Write-Error "No Jarvis processes found running"
            Write-Log "Process health check failed - no processes found" "ERROR"
            $script:HealthResults.Overall = $false
            $script:HealthResults.Errors += "No Jarvis processes running"
            return $false
        }
        
    } catch {
        Write-Warning "Process health check failed: $($_.Exception.Message)"
        Write-Log "Process health check error: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-DependencyHealth {
    Write-Debug "Testing dependency health..."
    
    try {
        # Check if package.json exists
        if (-not (Test-Path "package.json")) {
            throw "package.json not found"
        }
        
        # Check if node_modules exists
        if (-not (Test-Path "node_modules")) {
            throw "node_modules directory not found"
        }
        
        # Check critical files
        $criticalFiles = @(
            "src/server/index.js",
            "src/client/index.js", 
            "config/webpack.js"
        )
        
        $missingFiles = @()
        foreach ($file in $criticalFiles) {
            if (-not (Test-Path $file)) {
                $missingFiles += $file
            }
        }
        
        if ($missingFiles.Count -gt 0) {
            throw "Missing critical files: $($missingFiles -join ', ')"
        }
        
        $script:HealthResults.Checks["Dependencies"] = @{
            Status = "Healthy"
            PackageJson = $true
            NodeModules = $true
            CriticalFiles = $true
        }
        
        Write-Success "All dependencies and critical files are present"
        Write-Log "Dependency health check passed" "INFO"
        return $true
        
    } catch {
        $script:HealthResults.Checks["Dependencies"] = @{
            Status = "Unhealthy"
            Error = $_.Exception.Message
        }
        
        Write-Error "Dependency check failed: $($_.Exception.Message)"
        Write-Log "Dependency health check failed: $($_.Exception.Message)" "ERROR"
        $script:HealthResults.Overall = $false
        $script:HealthResults.Errors += "Dependency issues"
        return $false
    }
}

function Test-PerformanceMetrics {
    Write-Debug "Collecting performance metrics..."
    
    try {
        # System metrics
        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            $memory = Get-CimInstance Win32_OperatingSystem
            $cpu = Get-CimInstance Win32_Processor
            
            $script:HealthResults.Metrics = @{
                TotalMemoryGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
                FreeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
                CPUCores = $cpu.NumberOfCores
                CPUUsagePercent = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
            }
            
            # Memory usage warning
            $memoryUsagePercent = (($script:HealthResults.Metrics.TotalMemoryGB - $script:HealthResults.Metrics.FreeMemoryGB) / $script:HealthResults.Metrics.TotalMemoryGB) * 100
            
            if ($memoryUsagePercent -gt 80) {
                Write-Warning "High memory usage: $([math]::Round($memoryUsagePercent, 1))%"
                $script:HealthResults.Warnings += "High memory usage"
            }
            
            Write-Info "System metrics collected successfully"
            Write-Log "Performance metrics collected" "INFO"
        } else {
            Write-Debug "Performance metrics not implemented for this platform"
        }
        
        return $true
        
    } catch {
        Write-Warning "Failed to collect performance metrics: $($_.Exception.Message)"
        Write-Log "Performance metrics collection failed: $($_.Exception.Message)" "WARN"
        return $false
    }
}

function Test-ResponseTime {
    Write-Debug "Testing response time..."
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $Timeout -UseBasicParsing -ErrorAction Stop
        $stopwatch.Stop()
        
        $responseTimeMs = $stopwatch.ElapsedMilliseconds
        $script:HealthResults.Metrics["ResponseTimeMs"] = $responseTimeMs
        
        if ($responseTimeMs -lt 1000) {
            Write-Success "Response time: $responseTimeMs ms (Good)"
        } elseif ($responseTimeMs -lt 3000) {
            Write-Warning "Response time: $responseTimeMs ms (Slow)"
            $script:HealthResults.Warnings += "Slow response time"
        } else {
            Write-Error "Response time: $responseTimeMs ms (Very Slow)"
            $script:HealthResults.Errors += "Very slow response time"
        }
        
        Write-Log "Response time test: $responseTimeMs ms" "INFO"
        return $true
        
    } catch {
        Write-Error "Response time test failed: $($_.Exception.Message)"
        Write-Log "Response time test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main health check function
function Invoke-HealthCheck {
    Write-Header "Jarvis Health Check"
    Write-Info "Target: $Url"
    Write-Info "Timeout: $Timeout seconds"
    Write-Info "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    $checks = @(
        @{ Name = "Web Server"; Function = { Test-WebServerHealth } },
        @{ Name = "Response Time"; Function = { Test-ResponseTime } },
        @{ Name = "WebSocket"; Function = { Test-WebSocketHealth } },
        @{ Name = "Process"; Function = { Test-ProcessHealth } },
        @{ Name = "Dependencies"; Function = { Test-DependencyHealth } },
        @{ Name = "Performance"; Function = { Test-PerformanceMetrics } }
    )
    
    $passedChecks = 0
    $totalChecks = $checks.Count
    
    foreach ($check in $checks) {
        Write-Header "Checking $($check.Name)"
        if (& $check.Function) {
            $passedChecks++
        }
    }
    
    # Summary
    Write-Header "Health Check Summary"
    
    if ($script:HealthResults.Overall) {
        if ($script:HealthResults.Warnings.Count -eq 0) {
            Write-Success "🎉 All systems healthy! ($passedChecks/$totalChecks checks passed)"
        } else {
            Write-Warning "⚠️  Systems operational with warnings ($passedChecks/$totalChecks checks passed)"
        }
    } else {
        Write-Error "💥 System unhealthy! ($passedChecks/$totalChecks checks passed)"
    }
    
    # Display metrics if available
    if ($script:HealthResults.Metrics.Count -gt 0) {
        Write-Host "`n📊 Metrics:" -ForegroundColor Yellow
        foreach ($metric in $script:HealthResults.Metrics.GetEnumerator()) {
            Write-Host "  $($metric.Key): $($metric.Value)" -ForegroundColor White
        }
    }
    
    # Display warnings
    if ($script:HealthResults.Warnings.Count -gt 0) {
        Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
        foreach ($warning in $script:HealthResults.Warnings) {
            Write-Host "  • $warning" -ForegroundColor Yellow
        }
    }
    
    # Display errors
    if ($script:HealthResults.Errors.Count -gt 0) {
        Write-Host "`n❌ Errors:" -ForegroundColor Red
        foreach ($errorItem in $script:HealthResults.Errors) {
            Write-Host "  • $errorItem" -ForegroundColor Red
        }
        
        Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  1. Check if the development server is running: npm run watch" -ForegroundColor White
        Write-Host "  2. Verify system requirements: ./scripts/check-dependencies.ps1" -ForegroundColor White
        Write-Host "  3. Restart the application: ./scripts/start-dev.ps1" -ForegroundColor White
        Write-Host "  4. Check logs in ./logs/ directory" -ForegroundColor White
    }
    
    # Save results to file
    try {
        if (-not (Test-Path "logs")) {
            New-Item -ItemType Directory -Path "logs" -Force | Out-Null
        }
        
        $resultsJson = $script:HealthResults | ConvertTo-Json -Depth 4
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Set-Content -Path "logs/health-check-$timestamp.json" -Value $resultsJson -Encoding UTF8
        Write-Debug "Health check results saved to logs/health-check-$timestamp.json"
    } catch {
        Write-Warning "Could not save health check results: $($_.Exception.Message)"
    }
    
    Write-Log "Health check completed - Overall: $($script:HealthResults.Overall)" "INFO"
    
    return $script:HealthResults.Overall
}

# Main execution
if ($Continuous) {
    Write-Header "Continuous Health Monitoring"
    Write-Info "Monitoring $Url every $Interval seconds"
    Write-Info "Press Ctrl+C to stop monitoring"
    
    try {
        do {
            $isHealthy = Invoke-HealthCheck
            
            if (-not $isHealthy) {
                Write-Warning "System is unhealthy - continuing monitoring..."
            }
            
            Write-Host "`n⏱️  Next check in $Interval seconds..." -ForegroundColor Gray
            Start-Sleep -Seconds $Interval
            
        } while ($true)
    } catch [System.Management.Automation.RuntimeException] {
        Write-Info "`nMonitoring stopped by user"
    }
} else {
    $isHealthy = Invoke-HealthCheck
    
    if ($isHealthy) {
        exit 0
    } else {
        exit 1
    }
}