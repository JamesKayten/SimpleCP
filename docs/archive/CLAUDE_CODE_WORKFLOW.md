# Claude Code Workflow for SimpleCP

## TCC (Terminal Control Center) Integration

This workflow now uses the integrated TCC system for standardized startup and project management.

### Session Initialization
Every new session should start with:
```bash
source ~/tcc-init.sh
```
This provides immediate access to:
- `tcc-status` - Complete project and AI collaboration status
- `tcc-board` - View project BOARD.md files
- `tcc-rules` - Access AI behavior rules
- `tcc-setup` - Configure AI collaboration for projects

## "Check the Board" Standard Procedure

When the user says **"Check the board"**, execute this standardized workflow:

### 1. Repository Branch Inspection
- Check the SimpleCP repository for any new branches created by OCC (Online Claude Code)
- Use `git fetch` to ensure we have the latest remote branches
- Use `git branch -r` to list all remote branches
- Identify any new branches that aren't `main` or previously known branches

### 2. File Limit Violation Check
Inspect each new branch for file size violations according to SimpleCP's updated limits:

**Updated File Size Limits (as of 2025-11-22):**
- `stores/clipboard_item.py`: 300 lines max
- `stores/history_store.py`: 300 lines max
- `stores/snippet_store.py`: 300 lines max
- `clipboard_manager.py`: 300 lines max
- `api/models.py`: 300 lines max
- `api/endpoints.py`: 300 lines max
- `api/server.py`: 300 lines max
- `daemon.py`: 300 lines max

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

### TCC-Enhanced Commands
```bash
# Session startup
source ~/tcc-init.sh

# Project status check
tcc-status

# Board check procedure
cd ~/Documents/SimpleCP
git fetch --all
git branch -r --no-merged origin/main

# Check file line counts (updated for 300-line limit)
find . -name "*.py" -exec wc -l {} \; | grep -E "(clipboard_item|history_store|snippet_store|clipboard_manager|models|endpoints|server|daemon)"

# Merge workflow (if no violations)
git checkout main
git pull origin main
git merge <branch_name>
git push origin main
git branch -d <branch_name>  # Clean up local branch
```

### AI Communication Commands
```bash
# Access AI behavior rules
tcc-rules

# Update AI framework
tcc-sync

# Setup AI collaboration for new projects
tcc-setup --preset python
```

## File Locations
This document should be stored as:
- `~/CLAUDE_CODE_WORKFLOW.md` (primary reference)
- `docs/CLAUDE_CODE_WORKFLOW.md` (in repository backup)

## Integration with SimpleCP & TCC System
This workflow supports the enhanced collaboration model where:
- **TCC (Terminal Control Center)** provides standardized startup and project management
- **Online Claude Code (OCC)** creates feature branches with AI communication protocols
- **Local Claude Code (TCC)** validates, merges, and maintains code quality
- **GitHub** serves as the single source of truth
- **AI Collaboration Framework** provides persistent rules and protocols

## Recent Updates
- **2025-11-22**: Integrated TCC system for standardized workflows
- **2025-11-22**: Updated file size limits to 300 lines (from 200)
- **2025-11-22**: Added AI communication protocol support
- **2025-11-22**: Enhanced session initialization with TCC commands

---
**Created**: 2025-11-17
**Last Updated**: 2025-11-22
**Version**: 2.0 (TCC Integration)
**Purpose**: Standardized AI collaboration workflow with TCC system integration