# Repository Sync Protocol (MANDATORY)

**Last Updated:** 2025-11-24 (v2.0 - Streamlined)
**Applies To:** All AI agents (TCC, OCC)
**Priority:** CRITICAL - Blocks work if not executed

---

## 🚨 THE RULE: SCRIPTS OVER CLAIMS

**Problem:** AI claims "I synced" without proof.
**Solution:** Execute scripts. Show output. Proof required.

---

## 📋 PROTOCOL 1: PRE-WORK SYNC (Before ANY Work)

**COMMAND:**
```bash
bash .ai-framework/scripts/pre-work-sync.sh
```

**WHEN:**
- Start of every session
- Before reading/changing files
- After long inactivity

**MUST SHOW:**
- All verification steps (✅)
- "PRE-WORK SYNC COMPLETE"
- Sync status
- Commit hash

**IF FAILS:** STOP. Show error. Request user guidance. DO NOT proceed.

---

## 📋 PROTOCOL 2: POST-WORK SYNC (After ANY Changes)

**COMMAND:**
```bash
bash .ai-framework/scripts/post-work-sync.sh "Description of work"
```

**WHEN:**
- After completing tasks
- Before ending session
- After making file changes
- Before claiming "done"

**MUST SHOW:**
- Staged files list
- Commit confirmation
- Push confirmation
- "POST-WORK SYNC COMPLETE"

**IF FAILS:** STOP. Show error. DO NOT claim work complete. Retry or request help.

---

## 🔄 SESSION CONTINUITY (Optional - For Long Sessions)

### Setup (start of session):
```bash
source .ai-framework/scripts/session-logging.sh
init_session_log "TCC" "Task description"
```

### During work:
```bash
log_progress "Action" "Details"
checkpoint "Milestone"
```

### Recovery (after disconnection):
```bash
source .ai-framework/scripts/session-logging.sh
check_incomplete_session
get_last_state 50
```

---

## 🚫 VIOLATIONS

| Violation | Example |
|-----------|---------|
| Claim without proof | "I synced the repository" ← NO |
| Run without showing | "I ran the script" ← NO |
| Skip pre-sync | "I'll sync later" ← NO |
| Skip post-sync | "Changes not pushed yet" ← NO |

**Correct approach:**
```bash
$ bash .ai-framework/scripts/pre-work-sync.sh
[FULL OUTPUT SHOWN]
✅ Repository ready
```

---

## ✅ SUCCESS CRITERIA

### Pre-Work Sync Complete:
- [ ] `bash .ai-framework/scripts/pre-work-sync.sh` executed
- [ ] Complete output shown
- [ ] "PRE-WORK SYNC COMPLETE" displayed
- [ ] Status: ✅ SUCCESS

### Post-Work Sync Complete:
- [ ] `bash .ai-framework/scripts/post-work-sync.sh "message"` executed
- [ ] Complete output shown
- [ ] Commit confirmed
- [ ] Push confirmed
- [ ] "POST-WORK SYNC COMPLETE" displayed

---

## 🔧 SCRIPT LOCATIONS

```
.ai-framework/scripts/
├── pre-work-sync.sh      ← Run BEFORE work
├── post-work-sync.sh     ← Run AFTER work
└── session-logging.sh    ← For continuity
```

---

## 🎓 CORE PRINCIPLE

**Scripts over instructions.**
**Verification over claims.**
**Proof over promises.**

**If you can't show the output, you didn't do the work.**

---

**Enforcement:** Not running these scripts = RULE VIOLATION. Work considered INCOMPLETE.
