#!/usr/bin/env pwsh
# Jarvis System Dependency Check Script
# Compatible with Windows, Linux, and macOS

param(
    [switch]$Verbose,
    [switch]$Fix
)

$ErrorActionPreference = "Continue"
$script:FailedChecks = @()
$script:Warnings = @()

# Color output functions
function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor Green
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor Red
    $script:FailedChecks += $message
}

function Write-Warning($message) {
    Write-Host "⚠️  $message" -ForegroundColor Yellow
    $script:Warnings += $message
}

function Write-Info($message) {
    Write-Host "ℹ️  $message" -ForegroundColor Cyan
}

function Write-Header($message) {
    Write-Host "`n🔍 $message" -ForegroundColor Magenta
    Write-Host ("=" * ($message.Length + 4)) -ForegroundColor Magenta
}

# System Information
Write-Header "System Information"
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $os = "Windows"
    Write-Info "Operating System: Windows"
} elseif ($IsLinux) {
    $os = "Linux"
    Write-Info "Operating System: Linux"
} elseif ($IsMacOS) {
    $os = "macOS"
    Write-Info "Operating System: macOS"
} else {
    $os = "Unknown"
    Write-Warning "Operating System: Unknown"
}

# Check Node.js
Write-Header "Checking Node.js"
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        $nodeVersionNumber = $nodeVersion -replace 'v', ''
        $majorVersion = [int]($nodeVersionNumber -split '\.')[0]
        
        if ($majorVersion -ge 14) {
            Write-Success "Node.js version: $nodeVersion (✓ >= v14.0.0)"
        } else {
            Write-Error "Node.js version: $nodeVersion (✗ < v14.0.0 required)"
        }
    } else {
        Write-Error "Node.js not found or not in PATH"
    }
} catch {
    Write-Error "Failed to check Node.js version: $($_.Exception.Message)"
}

# Check npm
Write-Header "Checking npm"
try {
    $npmVersion = npm --version 2>$null
    if ($npmVersion) {
        Write-Success "npm version: v$npmVersion"
    } else {
        Write-Error "npm not found or not in PATH"
    }
} catch {
    Write-Error "Failed to check npm version: $($_.Exception.Message)"
}

# Check Git
Write-Header "Checking Git"
try {
    $gitVersion = git --version 2>$null
    if ($gitVersion) {
        Write-Success "$gitVersion"
    } else {
        Write-Warning "Git not found - optional for development"
    }
} catch {
    Write-Warning "Git not available - optional for development"
}

# Check PowerShell/Shell
Write-Header "Checking Shell Environment"
if ($PSVersionTable.PSVersion) {
    Write-Success "PowerShell version: $($PSVersionTable.PSVersion)"
} else {
    Write-Info "Shell: $($env:SHELL -split '/')[-1]"
}

# Check project directory and package.json
Write-Header "Checking Project Structure"
if (Test-Path "package.json") {
    Write-Success "package.json found"
    
    try {
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        Write-Success "Project: $($packageJson.name) v$($packageJson.version)"
        
        if ($packageJson.engines.node) {
            Write-Info "Required Node.js: $($packageJson.engines.node)"
        }
    } catch {
        Write-Error "Failed to parse package.json: $($_.Exception.Message)"
    }
} else {
    Write-Error "package.json not found in current directory"
}

# Check for node_modules
if (Test-Path "node_modules") {
    Write-Success "node_modules directory exists"
} else {
    Write-Warning "node_modules not found - run 'npm install' to install dependencies"
}

# Check critical project files
$criticalFiles = @(
    "src/server/index.js",
    "src/client/index.js",
    "config/webpack.js",
    "config/babel.js"
)

Write-Header "Checking Critical Project Files"
foreach ($file in $criticalFiles) {
    if (Test-Path $file) {
        Write-Success "$file exists"
    } else {
        Write-Error "$file missing"
    }
}

# Check network ports
Write-Header "Checking Port Availability"
$defaultPort = 1337
try {
    if ($os -eq "Windows") {
        $portCheck = netstat -an | Select-String ":$defaultPort "
    } else {
        $portCheck = netstat -an 2>/dev/null | grep ":$defaultPort "
    }
    
    if ($portCheck) {
        Write-Warning "Port $defaultPort appears to be in use"
        Write-Info "You may need to specify a different port or stop the running service"
    } else {
        Write-Success "Port $defaultPort is available"
    }
} catch {
    Write-Warning "Could not check port availability"
}

# Performance and resource checks
Write-Header "System Resources"
try {
    if ($os -eq "Windows") {
        $memory = Get-CimInstance Win32_OperatingSystem | Select-Object @{Name="TotalMemoryGB";Expression={[math]::Round($_.TotalVisibleMemorySize/1MB,2)}}
        Write-Info "Total Memory: $($memory.TotalMemoryGB) GB"
    } else {
        Write-Info "Memory check not implemented for this platform"
    }
} catch {
    Write-Warning "Could not check system memory"
}

# Check internet connectivity for npm
Write-Header "Checking Internet Connectivity"
try {
    $testConnection = Test-NetConnection registry.npmjs.org -Port 443 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($testConnection.TcpTestSucceeded) {
        Write-Success "npm registry accessible"
    } else {
        Write-Warning "npm registry may not be accessible"
    }
} catch {
    # Fallback for non-Windows systems or older PowerShell
    try {
        if (Get-Command curl -ErrorAction SilentlyContinue) {
            $curlResult = curl -s --connect-timeout 5 https://registry.npmjs.org/ 2>$null
            if ($curlResult) {
                Write-Success "npm registry accessible"
            } else {
                Write-Warning "npm registry may not be accessible"
            }
        } else {
            Write-Info "Could not test npm registry connectivity"
        }
    } catch {
        Write-Info "Could not test npm registry connectivity"
    }
}

# Auto-fix suggestions
if ($Fix -and $script:FailedChecks.Count -gt 0) {
    Write-Header "Auto-Fix Attempts"
    
    if ($script:FailedChecks -like "*node_modules not found*") {
        Write-Info "Attempting to install dependencies..."
        try {
            npm install --legacy-peer-deps
            Write-Success "Dependencies installed successfully"
        } catch {
            Write-Error "Failed to install dependencies: $($_.Exception.Message)"
        }
    }
}

# Summary
Write-Header "Summary"
if ($script:FailedChecks.Count -eq 0) {
    Write-Success "All dependency checks passed! ✨"
    Write-Info "You can now run: npm run watch"
} else {
    Write-Error "Found $($script:FailedChecks.Count) critical issues:"
    foreach ($issue in $script:FailedChecks) {
        Write-Host "  • $issue" -ForegroundColor Red
    }
    
    Write-Host "`n📋 Recommended Actions:" -ForegroundColor Yellow
    Write-Host "  1. Install missing dependencies" -ForegroundColor White
    Write-Host "  2. Run: ./scripts/check-dependencies.ps1 -Fix" -ForegroundColor White
    Write-Host "  3. Check the setup guide: ./docs/SETUP.md" -ForegroundColor White
}

if ($script:Warnings.Count -gt 0) {
    Write-Host "`n⚠️  Warnings ($($script:Warnings.Count)):" -ForegroundColor Yellow
    foreach ($warning in $script:Warnings) {
        Write-Host "  • $warning" -ForegroundColor Yellow
    }
}

# Return appropriate exit code
if ($script:FailedChecks.Count -gt 0) {
    exit 1
} else {
    exit 0
}