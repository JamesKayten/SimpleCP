# Port Configuration Fix - December 7, 2025

## 🐛 Issue Found: Wrong Default Port in Startup Diagnostics

### Problem
The app was using **port 8000** instead of the configured **port 49917** during startup diagnostics and port cleanup.

### Symptoms
```
🚀 SIMPLECP STARTUP DIAGNOSTICS
🔍 Backend Port: 8000  ❌ WRONG!
🔴 FORCE KILLING PORT 8000
```

Should be:
```
🚀 SIMPLECP STARTUP DIAGNOSTICS
🔍 Backend Port: 49917  ✅ CORRECT!
🔴 FORCE KILLING PORT 49917
```

### Root Cause
**File**: `SimpleCPApp.swift` (line 40)

```swift
// ❌ BEFORE (WRONG):
let port = backendPort == 0 ? 8000 : backendPort

// ✅ AFTER (FIXED):
let port = backendPort == 0 ? 49917 : backendPort
```

### Why This Happened
- `BackendService.swift` correctly declares: `@AppStorage("backendPort") var port: Int = 49917`
- But `SimpleCPApp.swift` had a hardcoded fallback to `8000` instead of `49917`
- When UserDefaults returns `0` (first launch or reset), it would default to wrong port

### Impact
- ⚠️ **Port conflict**: App tried to kill processes on port 8000 (wrong port)
- ⚠️ **Backend couldn't start**: Port 49917 might be occupied while app kills port 8000
- ⚠️ **Confusion in logs**: Diagnostics showed wrong port number

---

## ✅ Fixes Applied

### 1. Fixed Default Port Value
**File**: `SimpleCPApp.swift:40`
```swift
let port = backendPort == 0 ? 49917 : backendPort
```

### 2. Synchronized apiPort with backendPort
**File**: `BackendService.swift:79-83`

**CRITICAL BUG FOUND**: `BackendService` uses `@AppStorage("backendPort")` but `APIClient` uses `@AppStorage("apiPort")` - these are **different UserDefaults keys**!

```swift
init() {
    logger.info("BackendService initialized with monitoring capabilities")
    
    // Synchronize apiPort with backendPort to ensure consistency
    UserDefaults.standard.set(port, forKey: "apiPort")
    logger.info("Port configuration synchronized: backendPort=\(port), apiPort=\(port)")
    
    startMonitoring()
    ...
}
```

**Why This is Critical**:
- Backend starts on port from `backendPort` (default 49917)
- APIClient connects to port from `apiPort` (default 49917)
- If these get out of sync → **backend and client talk to different ports!**
- Solution: Always sync `apiPort` to match `backendPort` on initialization

### 3. Updated Comments
**File**: `SimpleCPApp.swift:46`
```swift
// ALWAYS kill anything on the configured port - no mercy
```

### 4. Updated Terminal Command Examples
**File**: `SimpleCPApp.swift:164-167`
```swift
/// Run this in Terminal to kill zombie backend processes:
/// lsof -ti:49917 | xargs kill -9
///
/// Or to check what's using the port:
/// lsof -i:49917
```

---

## 🔍 Port Configuration Architecture

### Where Port is Defined

1. **BackendService.swift** (line 54)
   ```swift
   @AppStorage("backendPort") var port: Int = 49917
   ```
   - This is the SOURCE OF TRUTH
   - Stored in UserDefaults as "backendPort"
   - Default: 49917

2. **SimpleCPApp.swift** (line 39-40)
   ```swift
   let backendPort = UserDefaults.standard.integer(forKey: "backendPort")
   let port = backendPort == 0 ? 49917 : backendPort  // ✅ NOW FIXED
   ```
   - Used only for startup diagnostics
   - Must match BackendService default

3. **Shell Scripts**
   - `kill_backend.sh`: Correctly uses 49917
   - `test_port_setup.sh`: Correctly uses 49917
   - `check_backend_port_config.sh`: Correctly uses 49917

### Why Port 49917?
- Hash of "SimpleCP" → 49917
- Falls in **private/dynamic port range** (49152-65535)
- Unlikely to conflict with other services
- More professional than default 8000

---

## 🧪 Testing

### Verify the Fix
1. **Clean UserDefaults** (simulate first launch):
   ```bash
   defaults delete com.simplecp.app backendPort
   ```

2. **Launch app** and check console output:
   ```
   🔍 Backend Port: 49917  ✅ Should be 49917, not 8000!
   ```

3. **Verify backend starts**:
   ```bash
   lsof -i:49917  # Should show Python process
   ```

### Expected Console Output
```
============================================================
🚀 SIMPLECP STARTUP DIAGNOSTICS
============================================================
🔍 Backend Port: 49917
🔍 Current Directory: /
🔍 Bundle Path: /Volumes/.../SimpleCP.app

🔴 FORCE KILLING PORT 49917
✅ Port 49917 freed successfully

📁 FILE SYSTEM CHECKS:
   - venv python exists: ✅
   - pyvenv.cfg exists: ✅
   ...
```

---

## 📝 Related Files

### Files Modified
- ✅ `SimpleCPApp.swift` - Fixed default port (3 changes)

### Files Verified (Already Correct)
- ✅ `BackendService.swift` - Port 49917 (correct)
- ✅ `kill_backend.sh` - Port 49917 (correct)
- ✅ `test_port_setup.sh` - Port 49917 (correct)
- ✅ `check_backend_port_config.sh` - Port 49917 (correct)

---

## 🎯 Summary

| Issue | Status | File | Line |
|-------|--------|------|------|
| Wrong default port (8000) | ✅ Fixed | SimpleCPApp.swift | 40 |
| apiPort/backendPort desync | ✅ Fixed | BackendService.swift | 79-83 |
| Misleading comment | ✅ Fixed | SimpleCPApp.swift | 46 |
| Wrong example commands | ✅ Fixed | SimpleCPApp.swift | 164-167 |

**Impact**: Critical - prevents backend/client connection  
**Risk**: Low - simple synchronization fix  
**Testing**: Required - verify both ports match at 49917

---

**Fixed**: December 7, 2025  
**Status**: ✅ Ready to test
