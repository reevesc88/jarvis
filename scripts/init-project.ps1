#!/usr/bin/env pwsh
# Jarvis Project Initialization Script
# Sets up the project from scratch for development

param(
    [switch]$SkipDependencyCheck,
    [switch]$Force,
    [string]$NodeVersion = "latest",
    [string]$Port = "1337"
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Success($message) { Write-Host "✅ $message" -ForegroundColor Green }
function Write-Error($message) { Write-Host "❌ $message" -ForegroundColor Red }
function Write-Warning($message) { Write-Host "⚠️  $message" -ForegroundColor Yellow }
function Write-Info($message) { Write-Host "ℹ️  $message" -ForegroundColor Cyan }
function Write-Header($message) {
    Write-Host "`n🚀 $message" -ForegroundColor Magenta
    Write-Host ("=" * ($message.Length + 4)) -ForegroundColor Magenta
}

Write-Header "Jarvis Webpack Dashboard - Project Initialization"
Write-Info "This script will set up Jarvis for development and production use"

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Error "package.json not found. Please run this script from the project root directory."
    exit 1
}

# Step 1: System dependency check
if (-not $SkipDependencyCheck) {
    Write-Header "Step 1: Checking System Dependencies"
    
    if (Test-Path "scripts/check-dependencies.ps1") {
        Write-Info "Running dependency check..."
        $checkResult = & "scripts/check-dependencies.ps1"
        
        if ($LASTEXITCODE -ne 0 -and -not $Force) {
            Write-Error "Dependency check failed. Use -Force to continue anyway, or fix the issues first."
            exit 1
        } elseif ($LASTEXITCODE -ne 0) {
            Write-Warning "Dependency check had warnings, but continuing due to -Force flag"
        } else {
            Write-Success "All system dependencies check passed"
        }
    } else {
        Write-Warning "Dependency check script not found, skipping system verification"
    }
} else {
    Write-Info "Skipping dependency check as requested"
}

# Step 2: Clean previous installations
Write-Header "Step 2: Cleaning Previous Installation"

if (Test-Path "node_modules") {
    if ($Force) {
        Write-Info "Removing existing node_modules directory..."
        Remove-Item "node_modules" -Recurse -Force
        Write-Success "Cleaned node_modules"
    } else {
        Write-Info "node_modules exists. Use -Force to clean and reinstall"
    }
}

if (Test-Path "package-lock.json" -and $Force) {
    Write-Info "Removing package-lock.json for fresh install..."
    Remove-Item "package-lock.json" -Force
}

if (Test-Path "dist") {
    Write-Info "Cleaning build directory..."
    Remove-Item "dist" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Success "Cleaned dist directory"
}

# Step 3: Install Node.js dependencies
Write-Header "Step 3: Installing Node.js Dependencies"

try {
    Write-Info "Installing npm packages (this may take a few minutes)..."
    
    # Use legacy peer deps for better compatibility with older packages
    $npmArgs = @("install", "--legacy-peer-deps")
    
    if ($env:CI -eq "true") {
        $npmArgs += "--prefer-offline"
        $npmArgs += "--no-audit"
    }
    
    Write-Info "Running: npm $($npmArgs -join ' ')"
    & npm @npmArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Dependencies installed successfully"
    } else {
        throw "npm install failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "Failed to install dependencies: $($_.Exception.Message)"
    Write-Info "Try running manually: npm install --legacy-peer-deps"
    exit 1
}

# Step 4: Verify critical files
Write-Header "Step 4: Verifying Project Structure"

$criticalPaths = @(
    @{ Path = "src/server"; Type = "Directory"; Description = "Server source files" },
    @{ Path = "src/client"; Type = "Directory"; Description = "Client source files" },
    @{ Path = "config"; Type = "Directory"; Description = "Webpack configuration" },
    @{ Path = "src/server/index.js"; Type = "File"; Description = "Main server entry point" },
    @{ Path = "config/webpack.js"; Type = "File"; Description = "Webpack configuration" },
    @{ Path = "config/babel.js"; Type = "File"; Description = "Babel configuration" }
)

foreach ($item in $criticalPaths) {
    if (Test-Path $item.Path) {
        Write-Success "$($item.Description): $($item.Path)"
    } else {
        Write-Error "Missing $($item.Description): $($item.Path)"
    }
}

# Step 5: Create necessary directories
Write-Header "Step 5: Creating Required Directories"

$requiredDirs = @("logs", "tmp", "dist")
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "Created directory: $dir"
    } else {
        Write-Info "Directory already exists: $dir"
    }
}

