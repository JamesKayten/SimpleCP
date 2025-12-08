# SimpleCP Project Structure

Comprehensive overview of the professional project structure.

## Directory Layout

```
SimpleCP/
├── .github/                      # GitHub-specific files
│   ├── workflows/                # GitHub Actions CI/CD
│   │   ├── ci.yml               # Main CI pipeline
│   │   ├── release.yml          # Release automation
│   │   └── dependency-update.yml # Automated dependency updates
│   └── ISSUE_TEMPLATE/          # Issue templates
│
├── backend/                      # Python Backend
│   ├── api/                     # REST API implementation
│   │   ├── __init__.py
│   │   ├── models.py            # Pydantic data models
│   │   ├── endpoints.py         # API route handlers
│   │   └── server.py            # FastAPI application
│   ├── config/                  # Configuration files
│   │   └── config.json          # Runtime configuration
│   ├── data/                    # Data storage
│   │   ├── snippets.json        # Saved snippets
│   │   └── example_*.json       # Example files (committed)
│   ├── logs/                    # Application logs (gitignored)
│   ├── monitoring/              # Monitoring and metrics
│   │   ├── __init__.py
│   │   ├── metrics.py           # Metrics collection
│   │   └── health.py            # Health checks
│   ├── stores/                  # Data stores
│   │   ├── __init__.py
│   │   ├── clipboard_item.py    # Data model
│   │   ├── history_store.py     # History management
│   │   └── snippet_store.py     # Snippet management
│   ├── tests/                   # Backend-specific tests
│   ├── clipboard_manager.py     # Core clipboard logic
│   ├── daemon.py                # Background daemon (API + clipboard monitor)
│   ├── logger.py                # Logging infrastructure
│   ├── main.py                  # Entry point (API only)
│   ├── monitoring_core.py       # Monitoring and analytics
│   ├── settings.py              # Configuration management
│   ├── requirements.txt         # Backend dependencies
│   └── requirements-dev.txt     # Dev dependencies
│
├── frontend/                     # Swift macOS Frontend
│   └── SimpleCP-App/            # Xcode project
│       ├── SimpleCP.xcodeproj/  # Xcode project file
│       └── SimpleCP/            # Swift source code
│           ├── SimpleCPApp.swift      # App entry point
│           ├── AppDelegate.swift      # App delegate
│           ├── Components/            # UI components
│           │   ├── FolderView.swift
│           │   ├── RecentClipsColumn.swift
│           │   ├── SavedSnippetsColumn.swift
│           │   └── ...
│           ├── Managers/              # State managers
│           │   ├── ClipboardManager.swift
│           │   └── ...
│           ├── Models/                # Data models
│           │   ├── ClipItem.swift
│           │   ├── Snippet.swift
│           │   └── ...
│           ├── Services/              # Backend communication
│           │   ├── APIClient.swift
│           │   ├── BackendService.swift
│           │   └── ...
│           ├── Views/                 # SwiftUI views
│           │   ├── ContentView.swift
│           │   ├── SettingsWindow.swift
│           │   └── ...
│           ├── Utils/                 # Utilities
│           ├── Info.plist             # App configuration
│           └── SimpleCP.entitlements  # App permissions
│
├── scripts/                      # Utility scripts
│   ├── install.sh               # Installation script
│   ├── setup_dev.sh             # Development setup
│   ├── build.sh                 # Build script
│   ├── build_python.sh          # Python build
│   ├── build_swift.sh           # Swift build
│   ├── backup.sh                # Backup utility
│   ├── restore.sh               # Restore utility
│   ├── healthcheck.sh           # Health check
│   ├── clean.sh                 # Cleanup script
│   ├── run_tests.sh             # Test runner
│   ├── release.sh               # Release script
│   ├── ai-tag-release.sh        # AI-assisted releases
│   ├── watch-build.sh           # Build watcher
│   ├── watch-all.sh             # Combined branch + board watcher
│   ├── lib/                     # Shared script libraries
│   │   └── watcher-common.sh   # Common watcher functions
│   ├── aim-launcher.sh          # AIM launcher
│   ├── tcc-file-compliance.sh   # TCC compliance
│   ├── tcc-validate-branch.sh   # Branch validation
│   ├── utilities/               # Helper scripts
│   ├── validation/              # Validation scripts
│   └── README.md                # Scripts documentation
│
├── tests/                        # Test suite
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   └── performance/             # Performance tests
│
├── docs/                         # Documentation
│   ├── API.md                   # API reference
│   ├── BOARD.md                 # AIM task board
│   ├── AI_COLLABORATION_GUIDE.md # AI workflow guide
│   ├── MONITORING.md            # Monitoring docs
│   ├── TESTING.md               # Testing guide
│   ├── TROUBLESHOOTING.md       # Troubleshooting
│   ├── USER_GUIDE.md            # User documentation
│   ├── PROJECT_STRUCTURE.md     # This file
│   ├── archive/                 # Archived docs
│   ├── development/             # Development guides
│   └── occ_communication/       # OCC docs
│
├── deployment/                   # Deployment configurations
│   └── systemd/                 # Systemd service
│       ├── simplecp.service
│       └── README.md
│
├── design/                       # Design assets
│
├── .claude/                      # Claude Code configuration
│   ├── commands/                # Custom slash commands
│   └── hooks/                   # Workflow hooks
│
├── .env.example                  # Environment variables template
├── .gitignore                    # Git ignore patterns
├── .pre-commit-config.yaml       # Pre-commit hooks
├── CHANGELOG.md                  # Version history
├── CLAUDE.md                     # AI workflow instructions
├── CONTRIBUTING.md               # Contribution guidelines
├── LICENSE                       # MIT License
├── MANIFEST.in                   # Package manifest
├── Makefile                      # Development commands
├── pyproject.toml                # Python project config
├── pytest.ini                    # Pytest configuration
├── README.md                     # Project README
├── requirements.txt              # Root dependencies
└── setup.py                      # Package setup
```

