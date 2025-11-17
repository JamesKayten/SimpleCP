"""
ClipboardManager - Core backend service.

Backend-only clipboard management using Flycut's multi-store pattern.
No UI code - designed to be consumed by REST API and future Swift frontend.
"""

import pyperclip
import json
import os
import threading
from datetime import datetime
from typing import Optional, List, Dict, Any
from stores.clipboard_item import ClipboardItem
from stores.history_store import HistoryStore
from stores.snippet_store import SnippetStore
from stores.indexing import rebuild_history_indexes, rebuild_snippet_indexes


class ClipboardManager:
    """
    Core clipboard manager backend.
    Based on Flycut's FlycutOperator pattern with multi-store architecture.

    Features:
    - Multi-store management (history, snippets)
    - Background clipboard monitoring
    - Snippet workflow methods
    - Persistence management
    - Search across all stores
    - API-ready methods
    """

    def __init__(
        self,
        data_dir: Optional[str] = None,
        max_history: int = 50,
        display_count: int = 10,
        auto_save_interval: int = 30
    ):
        """
        Initialize ClipboardManager with multi-store pattern.

        Args:
            data_dir: Directory for data storage
            max_history: Maximum history items
            display_count: Items to show directly
            auto_save_interval: Seconds between auto-saves (0 to disable)
        """
        self.history_store = HistoryStore(max_items=max_history, display_count=display_count)
        self.snippet_store = SnippetStore()
        self._current_clipboard = ""
        self.data_dir = data_dir or os.path.join(os.path.dirname(__file__), "data")
        os.makedirs(self.data_dir, exist_ok=True)
        self.history_file = os.path.join(self.data_dir, "history.json")
        self.snippets_file = os.path.join(self.data_dir, "snippets.json")

        # Lazy persistence for menu bar performance
        self.auto_save_enabled = False  # Disabled for performance
        self.auto_save_interval = auto_save_interval
        self._save_timer: Optional[threading.Timer] = None
        self._save_lock = threading.Lock()

        self.load_stores()

        # Start periodic save timer if interval > 0
        if self.auto_save_interval > 0:
            self._start_periodic_save()

    def check_clipboard(self) -> Optional[ClipboardItem]:
        """Check clipboard for changes and add to history if changed."""
        try:
            current = pyperclip.paste()
            if current != self._current_clipboard and current.strip():
                self._current_clipboard = current
                return self.add_clip(current)
        except Exception as e:
            print(f"Error checking clipboard: {e}")
        return None

    def add_clip(self, content: str, source_app: Optional[str] = None) -> ClipboardItem:
        """Add clipboard item to history with automatic deduplication."""
        clip = ClipboardItem(content=content, source_app=source_app)
        self.history_store.insert(clip)
        if self.auto_save_enabled:
            self.save_stores()
        return clip

    def copy_to_clipboard(self, clip_id: str) -> bool:
        """Copy item to system clipboard by ID using O(1) index lookup."""
        # Try history store first (O(1) lookup)
        item = self.history_store.get_by_id(clip_id)
        if item:
            pyperclip.copy(item.content)
            self._current_clipboard = item.content
            return True
        # Try snippet store (O(1) lookup)
        item = self.snippet_store.get_snippet_by_id(clip_id)
        if item:
            pyperclip.copy(item.content)
            self._current_clipboard = item.content
            return True
        return False

    def save_as_snippet(
        self, clip_id: str, name: str, folder: str, tags: Optional[List[str]] = None
    ) -> Optional[ClipboardItem]:
        """Convert history item to snippet using O(1) lookup."""
        item = self.history_store.get_by_id(clip_id)
        if item:
            snippet = item.make_snippet(name, folder, tags)
            self.snippet_store.add_snippet(folder, snippet)
            if self.auto_save_enabled:
                self.save_stores()
            return snippet
        return None

    # History operations
    def get_recent_history(self) -> List[ClipboardItem]:
        """Get recent history items."""
        return self.history_store.get_recent_items()

    def get_all_history(self, limit: Optional[int] = None) -> List[ClipboardItem]:
        """Get all history items."""
        return self.history_store.get_items(limit)

    def get_history_folders(self) -> List[Dict[str, Any]]:
        """Get auto-generated history folder ranges."""
        return self.history_store.get_auto_folders()

    def clear_history(self):
        """Clear all clipboard history."""
        self.history_store.clear()
        if self.auto_save_enabled:
            self.save_stores()

    def delete_history_item(self, clip_id: str) -> bool:
        """Delete specific history item by ID using indexed lookup."""
        # Find item using index
        item = self.history_store.get_by_id(clip_id)
        if item:
            # Find its index in the list
            for i, list_item in enumerate(self.history_store.items):
                if list_item.clip_id == clip_id:
                    self.history_store.delete_item(i)
                    if self.auto_save_enabled:
                        self.save_stores()
                    return True
        return False

    # Snippet operations
    def create_snippet_folder(self, folder_name: str) -> bool:
        """Create new snippet folder."""
        result = self.snippet_store.create_folder(folder_name)
        if result and self.auto_save_enabled:
            self.save_stores()
        return result

    def rename_snippet_folder(self, old_name: str, new_name: str) -> bool:
        """Rename snippet folder."""
        result = self.snippet_store.rename_folder(old_name, new_name)
        if result and self.auto_save_enabled:
            self.save_stores()
        return result

    def delete_snippet_folder(self, folder_name: str) -> bool:
        """Delete snippet folder."""
        result = self.snippet_store.delete_folder(folder_name)
        if result and self.auto_save_enabled:
            self.save_stores()
        return result

    def get_snippet_folders(self) -> List[str]:
        """Get all snippet folder names."""
        return self.snippet_store.get_folder_names()

    def get_folder_snippets(self, folder_name: str) -> List[ClipboardItem]:
        """Get all snippets in a folder."""
        return self.snippet_store.get_folder_items(folder_name)

    def get_all_snippets(self) -> Dict[str, List[ClipboardItem]]:
        """Get all snippets organized by folder."""
        return self.snippet_store.get_all_snippets()

    def add_snippet_direct(
        self, content: str, name: str, folder: str, tags: Optional[List[str]] = None
    ) -> ClipboardItem:
        """Create and add snippet directly."""
        snippet = ClipboardItem(content=content)
        snippet.make_snippet(name, folder, tags)
        self.snippet_store.add_snippet(folder, snippet)
        if self.auto_save_enabled:
            self.save_stores()
        return snippet

    def update_snippet(
        self, folder_name: str, clip_id: str,
        new_content: Optional[str] = None,
        new_name: Optional[str] = None,
        new_tags: Optional[List[str]] = None
    ) -> bool:
        """Update snippet properties."""
        result = self.snippet_store.update_snippet(
            folder_name, clip_id, new_content, new_name, new_tags
        )
        if result and self.auto_save_enabled:
            self.save_stores()
        return result

    def delete_snippet(self, folder_name: str, clip_id: str) -> bool:
        """Delete specific snippet."""
        result = self.snippet_store.delete_snippet(folder_name, clip_id)
        if result and self.auto_save_enabled:
            self.save_stores()
        return result

    def move_snippet(self, from_folder: str, to_folder: str, clip_id: str) -> bool:
        """Move snippet between folders."""
        result = self.snippet_store.move_snippet(from_folder, to_folder, clip_id)
        if result and self.auto_save_enabled:
            self.save_stores()
        return result

    # Search operations
    def search_all(self, query: str) -> Dict[str, List[ClipboardItem]]:
        """Search across history and snippets."""
        return {
            "history": self.history_store.search(query),
            "snippets": self.snippet_store.search(query)
        }

    # Persistence operations
    def save_stores(self):
        """Save all stores to disk."""
        try:
            history_data = [item.to_dict() for item in self.history_store.items]
            with open(self.history_file, 'w') as f:
                json.dump(history_data, f, indent=2)
            snippet_data = {
                folder: [item.to_dict() for item in items]
                for folder, items in self.snippet_store.folders.items()
            }
            with open(self.snippets_file, 'w') as f:
                json.dump(snippet_data, f, indent=2)
            self.history_store.modified = False
            self.snippet_store.modified = False
        except Exception as e:
            print(f"Error saving stores: {e}")

    def load_stores(self):
        """Load all stores from disk and rebuild indexes."""
        try:
            if os.path.exists(self.history_file):
                with open(self.history_file, 'r') as f:
                    data = json.load(f)
                self.history_store.items = [
                    ClipboardItem.from_dict(item_data) for item_data in data
                ]
                # Rebuild indexes for performance
                rebuild_history_indexes(self.history_store)

            if os.path.exists(self.snippets_file):
                with open(self.snippets_file, 'r') as f:
                    data = json.load(f)
                for folder_name, items_data in data.items():
                    self.snippet_store.folders[folder_name] = [
                        ClipboardItem.from_dict(item_data) for item_data in items_data
                    ]
                # Rebuild indexes for performance
                rebuild_snippet_indexes(self.snippet_store)

        except Exception as e:
            print(f"Error loading stores: {e}")

    def get_stats(self) -> Dict[str, Any]:
        """Get manager statistics."""
        return {
            "history_count": len(self.history_store),
            "snippet_count": len(self.snippet_store),
            "folder_count": len(self.snippet_store.folders),
            "max_history": self.history_store.max_items,
            "modified": self.history_store.modified or self.snippet_store.modified
        }

    # Lazy persistence methods for menu bar performance
    def _start_periodic_save(self):
        """Start periodic auto-save timer."""
        def save_if_modified():
            if self.history_store.modified or self.snippet_store.modified:
                self.save_stores()
            # Schedule next save
            if self.auto_save_interval > 0:
                self._save_timer = threading.Timer(
                    self.auto_save_interval,
                    save_if_modified
                )
                self._save_timer.daemon = True
                self._save_timer.start()

        # Start first timer
        save_if_modified()

    def shutdown(self):
        """
        Shutdown manager gracefully.
        Cancels timer and forces final save.
        Call this before app exit.
        """
        # Cancel periodic save timer
        if self._save_timer:
            self._save_timer.cancel()
            self._save_timer = None

        # Force final save
        with self._save_lock:
            if self.history_store.modified or self.snippet_store.modified:
                self.save_stores()
                print("💾 Final save completed")