# Step 6: Environment configuration
Write-Header "Step 6: Environment Configuration"

# Create a basic .env file if it doesn't exist
if (-not (Test-Path ".env")) {
    $envContent = @"
# Jarvis Configuration
JARVIS_PORT=$Port
JARVIS_HOST=localhost
JARVIS_ENV=development
NODE_ENV=development

# Optional configurations
# JARVIS_WATCH_ONLY=true
# JARVIS_PACKAGE_JSON_PATH=./
"@
    
    Set-Content -Path ".env" -Value $envContent
    Write-Success "Created .env configuration file"
} else {
    Write-Info ".env file already exists"
}

# Step 7: Test build
Write-Header "Step 7: Testing Build Process"

try {
    Write-Info "Testing webpack build..."
    $env:NODE_ENV = "production"
    & npm run build
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Build test successful"
    } else {
        Write-Warning "Build test failed - check configuration"
    }
} catch {
    Write-Warning "Build test failed: $($_.Exception.Message)"
}

# Step 8: Health check
Write-Header "Step 8: Final Health Check"

# Check if all necessary packages are available
$requiredCommands = @("node", "npm")
foreach ($cmd in $requiredCommands) {
    try {
        $version = & $cmd --version 2>$null
        Write-Success "$cmd is available: $version"
    } catch {
        Write-Error "$cmd is not available in PATH"
    }
}

# Check package.json scripts
try {
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    $requiredScripts = @("build", "watch")
    
    foreach ($script in $requiredScripts) {
        if ($packageJson.scripts.$script) {
            Write-Success "npm script '$script' is configured"
        } else {
            Write-Warning "npm script '$script' is missing"
        }
    }
} catch {
    Write-Warning "Could not verify package.json scripts"
}

# Step 9: Create startup shortcuts
Write-Header "Step 9: Creating Startup Scripts"

# Development script
$devScript = @"
#!/usr/bin/env pwsh
# Quick development server startup
Write-Host "🚀 Starting Jarvis Development Server..." -ForegroundColor Green
Write-Host "Dashboard will be available at: http://localhost:$Port" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

try {
    npm run watch
} catch {
    Write-Host "❌ Failed to start development server" -ForegroundColor Red
    Write-Host "Run 'npm run watch' manually for more details" -ForegroundColor Yellow
}
"@

Set-Content -Path "start-dev.ps1" -Value $devScript
Write-Success "Created start-dev.ps1 shortcut"

# Production script
$prodScript = @"
#!/usr/bin/env pwsh
# Production build script
Write-Host "🏗️  Building Jarvis for Production..." -ForegroundColor Green

try {
    npm run build
    Write-Host "✅ Production build completed successfully!" -ForegroundColor Green
    Write-Host "Built files are in the 'dist' directory" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Production build failed" -ForegroundColor Red
    Write-Host "Run 'npm run build' manually for more details" -ForegroundColor Yellow
}
"@

Set-Content -Path "build-prod.ps1" -Value $prodScript
Write-Success "Created build-prod.ps1 shortcut"

# Final summary
Write-Header "🎉 Initialization Complete!"

Write-Host ""
Write-Success "Jarvis Webpack Dashboard is ready for development!"
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Start development server: " -NoNewline -ForegroundColor White
Write-Host "./start-dev.ps1" -ForegroundColor Green
Write-Host "     or: " -NoNewline -ForegroundColor White  
Write-Host "npm run watch" -ForegroundColor Green
Write-Host ""
Write-Host "  2. Open your browser to: " -NoNewline -ForegroundColor White
Write-Host "http://localhost:$Port" -ForegroundColor Cyan
Write-Host ""
Write-Host "  3. For production build: " -NoNewline -ForegroundColor White
Write-Host "./build-prod.ps1" -ForegroundColor Green
Write-Host "     or: " -NoNewline -ForegroundColor White
Write-Host "npm run build" -ForegroundColor Green
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Yellow
Write-Host "  • Check docs/SETUP.md for detailed setup guide" -ForegroundColor White
Write-Host "  • Run scripts/check-dependencies.ps1 for system verification" -ForegroundColor White
Write-Host ""
Write-Host "🐛 Troubleshooting:" -ForegroundColor Yellow
Write-Host "  • If you encounter issues, run: scripts/check-dependencies.ps1 -Fix" -ForegroundColor White
Write-Host "  • For fresh install: ./scripts/init-project.ps1 -Force" -ForegroundColor White

exit 0