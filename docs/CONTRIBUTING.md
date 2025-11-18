# Contributing to SimpleCP

Thank you for considering contributing to SimpleCP! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Keep discussions professional

## Getting Started

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/SimpleCP.git
cd SimpleCP
```

### 2. Setup Development Environment

```bash
# Run the development setup script
./scripts/setup_dev.sh

# Or manually:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-dev.txt
pre-commit install
```

### 3. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

## Development Workflow

### 1. Make Changes

- Follow the existing code style
- Write clear, descriptive commit messages
- Keep commits focused and atomic
- Add tests for new features
- Update documentation as needed

### 2. Code Quality

Before committing, ensure:

```bash
# Format code
make format

# Run linters
make lint

# Run tests
make test

# Or run pre-commit hooks
pre-commit run --all-files
```

### 3. Commit

```bash
git add .
git commit -m "feat: add new feature"
```

Follow conventional commits:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Test additions/changes
- `chore:` - Build process or auxiliary tool changes

### 4. Push and Create PR

```bash
git push origin your-branch-name
```

Then create a Pull Request on GitHub.

## Pull Request Guidelines

### PR Checklist

- [ ] Code follows project style guidelines
- [ ] All tests pass
- [ ] New code has tests
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Commit messages are clear

### PR Description

Include:
- What: Summary of changes
- Why: Motivation and context
- How: Implementation approach
- Testing: How you tested it

## Code Style

### Python Style

- Follow PEP 8
- Use Black for formatting (line length: 88)
- Use type hints where appropriate
- Write docstrings for public APIs

Example:

```python
def add_clip(self, content: str, content_type: str = "text") -> ClipboardItem:
    """
    Add a clipboard item to history.

    Args:
        content: The clipboard content
        content_type: Type of content (text, url, etc.)

    Returns:
        The created ClipboardItem

    Raises:
        ValueError: If content is empty
    """
    if not content:
        raise ValueError("Content cannot be empty")

    item = ClipboardItem(content=content, content_type=content_type)
    self.history_store.add(item)
    return item
```

### Testing

- Write tests for all new features
- Maintain test coverage above 70%
- Use pytest fixtures for common setup
- Name tests clearly: `test_<what>_<condition>_<expected>`

Example:

```python
def test_add_clip_with_empty_content_raises_error():
    """Test that adding empty content raises ValueError."""
    manager = ClipboardManager()
    with pytest.raises(ValueError):
        manager.add_clip("")
```

## Project Structure

```
SimpleCP/
├── api/              # REST API implementation
├── stores/           # Data stores and models
├── config/           # Configuration management
├── monitoring/       # Metrics and health checks
├── tests/           # Test suite
│   ├── unit/        # Unit tests
│   └── integration/ # Integration tests
├── scripts/         # Utility scripts
├── deployment/      # Deployment configs
└── docs/           # Documentation
```

## Testing

### Run All Tests

```bash
make test
```

### Run Specific Tests

```bash
# Unit tests only
pytest tests/unit/

# Specific file
pytest tests/unit/test_history_store.py

# Specific test
pytest tests/unit/test_history_store.py::test_add_item
```

### Coverage

```bash
# Generate coverage report
pytest --cov=. --cov-report=html
open htmlcov/index.html
```

## Documentation

### Updating Documentation

- Keep README.md up to date
- Document all public APIs
- Add examples for complex features
- Update CHANGELOG.md for notable changes

### Building Docs

```bash
# Generate API documentation
cd docs
make html
```

## Common Tasks

### Adding a New Feature

1. Create feature branch
2. Write tests first (TDD)
3. Implement feature
4. Update documentation
5. Run full test suite
6. Create PR

### Fixing a Bug

1. Create fix branch
2. Write test that reproduces bug
3. Fix the bug
4. Verify test passes
5. Create PR

### Adding Dependencies

1. Add to `requirements.txt` or `requirements-dev.txt`
2. Update `pyproject.toml` if needed
3. Document why the dependency is needed
4. Check license compatibility

## Release Process

(For maintainers)

1. Update version in `__init__.py` and `pyproject.toml`
2. Update CHANGELOG.md
3. Create release tag: `git tag v1.0.0`
4. Push tag: `git push origin v1.0.0`
5. GitHub Actions will handle the rest

## Getting Help

- Open an issue for bugs or questions
- Join discussions on GitHub
- Check existing documentation
- Ask in pull request comments

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
