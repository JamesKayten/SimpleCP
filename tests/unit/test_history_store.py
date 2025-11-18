"""
Unit tests for HistoryStore class.
"""

import pytest
from stores.clipboard_item import ClipboardItem


class TestHistoryStore:
    """Test HistoryStore functionality."""

    def test_add_item(self, history_store):
        """Test adding an item to history."""
        item = ClipboardItem(content="test", content_type="text")
        history_store.add(item)

        assert history_store.count() == 1
        items = history_store.get_recent(10)
        assert len(items) == 1
        assert items[0].content == "test"

    def test_deduplication(self, history_store):
        """Test that duplicate items are moved to top."""
        item1 = ClipboardItem(content="test1", content_type="text")
        item2 = ClipboardItem(content="test2", content_type="text")

        history_store.add(item1)
        history_store.add(item2)
        history_store.add(item1)  # Duplicate

        # Should still have 2 items
        assert history_store.count() == 2

        # First item should be most recent
        recent = history_store.get_recent(10)
        assert recent[0].content == "test1"

    def test_max_size_limit(self, history_store):
        """Test that history respects max size limit."""
        # Add more items than max size
        for i in range(150):
            item = ClipboardItem(content=f"test{i}", content_type="text")
            history_store.add(item)

        # Should be trimmed to max size (100 by default)
        assert history_store.count() <= 100

    def test_search(self, history_store):
        """Test searching history."""
        item1 = ClipboardItem(content="hello world", content_type="text")
        item2 = ClipboardItem(content="goodbye world", content_type="text")

        history_store.add(item1)
        history_store.add(item2)

        results = history_store.search("hello")
        assert len(results) == 1
        assert results[0].content == "hello world"

    def test_delete_item(self, history_store):
        """Test deleting an item."""
        item = ClipboardItem(content="test", content_type="text")
        history_store.add(item)

        assert history_store.count() == 1
        history_store.delete(item.clip_id)
        assert history_store.count() == 0

    def test_clear_all(self, history_store):
        """Test clearing all history."""
        for i in range(5):
            item = ClipboardItem(content=f"test{i}", content_type="text")
            history_store.add(item)

        assert history_store.count() == 5
        history_store.clear()
        assert history_store.count() == 0
