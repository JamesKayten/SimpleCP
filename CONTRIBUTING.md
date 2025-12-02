# Contributing to SimpleCP

Thank you for considering contributing to SimpleCP! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Commit Messages](#commit-messages)
- [Documentation](#documentation)

---

## Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive behavior includes**:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behavior includes**:
- Trolling, insulting/derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information without permission
- Other conduct which could reasonably be considered inappropriate

---

## How Can I Contribute?

### Reporting Bugs

**Before submitting a bug report**:
1. Check the [troubleshooting guide](docs/TROUBLESHOOTING.md)
2. Search [existing issues](https://github.com/YourUsername/SimpleCP/issues)
3. Collect relevant information (see template below)

**Bug Report Template**:
```markdown
**System Information**:
- OS: macOS 13.2
- Python: 3.11.4
- SimpleCP: 1.0.0

**Description**:
Clear description of the bug

**Steps to Reproduce**:
1. Step one
2. Step two
3. See error

**Expected Behavior**:
What you expected to happen

**Actual Behavior**:
What actually happened

**Logs**:
```
Paste relevant logs here
```

**Additional Context**:
Any other relevant information
```

### Suggesting Enhancements

**Before suggesting an enhancement**:
1. Check if it's already planned in [roadmap](README.md#roadmap)
2. Search [existing feature requests](https://github.com/YourUsername/SimpleCP/issues?q=is%3Aissue+label%3Aenhancement)

**Enhancement Template**:
```markdown
**Feature Description**:
Clear description of the proposed feature

**Use Case**:
Why is this feature needed?

**Proposed Solution**:
How should it work?

**Alternatives Considered**:
Other approaches you've thought about

**Additional Context**:
Screenshots, mockups, examples
```

### Your First Code Contribution

**Good first issues**:
- Look for issues labeled `good first issue`
- Documentation improvements
- Test coverage improvements
- Bug fixes with clear reproduction steps

**Getting started**:
1. Fork the repository
2. Clone your fork: `git clone https://github.com/YourUsername/SimpleCP.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test thoroughly
6. Submit a pull request

---

## Development Setup

### Prerequisites

- macOS 10.14+
- Python 3.9+
- Git
- Virtual environment tool

### Setup Steps

```bash
# 1. Fork and clone
git clone https://github.com/YourUsername/SimpleCP.git
cd SimpleCP

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Install development dependencies
pip install pytest pytest-cov ruff black isort mypy

# 5. Create .env file
cp .env.example .env

# 6. Run tests
pytest

# 7. Start daemon
python daemon.py
```

### Project Structure

```
SimpleCP/
├── api/                    # REST API
│   ├── server.py          # FastAPI server
│   ├── endpoints.py       # API routes
│   └── models.py          # Pydantic models
├── stores/                # Data storage
│   ├── clipboard_item.py  # Item model
│   ├── history_store.py   # History management
│   └── snippet_store.py   # Snippet management
├── tests/                 # Test suite
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   └── performance/      # Performance tests
├── docs/                  # Documentation
├── logger.py             # Logging infrastructure
├── monitoring.py         # Monitoring & analytics
├── settings.py           # Configuration
├── clipboard_manager.py  # Main manager
└── daemon.py             # Background daemon
```

---

## Coding Standards

### Python Style Guide

We follow [PEP 8](https://pep8.org/) with some modifications:

**Line length**: 100 characters (not 79)

**Imports**:
```python
# Standard library
import os
import sys

# Third-party
from fastapi import FastAPI
import pytest

# Local
from clipboard_manager import ClipboardManager
from stores.clipboard_item import ClipboardItem
```

**Type hints**:
```python
def function_name(param: str, optional: Optional[int] = None) -> bool:
    """Docstring explaining function."""
    return True
```

**Docstrings**:
```python
def complex_function(param1: str, param2: int) -> dict:
    """
    One-line summary.

    Longer description if needed.

    Args:
        param1: Description of param1
        param2: Description of param2

    Returns:
        Dictionary containing results

    Raises:
        ValueError: If param1 is empty
    """
    pass
```

### Code Formatting

**Use automated tools**:

```bash
# Format code
black .

# Sort imports
isort .

# Lint
ruff check .

# Type check
mypy --ignore-missing-imports .
```

**Pre-commit checks** (recommended):

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

### Best Practices

**DO**:
- ✅ Write tests for new features
- ✅ Update documentation
- ✅ Use type hints
- ✅ Handle errors gracefully
- ✅ Log important events
- ✅ Follow existing patterns

**DON'T**:
- ❌ Commit commented-out code
- ❌ Leave print() statements for debugging
- ❌ Ignore test failures
- ❌ Commit large binary files
- ❌ Break existing tests
- ❌ Hardcode secrets or credentials

---

## Testing

### Running Tests

```bash
# All tests
pytest

# Specific test file
pytest tests/unit/test_clipboard_manager.py

# Specific test
pytest tests/unit/test_clipboard_manager.py::TestClipboardManager::test_add_clip

# With coverage
pytest --cov=. --cov-report=html

# Fast tests only
pytest -m "not slow"

# Watch mode
pytest-watch
```

### Writing Tests

**Test structure**:
```python
import pytest
from clipboard_manager import ClipboardManager


@pytest.mark.unit
class TestClipboardManager:
    """Test ClipboardManager functionality."""

    def test_add_clip(self, clipboard_manager):
        """Test adding clip to history."""
        # Arrange
        content = "Test content"

        # Act
        item = clipboard_manager.add_clip(content)

        # Assert
        assert item is not None
        assert item.content == content
        assert len(clipboard_manager.history_store) == 1
```

**Test requirements**:
- Descriptive test names
- One assertion per test (when possible)
- Use fixtures from `conftest.py`
- Mark tests appropriately (`@pytest.mark.unit`, etc.)
- Test both success and error cases
- Aim for 80%+ coverage

---

## Pull Request Process

### Before Submitting

**Checklist**:
- [ ] Code follows style guide
- [ ] All tests pass (`pytest`)
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] Commit messages follow convention
- [ ] No merge conflicts
- [ ] Code formatted (`black .`, `isort .`)
- [ ] Linting passes (`ruff check .`)

### Submitting PR

1. **Push to your fork**:
```bash
git push origin feature/your-feature-name
```

2. **Create Pull Request**:
   - Go to GitHub repository
   - Click "New Pull Request"
   - Select your branch
   - Fill out PR template

3. **PR Template**:
```markdown
## Description
Brief description of changes

## Related Issue
Fixes #123

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe testing performed

## Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Code formatted
- [ ] Commits follow convention
```

### Review Process

1. **Automated checks** run (CI/CD)
2. **Maintainer review** (usually within 1-3 days)
3. **Address feedback** if requested
4. **Approval and merge**

### After Merge

- Delete your branch
- Update your fork
- Celebrate! 🎉

---

## Commit Messages

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Formatting, no code change
- **refactor**: Code restructuring
- **test**: Adding/updating tests
- **chore**: Build, dependencies, etc.

### Examples

**Simple**:
```
feat: Add search highlighting
```

**With scope**:
```
fix(api): Handle empty clipboard content
```

**With body**:
```
feat(snippets): Add folder reordering

- Add drag-and-drop support
- Update API endpoint
- Add tests for reordering

Closes #45
```

**Breaking change**:
```
feat(api)!: Change response format

BREAKING CHANGE: API responses now include metadata object
```

---

## Documentation

### When to Update Docs

**Always update**:
- New features → User Guide + API docs
- API changes → API.md
- Configuration → User Guide settings section
- Bug fixes → Troubleshooting guide (if relevant)

### Documentation Files

| File | Content |
|------|---------|
| `README.md` | Overview, features, quick start |
| `QUICKSTART.md` | 5-minute setup guide |
| `docs/USER_GUIDE.md` | Complete user manual |
| `docs/API.md` | API reference |
| `docs/TESTING.md` | Testing guide |
| `docs/TROUBLESHOOTING.md` | Common issues |
| `docs/MONITORING.md` | Monitoring setup |
| `CONTRIBUTING.md` | This file |

### Documentation Standards

**DO**:
- ✅ Use clear, simple language
- ✅ Include code examples
- ✅ Add screenshots when helpful
- ✅ Keep updated with code changes
- ✅ Test all examples

**DON'T**:
- ❌ Use jargon without explanation
- ❌ Write overly long paragraphs
- ❌ Include outdated information
- ❌ Forget to update TOC

---

## Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes

Examples:
- `1.0.0` → `1.0.1` (bug fix)
- `1.0.1` → `1.1.0` (new feature)
- `1.1.0` → `2.0.0` (breaking change)

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped
- [ ] Git tag created
- [ ] Release notes written
- [ ] Distribution built

---

## Getting Help

**Questions?**
- GitHub Discussions
- Issue tracker
- Email: dev@simplecp.app

**Want to contribute but not sure how?**
- Look for `good first issue` label
- Ask in discussions
- Review open issues

---

## Recognition

Contributors are recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project README

Thank you for contributing! 🙏
