# Jarvis Webpack Dashboard - Deployment Guide

## 🚀 Deployment Overview

This guide covers deploying Jarvis for production use across different environments and platforms.

---

## 📋 Pre-Deployment Checklist

- [ ] All tests pass: `./scripts/verify-installation.ps1 -FullTest`
- [ ] Production build succeeds: `./scripts/start-prod.ps1`
- [ ] Environment variables configured
- [ ] Security review completed
- [ ] Performance benchmarks met
- [ ] Backup and rollback plan ready

---

## 🏭 Production Build

### Automated Production Build

```powershell
# Complete production build with deployment prep
./scripts/start-prod.ps1 -Deploy -DeployTarget docker

# Custom environment
./scripts/start-prod.ps1 -Environment production -CleanBuild

# With security and performance checks
./scripts/start-prod.ps1 -Deploy -Verbose
```

### Manual Production Build

```powershell
# Set production environment
$env:NODE_ENV = "production"
$env:JARVIS_ENV = "production"

# Clean previous builds
Remove-Item dist -Recurse -Force -ErrorAction SilentlyContinue

# Build for production
npm run build

# Verify build
Test-Path dist/index.html
Test-Path dist/server
Test-Path dist/assets
```

---

## 🖥️ Local Server Deployment

### Option 1: Node.js Server

**Build and run:**
```powershell
# Build for production
./scripts/start-prod.ps1 -DeployTarget local

# Start the server
cd dist
node server.js
```

**Custom configuration:**
```javascript
// dist/server.js configuration
const port = process.env.PORT || 8080;
const host = process.env.HOST || '0.0.0.0';
```

**Environment variables:**
```powershell
$env:PORT = "8080"
$env:HOST = "0.0.0.0"
$env:NODE_ENV = "production"
```

### Option 2: Process Manager (PM2)

**Install PM2:**
```powershell
npm install -g pm2
```

**Create ecosystem file:**
```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'jarvis-dashboard',
    script: './dist/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 8080
    },
    log_file: './logs/combined.log',
    out_file: './logs/out.log',
    error_file: './logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm Z'
  }]
};
```

**Deploy with PM2:**
```powershell
# Start application
pm2 start ecosystem.config.js

# Monitor
pm2 monit

# View logs
pm2 logs jarvis-dashboard

# Restart
pm2 restart jarvis-dashboard
```

---

## 🐳 Docker Deployment

### Single Container Deployment

**Build image:**
```powershell
# Build production version with Docker support
./scripts/start-prod.ps1 -Deploy -DeployTarget docker

# Build Docker image
docker build -t jarvis-dashboard .

# Run container
docker run -d -p 8080:8080 --name jarvis-app jarvis-dashboard
```

**Custom Dockerfile:**
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy built application
COPY dist/ ./dist/

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S jarvis -u 1001

# Set ownership
RUN chown -R jarvis:nodejs /app
USER jarvis

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:8080', (res) => process.exit(res.statusCode === 200 ? 0 : 1))"

# Start application
CMD ["node", "dist/server.js"]
```

### Docker Compose Deployment

**Create docker-compose.yml:**
```yaml
version: '3.8'

services:
  jarvis:
    build: .
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - PORT=8080
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:8080', (res) => process.exit(res.statusCode === 200 ? 0 : 1))"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl
    depends_on:
      - jarvis
    restart: unless-stopped

volumes:
  logs:
```

**Deploy with Docker Compose:**
```powershell
# Start services
docker-compose up -d

# View logs
docker-compose logs -f jarvis

# Scale application
docker-compose up -d --scale jarvis=3

# Update deployment
docker-compose build && docker-compose up -d
```

---

## ☁️ Cloud Deployment

### AWS Deployment

#### Option 1: AWS EC2

**Prepare EC2 instance:**
```bash
# Install Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install PM2
sudo npm install -g pm2

# Clone and setup project
git clone <repository-url>
cd jarvis
./scripts/init-project.ps1
```

**Deploy to EC2:**
```bash
# Build for production
./scripts/start-prod.ps1 -Environment production

