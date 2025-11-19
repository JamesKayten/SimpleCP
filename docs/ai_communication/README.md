# AI Communication Folder for SimpleCP

This folder enables direct **bidirectional communication** between TCC (Local AI) and OCC (Online AI) through the repository.

## AI Component Roles

### TCC (Test Coordination Component) - Local Claude Code
- **Lightweight project manager** keeping token usage minimal
- Runs validation checks and creates concise reports
- Acts as quality gatekeeper
- Maximizes your subscription value

### OCC (Online Claude Component) - Web-based Claude
- **Heavy coding workhorse** for complex implementation
- **Automatically checks this folder when activated**
- Implements all fixes and refactoring
- Activated by you only when needed (cost control)

## Cost Optimization Strategy

```
TCC (cheap) validates → finds issues → creates report
         ↓
You activate OCC only when needed
         ↓
OCC (controlled cost) fixes everything
         ↓
TCC re-validates → merges if clean
```

**You control when expensive online AI runs!**

---

## How It Works

### TCC → OCC Communication Flow

1. **TCC runs "work ready"** (local, fast, cheap)
2. **TCC validates code** against project standards
3. **If violations found:**
   - TCC creates `AI_REPORT_YYYY-MM-DD.md`
   - TCC tells you: "Activate OCC - violations detected"
4. **You open OCC session** (web Claude)
5. **OCC AUTOMATICALLY:**
   - Checks this folder for pending TCC reports
   - Finds `AI_REPORT_YYYY-MM-DD.md` without matching response
   - Says: "Found TCC report from [date] with [X] violations. Starting work..."
   - Implements all fixes
   - Creates `AI_RESPONSE_YYYY-MM-DD.md`
   - Commits and pushes changes
6. **Next "work ready":**
   - TCC reads `AI_RESPONSE_YYYY-MM-DD.md`
   - TCC re-validates to confirm fixes
   - TCC merges if clean

### OCC → TCC Communication Flow

1. **OCC completes work** (fixes, features, refactoring)
2. **OCC creates response file:**
   - `AI_RESPONSE_YYYY-MM-DD.md` - Fixes for specific TCC report
   - `AI_UPDATE_YYYY-MM-DD.md` - General updates or questions
3. **OCC pushes changes** to branch
4. **Next "work ready":**
   - TCC automatically reads OCC's response files
   - TCC reports to you: "OCC completed fixes for 3 violations"
   - TCC validates the changes
   - TCC merges if all checks pass

---

## File Types & Naming Convention

### TCC Creates:
- **`AI_REPORT_YYYY-MM-DD.md`** - Validation issues found
  - Concise, focused on violations
  - Specific remediation instructions
  - Example: AI_REPORT_2025-11-19.md

### OCC Creates:
- **`AI_RESPONSE_YYYY-MM-DD.md`** - Fixes completed for specific TCC report
  - References the AI_REPORT it's responding to
  - Detailed explanation of what was fixed
  - Same date as the report it responds to

- **`AI_UPDATE_YYYY-MM-DD.md`** - General updates or questions
  - For communications not tied to specific violations

- **`AI_REQUEST_YYYY-MM-DD.md`** - Requests for TCC actions
  - Rare, for special coordination needs

**Dating Rule:** Use same date (YYYY-MM-DD) for request/response pairs

---

## OCC Proactive Behavior (CRITICAL)

When you start a new OCC session, **OCC automatically executes this check:**

```
1. Check docs/ai_communication/ folder
2. Find all AI_REPORT_*.md files
3. Identify most recent report
4. Check if matching AI_RESPONSE_*.md exists

IF report exists without response:
  → "Found TCC report from [date] with [X] violations. Starting work..."
  → Read report, implement fixes, create response, push

ELSE IF all reports have responses:
  → "No pending TCC reports. Repository is clean."

ELSE IF no reports at all:
  → "No TCC reports found. Run 'work ready' with TCC first."
```

**No manual "Check docs/ai_communication/" command needed!** OCC does this automatically.

---

## Commands

### For You (Developer):

**To TCC (Local):**
```bash
"work ready"
```
TCC validates, creates report if issues found, tells you to activate OCC.

**To OCC (Online):**
Just start a new session - OCC automatically checks for pending work!

Alternative explicit command (if needed):
```
"Check docs/ai_communication/ for latest report and address the issues"
```

### For TCC (Local AI):
- Run "work ready" workflow
- Check for OCC response files FIRST
- Report OCC communications to user
- Create AI_REPORT if violations found
- Keep reports concise (minimize tokens)

