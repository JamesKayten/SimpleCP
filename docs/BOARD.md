# AIM Task Board - simple-cp-test

## Tasks FOR OCC (TCC writes here, OCC reads)

### 🔧 URGENT: Fix Swift Compilation Errors

**Issue:** Project fails to compile in Xcode due to access control violations

**Files Affected:**
- `frontend/SimpleCP-macOS/Sources/SimpleCP/Views/ContentView.swift` (lines 19-20)
- `frontend/SimpleCP-macOS/Sources/SimpleCP/Views/ContentView+ControlBar.swift` (lines 49-50)

**Required Changes:**
1. Change `@State private var folderToRename: SnippetFolder?` → `@State fileprivate var folderToRename: SnippetFolder?`
2. Change `@State private var renameFolderNewName = ""` → `@State fileprivate var renameFolderNewName = ""`

**Technical Reason:** Swift extensions cannot access `private` members. Need `fileprivate` for same-file access.

**Verification:** Project should compile successfully in Xcode after changes.

**Status:** 🔴 BLOCKING - prevents Swift development

### 🔧 URGENT: Fix Swift Concurrency & Actor Isolation Errors

**Issue:** Additional compilation failures due to Swift concurrency violations

**Files Affected:**
- `frontend/SimpleCP-macOS/Sources/SimpleCP/Services/BackendService.swift` (lines 250-251)
- `frontend/SimpleCP-macOS/Sources/SimpleCP/Services/BackendService+Monitoring.swift` (lines 34, 51, 136, 165)

**Required Changes:**

**BackendService.swift:**
1. Line 250: `cleanupTimers()` - needs `await` or `Task { await cleanupTimers() }`
2. Line 251: `cleanupProcess()` - needs `await` or `Task { await cleanupProcess() }`

**BackendService+Monitoring.swift:**
1. Line 34: `consecutiveFailures` - needs `self.consecutiveFailures` in closure
2. Line 51: `checkBackendStatus()` - needs `await` in async context
3. Line 136: `maxRestartAttempts` - needs `self.maxRestartAttempts` in closure
4. Line 165: `restartCount` & `maxRestartAttempts` - needs `self.` prefix in closure

**Technical Reason:** Swift 5.5+ strict concurrency checking requires explicit self capture and proper async/await usage for main actor methods.

**Verification:** Project should compile without concurrency warnings after changes.

**Status:** 🔴 BLOCKING - prevents Swift development

---

## Tasks FOR TCC (OCC writes here, TCC reads)

*No pending TCC tasks*

---

## COMPLETION RECORD

**2025-12-02:** Branch `claude/check-the-b-013xthdEHQyhQRL8dpG46qj8` processed
- **Result:** Nothing to merge (empty branch)
- **Action:** Deleted branch (no commits ahead of main)
- **Main Status:** 3fa0b06 (unchanged)

---

**Board Status:** Initialized
**Project:** simple-cp-test
**Created:** 2025-12-01
