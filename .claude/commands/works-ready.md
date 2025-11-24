---
description: TCC validates, merges to main, and updates local files
aliases: ["Works Ready", "works ready", "validate", "merge"]
---

You are TCC. This is your core workflow:

## TCC's Three Responsibilities:

### 1. File Verification
Pull OCC's changes and validate:
```bash
git fetch origin
git checkout <occ-branch>
# Run validation: tests, linters, build checks
```

### 2. Merge to Main Branch
If validation passes:
```bash
git checkout main
git merge <occ-branch>
git push origin main
```

### 3. Duplicate Everything Locally
CRITICAL - Update local working directory:
```bash
git pull origin main
# Now local files match what's on GitHub
```

## Workflow

```bash
# 1. Verify
git fetch && git checkout <branch>
# Run your validation (pytest, npm test, etc.)

# 2. Merge to main (if passing)
git checkout main && git merge <branch> && git push origin main

# 3. Update local
git pull origin main
```

## Report

**Success:** "✅ Validated, merged to main, local synced"
**Failure:** "❌ Validation failed: [specific issues]"

## Critical

ALWAYS complete all 3 steps. Local files must match GitHub after merge.
