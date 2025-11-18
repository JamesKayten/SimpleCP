# Claude Code Workflow for SimpleCP

## "File Ready" Command Workflow

When the user says **"file ready"**, Claude Code should execute the following automated workflow:

### 1. Check OCC Communications
**FIRST:** Check for any communications from OCC before processing branches
- Check `docs/occ_communication/` for new files since last run
- Process any `VIOLATION_RESPONSE_*.md` files (fixes completed)
- Process any `OCC_UPDATE_*.md` files (general updates/questions)
- Process any `MERGE_REQUEST_*.md` files (specific merge requests)
- Report OCC communications to user

### 2. Repository Branch Inspection
- Check the SimpleCP repository for any new branches created by OCC (Online Claude Code)
- Use `git fetch` to ensure we have the latest remote branches
- Use `git branch -r` to list all remote branches
- Identify any new branches that aren't `main` or previously known branches

### 3. File Limit Violation Check
Inspect each new branch for file size violations according to SimpleCP's strict limits:

**File Size Limits:**
- `stores/clipboard_item.py`: 200 lines max
- `stores/history_store.py`: 200 lines max
- `stores/snippet_store.py`: 200 lines max
- `clipboard_manager.py`: 300 lines max
- `api/models.py`: 200 lines max
- `api/endpoints.py`: 200 lines max
- `api/server.py`: 200 lines max
- `daemon.py`: 200 lines max

**Check Process:**
```bash
# For each new branch:
git checkout <branch_name>
wc -l <file_path>  # Check line count for each critical file
```

### 4. Alert on Violations & Generate OCC Communication
If any file exceeds its limit:
- **STOP** the merge process immediately
- Alert the user with specific details:
  - Which files are over limit
  - Current line count vs. limit
  - Exact violations per branch
- **AUTOMATICALLY CREATE** violation report in `docs/occ_communication/VIOLATION_REPORT_YYYY-MM-DD.md`
- Include specific refactoring instructions and line count requirements
- Provide user with simple OCC activation command

### 5. Merge Process (if no violations)
If all files are within limits:
```bash
git checkout main
git merge <branch_name>
git push origin main
git branch -d <branch_name>  # Clean up local branch
git push origin --delete <branch_name>  # Clean up remote branch
```

### 6. Report Results
Provide a summary:
- Branches processed
- Files checked
- Any violations found
- Merge status
- Next steps if needed

## OCC Violation Prompt Template

When violations are detected, generate this prompt for Online Claude Code:

```
URGENT: File Size Limit Violations Detected in SimpleCP Branches

The following branches have files that exceed SimpleCP's strict file size limits and cannot be merged into main:

[LIST SPECIFIC VIOLATIONS WITH:]
- Branch name
- File path
- Current line count vs. limit
- Lines over limit

REQUIRED ACTIONS:
1. Refactor oversized files by:
   - Extracting helper functions/classes into separate modules
   - Splitting large files into focused components
   - Moving utility functions to dedicated files
   - Breaking API endpoints into logical groups

2. Ensure ALL files meet these limits:
   - stores/*.py: 200 lines max
   - clipboard_manager.py: 300 lines max
   - api/*.py: 200 lines max
   - daemon.py: 200 lines max

3. Re-test functionality after refactoring
4. Push updated branches for re-validation

The main branch is protected - no merges will occur until all violations are resolved.
```

## OCC Communication System (Bidirectional)

The communication system enables both Local Claude Code and OCC to exchange information through repository files.

### Local Claude Code → OCC
**Automated Report Generation:**
- **File Location:** `docs/occ_communication/VIOLATION_REPORT_YYYY-MM-DD.md`
- **Content:** Detailed violation analysis, refactoring instructions, priorities
- **Timestamp:** Date/time of detection for audit trail

**User Activation Command:**
```
"Check docs/occ_communication/ for latest violation report and fix the issues"
```

### OCC → Local Claude Code
**Response File Types:**
- `VIOLATION_RESPONSE_YYYY-MM-DD.md` - Confirmation of fixes completed
- `OCC_UPDATE_YYYY-MM-DD.md` - General updates or questions for Local Claude Code
- `MERGE_REQUEST_YYYY-MM-DD.md` - Request specific branch merges after validation

**Processing:** During "file ready" workflow, Local Claude Code automatically:
1. **FIRST** checks communication folder for new OCC files
2. Processes and reports OCC communications to user
3. **THEN** proceeds with normal branch inspection

### Communication Protocol
1. **Local Claude Code** detects violations → Creates `VIOLATION_REPORT_*`
2. **User** activates OCC with simple command
3. **OCC** reads report → Implements fixes → Creates `VIOLATION_RESPONSE_*`
4. **User** runs "file ready" → Local Claude Code processes OCC response → Validates fixes
5. **Local Claude Code** merges clean branches or reports remaining issues

### Benefits
- ✅ **Bidirectional communication** - Both directions through repository
- ✅ **No copy/paste required** - All communication via files
- ✅ **Timestamped audit trail** - Complete history of interactions
- ✅ **Automated workflow integration** - Seamless process
- ✅ **Clear action items and responses** - Structured communication

## Quick Reference Commands

```bash
# Check for new branches
git fetch --all
git branch -r --merged origin/main --invert

# Check file line counts
find . -name "*.py" -exec wc -l {} \; | grep -E "(clipboard_item|history_store|snippet_store|clipboard_manager|models|endpoints|server|daemon)"

# Merge workflow
git checkout main
git pull origin main
git merge <branch_name>
git push origin main
```

## File Locations
This document should be stored as:
- `docs/CLAUDE_CODE_WORKFLOW.md` (in repository)
- Local reference copy for Claude Code sessions

## Integration with SimpleCP
This workflow supports the collaboration model where:
- Online Claude Code (OCC) creates feature branches
- Local Claude Code validates and merges them
- GitHub serves as the single source of truth

---
**Created**: 2025-11-17
**Purpose**: Automate branch inspection and merge workflow for SimpleCP development