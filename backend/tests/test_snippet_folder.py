"""Tests for snippet and folder operations."""

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


def test_create_folder(client):
    """Test creating folder."""
    test_client, _ = client
    response = test_client.post("/api/folders", json={"folder_name": "NewFolder"})
    assert response.status_code == 200


def test_rename_folder(client):
    """Test renaming folder."""
    test_client, manager = client
    manager.create_snippet_folder("OldName")
    response = test_client.put("/api/folders/OldName", json={"new_name": "NewName"})
    assert response.status_code == 200


def test_delete_folder(client):
    """Test deleting folder."""
    test_client, manager = client
    manager.create_snippet_folder("DeleteMe")
    response = test_client.delete("/api/folders/DeleteMe")
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


# ============================================================================
# REGRESSION TESTS: "sink folder" crash (Issue: folder rename with spaces)
# Root cause: Backend crashed when renaming folders with specific names
# ============================================================================

def test_rename_folder_with_spaces(client):
    """
    Regression test for 'sink folder' crash.
    Renaming folders with spaces should not crash the backend.
    """
    test_client, manager = client
    # Create folder with space in name (like "sink folder")
    manager.create_snippet_folder("sink folder")

    # Rename should succeed, not crash
    response = test_client.put(
        "/api/folders/sink%20folder",  # URL-encoded space
        json={"new_name": "renamed folder"}
    )
    assert response.status_code == 200


def test_rename_folder_sink_folder_specific(client):
    """
    Specific test for the exact 'sink folder' case that caused crashes.
    """
    test_client, manager = client
    manager.create_snippet_folder("sink folder")

    # Try various rename operations
    response = test_client.put(
        "/api/folders/sink%20folder",
        json={"new_name": "my sink"}
    )
    assert response.status_code == 200


def test_rename_folder_special_characters(client):
    """Test renaming folders with special characters doesn't crash."""
    test_client, manager = client

    # Test various problematic folder names
    problematic_names = [
        "folder with spaces",
        "folder-with-dashes",
        "folder_with_underscores",
        "folder.with.dots",
        "123numeric",
    ]

    for name in problematic_names:
        manager.create_snippet_folder(name)
        response = test_client.put(
            f"/api/folders/{name.replace(' ', '%20')}",
            json={"new_name": f"renamed_{name.replace(' ', '_')}"}
        )
        assert response.status_code == 200, f"Failed to rename '{name}'"


def test_rename_folder_empty_name(client):
    """Test that empty folder names are rejected."""
    test_client, manager = client
    manager.create_snippet_folder("ValidFolder")

    response = test_client.put(
        "/api/folders/ValidFolder",
        json={"new_name": ""}
    )
    # Should fail with 400 (bad request) or return error, not crash
    assert response.status_code in [400, 422]


def test_rename_folder_whitespace_only(client):
    """Test that whitespace-only folder names are rejected."""
    test_client, manager = client
    manager.create_snippet_folder("ValidFolder")

    response = test_client.put(
        "/api/folders/ValidFolder",
        json={"new_name": "   "}
    )
    # Should fail, not crash
    assert response.status_code in [400, 422]


def test_folder_delegate_error_handling(client):
    """
    Test that delegate errors don't crash folder operations.
    This tests the fix for _notify_delegates silently failing.
    """
    test_client, manager = client

    # Add a problematic delegate that raises an exception
    def bad_delegate(event, *args):
        raise ValueError("Simulated delegate error")

    manager.snippet_store.add_delegate(bad_delegate)

    # Folder operations should still work even with bad delegate
    manager.create_snippet_folder("TestFolder")

    response = test_client.put(
        "/api/folders/TestFolder",
        json={"new_name": "RenamedFolder"}
    )
    # Should succeed despite delegate error
    assert response.status_code == 200

    # Clean up
    manager.snippet_store.remove_delegate(bad_delegate)
