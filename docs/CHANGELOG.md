# Changelog

All notable changes to SimpleCP will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive professional project structure
- Complete testing infrastructure with pytest
- Configuration management with environment variables
- Development tools (Black, isort, flake8, mypy)
- Docker and docker-compose support
- Systemd service configuration
- CI/CD pipeline with GitHub Actions
- Monitoring and health check system
- Utility scripts for common operations
- Pre-commit hooks for code quality

### Changed
- Reorganized project structure for better maintainability
- Enhanced documentation structure

## [1.0.0] - 2024-01-01

### Added
- Initial release
- Python backend with clipboard monitoring
- REST API with FastAPI
- Multi-store architecture (History + Snippets)
- Automatic content type detection
- Full-text search functionality
- Folder-based snippet organization
- Background daemon service
- JSON persistence layer

### Features
- Clipboard history with deduplication
- Snippet management with folders
- REST API endpoints
- Auto-generated OpenAPI documentation
- Health check endpoints
- Statistics and monitoring

## Version History

- **v1.0.0** - Initial stable release
- **v0.1.0** - Initial development version

## Upgrade Guide

### From 0.x to 1.0

1. Backup your data:
   ```bash
   ./scripts/backup.sh
   ```

2. Update dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Update configuration:
   ```bash
   cp .env.example .env
   # Edit .env as needed
   ```

4. Restart service:
   ```bash
   systemctl restart simplecp
   ```

[Unreleased]: https://github.com/JamesKayten/SimpleCP/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/JamesKayten/SimpleCP/releases/tag/v1.0.0
