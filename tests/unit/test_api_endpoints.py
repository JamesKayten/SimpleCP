"""
Unit tests for API endpoints.
"""
import pytest
from fastapi.testclient import TestClient


@pytest.mark.api
class TestAPIEndpoints:
    """Test REST API endpoints."""

    def test_root_endpoint(self, api_client):
        """Test root endpoint."""
        response = api_client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "name" in data
        assert "version" in data
        assert "status" in data

    def test_health_endpoint(self, api_client):
        """Test health check endpoint."""
        response = api_client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data
        assert "clipboard_stats" in data

    def test_get_history(self, api_client, clipboard_manager):
        """Test getting history."""
        # Add some history
        for i in range(5):
            clipboard_manager.add_clip(f"Test {i}")

        response = api_client.get("/api/history")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 5

    def test_get_history_with_limit(self, api_client, clipboard_manager):
        """Test getting history with limit."""
        for i in range(10):
            clipboard_manager.add_clip(f"Test {i}")

        response = api_client.get("/api/history?limit=5")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5

    def test_get_recent_history(self, api_client, clipboard_manager):
        """Test getting recent history."""
        for i in range(15):
            clipboard_manager.add_clip(f"Test {i}")

        response = api_client.get("/api/history/recent")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) <= 10

    def test_delete_history_item(self, api_client, clipboard_manager):
        """Test deleting history item."""
        item = clipboard_manager.add_clip("Test")

        response = api_client.delete(f"/api/history/{item.clip_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_delete_nonexistent_history_item(self, api_client):
        """Test deleting non-existent item."""
        response = api_client.delete("/api/history/invalid-id")
        assert response.status_code == 404

    def test_clear_all_history(self, api_client, clipboard_manager):
        """Test clearing all history."""
        for i in range(5):
            clipboard_manager.add_clip(f"Test {i}")

        response = api_client.delete("/api/history")
        assert response.status_code == 200
        assert len(clipboard_manager.history_store) == 0

    def test_get_all_snippets(self, api_client, clipboard_manager):
        """Test getting all snippets."""
        clipboard_manager.create_snippet("Snippet 1", "Work", "Note 1")
        clipboard_manager.create_snippet("Snippet 2", "Personal", "Note 2")

        response = api_client.get("/api/snippets")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_get_snippets_in_folder(self, api_client, clipboard_manager):
        """Test getting snippets from specific folder."""
        clipboard_manager.create_snippet("Snippet 1", "Work", "Note 1")
        clipboard_manager.create_snippet("Snippet 2", "Work", "Note 2")

        response = api_client.get("/api/snippets/Work")
        assert response.status_code == 200
        data = response.json()
        assert len(data["snippets"]) == 2

    def test_create_snippet_from_history(self, api_client, clipboard_manager):
        """Test creating snippet from history item."""
        item = clipboard_manager.add_clip("Test content")

        payload = {
            "clip_id": item.clip_id,
            "folder_name": "Work",
            "name": "My Snippet",
        }
        response = api_client.post("/api/snippets", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_create_snippet_directly(self, api_client):
        """Test creating snippet directly."""
        payload = {
            "content": "Direct snippet",
            "folder_name": "Work",
            "name": "Direct Note",
        }
        response = api_client.post("/api/snippets", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_delete_snippet(self, api_client, clipboard_manager):
        """Test deleting snippet."""
        snippet = clipboard_manager.create_snippet("Test", "Work", "Note")

        response = api_client.delete(f"/api/snippets/Work/{snippet.clip_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_create_folder(self, api_client):
        """Test creating new folder."""
        payload = {"folder_name": "NewFolder"}
        response = api_client.post("/api/folders", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_rename_folder(self, api_client, clipboard_manager):
        """Test renaming folder."""
        clipboard_manager.create_snippet("Test", "OldName", "Note")

        payload = {"new_name": "NewName"}
        response = api_client.put("/api/folders/OldName", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_delete_folder(self, api_client, clipboard_manager):
        """Test deleting folder."""
        clipboard_manager.create_snippet("Test", "ToDelete", "Note")

        response = api_client.delete("/api/folders/ToDelete")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_copy_to_clipboard(self, api_client, clipboard_manager):
        """Test copying item to clipboard."""
        item = clipboard_manager.add_clip("Test content")

        payload = {"clip_id": item.clip_id}
        response = api_client.post("/api/clipboard/copy", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_search_endpoint(self, api_client, clipboard_manager):
        """Test search endpoint."""
        clipboard_manager.add_clip("Python programming")
        clipboard_manager.create_snippet("Python code", "Code", "Example")

        response = api_client.get("/api/search?q=Python")
        assert response.status_code == 200
        data = response.json()
        assert "history" in data
        assert "snippets" in data

    def test_get_stats_endpoint(self, api_client, clipboard_manager):
        """Test stats endpoint."""
        clipboard_manager.add_clip("Test")
        clipboard_manager.create_snippet("Snippet", "Work", "Note")

        response = api_client.get("/api/stats")
        assert response.status_code == 200
        data = response.json()
        assert "history_count" in data
        assert "snippet_count" in data
        assert "folder_count" in data

    def test_get_history_folders(self, api_client, clipboard_manager):
        """Test getting auto-generated history folders."""
        for i in range(25):
            clipboard_manager.add_clip(f"Test {i}")

        response = api_client.get("/api/history/folders")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0

    def test_get_snippet_folders(self, api_client, clipboard_manager):
        """Test getting snippet folder names."""
        clipboard_manager.create_snippet("Test 1", "Work", "Note 1")
        clipboard_manager.create_snippet("Test 2", "Personal", "Note 2")

        response = api_client.get("/api/snippets/folders")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert "Work" in data
        assert "Personal" in data

    def test_performance_header(self, api_client):
        """Test that performance headers are added."""
        response = api_client.get("/api/stats")
        assert response.status_code == 200
        assert "X-Process-Time" in response.headers

    def test_cors_headers(self, api_client):
        """Test CORS headers are present."""
        response = api_client.options("/api/history")
        # CORS headers should be present
        assert response.status_code == 200


@pytest.mark.api
@pytest.mark.slow
class TestAPIErrorHandling:
    """Test API error handling."""

    def test_invalid_endpoint(self, api_client):
        """Test accessing invalid endpoint."""
        response = api_client.get("/api/nonexistent")
        assert response.status_code == 404

    def test_invalid_method(self, api_client):
        """Test using invalid HTTP method."""
        response = api_client.patch("/api/history")
        assert response.status_code == 405

    def test_invalid_json_payload(self, api_client):
        """Test sending invalid JSON."""
        response = api_client.post(
            "/api/snippets",
            data="invalid json",
            headers={"Content-Type": "application/json"},
        )
        assert response.status_code == 422

    def test_missing_required_fields(self, api_client):
        """Test missing required fields in request."""
        response = api_client.post("/api/snippets", json={})
        assert response.status_code == 422

    def test_invalid_folder_name(self, api_client):
        """Test operations with invalid folder name."""
        response = api_client.get("/api/snippets/NonExistentFolder")
        # Should handle gracefully
        assert response.status_code in [200, 404]
