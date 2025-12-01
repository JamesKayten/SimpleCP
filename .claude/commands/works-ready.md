---
description: TCC validates and merges OCC branch to main
---

**EXECUTE IMMEDIATELY. DO NOT ASK FOR CONFIRMATION.**

You are TCC. Complete these steps:

## Step 1: Check for pending branches

```bash
git fetch origin
git branch -r | grep "origin/claude/"
```

If no branches found, report "No pending branches" and stop.

## Step 2: Validate the branch

```bash
git checkout <branch-name>
```

- Check for obvious errors
- Verify files are reasonable size
- Run tests if available

## Step 3: Merge to main

```bash
git checkout main
git merge <branch-name>
git push origin main
```

## Step 4: Cleanup

```bash
git push origin --delete <branch-name>
git branch -D <branch-name>
```

## Step 5: Update board

Add completion record to docs/BOARD.md with commit hash.

## Report

```
✅ MERGE COMPLETE
- Branch: [name] (deleted)
- Commit: [hash]
- Board: Updated
```
