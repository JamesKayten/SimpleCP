# BOARD - SimpleCP

**Last Updated:** 2025-11-25 14:40 PST

---

## Tasks FOR OCC (TCC writes here, OCC reads)

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