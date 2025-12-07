# Port Conflict Fix - December 6, 2025

## 🔴 Issue: Port 8000 Already in Use

**Symptom**: Backend shows error "Port 8000 is already in use" or backend dies immediately with exit code 1.

**Cause**: Another process (probably a previous backend instance) is still running on port 8000.

---

## ✅ Quick Fix (Choose One)

### Option 1: Use the "Force Kill Port" Button
1. Your app now shows a red "Force Kill Port" button when there's a port error
2. Click it to automatically kill the process
3. Backend will restart automatically

### Option 2: Run the Kill Script
```bash
cd /Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP
chmod +x kill_backend.sh
./kill_backend.sh
```

### Option 3: Manual Terminal Command
```bash
lsof -ti:8000 | xargs kill -9
```

---

## 🔧 What Was Changed

### 1. BackendService.swift - Improved Port Handling
**Before**: Just showed error message, required manual intervention

**After**: 
- Tries to connect to existing backend first (maybe it's healthy)
- If not healthy, automatically kills the process
- Waits 1 second for port to release
- Automatically retries backend start
- Only shows error if auto-kill fails

### 2. ContentView+ControlBar.swift - Added Force Kill Button
**New**: Red "Force Kill Port" button appears when there's a port conflict
- Only visible when backend error contains "port"
- One-click solution for users
- Automatically restarts backend after killing

### 3. kill_backend.sh - Helper Script
**New**: Standalone script to kill port 8000 process
- Shows what's using the port
- Kills it
- Verifies it's freed
- Easy to run from Terminal

---

## 📊 Why This Happens

Port 8000 stays occupied when:
1. **App crashes** - Backend process keeps running after app quits
2. **Force quit app** - Process doesn't get cleaned up properly
3. **Multiple launches** - Launching app multiple times quickly
4. **Other apps** - Something else using port 8000 (rare)

---

## 🧪 Testing

### Test the Auto-Kill Feature
1. Manually start backend in Terminal:
   ```bash
   cd /Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP
   source .venv/bin/activate
   python3 backend/main.py &
   ```

2. Launch SimpleCP app

3. **Expected**:
   - App detects port is occupied
   - Shows "⚠️ Port occupied by unresponsive process"
   - Shows "🔧 Attempting to free port..."
   - Automatically kills the process
   - Shows "✅ Successfully freed port 8000"
   - Backend starts normally

### Test the Force Kill Button
1. Start backend manually (same as above)
2. Launch SimpleCP app
3. If auto-kill fails, red "Force Kill Port" button appears
4. Click button
5. Backend should restart automatically

---

## 🔍 Debugging

### Check What's Using Port 8000
```bash
lsof -i:8000
```

**Example output**:
```
COMMAND   PID        USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
python3   12345 Smallfavor    3u  IPv4 0xabcdef123456      0t0  TCP localhost:8000 (LISTEN)
```

The PID (12345 in this example) is the process ID to kill.

### Kill Specific PID
```bash
kill -9 12345  # Replace with actual PID
```

### Check if Port is Free
```bash
lsof -ti:8000
# If output is empty, port is free
# If output shows a number, port is occupied
```

---

## 🚀 Prevention

To prevent port conflicts in the future:

### 1. Always Quit App Properly
- Use Cmd+Q or "Quit" from menu
- Don't force quit unless necessary
- This ensures AppDelegate.applicationWillTerminate() runs

### 2. Check Port Before Launch (Already Implemented)
The app now checks port status in `SimpleCPApp.init()`:
```swift
let portInUse = isPortInUse(8000)
print("Port 8000 in use: \(portInUse ? "⚠️ YES" : "✅ No")")
```

### 3. Auto-Cleanup on Startup (Already Implemented)
If port is occupied and backend doesn't respond, app now automatically kills it.

---

## 📝 Code Changes

### BackendService.swift - handlePortOccupied()
```swift
// NEW: Auto-kill unresponsive process
func handlePortOccupied() {
    // 1. Try to connect (maybe it's healthy)
    if healthCheckPasses() {
        useExistingBackend()
        return
    }
    
    // 2. Not healthy - kill it
    print("🔧 Attempting to free port...")
    let killed = killProcessOnPort(port)
    
    if killed {
        print("✅ Successfully freed port")
        Thread.sleep(forTimeInterval: 1.0)  // Wait for port release
        startBackendWithExponentialBackoff()  // Retry
    } else {
        // Show error + manual instructions
        showPortOccupiedError()
    }
}
```

### ContentView+ControlBar.swift - Force Kill Button
```swift
// NEW: UI button for manual port kill
if let error = backendService.backendError, 
   error.contains("port") || error.contains("Port") {
    Button(action: { forceKillPort() }) {
        Label("Force Kill Port", systemImage: "exclamationmark.triangle")
    }
    .buttonStyle(.borderedProminent)
    .tint(.red)
}
```

---

## ✅ Verification

After implementing this fix:

- [ ] Port conflicts are detected on startup
- [ ] App automatically kills unresponsive processes
- [ ] Red "Force Kill Port" button appears if auto-kill fails
- [ ] Manual kill script works (`./kill_backend.sh`)
- [ ] Backend restarts automatically after port is freed
- [ ] No manual intervention needed in most cases

---

## 📚 Related Files

- `BackendService.swift` - Auto-kill logic
- `ContentView+ControlBar.swift` - Force kill button
- `SimpleCPApp.swift` - Port status check on startup
- `kill_backend.sh` - Manual kill script
- `STARTUP_FIX_DEC6_FINAL.md` - Startup performance fix

---

**Status**: ✅ **FIXED** - Port conflicts now handled automatically  
**Priority**: 🔴 **CRITICAL** - Prevents app from starting  
**Testing**: Required - verify auto-kill works

---

Last updated: December 6, 2025, 11:15 AM
