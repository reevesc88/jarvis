#!/usr/bin/env pwsh
# Jarvis Production Build and Deployment Script
# Handles production builds, optimization, and deployment preparation

param(
    [string]$Environment = "production",
    [switch]$SkipBuild,
    [switch]$SkipTests,
    [switch]$Deploy,
    [string]$DeployTarget = "local",
    [switch]$Verbose,
    [switch]$CleanBuild
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Success($message) { Write-Host "✅ $message" -ForegroundColor Green }
function Write-Error($message) { Write-Host "❌ $message" -ForegroundColor Red }
function Write-Warning($message) { Write-Host "⚠️  $message" -ForegroundColor Yellow }
function Write-Info($message) { Write-Host "ℹ️  $message" -ForegroundColor Cyan }
function Write-Debug($message) { if ($Verbose) { Write-Host "🔍 $message" -ForegroundColor Gray } }
function Write-Header($message) {
    Write-Host "`n🏗️  $message" -ForegroundColor Magenta
    Write-Host ("=" * ($message.Length + 5)) -ForegroundColor Magenta
}

# Global variables
$script:BuildStartTime = Get-Date
$script:Errors = @()
$script:Warnings = @()

Write-Header "Jarvis Production Build & Deployment"
Write-Info "Environment: $Environment"
Write-Info "Target: $DeployTarget"
Write-Info "Started at: $($script:BuildStartTime.ToString('yyyy-MM-dd HH:mm:ss'))"

# Pre-build validation
Write-Header "Pre-Build Validation"

# Check if in correct directory
if (-not (Test-Path "package.json")) {
    Write-Error "package.json not found. Run this script from the project root."
    exit 1
}

# Validate package.json
try {
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    Write-Success "Project: $($packageJson.name) v$($packageJson.version)"
    
    if (-not $packageJson.scripts.build) {
        Write-Error "Build script not found in package.json"
        exit 1
    }
} catch {
    Write-Error "Failed to parse package.json: $($_.Exception.Message)"
    exit 1
}

# Check Node.js and npm versions
try {
    $nodeVersion = node --version 2>$null
    $npmVersion = npm --version 2>$null
    
    if ($nodeVersion -and $npmVersion) {
        Write-Success "Node.js: $nodeVersion, npm: v$npmVersion"
    } else {
        Write-Error "Node.js or npm not found in PATH"
        exit 1
    }
} catch {
    Write-Error "Failed to verify Node.js/npm: $($_.Exception.Message)"
    exit 1
}

# Check dependencies
if (-not (Test-Path "node_modules")) {
    Write-Warning "node_modules not found. Installing dependencies..."
    try {
        npm install --legacy-peer-deps --production=false
        Write-Success "Dependencies installed"
    } catch {
        Write-Error "Failed to install dependencies"
        exit 1
    }
} else {
    Write-Success "Dependencies are available"
}

# Environment setup
Write-Header "Environment Configuration"

$env:NODE_ENV = $Environment
$env:JARVIS_ENV = $Environment
$currentDate = Get-Date -Format "yyyy-MM-dd-HHmm"
$buildId = "$($packageJson.version)-$currentDate"

Write-Success "Environment variables set:"
Write-Info "  NODE_ENV=$Environment"
Write-Info "  JARVIS_ENV=$Environment"
Write-Info "  BUILD_ID=$buildId"

# Clean previous builds
if ($CleanBuild -or -not $SkipBuild) {
    Write-Header "Cleaning Previous Builds"
    
    if (Test-Path "dist") {
        Write-Info "Removing existing dist directory..."
        Remove-Item "dist" -Recurse -Force
        Write-Success "Cleaned dist directory"
    }
    
    # Clean other build artifacts
    $cleanupPaths = @("logs/*.log", "tmp/*", ".cache")
    foreach ($path in $cleanupPaths) {
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Debug "Cleaned: $path"
        }
    }
}

# Create required directories
$requiredDirs = @("dist", "logs", "tmp")
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Debug "Created directory: $dir"
    }
}

# Production build
if (-not $SkipBuild) {
    Write-Header "Production Build"
    
    try {
        Write-Info "Starting webpack production build..."
        Write-Info "This may take several minutes for optimization..."
        
        $buildStartTime = Get-Date
        
        if ($Verbose) {
            npm run build
        } else {
            $buildOutput = npm run build 2>&1
            $buildOutput | Out-File "logs/build-$currentDate.log" -Encoding UTF8
        }
        
        $buildDuration = (Get-Date) - $buildStartTime
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Build completed successfully in $($buildDuration.TotalSeconds.ToString('F1')) seconds"
        } else {
            Write-Error "Build failed with exit code $LASTEXITCODE"
            if (-not $Verbose) {
                Write-Info "Check build log: logs/build-$currentDate.log"
            }
            exit 1
        }
        
    } catch {
        Write-Error "Build process failed: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Info "Skipping build as requested"
}

