#!/usr/bin/env pwsh
# Jarvis Development Server Startup Script
# Handles development server with hot reloading and error recovery

param(
    [string]$Port = "1337",
    [string]$ServerHost = "localhost",
    [switch]$OpenBrowser,
    [switch]$Verbose,
    [switch]$SkipHealthCheck
)

$ErrorActionPreference = "Continue"

# Color output functions
function Write-Success($message) { Write-Host "✅ $message" -ForegroundColor Green }
function Write-Error($message) { Write-Host "❌ $message" -ForegroundColor Red }
function Write-Warning($message) { Write-Host "⚠️  $message" -ForegroundColor Yellow }
function Write-Info($message) { Write-Host "ℹ️  $message" -ForegroundColor Cyan }
function Write-Debug($message) { if ($Verbose) { Write-Host "🔍 $message" -ForegroundColor Gray } }
function Write-Header($message) {
    Write-Host "`n🚀 $message" -ForegroundColor Magenta
    Write-Host ("=" * ($message.Length + 4)) -ForegroundColor Magenta
}

# Cleanup function for graceful shutdown
function Cleanup {
    Write-Host "`n🛑 Shutting down development server..." -ForegroundColor Yellow
    
    # Kill any running webpack processes
    try {
        Get-Process | Where-Object { $_.ProcessName -like "*node*" -and $_.CommandLine -like "*webpack*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        Get-Process | Where-Object { $_.ProcessName -like "*npm*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Debug "No webpack processes to cleanup"
    }
    
    Write-Success "Development server stopped"
    exit 0
}

# Set up Ctrl+C handler
Register-EngineEvent PowerShell.Exiting -Action { Cleanup }
[Console]::TreatControlCAsInput = $false
[Console]::CancelKeyPress += { Cleanup }

Write-Header "Jarvis Development Server"
Write-Info "Starting Jarvis Webpack Dashboard development environment"
Write-Info "Server will be available at: http://$ServerHost`:$Port"
Write-Info "Press Ctrl+C to stop the server"

# Pre-flight checks
if (-not $SkipHealthCheck) {
    Write-Header "Pre-flight Checks"
    
    # Check if in correct directory
    if (-not (Test-Path "package.json")) {
        Write-Error "package.json not found. Run this script from the project root."
        exit 1
    }
    
    # Check Node.js
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Success "Node.js: $nodeVersion"
        } else {
            Write-Error "Node.js not found in PATH"
            exit 1
        }
    } catch {
        Write-Error "Failed to check Node.js: $($_.Exception.Message)"
        exit 1
    }
    
    # Check npm
    try {
        $npmVersion = npm --version 2>$null
        Write-Success "npm: v$npmVersion"
    } catch {
        Write-Error "npm not found in PATH"
        exit 1
    }
    
    # Check if dependencies are installed
    if (-not (Test-Path "node_modules")) {
        Write-Warning "node_modules not found. Installing dependencies..."
        try {
            npm install --legacy-peer-deps
            Write-Success "Dependencies installed"
        } catch {
            Write-Error "Failed to install dependencies. Run 'npm install --legacy-peer-deps' manually."
            exit 1
        }
    } else {
        Write-Success "Dependencies are installed"
    }
    
    # Check critical files
    $criticalFiles = @("src/server/index.js", "config/webpack.js", "src/client/index.js")
    foreach ($file in $criticalFiles) {
        if (Test-Path $file) {
            Write-Debug "Found: $file"
        } else {
            Write-Error "Critical file missing: $file"
            exit 1
        }
    }
}

# Port availability check
Write-Header "Port Configuration"
try {
    $portInUse = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Warning "Port $Port is already in use"
        Write-Info "You can:"
        Write-Info "  1. Stop the service using port $Port"
        Write-Info "  2. Use a different port: ./scripts/start-dev.ps1 -Port 3000"
        
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -notmatch '^[yY]') {
            Write-Info "Startup cancelled by user"
            exit 0
        }
    } else {
        Write-Success "Port $Port is available"
    }
} catch {
    Write-Debug "Could not check port availability: $($_.Exception.Message)"
}

