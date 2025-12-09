# Bug Fixes - December 7, 2025

## Issues Addressed

### 1. ✅ Snippet Creation Bug: Debug Output Capture [FIXED]

**Problem**: 
- Multiple `print()` statements were outputting debug information to stdout
- Debug output could potentially be captured and saved as snippets
- Print statements were not properly gated with `#if DEBUG` blocks

**Files Fixed**:
- ✅ `ClipboardManager+Snippets.swift` - Converted all `print()` to `logger.debug()` with `#if DEBUG`
- ✅ `ClipboardManager.swift` - Converted folder sync `print()` to `logger.debug()` with `#if DEBUG`
- ✅ `SaveSnippetWindowManager.swift` - Removed all debug `print()` statements

**Changes Made**:

1. **ClipboardManager+Snippets.swift**:
   - Lines 14-18: `print()` → `logger.debug()` wrapped in `#if DEBUG`
   - Line 28: `print()` → `logger.debug()` wrapped in `#if DEBUG`
   - Line 33: `print()` → `logger.debug()` wrapped in `#if DEBUG`
   - Lines 39-47: All `print()` → `logger.debug()` wrapped in `#if DEBUG`
   - Lines 241-244: `print()` → `logger.debug()` wrapped in `#if DEBUG`

2. **ClipboardManager.swift**:
   - Line 113: Folder sync `print()` → `logger.debug()` wrapped in `#if DEBUG`

3. **SaveSnippetWindowManager.swift**:
   - Removed 14 debug `print()` statements from:
     - `createNewFolder.toggle()` action
     - `newFolderName` onChange handler  
     - Create folder button action
     - `createFolder()` method

**Benefits**:
- ✅ Debug output only appears in DEBUG builds
- ✅ Uses proper Logger framework for structured logging
- ✅ Privacy-aware logging with `.public` privacy annotations
- ✅ Eliminates risk of debug output being captured as snippets

---

### 2. ✅ IPv6 Fallback: Network Connection Issues [FIXED]

**Problem**:
- Swift networking code was using `localhost` which can resolve to IPv4 or IPv6
- Backend might bind to IPv4 only, causing connection failures on systems preferring IPv6
- Health checks and API calls could fail intermittently

**Solution**: Changed all backend URLs from `localhost` to explicit IPv4 `127.0.0.1`

**Files Fixed**:
- ✅ `BackendService.swift` - 2 occurrences (lines 212, 465)
- ✅ `ClipboardManager.swift` - 1 occurrence (line 54)

**Changes Made**:

1. **BackendService.swift** - `handlePortOccupied()`:
   ```swift
   // OLD: http://localhost:\(self.port)/health
   // NEW: http://127.0.0.1:\(self.port)/health
   ```

2. **BackendService.swift** - `performHealthCheck()`:
   ```swift
   // OLD: http://localhost:\(port)/health
   // NEW: http://127.0.0.1:\(port)/health
   ```

3. **ClipboardManager.swift** - `waitForBackendAndSync()`:
   ```swift
   // OLD: http://localhost:49917/health
   // NEW: http://127.0.0.1:49917/health
   ```

**Benefits**:
- ✅ Guarantees IPv4 connections, avoiding IPv6 resolution issues
- ✅ More predictable and reliable backend connections
- ✅ Faster connection establishment (no DNS resolution needed)

**Note for Backend**: 
If you need the backend to support both IPv4 and IPv6, ensure Python's Uvicorn binds to `0.0.0.0` (all interfaces) instead of `localhost`:

```python
# In backend/main.py
uvicorn.run(app, host="0.0.0.0", port=port)  # Binds to all interfaces
```

---

### 3. ⚠️ Folder ID "33333": Test Data Issue [NEEDS BACKEND FIX]

**Problem**:
- Folder ID "33333" appears to be test/dummy data that doesn't exist
- This could cause API 404 errors when trying to save snippets to this folder

**Possible Root Causes**:
1. Hardcoded test data in frontend or backend
2. Old/stale data in UserDefaults or backend database
3. Backend returning invalid folder IDs

**Recommended Investigation**:

1. **Search for hardcoded "33333"**:
   ```bash
   # In your project directory:
   grep -r "33333" .
   ```

2. **Check ClipboardManager data persistence**:
   - Look at `ClipboardManager.swift` methods:
     - `loadData()` - Loading folders from UserDefaults
     - `saveFolders()` - Saving folders to UserDefaults
   - Check for any default/sample folders being created

3. **Check Backend**:
   - Look for hardcoded folder IDs in `backend/main.py`
   - Check database initialization/migrations
   - Verify folder list endpoint returns valid IDs

4. **Clear User Defaults** (temporary fix):
   ```swift
   // In ClipboardManager or a debug function:
   UserDefaults.standard.removeObject(forKey: "snippetFolders")
   UserDefaults.standard.synchronize()
   ```

5. **Add Validation**:
   Add folder ID validation before API calls:
   ```swift
   func saveAsSnippet(name: String, content: String, folderId: UUID?, tags: [String] = []) {
       // Validate folder exists if folderId is provided
       if let folderId = folderId {
           guard folders.contains(where: { $0.id == folderId }) else {
               logger.error("❌ Invalid folder ID: \(folderId)")
               // Handle error or use default folder
               return
           }
       }
       // ... rest of method
   }
   ```

**Next Steps**:
- [ ] Search codebase for "33333"
- [ ] Check UserDefaults content in debug
- [ ] Verify backend folder list API
- [ ] Add folder ID validation
- [ ] Consider adding folder sync on app startup

---

## Summary

### ✅ Fixed Issues:
1. **Debug Output Capture** - Converted all `print()` to proper logging with `#if DEBUG`
2. **IPv6 Connection Issues** - Changed `localhost` to `127.0.0.1` for reliable IPv4 connections

### ⚠️ Requires Investigation:
3. **Folder ID "33333"** - Need to find source and implement validation

### Files Modified:
- `ClipboardManager+Snippets.swift`
- `ClipboardManager.swift`  
- `SaveSnippetWindowManager.swift`
- `BackendService.swift`
- `MenuBarManager.swift` (earlier fix)

### Testing Checklist:
- [ ] Verify no debug output appears in release builds
- [ ] Test backend connections on IPv6-preferring systems
- [ ] Verify health checks succeed consistently
- [ ] Test snippet creation/saving
- [ ] Check folder list synchronization
- [ ] Investigate folder ID "33333" issue

---

**Generated**: December 7, 2025  
**Status**: Ready for testing
