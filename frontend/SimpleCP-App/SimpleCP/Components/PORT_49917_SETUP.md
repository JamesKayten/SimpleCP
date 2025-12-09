# Port 49917 Configuration Guide

## Overview

SimpleCP is configured to use **port 49917** instead of the default 8000. This is a private port (49152-65535 range) chosen to avoid conflicts with common development servers.

## Current Status

✅ **Swift App**: Configured to use port 49917  
✅ **Scripts**: Updated to work with port 49917  
⚠️ **Backend**: Needs configuration to use port 49917

---

## Backend Configuration Required

Your Python backend (`backend/main.py`) needs to be configured to accept the port from the Swift app. The app passes the port in **two ways**:

### 1. Command-Line Argument (Recommended)
```bash
python3 main.py --port 49917
```

### 2. Environment Variable (Fallback)
```bash
SIMPLECP_PORT=49917 python3 main.py
```

---

## How to Configure Your Backend

### Option A: Using argparse (Recommended)

Add this to your `backend/main.py`:

```python
import argparse
import os
import uvicorn
from fastapi import FastAPI

app = FastAPI()

# Your routes here...

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="SimpleCP Backend Server")
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.getenv("SIMPLECP_PORT", "49917")),  # Fallback to env var, then 49917
        help="Port to run the server on"
    )
    args = parser.parse_args()
    
    print(f"🚀 Starting SimpleCP backend on port {args.port}")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=args.port,
        log_level="info"
    )
```

### Option B: Environment Variable Only

If you prefer to only use environment variables:

```python
import os
import uvicorn
from fastapi import FastAPI

app = FastAPI()

# Your routes here...

if __name__ == "__main__":
    port = int(os.getenv("SIMPLECP_PORT", "49917"))
    
    print(f"🚀 Starting SimpleCP backend on port {port}")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=port,
        log_level="info"
    )
```

---

## Swift App Implementation

The Swift app (`BackendService.swift`) is configured to:

1. **Pass port as command-line argument**:
   ```swift
   process.arguments = [config.mainPyPath.path, "--port", "\(port)"]
   ```

2. **Set environment variable**:
   ```swift
   environment["SIMPLECP_PORT"] = "\(port)"
   ```

3. **Default to port 49917**:
   ```swift
   @AppStorage("backendPort") var port: Int = 49917
   ```

---

## Testing

### 1. Check if Port is Available
```bash
lsof -i:49917
```

If output is empty, port is free. If not, kill the process:
```bash
lsof -ti:49917 | xargs kill -9
```

### 2. Test Backend Manually
```bash
cd /Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP/backend
source ../.venv/bin/activate
python3 main.py --port 49917
```

Expected output:
```
🚀 Starting SimpleCP backend on port 49917
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:49917
```

### 3. Test Health Endpoint
In another terminal:
```bash
curl http://localhost:49917/health
```

Expected response:
```json
{"status":"healthy"}
```

### 4. Check App Connection
1. Launch SimpleCP app
2. Check connection status in the control bar
3. Should show: 🟢 **Connected**

---

## Troubleshooting

### Error: "Could not connect to the server"

**Cause**: Backend not listening on port 49917

**Solutions**:
1. Check if backend is running:
   ```bash
   lsof -i:49917
   ```

2. Check backend logs in Console.app:
   - Filter by "simplecp" or "backend"
   - Look for port configuration errors

3. Run diagnostic script:
   ```bash
   ./diagnose_backend.sh
   ```

4. Test backend manually (see Testing section above)

### Error: "Port 49917 is already in use"

**Solution**:
```bash
./kill_backend.sh
```

Or manually:
```bash
lsof -ti:49917 | xargs kill -9
```

### Backend Starts But Uses Wrong Port

**Check**:
1. Is your `main.py` configured to accept `--port` argument?
2. Run the configuration check:
   ```bash
   chmod +x configure_backend_port.sh
   ./configure_backend_port.sh
   ```

### Health Check Fails Despite Backend Running

**Check**:
1. Is backend listening on correct port?
   ```bash
   lsof -i:49917
   ```

2. Does health endpoint exist?
   ```bash
   curl -v http://localhost:49917/health
   ```

3. Check firewall settings (unlikely for localhost)

---

## Updated Scripts

All scripts have been updated to use port 49917:

- ✅ `kill_backend.sh` - Kills process on port 49917
- ✅ `diagnose_backend.sh` - Checks port 49917
- ✅ `configure_backend_port.sh` - New script to help configure backend

---

## Why Port 49917?

Port 49917 was chosen because:

1. **Private port range** (49152-65535): Won't conflict with system services
2. **Derived from "SimpleCP"**: Hash-based selection for uniqueness
3. **Avoids common ports**: 8000, 8080, 3000, etc. often used by dev servers
4. **Unlikely to conflict**: More stable for long-running development

---

## Quick Reference Commands

```bash
# Check if port is in use
lsof -i:49917

# Kill process on port
lsof -ti:49917 | xargs kill -9

# Start backend manually
cd backend && source ../.venv/bin/activate && python3 main.py --port 49917

# Test health endpoint
curl http://localhost:49917/health

# Run diagnostics
./diagnose_backend.sh

# Check backend configuration
./configure_backend_port.sh
```

---

## Next Steps

1. ✅ Update your `backend/main.py` to accept `--port` argument
2. ✅ Test backend manually on port 49917
3. ✅ Verify health endpoint responds
4. ✅ Launch SimpleCP app and verify connection
5. ✅ Test API functionality (create/edit snippets)

---

**Last Updated**: December 7, 2025  
**Status**: Configuration guide complete, backend update required
