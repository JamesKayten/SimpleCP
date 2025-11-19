# AI Task Framework Usage Guide

## Quick Start for AI Agents

### 1. Check for Work (Instant Detection)
```bash
source .ai/STATUS
if [ "$TASK_STATE" = "PENDING" ]; then
    cat "$TASK_FILE"  # Read detailed instructions
fi
```

Or use the helper script:
```bash
./.ai/check-tasks.sh
```

### 2. Read Task Details
```bash
cat .ai/CURRENT_TASK.md
```

### 3. Execute Work
Follow instructions in CURRENT_TASK.md or referenced file (e.g., OCC_IMPLEMENTATION_TASKS.md)

### 4. Update Status When Complete
```bash
# Update STATUS file
sed -i 's/TASK_STATE=IN_PROGRESS/TASK_STATE=IDLE/' .ai/STATUS
sed -i 's/SUMMARY=.*/SUMMARY=""/' .ai/STATUS

# Update CURRENT_TASK.md with completion notes
```

---

## File Responsibilities

### `.ai/STATUS` (Machine-Readable State)
- **Purpose:** Quick state detection for scripts/AI agents
- **Format:** Shell-sourceable key=value pairs
- **Updated by:** TCC when assigning work, AI when completing
- **Read by:** AI agents at session start

**Key fields:**
- `TASK_STATE`: Current state (IDLE/PENDING/IN_PROGRESS/BLOCKED)
- `TASK_FILE`: Path to detailed instructions
- `PRIORITY`: Urgency level (1-4)
- `ASSIGNED_TO`: Which AI should handle this

### `.ai/CURRENT_TASK.md` (Human-Readable Instructions)
- **Purpose:** Detailed task description and context
- **Format:** Structured markdown
- **Updated by:** TCC for new tasks, AI for completion history
- **Read by:** AI agents and humans

**Structure:**
1. **ACTIVE ASSIGNMENT** section (top) - Current work
2. **RECENT COMPLETIONS** section (middle) - Recent history
3. **ARCHIVED TASKS** section (bottom) - Old history

### Other Task Files
- `OCC_IMPLEMENTATION_TASKS.md`: Detailed implementation plans
- `BEHAVIOR_RULES.md`: Working style guidelines
- `FRAMEWORK_STATUS.md`: Auto-updated monitoring data

---

## Workflows

### TCC Assigning New Task

1. Update `.ai/STATUS`:
```bash
TASK_STATE=PENDING
TASK_FILE=.ai/CURRENT_TASK.md
TASK_SECTION="Swift Frontend Rebuild"
PRIORITY=1
EFFORT_HOURS=4
ASSIGNED_TO=OCC
SUMMARY="Rebuild Swift MenuBar app with two-column layout"
```

2. Update `.ai/CURRENT_TASK.md` with task details using template

3. (Optional) Create detailed task file like `OCC_IMPLEMENTATION_TASKS.md`

### AI Agent Starting Work

1. Check status:
```bash
./.ai/check-tasks.sh
```

2. If PENDING, read instructions:
```bash
cat .ai/CURRENT_TASK.md
```

3. Update status to IN_PROGRESS:
```bash
sed -i 's/TASK_STATE=PENDING/TASK_STATE=IN_PROGRESS/' .ai/STATUS
```

4. Execute tasks following BEHAVIOR_RULES.md

### AI Agent Completing Work

1. Update STATUS to IDLE:
```bash
sed -i 's/TASK_STATE=IN_PROGRESS/TASK_STATE=IDLE/' .ai/STATUS
sed -i 's/SUMMARY=.*/SUMMARY=""/' .ai/STATUS
```

2. Move task details from "ACTIVE ASSIGNMENT" to "RECENT COMPLETIONS" in CURRENT_TASK.md

3. Commit changes with completion message

---

## Benefits of This System

✅ **Fast Detection:** `source .ai/STATUS` is instant
✅ **Clear Separation:** State vs. instructions
✅ **Flexible:** STATUS points to any instruction file
✅ **Scriptable:** Easy for monitoring tools
✅ **Human-Friendly:** CURRENT_TASK.md readable by TCC
✅ **Historical:** Completed work preserved
✅ **Explicit:** No guessing about what to do next

---

## Best Practices

1. **Always check STATUS first** - Don't assume CURRENT_TASK.md has pending work
2. **Update STATE transitions** - PENDING → IN_PROGRESS → IDLE
3. **Keep STATUS file in sync** with CURRENT_TASK.md
4. **Use TASK_SECTION** to point to specific sections in long files
5. **Clear SUMMARY** when task completes
6. **Preserve completion history** in CURRENT_TASK.md for context

---

## Example Detection in AI Prompt

```bash
# At session start, AI should run:
source .ai/STATUS 2>/dev/null || TASK_STATE=UNKNOWN

if [ "$TASK_STATE" = "PENDING" ]; then
    echo "📋 Pending task detected - reading instructions..."
    cat "$TASK_FILE"
    # Begin work immediately per BEHAVIOR_RULES.md
fi
```
