"""Tests for folder API endpoints."""


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
