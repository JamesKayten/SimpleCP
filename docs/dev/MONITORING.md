# SimpleCP Monitoring & Analytics Guide

Complete guide to crash reporting, performance monitoring, and analytics for SimpleCP.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Sentry Crash Reporting](#sentry-crash-reporting)
- [Structured Logging](#structured-logging)
- [Performance Monitoring](#performance-monitoring)
- [Usage Analytics](#usage-analytics)
- [Health Monitoring](#health-monitoring)
- [Configuration](#configuration)
- [Production Best Practices](#production-best-practices)

---

## Overview

SimpleCP includes comprehensive monitoring and analytics capabilities:

- **Crash Reporting**: Automatic error tracking and reporting via Sentry
- **Structured Logging**: Configurable logging with file rotation and JSON formatting
- **Performance Monitoring**: Track API response times and operation durations
- **Usage Analytics**: Monitor clipboard events and API usage patterns
- **Health Monitoring**: Real-time health checks with detailed metrics

---

## Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
# Copy example configuration
cp .env.example .env

# Edit .env with your settings
nano .env
```

### 3. Enable Sentry (Optional)

1. Sign up at [sentry.io](https://sentry.io)
2. Create a new project
3. Copy your DSN
4. Update `.env`:

```env
ENABLE_SENTRY=true
SENTRY_DSN=https://your-dsn@sentry.io/project-id
```

### 4. Run with Monitoring

```bash
python daemon.py
```

Logs will be written to `./logs/simplecp.log` by default.

---

## Sentry Crash Reporting

### What is Sentry?

Sentry provides automatic crash reporting, error tracking, and performance monitoring. When enabled, SimpleCP will:

- Capture all unhandled exceptions
- Track API performance and slow endpoints
- Record breadcrumbs for debugging context
- Alert you when errors occur

### Setup

#### 1. Create Sentry Account

Visit [sentry.io](https://sentry.io) and create a free account.

#### 2. Create Project

- Create a new project in Sentry
- Choose "Python" as the platform
- Copy your DSN (Data Source Name)

#### 3. Configure SimpleCP

Update your `.env` file:

```env
ENABLE_SENTRY=true
SENTRY_DSN=https://your-dsn-here@sentry.io/project-id
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=0.1  # 10% for production
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `ENABLE_SENTRY` | `false` | Enable/disable Sentry integration |
| `SENTRY_DSN` | None | Your Sentry project DSN |
| `SENTRY_ENVIRONMENT` | Auto-set | Environment name (dev/staging/prod) |
| `SENTRY_TRACES_SAMPLE_RATE` | `1.0` | % of transactions to monitor (0.0-1.0) |
| `SENTRY_PROFILES_SAMPLE_RATE` | `1.0` | % of transactions to profile (0.0-1.0) |

### What Gets Tracked?

**Automatic Error Tracking:**
- All unhandled exceptions
- API endpoint errors
- Clipboard monitoring errors
- Data persistence failures

**Performance Monitoring:**
- API request durations
- Slow database operations
- Memory usage patterns

**Context & Breadcrumbs:**
- API requests (method, path, status)
- Clipboard events
- User actions
- System information

### Privacy

SimpleCP is configured to **NOT** send personally identifiable information (PII) to Sentry:

```python
# In monitoring.py
"send_default_pii": False  # PII protection enabled
```

---

## Structured Logging

### Overview

SimpleCP uses structured logging with:

- **Log Levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL
- **File Rotation**: Automatic log rotation at 10MB
- **JSON Format**: Optional JSON logs for production
- **Contextual Data**: Rich context in every log entry

### Configuration

```env
LOG_LEVEL=INFO
LOG_TO_FILE=true
LOG_FILE_PATH=./logs/simplecp.log
LOG_MAX_BYTES=10485760  # 10MB
LOG_BACKUP_COUNT=5
LOG_JSON_FORMAT=false
```

### Log Locations

- **Console**: Always enabled (stdout)
- **File**: `./logs/simplecp.log` (if `LOG_TO_FILE=true`)
- **Rotated Files**: `simplecp.log.1`, `simplecp.log.2`, etc.

### Log Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| `DEBUG` | Development debugging | Variable values, function calls |
| `INFO` | Normal operations | Startup, shutdown, clipboard events |
| `WARNING` | Unexpected but handled | Configuration issues, retries |
| `ERROR` | Errors that need attention | Failed operations, exceptions |
| `CRITICAL` | Critical failures | System crashes, data corruption |

### Development vs Production

**Development** (`LOG_JSON_FORMAT=false`):
```
2025-11-17 10:30:15 [INFO] simplecp: SimpleCP daemon started successfully
2025-11-17 10:30:16 [INFO] simplecp: New clipboard item: Hello World
```

**Production** (`LOG_JSON_FORMAT=true`):
```json
{"timestamp": "2025-11-17T10:30:15Z", "level": "INFO", "name": "simplecp", "message": "SimpleCP daemon started successfully"}
{"timestamp": "2025-11-17T10:30:16Z", "level": "INFO", "name": "simplecp", "message": "New clipboard item: Hello World"}
```

### Viewing Logs

```bash
# Tail logs in real-time
tail -f ./logs/simplecp.log

# Search for errors
grep ERROR ./logs/simplecp.log

# View last 100 lines
tail -n 100 ./logs/simplecp.log
```

---

## Performance Monitoring

### Overview

SimpleCP tracks performance metrics for all operations:

- API request/response times
- Clipboard check durations
- Data persistence operations
- Custom operation tracking

### Tracked Metrics

**For Each Operation:**
- **Count**: Total number of executions
- **Total Duration**: Cumulative time
- **Min/Max**: Fastest and slowest execution
- **Average**: Mean execution time

### Accessing Metrics

Performance metrics are available via the `/health` endpoint:

```bash
curl http://localhost:49917/health
```

Response:
```json
{
  "status": "healthy",
  "monitoring": {
    "performance": {
      "api_get_/api/history": {
        "count": 150,
        "total_ms": 1250.5,
        "min_ms": 5.2,
        "max_ms": 25.8,
        "avg_ms": 8.3
      }
    }
  }
}
```

### Custom Performance Tracking

```python
from monitoring import track_performance

# Using context manager
with track_performance("my_operation"):
    # Your code here
    pass

# Using decorator
from monitoring import track_performance_decorator

@track_performance_decorator("my_function")
def my_function():
    pass
```

---

## Usage Analytics

### Overview

Track usage patterns and user behavior:

- Clipboard events (new items, updates)
- API request counts
- History operations
- Snippet operations
- Search queries
- Error rates

### Tracked Events

```python
{
  "clipboard_events": 1234,
  "api_requests": 5678,
  "history_operations": 234,
  "snippet_operations": 89,
  "search_queries": 45,
  "errors": 3
}
```

### Accessing Analytics

Via the `/health` endpoint:

```bash
curl http://localhost:49917/health | jq '.monitoring.usage'
```

### Privacy

All analytics are **local only** - no data is sent to third parties unless Sentry is explicitly enabled.

---

## Health Monitoring

### Health Check Endpoint

The `/health` endpoint provides comprehensive system status:

```bash
curl http://localhost:49917/health
```

**Full Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "environment": "production",
  "clipboard_stats": {
    "history_count": 45,
    "snippet_count": 12,
    "folder_count": 3,
    "max_history": 50
  },
  "monitoring": {
    "performance": { ... },
    "usage": { ... },
    "sentry_enabled": true,
    "environment": "production"
  }
}
```

### Integration with Monitoring Tools

Use the `/health` endpoint with:

- **Uptime Monitors**: Pingdom, UptimeRobot
- **Application Monitoring**: Datadog, New Relic
- **Custom Scripts**: Curl + cron jobs

Example health check script:

```bash
#!/bin/bash
HEALTH=$(curl -s http://localhost:49917/health | jq -r '.status')
if [ "$HEALTH" != "healthy" ]; then
  echo "SimpleCP is unhealthy!"
  # Send alert
fi
```

---

## Configuration

### Environment Variables

All configuration via `.env` file. See `.env.example` for complete options.

### Configuration Priority

1. Environment variables (highest priority)
2. `.env` file
3. Default values (lowest priority)

### Runtime Configuration

Settings are loaded once at startup. To apply changes:

```bash
# Restart the daemon
pkill -f daemon.py
python daemon.py
```

---

## Production Best Practices

### 1. Enable Structured Logging

```env
LOG_JSON_FORMAT=true
LOG_LEVEL=INFO
```

**Benefits:**
- Easier parsing with log aggregation tools
- Better integration with ELK/Splunk/Datadog
- Structured query capabilities

### 2. Configure Sentry Sampling

```env
ENABLE_SENTRY=true
SENTRY_TRACES_SAMPLE_RATE=0.1  # 10% of transactions
SENTRY_PROFILES_SAMPLE_RATE=0.1
```

**Benefits:**
- Reduces Sentry costs
- Still captures all errors
- Representative performance data

### 3. Restrict CORS Origins

```env
CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

### 4. Set Production Environment

```env
ENVIRONMENT=production
```

**Effects:**
- Error messages show less detail
- Optimized performance settings
- Production-specific Sentry tagging

### 5. Monitor Health Endpoint

Set up automated health checks:

```bash
# Cron job (every 5 minutes)
*/5 * * * * curl -sf http://localhost:49917/health || alert.sh
```

### 6. Log Rotation

Default settings handle log rotation automatically:

```env
LOG_MAX_BYTES=10485760  # 10MB per file
LOG_BACKUP_COUNT=5       # Keep 5 backups = 50MB total
```

### 7. Regular Log Review

```bash
# Weekly error review
grep ERROR ./logs/simplecp.log.* | sort | uniq -c

# Performance analysis
grep "duration_ms" ./logs/simplecp.log | awk '{print $NF}' | sort -n
```

---

## Troubleshooting

### Sentry Not Receiving Events

1. **Check DSN**: Verify `SENTRY_DSN` is correct
2. **Enable Sentry**: Ensure `ENABLE_SENTRY=true`
3. **Check Connectivity**: Test network access to sentry.io
4. **View Logs**: Check for Sentry initialization errors

```bash
grep -i sentry ./logs/simplecp.log
```

### Logs Not Being Written

1. **Check Permissions**: Ensure write access to `./logs/`
2. **Verify Configuration**: `LOG_TO_FILE=true`
3. **Check Disk Space**: Ensure sufficient disk space

```bash
ls -la ./logs/
df -h
```

### High Log Volume

Reduce log verbosity:

```env
LOG_LEVEL=WARNING  # Only warnings and errors
```

Or disable specific verbose operations in code.

---

## API Reference

### Monitoring Functions

```python
# In monitoring.py

# Initialize Sentry
initialize_sentry()

# Track performance
with track_performance("operation_name"):
    pass

# Track events
track_clipboard_event("new_item", item_id="123")
track_api_request("GET", "/api/history", 200, 15.5)

# Capture errors
capture_exception(exception, context={"key": "value"})
capture_message("Important message", level="warning")

# Get statistics
stats = get_monitoring_stats()
```

### Logger Functions

```python
# In logger.py

# Get logger
from logger import logger

# Log messages
logger.debug("Debug message")
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
logger.critical("Critical message")

# Convenience functions
log_api_request("GET", "/api/health", 200, 5.2)
log_clipboard_event("new_item", item_id="abc")
log_error(exception, context={"request_id": "123"})
log_performance("save_data", 125.5)
```

---

## Support

For issues or questions:

1. Check logs: `tail -f ./logs/simplecp.log`
2. Review Sentry dashboard (if enabled)
3. Check health endpoint: `curl http://localhost:49917/health`
4. File an issue on GitHub

---

**Happy Monitoring! 📊**
