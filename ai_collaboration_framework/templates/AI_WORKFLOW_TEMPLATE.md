# AI Collaboration Workflow for {{PROJECT_NAME}}

## "Work Ready" Command Workflow

When the user says **"work ready"** or **"file ready"**, Local AI should execute the following automated workflow:

### 1. Check AI Communications
**FIRST:** Check for any communications from Online AI before processing branches
- Check `docs/ai_communication/` for new files since last run
- Process any `AI_RESPONSE_*.md` files (fixes completed)
- Process any `AI_UPDATE_*.md` files (general updates/questions)
- Process any `AI_REQUEST_*.md` files (specific action requests)
- Report AI communications to user

### 2. Repository Branch Inspection
- Check the repository for any new branches created by Online AI
- Use `git fetch` to ensure we have the latest remote branches
- Use `git branch -r` to list all remote branches
- Identify any new branches that aren't `main` or previously known branches

### 3. Validation Check
Inspect each new branch for violations according to project standards:

**Validation Rules:**
*See `docs/ai_communication/VALIDATION_RULES.md` for project-specific rules*

**Check Process:**
```bash
# For each new branch:
git checkout <branch_name>
# Run validation checks defined in VALIDATION_RULES.md
```

### 4. Alert on Violations & Generate AI Communication
If any validation fails:
- **STOP** the merge process immediately
- Alert the user with specific details:
  - Which files/rules are violated
  - Current metrics vs. limits
  - Exact violations per branch
- **AUTOMATICALLY CREATE** violation report in `docs/ai_communication/AI_REPORT_YYYY-MM-DD.md`
- Include specific remediation instructions and requirements
- Provide user with simple Online AI activation command

### 5. Merge Process (if no violations)
If all validations pass:
```bash
git checkout main
git merge <branch_name>
git push origin main
git branch -d <branch_name>  # Clean up local branch
git push origin --delete <branch_name>  # Clean up remote branch
```

### 6. Report Results
Provide a summary:
- Branches processed
- Validations performed
- Any violations found
- Merge status
- Next steps if needed

## AI Communication System (Bidirectional)

The communication system enables both Local AI and Online AI to exchange information through repository files.

### Local AI → Online AI
**Automated Report Generation:**
- **File Location:** `docs/ai_communication/AI_REPORT_YYYY-MM-DD.md`
- **Content:** Detailed violation analysis, remediation instructions, priorities
- **Timestamp:** Date/time of detection for audit trail

**User Activation Command:**
```
"Check docs/ai_communication/ for latest report and address the issues"
```

### Online AI → Local AI
**Response File Types:**
- `AI_RESPONSE_YYYY-MM-DD.md` - Confirmation of fixes completed
- `AI_UPDATE_YYYY-MM-DD.md` - General updates or questions for Local AI
- `AI_REQUEST_YYYY-MM-DD.md` - Request specific actions or clarifications

**Processing:** During "work ready" workflow, Local AI automatically:
1. **FIRST** checks communication folder for new Online AI files
2. Processes and reports AI communications to user
3. **THEN** proceeds with normal branch inspection

### Communication Protocol
1. **Local AI** detects violations → Creates `AI_REPORT_*`
2. **User** activates Online AI with simple command
3. **Online AI** reads report → Implements fixes → Creates `AI_RESPONSE_*`
4. **User** runs "work ready" → Local AI processes response → Validates fixes
5. **Local AI** merges clean branches or reports remaining issues

### Benefits
- ✅ **Bidirectional communication** - Both directions through repository
- ✅ **No copy/paste required** - All communication via files
- ✅ **Timestamped audit trail** - Complete history of interactions
- ✅ **Automated workflow integration** - Seamless process
- ✅ **Clear action items and responses** - Structured communication

## Quick Reference Commands

```bash
# Check for new branches
git fetch --all
git branch -r --merged origin/main --invert

# Run project-specific validation
# (Define these commands in VALIDATION_RULES.md)

# Merge workflow
git checkout main
git pull origin main
git merge <branch_name>
git push origin main
```

## File Locations
This framework uses:
- `docs/AI_COLLABORATION_FRAMEWORK.md` (framework overview)
- `docs/AI_WORKFLOW.md` (this file - workflow instructions)
- `docs/ai_communication/` (communication folder)
- `docs/ai_communication/VALIDATION_RULES.md` (project-specific rules)

## Integration with {{PROJECT_NAME}}
This workflow supports the collaboration model where:
- Online AI creates feature branches and implements functionality
- Local AI validates code quality and manages repository operations
- Repository serves as the communication channel between AIs
- User orchestrates the collaboration with simple commands

---
**Created**: Auto-generated during framework installation
**Purpose**: Enable AI-to-AI collaboration for {{PROJECT_NAME}} development