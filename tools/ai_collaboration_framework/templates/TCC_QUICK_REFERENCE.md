# TCC Quick Reference - Task Assignment

## Assign a Task in 60 Seconds

### 1. Edit STATUS file (5 fields)
```bash
nano .ai/STATUS
```
Set:
- `TASK_STATE=PENDING`
- `SUMMARY="Your task summary"`
- `PRIORITY=1` (1-4)
- `ASSIGNED_TO=OCC` (or ANY)
- `EFFORT_HOURS=4`

### 2. Edit CURRENT_TASK.md (top section only)
```bash
nano .ai/CURRENT_TASK.md
```
Fill in **ACTIVE ASSIGNMENT** section:
- What to do
- Which files
- How to verify

### 3. Done ✅
AI detects automatically at next session start.

---

## Check Current Status
```bash
source .ai/STATUS && echo "State: $TASK_STATE | Assigned to: $ASSIGNED_TO"
```

## Files Explained
- **STATUS** = Machine-readable state (IDLE/PENDING/etc)
- **CURRENT_TASK.md** = Human-readable instructions
- **FRAMEWORK_USAGE.md** = Full documentation
- **CURRENT_TASK.md.TEMPLATE** = Template to copy from

## Task States
- `IDLE` = No work pending
- `PENDING` = Task assigned, waiting for AI to start
- `IN_PROGRESS` = AI currently working on it
- `BLOCKED` = Task stuck, needs attention

---

## Validate & Merge Completed Work

### Step 1: Sync Repository (CRITICAL)
```bash
# Always sync first - OCC may have pushed changes
git fetch origin
git pull origin main  # Or your branch name
```

### Step 2: Check Task Completion
```bash
source .ai/STATUS
if [ "$TASK_STATE" = "IDLE" ]; then
    echo "✅ OCC marked task complete"
fi
```

### Step 3: Validate Compliance
Check against project standards:
```bash
# File size check (example: 300 line limit)
find . -name "*.py" -exec wc -l {} \; | awk '$1 > 300 {print}'

# Run project validation
cat docs/ai_communication/VALIDATION_RULES.md  # Review standards
```

**Check:**
- ✅ File size limits (e.g., ≤300 lines)
- ✅ Code quality (linting, formatting)
- ✅ Test coverage (e.g., ≥90%)
- ✅ No security issues
- ✅ All acceptance criteria met

### Step 4: Decision

#### ✅ If COMPLIANT → Merge to Main
```bash
# Review changes
git log --oneline -5
git diff main

# Merge to main
git checkout main
git merge <feature-branch>
git push origin main

# Update STATUS
sed -i 's/TASK_STATE=.*/TASK_STATE=IDLE/' .ai/STATUS
sed -i 's/SUMMARY=.*/SUMMARY=""/' .ai/STATUS

# Sync again to ensure everything is current
git pull origin main
```

#### ❌ If NON-COMPLIANT → Request Refactoring
```bash
# Update CURRENT_TASK.md with specific issues
nano .ai/CURRENT_TASK.md
# Add: "Files exceeding size limit: file1.py (450 lines), file2.py (380 lines)"
# Add: "Required: Split into modules ≤300 lines each"

# Update STATUS
sed -i 's/TASK_STATE=.*/TASK_STATE=PENDING/' .ai/STATUS
sed -i 's/SUMMARY=.*/SUMMARY="Refactor: file size compliance"/' .ai/STATUS

# Commit and push feedback
git add .ai/
git commit -m "Request refactoring for file size compliance"
git push origin main
```

### Step 5: Always Sync After Changes
```bash
# Keep local and remote in sync
git pull origin main
git push origin main
```

---

**Full guide:** `.ai/FRAMEWORK_USAGE.md`
