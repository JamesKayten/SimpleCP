# SimpleCP Project Structure

Comprehensive overview of the project structure.

## Directory Layout

```
SimpleCP/
├── .github/                      # GitHub configuration
│   ├── workflows/                # GitHub Actions CI/CD
│   │   ├── ci.yml               # Main CI pipeline
│   │   └── release.yml          # Release automation
│   └── ISSUE_TEMPLATE/          # Issue templates
│
├── backend/                      # Python Backend
│   ├── api/                     # REST API implementation
│   │   ├── __init__.py
│   │   ├── models.py            # Pydantic request/response models
│   │   ├── endpoints.py         # API route handlers
│   │   └── server.py            # FastAPI application setup
│   ├── config/                  # Configuration files
│   ├── data/                    # Data storage (JSON files)
│   ├── logs/                    # Application logs (gitignored)
│   ├── monitoring/              # Monitoring and metrics
│   │   ├── __init__.py
│   │   ├── metrics.py           # Metrics collection
│   │   └── health.py            # Health check endpoints
│   ├── stores/                  # Data stores
│   │   ├── __init__.py
│   │   ├── clipboard_item.py    # ClipboardItem data model
│   │   ├── history_store.py     # Clipboard history management
│   │   └── snippet_store.py     # Snippet/folder management
│   ├── clipboard_manager.py     # Core clipboard orchestration
│   ├── daemon.py                # Main entry point (daemon + API)
│   ├── settings.py              # Pydantic settings management
│   ├── logger.py                # Structured logging setup
│   ├── requirements.txt         # Production dependencies
│   └── requirements-dev.txt     # Development dependencies
│
├── frontend/                     # Swift macOS Frontend
│   └── SimpleCP-App/            # Xcode project
│       ├── SimpleCP.xcodeproj/  # Xcode project file
│       └── SimpleCP/            # Swift source code
│           ├── SimpleCPApp.swift      # App entry point
│           ├── AppDelegate.swift      # App delegate
│           ├── Components/            # Reusable UI components
│           ├── Managers/              # State managers
│           ├── Models/                # Data models
│           ├── Services/              # Backend communication
│           ├── Views/                 # SwiftUI views
│           ├── Utils/                 # Utilities
│           └── Info.plist             # App configuration
│
├── scripts/                      # Utility scripts
│   ├── build-and-run.sh         # Build and launch app
│   ├── build.sh                 # General build script
│   ├── build_python.sh          # Python package build
│   ├── install.sh               # Installation script
│   ├── setup_dev.sh             # Development environment setup
│   ├── run_tests.sh             # Test runner
│   ├── healthcheck.sh           # Health check utility
│   ├── clean.sh                 # Cleanup build artifacts
│   ├── backup.sh                # Data backup utility
│   ├── restore.sh               # Data restore utility
│   ├── release.sh               # Release script
│   ├── ai-tag-release.sh        # AI-assisted release tagging
│   ├── checkpoint.sh            # Create development checkpoint
│   ├── kill_backend.sh          # Stop backend process
│   ├── watch-build.sh           # File watcher for builds
│   ├── version_manager.sh       # Version management
│   ├── validation/              # Validation scripts
│   │   ├── common.sh            # Shared test utilities
│   │   └── run_all_tests.sh     # Run all validation tests
│   └── README.md                # Scripts documentation
│
├── tests/                        # Test suite
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   ├── performance/             # Performance tests
│   └── conftest.py              # Pytest fixtures
│
├── docs/                         # Documentation
│   ├── API.md                   # REST API reference
│   ├── CLAUDE.md                # AI development workflow (XC/DC)
│   ├── DEPLOYMENT.md            # Deployment guide
│   ├── FEATURE_BACKLOG.md       # Planned features
│   ├── MONITORING.md            # Monitoring and Sentry setup
│   ├── PROJECT_STRUCTURE.md     # This file
│   ├── TESTING.md               # Testing guide
│   ├── TROUBLESHOOTING.md       # Common issues and solutions
│   ├── USER_GUIDE.md            # End-user documentation
│   └── development/             # Development guides
│       └── ARCHITECTURE.md      # Architecture documentation
│
├── deployment/                   # Deployment configurations
│   └── systemd/                 # Systemd service files
│
├── design/                       # Design assets
│
├── .env.example                  # Environment variables template
├── .gitignore                    # Git ignore patterns
├── .pre-commit-config.yaml       # Pre-commit hooks config
├── CHANGELOG.md                  # Version history
├── CONTRIBUTING.md               # Contribution guidelines
├── LICENSE                       # MIT License
├── Makefile                      # Development commands
├── pyproject.toml                # Python project configuration
├── pytest.ini                    # Pytest configuration
├── README.md                     # Project overview
├── QUICKSTART.md                 # Quick start guide
└── requirements.txt              # Root dependencies
```

## Component Overview

### Backend (Python)

| Component | Purpose |
|-----------|---------|
| `api/` | FastAPI REST API with 30+ endpoints |
| `stores/` | Data persistence (history, snippets) |
| `monitoring/` | Health checks and metrics collection |
| `clipboard_manager.py` | Core clipboard monitoring and orchestration |
| `daemon.py` | Background service combining monitor + API |
| `settings.py` | Environment-based configuration |

### Frontend (Swift/macOS)

| Component | Purpose |
|-----------|---------|
| `SimpleCPApp.swift` | SwiftUI app entry (MenuBarExtra) |
| `Components/` | Reusable UI components |
| `Services/` | Backend API communication |
| `Managers/` | State management |
| `Views/` | Main application views |

### Scripts

| Category | Scripts |
|----------|---------|
| **Build** | `build.sh`, `build_python.sh`, `build-and-run.sh` |
| **Development** | `setup_dev.sh`, `install.sh`, `checkpoint.sh` |
| **Testing** | `run_tests.sh`, `healthcheck.sh` |
| **Release** | `release.sh`, `ai-tag-release.sh`, `version_manager.sh` |
| **Maintenance** | `clean.sh`, `backup.sh`, `restore.sh`, `kill_backend.sh` |

### Documentation

| Document | Purpose |
|----------|---------|
| `README.md` | Project overview and quick start |
| `QUICKSTART.md` | 5-minute setup guide |
| `docs/API.md` | Complete REST API reference |
| `docs/USER_GUIDE.md` | End-user documentation |
| `docs/CLAUDE.md` | XC/DC AI development workflow |
| `CONTRIBUTING.md` | Contribution guidelines |

## Development Workflow

SimpleCP uses a **dual-AI workflow** (see `docs/CLAUDE.md`):
- **XC** (Xcode Claude) - Swift/frontend development
- **DC** (Desktop Claude) - Python/backend, scripts, docs

Both work on a shared `dev` branch with frequent commits and pulls.

## Key Commands

```bash
# Backend
cd backend && python daemon.py     # Run backend daemon
cd backend && python -m pytest     # Run backend tests

# Frontend
./scripts/build-and-run.sh         # Build and launch app
open frontend/SimpleCP-App/SimpleCP.xcodeproj  # Open in Xcode

# Development
make test                          # Run all tests
make lint                          # Check code quality
make format                        # Auto-format code
./scripts/setup_dev.sh             # Set up dev environment
```

## Getting Started

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
./scripts/build-and-run.sh
```
