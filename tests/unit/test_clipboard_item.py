"""
Unit tests for ClipboardItem class.
"""
import pytest
from datetime import datetime
from stores.clipboard_item import ClipboardItem


@pytest.mark.unit
class TestClipboardItem:
    """Test ClipboardItem functionality."""

    def test_create_clipboard_item(self):
        """Test creating a basic clipboard item."""
        item = ClipboardItem(
            content="Test content",
            content_type="text",
            source_app="pytest",
        )

        assert item.content == "Test content"
        assert item.content_type == "text"
        assert item.source_app == "pytest"
        assert item.clip_id is not None
        assert isinstance(item.timestamp, datetime)

    def test_clipboard_item_with_name(self):
        """Test clipboard item with custom name."""
        item = ClipboardItem(
            content="Test content",
            content_type="text",
            name="My Snippet",
        )

        assert item.has_name is True
        assert item.snippet_name == "My Snippet"

    def test_display_string_truncation(self):
        """Test display string truncates long content."""
        long_content = "a" * 100
        item = ClipboardItem(content=long_content)

        display = item.get_display_string(max_length=50)
        assert len(display) == 50
        assert display.endswith("...")

    def test_display_string_multiline(self):
        """Test display string handles multiline content."""
        multiline = "Line 1\nLine 2\nLine 3"
        item = ClipboardItem(content=multiline)

        display = item.get_display_string()
        assert "\n" not in display
        assert "Line 1" in display

    def test_to_dict_conversion(self):
        """Test converting clipboard item to dictionary."""
        item = ClipboardItem(
            content="Test",
            content_type="text",
            source_app="pytest",
        )

        data = item.to_dict()
        assert isinstance(data, dict)
        assert data["content"] == "Test"
        assert data["content_type"] == "text"
        assert data["source_app"] == "pytest"
        assert "clip_id" in data
        assert "timestamp" in data

    def test_from_dict_creation(self):
        """Test creating clipboard item from dictionary."""
        data = {
            "clip_id": "test-123",
            "content": "Test content",
            "timestamp": datetime.now().isoformat(),
            "content_type": "text",
            "source_app": "pytest",
        }

        item = ClipboardItem.from_dict(data)
        assert item.clip_id == "test-123"
        assert item.content == "Test content"
        assert item.content_type == "text"

    def test_detect_content_type_url(self):
        """Test URL content type detection."""
        urls = [
            "https://example.com",
            "http://test.org",
            "https://github.com/user/repo",
        ]

        for url in urls:
            item = ClipboardItem(content=url)
            assert item.content_type == "url"

    def test_detect_content_type_code(self):
        """Test code content type detection."""
        code_samples = [
            "def hello():\n    pass",
            "function test() {}",
            "class MyClass:",
        ]

        for code in code_samples:
            item = ClipboardItem(content=code)
            assert item.content_type == "code"

    def test_detect_content_type_json(self):
        """Test JSON content type detection."""
        json_content = '{"key": "value", "number": 42}'
        item = ClipboardItem(content=json_content)
        assert item.content_type == "json"

    def test_equality_by_id(self):
        """Test clipboard items are equal if IDs match."""
        item1 = ClipboardItem(content="Test", clip_id="same-id")
        item2 = ClipboardItem(content="Different", clip_id="same-id")

        # Should be equal based on ID, not content
        assert item1.clip_id == item2.clip_id

    def test_tags_functionality(self):
        """Test tags attribute."""
        item = ClipboardItem(content="Test", tags=["important", "work"])
        assert "important" in item.tags
        assert "work" in item.tags
        assert len(item.tags) == 2

    def test_empty_content_handling(self):
        """Test handling of empty content."""
        item = ClipboardItem(content="")
        assert item.content == ""
        assert item.display_string == "(empty)"

    def test_whitespace_only_content(self):
        """Test handling of whitespace-only content."""
        item = ClipboardItem(content="   \n\t   ")
        display = item.get_display_string()
        assert display == "(empty)" or display.strip() == ""
