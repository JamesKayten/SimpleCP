"""
TempStore for SimpleCP.

Manages temporary clipboard storage for undo/redo functionality.
Adapted from Flycut's stashedStore architecture.
"""

from typing import Optional, List
from .clipboard_item import ClipboardItem


class TempStore:
    """
    Manages temporary clipboard items for undo/redo operations.

    This is inspired by Flycut's stashedStore, which provides a way
    to temporarily store clipboard items that might be restored later.

    Use cases:
    - Undo clipboard operations
    - Temporary storage during copy/paste workflows
    - Clipboard stack navigation
    """

    def __init__(self, max_items: int = 10):
        """
        Initialize TempStore.

        Args:
            max_items: Maximum number of items to keep in temp storage
        """
        self.max_items = max_items
        self.items: List[ClipboardItem] = []
        self.current_position = 0

    def stash(self, item: ClipboardItem) -> None:
        """
        Stash an item in temporary storage.

        Args:
            item: ClipboardItem to stash
        """
        # Add to front of list
        self.items.insert(0, item)

        # Enforce size limit
        if len(self.items) > self.max_items:
            self.items = self.items[:self.max_items]

        # Reset position
        self.current_position = 0

    def pop(self) -> Optional[ClipboardItem]:
        """
        Pop and return the most recent stashed item.

        Returns:
            Most recent ClipboardItem, or None if empty
        """
        if self.items:
            return self.items.pop(0)
        return None

    def peek(self, index: int = 0) -> Optional[ClipboardItem]:
        """
        Peek at item without removing it.

        Args:
            index: Position to peek at (default: 0 for most recent)

        Returns:
            ClipboardItem at index, or None if out of bounds
        """
        if 0 <= index < len(self.items):
            return self.items[index]
        return None

    def clear(self) -> None:
        """Clear all temporary items."""
        self.items.clear()
        self.current_position = 0

    def get_all(self) -> List[ClipboardItem]:
        """
        Get all stashed items.

        Returns:
            List of all ClipboardItem objects in temp storage
        """
        return self.items.copy()

    def navigate_forward(self) -> Optional[ClipboardItem]:
        """
        Navigate forward in temp stack (for redo-like operations).

        Returns:
            Next ClipboardItem, or None if at end
        """
        if self.current_position > 0:
            self.current_position -= 1
            return self.items[self.current_position]
        return None

    def navigate_backward(self) -> Optional[ClipboardItem]:
        """
        Navigate backward in temp stack (for undo-like operations).

        Returns:
            Previous ClipboardItem, or None if at beginning
        """
        if self.current_position < len(self.items) - 1:
            self.current_position += 1
            return self.items[self.current_position]
        return None

    def __len__(self) -> int:
        """Return number of items in temp store."""
        return len(self.items)

    def __repr__(self) -> str:
        """Developer-friendly representation."""
        return f"TempStore(items={len(self.items)}/{self.max_items}, position={self.current_position})"
