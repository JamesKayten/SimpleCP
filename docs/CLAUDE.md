# CLAUDE.md - AI Development Workflow

## Overview

SimpleCP uses a **dual-AI development workflow** with two Claude instances collaborating on a shared development branch:

| Instance | Name | Environment | Role |
|----------|------|-------------|------|
| **XC** | Xcode Claude | Xcode AI assistant | Swift/frontend development |
| **DC** | Desktop Claude | Claude Code CLI | Python/backend, scripts, infrastructure |

## Workflow

### Shared Development Branch

Both AIs work on the same `dev` branch (or feature branches as needed). The branch is always accessible to both:

- **XC** sees changes via Xcode's source control
- **DC** sees changes via git in the terminal

### Coordination

1. **Pull before working** - Always fetch latest changes before starting work
2. **Commit frequently** - Small, focused commits with clear messages
3. **Push when done** - Make changes available to the other AI immediately
4. **Communicate via commits** - Commit messages should explain intent

### Typical Flow

```
DC: git pull origin dev
DC: [makes backend changes]
DC: git commit -m "Add new API endpoint for X"
DC: git push origin dev

XC: [pulls latest]
XC: [updates Swift code to use new endpoint]
XC: [commits and pushes]

DC: git pull origin dev
DC: [continues work...]
```

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
- API runs on port 8000 by default
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

# Frontend
open frontend/SimpleCP-App/SimpleCP.xcodeproj  # Open in Xcode
./scripts/build-and-run.sh              # Build and launch app

# General
make test                               # Run all tests
make lint                               # Check code quality
```
