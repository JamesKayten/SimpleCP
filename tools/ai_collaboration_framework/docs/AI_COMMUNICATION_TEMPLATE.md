# AI Communication Template (Universal)

This template can be copied to any repository to enable Local ↔ Online AI collaboration.

## Setup Instructions

### 1. Copy Framework to New Project
```bash
# In your new project repository:
mkdir -p docs/ai_communication
```

### 2. Copy These Files:
```
docs/AI_COLLABORATION_FRAMEWORK.md    # Framework overview
docs/ai_communication/README.md       # Communication folder instructions
docs/AI_WORKFLOW.md                   # AI workflow document (customize for project)
```

### 3. Customize Validation Rules
Create `docs/ai_communication/VALIDATION_RULES.md`:

```markdown
# Project Validation Rules

## File Size Limits
- [Customize for your project]
- Example: `*.py`: 300 lines max
- Example: `*.js`: 200 lines max

## Code Quality Rules
- [Add your standards]
- Example: Test coverage: 85% minimum
- Example: Complexity: Max 10 per function

## Security Requirements
- [Define security standards]
- Example: No hardcoded secrets
- Example: All dependencies must be current

## Custom Checks
- [Add project-specific validations]
- Example: API documentation required
- Example: Performance benchmarks must pass
```

### 4. Adapt Workflow Document
Copy and customize the workflow document for your project:
- Update validation rules references
- Modify file patterns and limits
- Add project-specific commands
- Configure communication protocols

### 5. Communication File Templates

**AI_REPORT_YYYY-MM-DD.md Template:**
```markdown
# Validation Report
**Date:** YYYY-MM-DD
**Reporter:** [Local/Online AI Name]
**Status:** 🚨 ISSUES FOUND / ✅ ALL CLEAR

## Summary
[Brief overview of findings]

## Issues Found
### 🔴 CRITICAL - [Issue Type]
- **File:** `path/to/file`
- **Issue:** [Description]
- **Required Action:** [Specific fix needed]

## Required Actions
[Numbered list of specific tasks]

## Testing Requirements
[What to verify after fixes]
```

**AI_RESPONSE_YYYY-MM-DD.md Template:**
```markdown
# Response to Validation Report
**Date:** YYYY-MM-DD
**Reporter:** [AI Name]
**Reference:** AI_REPORT_YYYY-MM-DD.md

## Fixes Completed
- ✅ [Issue 1]: [What was done]
- ✅ [Issue 2]: [What was done]

## Testing Results
- [Test results and verification]

## New Line Counts / Metrics
- [Updated measurements]

## Ready for Re-validation
All issues addressed. Requesting re-validation of branches.
```

## Universal Commands

### For User (to activate partner AI):
```
"Check docs/ai_communication/ for latest report and address the issues"
```

### For AI Workflow Trigger:
```
"work ready"  or  "file ready"
```

## Customization Examples

### Python Django Project:
```markdown
# Validation Rules
- Models: 200 lines max
- Views: 150 lines max
- Tests: Required for all views
- Migration files: Auto-generated only
- Security: Django security checklist compliance
```

### React Project:
```markdown
# Validation Rules
- Components: 200 lines max
- Hooks: 100 lines max
- Bundle size: Under 1MB
- Test coverage: 90%
- Accessibility: WCAG 2.1 compliance
```

### Microservice:
```markdown
# Validation Rules
- Service files: 300 lines max
- API response time: Under 100ms
- Dependencies: Security scan required
- Documentation: OpenAPI spec required
- Monitoring: Health check endpoints required
```

## Framework Benefits

This template enables:
- ✅ **Any Project Type**: Adaptable validation rules
- ✅ **Any AI Combination**: Local/Online AI collaboration
- ✅ **Any Repository**: Works with GitHub, GitLab, etc.
- ✅ **Any Standards**: Configurable quality requirements
- ✅ **Continuous Quality**: 24/7 AI code review

---
**Usage**: Copy this template to any project and customize the validation rules for automatic AI collaboration and quality assurance.