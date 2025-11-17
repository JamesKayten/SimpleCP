# Claude Code Workflow for SimpleCP

## "File Ready" Command Workflow

When the user says **"file ready"**, Claude Code should execute the following automated workflow:

### 1. Repository Branch Inspection
- Check the SimpleCP repository for any new branches created by OCC (Online Claude Code)
- Use `git fetch` to ensure we have the latest remote branches
- Use `git branch -r` to list all remote branches
- Identify any new branches that aren't `main` or previously known branches

### 2. File Limit Violation Check
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

### 3. Alert on Violations
If any file exceeds its limit:
- **STOP** the merge process
- Alert the user with specific details:
  - Which files are over limit
  - Current line count vs. limit
  - Suggest refactoring or splitting files

### 4. Merge Process (if no violations)
If all files are within limits:
```bash
git checkout main
git merge <branch_name>
git push origin main
git branch -d <branch_name>  # Clean up local branch
git push origin --delete <branch_name>  # Clean up remote branch
```

### 5. Report Results
Provide a summary:
- Branches processed
- Files checked
- Any violations found
- Merge status
- Next steps if needed

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