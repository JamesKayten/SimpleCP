## SimpleCP Testing Guide

Comprehensive testing infrastructure for production-ready quality assurance.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Test Types](#test-types)
- [Code Coverage](#code-coverage)
- [Performance Testing](#performance-testing)
- [Load Testing](#load-testing)
- [CI/CD Integration](#cicd-integration)
- [Writing Tests](#writing-tests)
- [Best Practices](#best-practices)

---

## Overview

SimpleCP includes a comprehensive test suite ensuring code quality, reliability, and performance:

- **Unit Tests**: Test individual components in isolation
- **API Tests**: Validate REST API endpoints
- **Integration Tests**: Test complete workflows
- **Performance Tests**: Benchmark critical operations
- **Load Tests**: Simulate real-world usage patterns
- **CI/CD**: Automated testing on every commit

**Test Coverage Target**: 80%+ code coverage

---

## Quick Start

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Run All Tests

```bash
# Using pytest directly
pytest

# Using test runner script
./run_tests.sh all
```

### Quick Validation

```bash
# Run fast smoke tests (under 30 seconds)
./run_tests.sh fast
```

---

## Test Structure

```
tests/
├── conftest.py                    # Shared fixtures and configuration
├── unit/                          # Unit tests
│   ├── test_clipboard_item.py     # ClipboardItem tests
│   ├── test_history_store.py      # HistoryStore tests
│   ├── test_clipboard_manager.py  # ClipboardManager tests
│   └── test_api_endpoints.py      # API endpoint tests
├── integration/                   # Integration tests
│   └── test_workflows.py          # End-to-end workflow tests
└── performance/                   # Performance tests
    ├── test_benchmarks.py         # Performance benchmarks
    └── locustfile.py              # Load testing scenarios

pytest.ini                         # Pytest configuration
run_tests.sh                       # Test runner script
```

---

## Running Tests

### Using Test Runner Script

The `run_tests.sh` script provides convenient commands:

```bash
./run_tests.sh all          # Run all tests
./run_tests.sh unit         # Run unit tests only
./run_tests.sh api          # Run API tests only
./run_tests.sh integration  # Run integration tests only
./run_tests.sh performance  # Run performance tests
./run_tests.sh coverage     # Generate coverage report
./run_tests.sh fast         # Quick smoke tests
./run_tests.sh watch        # Watch mode (requires pytest-watch)
./run_tests.sh benchmark    # Performance benchmarks
./run_tests.sh load         # Load tests with Locust
./run_tests.sh help         # Show help
```

### Using pytest Directly

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/unit/test_clipboard_item.py

# Run specific test class
pytest tests/unit/test_clipboard_item.py::TestClipboardItem

# Run specific test
pytest tests/unit/test_clipboard_item.py::TestClipboardItem::test_create_clipboard_item

# Run tests by marker
pytest -m unit              # Unit tests only
pytest -m api               # API tests only
pytest -m integration       # Integration tests only
pytest -m performance       # Performance tests only
pytest -m "not slow"        # Skip slow tests

# Verbose output
pytest -v

# Stop on first failure
pytest -x

# Show local variables on failure
pytest -l

# Run last failed tests
pytest --lf

# Run tests in parallel (requires pytest-xdist)
pytest -n auto
```

---

## Test Types

### Unit Tests

Test individual components in isolation.

**Location**: `tests/unit/`

**Markers**: `@pytest.mark.unit`

**Run**:
```bash
pytest -m unit
```

**Examples**:
- `test_clipboard_item.py`: ClipboardItem class functionality
- `test_history_store.py`: History management
- `test_clipboard_manager.py`: Main clipboard manager
- `test_api_endpoints.py`: API endpoint validation

### API Tests

Test REST API endpoints and responses.

**Location**: `tests/unit/test_api_endpoints.py`

**Markers**: `@pytest.mark.api`

**Run**:
```bash
pytest -m api
```

**Coverage**:
- All GET endpoints
- POST/PUT/DELETE operations
- Error handling
- Request validation
- Response formats

### Integration Tests

Test complete workflows and feature interactions.

**Location**: `tests/integration/`

**Markers**: `@pytest.mark.integration`

**Run**:
```bash
pytest -m integration
```

**Examples**:
- Full clipboard lifecycle (add → copy → delete)
- Snippet workflows (create → rename → move → delete)
- History to snippet conversion
- Search across multiple sources
- Data persistence and reload

### Performance Tests

Benchmark critical operations for performance regression.

**Location**: `tests/performance/test_benchmarks.py`

**Markers**: `@pytest.mark.performance`

**Run**:
```bash
pytest -m performance
```

**Benchmarked Operations**:
- Adding clips
- Searching
- Retrieving history
- Saving/loading stores
- API endpoint response times
- Large dataset handling

---

## Code Coverage

### Generate Coverage Report

```bash
# HTML report (recommended)
pytest --cov=. --cov-report=html
open htmlcov/index.html

# Terminal report
pytest --cov=. --cov-report=term-missing

# XML report (for CI/CD)
pytest --cov=. --cov-report=xml

# All formats
./run_tests.sh coverage
```

### Coverage Configuration

Configured in `pytest.ini`:
- Minimum coverage: 80%
- Branch coverage: Enabled
- Excludes: Tests, virtual environments, generated files

### View Coverage

```bash
# After running tests with coverage
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

**Coverage Report Shows**:
- Overall coverage percentage
- Per-file coverage
- Missing lines (highlighted in red)
- Branch coverage
- Partially covered branches

---

## Performance Testing

### Benchmarking

Run performance benchmarks with pytest-benchmark:

```bash
# Run benchmarks
pytest tests/performance -v --benchmark-only

# Compare with previous runs
pytest --benchmark-compare

# Save benchmark results
pytest --benchmark-autosave

# View benchmark history
pytest --benchmark-histogram
```

**Benchmarked Operations**:
- `add_clip`: Adding items to history
- `search`: Search performance
- `get_history`: Retrieving all history
- `save_stores`: Persistence operations
- `load_stores`: Data loading
- API endpoint latency

### Performance Thresholds

Tests fail if operations exceed thresholds:

| Operation | Threshold |
|-----------|-----------|
| API endpoints | < 100ms |
| Search (100 items) | < 200ms |
| Save/Load stores | < 500ms |
| History retrieval | < 50ms |

---

## Load Testing

### Using Locust

Locust simulates realistic menu bar app usage patterns.

#### Start Load Test

```bash
# Using script
./run_tests.sh load

# Or manually
locust -f tests/performance/locustfile.py --host=http://localhost:8000
```

#### Access Web UI

1. Open http://localhost:8089
2. Set number of users and spawn rate
3. Click "Start swarming"
4. Monitor real-time statistics

#### User Types

**MenuBarUser** (70% of users):
- Frequent history checks
- Periodic clipboard operations
- Occasional snippet access
- Realistic wait times (1-5s)

**HeavyUser** (10% of users):
- Rapid history access
- Frequent searches
- Bulk operations
- Faster action rate (0.5-2s)

**IdleUser** (20% of users):
- Background health checks
- Long idle periods (30-60s)
- Simulates inactive apps

**StressTestUser** (use sparingly):
- Aggressive request patterns
- Rapid-fire operations
- For finding breaking points

#### Load Test Scenarios

```bash
# Light load (10 users)
locust -f tests/performance/locustfile.py \
  --users 10 --spawn-rate 2 --host http://localhost:8000

# Normal load (50 users)
locust -f tests/performance/locustfile.py \
  --users 50 --spawn-rate 5 --host http://localhost:8000

# Heavy load (100 users)
locust -f tests/performance/locustfile.py \
  --users 100 --spawn-rate 10 --host http://localhost:8000

# Spike test (rapid increase)
locust -f tests/performance/locustfile.py \
  --users 200 --spawn-rate 50 --host http://localhost:8000

# Endurance test (1 hour)
locust -f tests/performance/locustfile.py \
  --users 30 --spawn-rate 5 --run-time 1h --host http://localhost:8000
```

#### Monitoring During Load Tests

Monitor API server during tests:

```bash
# Terminal 1: Run server
python daemon.py

# Terminal 2: Monitor logs
tail -f logs/simplecp.log

# Terminal 3: Run load test
locust -f tests/performance/locustfile.py --host http://localhost:8000

# Terminal 4: Monitor health
watch -n 1 'curl -s http://localhost:8000/health | jq'
```

---

## CI/CD Integration

### GitHub Actions

Automated testing runs on:
- Every push to main/develop branches
- Every pull request
- All branches matching `claude/**`

**Workflow**: `.github/workflows/test.yml`

**Jobs**:
1. **Test**: Run full test suite across Python versions (3.9-3.12) and OS (Ubuntu, macOS)
2. **Lint**: Code quality checks (ruff, black, isort, mypy)
3. **Smoke Test**: Quick validation tests
4. **Security**: Security scanning (bandit, safety)
5. **Build**: Verify package builds correctly

### View Results

- Check the "Actions" tab in GitHub
- Status badges show build status
- Coverage reports uploaded to Codecov

### Local CI Simulation

Run the same checks locally before pushing:

```bash
# Run all tests
pytest

# Check formatting
black --check .

# Check imports
isort --check-only .

# Lint
ruff check .

# Type check
mypy --ignore-missing-imports .

# Security scan
bandit -r . -ll
```

---

## Writing Tests

### Test Structure

```python
"""
Module docstring describing test file.
"""
import pytest
from module import ComponentToTest


@pytest.mark.unit  # Add appropriate marker
class TestComponentName:
    """Test ComponentToTest functionality."""

    def test_specific_behavior(self):
        """Test that specific behavior works correctly."""
        # Arrange
        component = ComponentToTest()

        # Act
        result = component.method()

        # Assert
        assert result == expected_value
```

### Using Fixtures

```python
def test_with_fixture(clipboard_manager):
    """Test using shared fixture."""
    clipboard_manager.add_clip("Test")
    assert len(clipboard_manager.history_store) == 1
```

**Available Fixtures** (see `tests/conftest.py`):
- `test_data_dir`: Temporary directory for test data
- `clipboard_manager`: Fresh ClipboardManager instance
- `sample_clipboard_items`: Pre-created test items
- `api_client`: FastAPI TestClient
- `mock_clipboard_content`: Sample content variations

### Test Markers

Mark tests for categorization:

```python
@pytest.mark.unit
def test_unit():
    """Unit test marker."""
    pass

@pytest.mark.integration
def test_integration():
    """Integration test marker."""
    pass

@pytest.mark.api
def test_api():
    """API test marker."""
    pass

@pytest.mark.performance
def test_performance():
    """Performance test marker."""
    pass

@pytest.mark.slow
def test_slow_operation():
    """Slow test marker."""
    pass

@pytest.mark.smoke
def test_smoke():
    """Quick validation test."""
    pass
```

### Async Tests

```python
import pytest

@pytest.mark.asyncio
async def test_async_operation():
    """Test async operation."""
    result = await async_function()
    assert result is not None
```

### Parameterized Tests

```python
@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
    ("test", "TEST"),
])
def test_uppercase(input, expected):
    """Test uppercase conversion."""
    assert input.upper() == expected
```

### Mocking

```python
from unittest.mock import patch, MagicMock

@patch('pyperclip.paste')
def test_with_mock(mock_paste, clipboard_manager):
    """Test with mocked clipboard."""
    mock_paste.return_value = "Mocked content"

    item = clipboard_manager.check_clipboard()
    assert item.content == "Mocked content"
```

---

## Best Practices

### Test Organization

✅ **DO**:
- Group related tests in classes
- Use descriptive test names
- One assertion per test (when possible)
- Test both success and error paths
- Use fixtures for common setup
- Mark tests appropriately

❌ **DON'T**:
- Write tests dependent on execution order
- Test implementation details
- Use sleep() for timing (use mocks)
- Commit failing tests
- Skip tests without good reason

### Test Coverage

**Prioritize Testing**:
1. Public APIs and interfaces
2. Business logic and algorithms
3. Error handling and edge cases
4. Critical user workflows
5. Performance-sensitive operations

**Lower Priority**:
- Getters/setters with no logic
- Third-party library wrappers
- Simple data classes

### Performance Testing

- Set reasonable thresholds
- Test with realistic data sizes
- Compare against baseline
- Monitor for regressions
- Document expected performance

### Load Testing

- Start with light load
- Gradually increase users
- Monitor system resources
- Test sustained load (endurance)
- Test spike scenarios
- Document breaking points

---

## Troubleshooting

### Tests Fail Locally But Pass in CI

```bash
# Clear pytest cache
pytest --cache-clear

# Remove compiled Python files
find . -type f -name '*.pyc' -delete
find . -type d -name '__pycache__' -delete

# Reinstall dependencies
pip install --force-reinstall -r requirements.txt
```

### Slow Test Execution

```bash
# Skip slow tests
pytest -m "not slow"

# Run in parallel
pytest -n auto

# Profile test execution
pytest --durations=10
```

### Coverage Not Updating

```bash
# Clear coverage data
coverage erase

# Run with fresh coverage
pytest --cov=. --cov-report=html
```

### Load Tests Fail to Connect

```bash
# Check if server is running
curl http://localhost:8000/health

# Start server
python daemon.py

# Check port availability
lsof -i :8000
```

---

## Continuous Improvement

### Adding New Tests

1. Write test for new feature/bug
2. Ensure test fails initially (red)
3. Implement feature/fix
4. Ensure test passes (green)
5. Refactor if needed
6. Check coverage impact

### Reviewing Test Health

```bash
# Find slow tests
pytest --durations=20

# Check coverage gaps
pytest --cov=. --cov-report=term-missing

# Run only failed tests
pytest --lf -v
```

### Performance Regression Detection

```bash
# Save baseline
pytest --benchmark-only --benchmark-autosave --benchmark-save=baseline

# Compare with baseline
pytest --benchmark-only --benchmark-compare=baseline

# Generate comparison report
pytest --benchmark-compare=baseline --benchmark-compare-fail=mean:10%
```

---

## Resources

- [pytest documentation](https://docs.pytest.org/)
- [pytest-cov documentation](https://pytest-cov.readthedocs.io/)
- [Locust documentation](https://docs.locust.io/)
- [FastAPI testing guide](https://fastapi.tiangolo.com/tutorial/testing/)

---

**Keep tests green! 🟢**
