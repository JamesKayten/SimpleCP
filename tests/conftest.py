"""
Pytest configuration and shared fixtures for SimpleCP tests.
"""

import pytest
import os
import tempfile
import json
from pathlib import Path
from clipboard_manager import ClipboardManager
from stores.clipboard_item import ClipboardItem
from stores.history_store import HistoryStore
from stores.snippet_store import SnippetStore


@pytest.fixture
def temp_data_dir():
    """Create a temporary directory for test data."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield tmpdir


@pytest.fixture
def mock_history_file(temp_data_dir):
    """Create a temporary history file."""
    history_path = os.path.join(temp_data_dir, 'history.json')
    with open(history_path, 'w') as f:
        json.dump([], f)
    return history_path


@pytest.fixture
def mock_snippets_file(temp_data_dir):
    """Create a temporary snippets file."""
    snippets_path = os.path.join(temp_data_dir, 'snippets.json')
    with open(snippets_path, 'w') as f:
        json.dump({}, f)
    return snippets_path


@pytest.fixture
def history_store(mock_history_file):
    """Create a HistoryStore with temporary storage."""
    return HistoryStore(storage_file=mock_history_file)


@pytest.fixture
def snippet_store(mock_snippets_file):
    """Create a SnippetStore with temporary storage."""
    return SnippetStore(storage_file=mock_snippets_file)


@pytest.fixture
def clipboard_manager(mock_history_file, mock_snippets_file):
    """Create a ClipboardManager with temporary storage."""
    return ClipboardManager(
        history_file=mock_history_file,
        snippets_file=mock_snippets_file
    )


@pytest.fixture
def sample_clipboard_item():
    """Create a sample ClipboardItem for testing."""
    return ClipboardItem(
        content="Test content",
        content_type="text"
    )


@pytest.fixture
def sample_items():
    """Create multiple sample clipboard items."""
    return [
        ClipboardItem(content="Item 1", content_type="text"),
        ClipboardItem(content="Item 2", content_type="text"),
        ClipboardItem(content="https://example.com", content_type="url"),
    ]
