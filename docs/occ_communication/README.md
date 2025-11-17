# OCC Communication Folder

This folder enables direct communication between Local Claude Code and Online Claude Code (OCC) through the repository.

## How It Works

### Violation Detection
When Local Claude Code runs "file ready" and finds violations:
1. Creates `VIOLATION_REPORT_YYYY-MM-DD.md` with detailed findings
2. User activates OCC with: "Check docs/occ_communication/ for latest violation report and fix the issues"

### OCC Response
After fixing violations, OCC should create:
1. `VIOLATION_RESPONSE_YYYY-MM-DD.md` confirming fixes
2. Include new line counts and testing results

### File Naming Convention
- `VIOLATION_REPORT_YYYY-MM-DD.md` - Issues found by Local Claude Code
- `VIOLATION_RESPONSE_YYYY-MM-DD.md` - Fixes completed by OCC
- Use same date for request/response pairs

## Commands

### For User (to activate OCC):
```
"Check docs/occ_communication/ for latest violation report and fix the issues"
```

### For Local Claude Code:
- Auto-generates violation reports during "file ready" workflow
- Creates timestamped files with specific remediation instructions

### For OCC:
- Read latest VIOLATION_REPORT file
- Implement required refactoring
- Create VIOLATION_RESPONSE file confirming completion
- Push updated branches for re-validation

## Benefits
- ✅ No copy/paste needed
- ✅ Direct repository-based communication
- ✅ Timestamped audit trail
- ✅ Clear action items and responses
- ✅ Automated workflow integration