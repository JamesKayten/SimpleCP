# OCC Verbal Command Reference

**For Online Claude Code (OCC) and Web-based AI Agents**

This document maps natural language commands to framework actions, enabling immediate response to verbal triggers without requiring explicit script paths.

## Core Commands

### "check the board"
**Action**: Execute task detection and report status
```bash
./.ai/check-tasks.sh
```
**Expected Response**:
- If `TASK_STATE=PENDING`: Read `.ai/CURRENT_TASK.md` and begin work immediately
- If `TASK_STATE=IDLE`: Report "No pending tasks"
- If `TASK_STATE=IN_PROGRESS`: Report current task in progress
- If `TASK_STATE=BLOCKED`: Report blockage details

**Behavior**:
- Read task details from `CURRENT_TASK.md`
- Follow `.ai/BEHAVIOR_RULES.md` for execution style
- Update status to `IN_PROGRESS` when starting work
- Execute tasks without asking questions or exploring

### "work ready" / "file ready"
**Action**: Full validation and merge workflow
```bash
# Check OCC communications first
ls docs/occ_communication/

# Then run task detection
./.ai/check-tasks.sh

# For local Claude Code: also check branches for violations
```
**Expected Response**:
- Process any communication files from partner AI
- Check for pending tasks
- Execute assigned work immediately

### "check for tasks"
**Action**: Same as "check the board"
```bash
./.ai/check-tasks.sh
```

### "read my assignment"
**Action**: Display current task details
```bash
cat .ai/CURRENT_TASK.md
```

### "check status"
**Action**: Show current task state
```bash
source .ai/STATUS && echo "State: $TASK_STATE | Assigned to: $ASSIGNED_TO | Priority: $PRIORITY"
```

## Communication Commands

### "check for messages" / "check communications"
**Action**: Look for partner AI communications
```bash
# For OCC working on SimpleCP
ls -la docs/occ_communication/

# For general AI collaboration
ls -la docs/ai_communication/
```

### "check for violations"
**Action**: Look for violation reports from local AI
```bash
ls -la docs/occ_communication/VIOLATION_REPORT_*.md | tail -1
# Then read the latest report
```

## Task Management Commands

### "start work" / "begin task"
**Action**:
1. Update status to IN_PROGRESS
2. Begin executing first task in CURRENT_TASK.md

```bash
sed -i 's/TASK_STATE=PENDING/TASK_STATE=IN_PROGRESS/' .ai/STATUS
```

### "complete task" / "mark done"
**Action**: Update status to IDLE and archive task
```bash
sed -i 's/TASK_STATE=IN_PROGRESS/TASK_STATE=IDLE/' .ai/STATUS
sed -i 's/SUMMARY=.*/SUMMARY=""/' .ai/STATUS
```

### "block task" / "report blocked"
**Action**: Update status to BLOCKED with reason
```bash
sed -i 's/TASK_STATE=IN_PROGRESS/TASK_STATE=BLOCKED/' .ai/STATUS
# Add blocking reason to CURRENT_TASK.md
```

## Quick Reference

| Verbal Command | Script/File | Action |
|---|---|---|
| "check the board" | `.ai/check-tasks.sh` | Detect and report pending tasks |
| "work ready" | Multiple checks | Full workflow execution |
| "read my assignment" | `.ai/CURRENT_TASK.md` | Display task details |
| "check status" | `.ai/STATUS` | Show current state |
| "check for messages" | `docs/*_communication/` | Read partner AI updates |
| "start work" | Update STATUS | Begin task execution |
| "complete task" | Update STATUS | Mark task finished |

## Integration with OCC Sessions

When starting a new OCC session on this repository, **automatically**:

1. **Check the board** (run `.ai/check-tasks.sh`)
2. If PENDING tasks exist, read `CURRENT_TASK.md` immediately
3. Begin work per `BEHAVIOR_RULES.md` without asking permission

## Behavior Guidelines

Per `.ai/BEHAVIOR_RULES.md`, when verbal commands trigger tasks:
- ✅ **START WORK IMMEDIATELY** - No exploration or questions
- ✅ **BE DIRECT** - Execute first specified task without delay
- ✅ **BE CONCISE** - Simple responses, practical answers only
- ✅ **BE EFFICIENT** - Complete tasks quickly
- ✅ **STAY ORGANIZED** - Keep files in logical directories

## Command Aliases

These phrases all map to "check the board":
- "check the board"
- "check board"
- "what's on the board"
- "any tasks for me"
- "check for work"
- "check tasks"
- "is there work pending"

## Environment Detection

This command reference works in:
- ✅ Web Claude Code sessions
- ✅ Claude Code API integrations
- ✅ Any AI agent with repository access
- ✅ Cross-platform (macOS, Linux, containers)

## Framework Version
**Version**: 1.1
**Last Updated**: 2025-11-22
**Purpose**: Enable immediate verbal command recognition for OCC agents

---

**Quick Start**: When you see "check the board", immediately run `.ai/check-tasks.sh` and begin work if tasks are pending.
