"""
Integration tests for the REST API.
"""

import pytest
from fastapi.testclient import TestClient
from api.server import app


@pytest.fixture
def client():
    """Create a test client for the API."""
    return TestClient(app)


class TestAPIEndpoints:
    """Test API endpoint integration."""

    def test_health_check(self, client):
        """Test health check endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    def test_get_history(self, client):
        """Test getting clipboard history."""
        response = client.get("/api/history")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)
        assert "items" in data

    def test_get_recent_history(self, client):
        """Test getting recent clipboard history."""
        response = client.get("/api/history/recent")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)

    def test_get_snippets(self, client):
        """Test getting snippets."""
        response = client.get("/api/snippets")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)

    def test_get_folders(self, client):
        """Test getting folder list."""
        response = client.get("/api/snippets/folders")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)
        assert "folders" in data

    def test_create_snippet(self, client):
        """Test creating a new snippet."""
        snippet_data = {
            "content": "test snippet",
            "name": "Test",
            "folder": "Test Folder",
            "tags": ["test"]
        }
        response = client.post("/api/snippets", json=snippet_data)
        assert response.status_code in [200, 201]

    def test_search(self, client):
        """Test search functionality."""
        response = client.get("/api/search?q=test")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)
        assert "history_results" in data
        assert "snippet_results" in data

    def test_get_stats(self, client):
        """Test statistics endpoint."""
        response = client.get("/api/stats")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)
        assert "history_count" in data
        assert "snippet_count" in data
