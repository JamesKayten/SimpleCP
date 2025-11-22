# AI COLLABORATION - START HERE

**ANY AI working on this repository:**

1. **Read `.ai/BEHAVIOR_RULES.md`** - Understand working style requirements (if exists)
2. **Read `.ai/CURRENT_TASK.md`** - Get current assignment
3. **Execute tasks immediately** - No questions, no exploration
4. **Update `.ai/CURRENT_TASK.md`** when tasks completed

## Quick Start
```bash
# Check for pending tasks
./.ai/check-tasks.sh

# Or manually:
source .ai/STATUS
if [ "$TASK_STATE" = "PENDING" ]; then
    cat .ai/CURRENT_TASK.md
fi
```

## Project Info
- **Type:** {{PROJECT_TYPE}}
- **Language:** {{PRIMARY_LANGUAGE}}
- **File Size Limit:** {{FILE_SIZE_LIMIT}} lines
- **Test Coverage:** {{TEST_COVERAGE}}%
- **Tools:** {{TOOLS}}

## File Structure
- `STATUS` - Machine-readable task state
- `CURRENT_TASK.md` - What to work on
- `FRAMEWORK_USAGE.md` - How to use the task system
- `TCC_QUICK_REFERENCE.md` - Quick guide for task assignment
- `BEHAVIOR_RULES.md` - How to work (optional)

**Environment Universal:** Works in any environment (macOS, Linux, containers)

**No setup required** - Just read and execute.