# Start with PM2
pm2 start ecosystem.config.js
pm2 startup
pm2 save
```

#### Option 2: AWS ECS (Docker)

**Create task definition:**
```json
{
  "family": "jarvis-dashboard",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "jarvis",
      "image": "your-repo/jarvis-dashboard:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/jarvis-dashboard",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### Azure Deployment

#### Azure Container Instances

```powershell
# Build and push image
docker build -t jarvis-dashboard .
docker tag jarvis-dashboard your-registry.azurecr.io/jarvis-dashboard
docker push your-registry.azurecr.io/jarvis-dashboard

# Deploy to ACI
az container create \
  --resource-group myResourceGroup \
  --name jarvis-dashboard \
  --image your-registry.azurecr.io/jarvis-dashboard \
  --cpu 1 \
  --memory 1 \
  --ports 8080 \
  --environment-variables NODE_ENV=production
```

### Google Cloud Platform

#### Cloud Run Deployment

```powershell
# Build and push to Container Registry
docker build -t gcr.io/your-project/jarvis-dashboard .
docker push gcr.io/your-project/jarvis-dashboard

# Deploy to Cloud Run
gcloud run deploy jarvis-dashboard \
  --image gcr.io/your-project/jarvis-dashboard \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --set-env-vars NODE_ENV=production
```

---

## 🌐 Static Site Deployment

### CDN Deployment (Netlify, Vercel, etc.)

**Build for static deployment:**
```powershell
# Build static version
$env:NODE_ENV = "production"
npm run build

# Optimize for static hosting
Copy-Item dist/index.html dist/_redirects
```

**_redirects file for SPA routing:**
```
/*    /index.html   200
```

**Deploy to Netlify:**
```powershell
# Install Netlify CLI
npm install -g netlify-cli

# Login and deploy
netlify login
netlify deploy --prod --dir=dist
```

**Deploy to Vercel:**
```powershell
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

---

## 🔒 Security Configuration

### Environment Variables

**Production environment variables:**
```powershell
# Required
$env:NODE_ENV = "production"
$env:PORT = "8080"

# Optional security
$env:JARVIS_SECURE = "true"
$env:JARVIS_CORS_ORIGIN = "https://yourdomain.com"
$env:JARVIS_SESSION_SECRET = "your-secret-key"
```

### HTTPS Configuration

**SSL with Nginx:**
```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Security Headers

**Add security middleware:**
```javascript
// In your server configuration
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  next();
});
```

---

## 📊 Monitoring & Logging

### Health Checks

**Automated health monitoring:**
```powershell
# Production health check
./scripts/health-check.ps1 -Url "https://yourdomain.com" -Continuous -LogToFile

# Set up monitoring cron job (Linux/macOS)
# */5 * * * * /path/to/scripts/health-check.ps1 -Url https://yourdomain.com
```

### Application Monitoring

**PM2 monitoring:**
```powershell
# Monitor with PM2
pm2 monit

# Web monitoring dashboard
pm2 install pm2-server-monit
```

**Docker monitoring:**
```powershell
# Container stats
docker stats jarvis-app

# Container logs
docker logs -f jarvis-app

# Health check
docker exec jarvis-app curl -f http://localhost:8080/health || exit 1
```

### Log Management

**Centralized logging:**
```javascript
// winston logger configuration
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' })
  ]
});
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Example

```yaml
name: Deploy Jarvis Dashboard

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '18'
        
    - name: Install dependencies
      run: npm install --legacy-peer-deps
      
    - name: Run tests
      run: ./scripts/verify-installation.ps1 -QuickTest
      
    - name: Build for production
      run: ./scripts/start-prod.ps1 -SkipTests
      
    - name: Build Docker image
      run: docker build -t jarvis-dashboard .
      
    - name: Deploy to production
      run: |
        # Add your deployment commands here
        echo "Deploying to production..."
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-repo/jarvis.git'
            }
        }
        
        stage('Install') {
            steps {
                powershell './scripts/init-project.ps1'
            }
        }
        
        stage('Test') {
            steps {
                powershell './scripts/verify-installation.ps1 -FullTest'
            }
        }
        
        stage('Build') {
            steps {
                powershell './scripts/start-prod.ps1 -Deploy'
            }
        }
        
        stage('Deploy') {
            steps {
                // Add deployment steps
                powershell 'docker build -t jarvis-dashboard .'
            }
        }
    }
}
```

---

## 🔧 Performance Optimization

### Production Optimizations

**Server optimizations:**
```javascript
// Enable gzip compression
app.use(compression());

// Set static file caching
app.use(express.static('dist', {
  maxAge: '1y',
  etag: false
}));

// Enable keep-alive
app.use((req, res, next) => {
  res.setHeader('Connection', 'keep-alive');
  next();
});
```

**CDN Configuration:**
```javascript
// Serve assets from CDN
const CDN_URL = process.env.CDN_URL || '';
app.locals.cdnUrl = CDN_URL;
```

### Load Balancing

**Nginx load balancer:**
```nginx
upstream jarvis_backend {
    server 127.0.0.1:8080;
    server 127.0.0.1:8081;
    server 127.0.0.1:8082;
}

server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://jarvis_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 📋 Deployment Checklist

### Pre-deployment

- [ ] All tests pass
- [ ] Security review completed
- [ ] Performance benchmarks met
- [ ] Environment variables configured
- [ ] SSL certificates ready
- [ ] Database migrations completed (if applicable)
- [ ] Backup procedures in place

### Deployment

- [ ] Production build successful
- [ ] Docker image built and tested
- [ ] Load balancer configured
- [ ] Monitoring setup
- [ ] Health checks enabled
- [ ] Rollback plan ready

### Post-deployment

- [ ] Application starts successfully
- [ ] Health checks passing
- [ ] Performance metrics normal
- [ ] Logs being generated
- [ ] Monitoring alerts configured
- [ ] Documentation updated

---

## 🆘 Rollback Procedures

### Quick Rollback

```powershell
# Stop current deployment
docker stop jarvis-app

# Rollback to previous version
docker run -d -p 8080:8080 --name jarvis-app jarvis-dashboard:previous

# Verify rollback
./scripts/health-check.ps1 -Url "https://yourdomain.com"
```

### Full Rollback

```powershell
# 1. Stop all services
pm2 stop jarvis-dashboard

# 2. Restore previous version
git checkout previous-release
./scripts/start-prod.ps1

# 3. Restart services
pm2 restart jarvis-dashboard

# 4. Verify
./scripts/verify-installation.ps1 -FullTest
```

---

**🎉 Your Jarvis dashboard is now ready for production deployment!**

For additional deployment support, check the [troubleshooting guide](TROUBLESHOOTING.md) or reach out through the project's support channels.