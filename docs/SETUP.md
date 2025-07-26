# Jarvis Webpack Dashboard - Complete Setup Guide

## 🚀 Quick Start

**TL;DR - Get up and running in 3 commands:**

```powershell
# 1. Initialize the project
./scripts/init-project.ps1

# 2. Start development server
./scripts/start-dev.ps1

# 3. Open http://localhost:1337 in your browser
```

---

## 📋 Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation Methods](#installation-methods)
3. [Project Setup](#project-setup)
4. [Development Workflow](#development-workflow)
5. [Production Deployment](#production-deployment)
6. [Configuration](#configuration)
7. [Scripts Reference](#scripts-reference)
8. [Troubleshooting](#troubleshooting)
9. [Performance Optimization](#performance-optimization)
10. [Advanced Usage](#advanced-usage)

---

## 🔧 System Requirements

### Minimum Requirements

| Component | Version | Required |
|-----------|---------|----------|
| **Node.js** | >= 14.0.0 | ✅ Required |
| **npm** | >= 6.0.0 | ✅ Required |
| **PowerShell** | >= 5.1 | ✅ Required (Windows) |
| **Git** | Latest | ⚠️ Optional |
| **Memory** | 4GB RAM | ✅ Required |
| **Storage** | 1GB free | ✅ Required |

### Recommended Requirements

| Component | Version | Benefits |
|-----------|---------|----------|
| **Node.js** | >= 18.0.0 | Better performance, latest features |
| **npm** | >= 8.0.0 | Improved dependency resolution |
| **Memory** | 8GB RAM | Faster builds, better multitasking |
| **Storage** | 2GB free | Room for builds and logs |

### Platform Support

- ✅ **Windows 10/11** (Primary)
- ✅ **Linux** (Ubuntu, CentOS, etc.)
- ✅ **macOS** (10.14+)

---

## 📦 Installation Methods

### Method 1: Automated Setup (Recommended)

```powershell
# Clone the repository (if not already done)
git clone <repository-url>
cd jarvis

# Run the automated setup
./scripts/init-project.ps1
```

**What this does:**
- ✅ Checks system requirements
- ✅ Installs all dependencies
- ✅ Creates necessary directories
- ✅ Sets up environment configuration
- ✅ Tests the build process
- ✅ Creates startup shortcuts

### Method 2: Manual Setup

```powershell
# 1. Verify system requirements
./scripts/check-dependencies.ps1

# 2. Install dependencies
npm install --legacy-peer-deps

# 3. Create required directories
mkdir logs, tmp, dist -Force

# 4. Test build
npm run build

# 5. Start development server
npm run watch
```

### Method 3: Docker Setup

```dockerfile
# Use the provided Dockerfile
docker build -t jarvis .
docker run -p 1337:8080 jarvis
```

---

## 🔨 Project Setup

### 1. Initial Verification

Before starting, verify your system meets the requirements:

```powershell
# Check system dependencies
./scripts/check-dependencies.ps1 -Verbose

# Run comprehensive verification
./scripts/verify-installation.ps1 -FullTest
```

### 2. Environment Configuration

Create a `.env` file for custom configuration:

```env
# Server Configuration
JARVIS_PORT=1337
JARVIS_HOST=localhost
JARVIS_ENV=development

# Build Configuration
NODE_ENV=development
JARVIS_WATCH_ONLY=true
JARVIS_PACKAGE_JSON_PATH=./

# Optional: Custom paths
# JARVIS_LOG_PATH=./logs
# JARVIS_TEMP_PATH=./tmp
```

### 3. Project Structure

After setup, your project should look like this:

```
jarvis/
├── 📁 config/              # Webpack & build configuration
│   ├── babel.js            # Babel transpilation settings
│   ├── browsers.json       # Browser compatibility targets
│   ├── style.js            # CSS/SCSS processing
│   ├── uglify.json         # JavaScript minification
│   └── webpack.js          # Main webpack configuration
├── 📁 docs/                # Documentation
│   ├── SETUP.md           # This file
│   ├── TROUBLESHOOTING.md # Problem solving guide
│   └── DEPLOYMENT.md      # Production deployment
├── 📁 scripts/             # Automation scripts
│   ├── check-dependencies.ps1  # System verification
│   ├── init-project.ps1        # Project initialization
│   ├── start-dev.ps1           # Development server
│   ├── start-prod.ps1          # Production build
│   ├── health-check.ps1        # Health monitoring
│   └── verify-installation.ps1 # Complete verification
├── 📁 src/                 # Source code
│   ├── 📁 client/          # Frontend application
│   ├── 📁 server/          # Backend server
│   └── 📁 assets/          # Static assets
├── 📁 dist/                # Production build output
├── 📁 logs/                # Application logs
├── 📁 tmp/                 # Temporary files
├── package.json            # Project dependencies
└── README.md              # Project overview
```

---

## 🛠️ Development Workflow

### Starting Development

```powershell
# Option 1: Use the startup script (recommended)
./scripts/start-dev.ps1

# Option 2: Direct npm command
npm run watch

# Option 3: With custom port
./scripts/start-dev.ps1 -Port 3000

# Option 4: Auto-open browser
./scripts/start-dev.ps1 -OpenBrowser
```

### Development Features

- 🔥 **Hot Module Replacement (HMR)** - Instant updates without page refresh
- 📊 **Real-time Statistics** - Live webpack build metrics
- 🎯 **Error Overlay** - In-browser error display with stack traces
- 🔍 **Bundle Analysis** - Size analysis and optimization hints
- ⚡ **Fast Refresh** - Quick development cycle

### Making Changes

1. **Edit source files** in `src/client/` or `src/server/`
2. **Changes auto-compile** and browser refreshes automatically
3. **Check terminal** for compilation status and errors
4. **View updates** at `http://localhost:1337`

### Development Tools

```powershell
# Health check during development
./scripts/health-check.ps1

# Continuous monitoring
./scripts/health-check.ps1 -Continuous -Interval 30

# Performance testing
./scripts/health-check.ps1 -Verbose

# Dependency verification
./scripts/check-dependencies.ps1 -Fix
```

---

## 🚀 Production Deployment

### Building for Production

```powershell
# Full production build
./scripts/start-prod.ps1

# Custom environment
./scripts/start-prod.ps1 -Environment production

# With deployment preparation
./scripts/start-prod.ps1 -Deploy -DeployTarget docker

# Clean build
./scripts/start-prod.ps1 -CleanBuild
```

### Deployment Options

#### 1. Local Server Deployment

```powershell
# Build for production
npm run build

# Start production server
node dist/server.js
```

#### 2. Docker Deployment

```bash
# Build Docker image
docker build -t jarvis .

# Run container
docker run -d -p 8080:8080 --name jarvis-app jarvis

# With environment variables
docker run -d -p 8080:8080 -e PORT=8080 jarvis
```

#### 3. Static File Deployment

1. Run `npm run build`
2. Copy `dist/` directory to your web server
3. Configure server to serve `index.html` for all routes
4. Set appropriate caching headers for assets

### Production Verification

```powershell
# Verify production build
./scripts/verify-installation.ps1 -FullTest -Performance

# Health check production server
./scripts/health-check.ps1 -Url "http://your-domain.com"
```

---

## ⚙️ Configuration

### Webpack Configuration

Edit [`config/webpack.js`](../config/webpack.js) for build customization:

```javascript
// Example customizations
module.exports = (env) => ({
    // Entry points
    entry: './src/client/index.js',
    
    // Output configuration
    output: {
        path: path.resolve(__dirname, '../dist'),
        filename: '[name].[contenthash].js'
    },
    
    // Development server
    devServer: {
        port: process.env.JARVIS_PORT || 1337,
        hot: true
    }
});
```

### Babel Configuration

Edit [`config/babel.js`](../config/babel.js) for transpilation settings:

```javascript
module.exports = {
    presets: [
        ['@babel/preset-env', {
            targets: require('./browsers.json')
        }]
    ],
    plugins: [
        '@babel/plugin-transform-react-jsx'
    ]
};
```

### Browser Support

Edit [`config/browsers.json`](../config/browsers.json) for target browsers:

```json
[
    "> 1%",
    "last 2 versions", 
    "IE >= 10"
]
```

---

## 📚 Scripts Reference

### Development Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `check-dependencies.ps1` | System verification | `./scripts/check-dependencies.ps1 -Fix` |
| `init-project.ps1` | Project initialization | `./scripts/init-project.ps1 -Force` |
| `start-dev.ps1` | Development server | `./scripts/start-dev.ps1 -Port 3000` |
| `health-check.ps1` | Health monitoring | `./scripts/health-check.ps1 -Continuous` |
| `verify-installation.ps1` | Complete testing | `./scripts/verify-installation.ps1 -FullTest` |

### Production Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `start-prod.ps1` | Production build | `./scripts/start-prod.ps1 -Deploy` |
| `build-prod.ps1` | Quick production build | `./build-prod.ps1` |

### NPM Scripts

| Command | Purpose | Environment |
|---------|---------|-------------|
| `npm run watch` | Development server | Development |
| `npm run build` | Production build | Production |
| `npm run copy:server` | Copy server files | Build |
| `npm run copy:assets` | Copy static assets | Build |

### Script Parameters

#### `start-dev.ps1` Parameters

```powershell
-Port <number>          # Server port (default: 1337)
-ServerHost <string>    # Server host (default: localhost)
-OpenBrowser           # Auto-open browser
-Verbose               # Detailed output
-SkipHealthCheck       # Skip pre-flight checks
```

#### `start-prod.ps1` Parameters

```powershell
-Environment <string>   # Build environment (default: production)
-SkipBuild             # Skip build process
-Deploy                # Prepare for deployment
-DeployTarget <string> # Deployment target (local, docker)
-CleanBuild           # Clean previous builds
-Verbose              # Detailed output
```

#### `health-check.ps1` Parameters

```powershell
-Url <string>          # Target URL (default: http://localhost:1337)
-Timeout <number>      # Request timeout (default: 30)
-Continuous           # Continuous monitoring
-Interval <number>    # Check interval in seconds (default: 60)
-Verbose              # Detailed output
-LogToFile            # Save logs to file
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Port Already in Use

**Error:** `Port 1337 is already in use`

**Solutions:**
```powershell
# Use different port
./scripts/start-dev.ps1 -Port 3000

# Find and kill process using port
netstat -ano | findstr :1337
taskkill /PID <process-id> /F
```

#### 2. Dependencies Not Installed

**Error:** `node_modules not found`

**Solutions:**
```powershell
# Clean install
./scripts/init-project.ps1 -Force

# Manual install
npm install --legacy-peer-deps

# Clear npm cache
npm cache clean --force
```

#### 3. Build Failures

**Error:** `Build failed with exit code 1`

**Solutions:**
```powershell
# Check system requirements
./scripts/check-dependencies.ps1

# Clean build
./scripts/start-prod.ps1 -CleanBuild

# Verbose build output
npm run build -- --verbose
```

#### 4. Permission Errors

**Error:** `Access denied` or `Permission denied`

**Solutions:**
```powershell
# Run as administrator
Start-Process powershell -Verb runAs

# Check file permissions
icacls . /grant Everyone:F /T

# Use alternative PowerShell execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Diagnostic Commands

```powershell
# Complete system check
./scripts/check-dependencies.ps1 -Verbose

# Full verification test
./scripts/verify-installation.ps1 -FullTest -Verbose

# Health monitoring
./scripts/health-check.ps1 -Continuous -LogToFile

# Performance analysis
./scripts/verify-installation.ps1 -Performance
```

### Log Analysis

```powershell
# View recent logs
Get-Content logs/*.log -Tail 50

# Search for errors
Select-String "ERROR" logs/*.log

# Monitor logs in real-time
Get-Content logs/dev-output.log -Wait
```

### Getting Help

1. **Check the logs** in `logs/` directory
2. **Run diagnostics** with verification scripts
3. **Review error messages** in terminal output
4. **Check system resources** (memory, disk space)
5. **Verify network connectivity** for npm registry access

---

## ⚡ Performance Optimization

### Development Performance

```powershell
# Enable performance monitoring
./scripts/verify-installation.ps1 -Performance

# Optimize development build
$env:NODE_ENV = "development"
npm run watch
```

### Production Performance

```powershell
# Analyze bundle size
npm run build -- --analyze

# Enable production optimizations
$env:NODE_ENV = "production"
./scripts/start-prod.ps1
```

### System Optimization

1. **Increase Node.js memory limit:**
   ```powershell
   $env:NODE_OPTIONS = "--max-old-space-size=4096"
   ```

2. **Use SSD storage** for better I/O performance

3. **Close unnecessary applications** during builds

4. **Enable Windows Developer Mode** for faster file operations

---

## 🎯 Advanced Usage

### Custom Webpack Configuration

Create environment-specific webpack configs:

```javascript
// config/webpack.dev.js
module.exports = {
    mode: 'development',
    devtool: 'eval-source-map',
    // ... development specific settings
};

// config/webpack.prod.js  
module.exports = {
    mode: 'production',
    optimization: {
        minimize: true,
        // ... production optimizations
    }
};
```

### Environment Variables

Create environment-specific configurations:

```powershell
# Development
$env:JARVIS_ENV = "development"
$env:JARVIS_DEBUG = "true"

# Staging  
$env:JARVIS_ENV = "staging"
$env:JARVIS_PORT = "8080"

# Production
$env:JARVIS_ENV = "production"  
$env:NODE_ENV = "production"
```

### Custom Scripts

Create project-specific automation:

```powershell
# scripts/custom-deploy.ps1
param([string]$Target = "staging")

Write-Host "Deploying to $Target..."
./scripts/start-prod.ps1 -Environment $Target -Deploy -DeployTarget docker
```

### Monitoring Integration

```powershell
# Continuous integration health checks
./scripts/health-check.ps1 -Url "https://your-app.com" -LogToFile -Continuous

# Performance regression testing
./scripts/verify-installation.ps1 -Performance > performance-report.txt
```

---

## 📞 Support & Resources

### Documentation

- 📖 [Complete Setup Guide](SETUP.md) (this file)
- 🔧 [Troubleshooting Guide](TROUBLESHOOTING.md)
- 🚀 [Deployment Guide](DEPLOYMENT.md)
- 📊 [Performance Guide](PERFORMANCE.md)

### Community

- 💬 [GitHub Issues](https://github.com/zouhir/jarvis/issues)
- 📚 [Wiki](https://github.com/zouhir/jarvis/wiki)
- 🎯 [Discussions](https://github.com/zouhir/jarvis/discussions)

### Quick Reference

```powershell
# Emergency reset
./scripts/init-project.ps1 -Force

# Complete verification
./scripts/verify-installation.ps1 -FullTest

# Start fresh development session  
./scripts/start-dev.ps1 -OpenBrowser

# Production deployment
./scripts/start-prod.ps1 -Deploy
```

---

**🎉 You're all set! Jarvis is ready to help you analyze and optimize your webpack builds.**

For additional help, run `./scripts/check-dependencies.ps1 -Verbose` or check the troubleshooting guide.