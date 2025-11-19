"""Shared test fixtures for API tests."""
import pytest
import tempfile
import shutil
from fastapi.testclient import TestClient
from api.server import create_app
from clipboard_manager import ClipboardManager


@pytest.fixture
def client():
    """Create test client with temp data directory."""
    temp_dir = tempfile.mkdtemp()
    manager = ClipboardManager(data_dir=temp_dir)
    app = create_app(manager)
    yield TestClient(app), manager
    shutil.rmtree(temp_dir, ignore_errors=True)
