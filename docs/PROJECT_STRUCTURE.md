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
│   ├── ISSUE_TEMPLATE/          # Issue templates
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── PULL_REQUEST_TEMPLATE.md # PR template
│
├── api/                          # REST API implementation
│   ├── __init__.py              # Package initialization
│   ├── models.py                # Pydantic data models
│   ├── endpoints.py             # API route handlers
│   └── server.py                # FastAPI application
│
├── config/                       # Configuration management
│   ├── __init__.py
│   ├── settings.py              # Centralized settings
│   └── logging_config.py        # Logging configuration
│
├── deployment/                   # Deployment configurations
│   ├── docker/                  # Docker documentation
│   │   └── README.md
│   └── systemd/                 # Systemd service
│       ├── simplecp.service
│       └── README.md
│
├── docs/                         # Documentation
│   ├── api/                     # API documentation
│   │   └── API_REFERENCE.md
│   ├── development/             # Development guides
│   │   └── ARCHITECTURE.md
│   ├── deployment/              # Deployment guides
│   ├── ai_communication/        # AI collaboration docs
│   ├── occ_communication/       # OCC docs
│   ├── CONTRIBUTING.md          # Contribution guidelines
│   ├── CHANGELOG.md             # Version history
│   └── PROJECT_STRUCTURE.md     # This file
│
├── monitoring/                   # Monitoring and metrics
│   ├── __init__.py
│   ├── metrics.py               # Metrics collection
│   └── health.py                # Health checks
│
├── scripts/                      # Utility scripts
│   ├── install.sh               # Installation script
│   ├── setup_dev.sh             # Development setup
│   ├── backup.sh                # Backup utility
│   ├── restore.sh               # Restore utility
│   ├── healthcheck.sh           # Health check
│   ├── clean.sh                 # Cleanup script
│   └── README.md                # Scripts documentation
│
├── stores/                       # Data stores and models
│   ├── __init__.py
│   ├── clipboard_item.py        # Data model
│   ├── history_store.py         # History management
│   └── snippet_store.py         # Snippet management
│
├── tests/                        # Test suite
│   ├── __init__.py
│   ├── conftest.py              # Pytest configuration
│   ├── unit/                    # Unit tests
│   │   ├── __init__.py
│   │   ├── test_clipboard_item.py
│   │   ├── test_history_store.py
│   │   └── test_snippet_store.py
│   └── integration/             # Integration tests
│       ├── __init__.py
│       └── test_api.py
│
├── ui/                           # UI components (minimal)
│   ├── __init__.py
│   └── menu_builder.py
│
├── ai_collaboration_framework/   # AI collaboration tools
│   ├── templates/
│   └── scripts/
│
├── data/                         # Data storage (gitignored)
│   ├── history.json
│   ├── snippets.json
│   └── example_*.json           # Example files (committed)
│
├── logs/                         # Application logs (gitignored)
│
├── .dockerignore                 # Docker ignore patterns
├── .env.example                  # Environment variables example
├── .gitignore                    # Git ignore patterns
├── .pre-commit-config.yaml       # Pre-commit hooks configuration
├── Dockerfile                    # Docker image definition
├── docker-compose.yml            # Docker Compose configuration
├── LICENSE                       # MIT License
├── Makefile                      # Development commands
├── MANIFEST.in                   # Package manifest
├── pyproject.toml                # Modern Python project config
├── pytest.ini                    # Pytest configuration
├── README.md                     # Project README
├── requirements.txt              # Production dependencies
├── requirements-dev.txt          # Development dependencies
├── setup.py                      # Package setup script
│
├── __init__.py                   # Root package initialization
├── clipboard_manager.py          # Core business logic
├── daemon.py                     # Background daemon service
├── main.py                       # Main entry point
└── settings.py                   # Legacy settings (deprecated)
```

## Component Overview

### Core Application

| File/Directory | Purpose |
|----------------|---------|
| `clipboard_manager.py` | Core business logic and clipboard monitoring |
| `daemon.py` | Background daemon service with API server |
| `main.py` | Main application entry point |
| `settings.py` | Legacy settings (deprecated, use `config/`) |

### API Layer

| File | Purpose |
|------|---------|
| `api/models.py` | Pydantic models for request/response validation |
| `api/endpoints.py` | REST API route handlers |
| `api/server.py` | FastAPI application setup |

### Data Layer

| File | Purpose |
|------|---------|
| `stores/clipboard_item.py` | Data model for clipboard items |
| `stores/history_store.py` | Clipboard history management |
| `stores/snippet_store.py` | Snippet organization and management |

### Configuration

| File | Purpose |
|------|---------|
| `config/settings.py` | Centralized configuration with environment variables |
| `config/logging_config.py` | Logging setup and configuration |
| `.env.example` | Environment variables template |

### Testing

| File/Directory | Purpose |
|----------------|---------|
| `tests/unit/` | Unit tests for individual components |
| `tests/integration/` | Integration tests for API |
| `tests/conftest.py` | Shared test fixtures |
| `pytest.ini` | Pytest configuration |

### Development Tools

| File | Purpose |
|------|---------|
| `.pre-commit-config.yaml` | Pre-commit hooks for code quality |
| `pyproject.toml` | Modern Python project configuration |
| `Makefile` | Development commands |
| `requirements-dev.txt` | Development dependencies |

### Deployment

| File/Directory | Purpose |
|----------------|---------|
| `Dockerfile` | Docker image definition |
| `docker-compose.yml` | Docker Compose configuration |
| `deployment/systemd/` | Systemd service configuration |
| `.dockerignore` | Docker build ignore patterns |

### CI/CD

| File | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | Main CI pipeline |
| `.github/workflows/release.yml` | Release automation |
| `.github/workflows/dependency-update.yml` | Dependency updates |

### Documentation

| File | Purpose |
|------|---------|
| `docs/CONTRIBUTING.md` | Contribution guidelines |
| `docs/CHANGELOG.md` | Version history |
| `docs/api/API_REFERENCE.md` | Complete API reference |
| `docs/development/ARCHITECTURE.md` | Architecture documentation |
| `README.md` | Main project documentation |

### Utilities

| File | Purpose |
|------|---------|
| `scripts/install.sh` | Installation automation |
| `scripts/setup_dev.sh` | Development environment setup |
| `scripts/backup.sh` | Data backup utility |
| `scripts/restore.sh` | Data restore utility |
| `scripts/healthcheck.sh` | Health monitoring |
| `scripts/clean.sh` | Cleanup script |

### Monitoring

| File | Purpose |
|------|---------|
| `monitoring/metrics.py` | Metrics collection and reporting |
| `monitoring/health.py` | Health checks and system monitoring |

## Key Features

### 1. Professional Structure
- Clear separation of concerns
- Modular design
- Proper package organization

### 2. Complete Testing
- Unit tests for all components
- Integration tests for API
- Pytest configuration
- Test fixtures and helpers
- Coverage reporting

### 3. Development Tools
- Code formatting (Black, isort)
- Linting (flake8, mypy)
- Security scanning (bandit)
- Pre-commit hooks
- Makefile for common tasks

### 4. Deployment Ready
- Docker support
- Docker Compose
- Systemd service
- Health checks
- Backup/restore scripts

### 5. CI/CD Pipeline
- Automated testing
- Code quality checks
- Security scanning
- Automated releases
- Dependency updates

### 6. Configuration Management
- Environment variables
- Centralized settings
- Example configurations
- Multiple environment support

### 7. Comprehensive Documentation
- Architecture documentation
- API reference
- Contributing guidelines
- Deployment guides
- Change log

### 8. Monitoring & Observability
- Metrics collection
- Health checks
- Logging configuration
- System monitoring

## File Count Summary

- **Python Files**: 30+
- **Configuration Files**: 10+
- **Documentation Files**: 15+
- **Shell Scripts**: 6
- **Test Files**: 5+
- **Total Files**: 70+

## Lines of Code

- **Production Code**: ~2,500 lines
- **Test Code**: ~500 lines
- **Documentation**: ~3,000 lines
- **Configuration**: ~500 lines
- **Total**: ~6,500 lines

## Dependencies

### Production
- fastapi
- uvicorn
- pydantic
- pyperclip

### Development
- pytest
- pytest-cov
- black
- isort
- flake8
- mypy
- bandit
- pre-commit

## Getting Started

### Quick Start

```bash
# Clone repository
git clone https://github.com/JamesKayten/SimpleCP.git
cd SimpleCP

# Run installation script
./scripts/install.sh

# Start daemon
python daemon.py
```

### Development Setup

```bash
# Run development setup
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

1. **Update dependencies**: `make install-dev`
2. **Run tests**: `make test`
3. **Backup data**: `./scripts/backup.sh`
4. **Check health**: `./scripts/healthcheck.sh`
5. **Clean artifacts**: `./scripts/clean.sh`

### Code Quality

All changes should:
- Pass all tests
- Pass linting checks
- Maintain code coverage
- Follow style guidelines
- Include documentation

## Future Enhancements

Planned additions to the structure:
- Database migrations directory
- API versioning structure
- Plugin system directory
- Internationalization files
- Performance benchmarks
- Security audit reports
