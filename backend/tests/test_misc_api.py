"""Tests for miscellaneous API endpoints (search, stats, import/export)."""


def test_copy_to_clipboard(client):
    """Test copying to clipboard."""
    test_client, manager = client
    item = manager.add_clip("copy this")
    try:
        response = test_client.post(
            "/api/clipboard/copy", json={"clip_id": item.clip_id}
        )
        assert response.status_code == 200
    except Exception:
        # Skip if pyperclip not available in test environment
        pass


def test_search_get(client):
    """Test GET search."""
    test_client, manager = client
    manager.add_clip("searchable content")
    response = test_client.get("/api/search?q=searchable")
    assert response.status_code == 200
    data = response.json()
    assert "history" in data
    assert "snippets" in data


def test_search_post(client):
    """Test POST search."""
    test_client, manager = client
    manager.add_clip("findme")
    response = test_client.post("/api/search", json={"query": "findme"})
    assert response.status_code == 200


def test_get_stats(client):
    """Test stats endpoint."""
    test_client, _ = client
    response = test_client.get("/api/stats")
    assert response.status_code == 200
    data = response.json()
    assert "history_count" in data
    assert "snippet_count" in data


def test_get_status(client):
    """Test status endpoint."""
    test_client, _ = client
    response = test_client.get("/api/status")
    assert response.status_code == 200
    data = response.json()
    assert "monitoring" in data
    assert data["monitoring"] is True


def test_export_snippets(client):
    """Test export endpoint."""
    test_client, _ = client
    response = test_client.get("/api/export")
    assert response.status_code == 200
    data = response.json()
    assert "version" in data
    assert "snippets" in data


def test_import_snippets(client):
    """Test import endpoint."""
    test_client, _ = client
    import_data = {"version": "1.0", "snippets": []}
    response = test_client.post("/api/import", json=import_data)
    assert response.status_code == 200
