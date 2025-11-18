"""Tests for ClipboardItem model."""

import pytest
from datetime import datetime
from stores.clipboard_item import ClipboardItem


class TestClipboardItem:
    """Test ClipboardItem functionality."""

    def test_create_basic_item(self):
        """Test creating a basic clipboard item."""
        item = ClipboardItem(content="Hello World")
        assert item.content == "Hello World"
        assert item.item_type == "history"
        assert item.has_name is False
        assert isinstance(item.timestamp, datetime)
        assert item.clip_id is not None

    def test_content_type_detection_url(self):
        """Test URL content type detection."""
        item = ClipboardItem(content="https://example.com")
        assert item.content_type == "url"

    def test_content_type_detection_email(self):
        """Test email content type detection."""
        item = ClipboardItem(content="test@example.com")
        assert item.content_type == "email"

    def test_content_type_detection_code(self):
        """Test code content type detection."""
        item = ClipboardItem(content="def test():\n    pass")
        assert item.content_type == "code"

    def test_content_type_detection_text(self):
        """Test plain text content type detection."""
        item = ClipboardItem(content="Just some text")
        assert item.content_type == "text"

    def test_display_string_short(self):
        """Test display string for short content."""
        item = ClipboardItem(content="Short")
        assert item.display_string == "Short"

    def test_display_string_long(self):
        """Test display string for long content."""
        long_text = "A" * 100
        item = ClipboardItem(content=long_text, display_length=50)
        assert len(item.display_string) <= 50
        assert item.display_string.endswith("...")

    def test_display_string_multiline(self):
        """Test display string with newlines."""
        item = ClipboardItem(content="Line 1\nLine 2\nLine 3")
        assert "\n" not in item.display_string
        assert "Line 1 Line 2 Line 3" in item.display_string

    def test_make_snippet(self):
        """Test converting history item to snippet."""
        item = ClipboardItem(content="Test content")
        snippet = item.make_snippet("My Snippet", "Code", ["python", "test"])

        assert snippet.has_name is True
        assert snippet.snippet_name == "My Snippet"
        assert snippet.folder_path == "Code"
        assert snippet.tags == ["python", "test"]
        assert snippet.item_type == "snippet"

    def test_matches_search_content(self):
        """Test search matching in content."""
        item = ClipboardItem(content="Hello World")
        assert item.matches_search("hello") is True
        assert item.matches_search("world") is True
        assert item.matches_search("foo") is False

    def test_matches_search_snippet_name(self):
        """Test search matching in snippet name."""
        item = ClipboardItem(content="Test")
        item.make_snippet("Important Code", "Code", [])
        assert item.matches_search("important") is True
        assert item.matches_search("code") is True

    def test_matches_search_tags(self):
        """Test search matching in tags."""
        item = ClipboardItem(content="Test")
        item.make_snippet("Test", "Code", ["python", "testing"])
        assert item.matches_search("python") is True
        assert item.matches_search("testing") is True

    def test_update_display_length(self):
        """Test updating display length."""
        long_text = "A" * 100
        item = ClipboardItem(content=long_text, display_length=20)
        old_display = item.display_string

        item.update_display_length(30)
        assert len(item.display_string) != len(old_display)
        assert item.display_length == 30

    def test_to_dict(self):
        """Test converting item to dictionary."""
        item = ClipboardItem(content="Test", source_app="App")
        data = item.to_dict()

        assert data["content"] == "Test"
        assert data["source_app"] == "App"
        assert "timestamp" in data
        assert "clip_id" in data

    def test_from_dict(self):
        """Test creating item from dictionary."""
        original = ClipboardItem(content="Test")
        data = original.to_dict()

        restored = ClipboardItem.from_dict(data)
        assert restored.content == original.content
        assert restored.clip_id == original.clip_id
        assert restored.content_type == original.content_type

    def test_from_dict_with_snippet(self):
        """Test creating snippet from dictionary."""
        original = ClipboardItem(content="Test")
        original.make_snippet("My Snippet", "Code", ["tag1"])
        data = original.to_dict()

        restored = ClipboardItem.from_dict(data)
        assert restored.has_name is True
        assert restored.snippet_name == "My Snippet"
        assert restored.folder_path == "Code"
        assert restored.tags == ["tag1"]

    def test_str_representation(self):
        """Test string representation."""
        item = ClipboardItem(content="Test content")
        assert str(item) == item.display_string

        item.make_snippet("Named Snippet", "Code", [])
        assert str(item) == "Named Snippet"

    def test_equality(self):
        """Test item equality comparison."""
        item1 = ClipboardItem(content="Same content")
        item2 = ClipboardItem(content="Same content")
        item3 = ClipboardItem(content="Different content")

        assert item1 == item2
        assert item1 != item3
        assert item1 != "not an item"

    def test_unique_id_generation(self):
        """Test that each item gets a unique ID."""
        item1 = ClipboardItem(content="Test")
        item2 = ClipboardItem(content="Test")

        # Different timestamps should produce different IDs
        assert item1.clip_id != item2.clip_id

    def test_custom_clip_id(self):
        """Test creating item with custom clip_id."""
        custom_id = "custom123"
        item = ClipboardItem(content="Test", clip_id=custom_id)
        assert item.clip_id == custom_id