# Post-build validation
Write-Header "Post-Build Validation"

# Check if dist directory was created
if (-not (Test-Path "dist")) {
    Write-Error "dist directory not found after build"
    exit 1
}

# Validate critical build outputs
$criticalOutputs = @(
    @{ Path = "dist/index.html"; Description = "Main HTML file" },
    @{ Path = "dist/server"; Description = "Server files" },
    @{ Path = "dist/assets"; Description = "Static assets" }
)

$missingOutputs = 0
foreach ($output in $criticalOutputs) {
    if (Test-Path $output.Path) {
        Write-Success "$($output.Description): $($output.Path)"
    } else {
        Write-Error "Missing $($output.Description): $($output.Path)"
        $missingOutputs++
    }
}

if ($missingOutputs -gt 0) {
    Write-Error "$missingOutputs critical build outputs are missing"
    exit 1
}

# Build size analysis
Write-Header "Build Analysis"

try {
    $distSize = (Get-ChildItem "dist" -Recurse | Measure-Object -Property Length -Sum).Sum
    $distSizeMB = [math]::Round($distSize / 1MB, 2)
    
    Write-Success "Total build size: $distSizeMB MB"
    
    # Analyze individual components
    $components = @("server", "assets", "*.html", "*.js", "*.css")
    foreach ($component in $components) {
        $componentPath = Join-Path "dist" $component
        if (Test-Path $componentPath) {
            $componentSize = (Get-ChildItem $componentPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            if ($componentSize -gt 0) {
                $componentSizeMB = [math]::Round($componentSize / 1MB, 2)
                Write-Info "  $component`: $componentSizeMB MB"
            }
        }
    }
    
    # Build size warnings
    if ($distSizeMB -gt 50) {
        Write-Warning "Build size is quite large ($distSizeMB MB). Consider optimization."
        $script:Warnings += "Large build size: $distSizeMB MB"
    }
    
} catch {
    Write-Warning "Could not analyze build size: $($_.Exception.Message)"
}

# Security scan (basic)
Write-Header "Security Validation"

try {
    # Check for common security issues
    $securityIssues = @()
    
    # Check for exposed secrets in build
    $buildFiles = Get-ChildItem "dist" -Recurse -Include "*.js", "*.html", "*.css" -ErrorAction SilentlyContinue
    foreach ($file in $buildFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            # Check for potential secrets (basic patterns)
            $secretPatterns = @(
                "password\s*[:=]\s*['\`"].*['\`"]",
                "api[_-]?key\s*[:=]\s*['\`"].*['\`"]",
                "secret\s*[:=]\s*['\`"].*['\`"]"
            )
            
            foreach ($pattern in $secretPatterns) {
                if ($content -match $pattern) {
                    $securityIssues += "Potential secret in $($file.Name)"
                }
            }
        }
    }
    
    if ($securityIssues.Count -eq 0) {
        Write-Success "No obvious security issues detected"
    } else {
        foreach ($issue in $securityIssues) {
            Write-Warning "Security: $issue"
            $script:Warnings += $issue
        }
    }
    
} catch {
    Write-Warning "Security scan failed: $($_.Exception.Message)"
}

# Performance optimization check
Write-Header "Performance Optimization"

try {
    # Check for minification
    $jsFiles = Get-ChildItem "dist" -Recurse -Include "*.js" -ErrorAction SilentlyContinue
    $minifiedCount = 0
    
    foreach ($jsFile in $jsFiles) {
        $content = Get-Content $jsFile.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and $content.Length -gt 0) {
            # Simple heuristic: minified files have longer lines
            $lines = $content -split "`n"
            $avgLineLength = ($lines | Measure-Object -Property Length -Average).Average
            
            if ($avgLineLength -gt 200) {
                $minifiedCount++
            }
        }
    }
    
    if ($jsFiles.Count -gt 0) {
        $minificationRate = [math]::Round(($minifiedCount / $jsFiles.Count) * 100, 1)
        Write-Info "JavaScript minification: $minificationRate% ($minifiedCount/$($jsFiles.Count) files)"
        
        if ($minificationRate -lt 80) {
            Write-Warning "Low minification rate detected. Check webpack configuration."
            $script:Warnings += "Low minification rate: $minificationRate%"
        }
    }
    
} catch {
    Write-Warning "Performance check failed: $($_.Exception.Message)"
}

# Create deployment manifest
Write-Header "Creating Deployment Manifest"

