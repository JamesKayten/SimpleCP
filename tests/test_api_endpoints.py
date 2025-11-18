"""Tests for API endpoints."""

import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient
from api.endpoints import create_router
from clipboard_manager import ClipboardManager
from fastapi import FastAPI


@pytest.fixture
def api_client(clipboard_manager):
    """Create FastAPI test client."""
    app = FastAPI()
    router = create_router(clipboard_manager)
    app.include_router(router)
    return TestClient(app), clipboard_manager


class TestHistoryEndpoints:
    """Test history-related endpoints."""

    def test_get_history_empty(self, api_client):
        """Test getting empty history."""
        client, _ = api_client
        response = client.get("/api/history")
        assert response.status_code == 200
        assert response.json() == []

    def test_get_history_with_items(self, api_client):
        """Test getting history with items."""
        client, manager = api_client
        manager.add_clip("Item 1")
        manager.add_clip("Item 2")

        response = client.get("/api/history")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    def test_get_history_with_limit(self, api_client):
        """Test getting history with limit parameter."""
        client, manager = api_client
        for i in range(10):
            manager.add_clip(f"Item {i}")

        response = client.get("/api/history?limit=5")
        assert response.status_code == 200
        assert len(response.json()) == 5

    def test_get_recent_history(self, api_client):
        """Test getting recent history."""
        client, manager = api_client
        manager.add_clip("Recent item")

        response = client.get("/api/history/recent")
        assert response.status_code == 200
        assert len(response.json()) >= 1

    def test_get_history_folders(self, api_client):
        """Test getting history folders."""
        client, manager = api_client
        for i in range(15):
            manager.add_clip(f"Item {i}")

        response = client.get("/api/history/folders")
        assert response.status_code == 200
        folders = response.json()
        assert isinstance(folders, list)

    def test_delete_history_item(self, api_client):
        """Test deleting history item."""
        client, manager = api_client
        clip = manager.add_clip("To delete")

        response = client.delete(f"/api/history/{clip.clip_id}")
        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_delete_nonexistent_item(self, api_client):
        """Test deleting non-existent item."""
        client, _ = api_client
        response = client.delete("/api/history/nonexistent")
        assert response.status_code == 404

    def test_clear_history(self, api_client):
        """Test clearing all history."""
        client, manager = api_client
        manager.add_clip("Item 1")
        manager.add_clip("Item 2")

        response = client.delete("/api/history")
        assert response.status_code == 200
        assert len(manager.history_store.items) == 0


