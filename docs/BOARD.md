# BOARD - SimpleCP

**Last Updated:** 2025-11-25 14:50 PST

---

## Tasks FOR OCC (TCC writes here, OCC reads)

### 🚨 Task: CRITICAL - Fix folder UI interaction bugs
**Repository:** SimpleCP
**Files affected:**
- Folder management UI components (likely in Views or ContentView)

**Issues found:**
1. **Clicking on folder creates new folder:** When user clicks on existing folder in right panel, it triggers folder creation instead of folder selection
2. **Folder rename fails with network error:** User reports rename attempts show network connection errors

**Root cause analysis:**
- ✅ Backend API tested and working perfectly (`GET/POST/PUT /api/folders` all return 200)
- ❌ Frontend UI logic incorrectly handling folder click events
- ❌ Frontend may be making wrong API calls or handling responses incorrectly

**What OCC needs to do:**
- [ ] Fix folder click behavior - should select folder, not create new folder
- [ ] Debug folder rename functionality to ensure correct API calls
- [ ] Test all folder management UI interactions (create, rename, delete, select)

**Priority:** HIGH - Critical user functionality broken

**Test steps to reproduce:**
1. Open SimpleCP frontend
2. Click on any existing folder in right panel → Incorrectly creates new folder
3. Use "Manage Folders" dropdown to rename → Network error (even with backend running)

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