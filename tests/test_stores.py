"""Tests for store modules."""

import pytest
from stores.clipboard_item import ClipboardItem
from stores.history_store import HistoryStore
from stores.snippet_store import SnippetStore


class TestHistoryStore:
    """Test HistoryStore functionality."""

    def test_init(self):
        """Test HistoryStore initialization."""
        store = HistoryStore(max_items=100, display_count=20)
        assert store.max_items == 100
        assert store.display_count == 20
        assert len(store.items) == 0

    def test_insert_item(self):
        """Test inserting item."""
        store = HistoryStore()
        item = ClipboardItem(content="Test")
        store.insert(item)
        assert len(store.items) == 1
        assert store.modified is True

    def test_insert_duplicate(self):
        """Test inserting duplicate item."""
        store = HistoryStore()
        item1 = ClipboardItem(content="Same content")
        item2 = ClipboardItem(content="Same content")

        store.insert(item1)
        store.insert(item2)

        # Should only have one item due to deduplication
        assert len(store.items) == 1

    def test_max_items_enforcement(self):
        """Test that max_items limit is enforced."""
        store = HistoryStore(max_items=5)

        for i in range(10):
            store.insert(ClipboardItem(content=f"Item {i}"))

        assert len(store.items) == 5

    def test_get_items(self):
        """Test getting all items."""
        store = HistoryStore()
        for i in range(5):
            store.insert(ClipboardItem(content=f"Item {i}"))

        items = store.get_items()
        assert len(items) == 5

    def test_get_items_with_limit(self):
        """Test getting items with limit."""
        store = HistoryStore()
        for i in range(10):
            store.insert(ClipboardItem(content=f"Item {i}"))

        items = store.get_items(limit=3)
        assert len(items) == 3

    def test_get_recent_items(self):
        """Test getting recent items."""
        store = HistoryStore(display_count=5)
        for i in range(10):
            store.insert(ClipboardItem(content=f"Item {i}"))

        recent = store.get_recent_items()
        assert len(recent) <= 5

    def test_get_auto_folders(self):
        """Test getting auto-generated folders."""
        store = HistoryStore()
        for i in range(25):
            store.insert(ClipboardItem(content=f"Item {i}"))

        folders = store.get_auto_folders()
        assert len(folders) > 0
        assert all("name" in f for f in folders)
        assert all("items" in f for f in folders)

    def test_get_auto_folders_empty(self):
        """Test auto folders with empty store."""
        store = HistoryStore()
        folders = store.get_auto_folders()
        assert folders == []

    def test_delete_item(self):
        """Test deleting item by index."""
        store = HistoryStore()
        for i in range(5):
            store.insert(ClipboardItem(content=f"Item {i}"))

        store.delete_item(2)
        assert len(store.items) == 4

    def test_delete_invalid_index(self):
        """Test deleting with invalid index."""
        store = HistoryStore()
        store.insert(ClipboardItem(content="Test"))

        # Should not raise error for invalid index
        store.delete_item(999)
        assert len(store.items) == 1

    def test_clear(self):
        """Test clearing all items."""
        store = HistoryStore()
        for i in range(5):
            store.insert(ClipboardItem(content=f"Item {i}"))

        store.clear()
        assert len(store.items) == 0

    def test_search(self):
        """Test searching items."""
        store = HistoryStore()
        store.insert(ClipboardItem(content="Python code"))
        store.insert(ClipboardItem(content="JavaScript code"))
        store.insert(ClipboardItem(content="HTML markup"))

        results = store.search("code")
        assert len(results) == 2

    def test_search_no_results(self):
        """Test search with no matches."""
        store = HistoryStore()
        store.insert(ClipboardItem(content="Test"))

        results = store.search("nonexistent")
        assert len(results) == 0

    def test_len(self):
        """Test __len__ method."""
        store = HistoryStore()
        for i in range(5):
            store.insert(ClipboardItem(content=f"Item {i}"))

        assert len(store) == 5

    def test_modified_flag(self):
        """Test modified flag tracking."""
        store = HistoryStore()
        assert store.modified is False

        store.insert(ClipboardItem(content="Test"))
        assert store.modified is True

        store.modified = False
        store.clear()
        assert store.modified is True


