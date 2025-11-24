# CLAUDE.md - Mandatory Session Instructions

**This file is read automatically at session start. These rules are NON-NEGOTIABLE.**

---

## CRITICAL: Always Include Context

Every message to the user MUST include:

| Required | Example |
|----------|---------|
| **Repository** | "In **SimpleCP**..." or "In **AI-Collaboration-Management**..." |
| **Branch** | "On branch `claude/fix-xyz-01abc...`" |
| **File paths** | "Updated **SimpleCP/docs/BOARD.md**" |

**NEVER say vague things like:**
- "Two merges remain" (WHERE?)
- "The branch is ready" (WHICH ONE? WHICH REPO?)
- "Check the board" (WHICH BOARD?)

---

## MANDATORY: Completion Reports

When you finish ANY task, give the user this report directly:

```
## WORK COMPLETED

**Repository:** [exact repo name]
**Branch:** [full branch name]

### What was done:
- [action 1]
- [action 2]

### Merged to main:
- [branches merged, or "None"]
- **Commit hash:** [hash of merged commit - REQUIRED for verification]

### Sent back for refactoring:
- [items needing work, or "None"]

### Next action needed:
- [WHO] needs to [DO WHAT] in [WHICH REPO]
```

**Do NOT just write to BOARD.md and leave. TELL THE USER DIRECTLY.**

---

## Role Reminder

- **OCC** = Developer (writes code, commits to feature branches)
- **TCC** = Project Manager (tests, merges to main, manages workflow)

OCC cannot push to main. TCC should not write implementation code.

---

## TCC: Merge Verification (CRITICAL)

Before reporting a merge complete, TCC MUST:
1. `git fetch origin [branch]` to get latest
2. Check branch HEAD hash
3. Merge
4. Report the **exact commit hash** that was merged

This prevents stale merges where OCC pushed new commits during TCC's work.

---

## TCC: Sync Confirmation (CRITICAL)

After ANY merge or sync operation, TCC MUST explicitly confirm:

```
✅ SYNC STATUS
- Local main:  [commit hash]
- Remote main: [commit hash]
- Status: IN SYNC ✓ (or OUT OF SYNC ✗)
```

**Run these commands to verify:**
```bash
git rev-parse HEAD              # Local HEAD
git rev-parse origin/main       # Remote HEAD (after fetch)
git status                      # Should show "up to date with origin/main"
```

**The user MUST see clear confirmation that local and remote are synchronized.**
Do NOT assume sync is complete - VERIFY and REPORT explicitly.

---

## TCC: Board Update Required

After completing ANY task from the board, TCC MUST:
1. Update BOARD.md - mark task as ✅ COMPLETED or remove it
2. Commit and push to main
3. This triggers the board watcher alert so OCC knows work is done

**Do not leave stale tasks on the board.** Close the loop.

---

## AICM Sync Rule

**Any changes to AICM framework files while working in SimpleCP must also be committed to the main AI-Collaboration-Management repository.**

This keeps the main AICM repo up to date with improvements discovered during project work.

TCC is responsible for syncing AICM changes back to the main repo.

---

## Session Start Checklist

1. Read this file (you just did)
2. Check `docs/BOARD.md` for current status
3. Identify which repository you're in
4. Acknowledge your role (OCC or TCC)

---

**If you don't follow these rules, you're wasting the user's time.**