### For OCC (Online AI):
- **Automatically check for pending TCC reports on session start**
- Read latest AI_REPORT file thoroughly
- Implement all required changes
- Create detailed AI_RESPONSE file
- Never create validation reports (that's TCC's job)
- Push changes when done

---

## Communication File Templates

### AI_REPORT_YYYY-MM-DD.md (TCC Creates):
```markdown
# Validation Report for SimpleCP
**Date:** 2025-11-19
**Reporter:** TCC (Test Coordination Component)
**Status:** 🚨 ISSUES FOUND

## Summary
[Brief overview - keep concise]

## Violations Found

### 🔴 CRITICAL - File Size Violation
- **File:** `backend/api/endpoints.py`
- **Current:** 277 lines
- **Required:** 250 lines maximum
- **Action:** Refactor into modular routers

## Required Actions for OCC
1. [Specific task 1]
2. [Specific task 2]

## Ready for OCC Implementation
All violations documented. OCC should implement fixes.
```

### AI_RESPONSE_YYYY-MM-DD.md (OCC Creates):
```markdown
# Response to TCC Validation Report
**Date:** 2025-11-19
**Reporter:** OCC (Online Claude Component)
**Reference:** AI_REPORT_2025-11-19.md
**Status:** ✅ ALL VIOLATIONS RESOLVED

## Summary
[Brief overview of fixes]

## Fixes Completed

### ✅ Violation 1: endpoints.py Refactored
- **Original:** 277 lines
- **Result:** 30 lines (modular architecture)
- **Files Created:**
  - history_routes.py (60 lines)
  - snippet_routes.py (91 lines)
  - folder_routes.py (39 lines)
  - misc_routes.py (75 lines)
- **Status:** All files under 250-line limit ✅

## Verification
[Test results, line counts, etc.]

## Ready for TCC Re-validation
All violations resolved. Ready for TCC to validate and merge.
```

---

## Workflow Example

### Complete Cycle:

```
1. Developer: "work ready" → TCC
2. TCC: Validates files
3. TCC: Finds 3 violations
4. TCC: Creates AI_REPORT_2025-11-19.md
5. TCC: "Found 3 violations. Activate OCC."

6. Developer: Opens OCC session (web Claude)
7. OCC: (Automatically checks folder)
8. OCC: "Found TCC report from 2025-11-19 with 3 violations. Starting work..."
9. OCC: Reads report thoroughly
10. OCC: Refactors 3 files
11. OCC: Creates AI_RESPONSE_2025-11-19.md
12. OCC: Commits and pushes
13. OCC: "All violations resolved. Ready for TCC re-validation."

14. Developer: "work ready" → TCC
15. TCC: "OCC completed fixes for 3 violations. Validating..."
16. TCC: Reads AI_RESPONSE_2025-11-19.md
17. TCC: Re-runs validation checks
18. TCC: "All checks pass ✅"
19. TCC: Merges branch to main
20. TCC: "Merge complete. Repository clean."

Done! Zero manual coordination.
```

---

## Project-Specific Configuration

### SimpleCP Validation Rules
See `VALIDATION_RULES.md` in this folder for:
- File size limits (250 lines)
- Code quality standards
- Security requirements
- Testing thresholds (90% coverage)
- Performance criteria

---

## Benefits

### For Developers:
- ✅ **Cost optimization** - Control when expensive online AI runs
- ✅ **Continuous monitoring** - Local AI watches your code constantly
- ✅ **Zero manual coordination** - AIs communicate through repository
- ✅ **Complete audit trail** - All decisions documented
- ✅ **Maximized subscription value** - Local AI stays lightweight

### For AI Collaboration:
- ✅ **Proactive OCC behavior** - Automatically picks up work
- ✅ **Clear role separation** - TCC validates, OCC implements
- ✅ **Bidirectional communication** - Both directions automated
- ✅ **Structured protocols** - Consistent file formats
- ✅ **Scalable pattern** - Works for teams and complex projects

---

## Framework Philosophy

**Old Model:** You manually copy issues to online AI, paste back fixes
**New Model:** Repository is the communication channel

**Cost Strategy:**
- TCC (local): Fast checks, minimal tokens → cheap continuous monitoring
- OCC (online): Heavy work, activated only when needed → controlled costs
- You: Maximum control over when to spend subscription tokens

**Result:** Professional AI-assisted development at optimized cost.

---

**Project**: SimpleCP
**Framework**: AI Collaboration Framework v1.1
**Updated**: 2025-11-19 - Added OCC proactive behavior and cost optimization
