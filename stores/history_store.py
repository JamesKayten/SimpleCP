"""
HistoryStore for SimpleCP.

Manages recent clipboard history with automatic deduplication,
size limits, and search functionality.
"""

import json
import os
from typing import List, Optional, Dict, Any
from datetime import datetime
from stores.clipboard_item import ClipboardItem


class HistoryStore:
    """
    Manages clipboard history with intelligent deduplication and search.

    Features:
    - Automatic deduplication (moves existing items to top)
    - Configurable size limits
    - Content-based search
    - JSON persistence
    - ClipboardItem management
    """

    def __init__(self, max_items: int = 50, data_dir: Optional[str] = None):
        """
        Initialize the HistoryStore.

        Args:
            max_items: Maximum number of items to keep in history
            data_dir: Directory for storing history data
        """
        self.max_items = max_items
        self.items: List[ClipboardItem] = []

        # Setup data directory
        if data_dir is None:
            data_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")
        self.data_dir = data_dir
        os.makedirs(self.data_dir, exist_ok=True)

        self.history_file = os.path.join(self.data_dir, "history.json")

    def add(self, content: str, source_app: Optional[str] = None) -> ClipboardItem:
        """
        Add new content to history with automatic deduplication.

        If content already exists, it will be moved to the top of the history.
        Otherwise, a new ClipboardItem is created and added to the top.

        Args:
            content: The clipboard content to add
            source_app: Optional source application name

        Returns:
            The ClipboardItem that was added or moved
        """
        # Check for existing item with same content
        existing_item = self.find_by_content(content)

        if existing_item:
            # Move existing item to top (deduplication)
            self.items.remove(existing_item)
            # Update timestamp to reflect new copy time
            existing_item.timestamp = datetime.now()
            self.items.insert(0, existing_item)
            return existing_item
        else:
            # Create new item and add to top
            new_item = ClipboardItem(
                content=content,
                timestamp=datetime.now(),
                source_app=source_app,
                item_type="history"
            )
            self.items.insert(0, new_item)

            # Enforce size limit
            if len(self.items) > self.max_items:
                self.items = self.items[:self.max_items]

            return new_item

    def find_by_content(self, content: str) -> Optional[ClipboardItem]:
        """
        Find an item by exact content match.

        Args:
            content: The content to search for

        Returns:
            The matching ClipboardItem or None if not found
        """
        for item in self.items:
            if item.content == content:
                return item
        return None

    def search(self, query: str, case_sensitive: bool = False) -> List[ClipboardItem]:
        """
        Search history for items containing the query string.

        Args:
            query: The search term
            case_sensitive: Whether to perform case-sensitive search

        Returns:
            List of matching ClipboardItems
        """
        if not query:
            return []

        results = []
        search_query = query if case_sensitive else query.lower()

        for item in self.items:
            search_content = item.content if case_sensitive else item.content.lower()
            if search_query in search_content:
                results.append(item)

        return results

    def get_recent(self, count: int = 10) -> List[ClipboardItem]:
        """
        Get the most recent items from history.

        Args:
            count: Number of items to return

        Returns:
            List of most recent ClipboardItems
        """
        return self.items[:min(count, len(self.items))]

    def get_all(self) -> List[ClipboardItem]:
        """
        Get all items in history.

        Returns:
            List of all ClipboardItems
        """
        return self.items.copy()

    def remove(self, item: ClipboardItem) -> bool:
        """
        Remove a specific item from history.

        Args:
            item: The ClipboardItem to remove

        Returns:
            True if item was removed, False if not found
        """
        try:
            self.items.remove(item)
            return True
        except ValueError:
            return False

    def remove_by_content(self, content: str) -> bool:
        """
        Remove an item by its content.

        Args:
            content: The content to match and remove

        Returns:
            True if item was removed, False if not found
        """
        item = self.find_by_content(content)
        if item:
            return self.remove(item)
        return False

    def clear(self):
        """Clear all items from history."""
        self.items = []

    def size(self) -> int:
        """
        Get the current number of items in history.

        Returns:
            Number of items in history
        """
        return len(self.items)

    def is_empty(self) -> bool:
        """
        Check if history is empty.

        Returns:
            True if history is empty, False otherwise
        """
        return len(self.items) == 0

    def save(self) -> bool:
        """
        Save history to JSON file.

        Returns:
            True if save successful, False otherwise
        """
        try:
            data = [item.to_dict() for item in self.items]
            with open(self.history_file, 'w') as f:
                json.dump(data, f, indent=2)
            return True
        except Exception as e:
            print(f"Error saving history: {e}")
            return False

    def load(self) -> bool:
        """
        Load history from JSON file.

        Returns:
            True if load successful, False otherwise
        """
        try:
            if os.path.exists(self.history_file):
                with open(self.history_file, 'r') as f:
                    data = json.load(f)

                self.items = [ClipboardItem.from_dict(item_data) for item_data in data]

                # Enforce size limit after loading
                if len(self.items) > self.max_items:
                    self.items = self.items[:self.max_items]

                return True
            else:
                # No file exists yet, start with empty history
                self.items = []
                return True
        except Exception as e:
            print(f"Error loading history: {e}")
            self.items = []
            return False

    def get_stats(self) -> Dict[str, Any]:
        """
        Get statistics about the history.

        Returns:
            Dictionary containing history statistics
        """
        if not self.items:
            return {
                "total_items": 0,
                "max_items": self.max_items,
                "oldest_item": None,
                "newest_item": None
            }

        return {
            "total_items": len(self.items),
            "max_items": self.max_items,
            "oldest_item": self.items[-1].timestamp.isoformat(),
            "newest_item": self.items[0].timestamp.isoformat()
        }

    def __len__(self) -> int:
        """Return the number of items in history."""
        return len(self.items)

    def __iter__(self):
        """Make the store iterable."""
        return iter(self.items)

    def __repr__(self) -> str:
        return f"HistoryStore(items={len(self.items)}, max={self.max_items})"
