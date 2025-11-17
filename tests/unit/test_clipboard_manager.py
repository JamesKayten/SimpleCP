"""
Unit tests for ClipboardManager class.
"""
import pytest
from unittest.mock import patch, MagicMock
from clipboard_manager import ClipboardManager
from stores.clipboard_item import ClipboardItem


@pytest.mark.unit
class TestClipboardManager:
    """Test ClipboardManager functionality."""

    def test_create_clipboard_manager(self, clipboard_manager):
        """Test creating clipboard manager."""
        assert clipboard_manager is not None
        assert clipboard_manager.history_store is not None
        assert clipboard_manager.snippet_store is not None

    def test_add_clip(self, clipboard_manager):
        """Test adding a clip to history."""
        item = clipboard_manager.add_clip("Test content")
        assert item is not None
        assert item.content == "Test content"
        assert len(clipboard_manager.history_store) == 1

    def test_add_empty_clip(self, clipboard_manager):
        """Test that empty clips are not added."""
        item = clipboard_manager.add_clip("")
        assert item is None
        assert len(clipboard_manager.history_store) == 0

    def test_add_whitespace_clip(self, clipboard_manager):
        """Test that whitespace-only clips are not added."""
        item = clipboard_manager.add_clip("   \n\t   ")
        assert item is None
        assert len(clipboard_manager.history_store) == 0

    @patch("pyperclip.paste")
    def test_check_clipboard(self, mock_paste, clipboard_manager):
        """Test clipboard checking."""
        mock_paste.return_value = "New content"

        item = clipboard_manager.check_clipboard()
        assert item is not None
        assert item.content == "New content"

    @patch("pyperclip.paste")
    def test_check_clipboard_no_change(self, mock_paste, clipboard_manager):
        """Test clipboard check with no change."""
        mock_paste.return_value = "Same content"

        # First check
        item1 = clipboard_manager.check_clipboard()
        assert item1 is not None

        # Second check with same content
        item2 = clipboard_manager.check_clipboard()
        assert item2 is None  # No new item

    @patch("pyperclip.copy")
    def test_copy_to_clipboard(self, mock_copy, clipboard_manager):
        """Test copying item to system clipboard."""
        item = clipboard_manager.add_clip("Test content")

        success = clipboard_manager.copy_to_clipboard(item.clip_id)
        assert success is True
        mock_copy.assert_called_once_with("Test content")

    def test_copy_invalid_id(self, clipboard_manager):
        """Test copying with invalid ID."""
        success = clipboard_manager.copy_to_clipboard("invalid-id")
        assert success is False

    def test_get_all_history(self, clipboard_manager):
        """Test getting all history items."""
        for i in range(5):
            clipboard_manager.add_clip(f"Test {i}")

        items = clipboard_manager.get_all_history()
        assert len(items) == 5

    def test_get_all_history_with_limit(self, clipboard_manager):
        """Test getting history with limit."""
        for i in range(10):
            clipboard_manager.add_clip(f"Test {i}")

        items = clipboard_manager.get_all_history(limit=5)
        assert len(items) == 5

    def test_get_recent_history(self, clipboard_manager):
        """Test getting recent history for display."""
        for i in range(15):
            clipboard_manager.add_clip(f"Test {i}")

        recent = clipboard_manager.get_recent_history()
        assert len(recent) <= clipboard_manager.display_count

    def test_delete_history_item(self, clipboard_manager):
        """Test deleting history item."""
        item = clipboard_manager.add_clip("Test")

        success = clipboard_manager.delete_history_item(item.clip_id)
        assert success is True
        assert len(clipboard_manager.history_store) == 0

    def test_clear_all_history(self, clipboard_manager):
        """Test clearing all history."""
        for i in range(5):
            clipboard_manager.add_clip(f"Test {i}")

        clipboard_manager.clear_history()
        assert len(clipboard_manager.history_store) == 0

    def test_save_snippet(self, clipboard_manager):
        """Test saving item as snippet."""
        item = clipboard_manager.add_clip("Test snippet content")

        success = clipboard_manager.save_as_snippet(
            item.clip_id, "Default", "My Snippet"
        )
        assert success is True

        snippets = clipboard_manager.get_all_snippets()
        assert len(snippets) > 0

    def test_save_snippet_invalid_id(self, clipboard_manager):
        """Test saving snippet with invalid ID."""
        success = clipboard_manager.save_as_snippet("invalid-id", "Default", "Test")
        assert success is False

    def test_create_snippet_directly(self, clipboard_manager):
        """Test creating snippet directly."""
        snippet = clipboard_manager.create_snippet(
            content="Direct snippet",
            folder="Work",
            name="Important Note",
        )
        assert snippet is not None
        assert snippet.has_name is True

    def test_get_snippets_by_folder(self, clipboard_manager):
        """Test getting snippets from specific folder."""
        clipboard_manager.create_snippet("Snippet 1", "Work", "Note 1")
        clipboard_manager.create_snippet("Snippet 2", "Work", "Note 2")
        clipboard_manager.create_snippet("Snippet 3", "Personal", "Note 3")

        work_snippets = clipboard_manager.get_snippets_in_folder("Work")
        assert len(work_snippets) == 2

    def test_delete_snippet(self, clipboard_manager):
        """Test deleting snippet."""
        snippet = clipboard_manager.create_snippet("Test", "Default", "Note")

        success = clipboard_manager.delete_snippet("Default", snippet.clip_id)
        assert success is True

    def test_rename_folder(self, clipboard_manager):
        """Test renaming snippet folder."""
        clipboard_manager.create_snippet("Test", "OldName", "Note")

        success = clipboard_manager.rename_folder("OldName", "NewName")
        assert success is True

        folders = clipboard_manager.get_all_folders()
        assert "NewName" in folders
        assert "OldName" not in folders

    def test_delete_folder(self, clipboard_manager):
        """Test deleting snippet folder."""
        clipboard_manager.create_snippet("Test", "ToDelete", "Note")

        success = clipboard_manager.delete_folder("ToDelete")
        assert success is True

        folders = clipboard_manager.get_all_folders()
        assert "ToDelete" not in folders

    def test_search_all(self, clipboard_manager):
        """Test searching across history and snippets."""
        clipboard_manager.add_clip("Python programming")
        clipboard_manager.create_snippet("Python code", "Code", "Example")

        results = clipboard_manager.search_all("Python")
        assert len(results["history"]) >= 1
        assert len(results["snippets"]) >= 1

    def test_get_stats(self, clipboard_manager):
        """Test getting statistics."""
        for i in range(3):
            clipboard_manager.add_clip(f"Test {i}")

        clipboard_manager.create_snippet("Snippet", "Work", "Note")

        stats = clipboard_manager.get_stats()
        assert stats["history_count"] == 3
        assert stats["snippet_count"] == 1
        assert "folder_count" in stats
        assert "max_history" in stats

    def test_save_and_load_stores(self, clipboard_manager, test_data_dir):
        """Test persistence of stores."""
        # Add some data
        clipboard_manager.add_clip("Test history")
        clipboard_manager.create_snippet("Test snippet", "Work", "Note")

        # Save
        clipboard_manager.save_stores()

        # Create new manager and load
        new_manager = ClipboardManager(data_dir=test_data_dir)
        new_manager.load_stores()

        assert len(new_manager.history_store) == 1
        assert len(new_manager.snippet_store.get_all_snippets()) == 1

    def test_max_history_enforcement(self, test_data_dir):
        """Test that max_history limit is enforced."""
        manager = ClipboardManager(data_dir=test_data_dir, max_history=5)

        # Add more items than max_history
        for i in range(10):
            manager.add_clip(f"Test {i}")

        assert len(manager.history_store) <= 5
