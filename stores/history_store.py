"""
HistoryStore for SimpleCP.

Manages recent clipboard history with automatic deduplication,
size limits, and auto-generated folder organization.
Adapted from Flycut's FlycutStore architecture.
"""

from typing import List, Dict, Any, Callable, Optional, Tuple
from .clipboard_item import ClipboardItem


class HistoryStore:
    """
    Manages clipboard history with Flycut-inspired patterns.

    Key features:
    - Configurable size limits (max_items, display_count, display_length)
    - Delegate pattern for UI update notifications
    - Automatic duplicate detection and removal
    - Auto-generated folders for older items (11-20, 21-30, etc.)
    - Modified state tracking for persistence

    Inspired by Flycut's FlycutStore with enhancements.
    """

    def __init__(
        self,
        max_items: int = 50,
        display_count: int = 10,
        display_length: int = 50
    ):
        """
        Initialize HistoryStore.

        Args:
            max_items: Maximum number of items to remember (jcRememberNum)
            display_count: Number of items to show directly (jcDisplayNum)
            display_length: Character limit for display (jcDisplayLen)
        """
        # Flycut's core settings
        self.max_items = max_items              # jcRememberNum
        self.display_count = display_count      # jcDisplayNum
        self.display_length = display_length    # jcDisplayLen
        self.modified = False                   # modifiedSinceLastSaveStore

        # Storage
        self.items: List[ClipboardItem] = []    # jcList

        # Delegate pattern for UI updates
        self.delegates: List[Callable] = []

    def add_delegate(self, delegate: Callable) -> None:
        """
        Add a delegate to receive update notifications.

        Delegate will be called with: delegate(event_type, *args)
        Event types: 'will_insert', 'did_insert', 'will_delete', 'did_delete',
                    'did_update', 'will_clear', 'did_clear'
        """
        if delegate not in self.delegates:
            self.delegates.append(delegate)

    def remove_delegate(self, delegate: Callable) -> None:
        """Remove a delegate from notifications."""
        if delegate in self.delegates:
            self.delegates.remove(delegate)

    def notify_delegates(self, event_type: str, *args) -> None:
        """Notify all delegates of an event."""
        for delegate in self.delegates:
            try:
                delegate(event_type, *args)
            except Exception as e:
                print(f"Delegate notification error: {e}")

    def insert(self, item: ClipboardItem, index: int = 0) -> None:
        """
        Insert item at specified index (Flycut's insertClipping pattern).

        Args:
            item: ClipboardItem to insert
            index: Position to insert (default: 0 for most recent)
        """
        self.notify_delegates('will_insert', index, item)

        # Update display length for consistency
        item.update_display_length(self.display_length)

        # Insert item
        self.items.insert(index, item)

        # Enforce size limit (Flycut's trimming)
        if len(self.items) > self.max_items:
            removed_item = self.items.pop()
            self.notify_delegates('did_delete', len(self.items), removed_item)

        self.modified = True
        self.notify_delegates('did_insert', index, item)

    def find_duplicate(self, item: ClipboardItem) -> int:
        """
        Find duplicate item in history (Flycut's removeDuplicates pattern).

        Args:
            item: ClipboardItem to search for

        Returns:
            Index of duplicate item, or -1 if not found
        """
        for i, existing_item in enumerate(self.items):
            if existing_item.content == item.content:
                return i
        return -1

    def move_to_top(self, index: int) -> None:
        """
        Move item at index to position 0 (Flycut's duplicate handling).

        Args:
            index: Index of item to move to top
        """
        if 0 <= index < len(self.items):
            item = self.items.pop(index)
            self.notify_delegates('will_delete', index, item)
            self.items.insert(0, item)
            self.notify_delegates('did_insert', 0, item)
            self.modified = True

    def add_clip(self, content: str) -> ClipboardItem:
        """
        Add new clip with automatic duplicate handling.

        Args:
            content: Text content to add

        Returns:
            The ClipboardItem that was added or moved to top
        """
        # Create new item
        new_item = ClipboardItem(content, display_length=self.display_length)

        # Check for duplicates
        existing_index = self.find_duplicate(new_item)
        if existing_index >= 0:
            # Move existing item to top
            self.move_to_top(existing_index)
            return self.items[0]

        # Add new item to top
        self.insert(new_item, 0)
        return new_item

    def get_item(self, index: int) -> Optional[ClipboardItem]:
        """
        Get item at index.

        Args:
            index: Position in history

        Returns:
            ClipboardItem at index, or None if out of bounds
        """
        if 0 <= index < len(self.items):
            return self.items[index]
        return None

    def remove_item(self, index: int) -> Optional[ClipboardItem]:
        """
        Remove item at index.

        Args:
            index: Position to remove

        Returns:
            Removed ClipboardItem, or None if out of bounds
        """
        if 0 <= index < len(self.items):
            self.notify_delegates('will_delete', index, self.items[index])
            removed_item = self.items.pop(index)
            self.notify_delegates('did_delete', index, removed_item)
            self.modified = True
            return removed_item
        return None

    def clear(self) -> None:
        """Clear all items from history."""
        self.notify_delegates('will_clear')
        self.items.clear()
        self.modified = True
        self.notify_delegates('did_clear')

    def get_recent_items(self, count: Optional[int] = None) -> List[ClipboardItem]:
        """
        Get most recent items (those shown directly in UI).

        Args:
            count: Number of items to return (default: display_count)

        Returns:
            List of recent ClipboardItem objects
        """
        count = count or self.display_count
        return self.items[:count]

    def get_auto_folders(self) -> List[Dict[str, Any]]:
        """
        Generate auto-folders for older items (SimpleCP enhancement).

        Creates folders like "11-20", "21-30", etc. for items beyond
        the first display_count items.

        Returns:
            List of folder dictionaries with 'name' and 'items' keys
        """
        folders = []
        total_items = len(self.items)

        # Skip first display_count items (they show directly)
        start_index = self.display_count

        while start_index < total_items:
            # Calculate folder range
            end_index = min(start_index + self.display_count - 1, total_items - 1)
            folder_name = f"{start_index + 1}-{end_index + 1}"

            # Get items in this range
            folder_items = self.items[start_index:end_index + 1]

            folders.append({
                "name": folder_name,
                "items": folder_items,
                "start_index": start_index,
                "end_index": end_index,
                "count": len(folder_items)
            })

            start_index = end_index + 1

        return folders

    def search(self, query: str) -> List[Tuple[int, ClipboardItem]]:
        """
        Search for items matching query.

        Args:
            query: Search string (case-insensitive)

        Returns:
            List of (index, ClipboardItem) tuples matching query
        """
        query_lower = query.lower()
        results = []

        for i, item in enumerate(self.items):
            if query_lower in item.content.lower():
                results.append((i, item))

        return results

    def get_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about the history store.

        Returns:
            Dictionary with statistics
        """
        total_items = len(self.items)
        auto_folders = self.get_auto_folders()

        content_types = {}
        for item in self.items:
            content_type = item.content_type
            content_types[content_type] = content_types.get(content_type, 0) + 1

        return {
            "total_items": total_items,
            "recent_items": min(total_items, self.display_count),
            "folder_count": len(auto_folders),
            "max_items": self.max_items,
            "is_full": total_items >= self.max_items,
            "content_types": content_types,
            "modified": self.modified
        }

    def to_dict(self) -> Dict[str, Any]:
        """
        Serialize store to dictionary for persistence.

        Returns:
            Dictionary representation of store
        """
        return {
            "max_items": self.max_items,
            "display_count": self.display_count,
            "display_length": self.display_length,
            "items": [item.to_dict() for item in self.items]
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'HistoryStore':
        """
        Deserialize store from dictionary.

        Args:
            data: Dictionary containing store data

        Returns:
            Reconstructed HistoryStore
        """
        store = cls(
            max_items=data.get("max_items", 50),
            display_count=data.get("display_count", 10),
            display_length=data.get("display_length", 50)
        )

        # Load items
        items_data = data.get("items", [])
        for item_data in items_data:
            item = ClipboardItem.from_dict(item_data)
            store.items.append(item)

        store.modified = False  # Just loaded, so not modified
        return store

    def __len__(self) -> int:
        """Return number of items in store."""
        return len(self.items)

    def __repr__(self) -> str:
        """Developer-friendly representation."""
        return f"HistoryStore(items={len(self.items)}/{self.max_items}, modified={self.modified})"