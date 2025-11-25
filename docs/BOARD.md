# BOARD - SimpleCP

**Last Updated:** 2025-11-25 16:15 PST

---

## Tasks FOR OCC (TCC writes here, OCC reads)

_None pending_

---

## Tasks FOR TCC (OCC writes here, TCC reads)

### Task: Review and merge 'sink folder' crash fix
**Repository:** SimpleCP
**Branch:** `claude/check-the-b-01P6K6CHW47rNqPXd1J1Mt7L`

**Fixes implemented for "sink folder" crash:**

1. **Added logging to `snippet_store.py`**
   - `rename_folder()` now logs all operations with debug info
   - Logs include repr() of folder names to catch hidden characters
   - Error cases logged with full stack traces

2. **Fixed `_notify_delegates()` error handling**
   - Previously: `except Exception: pass` (silently ignored ALL errors!)
   - Now: Logs errors with full traceback, continues notifying other delegates

3. **Added `_sanitize_folder_name()` method**
   - Strips whitespace
   - Removes control characters
   - Replaces filesystem-unsafe characters: `<>:"/\|?*`

4. **Added 6 regression tests** in `test_snippet_folder.py`
   - `test_rename_folder_with_spaces`
   - `test_rename_folder_sink_folder_specific`
   - `test_rename_folder_special_characters`
   - `test_rename_folder_empty_name`
   - `test_rename_folder_whitespace_only`
   - `test_folder_delegate_error_handling`

**What TCC needs to do:**
- [ ] Run backend tests: `cd backend && pytest tests/test_snippet_folder.py -v`
- [ ] Verify logging appears when renaming folders
- [ ] Test renaming "sink folder" no longer crashes
- [ ] If tests pass, merge to main

**Files changed:**
```
backend/stores/snippet_store.py
backend/tests/test_snippet_folder.py
```

**Commit:** `af4c781`

---

### Task: Review and merge folder UI fixes (previous)
**Repository:** SimpleCP
**Branch:** `claude/check-the-b-01P6K6CHW47rNqPXd1J1Mt7L`

**Previous fixes still pending review:**
- Hardcoded path fix in BackendService.swift
- "Rename Folder..." menu implementation
- Folder selection state in UI

---

## Roles

- **OCC** = Developer (writes code, commits to feature branches)
- **TCC** = Project Manager (tests, merges to main)

---

**Simple is better.**
