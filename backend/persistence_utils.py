"""Persistence utilities for clipboard manager stores."""

import json
import os
from stores.clipboard_item import ClipboardItem


def save_stores(history_store, snippet_store, history_file, snippets_file):
    """Save all stores to disk."""
    try:
        history_data = [item.to_dict() for item in history_store.items]
        with open(history_file, "w") as f:
            json.dump(history_data, f, indent=2)
        snippet_data = {
            folder: [item.to_dict() for item in items]
            for folder, items in snippet_store.folders.items()
        }
        with open(snippets_file, "w") as f:
            json.dump(snippet_data, f, indent=2)
        history_store.modified = False
        snippet_store.modified = False
    except Exception as e:
        print(f"Error saving stores: {e}")


def load_stores(history_store, snippet_store, history_file, snippets_file):
    """Load all stores from disk."""
    try:
        if os.path.exists(history_file):
            with open(history_file, "r") as f:
                data = json.load(f)
            history_store.items = [
                ClipboardItem.from_dict(item_data) for item_data in data
            ]
        if os.path.exists(snippets_file):
            with open(snippets_file, "r") as f:
                data = json.load(f)
            for folder_name, items_data in data.items():
                snippet_store.folders[folder_name] = [
                    ClipboardItem.from_dict(item_data) for item_data in items_data
                ]
    except Exception as e:
        print(f"Error loading stores: {e}")
