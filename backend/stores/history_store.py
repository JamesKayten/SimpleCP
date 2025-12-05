"""
HistoryStore for SimpleCP.

Manages recent clipboard history with automatic deduplication,
size limits, and auto-generated folder ranges.
"""

from typing import List, Optional, Callable, Dict, Any
from stores.clipboard_item import ClipboardItem


class HistoryStore:
    """
    Manages clipboard history items.

    Features:
    - Automatic deduplication (moves duplicates to top)
    - Size limits with automatic trimming
    - Auto-generated folder ranges (11-20, 21-30, etc.)
    - Delegate pattern for UI updates
    - Modified flag for persistence tracking
    """

    def __init__(
        self,
        max_items: int = 50,
        display_count: int = 10,
        display_length: int = 50,
    ):
        """
        Initialize HistoryStore.

        Args:
            max_items: Maximum items to store
            display_count: How many to display directly
            display_length: Character limit for display
        """
        self.max_items = max_items
        self.display_count = display_count
        self.display_length = display_length

        # Storage
        self.items: List[ClipboardItem] = []

        # Dirty flag for persistence
        self.modified = False

        # Delegate callbacks for UI updates
        self._delegates: List[Callable] = []

    def insert(self, item: ClipboardItem, index: int = 0) -> bool:
        """Insert item with duplicate handling. Returns True if inserted."""
        # Check for duplicates
        duplicate_index = self.find_duplicate(item)
        if duplicate_index >= 0:
            self.move_to_top(duplicate_index)
            return False

        self._notify_delegates("will_insert", index, item)
        self.items.insert(index, item)
        self.modified = True

        # Enforce size limit
        if len(self.items) > self.max_items:
            removed = self.items.pop()
            self._notify_delegates("did_delete", len(self.items), removed)

        self._notify_delegates("did_insert", index, item)
        return True

    def find_duplicate(self, item: ClipboardItem) -> int:
        """Find duplicate by content. Returns index or -1."""
        for i, existing_item in enumerate(self.items):
            if existing_item.content == item.content:
                return i
        return -1

    def move_to_top(self, index: int):
        """Move item at index to top."""
        if 0 <= index < len(self.items):
            item = self.items.pop(index)
            self.items.insert(0, item)
            self.modified = True
            self._notify_delegates("item_moved", index, 0, item)

    def get_items(self, limit: Optional[int] = None) -> List[ClipboardItem]:
        """Get history items with optional limit."""
        return self.items.copy() if limit is None else self.items[:limit]

    def get_recent_items(self) -> List[ClipboardItem]:
        """Get items for direct display."""
        return self.items[: self.display_count]

    def get_auto_folders(self) -> List[Dict[str, Any]]:
        """
        Generate auto-folders for history beyond display_count.
        Groups items in ranges like "11-20", "21-30", etc.

        Returns:
            List of folder dictionaries with name and items
        """
        folders = []
        total_items = len(self.items)

        # Skip first display_count items (they show directly)
        start_index = self.display_count

        while start_index < total_items:
            end_index = min(start_index + self.display_count - 1, total_items - 1)
            folder_name = f"{start_index + 1}-{end_index + 1}"
            folder_items = self.items[start_index : end_index + 1]

            folders.append(
                {
                    "name": folder_name,
                    "start_index": start_index,
                    "end_index": end_index,
                    "items": folder_items,
                    "count": len(folder_items),
                }
            )

            start_index = end_index + 1

        return folders

    def delete_item(self, index: int) -> Optional[ClipboardItem]:
        """Delete item at index."""
        if 0 <= index < len(self.items):
            item = self.items.pop(index)
            self.modified = True
            self._notify_delegates("did_delete", index, item)
            return item
        return None

    def clear(self):
        """Clear all history items."""
        self.items.clear()
        self.modified = True
        self._notify_delegates("store_cleared")

    def search(self, query: str) -> List[ClipboardItem]:
        """Search items matching query."""
        return [item for item in self.items if item.matches_search(query)]

    def add_delegate(self, callback: Callable):
        """Add delegate callback for store updates."""
        if callback not in self._delegates:
            self._delegates.append(callback)

    def remove_delegate(self, callback: Callable):
        """Remove delegate callback."""
        if callback in self._delegates:
            self._delegates.remove(callback)

    def _notify_delegates(self, event: str, *args):
        """Notify all delegates of an event."""
        for delegate in self._delegates:
            try:
                delegate(event, *args)
            except Exception:
                pass  # Don't let delegate errors break the store

    def __len__(self) -> int:
        """Return number of items in store."""
        return len(self.items)

    def __getitem__(self, index: int) -> ClipboardItem:
        """Get item by index."""
        return self.items[index]

    def __repr__(self) -> str:
        return f"HistoryStore(items={len(self.items)}, max={self.max_items})"
