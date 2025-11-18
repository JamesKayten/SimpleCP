# AI Communication Folder for SimpleCP

This folder enables direct **bidirectional communication** between Local AI and Online AI through the repository.

## How It Works

### Local AI → Online AI
When Local AI runs "work ready" and finds violations:
1. Creates `AI_REPORT_YYYY-MM-DD.md` with detailed findings
2. User activates Online AI with: "Check docs/ai_communication/ for latest report and address the issues"

### Online AI → Local AI
When Online AI has updates to share:
1. Creates response files (see File Types below)
2. Local AI automatically processes these during next "work ready" run
3. Reports AI communications to user before proceeding with validation

### File Types & Naming Convention
**Local AI creates:**
- `AI_REPORT_YYYY-MM-DD.md` - Issues found during validation

**Online AI creates:**
- `AI_RESPONSE_YYYY-MM-DD.md` - Fixes completed for specific report
- `AI_UPDATE_YYYY-MM-DD.md` - General updates or questions
- `AI_REQUEST_YYYY-MM-DD.md` - Request specific actions after validation

**Dating:** Use same date for request/response pairs

## Commands

### For User (to activate Online AI):
```
"Check docs/ai_communication/ for latest report and address the issues"
```

### For Local AI:
- **Reads AI communications FIRST** during "work ready" workflow
- Auto-generates violation reports when issues detected
- Creates timestamped files with specific remediation instructions
- Reports all AI communications to user before proceeding

### For Online AI:
- Read latest AI_REPORT file
- Implement required changes
- Create AI_RESPONSE file confirming completion
- Create UPDATE/REQUEST files for other communications
- Push updated branches for re-validation

## Workflow Example
1. **"work ready"** → Local AI checks communication folder first
2. **Processes any AI files** → Reports to user: "Online AI completed fixes for api.py..."
3. **Checks branches** → Validates according to project rules
4. **Result:** Either merges clean branches or creates new violation reports

## Project-Specific Configuration

### SimpleCP Validation Rules
See `VALIDATION_RULES.md` in this folder for:
- File size limits
- Code quality standards
- Security requirements
- Testing thresholds
- Performance criteria

### Custom Commands
```bash
# Add SimpleCP-specific validation commands here
# Examples:
# npm run lint
# python -m pytest --coverage
# docker build --test
```

## Communication File Templates

### AI_REPORT_YYYY-MM-DD.md Template:
```markdown
# Validation Report for SimpleCP
**Date:** YYYY-MM-DD
**Reporter:** Local AI
**Status:** 🚨 ISSUES FOUND / ✅ ALL CLEAR

## Summary
[Brief overview of findings]

## Issues Found
### 🔴 CRITICAL - [Issue Type]
- **File:** `path/to/file`
- **Issue:** [Description]
- **Current:** [current state]
- **Required:** [required state]
- **Action:** [specific fix needed]

## Required Actions
1. [Specific task 1]
2. [Specific task 2]

## Testing Requirements
[What to verify after fixes]

## Ready for Re-validation
Request re-validation after fixes are complete.
```

### AI_RESPONSE_YYYY-MM-DD.md Template:
```markdown
# Response to Validation Report
**Date:** YYYY-MM-DD
**Reporter:** Online AI
**Reference:** AI_REPORT_YYYY-MM-DD.md

## Fixes Completed
- ✅ [Issue 1]: [What was done]
- ✅ [Issue 2]: [What was done]

## Testing Results
- [Test results and verification]

## Updated Metrics
- [New measurements/line counts]

## Ready for Re-validation
All issues addressed. Requesting re-validation of branches.
```

## Benefits
- ✅ **Bidirectional communication** - Both directions automated
- ✅ **No copy/paste needed** - Direct repository-based exchange
- ✅ **Timestamped audit trail** - Complete communication history
- ✅ **Project integration** - Customized for SimpleCP requirements
- ✅ **Automated workflow** - Seamless AI collaboration process

---
**Project**: SimpleCP
**Framework**: AI Collaboration Framework
**Setup Date**: Auto-generated during installation