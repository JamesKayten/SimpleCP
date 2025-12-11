# SimpleCP Deployment Guide

Complete guide to deploying SimpleCP in production environments.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deployment Methods](#deployment-methods)
- [Production Configuration](#production-configuration)
- [Security Hardening](#security-hardening)
- [Monitoring Setup](#monitoring-setup)
- [Backup & Recovery](#backup--recovery)
- [Update Procedures](#update-procedures)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting](#troubleshooting)

---

## Overview

SimpleCP can be deployed in several configurations:

- **Single User**: Local daemon on macOS
- **Team/Office**: Centralized server with multiple clients
- **Development**: Local testing environment

This guide covers production-ready deployment practices.

---

## Prerequisites

### System Requirements

**Minimum**:
- macOS 10.14 or later
- Python 3.9+
- 50MB RAM
- 10MB disk space

**Recommended**:
- macOS 12.0 or later
- Python 3.11+
- 100MB RAM
- 100MB disk space (for logs and data)

### Dependencies

```bash
# Python 3.9+
python3 --version

# pip (latest)
pip3 --version

# Git (for installation from source)
git --version
```

---

## Deployment Methods

### Method 1: Release Package (Recommended)

**For end users and production deployments**

```bash
# Download latest release
curl -L https://github.com/JamesKayten/SimpleCP/releases/latest/download/simplecp-1.0.0.tar.gz -o simplecp.tar.gz

# Verify checksum
curl -L https://github.com/JamesKayten/SimpleCP/releases/latest/download/simplecp-1.0.0.tar.gz.sha256 -o simplecp.tar.gz.sha256
shasum -a 256 -c simplecp.tar.gz.sha256

# Extract
tar -xzf simplecp.tar.gz
cd simplecp-1.0.0

# Install
pip3 install -r requirements.txt

# Configure
cp .env.example .env
# Edit .env as needed

# Run
python3 daemon.py
```

---

### Method 2: From Source

**For development or customization**

```bash
# Clone repository
git clone https://github.com/JamesKayten/SimpleCP.git
cd SimpleCP

# Checkout stable release
git checkout v1.0.0

# Create virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure
cp .env.example .env
# Edit .env

# Run
python daemon.py
```

---

### Method 3: pip Install (Future)

**Once published to PyPI**

```bash
# Install from PyPI
pip install simplecp

# Run
simplecp-daemon
```

---

## Production Configuration

### Environment Configuration

Create `.env` file with production settings:

```env
# Application
ENVIRONMENT=production
APP_VERSION=1.0.0

# API Server
API_HOST=127.0.0.1  # localhost only for security
API_PORT=49917

# Clipboard
MAX_HISTORY_ITEMS=50
CLIPBOARD_CHECK_INTERVAL=1

# Logging
LOG_LEVEL=INFO
LOG_TO_FILE=true
LOG_FILE_PATH=./logs/simplecp.log
LOG_JSON_FORMAT=true  # Structured logs for production
LOG_MAX_BYTES=10485760  # 10MB
LOG_BACKUP_COUNT=5

# Monitoring
ENABLE_SENTRY=true
SENTRY_DSN=your-production-sentry-dsn
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=0.1  # 10% sampling

# Performance
ENABLE_PERFORMANCE_TRACKING=true
ENABLE_USAGE_ANALYTICS=true

# CORS (if allowing remote access)
CORS_ORIGINS=https://yourdomain.com
```

### Directory Structure

```
/opt/simplecp/               # Installation directory
├── venv/                    # Virtual environment
├── data/                    # Application data
│   ├── history.json
│   └── snippets.json
├── logs/                    # Log files
│   ├── simplecp.log
│   └── simplecp.log.*       # Rotated logs
├── backups/                 # Backup directory
└── .env                     # Production config
```

### File Permissions

```bash
# Set ownership
chown -R $USER:staff /opt/simplecp

# Set permissions
chmod 755 /opt/simplecp
chmod 644 /opt/simplecp/.env
chmod 700 /opt/simplecp/data
chmod 755 /opt/simplecp/logs
chmod 700 /opt/simplecp/backups
```

---

## Security Hardening

### 1. Network Security

**Firewall Rules**:
```bash
# Only allow localhost connections (default)
API_HOST=127.0.0.1

# Or use firewall
sudo pfctl -e
# Add rule to allow only localhost
```

**API Security**:
- Keep `API_HOST=127.0.0.1` for localhost only
- Use reverse proxy (nginx) if exposing externally
- Implement API authentication for remote access

### 2. Data Security

**Sensitive Data**:
```bash
# Never store in clipboard history:
# - Passwords
# - API keys
# - Private keys
# - Credit card numbers

# Use .gitignore for sensitive files
echo ".env" >> .gitignore
echo "data/*.json" >> .gitignore
```

**File Encryption** (optional):
```bash
# Encrypt data directory
# macOS FileVault recommended
```

### 3. Secrets Management

**Environment Variables**:
```bash
# Never commit .env to git
# Use different .env for each environment
# Store Sentry DSN securely
```

**Sentry DSN Protection**:
```env
# Use environment-specific DSNs
SENTRY_DSN_DEVELOPMENT=https://dev@sentry.io/123
SENTRY_DSN_PRODUCTION=https://prod@sentry.io/456
```

### 4. Access Control

**File Permissions**:
```bash
# Restrict access to data
chmod 700 data/
chmod 600 data/*.json

# Restrict config access
chmod 600 .env
```

---

## Monitoring Setup

### 1. Sentry Configuration

```bash
# Sign up at sentry.io
# Create project
# Copy DSN to .env

ENABLE_SENTRY=true
SENTRY_DSN=https://your-dsn@sentry.io/project-id
SENTRY_ENVIRONMENT=production
```

### 2. Health Monitoring

**Health Check Endpoint**:
```bash
# Monitor with cron
*/5 * * * * curl -sf http://localhost:49917/health || /path/to/alert.sh
```

**Health Check Script** (`/usr/local/bin/simplecp-healthcheck`):
```bash
#!/bin/bash
HEALTH=$(curl -s http://localhost:49917/health | jq -r '.status')
if [ "$HEALTH" != "healthy" ]; then
    echo "SimpleCP unhealthy!" | mail -s "SimpleCP Alert" admin@example.com
    # Or send to Slack/Discord/etc
fi
```

### 3. Log Monitoring

**Automated Log Analysis**:
```bash
# Daily error report
0 9 * * * grep ERROR /opt/simplecp/logs/simplecp.log | mail -s "SimpleCP Errors" admin@example.com
```

**Log Aggregation** (optional):
- Ship logs to ELK Stack
- Use Splunk
- Send to CloudWatch

---

## Backup & Recovery

### Automated Backups

**Backup Script** (`/usr/local/bin/simplecp-backup`):
```bash
#!/bin/bash
BACKUP_DIR="/opt/simplecp/backups"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/simplecp-backup-${DATE}.tar.gz"

# Create backup
tar -czf "${BACKUP_FILE}" \
    /opt/simplecp/data/ \
    /opt/simplecp/.env

# Keep only last 30 days
find "${BACKUP_DIR}" -name "simplecp-backup-*.tar.gz" -mtime +30 -delete

echo "Backup created: ${BACKUP_FILE}"
```

**Cron Schedule**:
```bash
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/simplecp-backup

# Weekly backup to external storage
0 3 * * 0 rsync -av /opt/simplecp/backups/ /Volumes/External/simplecp-backups/
```

### Recovery Procedures

**Restore from Backup**:
```bash
# Stop daemon
pkill -f daemon.py

# Restore data
cd /opt/simplecp
tar -xzf backups/simplecp-backup-YYYYMMDD-HHMMSS.tar.gz --strip-components=3

# Verify
ls -la data/

# Restart daemon
python3 daemon.py &
```

**Disaster Recovery**:
```bash
# 1. Reinstall SimpleCP
# 2. Restore from backup
# 3. Verify configuration
# 4. Test functionality
# 5. Monitor for issues
```

---

## Update Procedures

### Check for Updates

```bash
# Manual check
python3 version.py

# Or via API
curl http://localhost:49917/api/version
```

### Update Process

**1. Preparation**:
```bash
# Backup current installation
/usr/local/bin/simplecp-backup

# Note current version
python3 -c "from version import __version__; print(__version__)"
```

**2. Download New Version**:
```bash
# Download latest release
VERSION="1.1.0"
curl -L https://github.com/JamesKayten/SimpleCP/releases/download/v${VERSION}/simplecp-${VERSION}.tar.gz -o simplecp-new.tar.gz

# Verify checksum
curl -L https://github.com/JamesKayten/SimpleCP/releases/download/v${VERSION}/simplecp-${VERSION}.tar.gz.sha256 -o simplecp-new.tar.gz.sha256
shasum -a 256 -c simplecp-new.tar.gz.sha256
```

**3. Update**:
```bash
# Stop daemon
pkill -f daemon.py

# Backup data
cp -r data/ data.backup

# Extract new version
tar -xzf simplecp-new.tar.gz
cd simplecp-${VERSION}

# Install new dependencies
pip3 install -r requirements.txt

# Copy data back
cp -r ../data/ .

# Copy config (merge changes)
cp ../.env .

# Test
python3 daemon.py --help

# Run
python3 daemon.py &
```

**4. Verification**:
```bash
# Check version
curl http://localhost:49917/ | jq '.version'

# Check health
curl http://localhost:49917/health

# Check logs
tail -f logs/simplecp.log
```

### Automated Updates (Optional)

```bash
# Update script
#!/bin/bash
# /usr/local/bin/simplecp-update

# Check for updates
CURRENT=$(python3 -c "from version import __version__; print(__version__)")
LATEST=$(curl -s https://api.github.com/repos/JamesKayten/SimpleCP/releases/latest | jq -r '.tag_name' | sed 's/v//')

if [ "$CURRENT" != "$LATEST" ]; then
    echo "Update available: $CURRENT -> $LATEST"
    # Send notification
    echo "SimpleCP update available" | mail -s "Update Available" admin@example.com
else
    echo "Up to date: $CURRENT"
fi
```

---

## Rollback Procedures

### When to Rollback

- New version has critical bugs
- Performance degradation
- Data corruption
- Compatibility issues

### Rollback Steps

**1. Stop Current Version**:
```bash
pkill -f daemon.py
```

**2. Restore Previous Version**:
```bash
# If you kept previous directory
cd /opt/simplecp-1.0.0

# Or restore from backup
tar -xzf backups/simplecp-backup-before-update.tar.gz
```

**3. Restore Data**:
```bash
# Restore data from before update
cp -r data.backup/* data/
```

**4. Restart**:
```bash
python3 daemon.py &
```

**5. Verify**:
```bash
# Check version
curl http://localhost:49917/ | jq '.version'

# Check data integrity
curl http://localhost:49917/api/stats
```

**6. Report Issue**:
- Create GitHub issue with details
- Include logs
- Describe problem
- Note steps to reproduce

---

## Troubleshooting

### Deployment Issues

**Port Already in Use**:
```bash
# Find process
lsof -i :49917

# Kill process
kill -9 <PID>

# Or change port in .env
API_PORT=8001
```

**Permission Denied**:
```bash
# Fix permissions
chmod 755 /opt/simplecp
chmod -R 644 /opt/simplecp/data

# Or run as specific user
sudo -u simplecp python3 daemon.py
```

**Dependencies Not Found**:
```bash
# Reinstall
pip3 install --force-reinstall -r requirements.txt

# Or use virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Runtime Issues

**High Memory Usage**:
```bash
# Reduce history limit in .env
MAX_HISTORY_ITEMS=25

# Restart daemon
```

**Slow Performance**:
```bash
# Increase check interval
CLIPBOARD_CHECK_INTERVAL=2

# Disable analytics if not needed
ENABLE_USAGE_ANALYTICS=false
```

**Data Corruption**:
```bash
# Restore from backup
cp backups/latest/data/* data/

# Or reset
rm data/*.json
# Daemon will recreate on startup
```

For more issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Production Checklist

Before going to production:

- [ ] Configuration reviewed and set to production
- [ ] Sentry configured and tested
- [ ] Logs configured with rotation
- [ ] Backup script created and tested
- [ ] Health monitoring configured
- [ ] Security hardening applied
- [ ] Documentation reviewed
- [ ] Team trained on procedures
- [ ] Rollback procedure tested
- [ ] Monitoring dashboards set up
- [ ] Alert recipients configured
- [ ] Incident response plan created

---

## Support

- **Documentation**: [docs/](.)
- **Issues**: [GitHub Issues](https://github.com/JamesKayten/SimpleCP/issues)
- **Email**: support@simplecp.app
- **Emergency**: Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Production deployment complete! 🚀**
