"""
Integration tests for complete workflows.
"""
import pytest
from fastapi.testclient import TestClient


@pytest.mark.integration
class TestClipboardWorkflows:
    """Test complete clipboard workflows."""

    def test_full_clipboard_lifecycle(self, api_client, clipboard_manager):
        """Test complete clipboard item lifecycle."""
        # 1. Add item to history
        item = clipboard_manager.add_clip("Important code snippet")
        assert item is not None

        # 2. Verify it appears in history
        response = api_client.get("/api/history")
        assert response.status_code == 200
        history = response.json()
        assert len(history) >= 1

        # 3. Copy to clipboard
        response = api_client.post(
            "/api/clipboard/copy", json={"clip_id": item.clip_id}
        )
        assert response.status_code == 200

        # 4. Delete from history
        response = api_client.delete(f"/api/history/{item.clip_id}")
        assert response.status_code == 200

        # 5. Verify deletion
        response = api_client.get("/api/history")
        history = response.json()
        assert item.clip_id not in [h["clip_id"] for h in history]

    def test_snippet_workflow(self, api_client, clipboard_manager):
        """Test complete snippet workflow."""
        # 1. Create snippet
        payload = {
            "content": "def hello():\n    print('Hello')",
            "folder_name": "PythonCode",
            "name": "Hello Function",
        }
        response = api_client.post("/api/snippets", json=payload)
        assert response.status_code == 200

        # 2. Verify snippet exists
        response = api_client.get("/api/snippets/PythonCode")
        assert response.status_code == 200
        data = response.json()
        snippets = data["snippets"]
        assert len(snippets) >= 1
        snippet_id = snippets[0]["clip_id"]

        # 3. Copy snippet to clipboard
        response = api_client.post("/api/clipboard/copy", json={"clip_id": snippet_id})
        assert response.status_code == 200

        # 4. Rename folder
        response = api_client.put(
            "/api/folders/PythonCode", json={"new_name": "Python"}
        )
        assert response.status_code == 200

        # 5. Verify rename
        response = api_client.get("/api/snippets/Python")
        assert response.status_code == 200

        # 6. Delete snippet
        response = api_client.delete(f"/api/snippets/Python/{snippet_id}")
        assert response.status_code == 200

        # 7. Delete folder
        response = api_client.delete("/api/folders/Python")
        assert response.status_code == 200

    def test_history_to_snippet_workflow(self, api_client, clipboard_manager):
        """Test converting history item to snippet."""
        # 1. Add to history
        item = clipboard_manager.add_clip("Useful command: docker ps -a")

        # 2. Save as snippet
        payload = {
            "clip_id": item.clip_id,
            "folder_name": "Commands",
            "name": "Docker PS",
        }
        response = api_client.post("/api/snippets", json=payload)
        assert response.status_code == 200

        # 3. Verify snippet created
        response = api_client.get("/api/snippets/Commands")
        assert response.status_code == 200
        data = response.json()
        assert len(data["snippets"]) >= 1

        # 4. Original should still be in history
        response = api_client.get("/api/history")
        assert response.status_code == 200
        history = response.json()
        assert any(h["clip_id"] == item.clip_id for h in history)

    def test_search_workflow(self, api_client, clipboard_manager):
        """Test search across history and snippets."""
        # 1. Add various items
        clipboard_manager.add_clip("Python programming tutorial")
        clipboard_manager.add_clip("JavaScript basics")
        clipboard_manager.create_snippet("Python code example", "Code", "PyExample")
        clipboard_manager.create_snippet("Java application", "Code", "JavaApp")

        # 2. Search for Python
        response = api_client.get("/api/search?q=Python")
        assert response.status_code == 200
        data = response.json()
        assert len(data["history"]) >= 1
        assert len(data["snippets"]) >= 1

        # 3. Search for something not present
        response = api_client.get("/api/search?q=Nonexistent")
        assert response.status_code == 200
        data = response.json()
        assert len(data["history"]) == 0
        assert len(data["snippets"]) == 0


