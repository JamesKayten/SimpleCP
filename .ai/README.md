# AI COLLABORATION - START HERE

## 🚀 FRAMEWORK UPDATED - NEW TASK DETECTION SYSTEM

**Read `.ai/FRAMEWORK_USAGE.md` for complete guide**

---

## For AI AGENTS (OCC/Other AIs) - EXECUTING Work

1. **Check for pending work** (instant detection):
```bash
./.ai/check-tasks.sh
# OR
source .ai/STATUS && echo $TASK_STATE
```

2. **Read assignment** if PENDING:
```bash
cat .ai/CURRENT_TASK.md
```

3. **Read working rules**:
```bash
cat .ai/BEHAVIOR_RULES.md
```

4. **Execute immediately** - No questions, no exploration

5. **Update status when done**:
```bash
sed -i 's/TASK_STATE=IN_PROGRESS/TASK_STATE=IDLE/' .ai/STATUS
```

---

## For TCC - ASSIGNING Work

**⚡ 60-second guide:** `.ai/TCC_QUICK_REFERENCE.md`
**📖 Full documentation:** `.ai/FRAMEWORK_USAGE.md`

**Quick assign:**
```bash
# 1. Update STATUS file
nano .ai/STATUS  # Set TASK_STATE=PENDING, add details

# 2. Update CURRENT_TASK.md with task description
# Use .ai/CURRENT_TASK.md.TEMPLATE as guide

# 3. Done - AI will detect and execute automatically
```

---

## Quick Start (Legacy - Still Works)
```bash
# Read current assignment
cat .ai/CURRENT_TASK.md

# Start working immediately on specified tasks
```

## Project Info
- **Type:** Python Backend/API
- **Language:** python
- **File Size Limit:** 250 lines
- **Test Coverage:** 90%
- **Tools:** black,flake8,pytest,pyperclip

## File Structure
- `BEHAVIOR_RULES.md` - How to work
- `CURRENT_TASK.md` - What to work on
- `COMPLETED_TASKS.md` - Work history

**Environment Universal:** Works in any environment (macOS, Linux, containers)

**No setup required** - Just read and execute.