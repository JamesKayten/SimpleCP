# SimpleCP Troubleshooting Guide

Solutions to common issues and problems.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Startup Problems](#startup-problems)
- [Clipboard Monitoring Issues](#clipboard-monitoring-issues)
- [Performance Issues](#performance-issues)
- [Data & Storage Issues](#data--storage-issues)
- [API Server Issues](#api-server-issues)
- [Menu Bar Issues](#menu-bar-issues)
- [Common Error Messages](#common-error-messages)
- [Diagnostic Tools](#diagnostic-tools)
- [Getting Help](#getting-help)

---

## Installation Issues

### Python Version Errors

**Problem**: `python: command not found` or `Python 3.9+ required`

**Solution**:
```bash
# Check Python version
python3 --version

# If not installed, install via Homebrew
brew install python@3.11

# Verify installation
python3 --version
```

---

### Dependency Installation Failures

**Problem**: `pip install -r requirements.txt` fails

**Solutions**:

1. **Upgrade pip**:
```bash
python3 -m pip install --upgrade pip
```

2. **Use virtual environment**:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

3. **Install dependencies individually**:
```bash
pip install pyperclip
pip install fastapi uvicorn
pip install pydantic pydantic-settings
```

4. **macOS ARM (M1/M2) issues**:
```bash
# Use Rosetta if needed
arch -x86_64 pip install -r requirements.txt
```

---

### Permission Denied Errors

**Problem**: `Permission denied` when installing or running

**Solution**:
```bash
# Don't use sudo with pip
pip install --user -r requirements.txt

# Or use virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

---

## Startup Problems

### Daemon Won't Start

**Problem**: `python daemon.py` exits immediately

**Diagnostic Steps**:

1. **Check for errors**:
```bash
python daemon.py 2>&1 | tee startup.log
```

2. **Check if port is in use**:
```bash
lsof -i :8000
# If occupied, kill process or change port
```

3. **Check logs**:
```bash
tail -f logs/simplecp.log
```

**Common Causes**:
- Port 8000 already in use → Change `API_PORT` in `.env`
- Missing dependencies → Run `pip install -r requirements.txt`
- Permission issues → Check file permissions
- Data directory not writable → Check `~/Library/Application Support/SimpleCP/`

---

### "Address Already in Use" Error

**Problem**: `[Errno 48] Address already in use`

**Solution**:

1. **Find process using port 8000**:
```bash
lsof -i :8000
```

2. **Kill the process**:
```bash
kill -9 <PID>
```

3. **Or change port in `.env`**:
```env
API_PORT=8001
```

---

### Daemon Crashes on Startup

**Problem**: Daemon starts then crashes immediately

**Check**:

1. **Python version**:
```bash
python3 --version  # Must be 3.9+
```

2. **Dependencies**:
```bash
pip list | grep -E "(fastapi|uvicorn|pydantic|pyperclip)"
```

3. **Data directory**:
```bash
ls -la ~/Library/Application\ Support/SimpleCP/
# Should exist and be writable
```

4. **Logs**:
```bash
cat logs/simplecp.log
```

---

## Clipboard Monitoring Issues

### Clipboard Not Being Monitored

**Problem**: New clipboard items not appearing in history

**Check**:

1. **Accessibility Permissions**:
   - System Preferences → Security & Privacy → Privacy → Accessibility
   - Ensure Terminal (or your terminal app) is checked
   - Or ensure SimpleCP is checked if using app bundle

2. **Daemon is running**:
```bash
# Check if process is running
ps aux | grep daemon.py

# Check API health
curl http://localhost:8000/health
```

3. **Check interval setting**:
```bash
# In .env file
CLIPBOARD_CHECK_INTERVAL=1  # Should be 1 second
```

**Restart daemon**:
```bash
pkill -f daemon.py
python daemon.py
```

---

### Duplicate Items in History

**Problem**: Same item appears multiple times

**Cause**: Clipboard check interval too fast or app copying multiple times

**Solution**:
```bash
# Increase check interval in .env
CLIPBOARD_CHECK_INTERVAL=2  # 2 seconds instead of 1
```

---

### Some Apps Not Monitored

**Problem**: Clipboard items from certain apps don't appear

**Possible Causes**:
- App uses custom clipboard format (not plain text)
- App has clipboard protection
- App running in sandbox mode

**Solution**:
- SimpleCP currently only monitors plain text
- Images, files, and rich media not yet supported
- Password managers intentionally excluded for security

---

## Performance Issues

### High CPU Usage

**Problem**: SimpleCP using excessive CPU

**Diagnostic**:
```bash
# Check CPU usage
top | grep python

# Check log for errors
tail -f logs/simplecp.log
```

**Solutions**:

1. **Increase check interval**:
```env
CLIPBOARD_CHECK_INTERVAL=2  # Instead of 1 second
```

2. **Reduce history limit**:
```env
MAX_HISTORY_ITEMS=25  # Instead of 50
```

3. **Disable performance tracking**:
```env
ENABLE_PERFORMANCE_TRACKING=false
```

---

### High Memory Usage

**Problem**: Memory usage growing over time

**Check current usage**:
```bash
ps aux | grep daemon.py
```

**Solutions**:

1. **Reduce history size**:
```env
MAX_HISTORY_ITEMS=25
```

2. **Clear old data**:
```bash
curl -X DELETE http://localhost:8000/api/history
```

3. **Restart daemon periodically**:
```bash
# Create cron job to restart daily
0 3 * * * pkill -f daemon.py && python /path/to/daemon.py &
```

---

### Slow API Responses

**Problem**: API requests taking too long

**Diagnostic**:
```bash
# Check response time
time curl http://localhost:8000/api/history

# Check if server is under load
curl http://localhost:8000/health
```

**Solutions**:

1. **Reduce data size**:
   - Clear old history
   - Remove unused snippets
   - Reduce `MAX_HISTORY_ITEMS`

2. **Check for errors**:
```bash
tail logs/simplecp.log
```

3. **Restart daemon**:
```bash
pkill -f daemon.py
python daemon.py
```

---

## Data & Storage Issues

### Lost Clipboard History

**Problem**: History disappeared after restart

**Recovery**:

1. **Check data files**:
```bash
ls -la ~/Library/Application\ Support/SimpleCP/data/
cat ~/Library/Application\ Support/SimpleCP/data/history.json
```

2. **Restore from backup** (if available):
```bash
cp ~/Backups/SimpleCP/data/history.json \
   ~/Library/Application\ Support/SimpleCP/data/
```

3. **Check file permissions**:
```bash
chmod 644 ~/Library/Application\ Support/SimpleCP/data/*.json
```

**Prevention**:
- Regular backups
- Check logs for save errors
- Don't force quit daemon

---

### Data Corruption

**Problem**: `Error loading stores` in logs

**Solution**:

1. **Backup current data**:
```bash
cp ~/Library/Application\ Support/SimpleCP/data/history.json \
   ~/Library/Application\ Support/SimpleCP/data/history.json.backup
```

2. **Validate JSON**:
```bash
python3 -m json.tool data/history.json
```

3. **Reset if corrupted**:
```bash
# Creates fresh empty files
rm data/*.json
python daemon.py
```

---

### Disk Space Issues

**Problem**: Running out of disk space

**Check usage**:
```bash
du -sh ~/Library/Application\ Support/SimpleCP/
du -sh logs/
```

**Clean up**:
```bash
# Clear old logs
rm logs/simplecp.log.*

# Reduce history
curl -X DELETE http://localhost:8000/api/history

# Remove old backups
```

---

## API Server Issues

### API Not Responding

**Problem**: `curl: (7) Failed to connect to localhost port 8000`

**Check**:

1. **Server is running**:
```bash
lsof -i :8000
```

2. **Health check**:
```bash
curl http://localhost:8000/health
```

3. **Logs**:
```bash
tail -f logs/simplecp.log
```

**Solutions**:
- Restart daemon
- Check firewall settings
- Verify port in `.env` matches request

---

### CORS Errors

**Problem**: Browser requests blocked by CORS

**Solution**:

Add origins to `.env`:
```env
CORS_ORIGINS=http://localhost:3000,https://myapp.com
```

Or allow all (development only):
```env
CORS_ORIGINS=*
```

---

### 404 Not Found

**Problem**: Endpoint returns 404

**Check**:

1. **Correct URL**:
```bash
# Wrong
curl http://localhost:8000/history

# Correct
curl http://localhost:8000/api/history
```

2. **API documentation**:
```bash
# View available endpoints
curl http://localhost:8000/docs
```

---

### 422 Validation Error

**Problem**: Request data validation fails

**Example**:
```json
{
  "detail": [
    {
      "loc": ["body", "folder_name"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

**Solution**: Include all required fields in request body

**Correct request**:
```bash
curl -X POST http://localhost:8000/api/snippets \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Test",
    "folder_name": "Work",
    "name": "Test Snippet"
  }'
```

---

## Menu Bar Issues

### Menu Bar Icon Not Showing

**Problem**: SimpleCP icon not visible in menu bar

**Note**: Menu bar integration requires Swift frontend (Phase 4)

**Current**: API backend only
- Access via API calls
- Web interface (coming soon)
- Command line tools

**Future**: macOS menu bar app

---

## Common Error Messages

### "ModuleNotFoundError: No module named 'fastapi'"

**Cause**: Dependencies not installed

**Solution**:
```bash
pip install -r requirements.txt
```

---

### "Error checking clipboard: ..."

**Cause**: Clipboard access issue

**Solution**:
1. Check accessibility permissions
2. Restart daemon
3. Check system clipboard works in other apps

---

### "Error saving stores: Permission denied"

**Cause**: No write permission to data directory

**Solution**:
```bash
chmod -R 755 ~/Library/Application\ Support/SimpleCP/
```

---

### "Sentry initialization failed"

**Cause**: Invalid Sentry DSN or network issue

**Solution**:
1. Verify `SENTRY_DSN` in `.env`
2. Or disable Sentry:
```env
ENABLE_SENTRY=false
```

---

## Diagnostic Tools

### Health Check

```bash
# Basic health check
curl http://localhost:8000/health | jq

# Check specific stats
curl http://localhost:8000/api/stats | jq
```

---

### Logs Analysis

```bash
# View recent errors
grep ERROR logs/simplecp.log | tail -20

# Monitor in real-time
tail -f logs/simplecp.log

# Search for specific issue
grep -i "clipboard" logs/simplecp.log
```

---

### System Information

```bash
# Python version
python3 --version

# Installed packages
pip list

# Process information
ps aux | grep daemon.py

# Port usage
lsof -i :8000

# Disk usage
du -sh ~/Library/Application\ Support/SimpleCP/
```

---

### Test Suite

```bash
# Run quick tests
./run_tests.sh fast

# Run all tests
pytest

# Test specific component
pytest tests/unit/test_clipboard_manager.py -v
```

---

### Monitoring Script

Create `check_simplecp.sh`:

```bash
#!/bin/bash

echo "=== SimpleCP Health Check ==="
echo ""

# Check if running
if lsof -i :8000 > /dev/null 2>&1; then
    echo "✓ Daemon is running"
else
    echo "✗ Daemon is NOT running"
    exit 1
fi

# Check API health
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✓ API is responding"
else
    echo "✗ API is NOT responding"
    exit 1
fi

# Check stats
STATS=$(curl -s http://localhost:8000/api/stats)
echo ""
echo "Statistics:"
echo "$STATS" | jq

# Check logs for errors
ERROR_COUNT=$(grep -c ERROR logs/simplecp.log 2>/dev/null || echo 0)
echo ""
echo "Recent errors: $ERROR_COUNT"

if [ $ERROR_COUNT -gt 0 ]; then
    echo "Last 5 errors:"
    grep ERROR logs/simplecp.log | tail -5
fi

echo ""
echo "=== Health Check Complete ==="
```

Usage:
```bash
chmod +x check_simplecp.sh
./check_simplecp.sh
```

---

## Getting Help

### Before Asking for Help

1. **Check logs**:
```bash
tail -50 logs/simplecp.log
```

2. **Run diagnostics**:
```bash
./check_simplecp.sh
```

3. **Search existing issues**:
   - [GitHub Issues](https://github.com/YourUsername/SimpleCP/issues)

4. **Check documentation**:
   - [User Guide](USER_GUIDE.md)
   - [API Documentation](API.md)
   - [Testing Guide](TESTING.md)

---

### Reporting Issues

**Include**:
1. **System information**:
   - macOS version
   - Python version (`python3 --version`)
   - SimpleCP version

2. **Error messages**:
   - Copy exact error from logs
   - Include stack trace if available

3. **Steps to reproduce**:
   - What you did
   - What you expected
   - What actually happened

4. **Configuration**:
   - Relevant `.env` settings (redact sensitive data)
   - Any custom configuration

**Example Issue**:
```markdown
**System**: macOS 13.2, Python 3.11.4, SimpleCP 1.0.0

**Problem**: Daemon crashes on startup

**Error**:
```
2025-01-15 10:30:00 [ERROR] simplecp: Error in API server: ...
```

**Steps**:
1. Installed dependencies: `pip install -r requirements.txt`
2. Ran: `python daemon.py`
3. Daemon started then crashed after 2 seconds

**Config**:
```env
API_PORT=8000
MAX_HISTORY_ITEMS=50
```

**Logs**: (attached)
```

---

### Support Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community help
- **Documentation**: Most common issues covered here
- **Email**: support@simplecp.app

---

### Emergency Recovery

**If nothing works**:

1. **Complete reset**:
```bash
# Backup data first!
cp -r ~/Library/Application\ Support/SimpleCP ~/Desktop/SimpleCP_backup

# Remove all data
rm -rf ~/Library/Application\ Support/SimpleCP

# Reinstall
cd SimpleCP
pip install -r requirements.txt
python daemon.py
```

2. **Fresh install**:
```bash
# Remove installation
rm -rf SimpleCP

# Clone fresh copy
git clone https://github.com/YourUsername/SimpleCP.git
cd SimpleCP
pip install -r requirements.txt
python daemon.py
```

---

**Still stuck? [Open an issue](https://github.com/YourUsername/SimpleCP/issues/new)!**