try {
    $manifest = @{
        buildId = $buildId
        version = $packageJson.version
        buildTime = $script:BuildStartTime.ToString('yyyy-MM-dd HH:mm:ss UTC')
        environment = $Environment
        nodeVersion = $nodeVersion.Trim()
        npmVersion = $npmVersion.Trim()
        buildSizeMB = $distSizeMB
        warnings = $script:Warnings
        files = @()
    }
    
    # Add file list to manifest
    $distFiles = Get-ChildItem "dist" -Recurse -File
    foreach ($file in $distFiles) {
        $relativePath = $file.FullName.Replace((Resolve-Path "dist").Path, "").TrimStart('\').Replace('\', '/')
        $manifest.files += @{
            path = $relativePath
            size = $file.Length
            lastModified = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        }
    }
    
    $manifestJson = $manifest | ConvertTo-Json -Depth 4
    Set-Content -Path "dist/manifest.json" -Value $manifestJson -Encoding UTF8
    
    Write-Success "Deployment manifest created: dist/manifest.json"
    
} catch {
    Write-Warning "Failed to create deployment manifest: $($_.Exception.Message)"
}

# Deployment preparation
if ($Deploy) {
    Write-Header "Deployment Preparation"
    
    switch ($DeployTarget.ToLower()) {
        "local" {
            Write-Info "Preparing for local deployment..."
            
            # Create a simple server script for local deployment
            $serverScript = @"
#!/usr/bin/env node
// Simple static server for Jarvis production build
const path = require('path');
const fs = require('fs');
const http = require('http');
const serveStatic = require('serve-static');

const port = process.env.PORT || 8080;
const distPath = path.join(__dirname);

// Serve static files
const serve = serveStatic(distPath, {
    'index': ['index.html'],
    'setHeaders': function(res, path) {
        // Set caching headers for assets
        if (path.match(/\.(js|css|png|jpg|jpeg|gif|ico|svg)$/)) {
            res.setHeader('Cache-Control', 'public, max-age=31536000'); // 1 year
        }
    }
});

const server = http.createServer((req, res) => {
    serve(req, res, () => {
        // Fallback for SPA routing
        if (req.url.indexOf('.') === -1) {
            fs.readFile(path.join(distPath, 'index.html'), (err, data) => {
                if (err) {
                    res.writeHead(404);
                    res.end('Not found');
                    return;
                }
                res.writeHead(200, { 'Content-Type': 'text/html' });
                res.end(data);
            });
        } else {
            res.writeHead(404);
            res.end('Not found');
        }
    });
});

server.listen(port, () => {
    console.log('🚀 Jarvis production server running on http://localhost:' + port);
    console.log('📊 Dashboard available at: http://localhost:' + port);
});
"@
            
            Set-Content -Path "dist/server.js" -Value $serverScript -Encoding UTF8
            Write-Success "Local deployment server created: dist/server.js"
            Write-Info "To start: node dist/server.js"
        }
        
        "docker" {
            Write-Info "Preparing for Docker deployment..."
            
            # Create Dockerfile
            $dockerfile = @"
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy built application
COPY dist/ ./dist/

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S jarvis -u 1001

# Change ownership
RUN chown -R jarvis:nodejs /app
USER jarvis

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "http.get('http://localhost:8080', (res) => process.exit(res.statusCode === 200 ? 0 : 1))"

CMD ["node", "dist/server.js"]
"@
            
            Set-Content -Path "Dockerfile" -Value $dockerfile -Encoding UTF8
            Write-Success "Dockerfile created"
            
            # Create .dockerignore
            $dockerignore = @"
node_modules
src
config
scripts
logs
tmp
.git
.gitignore
*.md
.env*
"@
            Set-Content -Path ".dockerignore" -Value $dockerignore -Encoding UTF8
            Write-Success "Docker configuration created"
        }
        
        default {
            Write-Warning "Unknown deployment target: $DeployTarget"
        }
    }
}

# Final summary
$totalDuration = (Get-Date) - $script:BuildStartTime
Write-Header "🎉 Production Build Complete!"

Write-Host ""
Write-Success "Build Summary:"
Write-Info "  Version: $($packageJson.version)"
Write-Info "  Build ID: $buildId"
Write-Info "  Environment: $Environment"
Write-Info "  Build Time: $($totalDuration.TotalMinutes.ToString('F1')) minutes"
Write-Info "  Build Size: $distSizeMB MB"
Write-Info "  Output Directory: dist/"

if ($script:Warnings.Count -gt 0) {
    Write-Host ""
    Write-Warning "Build Warnings ($($script:Warnings.Count)):"
    foreach ($warning in $script:Warnings) {
        Write-Host "  • $warning" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📦 Deployment Options:" -ForegroundColor Yellow
Write-Host "  Local: " -NoNewline -ForegroundColor White
Write-Host "node dist/server.js" -ForegroundColor Green
if (Test-Path "Dockerfile") {
    Write-Host "  Docker: " -NoNewline -ForegroundColor White
    Write-Host "docker build -t jarvis . && docker run -p 8080:8080 jarvis" -ForegroundColor Green
}
Write-Host "  Manual: Copy dist/ to your web server" -ForegroundColor White

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test the production build locally" -ForegroundColor White
Write-Host "  2. Review the deployment manifest: dist/manifest.json" -ForegroundColor White
Write-Host "  3. Deploy to your target environment" -ForegroundColor White

exit 0