"""Shared pytest fixtures for SimpleCP tests."""

import pytest
import tempfile
import shutil
import os
from clipboard_manager import ClipboardManager
from stores.clipboard_item import ClipboardItem


@pytest.fixture
def temp_data_dir():
    """Create temporary data directory for tests."""
    temp_dir = tempfile.mkdtemp()
    yield temp_dir
    shutil.rmtree(temp_dir)


@pytest.fixture
def clipboard_manager(temp_data_dir):
    """Create ClipboardManager instance for tests."""
    manager = ClipboardManager(data_dir=temp_data_dir, max_history=50)
    return manager


@pytest.fixture
def sample_clip():
    """Create sample clipboard item."""
    return ClipboardItem(content="Test clipboard content", source_app="TestApp")


@pytest.fixture
def sample_snippet():
    """Create sample snippet."""
    clip = ClipboardItem(content="def test():\n    pass")
    clip.make_snippet("Test Snippet", "Code", ["python", "test"])
    return clip
