"""Tests for ClipboardManager."""

import pytest
import os
import json
from clipboard_manager import ClipboardManager
from stores.clipboard_item import ClipboardItem


class TestClipboardManager:
    """Test ClipboardManager functionality."""

    def test_init(self, temp_data_dir):
        """Test ClipboardManager initialization."""
        manager = ClipboardManager(data_dir=temp_data_dir, max_history=100)
        assert manager.data_dir == temp_data_dir
        assert manager.history_store.max_items == 100
        assert os.path.exists(temp_data_dir)

    def test_add_clip(self, clipboard_manager):
        """Test adding clip to history."""
        clip = clipboard_manager.add_clip("Test content")
        assert clip.content == "Test content"
        assert len(clipboard_manager.history_store.items) == 1

    def test_add_clip_with_source_app(self, clipboard_manager):
        """Test adding clip with source app."""
        clip = clipboard_manager.add_clip("Test", source_app="TestApp")
        assert clip.source_app == "TestApp"

    def test_get_recent_history(self, clipboard_manager):
        """Test getting recent history."""
        clipboard_manager.add_clip("Item 1")
        clipboard_manager.add_clip("Item 2")
        clipboard_manager.add_clip("Item 3")

        recent = clipboard_manager.get_recent_history()
        assert len(recent) <= clipboard_manager.history_store.display_count

    def test_get_all_history(self, clipboard_manager):
        """Test getting all history."""
        clipboard_manager.add_clip("Item 1")
        clipboard_manager.add_clip("Item 2")

        all_items = clipboard_manager.get_all_history()
        assert len(all_items) == 2

    def test_get_all_history_with_limit(self, clipboard_manager):
        """Test getting history with limit."""
        for i in range(10):
            clipboard_manager.add_clip(f"Item {i}")

        limited = clipboard_manager.get_all_history(limit=5)
        assert len(limited) == 5

    def test_clear_history(self, clipboard_manager):
        """Test clearing history."""
        clipboard_manager.add_clip("Item 1")
        clipboard_manager.add_clip("Item 2")
        clipboard_manager.clear_history()

        assert len(clipboard_manager.history_store.items) == 0

    def test_delete_history_item(self, clipboard_manager):
        """Test deleting specific history item."""
        clip = clipboard_manager.add_clip("Test item")
        result = clipboard_manager.delete_history_item(clip.clip_id)

        assert result is True
        assert len(clipboard_manager.history_store.items) == 0

    def test_delete_nonexistent_history_item(self, clipboard_manager):
        """Test deleting non-existent item."""
        result = clipboard_manager.delete_history_item("nonexistent")
        assert result is False

    def test_save_as_snippet(self, clipboard_manager):
        """Test converting history item to snippet."""
        clip = clipboard_manager.add_clip("Code snippet")
        snippet = clipboard_manager.save_as_snippet(
            clip.clip_id, "My Snippet", "Code", ["python"]
        )

        assert snippet is not None
        assert snippet.snippet_name == "My Snippet"
        assert snippet.folder_path == "Code"
        assert len(clipboard_manager.snippet_store.folders["Code"]) == 1

    def test_save_as_snippet_nonexistent(self, clipboard_manager):
        """Test converting non-existent item to snippet."""
        result = clipboard_manager.save_as_snippet("nonexistent", "Name", "Folder", [])
        assert result is None

    def test_create_snippet_folder(self, clipboard_manager):
        """Test creating snippet folder."""
        result = clipboard_manager.create_snippet_folder("MyFolder")
        assert result is True
        assert "MyFolder" in clipboard_manager.snippet_store.folders

    def test_create_duplicate_folder(self, clipboard_manager):
        """Test creating duplicate folder."""
        clipboard_manager.create_snippet_folder("MyFolder")
        result = clipboard_manager.create_snippet_folder("MyFolder")
        assert result is False

    def test_rename_snippet_folder(self, clipboard_manager):
        """Test renaming snippet folder."""
        clipboard_manager.create_snippet_folder("OldName")
        result = clipboard_manager.rename_snippet_folder("OldName", "NewName")

        assert result is True
        assert "NewName" in clipboard_manager.snippet_store.folders
        assert "OldName" not in clipboard_manager.snippet_store.folders

    def test_rename_nonexistent_folder(self, clipboard_manager):
        """Test renaming non-existent folder."""
        result = clipboard_manager.rename_snippet_folder("NonExistent", "NewName")
        assert result is False

    def test_delete_snippet_folder(self, clipboard_manager):
        """Test deleting snippet folder."""
        clipboard_manager.create_snippet_folder("ToDelete")
        result = clipboard_manager.delete_snippet_folder("ToDelete")

        assert result is True
        assert "ToDelete" not in clipboard_manager.snippet_store.folders

    def test_get_snippet_folders(self, clipboard_manager):
        """Test getting snippet folder names."""
        clipboard_manager.create_snippet_folder("Folder1")
        clipboard_manager.create_snippet_folder("Folder2")

        folders = clipboard_manager.get_snippet_folders()
        assert "Folder1" in folders
        assert "Folder2" in folders

    def test_add_snippet_direct(self, clipboard_manager):
        """Test adding snippet directly."""
        snippet = clipboard_manager.add_snippet_direct(
            "Direct snippet", "My Snippet", "Code", ["test"]
        )

        assert snippet.snippet_name == "My Snippet"
        assert snippet.folder_path == "Code"
        assert "Code" in clipboard_manager.snippet_store.folders

    def test_get_folder_snippets(self, clipboard_manager):
        """Test getting snippets from folder."""
        clipboard_manager.add_snippet_direct("Snippet 1", "S1", "Folder", [])
        clipboard_manager.add_snippet_direct("Snippet 2", "S2", "Folder", [])

        snippets = clipboard_manager.get_folder_snippets("Folder")
        assert len(snippets) == 2

    def test_get_all_snippets(self, clipboard_manager):
        """Test getting all snippets organized by folder."""
        clipboard_manager.add_snippet_direct("S1", "S1", "Folder1", [])
        clipboard_manager.add_snippet_direct("S2", "S2", "Folder2", [])

        all_snippets = clipboard_manager.get_all_snippets()
        assert "Folder1" in all_snippets
        assert "Folder2" in all_snippets

    def test_update_snippet(self, clipboard_manager):
        """Test updating snippet properties."""
        snippet = clipboard_manager.add_snippet_direct("Old", "Old Name", "Folder", [])
        result = clipboard_manager.update_snippet(
            "Folder", snippet.clip_id, "New content", "New Name", ["new_tag"]
        )

        assert result is True
        updated = clipboard_manager.get_folder_snippets("Folder")[0]
        assert updated.content == "New content"
        assert updated.snippet_name == "New Name"

    def test_delete_snippet(self, clipboard_manager):
        """Test deleting snippet."""
        snippet = clipboard_manager.add_snippet_direct("Test", "Test", "Folder", [])
        result = clipboard_manager.delete_snippet("Folder", snippet.clip_id)

        assert result is True
        assert len(clipboard_manager.get_folder_snippets("Folder")) == 0

    def test_move_snippet(self, clipboard_manager):
        """Test moving snippet between folders."""
        clipboard_manager.create_snippet_folder("Folder1")
        clipboard_manager.create_snippet_folder("Folder2")
        snippet = clipboard_manager.add_snippet_direct("Test", "Test", "Folder1", [])

        result = clipboard_manager.move_snippet("Folder1", "Folder2", snippet.clip_id)

        assert result is True
        assert len(clipboard_manager.get_folder_snippets("Folder1")) == 0
        assert len(clipboard_manager.get_folder_snippets("Folder2")) == 1

    def test_search_all(self, clipboard_manager):
        """Test searching across history and snippets."""
        clipboard_manager.add_clip("Python code here")
        clipboard_manager.add_snippet_direct("JavaScript code", "JS", "Code", [])

        results = clipboard_manager.search_all("code")
        assert len(results["history"]) == 1
        assert len(results["snippets"]) == 1

    def test_search_all_no_results(self, clipboard_manager):
        """Test search with no matches."""
        clipboard_manager.add_clip("Test")
        results = clipboard_manager.search_all("nonexistent")

        assert len(results["history"]) == 0
        assert len(results["snippets"]) == 0

    def test_save_stores(self, clipboard_manager, temp_data_dir):
        """Test saving stores to disk."""
        clipboard_manager.add_clip("History item")
        clipboard_manager.add_snippet_direct("Snippet", "S1", "Folder", [])

        clipboard_manager.save_stores()

        assert os.path.exists(clipboard_manager.history_file)
        assert os.path.exists(clipboard_manager.snippets_file)

    def test_load_stores(self, temp_data_dir):
        """Test loading stores from disk."""
        # Create and save data
        manager1 = ClipboardManager(data_dir=temp_data_dir)
        manager1.add_clip("Persisted item")
        manager1.add_snippet_direct("Persisted snippet", "S1", "Folder", [])
        manager1.save_stores()

        # Load in new instance
        manager2 = ClipboardManager(data_dir=temp_data_dir)
        assert len(manager2.history_store.items) == 1
        assert "Folder" in manager2.snippet_store.folders

    def test_get_stats(self, clipboard_manager):
        """Test getting manager statistics."""
        clipboard_manager.add_clip("Item 1")
        clipboard_manager.add_clip("Item 2")
        clipboard_manager.add_snippet_direct("S1", "S1", "F1", [])
        clipboard_manager.create_snippet_folder("F2")

        stats = clipboard_manager.get_stats()
        assert stats["history_count"] == 2
        assert stats["snippet_count"] == 1
        assert stats["folder_count"] == 2
        assert stats["max_history"] == 50

    def test_auto_save_disabled(self, temp_data_dir):
        """Test with auto-save disabled."""
        manager = ClipboardManager(data_dir=temp_data_dir)
        manager.auto_save_enabled = False

        manager.add_clip("Test")
        # File shouldn't be created yet
        assert (
            not os.path.exists(manager.history_file)
            or os.path.getsize(manager.history_file) == 0
        )

    def test_get_history_folders(self, clipboard_manager):
        """Test getting auto-generated history folders."""
        for i in range(15):
            clipboard_manager.add_clip(f"Item {i}")

        folders = clipboard_manager.get_history_folders()
        assert len(folders) > 0
        assert all("name" in f for f in folders)
        assert all("count" in f for f in folders)
