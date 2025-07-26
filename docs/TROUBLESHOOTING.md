# Jarvis Webpack Dashboard - Troubleshooting Guide

## 🔧 Quick Diagnostics

**First, run the automated diagnostics:**

```powershell
# System check
./scripts/check-dependencies.ps1 -Verbose

# Full verification
./scripts/verify-installation.ps1 -FullTest

# Health check
./scripts/health-check.ps1 -Verbose
```

---

## 🚨 Common Issues & Solutions

### 1. Server Won't Start

#### Issue: "Port 1337 is already in use"

**Symptoms:**
- Error when starting development server
- "EADDRINUSE" error message

**Solutions:**

```powershell
# Option 1: Use different port
./scripts/start-dev.ps1 -Port 3000

# Option 2: Find and kill the process
netstat -ano | findstr :1337
taskkill /PID <process-id> /F

# Option 3: Kill all Node.js processes
Get-Process node | Stop-Process -Force
```

#### Issue: "Cannot find module" errors

**Symptoms:**
- Import/require errors
- Missing dependency messages

**Solutions:**

```powershell
# Clean reinstall dependencies
Remove-Item node_modules -Recurse -Force
Remove-Item package-lock.json
npm install --legacy-peer-deps

# Or use the automated fix
./scripts/init-project.ps1 -Force
```

### 2. Build Failures

#### Issue: "Build failed with exit code 1"

**Symptoms:**
- Production build fails
- Webpack compilation errors

**Solutions:**

```powershell
# Check for detailed errors
npm run build -- --verbose

# Clean build
./scripts/start-prod.ps1 -CleanBuild

# Check disk space
Get-PSDrive C

# Clear npm cache
npm cache clean --force
```

#### Issue: "out of memory" errors

**Symptoms:**
- Build process crashes
- "JavaScript heap out of memory"

**Solutions:**

```powershell
# Increase Node.js memory limit
$env:NODE_OPTIONS = "--max-old-space-size=4096"
npm run build

# Or permanently set in environment
[System.Environment]::SetEnvironmentVariable("NODE_OPTIONS", "--max-old-space-size=4096", "User")
```

### 3. Permission Issues

#### Issue: "Access denied" or "Permission denied"

**Symptoms:**
- Script execution fails
- File access errors

**Solutions:**

```powershell
# Run PowerShell as Administrator
Start-Process powershell -Verb runAs

# Change execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Fix file permissions
icacls . /grant Everyone:F /T
```

### 4. Network Issues

#### Issue: "npm install fails" or "Registry timeout"

**Symptoms:**
- Package installation fails
- Network timeouts

**Solutions:**

```powershell
# Check internet connectivity
Test-NetConnection registry.npmjs.org -Port 443

# Use different registry
npm config set registry https://registry.npmjs.org/

# Clear npm cache
npm cache clean --force

# Retry with longer timeout
npm install --timeout=300000 --legacy-peer-deps
```

### 5. Browser Issues

#### Issue: "Page not loading" or "Connection refused"

**Symptoms:**
- Browser shows connection errors
- Blank page in browser

**Solutions:**

```powershell
# Check if server is running
./scripts/health-check.ps1

# Verify port accessibility
Test-NetConnection localhost -Port 1337

# Check firewall settings
New-NetFirewallRule -DisplayName "Jarvis Dev Server" -Direction Inbound -Port 1337 -Protocol TCP -Action Allow

# Try different browser
Start-Process "http://localhost:1337"
```

---

## 🔍 Diagnostic Commands

### System Diagnostics

```powershell
# Check Node.js and npm versions
node --version
npm --version

# Check available memory
Get-ComputerInfo | Select-Object TotalPhysicalMemory

# Check disk space
Get-PSDrive

# Check PowerShell version
$PSVersionTable
```

### Project Diagnostics

```powershell
# Verify project structure
Get-ChildItem -Recurse -Directory | Select-Object Name

# Check package.json validity
Get-Content package.json | ConvertFrom-Json

# List installed packages
npm list --depth=0

# Check for outdated packages
npm outdated
```

### Network Diagnostics

```powershell
# Test npm registry
Test-NetConnection registry.npmjs.org -Port 443

# Check local server
Test-NetConnection localhost -Port 1337

# View network connections
netstat -an | findstr :1337
```

### Performance Diagnostics

```powershell
# Check CPU usage
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# Check memory usage by Node.js
Get-Process node | Select-Object Id, ProcessName, WorkingSet

# Monitor build performance
Measure-Command { npm run build }
```

---

## 📊 Log Analysis

### Log Locations

| Log Type | Location | Purpose |
|----------|----------|---------|
| Development | `logs/dev-output.log` | Development server output |
| Errors | `logs/dev-error.log` | Development server errors |
| Health Checks | `logs/health-check.log` | Health monitoring |
| Build | `logs/build-*.log` | Production build output |
| Verification | `logs/verification-*.json` | Installation tests |

### Reading Logs

```powershell
# View recent log entries
Get-Content logs/dev-output.log -Tail 50

# Search for errors
Select-String "ERROR" logs/*.log

# Monitor logs in real-time
Get-Content logs/dev-output.log -Wait

# Filter by timestamp
Get-Content logs/health-check.log | Where-Object { $_ -match "2024-" }
```

### Common Log Patterns

#### Success Patterns
```
✅ Server started successfully
✅ Build completed in X seconds
✅ All health checks passed
```

