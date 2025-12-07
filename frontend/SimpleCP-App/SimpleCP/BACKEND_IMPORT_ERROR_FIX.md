# Backend Import Error Fix Guide
**Error**: `ModuleNotFoundError: No module named 'api.server'`  
**Date**: December 6, 2025

---

## 🔍 Problem

Your `backend/main.py` is trying to import:
```python
from api.server import run_server  # Line 19
```

But the `backend/api/server.py` file doesn't exist or isn't accessible.

---

## 🚨 Immediate Diagnosis

Run this script to check your backend structure:

```bash
cd /Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP
chmod +x check_backend_structure.sh
./check_backend_structure.sh
```

This will show you exactly what's missing.

---

## 🔧 Solution Options

### **Option 1: Fix the Backend Structure** (If you have modular backend)

If your backend is supposed to use `api/server.py`:

```bash
cd /Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP/backend

# Check if api/ directory exists
ls -la api/

# If missing, create it:
mkdir -p api
touch api/__init__.py

# Check if server.py exists
ls -la api/server.py

# If missing, you need to create it or restore it from backup
```

**What `api/server.py` should contain**:
```python
# backend/api/server.py

from fastapi import FastAPI
import uvicorn
import os

app = FastAPI()

@app.get("/health")
async def health():
    return {"status": "healthy"}

# Add your other routes here...

def run_server():
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="127.0.0.1", port=port)
```

**What `api/__init__.py` should contain**:
```python
# backend/api/__init__.py
# This file can be empty, it just makes Python treat 'api' as a package
```

---

### **Option 2: Simplify main.py** (Recommended if backend is simple)

If you don't need the modular structure, simplify `backend/main.py`:

**Before** (broken):
```python
# backend/main.py
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from api.server import run_server  # ← This fails

if __name__ == "__main__":
    run_server()
```

**After** (fixed):
```python
# backend/main.py
from fastapi import FastAPI
import uvicorn
import os

app = FastAPI()

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.post("/api/clipboard/add")
async def add_clipboard_item(item: dict):
    # Your logic here
    return {"success": True}

# Add other routes...

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="127.0.0.1", port=port)
```

This removes the dependency on `api/server.py` entirely.

---

## 🧪 Test the Fix

### 1. Test manually in Terminal:

```bash
cd /Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP
source .venv/bin/activate
cd backend
python3 main.py
```

**Expected output** (success):
```
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
```

**Error output** (still broken):
```
Traceback (most recent call last):
  File ".../main.py", line 19, in <module>
    from api.server import run_server
ModuleNotFoundError: No module named 'api.server'
```

### 2. Test the API:

In another Terminal window:
```bash
curl http://localhost:8000/health
```

**Expected**: `{"status":"healthy"}`

### 3. Run the app:

Once the backend works manually, restart your SimpleCP app. It should now connect successfully.

---

## 🔍 Check Your Backend Structure

Your backend should look like one of these:

### **Option A: Modular Structure**
```
backend/
├── main.py              # Imports from api.server
├── requirements.txt
└── api/
    ├── __init__.py      # Empty file (makes it a Python package)
    ├── server.py        # Contains run_server() and FastAPI app
    └── routes/          # Optional: split routes into modules
        ├── __init__.py
        ├── clipboard.py
        └── snippets.py
```

### **Option B: Standalone Structure** (Simpler)
```
backend/
├── main.py              # Contains everything (FastAPI app + routes)
└── requirements.txt
```

---

## 📝 Updated BackendService Validation

I've updated `BackendService.swift` to detect this issue early:

**New behavior**:
- ✅ Checks for `backend/api/` directory
- ✅ Checks for `backend/api/server.py`
- ✅ Checks for `backend/api/__init__.py`
- ⚠️ Shows warnings if structure is incomplete
- ❌ Better error messages when backend crashes

**Console output** (if missing files):
```
⚠️ WARNING: backend/api/ directory not found
   Backend structure may be incomplete
   
⚠️ WARNING: backend/api/server.py not found
   Backend will likely crash on import
```

---

## 🚀 Quick Recovery Steps

1. **Check what you have**:
   ```bash
   ls -la backend/
   ls -la backend/api/
   ```

2. **Choose your approach**:
   - If you have `api/server.py` → Make sure `api/__init__.py` exists
   - If you DON'T have `api/` → Simplify `main.py` to not import from it

3. **Test manually**:
   ```bash
   source .venv/bin/activate
   python3 backend/main.py
   ```

4. **Once working, restart app**

---

## 💡 Why This Happens

Python requires:
1. **`__init__.py`** in every directory to treat it as a package
2. **Proper PYTHONPATH** or relative imports
3. **Files must exist** where they're imported from

The error `ModuleNotFoundError: No module named 'api.server'` means:
- Python can't find a directory named `api/`
- OR `api/` exists but doesn't have `__init__.py`
- OR `api/server.py` doesn't exist
- OR you're running from the wrong directory

---

## 📚 Related Files

- `BackendService.swift` - Updated validation logic
- `check_backend_structure.sh` - Diagnostic script (run this first!)
- `PROJECT_STATUS_REPORT.md` - Full project documentation

---

## ✅ Verification Checklist

After fixing, verify:

- [ ] `python3 backend/main.py` runs without errors
- [ ] `curl http://localhost:8000/health` returns `{"status":"healthy"}`
- [ ] SimpleCP app connects successfully
- [ ] Connection indicator shows green "Connected"
- [ ] No error logs in Console.app

---

**Status**: 🔴 Backend structure issue - needs manual fix  
**Next Step**: Run `./check_backend_structure.sh` to diagnose
