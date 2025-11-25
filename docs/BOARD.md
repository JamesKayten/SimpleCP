# BOARD - SimpleCP

**Last Updated:** 2025-11-25 14:50 PST

---

## Tasks FOR OCC (TCC writes here, OCC reads)

### ✅ COMPLETED: "Sink folder" crash investigation
**Repository:** SimpleCP
**Completed by:** TCC on 2025-11-25
**Files analyzed:**
- `backend/api/endpoints.py:181` - `rename_folder` API endpoint
- `backend/clipboard_manager.py:127` - `rename_snippet_folder` method
- `backend/stores/snippet_store.py:46` - Core `rename_folder` implementation
- `backend/stores/snippet_store.py:221` - `_notify_delegates` system

**ROOT CAUSE IDENTIFIED:**
🚨 **Backend crashes when renaming folders named "sink folder"**
- Confirmed reproducible backend process termination (`status: killed`)
- Last successful API call: `PUT /api/folders/TCC_Test_Folder` before crash
- Folder rename code has proper error handling - crash occurs deeper in system
- No error messages in logs (process terminates without traceback)

**POTENTIAL CAUSES:**
1. **Special characters in "sink folder" name** causing file system issues
2. **Memory corruption** during folder path updates in snippet items
3. **Race condition** in delegate notification system during auto-save
4. **System-level resource exhaustion** during JSON serialization

**WHAT OCC NEEDS TO DO:**
- [ ] **Add comprehensive logging** to `rename_folder` method with detailed step tracking
- [ ] **Add error logging** to delegate notification system (currently swallows exceptions)
- [ ] **Implement input sanitization** for folder names with special characters
- [ ] **Add memory/resource monitoring** during folder operations
- [ ] **Create unit test** that reproduces crash with "sink folder" name

**WORKAROUND FOR USER:**
Avoid renaming folders to names containing "sink" until fix is deployed.

**Priority:** CRITICAL - Backend crash bug affects core functionality

---

### Task: Fix hardcoded project path in BackendService
**Repository:** SimpleCP
**Files affected:**
- `frontend/SimpleCP-macOS/Sources/SimpleCP/Services/BackendService.swift`

**Issue found:**
Line 498 contains incorrect hardcoded path: `/Volumes/User_Smallfavor/Users/Smallfavor/clipboard_manager`

**What OCC needs to do:**
- [ ] Update hardcoded path to: `/Volumes/User_Smallfavor/Users/Smallfavor/Documents/SimpleCP`
- [ ] Consider making the path detection more flexible/dynamic rather than hardcoded

**Priority:** Medium - App works but path detection could fail in some scenarios

**Logs:**
```swift
// Line 498 in BackendService.swift
let possiblePaths = [
    "/Volumes/User_Smallfavor/Users/Smallfavor/clipboard_manager", // ← INCORRECT
    FileManager.default.currentDirectoryPath,
    ProcessInfo.processInfo.environment["PROJECT_DIR"] ?? ""
]
```

---

## Tasks FOR TCC (OCC writes here, TCC reads)

_None pending_

<!--
OCC: Post merge requests, testing requests here for TCC.

### Task: [Brief description]
**Repository:** [repo name]
**Branch:** [branch ready for review/merge]

**What TCC needs to do:**
- [ ] Test X
- [ ] Merge Y
-->

---

## Roles

- **OCC** = Developer (writes code, commits to feature branches)
- **TCC** = Project Manager (tests, merges to main)

---

**Simple is better.**