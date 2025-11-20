# Natural Language Command Reference

## 🎯 Purpose
This file maps natural language commands to framework operations, enabling intuitive interaction with the AI collaboration system.

## 📋 Command Mappings

### Task & Board Management

**"Check the board"**
```bash
cat .ai/STATUS && cat .ai/CURRENT_TASK.md
```
Shows current task state and detailed instructions.

**"What's my task?"** / **"What should I work on?"**
```bash
cat .ai/CURRENT_TASK.md
```
Displays the current task assignment details.

**"Am I assigned?"** / **"Is there work for me?"**
```bash
source .ai/STATUS && echo "Assigned to: $ASSIGNED_TO | State: $TASK_STATE"
```
Checks if you have pending work assigned.

**"What's the priority?"**
```bash
source .ai/STATUS && echo "Priority: $PRIORITY (1=Critical, 2=High, 3=Normal, 4=Low)"
```
Shows current task priority level.

**"Show task status"**
```bash
./.ai/check-tasks.sh
```
Runs the automated task detection script.

### Work Status Updates

**"Start work"** / **"Begin task"**
```bash
# Update STATUS to IN_PROGRESS
sed -i 's/TASK_STATE=PENDING/TASK_STATE=IN_PROGRESS/' .ai/STATUS
```
Marks task as in progress.

**"Task complete"** / **"Finished"**
```bash
# Update STATUS to IDLE
sed -i 's/TASK_STATE=IN_PROGRESS/TASK_STATE=IDLE/' .ai/STATUS
sed -i 's/SUMMARY=.*/SUMMARY=""/' .ai/STATUS
```
Marks task as complete and clears summary.

**"Blocked"** / **"Need help"**
```bash
# Update STATUS to BLOCKED
sed -i 's/TASK_STATE=.*/TASK_STATE=BLOCKED/' .ai/STATUS
```
Marks task as blocked, requiring attention.

### Communication

**"Check for messages"** / **"Any pings?"**
```bash
cat .ai/PING_TEST.md 2>/dev/null || echo "No messages"
```
Checks for inter-AI communication.

**"Read communications"**
```bash
ls -lt .ai/*.md | head -10
```
Lists recent communication files.

### Framework Information

**"Show framework status"**
```bash
cat .ai/FRAMEWORK_STATUS.md
```
Displays auto-updated framework metrics.

**"Show behavior rules"**
```bash
cat .ai/BEHAVIOR_RULES.md
```
Displays working style requirements.

**"How do I use this?"** / **"Help"**
```bash
cat .ai/FRAMEWORK_USAGE.md
```
Shows complete framework usage guide.

## 🚀 Quick Start Protocol

When you hear natural language like:
- "Check the board"
- "What's my assignment?"
- "Is there work to do?"

**Immediately execute:**
1. `source .ai/STATUS`
2. If `TASK_STATE=PENDING`, read `.ai/CURRENT_TASK.md`
3. Begin work per `BEHAVIOR_RULES.md`

## 🎯 Detection Keywords

AI agents should trigger framework checks when hearing:
- **board**, **task**, **assignment**, **work**
- **status**, **state**, **pending**, **assigned**
- **check**, **what**, **show**, **read**
- **priority**, **urgent**, **critical**

## 💡 Design Philosophy

Natural language commands should:
1. **Map directly** to framework operations
2. **Be intuitive** for both humans and AIs
3. **Avoid ambiguity** in interpretation
4. **Promote efficiency** through clear actions

## 📝 Examples in Context

### Scenario 1: Session Start
```
Human: "Check the board"
AI: *Immediately runs: cat .ai/STATUS && cat .ai/CURRENT_TASK.md*
AI: "Current state: PENDING. Task: Implement feature X. Priority: HIGH"
```

### Scenario 2: Status Check
```
Human: "Am I assigned?"
AI: *Runs: source .ai/STATUS && echo $ASSIGNED_TO*
AI: "Yes, assigned to OCC"
```

### Scenario 3: Work Completion
```
AI: "Task completed. Updating board..."
AI: *Runs: sed -i 's/TASK_STATE=IN_PROGRESS/TASK_STATE=IDLE/' .ai/STATUS*
AI: "Board updated to IDLE"
```

## 🔄 Integration with Existing Framework

This file complements:
- `.ai/BEHAVIOR_RULES.md` - Defines work style
- `.ai/FRAMEWORK_USAGE.md` - Technical documentation
- `.ai/STATUS` - Machine-readable state
- `.ai/CURRENT_TASK.md` - Human-readable instructions

**Key Enhancement:** Bridges the gap between conversational interaction and technical framework operations.

---

**Version:** 1.0
**Created:** 2024-11-20
**Purpose:** Enable natural language framework interaction
