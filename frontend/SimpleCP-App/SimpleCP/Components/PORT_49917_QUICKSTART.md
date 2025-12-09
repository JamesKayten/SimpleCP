# SimpleCP Port 49917 Configuration - Quick Start

## 🎯 What's Been Done

Your Swift app is now fully configured to use **port 49917**. Here's what was updated:

### ✅ Swift App (`BackendService.swift`)
- Default port set to 49917
- Passes `--port 49917` as command-line argument to Python backend
- Sets `SIMPLECP_PORT=49917` environment variable
- All health checks target `http://localhost:49917`

### ✅ Shell Scripts
- `kill_backend.sh` - kills processes on port 49917
- `diagnose_backend.sh` - checks port 49917 status
- `configure_backend_port.sh` - NEW: helps configure backend
- `test_port_setup.sh` - NEW: tests entire setup
- `check_backend_port_config.sh` - NEW: verifies backend configuration

### ✅ Documentation
- `PORT_49917_SETUP.md` - Complete configuration guide
- `PORT_49917_QUICKSTART.md` - This file

---

## 🚀 Next Steps (Required)

### Step 1: Configure Your Python Backend

Your `backend/main.py` needs to accept the port from the Swift app.

**Add this code to your `backend/main.py`:**

```python
import argparse
import os
import uvicorn
from fastapi import FastAPI

app = FastAPI()

# ... your routes and other code ...

if __name__ == "__main__":
    # Accept port from command line or environment
    parser = argparse.ArgumentParser(description="SimpleCP Backend")
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.getenv("SIMPLECP_PORT", "49917")),
        help="Port to run the server on (default: 49917)"
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

### Step 2: Verify Backend Configuration

Run the configuration check script:

```bash
chmod +x check_backend_port_config.sh
./check_backend_port_config.sh
```

This will tell you if your backend is properly configured.

### Step 3: Test Everything

Run the complete test:

```bash
chmod +x test_port_setup.sh
./test_port_setup.sh
```

This interactive script will:
1. Check if port 49917 is available
2. Verify backend files exist
3. Check Python environment
4. Verify backend port configuration
5. Optionally start the backend for testing

---

## 🧪 Manual Testing

If you prefer to test manually:

### 1. Kill Any Existing Backend
```bash
lsof -ti:49917 | xargs kill -9
```

### 2. Start Backend Manually
```bash
cd /Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP/backend
source ../.venv/bin/activate
python3 main.py --port 49917
```

You should see:
```
🚀 Starting SimpleCP backend on port 49917
INFO:     Started server process [xxxxx]
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

### 4. Launch SimpleCP App
- Open your Swift app in Xcode and run it
- Check the connection status in the control bar
- Should show: 🟢 **Connected**

---

## 🔧 Troubleshooting

### Issue: Backend won't start

**Check:**
```bash
./diagnose_backend.sh
```

**Common causes:**
- Port already in use (kill with `./kill_backend.sh`)
- Python environment missing (check with `./test_port_setup.sh`)
- Missing dependencies (run `pip install -r requirements.txt`)

### Issue: Health check fails

**Check if backend is actually running:**
```bash
lsof -i:49917
```

**If nothing shows up:**
- Backend isn't running
- Check backend logs in Console.app (filter by "backend" or "simplecp")
- Try manual start (see Manual Testing above)

**If process is running but health check fails:**
- Backend might be on wrong port
- Check backend configuration: `./check_backend_port_config.sh`
- Verify health endpoint works: `curl http://localhost:49917/health`

### Issue: "Port 49917 already in use"

**Quick fix:**
```bash
./kill_backend.sh
```

**Or manually:**
```bash
lsof -ti:49917 | xargs kill -9
```

---

## 📊 How It All Works

### Swift App → Backend Communication

1. **App starts** → BackendService initializes
2. **BackendService** checks if port 49917 is available
3. **If available** → Starts Python backend:
   ```
   python3 main.py --port 49917
   ```
   With environment: `SIMPLECP_PORT=49917`
4. **Backend starts** on port 49917
5. **Health check** sends request to `http://localhost:49917/health`
6. **Backend responds** with `{"status":"healthy"}`
7. **Connection established** → API calls can flow

### Why Two Methods (CLI + Environment)?

- **Primary**: `--port 49917` command-line argument
- **Fallback**: `SIMPLECP_PORT` environment variable
- Backend can support both for maximum flexibility

---

## 📁 File Summary

### Modified Files
- `BackendService.swift` - Port configuration and backend startup
- `kill_backend.sh` - Port 8000 → 49917
- `diagnose_backend.sh` - Port 8000 → 49917

### New Files
- `PORT_49917_SETUP.md` - Comprehensive setup guide
- `PORT_49917_QUICKSTART.md` - This file
- `configure_backend_port.sh` - Backend configuration helper
- `test_port_setup.sh` - Complete setup test script
- `check_backend_port_config.sh` - Backend configuration verifier

### Files You Need to Update
- `backend/main.py` - Add argparse and port configuration (see Step 1 above)

---

## ✅ Checklist

Before considering this done:

- [ ] Backend `main.py` updated with port argument support
- [ ] Run `./check_backend_port_config.sh` - shows backend is configured
- [ ] Run `./test_port_setup.sh` - all checks pass
- [ ] Backend starts manually on port 49917
- [ ] Health endpoint responds: `curl http://localhost:49917/health`
- [ ] Swift app connects and shows green "Connected" status
- [ ] Can create/edit/delete snippets (API calls work)

---

## 🆘 Need Help?

### Quick Diagnostics
```bash
# Check port status
lsof -i:49917

# Check backend configuration
./check_backend_port_config.sh

# Full diagnostic
./diagnose_backend.sh

# Complete test
./test_port_setup.sh
```

### Check Logs
1. Open **Console.app** (macOS)
2. Filter by "simplecp" or "backend"
3. Look for error messages

### Manual Backend Start
```bash
cd /Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP/backend
source ../.venv/bin/activate
python3 main.py --port 49917
```

Watch the output for errors.

---

## 🎉 Success Indicators

When everything is working:

1. ✅ Backend starts with message: "🚀 Starting SimpleCP backend on port 49917"
2. ✅ `lsof -i:49917` shows Python process
3. ✅ `curl http://localhost:49917/health` returns `{"status":"healthy"}`
4. ✅ Swift app shows 🟢 **Connected**
5. ✅ Creating snippets syncs to backend without errors
6. ✅ No "Could not connect to server" errors in logs

---

**Created**: December 7, 2025  
**Status**: Swift app ready, backend configuration required  
**Next Action**: Update `backend/main.py` (see Step 1)
