# Fully Autonomous AI-to-AI Workflow

## How It Works (No User Intervention Required)

### Step 1: User Describes Task to TCC
```
User → TCC: "Add user authentication to the API"
```

### Step 2: TCC Creates Task for OCC
TCC writes task to `.ai/TASK_FOR_OCC.md` and pushes to main branch

### Step 3: GitHub Action Auto-Triggers OCC
- Push to `TASK_FOR_OCC.md` triggers `occ-task-detector.yml`
- GitHub Action calls Claude API with task details
- OCC implements the feature on new branch
- OCC commits and pushes work
- OCC writes `.ai/OCC_COMPLETED.md` to notify TCC

### Step 4: GitHub Action Auto-Triggers TCC Validation
- Push to `OCC_COMPLETED.md` triggers `tcc-validator.yml`
- TCC validates file sizes (250 line limit)
- TCC validates code quality (Black, Flake8)
- TCC checks for violations

### Step 5a: If Clean → Auto-Merge
- TCC merges OCC's branch to main
- Creates `.ai/TCC_RESULT.md` with success message
- Workflow complete ✅

### Step 5b: If Violations → Auto-Request Fixes
- TCC creates `.ai/VIOLATIONS_FOR_OCC.md` with detailed report
- Push triggers `occ-fix-violations.yml`
- OCC reads violations and fixes them
- OCC notifies TCC when done
- Loop back to Step 4 (re-validation)

### Step 6: Cycle Continues Until Merge
The workflow loops automatically until all code passes validation, then auto-merges.

## File Communication Protocol

| File | Creator | Purpose | Next Action |
|------|---------|---------|-------------|
| `TASK_FOR_OCC.md` | TCC | Assign work to OCC | Triggers OCC |
| `OCC_COMPLETED.md` | OCC | Notify task done | Triggers TCC validation |
| `VIOLATIONS_FOR_OCC.md` | TCC | Report issues | Triggers OCC fixes |
| `TCC_RESULT.md` | TCC | Confirm merge | End workflow |

## GitHub Actions Workflow Chain

```
User → TCC (local)
         ↓ (creates TASK_FOR_OCC.md)
         ↓ (git push)
GitHub Action: occ-task-detector.yml
         ↓ (calls Claude API)
OCC (via API) implements code
         ↓ (creates OCC_COMPLETED.md)
         ↓ (git push)
GitHub Action: tcc-validator.yml
         ↓ (runs validation scripts)
         ├─→ CLEAN → auto-merge → DONE ✅
         └─→ VIOLATIONS → creates VIOLATIONS_FOR_OCC.md
                    ↓ (git push)
         GitHub Action: occ-fix-violations.yml
                    ↓ (calls Claude API)
         OCC fixes violations
                    ↓ (creates OCC_COMPLETED.md)
                    ↓ (loops back to validation)
```

## Required Setup

### 1. GitHub Repository Secrets
Add your Anthropic API key:
- Go to repository Settings → Secrets and variables → Actions
- Add secret: `ANTHROPIC_API_KEY`

### 2. GitHub Actions Enabled
- Ensure Actions are enabled in repository settings
- Workflows will trigger automatically on file changes

### 3. File Size Limits
All files must be ≤250 lines (enforced by TCC validator)

## Truly Autonomous Features

✅ No user copy/paste between AIs
✅ No manual trigger needed
✅ OCC auto-detects tasks via GitHub Actions
✅ TCC auto-validates via GitHub Actions
✅ Auto-merge when code is clean
✅ Auto-fix-retry loop for violations
✅ Complete audit trail in git history
✅ All logic contained in repository

## User Experience

**User does:**
1. Tell TCC what they want
2. Wait for completion notification

**User doesn't do:**
- Manually trigger OCC
- Copy/paste between AIs
- Check for completion
- Merge branches

The AIs handle everything autonomously via GitHub Actions!
