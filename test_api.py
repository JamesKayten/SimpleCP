#!/usr/bin/env python3
"""
SimpleCP API Test Script.

Tests all REST API endpoints to ensure they work correctly.

Usage:
    1. Start the daemon: python3 main.py
    2. In another terminal, run: python3 test_api.py
"""

import requests
import json
import time
from typing import Dict, Any

BASE_URL = "http://127.0.0.1:8080"


def print_test(name: str):
    """Print test header."""
    print(f"\n{'=' * 60}")
    print(f"TEST: {name}")
    print('=' * 60)


def print_result(endpoint: str, method: str, response: requests.Response):
    """Print test result."""
    status_emoji = "✅" if response.status_code < 400 else "❌"
    print(f"{status_emoji} {method} {endpoint} - Status: {response.status_code}")

    try:
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2)}")
    except:
        print(f"Response: {response.text[:200]}")


def test_status():
    """Test status endpoint."""
    print_test("Backend Status")
    response = requests.get(f"{BASE_URL}/api/status")
    print_result("/api/status", "GET", response)
    return response.status_code == 200


def test_settings():
    """Test settings endpoints."""
    print_test("Settings Management")

    # Get settings
    response = requests.get(f"{BASE_URL}/api/settings")
    print_result("/api/settings", "GET", response)

    # Update settings
    update_data = {
        "max_history_items": 100,
        "clipboard_check_interval": 0.5
    }
    response = requests.put(f"{BASE_URL}/api/settings", json=update_data)
    print_result("/api/settings", "PUT", response)

    return response.status_code == 200


def test_history():
    """Test history endpoints."""
    print_test("History Management")

    # Get history
    response = requests.get(f"{BASE_URL}/api/history")
    print_result("/api/history", "GET", response)

    # Get history folders
    response = requests.get(f"{BASE_URL}/api/history/folders")
    print_result("/api/history/folders", "GET", response)

    # Get specific folder (if exists)
    if response.status_code == 200 and response.json():
        folder = response.json()[0]["name"]
        response = requests.get(f"{BASE_URL}/api/history/{folder}")
        print_result(f"/api/history/{folder}", "GET", response)

    return True


def test_snippets():
    """Test snippet endpoints."""
    print_test("Snippet Management")

    # Create a folder
    folder_data = {"name": "Test Folder"}
    response = requests.post(f"{BASE_URL}/api/folders", json=folder_data)
    print_result("/api/folders", "POST", response)

    # Create a snippet
    snippet_data = {
        "name": "Test Snippet",
        "content": "This is a test snippet content",
        "folder": "Test Folder"
    }
    response = requests.post(f"{BASE_URL}/api/snippets", json=snippet_data)
    print_result("/api/snippets", "POST", response)

    snippet_id = None
    if response.status_code == 200:
        snippet_id = response.json()["id"]
        print(f"Created snippet with ID: {snippet_id}")

    # Get all snippet folders
    response = requests.get(f"{BASE_URL}/api/snippets")
    print_result("/api/snippets", "GET", response)

    # Get snippets in folder
    response = requests.get(f"{BASE_URL}/api/snippets/Test Folder")
    print_result("/api/snippets/Test Folder", "GET", response)

    # Update snippet
    if snippet_id:
        update_data = {
            "name": "Updated Test Snippet",
            "content": "This is updated content"
        }
        response = requests.put(f"{BASE_URL}/api/snippets/{snippet_id}", json=update_data)
        print_result(f"/api/snippets/{snippet_id}", "PUT", response)

        # Delete snippet
        response = requests.delete(f"{BASE_URL}/api/snippets/{snippet_id}")
        print_result(f"/api/snippets/{snippet_id}", "DELETE", response)

    return True


def test_search():
    """Test search endpoint."""
    print_test("Search Functionality")

    # Search for "test"
    response = requests.get(f"{BASE_URL}/api/search?q=test")
    print_result("/api/search?q=test", "GET", response)

    return response.status_code == 200


def test_clipboard_copy():
    """Test clipboard copy endpoint."""
    print_test("Clipboard Copy")

    # Try to copy first history item
    response = requests.get(f"{BASE_URL}/api/history")
    if response.status_code == 200 and response.json()["items"]:
        copy_data = {"index": 0}
        response = requests.post(f"{BASE_URL}/api/history/copy", json=copy_data)
        print_result("/api/history/copy", "POST", response)
        return response.status_code == 200
    else:
        print("No history items to test copy")
        return True


def test_root():
    """Test root endpoint."""
    print_test("Root Endpoint")
    response = requests.get(f"{BASE_URL}/")
    print_result("/", "GET", response)
    return response.status_code == 200


def run_all_tests():
    """Run all API tests."""
    print("\n" + "=" * 60)
    print("SimpleCP REST API Test Suite")
    print("=" * 60)
    print(f"Target: {BASE_URL}")
    print(f"Time: {time.strftime('%Y-%m-%d %H:%M:%S')}")

    # Check if server is running
    try:
        requests.get(f"{BASE_URL}/", timeout=2)
    except requests.exceptions.ConnectionError:
        print("\n❌ ERROR: Cannot connect to API server!")
        print("Please start the daemon first: python3 main.py")
        return

    tests = [
        ("Root", test_root),
        ("Status", test_status),
        ("Settings", test_settings),
        ("History", test_history),
        ("Snippets", test_snippets),
        ("Search", test_search),
        ("Clipboard Copy", test_clipboard_copy),
    ]

    results = []
    for name, test_func in tests:
        try:
            success = test_func()
            results.append((name, success))
        except Exception as e:
            print(f"❌ Test '{name}' failed with exception: {e}")
            results.append((name, False))

    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)

    passed = sum(1 for _, success in results if success)
    total = len(results)

    for name, success in results:
        emoji = "✅" if success else "❌"
        print(f"{emoji} {name}")

    print(f"\nPassed: {passed}/{total}")

    if passed == total:
        print("\n🎉 All tests passed!")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")


if __name__ == "__main__":
    run_all_tests()
