#!/usr/bin/env python3
"""Test script to add multiple items to history and test auto-folders."""

import requests
import time

BASE_URL = "http://localhost:49917"


def add_test_clips():
    """Add 25 test clips to history to test auto-folder generation."""
    print("Adding 25 test clips to history...")

    for i in range(1, 26):
        response = requests.post(
            f"{BASE_URL}/api/snippets",
            json={
                "content": f"Test clip content #{i} - This is a test item for history",
                "name": f"History Item {i}",
                "folder": "TestHistory",
                "tags": ["test", f"item{i}"],
            },
        )

        if response.status_code == 200:
            print(f"✓ Added clip {i}")
        else:
            print(f"✗ Failed to add clip {i}: {response.text}")

        time.sleep(0.1)  # Small delay to ensure different timestamps


def test_history_folders():
    """Test auto-generated history folders."""
    print("\n" + "=" * 50)
    print("Testing History Folders API...")
    print("=" * 50)

    # Get history folders
    response = requests.get(f"{BASE_URL}/api/history/folders")

    if response.status_code == 200:
        folders = response.json()
        print(f"\n✓ Found {len(folders)} auto-generated folders:")
        for folder in folders:
            print(
                f"  - {folder['name']}: {folder['count']} items (indexes {folder['start_index']}-{folder['end_index']})"
            )
    else:
        print(f"✗ Failed to get folders: {response.text}")

    # Get recent history
    response = requests.get(f"{BASE_URL}/api/history/recent")

    if response.status_code == 200:
        recent = response.json()
        print(f"\n✓ Recent history: {len(recent)} items")
    else:
        print(f"✗ Failed to get recent history: {response.text}")


def test_stats():
    """Test stats endpoint."""
    print("\n" + "=" * 50)
    print("Testing Stats API...")
    print("=" * 50)

    response = requests.get(f"{BASE_URL}/api/stats")

    if response.status_code == 200:
        stats = response.json()
        print(f"\n✓ Stats:")
        print(f"  - History count: {stats['history_count']}")
        print(f"  - Snippet count: {stats['snippet_count']}")
        print(f"  - Folder count: {stats['folder_count']}")
        print(f"  - Max history: {stats['max_history']}")
    else:
        print(f"✗ Failed to get stats: {response.text}")


if __name__ == "__main__":
    try:
        # Test that server is running
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code != 200:
            print("✗ Server is not healthy!")
            exit(1)

        print("✓ Server is running and healthy")

        # Run tests
        add_test_clips()
        test_history_folders()
        test_stats()

        print("\n" + "=" * 50)
        print("✓ All tests completed!")
        print("=" * 50)

    except requests.exceptions.ConnectionError:
        print("✗ Could not connect to server at", BASE_URL)
        print("Make sure the daemon is running: python3 daemon.py")
        exit(1)
    except Exception as e:
        print(f"✗ Error: {e}")
        exit(1)
