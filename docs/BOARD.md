# BOARD - SimpleCP

**Last Updated:** 2025-11-25 14:50 PST

---

## Tasks FOR OCC (TCC writes here, OCC reads)

### 🚨 Task: CRITICAL - Investigate "sink folder" error
**Repository:** SimpleCP
**Files affected:**
- TBD - investigating specific "sink folder" error reported by user

**Issues found:**
1. **Folder creation issue:** User clarified this was a misunderstanding of UI behavior ✅ RESOLVED
2. **"Sink folder" error:** User reports specific error with sink folder - requires investigation

**Status:**
- ✅ Folder click behavior clarified - not a bug
- ❌ **New issue:** "Sink folder" error needs investigation
- ✅ Backend monitoring active and API endpoints working

**What TCC is doing:**
- [ ] **Monitor backend for "sink folder" related errors**
- [ ] **Search codebase for sink-related functionality**
- [ ] **Request user to provide specific error details**

**Priority:** HIGH - User-reported critical issue

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