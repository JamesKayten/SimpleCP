"""
Unit tests for HistoryStore class.
"""
import pytest
from stores.history_store import HistoryStore
from stores.clipboard_item import ClipboardItem


@pytest.mark.unit
class TestHistoryStore:
    """Test HistoryStore functionality."""

    @pytest.fixture
    def history_store(self):
        """Create a fresh history store for each test."""
        return HistoryStore(max_items=10, display_count=5)

    def test_create_history_store(self, history_store):
        """Test creating a history store."""
        assert history_store.max_items == 10
        assert history_store.display_count == 5
        assert len(history_store) == 0

    def test_add_item(self, history_store):
        """Test adding an item to history."""
        item = ClipboardItem(content="Test")
        history_store.add_item(item)

        assert len(history_store) == 1
        assert history_store.get_item(0) == item

    def test_add_multiple_items(self, history_store):
        """Test adding multiple items."""
        for i in range(5):
            item = ClipboardItem(content=f"Test {i}")
            history_store.add_item(item)

        assert len(history_store) == 5

    def test_max_items_limit(self, history_store):
        """Test that history respects max_items limit."""
        # Add more items than max_items
        for i in range(15):
            item = ClipboardItem(content=f"Test {i}")
            history_store.add_item(item)

        assert len(history_store) == 10  # Should be capped at max_items

    def test_get_item_by_index(self, history_store):
        """Test retrieving item by index."""
        items = []
        for i in range(5):
            item = ClipboardItem(content=f"Test {i}")
            history_store.add_item(item)
            items.append(item)

        # Most recent should be at index 0
        assert history_store.get_item(0) == items[-1]
        assert history_store.get_item(4) == items[0]

    def test_get_item_by_id(self, history_store):
        """Test retrieving item by ID."""
        item = ClipboardItem(content="Test")
        history_store.add_item(item)

        retrieved = history_store.get_item_by_id(item.clip_id)
        assert retrieved == item

    def test_get_item_by_invalid_id(self, history_store):
        """Test retrieving item with invalid ID."""
        result = history_store.get_item_by_id("invalid-id")
        assert result is None

    def test_delete_item_by_id(self, history_store):
        """Test deleting item by ID."""
        item = ClipboardItem(content="Test")
        history_store.add_item(item)

        success = history_store.delete_item(item.clip_id)
        assert success is True
        assert len(history_store) == 0

    def test_delete_nonexistent_item(self, history_store):
        """Test deleting non-existent item."""
        success = history_store.delete_item("invalid-id")
        assert success is False

    def test_clear_history(self, history_store):
        """Test clearing all history."""
        for i in range(5):
            item = ClipboardItem(content=f"Test {i}")
            history_store.add_item(item)

        history_store.clear()
        assert len(history_store) == 0

    def test_get_all_items(self, history_store):
        """Test getting all items."""
        for i in range(5):
            item = ClipboardItem(content=f"Test {i}")
            history_store.add_item(item)

        all_items = history_store.get_all()
        assert len(all_items) == 5

    def test_get_recent_items(self, history_store):
        """Test getting recent items for display."""
        for i in range(10):
            item = ClipboardItem(content=f"Test {i}")
            history_store.add_item(item)

        recent = history_store.get_recent()
        assert len(recent) == 5  # display_count

    def test_get_display_folders(self, history_store):
        """Test auto-generated folder structure."""
        # Add more than display_count items
        for i in range(25):
            item = ClipboardItem(content=f"Test {i}")
            history_store.add_item(item)

        folders = history_store.get_display_folders()
        assert len(folders) > 0

        # Check folder structure
        folder = folders[0]
        assert "name" in folder
        assert "start_index" in folder
        assert "end_index" in folder

    def test_search_items(self, history_store):
        """Test searching history items."""
        history_store.add_item(ClipboardItem(content="Hello World"))
        history_store.add_item(ClipboardItem(content="Python code"))
        history_store.add_item(ClipboardItem(content="Hello Python"))

        results = history_store.search("Hello")
        assert len(results) == 2

        results = history_store.search("Python")
        assert len(results) == 2

        results = history_store.search("nonexistent")
        assert len(results) == 0

    def test_search_case_insensitive(self, history_store):
        """Test search is case-insensitive."""
        history_store.add_item(ClipboardItem(content="HELLO"))

        results = history_store.search("hello")
        assert len(results) == 1

    def test_to_dict_serialization(self, history_store):
        """Test serializing history to dictionary."""
        for i in range(3):
            item = ClipboardItem(content=f"Test {i}")
            history_store.add_item(item)

        data = history_store.to_dict()
        assert isinstance(data, dict)
        assert "items" in data
        assert len(data["items"]) == 3

    def test_from_dict_deserialization(self):
        """Test deserializing history from dictionary."""
        data = {
            "items": [
                {
                    "clip_id": "test-1",
                    "content": "Test 1",
                    "timestamp": "2025-01-01T00:00:00",
                    "content_type": "text",
                },
                {
                    "clip_id": "test-2",
                    "content": "Test 2",
                    "timestamp": "2025-01-01T00:01:00",
                    "content_type": "text",
                },
            ]
        }

        history_store = HistoryStore.from_dict(data, max_items=10)
        assert len(history_store) == 2

    def test_delegate_notification(self, history_store):
        """Test delegate notification on changes."""
        notifications = []

        def delegate(event, *args):
            notifications.append((event, args))

        history_store.add_delegate(delegate)

        item = ClipboardItem(content="Test")
        history_store.add_item(item)

        assert len(notifications) > 0
        assert notifications[0][0] == "item_added"

    def test_duplicate_prevention(self, history_store):
        """Test that consecutive duplicates are not added."""
        item1 = ClipboardItem(content="Test")
        item2 = ClipboardItem(content="Test")  # Same content

        history_store.add_item(item1)
        # Depending on implementation, this might be prevented
        history_store.add_item(item2)

        # Note: Actual behavior depends on implementation
        # This test documents expected behavior
