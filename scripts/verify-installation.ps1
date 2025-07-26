#!/usr/bin/env pwsh
# Jarvis Installation Verification and Testing Utility
# Performs comprehensive end-to-end verification of the complete setup

param(
    [switch]$QuickTest,
    [switch]$FullTest,
    [switch]$Performance,
    [string]$Port = "1337",
    [int]$TestTimeout = 60,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

# Color output functions
function Write-Success($message) { Write-Host "✅ $message" -ForegroundColor Green }
function Write-Error($message) { Write-Host "❌ $message" -ForegroundColor Red }
function Write-Warning($message) { Write-Host "⚠️  $message" -ForegroundColor Yellow }
function Write-Info($message) { Write-Host "ℹ️  $message" -ForegroundColor Cyan }
function Write-Debug($message) { if ($Verbose) { Write-Host "🔍 $message" -ForegroundColor Gray } }
function Write-Header($message) {
    Write-Host "`n🧪 $message" -ForegroundColor Magenta
    Write-Host ("=" * ($message.Length + 4)) -ForegroundColor Magenta
}

# Test results tracking
$script:TestResults = @{
    StartTime = Get-Date
    Tests = @{}
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warnings = 0
    }
    Errors = @()
    Warnings = @()
}

function Add-TestResult($testName, $status, $message, $details = @{}) {
    $script:TestResults.Tests[$testName] = @{
        Status = $status
        Message = $message
        Details = $details
        Timestamp = Get-Date
    }
    
    $script:TestResults.Summary.Total++
    
    switch ($status) {
        "PASS" { 
            $script:TestResults.Summary.Passed++
            Write-Success "$testName`: $message"
        }
        "FAIL" { 
            $script:TestResults.Summary.Failed++
            Write-Error "$testName`: $message"
            $script:TestResults.Errors += "$testName`: $message"
        }
        "WARN" { 
            $script:TestResults.Summary.Warnings++
            Write-Warning "$testName`: $message"
            $script:TestResults.Warnings += "$testName`: $message"
        }
    }
    
    Write-Debug "Test details: $($details | ConvertTo-Json -Compress)"
}

function Test-SystemRequirements {
    Write-Header "System Requirements Verification"
    
    # Test Node.js version
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            $versionNumber = $nodeVersion -replace 'v', ''
            $majorVersion = [int]($versionNumber -split '\.')[0]
            
            if ($majorVersion -ge 14) {
                Add-TestResult "NodeJS Version" "PASS" "Node.js $nodeVersion (>= v14.0.0 required)" @{ Version = $nodeVersion }
            } else {
                Add-TestResult "NodeJS Version" "FAIL" "Node.js $nodeVersion is too old (>= v14.0.0 required)" @{ Version = $nodeVersion }
            }
        } else {
            Add-TestResult "NodeJS Installation" "FAIL" "Node.js not found in PATH" @{}
        }
    } catch {
        Add-TestResult "NodeJS Check" "FAIL" "Failed to check Node.js: $($_.Exception.Message)" @{}
    }
    
    # Test npm
    try {
        $npmVersion = npm --version 2>$null
        if ($npmVersion) {
            Add-TestResult "NPM Installation" "PASS" "npm v$npmVersion is available" @{ Version = $npmVersion }
        } else {
            Add-TestResult "NPM Installation" "FAIL" "npm not found in PATH" @{}
        }
    } catch {
        Add-TestResult "NPM Check" "FAIL" "Failed to check npm: $($_.Exception.Message)" @{}
    }
    
    # Test Git (optional)
    try {
        $gitVersion = git --version 2>$null
        if ($gitVersion) {
            Add-TestResult "Git Installation" "PASS" "$gitVersion (optional)" @{ Version = $gitVersion }
        } else {
            Add-TestResult "Git Installation" "WARN" "Git not found (optional for development)" @{}
        }
    } catch {
        Add-TestResult "Git Check" "WARN" "Git not available (optional)" @{}
    }
}

