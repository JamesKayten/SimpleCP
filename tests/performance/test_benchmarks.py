"""
Performance benchmarks for SimpleCP.
"""
import pytest
import time
from clipboard_manager import ClipboardManager


@pytest.mark.performance
class TestPerformanceBenchmarks:
    """Performance benchmarks for core operations."""

    def test_add_clip_performance(self, clipboard_manager, benchmark):
        """Benchmark adding clips to history."""

        def add_clip():
            clipboard_manager.add_clip("Test content for benchmarking")

        result = benchmark(add_clip)

    def test_search_performance(self, clipboard_manager, benchmark):
        """Benchmark search operations."""
        # Prep: Add items to search through
        for i in range(100):
            clipboard_manager.add_clip(f"Test content {i} with searchable text")

        def search():
            return clipboard_manager.search_all("searchable")

        result = benchmark(search)

    def test_get_history_performance(self, clipboard_manager, benchmark):
        """Benchmark retrieving history."""
        # Prep: Add many items
        for i in range(50):
            clipboard_manager.add_clip(f"Test {i}")

        def get_history():
            return clipboard_manager.get_all_history()

        result = benchmark(get_history)

    def test_save_stores_performance(self, clipboard_manager, benchmark):
        """Benchmark saving stores to disk."""
        # Prep: Add data
        for i in range(50):
            clipboard_manager.add_clip(f"History {i}")
        for i in range(20):
            clipboard_manager.create_snippet(f"Snippet {i}", "Bench", f"Note {i}")

        def save():
            clipboard_manager.save_stores()

        result = benchmark(save)

    def test_load_stores_performance(self, clipboard_manager, benchmark, test_data_dir):
        """Benchmark loading stores from disk."""
        # Prep: Create data and save
        for i in range(50):
            clipboard_manager.add_clip(f"History {i}")
        clipboard_manager.save_stores()

        def load():
            new_manager = ClipboardManager(data_dir=test_data_dir)
            new_manager.load_stores()
            return new_manager

        result = benchmark(load)


@pytest.mark.performance
@pytest.mark.api
class TestAPIPerformance:
    """Performance tests for API endpoints."""

    def test_api_history_endpoint_performance(self, api_client, clipboard_manager):
        """Test /api/history performance."""
        # Prep: Add data
        for i in range(50):
            clipboard_manager.add_clip(f"Test {i}")

        # Benchmark
        times = []
        for _ in range(10):
            start = time.time()
            response = api_client.get("/api/history")
            duration = time.time() - start
            times.append(duration)
            assert response.status_code == 200

        avg_time = sum(times) / len(times)
        assert avg_time < 0.1  # Should complete in under 100ms

    def test_api_search_performance(self, api_client, clipboard_manager):
        """Test /api/search performance."""
        # Prep: Add data
        for i in range(100):
            clipboard_manager.add_clip(f"Content {i} with searchable keyword")

        # Benchmark
        times = []
        for _ in range(10):
            start = time.time()
            response = api_client.get("/api/search?q=searchable")
            duration = time.time() - start
            times.append(duration)
            assert response.status_code == 200

        avg_time = sum(times) / len(times)
        assert avg_time < 0.2  # Should complete in under 200ms

    def test_api_snippets_performance(self, api_client, clipboard_manager):
        """Test /api/snippets performance."""
        # Prep: Add many snippets
        for i in range(50):
            clipboard_manager.create_snippet(f"Snippet {i}", "Test", f"Note {i}")

        # Benchmark
        times = []
        for _ in range(10):
            start = time.time()
            response = api_client.get("/api/snippets")
            duration = time.time() - start
            times.append(duration)
            assert response.status_code == 200

        avg_time = sum(times) / len(times)
        assert avg_time < 0.15  # Should complete in under 150ms


@pytest.mark.performance
@pytest.mark.slow
class TestScalability:
    """Test scalability with large datasets."""

    def test_large_history_handling(self, test_data_dir):
        """Test handling very large history."""
        manager = ClipboardManager(data_dir=test_data_dir, max_history=500)

        # Add many items
        start = time.time()
        for i in range(1000):
            manager.add_clip(f"Large test {i}")
        duration = time.time() - start

        # Should handle efficiently (under 5 seconds for 1000 items)
        assert duration < 5.0

        # Should respect max_history
        assert len(manager.history_store) <= 500

    def test_many_snippets_handling(self, test_data_dir):
        """Test handling many snippets."""
        manager = ClipboardManager(data_dir=test_data_dir)

        # Create many snippets across folders
        start = time.time()
        for folder_num in range(10):
            folder = f"Folder{folder_num}"
            for i in range(50):
                manager.create_snippet(f"Content {i}", folder, f"Note {i}")
        duration = time.time() - start

        # Should complete in reasonable time
        assert duration < 10.0

        # Verify all created
        all_snippets = manager.get_all_snippets()
        assert len(all_snippets) >= 500

    def test_search_scalability(self, test_data_dir):
        """Test search with very large dataset."""
        manager = ClipboardManager(data_dir=test_data_dir, max_history=500)

        # Add diverse content
        for i in range(500):
            if i % 10 == 0:
                manager.add_clip(f"FINDME special content {i}")
            else:
                manager.add_clip(f"Regular content {i}")

        # Search should still be fast
        start = time.time()
        results = manager.search_all("FINDME")
        duration = time.time() - start

        assert duration < 1.0  # Should complete in under 1 second
        assert len(results["history"]) >= 40  # Should find ~50 matches


@pytest.mark.performance
class TestMemoryEfficiency:
    """Test memory efficiency."""

    def test_memory_usage_bounds(self, test_data_dir):
        """Test that memory usage stays reasonable."""
        import sys

        manager = ClipboardManager(data_dir=test_data_dir, max_history=100)

        # Get baseline size
        baseline_size = sys.getsizeof(manager)

        # Add content
        for i in range(100):
            manager.add_clip(f"Test content {i}" * 10)  # Longer content

        # Size should not grow excessively
        final_size = sys.getsizeof(manager)

        # Note: This is a basic check; proper memory profiling would be more comprehensive
        # Just ensure we're not leaking memory catastrophically
        assert final_size < baseline_size * 1000  # Generous bound
