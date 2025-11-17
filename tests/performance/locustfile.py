"""
Load testing for SimpleCP API using Locust.

Run with: locust -f tests/performance/locustfile.py --host=http://localhost:8000

Simulates menu bar app usage patterns:
- Frequent history checks
- Periodic clipboard operations
- Occasional snippet access
- Search queries
"""
from locust import HttpUser, task, between
import random


class MenuBarUser(HttpUser):
    """
    Simulates a menu bar app user interacting with SimpleCP API.

    Wait time represents realistic delays between user actions.
    """

    wait_time = between(1, 5)  # 1-5 seconds between actions

    def on_start(self):
        """Initialize user session."""
        # Check health on start
        self.client.get("/health")

    @task(10)
    def get_recent_history(self):
        """
        Most common operation: Getting recent history for display.

        Weight: 10 (very frequent)
        """
        self.client.get("/api/history/recent")

    @task(5)
    def get_full_history(self):
        """
        Get full history (when user opens main window).

        Weight: 5 (frequent)
        """
        self.client.get("/api/history")

    @task(3)
    def copy_to_clipboard(self):
        """
        Copy item to clipboard by simulating click.

        Weight: 3 (moderate)
        """
        # Get history first to get a valid clip_id
        response = self.client.get("/api/history/recent")
        if response.status_code == 200:
            items = response.json()
            if items:
                clip_id = items[0]["clip_id"]
                self.client.post("/api/clipboard/copy", json={"clip_id": clip_id})

    @task(2)
    def search_history(self):
        """
        Search operation (when user types in search box).

        Weight: 2 (occasional)
        """
        search_terms = ["code", "test", "python", "hello", "important"]
        query = random.choice(search_terms)
        self.client.get(f"/api/search?q={query}")

    @task(2)
    def get_snippets(self):
        """
        Access snippets (when user opens snippets panel).

        Weight: 2 (occasional)
        """
        self.client.get("/api/snippets")

    @task(1)
    def get_stats(self):
        """
        Get stats (periodic background check).

        Weight: 1 (rare)
        """
        self.client.get("/api/stats")

    @task(1)
    def create_snippet(self):
        """
        Create snippet from history (rare user action).

        Weight: 1 (rare)
        """
        response = self.client.get("/api/history/recent")
        if response.status_code == 200:
            items = response.json()
            if items:
                clip_id = items[0]["clip_id"]
                payload = {
                    "clip_id": clip_id,
                    "folder_name": "Work",
                    "name": f"Snippet {random.randint(1, 1000)}",
                }
                self.client.post("/api/snippets", json=payload)

    @task(1)
    def delete_history_item(self):
        """
        Delete history item (occasional cleanup).

        Weight: 1 (rare)
        """
        response = self.client.get("/api/history/recent")
        if response.status_code == 200:
            items = response.json()
            if items and len(items) > 5:  # Don't delete if history is small
                clip_id = items[-1]["clip_id"]  # Delete oldest in recent
                self.client.delete(f"/api/history/{clip_id}")


class HeavyUser(HttpUser):
    """
    Simulates a power user with intensive usage patterns.
    """

    wait_time = between(0.5, 2)  # Faster actions

    @task(15)
    def rapid_history_access(self):
        """Rapidly access history."""
        self.client.get("/api/history/recent")

    @task(10)
    def frequent_search(self):
        """Frequent search operations."""
        searches = ["python", "code", "test", "data", "config"]
        for search in searches:
            self.client.get(f"/api/search?q={search}")
            if random.random() < 0.3:  # 30% chance to break early
                break

    @task(5)
    def bulk_snippet_access(self):
        """Access multiple snippet folders."""
        response = self.client.get("/api/snippets/folders")
        if response.status_code == 200:
            folders = response.json()
            if folders:
                folder = random.choice(folders)
                self.client.get(f"/api/snippets/{folder}")


class IdleUser(HttpUser):
    """
    Simulates an idle user (app running but not actively used).

    Represents background polling and health checks.
    """

    wait_time = between(30, 60)  # Long waits between actions

    @task(1)
    def health_check(self):
        """Periodic health check."""
        self.client.get("/health")

    @task(1)
    def check_for_updates(self):
        """Check if there's new content."""
        self.client.get("/api/stats")


class StressTestUser(HttpUser):
    """
    Stress test user for finding breaking points.

    Use sparingly in load tests.
    """

    wait_time = between(0.1, 0.5)  # Very aggressive

    @task(20)
    def rapid_fire_requests(self):
        """Rapid-fire requests."""
        endpoints = [
            "/api/history/recent",
            "/api/stats",
            "/health",
            "/api/snippets/folders",
        ]
        endpoint = random.choice(endpoints)
        self.client.get(endpoint)

    @task(5)
    def create_many_snippets(self):
        """Create multiple snippets quickly."""
        for i in range(5):
            payload = {
                "content": f"Stress test snippet {random.randint(1, 10000)}",
                "folder_name": "StressTest",
                "name": f"Item {i}",
            }
            self.client.post("/api/snippets", json=payload)
            if random.random() < 0.5:  # 50% chance to break
                break


# Usage instructions:
"""
Load Testing Scenarios:

1. Light load (typical usage):
   locust -f locustfile.py --users 10 --spawn-rate 2 --host http://localhost:8000

2. Normal load (multiple active users):
   locust -f locustfile.py --users 50 --spawn-rate 5 --host http://localhost:8000

3. Heavy load (stress test):
   locust -f locustfile.py --users 100 --spawn-rate 10 --host http://localhost:8000

4. Spike test (rapid increase):
   locust -f locustfile.py --users 200 --spawn-rate 50 --host http://localhost:8000

5. Endurance test (long duration):
   locust -f locustfile.py --users 30 --spawn-rate 5 --run-time 1h --host http://localhost:8000

Mix users for realistic scenarios:
- 70% MenuBarUser (typical users)
- 20% IdleUser (background users)
- 10% HeavyUser (power users)
"""
