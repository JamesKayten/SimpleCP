#!/usr/bin/env python3
"""Test script to directly add items to history using ClipboardManager."""

import sys
import time
from clipboard_manager import ClipboardManager

def test_history_auto_folders():
    """Test auto-generated history folders by adding items directly."""
    print("="*60)
    print("Testing History Auto-Folder Generation")
    print("="*60)

    # Create manager instance
    manager = ClipboardManager()

    # Clear any existing history
    print("\nClearing existing history...")
    manager.history_store.clear()

    # Add 25 test items to history
    print("\nAdding 25 test items to history...")
    for i in range(1, 26):
        content = f"Test history item #{i:02d} - Sample clipboard content for testing auto-folders"
        item = manager.add_clip(content, source_app=f"TestApp{i%3}")
        print(f"  ✓ Added item {i}: {item.display_string}")
        time.sleep(0.01)  # Small delay for unique timestamps

    # Get history stats
    print(f"\n{'='*60}")
    print("History Stats:")
    print(f"{'='*60}")
    print(f"Total history items: {len(manager.history_store.items)}")
    print(f"Max history size: {manager.history_store.max_items}")

    # Test auto-generated folders
    print(f"\n{'='*60}")
    print("Auto-Generated Folders:")
    print(f"{'='*60}")

    folders = manager.get_history_folders()
    print(f"\nFound {len(folders)} auto-generated folders:")

    for folder in folders:
        print(f"\n📁 {folder['name']}:")
        print(f"   Range: {folder['start_index']}-{folder['end_index']}")
        print(f"   Count: {folder['count']} items")
        print(f"   Items:")
        for idx, item in enumerate(folder['items'][:3], 1):  # Show first 3
            print(f"     {idx}. {item.display_string}")
        if len(folder['items']) > 3:
            print(f"     ... and {len(folder['items']) - 3} more")

    # Test recent history
    print(f"\n{'='*60}")
    print("Recent History (First 10 items):")
    print(f"{'='*60}")

    recent = manager.get_recent_history()
    for idx, item in enumerate(recent, 1):
        print(f"  {idx}. {item.display_string}")

    # Test search
    print(f"\n{'='*60}")
    print("Search Test (query: 'item #05'):")
    print(f"{'='*60}")

    results = manager.search_all("item #05")
    print(f"History matches: {len(results['history'])}")
    print(f"Snippet matches: {len(results['snippets'])}")

    if results['history']:
        print("\nMatches:")
        for item in results['history']:
            print(f"  - {item.display_string}")

    # Save data
    print(f"\n{'='*60}")
    print("Saving data...")
    manager.save_stores()
    print("✓ Data saved successfully")

    print(f"\n{'='*60}")
    print("✓ All tests completed successfully!")
    print(f"{'='*60}\n")

if __name__ == "__main__":
    try:
        test_history_auto_folders()
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