function Test-ProjectStructure {
    Write-Header "Project Structure Verification"
    
    # Essential files
    $essentialFiles = @(
        @{ Path = "package.json"; Description = "Package configuration" },
        @{ Path = "src/server/index.js"; Description = "Server entry point" },
        @{ Path = "src/client/index.js"; Description = "Client entry point" },
        @{ Path = "config/webpack.js"; Description = "Webpack configuration" },
        @{ Path = "config/babel.js"; Description = "Babel configuration" }
    )
    
    foreach ($file in $essentialFiles) {
        if (Test-Path $file.Path) {
            Add-TestResult "File: $($file.Path)" "PASS" "$($file.Description) exists" @{ Path = $file.Path }
        } else {
            Add-TestResult "File: $($file.Path)" "FAIL" "$($file.Description) is missing" @{ Path = $file.Path }
        }
    }
    
    # Essential directories
    $essentialDirs = @(
        @{ Path = "src"; Description = "Source code directory" },
        @{ Path = "src/server"; Description = "Server source directory" },
        @{ Path = "src/client"; Description = "Client source directory" },
        @{ Path = "config"; Description = "Configuration directory" }
    )
    
    foreach ($dir in $essentialDirs) {
        if (Test-Path $dir.Path -PathType Container) {
            Add-TestResult "Directory: $($dir.Path)" "PASS" "$($dir.Description) exists" @{ Path = $dir.Path }
        } else {
            Add-TestResult "Directory: $($dir.Path)" "FAIL" "$($dir.Description) is missing" @{ Path = $dir.Path }
        }
    }
}

function Test-Dependencies {
    Write-Header "Dependencies Verification"
    
    # Check node_modules
    if (Test-Path "node_modules") {
        Add-TestResult "Node Modules" "PASS" "Dependencies directory exists" @{}
        
        # Check package-lock.json
        if (Test-Path "package-lock.json") {
            Add-TestResult "Package Lock" "PASS" "Package lock file exists" @{}
        } else {
            Add-TestResult "Package Lock" "WARN" "package-lock.json not found" @{}
        }
        
        # Check critical dependencies
        $criticalDeps = @("webpack", "preact", "socket.io", "polka")
        foreach ($dep in $criticalDeps) {
            if (Test-Path "node_modules/$dep") {
                Add-TestResult "Dependency: $dep" "PASS" "$dep is installed" @{ Package = $dep }
            } else {
                Add-TestResult "Dependency: $dep" "FAIL" "$dep is missing" @{ Package = $dep }
            }
        }
        
    } else {
        Add-TestResult "Node Modules" "FAIL" "Dependencies not installed - run 'npm install --legacy-peer-deps'" @{}
    }
}

function Test-Configuration {
    Write-Header "Configuration Verification"
    
    # Test package.json parsing
    try {
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        Add-TestResult "Package JSON Parse" "PASS" "package.json is valid JSON" @{ 
            Name = $packageJson.name
            Version = $packageJson.version 
        }
        
        # Check required scripts
        $requiredScripts = @("build", "watch")
        foreach ($script in $requiredScripts) {
            if ($packageJson.scripts.$script) {
                Add-TestResult "Script: $script" "PASS" "npm script '$script' is configured" @{ Script = $packageJson.scripts.$script }
            } else {
                Add-TestResult "Script: $script" "FAIL" "npm script '$script' is missing" @{}
            }
        }
        
    } catch {
        Add-TestResult "Package JSON Parse" "FAIL" "Failed to parse package.json: $($_.Exception.Message)" @{}
    }
    
    # Test webpack config
    try {
        if (Test-Path "config/webpack.js") {
            # Basic syntax check by attempting to load the file
            $webpackConfig = Get-Content "config/webpack.js" -Raw
            if ($webpackConfig -match "module\.exports") {
                Add-TestResult "Webpack Config" "PASS" "Webpack configuration appears valid" @{}
            } else {
                Add-TestResult "Webpack Config" "WARN" "Webpack configuration format unclear" @{}
            }
        }
    } catch {
        Add-TestResult "Webpack Config" "FAIL" "Failed to validate webpack config: $($_.Exception.Message)" @{}
    }
}

