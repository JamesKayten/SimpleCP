#!/usr/bin/env python3
"""Simple load test for SimpleCP API."""

import requests
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

BASE_URL = "http://localhost:8000"


def test_health():
    """Test health endpoint."""
    response = requests.get(f"{BASE_URL}/health")
    return response.status_code == 200


def test_get_history():
    """Test get history endpoint."""
    response = requests.get(f"{BASE_URL}/api/history")
    return response.status_code == 200


def test_get_stats():
    """Test get stats endpoint."""
    response = requests.get(f"{BASE_URL}/api/stats")
    return response.status_code == 200


def test_search():
    """Test search endpoint."""
    response = requests.get(f"{BASE_URL}/api/search?q=test")
    return response.status_code == 200


def run_load_test(concurrent_requests=10, total_requests=100):
    """Run load test with concurrent requests."""
    print("=" * 60)
    print(f"SimpleCP API Load Test")
    print(f"Concurrent requests: {concurrent_requests}")
    print(f"Total requests: {total_requests}")
    print("=" * 60)

    tests = [
        ("Health Check", test_health),
        ("Get History", test_get_history),
        ("Get Stats", test_get_stats),
        ("Search", test_search),
    ]

    for test_name, test_func in tests:
        print(f"\nTesting: {test_name}")
        print("-" * 60)

        start_time = time.time()
        success_count = 0
        error_count = 0

        with ThreadPoolExecutor(max_workers=concurrent_requests) as executor:
            futures = [executor.submit(test_func) for _ in range(total_requests)]

            for future in as_completed(futures):
                try:
                    if future.result():
                        success_count += 1
                    else:
                        error_count += 1
                except Exception as e:
                    error_count += 1
                    print(f"Error: {e}")

        end_time = time.time()
        duration = end_time - start_time
        requests_per_sec = total_requests / duration

        print(f"✓ Success: {success_count}/{total_requests}")
        print(f"✗ Errors: {error_count}/{total_requests}")
        print(f"Duration: {duration:.2f}s")
        print(f"Requests/sec: {requests_per_sec:.2f}")

    print("\n" + "=" * 60)
    print("✓ Load test completed!")
    print("=" * 60)


if __name__ == "__main__":
    try:
        # Quick check that server is running
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code != 200:
            print("✗ Server is not healthy!")
            exit(1)

        # Run load test
        run_load_test(concurrent_requests=10, total_requests=100)

    except requests.exceptions.ConnectionError:
        print("✗ Could not connect to server at", BASE_URL)
        print("Make sure the daemon is running: python3 daemon.py")
        exit(1)
    except Exception as e:
        print(f"✗ Error: {e}")
        exit(1)
