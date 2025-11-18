"""
Unit tests for SnippetStore class.
"""

import pytest
from stores.clipboard_item import ClipboardItem


class TestSnippetStore:
    """Test SnippetStore functionality."""

    def test_create_folder(self, snippet_store):
        """Test creating a folder."""
        folder = snippet_store.create_folder("Test Folder")
        assert folder is not None
        assert "Test Folder" in snippet_store.get_folders()

    def test_add_snippet(self, snippet_store):
        """Test adding a snippet to a folder."""
        snippet_store.create_folder("Code")
        item = ClipboardItem(content="print('hello')", content_type="code")

        snippet_store.add("Code", item, name="Hello World")
        items = snippet_store.get_folder_items("Code")

        assert len(items) == 1
        assert items[0].name == "Hello World"

    def test_move_snippet(self, snippet_store):
        """Test moving a snippet between folders."""
        snippet_store.create_folder("Folder1")
        snippet_store.create_folder("Folder2")

        item = ClipboardItem(content="test", content_type="text")
        snippet_store.add("Folder1", item, name="Test")

        snippet_store.move(item.clip_id, "Folder1", "Folder2")

        folder1_items = snippet_store.get_folder_items("Folder1")
        folder2_items = snippet_store.get_folder_items("Folder2")

        assert len(folder1_items) == 0
        assert len(folder2_items) == 1

    def test_delete_snippet(self, snippet_store):
        """Test deleting a snippet."""
        snippet_store.create_folder("Code")
        item = ClipboardItem(content="test", content_type="text")
        snippet_store.add("Code", item, name="Test")

        items_before = snippet_store.get_folder_items("Code")
        assert len(items_before) == 1

        snippet_store.delete("Code", item.clip_id)
        items_after = snippet_store.get_folder_items("Code")
        assert len(items_after) == 0

    def test_rename_folder(self, snippet_store):
        """Test renaming a folder."""
        snippet_store.create_folder("Old Name")
        snippet_store.rename_folder("Old Name", "New Name")

        folders = snippet_store.get_folders()
        assert "Old Name" not in folders
        assert "New Name" in folders

    def test_delete_folder(self, snippet_store):
        """Test deleting a folder."""
        snippet_store.create_folder("Test")
        assert "Test" in snippet_store.get_folders()

        snippet_store.delete_folder("Test")
        assert "Test" not in snippet_store.get_folders()

    def test_search_snippets(self, snippet_store):
        """Test searching across all snippets."""
        snippet_store.create_folder("Code")
        item1 = ClipboardItem(content="python code", content_type="code")
        item2 = ClipboardItem(content="javascript code", content_type="code")

        snippet_store.add("Code", item1, name="Python")
        snippet_store.add("Code", item2, name="JavaScript")

        results = snippet_store.search("python")
        assert len(results) == 1
        assert results[0].content == "python code"
