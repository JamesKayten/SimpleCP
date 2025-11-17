# File Size Limit Violations Report
**Date:** 2025-11-17
**Time:** 15:53 UTC
**Reporter:** Claude Code (Local)
**Status:** 🚨 MERGE BLOCKED

## Summary
8 OCC branches detected with **3 critical file size violations**. All merges halted until violations are resolved.

## Violation Details

### 🔴 CRITICAL - Branch: `claude/add-crash-reporting-monitoring-01HoQe2KYyJpSDgSV3iXDW5z`
- **File:** `api/server.py`
- **Current Size:** 212 lines
- **Limit:** 200 lines
- **Over Limit:** +12 lines
- **Priority:** Medium

### 🔴 CRITICAL - Branch: `claude/advanced-features-01QejCKQKY6KRopDnFrhYjHa`
- **File:** `clipboard_manager.py`
- **Current Size:** 458 lines
- **Limit:** 300 lines
- **Over Limit:** +158 lines
- **Priority:** 🚨 HIGH (SEVERE violation)

### 🔴 CRITICAL - Branch: `claude/clipboard-rest-api-01DzcCuzbBB7D7V7fX6Wzdm3`
- **File:** `api/server.py`
- **Current Size:** 397 lines
- **Limit:** 200 lines
- **Over Limit:** +197 lines
- **Priority:** 🚨 HIGH (SEVERE violation)

## Required Actions

### Immediate Priorities (Severe Violations)
1. **clipboard_manager.py (458 → 300 lines):**
   - Extract clipboard monitoring logic to `services/monitor.py`
   - Move search functionality to `services/search.py`
   - Create `services/persistence.py` for save/load operations
   - Keep only core manager logic in main file

2. **api/server.py (397 → 200 lines):**
   - Split into endpoint modules:
     - `api/history_endpoints.py`
     - `api/snippet_endpoints.py`
     - `api/folder_endpoints.py`
   - Keep only FastAPI app setup in main server.py
   - Move middleware/CORS setup to `api/middleware.py`

### Secondary Priority
3. **api/server.py (212 → 200 lines) in monitoring branch:**
   - Extract logging/monitoring setup to `services/monitoring.py`
   - Move error handlers to `api/error_handlers.py`

## File Size Limits Reference
```
stores/clipboard_item.py: 200 lines max
stores/history_store.py: 200 lines max
stores/snippet_store.py: 200 lines max
clipboard_manager.py: 300 lines max
api/models.py: 200 lines max
api/endpoints.py: 200 lines max
api/server.py: 200 lines max
daemon.py: 200 lines max
```

## Testing Requirements
After refactoring:
1. Run all existing tests
2. Verify API endpoints still function
3. Test clipboard monitoring
4. Confirm snippet operations work
5. Validate daemon startup

## Response Instructions
When violations are fixed:
1. Push updated branches to GitHub
2. Create response file: `docs/occ_communication/VIOLATION_RESPONSE_2025-11-17.md`
3. Include:
   - List of refactored files
   - New line counts
   - Testing results
   - Ready for merge confirmation

## Branches Awaiting Fix
- claude/add-crash-reporting-monitoring-01HoQe2KYyJpSDgSV3iXDW5z
- claude/advanced-features-01QejCKQKY6KRopDnFrhYjHa
- claude/clipboard-rest-api-01DzcCuzbBB7D7V7fX6Wzdm3
- claude/audit-repo-compatibility-01CxGGV9nppHxuDoHhWzCaBr (pending check)
- claude/optimize-menubar-backend-01DxXU2c37jvUZuYNuET1diB (pending check)
- claude/python-backend-rest-api-01Mw9CH1oHHCoHCYEsxp6KfU (appears clean)
- claude/swift-frontend-build-01SX2icqjQVcsDZWvjhRAk6A (pending check)
- claude/test-python-backend-015mX9x8sWWdovpXpsAy4dBr (pending check)

---
**Next Steps:** OCC should prioritize the HIGH priority violations first, then address the medium priority issue.