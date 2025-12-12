# CLAUDE.md - AI Development Workflow

## Overview

SimpleCP uses a **dual-AI development workflow** with two Claude instances working on the same local files:

| Instance | Name | Environment | Role |
|----------|------|-------------|------|
| **XC** | Xcode Claude | Xcode AI assistant | Swift/frontend development |
| **DC** | Desktop Claude | Claude Code CLI | Python/backend, scripts, infrastructure |

## Development Flow

### Key Principle: Same Local Files

Both XC and DC edit the **same files on disk**. No commit/push needed to see each other's changes - edits are visible instantly.

### Standard Development Cycle

```
1. DC edits code on `dev` branch
2. User tests in Xcode (Cmd+B to build, Cmd+R to run)
3. If it works → commit and merge to main
4. If not → DC fixes, user rebuilds
```

### When to Commit

- **Don't commit** until changes are tested and working
- **Do commit** when a feature/fix is complete and verified
- After commit → merge `dev` to `main` → push

### Git is for Checkpoints, Not Coordination

Git commits are snapshots for history/backup. The actual files exist independently of git. Use commits to:
- Save working states
- Sync to GitHub (backup)
- Merge tested code to main

## Responsibilities

### XC (Xcode Claude)
- Swift/SwiftUI frontend code
- Xcode project configuration
- macOS-specific features
- UI/UX implementation

### DC (Desktop Claude)
- Python backend code
- FastAPI endpoints
- Shell scripts and tooling
- Documentation
- Git operations and branch management
- CI/CD configuration

## Guidelines

### For Both AIs

1. **Read before writing** - Understand existing code before modifying
2. **Keep commits atomic** - One logical change per commit
3. **Test your changes** - Run relevant tests before pushing
4. **Don't break the build** - Ensure code compiles/runs before pushing

### Conflict Resolution

If merge conflicts occur:
1. The AI encountering the conflict resolves it
2. Prefer the most recent intentional change
3. When uncertain, preserve both changes and note in commit message

## Project Context

### Backend (Python)
- Entry point: `backend/daemon.py` or `backend/main.py`
- API runs on port 49917 by default
- Uses FastAPI with Pydantic models

### Frontend (Swift)
- Xcode project: `frontend/SimpleCP-App/SimpleCP.xcodeproj`
- Menu bar app using SwiftUI
- Communicates with backend via REST API

### Key Commands

```bash
# Backend
cd backend && python daemon.py          # Run backend daemon
cd backend && python -m pytest          # Run backend tests

# Frontend (use Xcode)
open frontend/SimpleCP-App/SimpleCP.xcodeproj  # Open in Xcode
# Build and run from Xcode (Cmd+R)
```