## Component Overview

### Backend (Python)

| Component | Purpose |
|-----------|---------|
| `api/` | FastAPI REST API implementation |
| `stores/` | Data persistence and models |
| `monitoring/` | Health checks and metrics |
| `clipboard_manager.py` | Core clipboard monitoring logic |
| `daemon.py` | Background service with API server |

### Frontend (Swift/macOS)

| Component | Purpose |
|-----------|---------|
| `SimpleCPApp.swift` | SwiftUI app entry point (MenuBarExtra) |
| `Components/` | Reusable UI components |
| `Services/` | Backend communication layer |
| `Managers/` | State management |
| `Views/` | Main application views |

### Scripts

| Category | Scripts |
|----------|---------|
| **Build** | `build.sh`, `build_python.sh`, `build_swift.sh` |
| **Development** | `setup_dev.sh`, `install.sh` |
| **Testing** | `run_tests.sh`, `healthcheck.sh` |
| **AIM Workflow** | `aim-launcher.sh`, `watch-*.sh`, `tcc-*.sh` |
| **Release** | `release.sh`, `ai-tag-release.sh` |

### Documentation

| Document | Purpose |
|----------|---------|
| `README.md` | Project overview and quick start |
| `QUICKSTART.md` | Fast setup guide |
| `docs/API.md` | Complete API reference |
| `docs/USER_GUIDE.md` | End-user documentation |
| `CONTRIBUTING.md` | Contribution guidelines |
| `CLAUDE.md` | AI collaboration workflow |

## Key Features

### 1. Monorepo Structure
- Backend and frontend in single repository
- Shared scripts and configuration
- Unified versioning and releases

### 2. Professional Python Backend
- FastAPI with async support
- Pydantic models for validation
- Comprehensive test suite
- Metrics and monitoring

### 3. Native macOS Frontend
- SwiftUI menu bar application
- Clean architecture (MVVM-ish)
- Backend service integration
- System permissions handling

### 4. Development Tooling
- Pre-commit hooks for quality
- Makefile for common tasks
- Comprehensive .gitignore
- pytest configuration

### 5. AI Collaboration (AIM)
- TCC/OCC workflow support
- Custom Claude commands
- Branch validation scripts
- Task board integration

### 6. CI/CD Ready
- GitHub Actions workflows
- Automated testing
- Release automation
- Dependency management

## Getting Started

### Quick Start

```bash
# Clone repository
git clone https://github.com/JamesKayten/SimpleCP.git
cd SimpleCP

# Start backend
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python daemon.py

# Build frontend (separate terminal)
cd frontend/SimpleCP-App
open SimpleCP.xcodeproj
# Build and run in Xcode
```

### Development Setup

```bash
# Full development setup
./scripts/setup_dev.sh

# Run tests
make test

# Format code
make format

# Run linters
make lint
```

## Maintenance

### Regular Tasks

1. **Update dependencies**: Check `requirements.txt` and Swift packages
2. **Run tests**: `./scripts/run_tests.sh`
3. **Backup data**: `./scripts/backup.sh`
4. **Check health**: `./scripts/healthcheck.sh`
5. **Clean artifacts**: `./scripts/clean.sh`

### Code Quality

All changes should:
- Pass all tests (Python and Swift)
- Pass linting checks
- Follow style guidelines
- Include documentation updates
