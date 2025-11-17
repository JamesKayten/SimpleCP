"""
HistoryStore for SimpleCP.

Manages recent clipboard history with automatic deduplication
and size limits. Based on Flycut's ClippingStore architecture.
"""

import json
from pathlib import Path
from typing import List, Dict, Optional
from datetime import datetime
from .clipboard_item import ClipboardItem


class HistoryStore:
    """
    Manages clipboard history with Flycut-inspired patterns.

    Features:
    - Auto-deduplication: Removes duplicates, keeps most recent
    - Size limits: Automatic trimming to max_items
    - Persistence: JSON-based storage with dirty flag tracking
    - Auto-folders: Generates time-based folders (1-10, 11-20, etc.)
    """

    def __init__(self, max_items: int = 50, data_file: str = "data/history.json"):
        """
        Initialize the HistoryStore.

        Args:
            max_items: Maximum number of items to keep in history
            data_file: Path to JSON file for persistence
        """
        self.max_items = max_items
        self.data_file = Path(data_file)
        self.items: List[ClipboardItem] = []
        self._dirty = False  # Track if data needs saving

        # Ensure data directory exists
        self.data_file.parent.mkdir(parents=True, exist_ok=True)

        # Load existing data
        self.load()

    def add(self, item: ClipboardItem) -> bool:
        """
        Add item to history with auto-deduplication.

        If item already exists, remove old instance and add new one at the top.
        This follows Flycut's behavior of moving duplicates to the top.

        Args:
            item: ClipboardItem to add

        Returns:
            bool: True if item was added, False if it was a duplicate
        """
        # Check for duplicates
        duplicate_found = False
        for existing in self.items[:]:  # Copy list to avoid modification during iteration
            if existing.content == item.content:
                self.items.remove(existing)
                duplicate_found = True
                break

        # Add to front (most recent)
        self.items.insert(0, item)

        # Trim to max size
        if len(self.items) > self.max_items:
            self.items = self.items[:self.max_items]

        self._dirty = True
        self.save()

        return not duplicate_found

    def get_all(self) -> List[ClipboardItem]:
        """
        Get all history items.

        Returns:
            List of ClipboardItems, newest first
        """
        return self.items.copy()

    def get_folders(self) -> List[Dict[str, any]]:
        """
        Get auto-generated history folders.

        Creates folders like:
        - "1-10" (most recent 10 items)
        - "11-20"
        - "21-30"
        - etc.

        Returns:
            List of folder dictionaries with name, start, end indices
        """
        folders = []
        total = len(self.items)
        folder_size = 10

        for start in range(0, total, folder_size):
            end = min(start + folder_size, total)
            folder = {
                "name": f"{start + 1}-{end}",
                "start": start,
                "end": end,
                "count": end - start
            }
            folders.append(folder)

        return folders

    def get_folder_items(self, folder_name: str) -> List[ClipboardItem]:
        """
        Get items in a specific folder range.

        Args:
            folder_name: Folder name like "1-10" or "11-20"

        Returns:
            List of ClipboardItems in that range
        """
        try:
            # Parse folder name "1-10" -> start=0, end=10
            start_str, end_str = folder_name.split('-')
            start = int(start_str) - 1  # Convert to 0-based index
            end = int(end_str)

            return self.items[start:end]
        except (ValueError, IndexError):
            return []

    def get_by_index(self, index: int) -> Optional[ClipboardItem]:
        """
        Get item by index.

        Args:
            index: Index in history (0 = most recent)

        Returns:
            ClipboardItem or None if index out of range
        """
        if 0 <= index < len(self.items):
            return self.items[index]
        return None

    def search(self, query: str) -> List[ClipboardItem]:
        """
        Search history for items matching query.

        Args:
            query: Search string (case-insensitive)

        Returns:
            List of matching ClipboardItems
        """
        query_lower = query.lower()
        return [
            item for item in self.items
            if query_lower in item.content.lower()
        ]

    def clear(self):
        """Clear all history items."""
        self.items = []
        self._dirty = True
        self.save()

    def remove(self, index: int) -> bool:
        """
        Remove item at specific index.

        Args:
            index: Index to remove

        Returns:
            bool: True if removed successfully
        """
        if 0 <= index < len(self.items):
            self.items.pop(index)
            self._dirty = True
            self.save()
            return True
        return False

    def save(self):
        """Save history to JSON file if dirty."""
        if not self._dirty:
            return

        try:
            data = [item.to_dict() for item in self.items]
            with open(self.data_file, 'w') as f:
                json.dump(data, f, indent=2)
            self._dirty = False
        except Exception as e:
            print(f"Error saving history: {e}")

    def load(self):
        """Load history from JSON file."""
        if not self.data_file.exists():
            return

        try:
            with open(self.data_file, 'r') as f:
                data = json.load(f)

            self.items = [ClipboardItem.from_dict(item_data) for item_data in data]
            self._dirty = False
        except Exception as e:
            print(f"Error loading history: {e}")
            self.items = []

    def get_stats(self) -> Dict[str, any]:
        """
        Get statistics about the history store.

        Returns:
            Dictionary with stats
        """
        return {
            "total_items": len(self.items),
            "max_items": self.max_items,
            "usage_percent": int((len(self.items) / self.max_items) * 100),
            "folders": len(self.get_folders())
        }

    def __len__(self) -> int:
        """Return number of items in history."""
        return len(self.items)

    def __repr__(self) -> str:
        return f"HistoryStore(items={len(self.items)}, max={self.max_items})"
