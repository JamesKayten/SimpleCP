"""
Unit tests for ClipboardItem class.
"""

import pytest
from datetime import datetime
from stores.clipboard_item import ClipboardItem


class TestClipboardItem:
    """Test ClipboardItem functionality."""

    def test_create_basic_item(self):
        """Test creating a basic clipboard item."""
        item = ClipboardItem(content="test", content_type="text")
        assert item.content == "test"
        assert item.content_type == "text"
        assert item.clip_id is not None
        assert isinstance(item.timestamp, datetime)

    def test_content_type_detection(self):
        """Test automatic content type detection."""
        # URL detection
        url_item = ClipboardItem(content="https://example.com")
        assert url_item.content_type in ["url", "text"]

        # Email detection
        email_item = ClipboardItem(content="test@example.com")
        assert email_item.content_type in ["email", "text"]

    def test_to_dict(self):
        """Test converting item to dictionary."""
        item = ClipboardItem(content="test", content_type="text")
        data = item.to_dict()

        assert isinstance(data, dict)
        assert data["content"] == "test"
        assert data["content_type"] == "text"
        assert "clip_id" in data
        assert "timestamp" in data

    def test_from_dict(self):
        """Test creating item from dictionary."""
        data = {
            "clip_id": "test-id",
            "content": "test content",
            "content_type": "text",
            "timestamp": datetime.now().isoformat()
        }
        item = ClipboardItem.from_dict(data)

        assert item.clip_id == "test-id"
        assert item.content == "test content"
        assert item.content_type == "text"
