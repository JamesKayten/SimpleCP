# AI STARTUP PROTOCOL - Execute Every Session

**Last Updated:** 2025-11-24 (v2.0 - Streamlined)
**Applies To:** All AI instances (TCC, OCC, specialized agents)
**Execution Time:** 2-3 minutes

---

## 🚀 STARTUP SEQUENCE (Execute in Order)

### STEP 0: Check for Incomplete Session

```bash
source .ai-framework/scripts/session-logging.sh
check_incomplete_session
```

**If incomplete session found:**
```bash
get_last_state 50  # Show last 50 lines
```
**Ask user:** "Incomplete session detected. Resume (1), View full log (2), or Start fresh (3)?"

**If no incomplete session:** Continue to Step 1

---

### STEP 1: Acknowledge Rules

**Say:** "Rules confirmed - holistic approach enabled"

**Read (scan quickly):**
- `rules/GENERAL_AI_RULES.md` - Verification-first protocol
- `rules/REPOSITORY_SYNC_PROTOCOL.md` - Sync requirements

---

### STEP 2: Discover Project Context

```bash
pwd                         # Current directory
ls .ai/                    # Framework files check
cat BOARD.md               # Current status
cat .ai/CURRENT_TASK.md    # Task details (if exists)
```

**TCC-specific:** Run `/check-the-board` first

---

### STEP 3: Repository Sync (MANDATORY)

```bash
bash .ai-framework/scripts/pre-work-sync.sh
```

**MUST show complete output including:**
- All verification steps
- "PRE-WORK SYNC COMPLETE"
- Sync status
- Commit hash

**If sync fails:** STOP. Show error. Request user intervention.

---

### STEP 4: Check Process Environment

```bash
# Check common ports
lsof -ti:8000              # Backend
lsof -ti:8080              # Frontend

# Check running processes
ps aux | grep -E "(python3|node|SimpleCP)" | grep -v grep
```

**Kill conflicts if found. Prepare clean environment.**

---

### STEP 5: Check Project-Specific Rules

```bash
cat .ai/PROJECT_RULES.md   # If exists
```

**Integration:**
- GENERAL_AI_RULES.md = Base (cannot override)
- PROJECT_RULES.md = Additional specifics

---

## ✅ STARTUP COMPLETE CHECKLIST

Execute before starting work:

- [ ] Rules acknowledged: "Rules confirmed - holistic approach enabled"
- [ ] Sync verified: `bash .ai-framework/scripts/pre-work-sync.sh` (output shown)
- [ ] Project context loaded: BOARD.md, CURRENT_TASK.md read
- [ ] Processes checked: Clean environment verified
- [ ] Ready statement: "Ready to [capability summary]"

---

## 🎯 AI-SPECIFIC PROTOCOLS

### TCC (Terminal Claude Code):
1. **ALWAYS start with:** `/check-the-board`
2. Follow BOARD.md instructions
3. Execute standard startup if `/check-the-board` not available

### OCC (Online Claude Code):
1. Execute standard startup
2. Check: `cat .ai/STATUS | grep "ASSIGNED_TO=OCC"`
3. Begin assigned tasks

---

## 🚫 STARTUP FAILURES - Quick Reference

| Issue | Action |
|-------|--------|
| Rules not found | Report to user, use holistic principles |
| Sync fails | STOP. Show error. Request guidance |
| Port conflicts | Kill processes, document persistent services |
| Multiple AIs active | Coordinate via communication.log |

---

## 📊 STARTUP REPORT FORMAT

```
✅ Rules confirmed - holistic approach enabled
📂 Project: [NAME] ([TYPE])
📊 Status: [IDLE/PENDING/IN_PROGRESS/BLOCKED]
🔄 Repository: [SYNCED] - [BRANCH]
🎯 Ready to: [capability summary]
```

---

**Enforcement:** No work begins without completed startup. Sync verification is mandatory.