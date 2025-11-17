"""
ClipboardManager - Core backend service.

Backend-only clipboard management using Flycut's multi-store pattern.
No UI code - designed to be consumed by REST API and future Swift frontend.
"""

import pyperclip
import json
import os
import tempfile
import threading
import logging
from datetime import datetime
from typing import Optional, List, Dict, Any
from stores.clipboard_item import ClipboardItem
from stores.history_store import HistoryStore
from stores.snippet_store import SnippetStore

logger = logging.getLogger(__name__)


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
        display_count: int = 10
    ):
        """Initialize ClipboardManager with multi-store pattern."""
        # Thread safety lock for concurrent access from API and clipboard monitor
        self._lock = threading.RLock()

        self.history_store = HistoryStore(max_items=max_history, display_count=display_count)
        self.snippet_store = SnippetStore()
        self._current_clipboard = ""
        self.data_dir = data_dir or os.path.join(os.path.dirname(__file__), "data")
        os.makedirs(self.data_dir, exist_ok=True)
        self.history_file = os.path.join(self.data_dir, "history.json")
        self.snippets_file = os.path.join(self.data_dir, "snippets.json")
        self.auto_save_enabled = True
        self.load_stores()

    def check_clipboard(self) -> Optional[ClipboardItem]:
        """Check clipboard for changes and add to history if changed."""
        with self._lock:
            try:
                current = pyperclip.paste()
                if current != self._current_clipboard and current.strip():
                    self._current_clipboard = current
                    return self.add_clip(current)
            except Exception as e:
                logger.error(f"Error checking clipboard: {e}")
            return None

    def add_clip(self, content: str, source_app: Optional[str] = None) -> ClipboardItem:
        """Add clipboard item to history with automatic deduplication."""
        with self._lock:
            clip = ClipboardItem(content=content, source_app=source_app)
            self.history_store.insert(clip)
            if self.auto_save_enabled:
                self.save_stores()
            return clip

    def copy_to_clipboard(self, clip_id: str) -> bool:
        """Copy item to system clipboard by ID."""
        with self._lock:
            for item in self.history_store.items:
                if item.clip_id == clip_id:
                    pyperclip.copy(item.content)
                    self._current_clipboard = item.content
                    return True
            item = self.snippet_store.get_snippet_by_id(clip_id)
            if item:
                pyperclip.copy(item.content)
                self._current_clipboard = item.content
                return True
            return False

    def save_as_snippet(
        self, clip_id: str, name: str, folder: str, tags: Optional[List[str]] = None
    ) -> Optional[ClipboardItem]:
        """Convert history item to snippet."""
        with self._lock:
            for item in self.history_store.items:
                if item.clip_id == clip_id:
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
        with self._lock:
            self.history_store.clear()
            if self.auto_save_enabled:
                self.save_stores()

    def delete_history_item(self, clip_id: str) -> bool:
        """Delete specific history item by ID."""
        with self._lock:
            for i, item in enumerate(self.history_store.items):
                if item.clip_id == clip_id:
                    self.history_store.delete_item(i)
                    if self.auto_save_enabled:
                        self.save_stores()
                    return True
            return False

    # Snippet operations
    def create_snippet_folder(self, folder_name: str) -> bool:
        """Create new snippet folder."""
        with self._lock:
            result = self.snippet_store.create_folder(folder_name)
            if result and self.auto_save_enabled:
                self.save_stores()
            return result

    def rename_snippet_folder(self, old_name: str, new_name: str) -> bool:
        """Rename snippet folder."""
        with self._lock:
            result = self.snippet_store.rename_folder(old_name, new_name)
            if result and self.auto_save_enabled:
                self.save_stores()
            return result

    def delete_snippet_folder(self, folder_name: str) -> bool:
        """Delete snippet folder."""
        with self._lock:
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
        with self._lock:
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
        with self._lock:
            result = self.snippet_store.update_snippet(
                folder_name, clip_id, new_content, new_name, new_tags
            )
            if result and self.auto_save_enabled:
                self.save_stores()
            return result

    def delete_snippet(self, folder_name: str, clip_id: str) -> bool:
        """Delete specific snippet."""
        with self._lock:
            result = self.snippet_store.delete_snippet(folder_name, clip_id)
            if result and self.auto_save_enabled:
                self.save_stores()
            return result

    def move_snippet(self, from_folder: str, to_folder: str, clip_id: str) -> bool:
        """Move snippet between folders."""
        with self._lock:
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
        """Save all stores to disk with atomic writes."""
        # Note: This is called from within locked methods, so it inherits the lock
        try:
            # Atomic write for history: write to temp file, then rename
            history_data = [item.to_dict() for item in self.history_store.items]
            with tempfile.NamedTemporaryFile(mode='w', dir=self.data_dir, delete=False) as f:
                temp_history = f.name
                json.dump(history_data, f, indent=2)
            os.replace(temp_history, self.history_file)

            # Atomic write for snippets: write to temp file, then rename
            snippet_data = {
                folder: [item.to_dict() for item in items]
                for folder, items in self.snippet_store.folders.items()
            }
            with tempfile.NamedTemporaryFile(mode='w', dir=self.data_dir, delete=False) as f:
                temp_snippets = f.name
                json.dump(snippet_data, f, indent=2)
            os.replace(temp_snippets, self.snippets_file)

            self.history_store.modified = False
            self.snippet_store.modified = False
            logger.debug(f"Saved stores: {len(self.history_store)} history, {len(self.snippet_store)} snippets")
        except Exception as e:
            logger.error(f"Error saving stores: {e}", exc_info=True)
            # Clean up temp files if they exist
            try:
                if 'temp_history' in locals() and os.path.exists(temp_history):
                    os.unlink(temp_history)
                if 'temp_snippets' in locals() and os.path.exists(temp_snippets):
                    os.unlink(temp_snippets)
            except Exception as cleanup_error:
                logger.error(f"Error cleaning up temp files: {cleanup_error}")

    def load_stores(self):
        """Load all stores from disk."""
        with self._lock:
            try:
                if os.path.exists(self.history_file):
                    with open(self.history_file, 'r') as f:
                        data = json.load(f)
                    self.history_store.items = [
                        ClipboardItem.from_dict(item_data) for item_data in data
                    ]
                    logger.info(f"Loaded {len(self.history_store)} history items")
                if os.path.exists(self.snippets_file):
                    with open(self.snippets_file, 'r') as f:
                        data = json.load(f)
                    for folder_name, items_data in data.items():
                        self.snippet_store.folders[folder_name] = [
                            ClipboardItem.from_dict(item_data) for item_data in items_data
                        ]
                    logger.info(f"Loaded {len(self.snippet_store)} snippets from {len(self.snippet_store.folders)} folders")
            except Exception as e:
                logger.error(f"Error loading stores: {e}", exc_info=True)

    def get_stats(self) -> Dict[str, Any]:
        """Get manager statistics."""
        return {
            "history_count": len(self.history_store),
            "snippet_count": len(self.snippet_store),
            "folder_count": len(self.snippet_store.folders),
            "max_history": self.history_store.max_items
        }
