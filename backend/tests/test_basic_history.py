"""Tests for basic endpoints and history operations."""

import pytest
from fastapi.testclient import TestClient
from api.server import create_app
from clipboard_manager import ClipboardManager


@pytest.fixture
def client():
    """Create test client."""
    import tempfile
    import shutil

    temp_dir = tempfile.mkdtemp()
    manager = ClipboardManager(data_dir=temp_dir)
    app = create_app(manager)
    yield TestClient(app), manager
    shutil.rmtree(temp_dir, ignore_errors=True)


def test_root_endpoint(client):
    """Test root endpoint."""
    test_client, _ = client
    response = test_client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "SimpleCP"
    assert data["status"] == "running"


def test_health_endpoint(client):
    """Test health endpoint."""
    test_client, _ = client
    response = test_client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "clipboard_stats" in data


def test_get_history_empty(client):
    """Test getting empty history."""
    test_client, manager = client
    manager.clear_history()
    response = test_client.get("/api/history")
    assert response.status_code == 200
    assert response.json() == []


def test_get_recent_history(client):
    """Test getting recent history."""
    test_client, manager = client
    manager.add_clip("test content")
    response = test_client.get("/api/history/recent")
    assert response.status_code == 200
    items = response.json()
    assert len(items) > 0


def test_get_history_folders(client):
    """Test getting history folders."""
    test_client, _ = client
    response = test_client.get("/api/history/folders")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_delete_history_item(client):
    """Test deleting history item."""
    test_client, manager = client
    item = manager.add_clip("test delete")
    response = test_client.delete(f"/api/history/{item.clip_id}")
    assert response.status_code == 200
    assert response.json()["success"] is True


def test_delete_nonexistent_history(client):
    """Test deleting non-existent history item."""
    test_client, _ = client
    response = test_client.delete("/api/history/nonexistent")
    assert response.status_code == 404


def test_clear_history(client):
    """Test clearing history."""
    test_client, manager = client
    manager.add_clip("test1")
    manager.add_clip("test2")
    response = test_client.delete("/api/history")
    assert response.status_code == 200
    assert response.json()["success"] is True