function Test-BuildProcess {
    Write-Header "Build Process Verification"
    
    if (-not $QuickTest) {
        Write-Info "Testing build process (this may take a few minutes)..."
        
        try {
            # Clean previous build
            if (Test-Path "dist") {
                Remove-Item "dist" -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            # Test build
            $buildOutput = npm run build 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Add-TestResult "Build Process" "PASS" "Production build completed successfully" @{}
                
                # Check build outputs
                if (Test-Path "dist") {
                    Add-TestResult "Build Output" "PASS" "Build directory created" @{}
                    
                    $buildFiles = @("index.html", "server", "assets")
                    foreach ($file in $buildFiles) {
                        $filePath = Join-Path "dist" $file
                        if (Test-Path $filePath) {
                            Add-TestResult "Build File: $file" "PASS" "Build artifact exists" @{ Path = $filePath }
                        } else {
                            Add-TestResult "Build File: $file" "WARN" "Build artifact missing" @{ Path = $filePath }
                        }
                    }
                } else {
                    Add-TestResult "Build Output" "FAIL" "Build directory not created" @{}
                }
                
            } else {
                Add-TestResult "Build Process" "FAIL" "Build failed with exit code $LASTEXITCODE" @{ 
                    ExitCode = $LASTEXITCODE
                    Output = $buildOutput -join "`n"
                }
            }
            
        } catch {
            Add-TestResult "Build Process" "FAIL" "Build process exception: $($_.Exception.Message)" @{}
        }
    } else {
        Add-TestResult "Build Process" "WARN" "Skipped (QuickTest mode)" @{}
    }
}

function Test-ServerStartup {
    Write-Header "Server Startup Verification"
    
    if (-not $QuickTest) {
        Write-Info "Testing server startup (timeout: $TestTimeout seconds)..."
        
        try {
            # Start the development server in background
            $serverProcess = Start-Process -FilePath "npm" -ArgumentList "run", "watch" -NoNewWindow -PassThru -RedirectStandardOutput "logs/test-server.log" -RedirectStandardError "logs/test-error.log"
            
            Add-TestResult "Server Start" "PASS" "Development server started (PID: $($serverProcess.Id))" @{ ProcessId = $serverProcess.Id }
            
            # Wait for server to be ready
            $timeout = $TestTimeout
            $serverReady = $false
            
            while ($timeout -gt 0 -and -not $serverReady) {
                Start-Sleep -Seconds 2
                $timeout -= 2
                
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
                    if ($response -and $response.StatusCode -eq 200) {
                        $serverReady = $true
                        Add-TestResult "Server Response" "PASS" "Server is responding on port $Port" @{ 
                            StatusCode = $response.StatusCode
                            ResponseTime = $timeout
                        }
                    }
                } catch {
                    Write-Debug "Server not ready yet... ($timeout seconds remaining)"
                }
            }
            
            if (-not $serverReady) {
                Add-TestResult "Server Response" "FAIL" "Server did not respond within $TestTimeout seconds" @{ Timeout = $TestTimeout }
            }
            
            # Performance test
            if ($Performance -and $serverReady) {
                Write-Info "Running performance tests..."
                
                $responseTimes = @()
                for ($i = 1; $i -le 5; $i++) {
                    try {
                        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                        $response = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
                        $stopwatch.Stop()
                        $responseTimes += $stopwatch.ElapsedMilliseconds
                    } catch {
                        Write-Debug "Performance test $i failed: $($_.Exception.Message)"
                    }
                }
                
                if ($responseTimes.Count -gt 0) {
                    $avgResponseTime = ($responseTimes | Measure-Object -Average).Average
                    Add-TestResult "Performance Test" "PASS" "Average response time: $([math]::Round($avgResponseTime, 1)) ms" @{ 
                        AverageMs = $avgResponseTime
                        Samples = $responseTimes.Count
                    }
                } else {
                    Add-TestResult "Performance Test" "FAIL" "All performance tests failed" @{}
                }
            }
            
            # Cleanup: Stop the server
            try {
                if (-not $serverProcess.HasExited) {
                    $serverProcess.Kill()
                    Add-TestResult "Server Cleanup" "PASS" "Development server stopped successfully" @{}
                }
            } catch {
                Add-TestResult "Server Cleanup" "WARN" "Failed to stop server cleanly: $($_.Exception.Message)" @{}
            }
            
        } catch {
            Add-TestResult "Server Startup" "FAIL" "Server startup failed: $($_.Exception.Message)" @{}
        }
    } else {
        Add-TestResult "Server Startup" "WARN" "Skipped (QuickTest mode)" @{}
    }
}

