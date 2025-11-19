# OCC Communication Folder (Bidirectional)

This folder enables direct **bidirectional communication** between Local Claude Code and Online Claude Code (OCC) through the repository.

## How It Works

### Local Claude Code → OCC
When Local Claude Code runs "file ready" and finds violations:
1. Creates `VIOLATION_REPORT_YYYY-MM-DD.md` with detailed findings
2. User activates OCC with: "Check docs/occ_communication/ for latest violation report and fix the issues"

### OCC → Local Claude Code
When OCC has updates to share:
1. Creates response files (see File Types below)
2. Local Claude Code automatically processes these during next "file ready" run
3. Reports OCC communications to user before proceeding with branch inspection

### File Types & Naming Convention
**Local Claude Code creates:**
- `VIOLATION_REPORT_YYYY-MM-DD.md` - Issues found during branch inspection

**OCC creates:**
- `VIOLATION_RESPONSE_YYYY-MM-DD.md` - Fixes completed for specific violation report
- `OCC_UPDATE_YYYY-MM-DD.md` - General updates or questions
- `MERGE_REQUEST_YYYY-MM-DD.md` - Request specific branch merges after validation

**Dating:** Use same date for request/response pairs

## Commands

### For User (to activate OCC):
```
"Check docs/occ_communication/ for latest violation report and fix the issues"
```

### For Local Claude Code:
- **Reads OCC communications FIRST** during "file ready" workflow
- Auto-generates violation reports when violations detected
- Creates timestamped files with specific remediation instructions
- Reports all OCC communications to user before proceeding

### For OCC:
- Read latest VIOLATION_REPORT file
- Implement required refactoring
- Create VIOLATION_RESPONSE file confirming completion
- Create UPDATE/MERGE_REQUEST files for other communications
- Push updated branches for re-validation

## Workflow Example
1. **"file ready"** → Local Claude Code checks communication folder first
2. **Processes any OCC files** → Reports to user: "OCC completed fixes for api/server.py..."
3. **Checks branches** → Validates file sizes
4. **Result:** Either merges clean branches or creates new violation reports

## Benefits
- ✅ **Bidirectional communication** - Both directions automated
- ✅ **No copy/paste needed** - Direct repository-based exchange
- ✅ **Timestamped audit trail** - Complete communication history
- ✅ **Clear action items and responses** - Structured format
- ✅ **Automated workflow integration** - Seamless process