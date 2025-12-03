# AI Collaboration Guide for SimpleCP

**Complete guide for AI-assisted development workflows in SimpleCP**

## Overview
This guide covers all aspects of AI collaboration for SimpleCP development, including local Claude Code integration, web-based AI collaboration, and the automated framework for seamless AI coordination.

## Table of Contents
- [Quick Start](#quick-start)
- [AI Collaboration Framework](#ai-collaboration-framework)
- [Claude Code Workflow](#claude-code-workflow)
- [Web Claude Collaboration](#web-claude-collaboration)
- [GitHub Integration](#github-integration)
- [Communication Templates](#communication-templates)
- [Best Practices](#best-practices)

---

## Quick Start

### For Local Development (Claude Code)
```bash
# Initialize or check AI collaboration status
wr                          # Works Ready - check for pending tasks
/check-the-board           # Check current task board

# Common workflows
cd simple-cp-test
claude                     # Start Claude Code session
```

### For Web-based AI Assistance
1. Share repository context via GitHub URL
2. Use structured communication templates (see below)
3. Follow the handover protocols for seamless transitions

---

## AI Collaboration Framework

### Core Concept
- **Repository as Communication Channel**: AIs read/write structured files for coordination
- **Automated Validation**: Configurable rules enforce code quality and standards
- **Bidirectional Workflow**: Each AI can initiate and respond to the other
- **Audit Trail**: Complete history of all AI interactions and decisions

### Universal Workflow
```
1. Local AI runs "works ready" command
2. Checks for communications from Online AI
3. Validates existing code and dependencies
4. Processes pending tasks from BOARD.md
5. Reports status and next actions
```

### File Structure for AI Communication
```
simple-cp-test/
├── docs/
│   └── BOARD.md                    # Main task coordination
├── .claude/
│   ├── commands/                   # Slash commands
│   └── hooks/                      # Automated workflows
└── scripts/
    ├── tcc-validate-branch.sh      # Validation automation
    └── aim-launcher.sh             # Watcher system
```

---

## Claude Code Workflow

### "Works Ready" Command Workflow
When you execute **"wr"** or **"/works-ready"**, Claude Code:

1. **Checks AI Communications**
   - Reviews `docs/BOARD.md` for pending tasks
   - Processes any updates from external AI collaborators
   - Reports current status

2. **Validates Repository State**
   - Runs compliance checks
   - Verifies build status
   - Checks for merge conflicts

3. **Processes Pending Work**
   - Merges validated feature branches
   - Updates documentation
   - Runs automated tests

4. **Reports Results**
   - Summarizes completed actions
   - Identifies next required steps
   - Updates task board

### Available Commands
- `/works-ready` - Full automation check and process
- `/check-the-board` - Review current tasks
- `/merge-to-main` - Validate and merge branches
- `/verify` - Run compliance and validation checks
- `/fix-violations` - Address validation issues

---

## Web Claude Collaboration

### Handover Protocol
When transitioning from web Claude to local Claude Code:

1. **Context Transfer**
   ```
   Repository: simple-cp-test
   Branch: [current branch]
   Task: [specific task description]
   Files modified: [list files]
   Next steps: [action items]
   ```

2. **Task Documentation**
   - Update `docs/BOARD.md` with current status
   - Document any architectural decisions made
   - Note any dependencies or blockers

3. **Code Quality**
   - Ensure all changes follow project patterns
   - Include proper error handling
   - Add appropriate documentation

### Communication Templates
Use these templates for consistent AI collaboration:

#### Task Assignment Template
```markdown
## AI TASK: [Brief Description]

**Assigned to:** [Local/Web AI]
**Priority:** [High/Medium/Low]
**Estimated time:** [time estimate]

### Context
[Background information]

### Requirements
- [ ] Requirement 1
- [ ] Requirement 2

### Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2

### Files to modify
- `path/to/file1.py`
- `path/to/file2.swift`
```

#### Status Update Template
```markdown
## AI STATUS UPDATE

**Task:** [task description]
**Status:** [In Progress/Complete/Blocked]
**Progress:** [percentage or description]

### Completed
- [x] Item 1
- [x] Item 2

### In Progress
- [ ] Item 3

### Blockers
- [Issue description]
```

---

## GitHub Integration

### Branch Workflow
1. **Feature branches**: `claude/feature-name-[session-id]`
2. **Validation**: Automated checks before merge
3. **Clean up**: Remove merged branches automatically

### Collaboration Patterns
- **OCC (Online Claude Code)**: Develops features on branches
- **TCC (Testing/Coordination Claude)**: Validates and merges to main
- **Documentation**: Always update BOARD.md with changes

### Quality Gates
- File size compliance (< 300 lines for most files)
- Pattern validation (no hardcoded paths)
- Test coverage requirements
- Documentation updates

---

## Best Practices

### Code Quality
- Follow existing patterns and conventions
- Keep functions focused and testable
- Add proper error handling and logging
- Update documentation with changes

### AI Coordination
- Always update BOARD.md with task status
- Use clear, specific commit messages
- Test changes before requesting review
- Provide context for complex decisions

### Communication
- Be specific about files and locations
- Include relevant code snippets in discussions
- Document architectural decisions
- Use consistent terminology

### Handover Checklist
- [ ] Repository state is clean (no uncommitted changes)
- [ ] All changes are on appropriate feature branch
- [ ] BOARD.md is updated with current status
- [ ] Next steps are clearly documented
- [ ] Any blockers or dependencies are noted

---

## Troubleshooting

### Common Issues
1. **Merge conflicts**: Use `/verify` to check before requesting merge
2. **Validation failures**: Run `/fix-violations` to address issues
3. **Missing context**: Check BOARD.md and recent commit messages
4. **Build failures**: Review error logs and run local tests

### Getting Help
- Check `docs/TROUBLESHOOTING.md` for technical issues
- Review `docs/BOARD.md` for current project status
- Use `docs/API.md` for backend integration questions
- See `docs/USER_GUIDE.md` for feature documentation

---

*This guide consolidates multiple AI collaboration documents into a single, comprehensive resource for efficient AI-assisted development.*