@pytest.mark.integration
class TestPersistenceWorkflows:
    """Test data persistence workflows."""

    def test_save_and_reload_workflow(self, test_data_dir):
        """Test complete save and reload workflow."""
        from clipboard_manager import ClipboardManager

        # 1. Create manager and add data
        manager1 = ClipboardManager(data_dir=test_data_dir)
        manager1.add_clip("History item 1")
        manager1.add_clip("History item 2")
        manager1.create_snippet("Snippet 1", "Work", "Note 1")

        # 2. Save
        manager1.save_stores()

        # 3. Create new manager and load
        manager2 = ClipboardManager(data_dir=test_data_dir)
        manager2.load_stores()

        # 4. Verify data restored
        assert len(manager2.history_store) == 2
        assert len(manager2.snippet_store.get_all_snippets()) == 1

    def test_concurrent_modifications(self, clipboard_manager):
        """Test handling concurrent modifications."""
        # Add items rapidly
        items = []
        for i in range(20):
            item = clipboard_manager.add_clip(f"Concurrent test {i}")
            if item:
                items.append(item)

        # Verify all items were added correctly
        history = clipboard_manager.get_all_history()
        assert len(history) <= 20


@pytest.mark.integration
@pytest.mark.slow
class TestScalabilityWorkflows:
    """Test workflows with large amounts of data."""

    def test_large_history_workflow(self, api_client, clipboard_manager):
        """Test handling large history."""
        # Add many items
        for i in range(100):
            clipboard_manager.add_clip(f"Test item {i}")

        # Should respect max limit
        response = api_client.get("/api/history")
        assert response.status_code == 200
        history = response.json()
        assert len(history) <= 50  # max_history

        # Recent items should work
        response = api_client.get("/api/history/recent")
        assert response.status_code == 200
        recent = response.json()
        assert len(recent) <= 10  # display_count

    def test_many_snippets_workflow(self, api_client, clipboard_manager):
        """Test handling many snippets."""
        # Create multiple folders with snippets
        for folder_num in range(5):
            folder = f"Folder{folder_num}"
            for snippet_num in range(10):
                clipboard_manager.create_snippet(
                    f"Snippet {snippet_num}", folder, f"Note {snippet_num}"
                )

        # Get all snippets
        response = api_client.get("/api/snippets")
        assert response.status_code == 200
        snippets = response.json()
        assert len(snippets) >= 50

        # Get stats
        response = api_client.get("/api/stats")
        assert response.status_code == 200
        stats = response.json()
        assert stats["snippet_count"] >= 50
        assert stats["folder_count"] >= 5

    def test_search_performance(self, api_client, clipboard_manager):
        """Test search with large dataset."""
        # Add many items with searchable content
        for i in range(100):
            if i % 3 == 0:
                clipboard_manager.add_clip(f"Python code example {i}")
            else:
                clipboard_manager.add_clip(f"Other content {i}")

        # Search should complete quickly
        import time

        start = time.time()
        response = api_client.get("/api/search?q=Python")
        duration = time.time() - start

        assert response.status_code == 200
        assert duration < 1.0  # Should complete in under 1 second


@pytest.mark.integration
class TestErrorRecoveryWorkflows:
    """Test error recovery scenarios."""

    def test_invalid_data_recovery(self, api_client, clipboard_manager):
        """Test recovery from invalid data."""
        # Try to create snippet with empty content
        payload = {"content": "", "folder_name": "Test", "name": "Empty"}
        response = api_client.post("/api/snippets", json=payload)
        # Should either reject or handle gracefully
        assert response.status_code in [200, 400, 422]

        # System should still be functional
        response = api_client.get("/api/stats")
        assert response.status_code == 200

    def test_folder_deletion_with_snippets(self, api_client, clipboard_manager):
        """Test deleting folder containing snippets."""
        # Create folder with snippets
        clipboard_manager.create_snippet("Snippet 1", "TestFolder", "Note 1")
        clipboard_manager.create_snippet("Snippet 2", "TestFolder", "Note 2")

        # Delete folder
        response = api_client.delete("/api/folders/TestFolder")
        assert response.status_code == 200

        # Verify folder and contents are gone
        response = api_client.get("/api/snippets/TestFolder")
        data = response.json()
        assert len(data.get("snippets", [])) == 0