class TestSnippetEndpoints:
    """Test snippet-related endpoints."""

    def test_get_all_snippets_empty(self, api_client):
        """Test getting empty snippets."""
        client, _ = api_client
        response = client.get("/api/snippets")
        assert response.status_code == 200
        assert response.json() == []

    def test_get_all_snippets(self, api_client):
        """Test getting all snippets."""
        client, manager = api_client
        manager.add_snippet_direct("Snippet 1", "S1", "Folder1", [])
        manager.add_snippet_direct("Snippet 2", "S2", "Folder2", [])

        response = client.get("/api/snippets")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    def test_get_snippet_folders(self, api_client):
        """Test getting snippet folder names."""
        client, manager = api_client
        manager.create_snippet_folder("Folder1")
        manager.create_snippet_folder("Folder2")

        response = client.get("/api/snippets/folders")
        assert response.status_code == 200
        folders = response.json()
        assert "Folder1" in folders
        assert "Folder2" in folders

    def test_get_folder_snippets(self, api_client):
        """Test getting snippets in a folder."""
        client, manager = api_client
        manager.add_snippet_direct("S1", "S1", "MyFolder", [])
        manager.add_snippet_direct("S2", "S2", "MyFolder", [])

        response = client.get("/api/snippets/MyFolder")
        assert response.status_code == 200
        assert len(response.json()) == 2

    def test_create_snippet_from_history(self, api_client):
        """Test creating snippet from history item."""
        client, manager = api_client
        clip = manager.add_clip("Code here")

        response = client.post(
            "/api/snippets",
            json={
                "clip_id": clip.clip_id,
                "name": "My Snippet",
                "folder": "Code",
                "tags": ["python"],
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["snippet_name"] == "My Snippet"

    def test_create_snippet_direct(self, api_client):
        """Test creating snippet directly."""
        client, _ = api_client
        response = client.post(
            "/api/snippets",
            json={
                "content": "def test(): pass",
                "name": "Test Function",
                "folder": "Code",
                "tags": ["python"],
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["snippet_name"] == "Test Function"

    def test_create_snippet_missing_data(self, api_client):
        """Test creating snippet without clip_id or content."""
        client, _ = api_client
        response = client.post(
            "/api/snippets", json={"name": "Test", "folder": "Code", "tags": []}
        )

        assert response.status_code == 400

    def test_create_snippet_nonexistent_clip(self, api_client):
        """Test creating snippet from non-existent clip."""
        client, _ = api_client
        response = client.post(
            "/api/snippets",
            json={
                "clip_id": "nonexistent",
                "name": "Test",
                "folder": "Code",
                "tags": [],
            },
        )

        assert response.status_code == 404

    def test_update_snippet(self, api_client):
        """Test updating snippet."""
        client, manager = api_client
        snippet = manager.add_snippet_direct("Old", "Old", "Folder", [])

        response = client.put(
            f"/api/snippets/Folder/{snippet.clip_id}",
            json={"content": "New content", "name": "New name", "tags": ["new"]},
        )

        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_update_nonexistent_snippet(self, api_client):
        """Test updating non-existent snippet."""
        client, manager = api_client
        manager.create_snippet_folder("Folder")

        response = client.put(
            "/api/snippets/Folder/nonexistent", json={"content": "New"}
        )

        assert response.status_code == 404

    def test_delete_snippet(self, api_client):
        """Test deleting snippet."""
        client, manager = api_client
        snippet = manager.add_snippet_direct("Test", "Test", "Folder", [])

        response = client.delete(f"/api/snippets/Folder/{snippet.clip_id}")
        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_delete_nonexistent_snippet(self, api_client):
        """Test deleting non-existent snippet."""
        client, manager = api_client
        manager.create_snippet_folder("Folder")

        response = client.delete("/api/snippets/Folder/nonexistent")
        assert response.status_code == 404

    def test_move_snippet(self, api_client):
        """Test moving snippet to different folder."""
        client, manager = api_client
        manager.create_snippet_folder("Folder1")
        manager.create_snippet_folder("Folder2")
        snippet = manager.add_snippet_direct("Test", "Test", "Folder1", [])

        response = client.post(
            f"/api/snippets/Folder1/{snippet.clip_id}/move",
            json={"to_folder": "Folder2"},
        )

        assert response.status_code == 200
        assert len(manager.get_folder_snippets("Folder2")) == 1


class TestFolderEndpoints:
    """Test folder-related endpoints."""

    def test_create_folder(self, api_client):
        """Test creating folder."""
        client, _ = api_client
        response = client.post("/api/folders", json={"folder_name": "NewFolder"})

        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_create_duplicate_folder(self, api_client):
        """Test creating duplicate folder."""
        client, manager = api_client
        manager.create_snippet_folder("Existing")

        response = client.post("/api/folders", json={"folder_name": "Existing"})

        assert response.status_code == 409

    def test_rename_folder(self, api_client):
        """Test renaming folder."""
        client, manager = api_client
        manager.create_snippet_folder("OldName")

        response = client.put("/api/folders/OldName", json={"new_name": "NewName"})

        assert response.status_code == 200
        assert "NewName" in manager.get_snippet_folders()

    def test_rename_nonexistent_folder(self, api_client):
        """Test renaming non-existent folder."""
        client, _ = api_client
        response = client.put("/api/folders/NonExistent", json={"new_name": "NewName"})

        assert response.status_code == 404

    def test_delete_folder(self, api_client):
        """Test deleting folder."""
        client, manager = api_client
        manager.create_snippet_folder("ToDelete")

        response = client.delete("/api/folders/ToDelete")
        assert response.status_code == 200
        assert "ToDelete" not in manager.get_snippet_folders()


class TestOtherEndpoints:
    """Test search, stats, and clipboard endpoints."""

    def test_search(self, api_client):
        """Test search endpoint."""
        client, manager = api_client
        manager.add_clip("Python code")
        manager.add_snippet_direct("JavaScript", "JS", "Code", [])

        response = client.get("/api/search?q=code")
        assert response.status_code == 200
        data = response.json()
        assert "history" in data
        assert "snippets" in data

    def test_search_empty(self, api_client):
        """Test search with no results."""
        client, _ = api_client
        response = client.get("/api/search?q=nonexistent")

        assert response.status_code == 200
        data = response.json()
        assert len(data["history"]) == 0
        assert len(data["snippets"]) == 0

    def test_get_stats(self, api_client):
        """Test stats endpoint."""
        client, manager = api_client
        manager.add_clip("Item")
        manager.add_snippet_direct("Snippet", "S", "Folder", [])

        response = client.get("/api/stats")
        assert response.status_code == 200
        stats = response.json()
        assert stats["history_count"] == 1
        assert stats["snippet_count"] == 1
        assert "folder_count" in stats

    @patch("pyperclip.copy")
    def test_copy_to_clipboard_history(self, mock_copy, api_client):
        """Test copying history item to clipboard."""
        client, manager = api_client
        clip = manager.add_clip("Copy me")

        response = client.post("/api/clipboard/copy", json={"clip_id": clip.clip_id})

        assert response.status_code == 200
        assert response.json()["success"] is True
        mock_copy.assert_called_once_with("Copy me")

    @patch("pyperclip.copy")
    def test_copy_to_clipboard_snippet(self, mock_copy, api_client):
        """Test copying snippet to clipboard."""
        client, manager = api_client
        snippet = manager.add_snippet_direct("Copy me", "S", "Folder", [])

        response = client.post("/api/clipboard/copy", json={"clip_id": snippet.clip_id})

        assert response.status_code == 200
        mock_copy.assert_called_once_with("Copy me")

    def test_copy_nonexistent_item(self, api_client):
        """Test copying non-existent item."""
        client, _ = api_client
        response = client.post("/api/clipboard/copy", json={"clip_id": "nonexistent"})

        assert response.status_code == 404
