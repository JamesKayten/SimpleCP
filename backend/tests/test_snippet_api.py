"""Tests for snippet API endpoints."""


def test_get_all_snippets(client):
    """Test getting all snippets."""
    test_client, _ = client
    response = test_client.get("/api/snippets")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_get_snippet_folders(client):
    """Test getting snippet folders."""
    test_client, _ = client
    response = test_client.get("/api/snippets/folders")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_create_snippet_from_history(client):
    """Test creating snippet from history."""
    test_client, manager = client
    item = manager.add_clip("snippet content")
    response = test_client.post(
        "/api/snippets",
        json={
            "clip_id": item.clip_id,
            "name": "Test Snippet",
            "folder": "TestFolder",
            "tags": ["test"],
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["content"] == "snippet content"


def test_create_snippet_direct(client):
    """Test creating snippet directly."""
    test_client, _ = client
    response = test_client.post(
        "/api/snippets",
        json={
            "content": "direct snippet",
            "name": "Direct",
            "folder": "TestFolder",
            "tags": [],
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["content"] == "direct snippet"


def test_create_snippet_invalid(client):
    """Test creating snippet with invalid data."""
    test_client, _ = client
    response = test_client.post(
        "/api/snippets", json={"name": "Invalid", "folder": "Test", "tags": []}
    )
    assert response.status_code == 400


def test_update_snippet(client):
    """Test updating snippet."""
    test_client, manager = client
    snippet = manager.add_snippet_direct("old", "Test", "Folder", [])
    response = test_client.put(
        f"/api/snippets/Folder/{snippet.clip_id}",
        json={"content": "new", "name": "Updated", "tags": ["updated"]},
    )
    assert response.status_code == 200


def test_delete_snippet(client):
    """Test deleting snippet."""
    test_client, manager = client
    snippet = manager.add_snippet_direct("delete me", "Test", "Folder", [])
    response = test_client.delete(f"/api/snippets/Folder/{snippet.clip_id}")
    assert response.status_code == 200


def test_move_snippet(client):
    """Test moving snippet."""
    test_client, manager = client
    manager.create_snippet_folder("Source")
    manager.create_snippet_folder("Dest")
    snippet = manager.add_snippet_direct("move me", "Test", "Source", [])
    response = test_client.post(
        f"/api/snippets/Source/{snippet.clip_id}/move", json={"to_folder": "Dest"}
    )
    assert response.status_code == 200


def test_get_folder_snippets(client):
    """Test getting snippets from folder."""
    test_client, manager = client
    manager.add_snippet_direct("test", "Test", "TestFolder", [])
    response = test_client.get("/api/snippets/TestFolder")
    assert response.status_code == 200
    items = response.json()
    assert len(items) > 0


def test_update_snippet_not_found(client):
    """Test updating non-existent snippet."""
    test_client, _ = client
    response = test_client.put(
        "/api/snippets/Folder/nonexistent", json={"content": "new"}
    )
    assert response.status_code == 404


def test_delete_snippet_not_found(client):
    """Test deleting non-existent snippet."""
    test_client, _ = client
    response = test_client.delete("/api/snippets/Folder/nonexistent")
    assert response.status_code == 404


def test_move_snippet_not_found(client):
    """Test moving non-existent snippet."""
    test_client, _ = client
    response = test_client.post(
        "/api/snippets/Source/nonexistent/move", json={"to_folder": "Dest"}
    )
    assert response.status_code == 404