function Test-Scripts {
    Write-Header "Script Verification"
    
    # Test our custom scripts
    $customScripts = @(
        @{ Path = "scripts/check-dependencies.ps1"; Description = "Dependency checker" },
        @{ Path = "scripts/init-project.ps1"; Description = "Project initializer" },
        @{ Path = "scripts/start-dev.ps1"; Description = "Development starter" },
        @{ Path = "scripts/start-prod.ps1"; Description = "Production builder" },
        @{ Path = "scripts/health-check.ps1"; Description = "Health checker" }
    )
    
    foreach ($script in $customScripts) {
        if (Test-Path $script.Path) {
            # Basic syntax check
            try {
                $scriptContent = Get-Content $script.Path -Raw
                if ($scriptContent -match "param\s*\(" -and $scriptContent -match "#!/usr/bin/env pwsh") {
                    Add-TestResult "Script: $($script.Path)" "PASS" "$($script.Description) is available and valid" @{ Path = $script.Path }
                } else {
                    Add-TestResult "Script: $($script.Path)" "WARN" "$($script.Description) format issues" @{ Path = $script.Path }
                }
            } catch {
                Add-TestResult "Script: $($script.Path)" "FAIL" "Script validation failed: $($_.Exception.Message)" @{ Path = $script.Path }
            }
        } else {
            Add-TestResult "Script: $($script.Path)" "FAIL" "$($script.Description) is missing" @{ Path = $script.Path }
        }
    }
}

# Main execution
Write-Header "Jarvis Installation Verification"
Write-Info "Test Mode: $(if ($QuickTest) { 'Quick Test' } elseif ($FullTest) { 'Full Test' } else { 'Standard Test' })"
Write-Info "Performance Tests: $(if ($Performance) { 'Enabled' } else { 'Disabled' })"
Write-Info "Port: $Port"
Write-Info "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Create logs directory
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" -Force | Out-Null
}

# Run test suites
Test-SystemRequirements
Test-ProjectStructure
Test-Dependencies
Test-Configuration
Test-Scripts

if ($FullTest -or -not $QuickTest) {
    Test-BuildProcess
    Test-ServerStartup
}

# Generate final report
$endTime = Get-Date
$duration = $endTime - $script:TestResults.StartTime

Write-Header "🎯 Verification Complete!"

$passRate = if ($script:TestResults.Summary.Total -gt 0) { 
    [math]::Round(($script:TestResults.Summary.Passed / $script:TestResults.Summary.Total) * 100, 1) 
} else { 0 }

Write-Host ""
Write-Host "📊 Test Summary:" -ForegroundColor Yellow
Write-Host "  Total Tests: $($script:TestResults.Summary.Total)" -ForegroundColor White
Write-Host "  Passed: $($script:TestResults.Summary.Passed)" -ForegroundColor Green
Write-Host "  Failed: $($script:TestResults.Summary.Failed)" -ForegroundColor Red
Write-Host "  Warnings: $($script:TestResults.Summary.Warnings)" -ForegroundColor Yellow
Write-Host "  Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { 'Green' } elseif ($passRate -ge 60) { 'Yellow' } else { 'Red' })
Write-Host "  Duration: $($duration.TotalSeconds.ToString('F1')) seconds" -ForegroundColor White

if ($script:TestResults.Summary.Failed -eq 0) {
    Write-Host ""
    Write-Success "🎉 All critical tests passed! Jarvis is ready for use."
    Write-Info "You can start development with: ./scripts/start-dev.ps1"
} else {
    Write-Host ""
    Write-Error "💥 $($script:TestResults.Summary.Failed) test(s) failed. Please address the issues before using Jarvis."
    
    Write-Host "`n🔧 Failed Tests:" -ForegroundColor Red
    foreach ($errorItem in $script:TestResults.Errors) {
        Write-Host "  • $errorItem" -ForegroundColor Red
    }
    
    Write-Host "`n📋 Recommended Actions:" -ForegroundColor Yellow
    Write-Host "  1. Run dependency installer: ./scripts/init-project.ps1" -ForegroundColor White
    Write-Host "  2. Check system requirements: ./scripts/check-dependencies.ps1" -ForegroundColor White
    Write-Host "  3. Review error details in the test results below" -ForegroundColor White
}

if ($script:TestResults.Summary.Warnings -gt 0) {
    Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
    foreach ($warning in $script:TestResults.Warnings) {
        Write-Host "  • $warning" -ForegroundColor Yellow
    }
}

# Save detailed results
try {
    $resultsJson = $script:TestResults | ConvertTo-Json -Depth 4
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Set-Content -Path "logs/verification-$timestamp.json" -Value $resultsJson -Encoding UTF8
    Write-Debug "Detailed results saved to logs/verification-$timestamp.json"
} catch {
    Write-Warning "Could not save detailed results: $($_.Exception.Message)"
}

# Exit with appropriate code
if ($script:TestResults.Summary.Failed -eq 0) {
    exit 0
} else {
    exit 1
}