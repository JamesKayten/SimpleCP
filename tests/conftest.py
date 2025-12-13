"""
Pytest configuration and fixtures for SimpleCP tests.
"""
import os
import sys
import tempfile
import shutil
from pathlib import Path
from typing import Generator
import pytest
from fastapi.testclient import TestClient

# Add backend directory to path for imports
backend_dir = Path(__file__).parent.parent / "backend"
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

# Set test environment before importing app modules
os.environ["ENVIRONMENT"] = "test"
os.environ["LOG_TO_FILE"] = "false"
os.environ["ENABLE_SENTRY"] = "false"

from clipboard_manager import ClipboardManager
from stores.clipboard_item import ClipboardItem
from api.server import create_app


@pytest.fixture(scope="session")
def test_data_dir() -> Generator[str, None, None]:
    """Create temporary directory for test data."""
    temp_dir = tempfile.mkdtemp(prefix="simplecp_test_")
    yield temp_dir
    # Cleanup
    shutil.rmtree(temp_dir, ignore_errors=True)


@pytest.fixture
def clipboard_manager(test_data_dir) -> ClipboardManager:
    """Create a fresh ClipboardManager instance for testing."""
    manager = ClipboardManager(
        data_dir=test_data_dir,
        max_history=50,
        display_count=10,
    )
    return manager


@pytest.fixture
def sample_clipboard_items() -> list[ClipboardItem]:
    """Create sample clipboard items for testing."""
    items = []
    for i in range(5):
        item = ClipboardItem(
            content=f"Test content {i}",
            content_type="text",
            source_app="pytest",
        )
        items.append(item)
    return items


@pytest.fixture
def api_client(clipboard_manager) -> TestClient:
    """Create FastAPI test client."""
    app = create_app(clipboard_manager)
    return TestClient(app)


@pytest.fixture
def mock_clipboard_content():
    """Sample clipboard content for testing."""
    return {
        "text": "Hello, World!",
        "code": "def hello():\n    print('Hello, World!')",
        "url": "https://example.com",
        "json": '{"key": "value", "number": 42}',
    }


@pytest.fixture(autouse=True)
def reset_clipboard_manager(clipboard_manager):
    """Reset clipboard manager state between tests."""
    yield
    # Clear stores after each test
    try:
        clipboard_manager.history_store.clear()
    except Exception:
        pass
    # SnippetStore doesn't have a clear() method, clear folders manually
    try:
        clipboard_manager.snippet_store.folders.clear()
    except Exception:
        pass


@pytest.fixture
def performance_test_size():
    """Standard size for performance tests."""
    return 100
