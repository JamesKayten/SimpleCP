# TCC Workflow Guide

**Simple collaboration workflow for Terminal Claude Code**

---

## TCC's Core Responsibilities

TCC has **three critical responsibilities** in this collaboration:

### 1. File Verification
Validate OCC's changes:
- Run tests
- Check linters
- Verify builds
- Ensure quality standards

### 2. Merge to Main Branch
If validation passes:
- Merge OCC's branch to main
- Push to GitHub

### 3. Duplicate Everything Locally
CRITICAL - Update local working directory:
- Pull latest from main
- Ensure local files match GitHub
- User can immediately test/use the code

**All three steps must complete. Never skip step 3.**

---

## Complete TCC Workflow

```bash
# 1. File Verification
git fetch origin
git checkout <occ-branch>
# Run validation: pytest, npm test, make test, etc.

# 2. Merge to Main (if passing)
git checkout main
git merge <occ-branch>
git push origin main

# 3. Duplicate Locally
git pull origin main
# Local files now match GitHub
```

---

## Available Commands

### `/check-the-board`
Read BOARD.md and TASKS.md for current status.

### `/works-ready`
**TCC's main command** - Executes all three responsibilities:
1. Verify files
2. Merge to main
3. Update local

### `/verify`
Just runs validation without merging.

### `/merge-to-main`
Create PR (for human review workflow).

---

## Collaboration Pattern

**TCC's Role:**
1. File verification - Validate code quality
2. Merge to main - Push passing code
3. Update local - Sync working directory

**OCC's Role:**
1. Read TCC's reports
2. Fix issues
3. Push changes

**Communication:**
- Through BOARD.md status updates
- Through git commits
- Simple file-based collaboration

---

## Critical Rule

**TCC must ALWAYS complete all 3 steps:**
1. ✅ Verify files
2. ✅ Merge to main
3. ✅ Update local working directory

**Never skip step 3.** Local files must match GitHub after merge.

---

## Troubleshooting

**Problem:** Validation fails
**Solution:** Report issues, don't merge, wait for OCC fixes

**Problem:** Merge succeeds but local not updated
**Solution:** Run `git pull origin main` immediately

**Problem:** Local files don't match GitHub
**Solution:** You skipped step 3. Always complete all 3 steps.

---

**Version:** 3.0 Simple
**Last Updated:** November 23, 2025

**TCC: Verify, Merge, Update Local. Always.**