# Environment setup
Write-Header "Environment Setup"
$env:JARVIS_PORT = $Port
$env:JARVIS_HOST = $ServerHost
$env:JARVIS_ENV = "development"
$env:NODE_ENV = "development"

Write-Success "Environment configured:"
Write-Info "  JARVIS_PORT=$Port"
Write-Info "  JARVIS_HOST=$ServerHost"
Write-Info "  NODE_ENV=development"

# Clean previous builds
if (Test-Path "dist") {
    Write-Info "Cleaning previous build..."
    Remove-Item "dist" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Success "Build directory cleaned"
}

# Start development server
Write-Header "Starting Development Server"
Write-Info "Initializing webpack development server..."
Write-Info "This may take a moment on first run..."

try {
    # Start the webpack watch process
    Write-Success "Starting webpack in watch mode..."
    
    if ($Verbose) {
        Write-Info "Running: npm run watch"
        $process = Start-Process -FilePath "npm" -ArgumentList "run", "watch" -NoNewWindow -PassThru
    } else {
        $process = Start-Process -FilePath "npm" -ArgumentList "run", "watch" -NoNewWindow -PassThru -RedirectStandardOutput "logs/dev-output.log" -RedirectStandardError "logs/dev-error.log"
    }
    
    # Wait a moment for the server to start
    Start-Sleep -Seconds 3
    
    # Check if process is still running
    if ($process.HasExited) {
        Write-Error "Development server failed to start"
        Write-Info "Check logs in ./logs/ directory for details"
        exit 1
    }
    
    Write-Success "Development server started successfully!"
    Write-Header "🎉 Jarvis Dashboard Ready!"
    
    Write-Host ""
    Write-Host "📊 Dashboard URL: " -NoNewline -ForegroundColor Yellow
    Write-Host "http://$ServerHost`:$Port" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔥 Features:" -ForegroundColor Yellow
    Write-Host "  • Hot Module Replacement (HMR) enabled" -ForegroundColor White
    Write-Host "  • Real-time webpack statistics" -ForegroundColor White
    Write-Host "  • Bundle size analysis" -ForegroundColor White
    Write-Host "  • Performance budgets" -ForegroundColor White
    Write-Host "  • Error overlay with search integration" -ForegroundColor White
    Write-Host ""
    Write-Host "⚡ Development Tips:" -ForegroundColor Yellow
    Write-Host "  • Changes to source files will auto-reload" -ForegroundColor White
    Write-Host "  • Check the terminal for webpack compilation status" -ForegroundColor White
    Write-Host "  • Use browser dev tools for debugging" -ForegroundColor White
    Write-Host ""
    Write-Host "🛑 To stop the server: " -NoNewline -ForegroundColor Yellow
    Write-Host "Press Ctrl+C" -ForegroundColor Red
    Write-Host ""
    
    # Open browser if requested
    if ($OpenBrowser) {
        Write-Info "Opening browser..."
        try {
            Start-Process "http://$ServerHost`:$Port"
            Write-Success "Browser opened"
        } catch {
            Write-Warning "Could not open browser automatically"
        }
    }
    
    # Monitor the process
    Write-Info "Monitoring development server (PID: $($process.Id))..."
    
    while (-not $process.HasExited) {
        Start-Sleep -Seconds 5
        
        # Check if port is responding
        try {
            $response = Invoke-WebRequest -Uri "http://$ServerHost`:$Port" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
            if (-not $response -or $response.StatusCode -ne 200) {
                Write-Warning "Server not responding on http://$ServerHost`:$Port"
            }
        } catch {
            Write-Debug "Health check failed: $($_.Exception.Message)"
        }
    }
    
    Write-Warning "Development server process has exited"
    
} catch {
    Write-Error "Failed to start development server: $($_.Exception.Message)"
    Write-Info ""
    Write-Info "🔧 Troubleshooting:"
    Write-Info "  1. Check if all dependencies are installed: npm install --legacy-peer-deps"
    Write-Info "  2. Verify system requirements: ./scripts/check-dependencies.ps1"
    Write-Info "  3. Try a fresh installation: ./scripts/init-project.ps1 -Force"
    Write-Info "  4. Check logs in ./logs/ directory"
    Write-Info "  5. Try manual start: npm run watch"
    
    exit 1
} finally {
    Cleanup
}