class TestSnippetStore:
    """Test SnippetStore functionality."""

    def test_init(self):
        """Test SnippetStore initialization."""
        store = SnippetStore()
        assert len(store.folders) == 0
        assert store.modified is False

    def test_create_folder(self):
        """Test creating folder."""
        store = SnippetStore()
        result = store.create_folder("MyFolder")
        assert result is True
        assert "MyFolder" in store.folders
        assert store.modified is True

    def test_create_duplicate_folder(self):
        """Test creating duplicate folder."""
        store = SnippetStore()
        store.create_folder("MyFolder")
        result = store.create_folder("MyFolder")
        assert result is False

    def test_rename_folder(self):
        """Test renaming folder."""
        store = SnippetStore()
        store.create_folder("OldName")
        result = store.rename_folder("OldName", "NewName")

        assert result is True
        assert "NewName" in store.folders
        assert "OldName" not in store.folders

    def test_rename_nonexistent_folder(self):
        """Test renaming non-existent folder."""
        store = SnippetStore()
        result = store.rename_folder("NonExistent", "NewName")
        assert result is False

    def test_rename_to_existing_name(self):
        """Test renaming to existing folder name."""
        store = SnippetStore()
        store.create_folder("Folder1")
        store.create_folder("Folder2")

        result = store.rename_folder("Folder1", "Folder2")
        assert result is False

    def test_delete_folder(self):
        """Test deleting folder."""
        store = SnippetStore()
        store.create_folder("ToDelete")
        result = store.delete_folder("ToDelete")

        assert result is True
        assert "ToDelete" not in store.folders

    def test_delete_nonexistent_folder(self):
        """Test deleting non-existent folder."""
        store = SnippetStore()
        result = store.delete_folder("NonExistent")
        assert result is False

    def test_add_snippet(self):
        """Test adding snippet to folder."""
        store = SnippetStore()
        snippet = ClipboardItem(content="Code")
        snippet.make_snippet("My Snippet", "Code", [])

        store.add_snippet("Code", snippet)
        assert "Code" in store.folders
        assert len(store.folders["Code"]) == 1

    def test_get_folder_items(self):
        """Test getting folder items."""
        store = SnippetStore()
        snippet = ClipboardItem(content="Code")
        snippet.make_snippet("S1", "Folder", [])
        store.add_snippet("Folder", snippet)

        items = store.get_folder_items("Folder")
        assert len(items) == 1

    def test_get_folder_items_nonexistent(self):
        """Test getting items from non-existent folder."""
        store = SnippetStore()
        items = store.get_folder_items("NonExistent")
        assert items == []

    def test_get_all_snippets(self):
        """Test getting all snippets."""
        store = SnippetStore()
        s1 = ClipboardItem(content="C1")
        s1.make_snippet("S1", "F1", [])
        s2 = ClipboardItem(content="C2")
        s2.make_snippet("S2", "F2", [])

        store.add_snippet("F1", s1)
        store.add_snippet("F2", s2)

        all_snippets = store.get_all_snippets()
        assert "F1" in all_snippets
        assert "F2" in all_snippets

    def test_get_folder_names(self):
        """Test getting folder names."""
        store = SnippetStore()
        store.create_folder("Folder1")
        store.create_folder("Folder2")

        names = store.get_folder_names()
        assert "Folder1" in names
        assert "Folder2" in names

    def test_update_snippet(self):
        """Test updating snippet."""
        store = SnippetStore()
        snippet = ClipboardItem(content="Old")
        snippet.make_snippet("Old Name", "Folder", [])
        store.add_snippet("Folder", snippet)

        result = store.update_snippet(
            "Folder", snippet.clip_id, "New", "New Name", ["new"]
        )

        assert result is True
        updated = store.folders["Folder"][0]
        assert updated.content == "New"
        assert updated.snippet_name == "New Name"

    def test_update_snippet_partial(self):
        """Test updating snippet with partial data."""
        store = SnippetStore()
        snippet = ClipboardItem(content="Content")
        snippet.make_snippet("Name", "Folder", ["tag1"])
        store.add_snippet("Folder", snippet)

        # Update only name
        result = store.update_snippet("Folder", snippet.clip_id, None, "New Name", None)

        assert result is True
        updated = store.folders["Folder"][0]
        assert updated.content == "Content"  # Unchanged
        assert updated.snippet_name == "New Name"  # Changed

    def test_update_nonexistent_snippet(self):
        """Test updating non-existent snippet."""
        store = SnippetStore()
        store.create_folder("Folder")

        result = store.update_snippet("Folder", "nonexistent", "New", None, None)
        assert result is False

    def test_delete_snippet(self):
        """Test deleting snippet."""
        store = SnippetStore()
        snippet = ClipboardItem(content="Test")
        snippet.make_snippet("Test", "Folder", [])
        store.add_snippet("Folder", snippet)

        result = store.delete_snippet("Folder", snippet.clip_id)
        assert result is True
        assert len(store.folders["Folder"]) == 0

    def test_delete_nonexistent_snippet(self):
        """Test deleting non-existent snippet."""
        store = SnippetStore()
        store.create_folder("Folder")

        result = store.delete_snippet("Folder", "nonexistent")
        assert result is False

    def test_move_snippet(self):
        """Test moving snippet between folders."""
        store = SnippetStore()
        store.create_folder("Folder1")
        store.create_folder("Folder2")

        snippet = ClipboardItem(content="Test")
        snippet.make_snippet("Test", "Folder1", [])
        store.add_snippet("Folder1", snippet)

        result = store.move_snippet("Folder1", "Folder2", snippet.clip_id)

        assert result is True
        assert len(store.folders["Folder1"]) == 0
        assert len(store.folders["Folder2"]) == 1

    def test_move_snippet_nonexistent_source(self):
        """Test moving from non-existent folder."""
        store = SnippetStore()
        store.create_folder("Folder2")

        result = store.move_snippet("NonExistent", "Folder2", "some_id")
        assert result is False

    def test_move_snippet_nonexistent_dest(self):
        """Test moving to non-existent folder (creates destination)."""
        store = SnippetStore()
        snippet = ClipboardItem(content="Test")
        snippet.make_snippet("Test", "Folder1", [])
        store.add_snippet("Folder1", snippet)

        result = store.move_snippet("Folder1", "NonExistent", snippet.clip_id)
        # Should succeed and create destination folder
        assert result is True
        assert "NonExistent" in store.folders

    def test_get_snippet_by_id(self):
        """Test getting snippet by ID."""
        store = SnippetStore()
        snippet = ClipboardItem(content="Test")
        snippet.make_snippet("Test", "Folder", [])
        store.add_snippet("Folder", snippet)

        found = store.get_snippet_by_id(snippet.clip_id)
        assert found is not None
        assert found.clip_id == snippet.clip_id

    def test_get_snippet_by_id_not_found(self):
        """Test getting non-existent snippet by ID."""
        store = SnippetStore()
        found = store.get_snippet_by_id("nonexistent")
        assert found is None

    def test_search(self):
        """Test searching snippets."""
        store = SnippetStore()
        s1 = ClipboardItem(content="Python code")
        s1.make_snippet("Python", "Code", ["python"])
        s2 = ClipboardItem(content="JavaScript code")
        s2.make_snippet("JS", "Code", ["js"])

        store.add_snippet("Code", s1)
        store.add_snippet("Code", s2)

        results = store.search("python")
        assert len(results) == 1

    def test_len(self):
        """Test __len__ method."""
        store = SnippetStore()
        s1 = ClipboardItem(content="S1")
        s1.make_snippet("S1", "F1", [])
        s2 = ClipboardItem(content="S2")
        s2.make_snippet("S2", "F2", [])

        store.add_snippet("F1", s1)
        store.add_snippet("F2", s2)

        assert len(store) == 2