#### Warning Patterns
```
⚠️ High memory usage detected
⚠️ Slow response time: X ms
⚠️ Deprecated dependency found
```

#### Error Patterns
```
❌ Failed to start server
❌ Build failed with exit code 1
❌ Cannot connect to localhost:1337
```

---

## 🛠️ Advanced Troubleshooting

### Performance Issues

#### Slow Build Times

**Diagnosis:**
```powershell
# Profile build performance
npm run build -- --profile --json > build-stats.json

# Analyze bundle
npx webpack-bundle-analyzer build-stats.json
```

**Solutions:**
- Enable webpack caching
- Exclude `node_modules` from source maps
- Use parallel processing
- Increase Node.js memory limit

#### High Memory Usage

**Diagnosis:**
```powershell
# Monitor memory during build
while ($true) { 
    Get-Process node | Select-Object WorkingSet; 
    Start-Sleep 5 
}
```

**Solutions:**
```powershell
# Increase swap file size
# Optimize webpack configuration
# Use webpack-dev-server instead of webpack --watch
```

### Configuration Issues

#### Webpack Configuration Problems

**Diagnosis:**
```powershell
# Validate webpack config
npx webpack --config config/webpack.js --validate

# Test config without building
npx webpack --config config/webpack.js --dry-run
```

**Solutions:**
- Check for syntax errors in config files
- Verify all required plugins are installed
- Ensure environment variables are set correctly

#### Environment Variable Issues

**Diagnosis:**
```powershell
# List all environment variables
Get-ChildItem Env: | Where-Object Name -like "*JARVIS*"

# Check specific variables
echo $env:NODE_ENV
echo $env:JARVIS_PORT
```

**Solutions:**
```powershell
# Set environment variables
$env:NODE_ENV = "development"
$env:JARVIS_PORT = "1337"

# Persist environment variables
[System.Environment]::SetEnvironmentVariable("NODE_ENV", "development", "User")
```

---

## 🔄 Recovery Procedures

### Complete Reset

When all else fails, perform a complete reset:

```powershell
# 1. Stop all processes
Get-Process node | Stop-Process -Force
Get-Process npm | Stop-Process -Force

# 2. Clean all build artifacts
Remove-Item dist -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item node_modules -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item package-lock.json -ErrorAction SilentlyContinue
Remove-Item logs/*.log -ErrorAction SilentlyContinue

# 3. Clear caches
npm cache clean --force

# 4. Reinstall everything
./scripts/init-project.ps1 -Force

# 5. Verify installation
./scripts/verify-installation.ps1 -FullTest
```

### Backup & Restore

#### Create Backup

```powershell
# Backup critical files
$backupPath = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory $backupPath
Copy-Item package.json, package-lock.json, .env -Destination $backupPath
Copy-Item config, src -Recurse -Destination $backupPath
```

#### Restore from Backup

```powershell
# Restore from backup
$backupPath = "backup-20240126-143000"  # Use your backup folder
Copy-Item "$backupPath/*" -Recurse -Destination . -Force
npm install --legacy-peer-deps
```

---

## 🆘 Getting Help

### Before Asking for Help

1. **Run diagnostics** and collect output:
   ```powershell
   ./scripts/verify-installation.ps1 -FullTest -Verbose > diagnostics.txt
   ```

2. **Check logs** for error messages:
   ```powershell
   Get-Content logs/*.log | Select-String "ERROR|FAIL"
   ```

3. **Gather system information**:
   ```powershell
   Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion
   node --version
   npm --version
   ```

### Information to Include

When reporting issues, include:

- **System Information** (OS, Node.js version, npm version)
- **Error Messages** (exact error text and stack traces)
- **Steps to Reproduce** (what you were trying to do)
- **Log Output** (relevant log entries)
- **Configuration** (any custom settings)

### Support Channels

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/zouhir/jarvis/issues)
- 💬 **Questions**: [GitHub Discussions](https://github.com/zouhir/jarvis/discussions)
- 📚 **Documentation**: [Project Wiki](https://github.com/zouhir/jarvis/wiki)

---

## 📋 Troubleshooting Checklist

### Before Starting Development

- [ ] System requirements met (Node.js >= 14, npm >= 6)
- [ ] All dependencies installed (`npm install` completed)
- [ ] Critical files present (src/, config/, package.json)
- [ ] Port 1337 available (or alternative configured)
- [ ] Sufficient disk space (> 1GB free)
- [ ] Network connectivity (npm registry accessible)

### When Issues Occur

- [ ] Check logs in `logs/` directory
- [ ] Run health check: `./scripts/health-check.ps1`
- [ ] Verify dependencies: `./scripts/check-dependencies.ps1`
- [ ] Check system resources (memory, disk space)
- [ ] Try different port: `./scripts/start-dev.ps1 -Port 3000`
- [ ] Clear cache and reinstall: `./scripts/init-project.ps1 -Force`
- [ ] Check firewall/antivirus settings

### Performance Issues

- [ ] Monitor memory usage during builds
- [ ] Check for long-running processes
- [ ] Verify SSD storage being used
- [ ] Increase Node.js memory limit
- [ ] Close unnecessary applications
- [ ] Check for background scans (antivirus)

---

**💡 Remember: Most issues can be resolved by running `./scripts/init-project.ps1 -Force` to reset the project to a clean state.**

For persistent issues, gather diagnostic information and reach out through the support channels listed above.