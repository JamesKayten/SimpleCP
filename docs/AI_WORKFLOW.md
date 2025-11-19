# AI Collaboration Workflow for SimpleCP

## Project Configuration
**Type:** Python Backend/API
**Language:** python
**Max File Size:** 250 lines
**Test Coverage:** 90%
**Validation Tools:** black,flake8,pytest,pyperclip

## AI Component Roles

### TCC (Test Coordination Component) - Local Claude Code
**Role:** Lightweight Project Manager & Quality Gatekeeper
**Purpose:** Minimize subscription token usage through fast validation checks

**Responsibilities:**
- Quick validation checks (file sizes, basic quality)
- Create concise violation reports
- Act as quality gatekeeper before merges
- Process OCC response files
- **Keep token usage minimal** - this maximizes subscription value

### OCC (Online Claude Component) - Web-based Claude
**Role:** Heavy Coding Workhorse
**Purpose:** Handle complex refactoring and implementation work

**Responsibilities:**
- **Automatically check for pending TCC reports on session start**
- Implement all fixes and refactoring
- Create detailed response documentation
- Handle multi-file complex changes
- Activated by user only when needed (cost control)

## Cost Optimization Strategy

```
TCC (Local - Lightweight) → Creates reports (minimal tokens)
         ↓
User activates OCC only when issues found
         ↓
OCC (Online - Heavy) → Implements fixes (controlled cost)
         ↓
TCC validates fixes → Repeat if needed
```

**Key Benefit:** You control when expensive online AI runs, while local AI handles continuous monitoring cheaply.

---

## "Work Ready" Command Workflow for TCC

When you say **"work ready"** to TCC (Local AI), execute this automated workflow:

### 1. Check AI Communications
**FIRST:** Check for communications from OCC
- Check `docs/ai_communication/` for new files since last run
- Process any `AI_RESPONSE_*.md` files (fixes completed by OCC)
- Process any `AI_UPDATE_*.md` files (general updates/questions)
- Report AI communications to user

### 2. Repository Branch Inspection
- Check for new branches created by OCC
- Use `git fetch` to get latest remote branches
- Identify branches that aren't `main` or previously known

### 3. Validation Check
Apply SimpleCP-specific validation rules:

**File Size Limits:**
- Maximum: 250 lines per file
- Check with: `find backend -name "*.py" -type f | xargs wc -l | awk '$1 > 250 {print "VIOLATION: " $2 " (" $1 " lines)"}'`

**Test Coverage:**
- Minimum: 90% coverage required

**Code Quality Tools:**
- Configured: black,flake8,pytest,pyperclip

### 4. Violation Response
If violations found:
- **STOP** merge process immediately
- Create `docs/ai_communication/AI_REPORT_YYYY-MM-DD.md`
- Include specific remediation instructions
- **Provide OCC activation command to user:**
  ```
  "Activate OCC (Online Claude) - violations detected. Share the repository context."
  ```

### 5. Clean Merge
If all validations pass:
- Merge branch to main
- Push to remote
- Clean up branches
- Report success

---

## OCC Activation Workflow (IMPORTANT)

When user starts a new OCC session, **OCC MUST automatically**:

### Step 1: Proactive Check (Automatic)
```
1. Immediately check docs/ai_communication/ folder
2. Look for AI_REPORT_*.md files
3. Identify most recent TCC report
4. Check if there's an AI_RESPONSE_*.md for that report already
```

### Step 2: Decision Tree
```
IF pending TCC report exists (no matching AI_RESPONSE):
  → "Found TCC report from [date] with [X] violations. Starting work..."
  → Begin implementing fixes immediately
  → Create AI_RESPONSE_*.md
  → Commit and push changes
  → Report completion

ELSE IF all reports have responses:
  → "No pending TCC reports. Repository is clean."
  → Ask user what to work on

ELSE IF no reports at all:
  → "No TCC reports found. TCC hasn't run validation yet."
  → Suggest user run "work ready" with TCC first
```

### Step 3: Work Execution (If Violations Found)
```
1. Read TCC report thoroughly
2. Identify all violations and requirements
3. Plan refactoring approach
4. Implement all fixes
5. Create comprehensive AI_RESPONSE_YYYY-MM-DD.md
6. Commit with clear messages
7. Push to branch
8. Report to user: "All violations resolved. Ready for TCC re-validation."
```

**CRITICAL:** OCC should NEVER create its own validation reports. That's TCC's job.

---

## Project-Specific Validation Commands

```bash
# File size check (TCC runs this)
find backend -name "*.py" -type f | xargs wc -l | sort -rn | head -20

# Code quality (if TCC wants to check)
black --check backend/
flake8 --max-line-length=88 backend/
pytest --cov=backend --cov-report=term-missing --cov-fail-under=90
```

---

## Complete Workflow Example

### Cycle 1: Initial Violations
```
1. User to TCC: "work ready"
2. TCC: Checks files, finds 3 violations
3. TCC: Creates AI_REPORT_2025-11-19.md
4. TCC: "Found 3 violations. Activate OCC to fix."
5. User opens OCC session (web Claude)
6. OCC: (Automatically checks folder)
7. OCC: "Found TCC report from 2025-11-19 with 3 violations. Starting work..."
8. OCC: Refactors 3 files, creates AI_RESPONSE_2025-11-19.md
9. OCC: Commits and pushes
10. OCC: "All violations resolved. Ready for TCC re-validation."
```

### Cycle 2: Re-validation
```
1. User to TCC: "work ready"
2. TCC: Reads AI_RESPONSE_2025-11-19.md
3. TCC: "OCC completed fixes for 3 violations. Validating..."
4. TCC: Re-runs validation checks
5. TCC: "All checks pass ✅. Merging to main."
6. TCC: Merges branch, cleans up
7. Done!
```

---

## Key Principles

1. **TCC stays lightweight** - Quick checks, concise reports only
2. **OCC proactively checks for work** - No manual coordination needed
3. **User controls OCC activation** - Cost optimization
4. **Complete audit trail** - All AI decisions documented
5. **Zero copy-paste** - Repository is communication channel

---

## For Framework Users

This workflow optimizes AI collaboration costs:
- **Local AI (TCC):** Fast, cheap validation checks
- **Online AI (OCC):** Heavy implementation work, activated only when needed
- **You:** Control costs by activating OCC only when TCC finds issues

**Result:** Maximum development velocity with optimized AI subscription costs.

---

**Project**: SimpleCP (Python Backend/API)
**Framework**: AI Collaboration Framework v1.1
**Parameters**: File size: 250 lines, Coverage: 90%, Tools: black,flake8,pytest,pyperclip
**Updated**: 2025-11-19 - Added cost optimization strategy and OCC proactive behavior
