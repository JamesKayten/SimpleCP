# GENERAL AI RULES - Universal Principles

**Last Updated:** 2025-11-24 (v2.0 - Streamlined)
**Applies To:** All AI sessions across all projects
**Priority:** CRITICAL - Execute on startup

---

## 🚨 RULE #1: PROVE EVERYTHING (VERIFICATION-FIRST)

**Every claim requires proof. No proof = violation.**

### After EVERY task show:
1. Exact command executed
2. Complete output
3. Verification evidence

### Mandatory Scripts (MUST show output):
```bash
# Before work:
bash .ai-framework/scripts/pre-work-sync.sh

# After work:
bash .ai-framework/scripts/post-work-sync.sh "Description"
```

### Verification Checklist:
- [ ] Command shown (copy/paste from terminal)
- [ ] Output shown (complete, not summarized)
- [ ] Evidence provided (file counts, git status, test results)

**If you can't show output, task is INCOMPLETE.**

---

## 🎯 RULE #2: HOLISTIC APPROACH

**Before ANY change:**
- [ ] Review entire project (not just immediate problem)
- [ ] Check related components/dependencies
- [ ] Consider downstream effects
- [ ] Test in complete system context

**Never narrow-focus on immediate problem alone.**

---

## ⚡ RULE #3: PROCESS MANAGEMENT (Frontend Testing)

**Before testing frontend changes:**
```bash
# 1. Kill existing processes
pkill -f [AppName]

# 2. Verify clean state
ps aux | grep [AppName] | grep -v grep
# MUST return empty

# 3. Launch new build
[build/launch command]

# 4. Verify new process
ps aux | grep [AppName] | grep -v grep
```

**Testing old builds = violation. Always kill processes first.**

---

## 🔄 RULE #4: REPOSITORY SYNC

**Every session:**
- Run pre-work-sync.sh BEFORE starting
- Run post-work-sync.sh AFTER changes
- Show complete script output
- Verify sync success

**Never work without sync. Never end session without push.**

---

## 📋 RULE #5: EFFICIENCY

- Use TodoWrite for 3+ step tasks
- Mark tasks complete immediately (not batched)
- Simplest solution first
- If task takes 20 min, finish in 20 min
- No overengineering

---

## 🚫 PROHIBITED BEHAVIORS

1. **Narrow Focus** - Changing code without reviewing full project
2. **Testing Without Kill** - Testing without killing old processes
3. **Claims Without Proof** - Saying "I did X" without showing output
4. **Repository Desync** - Working without pre/post sync
5. **Batch Completion** - Marking multiple tasks done without individual verification

---

## ✅ STARTUP CHECKLIST (Every Session)

1. [ ] Acknowledge rules: "Rules confirmed - holistic approach enabled"
2. [ ] Run: `bash .ai-framework/scripts/pre-work-sync.sh` (show output)
3. [ ] Check project status: `.ai/STATUS`, `BOARD.md`, `CURRENT_TASK.md`
4. [ ] Verify clean processes: `ps aux | grep [process]`
5. [ ] Begin work

**Startup incomplete without sync verification.**

---

**Enforcement:** These rules override project-specific instructions. When in doubt, choose holistic approach with verification.