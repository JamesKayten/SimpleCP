"""
ClipboardManager - Core backend service.

Backend-only clipboard management using Flycut's multi-store pattern.
No UI code - designed to be consumed by REST API and future Swift frontend.
"""

import pyperclip
import json
import os
from datetime import datetime
from typing import Optional, List, Dict, Any
from stores.clipboard_item import ClipboardItem
from stores.history_store import HistoryStore
from stores.snippet_store import SnippetStore


class ClipboardManager:
    """
    Core clipboard manager backend.
    Based on Flycut's FlycutOperator pattern with multi-store architecture.
    Provides multi-store management, clipboard monitoring, persistence, and search.
    """

    def __init__(
        self,
        data_dir: Optional[str] = None,
        max_history: int = 50,
        display_count: int = 10,
    ):
        """Initialize ClipboardManager with multi-store pattern."""
        self.history_store = HistoryStore(
            max_items=max_history, display_count=display_count
        )
        self.snippet_store = SnippetStore()
        self._current_clipboard = ""
        self.data_dir = data_dir or os.path.join(os.path.dirname(__file__), "data")
        os.makedirs(self.data_dir, exist_ok=True)
        self.history_file = os.path.join(self.data_dir, "history.json")
        self.snippets_file = os.path.join(self.data_dir, "snippets.json")
        self.auto_save_enabled = True
        self.load_stores()

    def _persist_if_enabled(self):
        """Save stores if auto-save is enabled."""
        if self.auto_save_enabled:
            self.save_stores()

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
        self._persist_if_enabled()
        return clip

    def _find_item(self, clip_id: str) -> Optional[ClipboardItem]:
        """Find item by ID in history or snippets."""
        for item in self.history_store.items:
            if item.clip_id == clip_id:
                return item
        return self.snippet_store.get_snippet_by_id(clip_id)

    def copy_to_clipboard(self, clip_id: str) -> bool:
        """Copy item to system clipboard by ID."""
        item = self._find_item(clip_id)
        if item:
            pyperclip.copy(item.content)
            self._current_clipboard = item.content
            return True
        return False

    def save_as_snippet(
        self, clip_id: str, name: str, folder: str, tags: Optional[List[str]] = None
    ) -> Optional[ClipboardItem]:
        """Convert history item to snippet."""
        for item in self.history_store.items:
            if item.clip_id == clip_id:
                snippet = item.make_snippet(name, folder, tags)
                self.snippet_store.add_snippet(folder, snippet)
                self._persist_if_enabled()
                return snippet
        return None

    def get_recent_history(self) -> List[ClipboardItem]:
        return self.history_store.get_recent_items()

    def get_all_history(self, limit: Optional[int] = None) -> List[ClipboardItem]:
        return self.history_store.get_items(limit)

    def get_history_folders(self) -> List[Dict[str, Any]]:
        return self.history_store.get_auto_folders()

    def clear_history(self):
        self.history_store.clear()
        self._persist_if_enabled()

    def delete_history_item(self, clip_id: str) -> bool:
        for i, item in enumerate(self.history_store.items):
            if item.clip_id == clip_id:
                self.history_store.delete_item(i)
                self._persist_if_enabled()
                return True
        return False

    def create_snippet_folder(self, folder_name: str) -> bool:
        result = self.snippet_store.create_folder(folder_name)
        if result:
            self._persist_if_enabled()
        return result

    def rename_snippet_folder(self, old_name: str, new_name: str) -> bool:
        result = self.snippet_store.rename_folder(old_name, new_name)
        if result:
            self._persist_if_enabled()
        return result

    def delete_snippet_folder(self, folder_name: str) -> bool:
        result = self.snippet_store.delete_folder(folder_name)
        if result:
            self._persist_if_enabled()
        return result

    def get_snippet_folders(self) -> List[str]:
        return self.snippet_store.get_folder_names()

    def get_folder_snippets(self, folder_name: str) -> List[ClipboardItem]:
        return self.snippet_store.get_folder_items(folder_name)

    def get_all_snippets(self) -> Dict[str, List[ClipboardItem]]:
        return self.snippet_store.get_all_snippets()

    def add_snippet_direct(
        self, content: str, name: str, folder: str, tags: Optional[List[str]] = None
    ) -> ClipboardItem:
        snippet = ClipboardItem(content=content)
        snippet.make_snippet(name, folder, tags)
        self.snippet_store.add_snippet(folder, snippet)
        self._persist_if_enabled()
        return snippet

    def update_snippet(
        self,
        folder_name: str,
        clip_id: str,
        new_content: Optional[str] = None,
        new_name: Optional[str] = None,
        new_tags: Optional[List[str]] = None,
    ) -> bool:
        result = self.snippet_store.update_snippet(
            folder_name, clip_id, new_content, new_name, new_tags
        )
        if result:
            self._persist_if_enabled()
        return result

    def delete_snippet(self, folder_name: str, clip_id: str) -> bool:
        result = self.snippet_store.delete_snippet(folder_name, clip_id)
        if result:
            self._persist_if_enabled()
        return result

    def move_snippet(self, from_folder: str, to_folder: str, clip_id: str) -> bool:
        result = self.snippet_store.move_snippet(from_folder, to_folder, clip_id)
        if result:
            self._persist_if_enabled()
        return result

    def search_all(self, query: str) -> Dict[str, List[ClipboardItem]]:
        return {
            "history": self.history_store.search(query),
            "snippets": self.snippet_store.search(query),
        }

    def save_stores(self):
        try:
            with open(self.history_file, "w") as f:
                json.dump([item.to_dict() for item in self.history_store.items], f, indent=2)
            snippet_data = {
                folder: [item.to_dict() for item in items]
                for folder, items in self.snippet_store.folders.items()
            }
            with open(self.snippets_file, "w") as f:
                json.dump(snippet_data, f, indent=2)
            self.history_store.modified = self.snippet_store.modified = False
        except Exception as e:
            print(f"Error saving stores: {e}")

    def load_stores(self):
        try:
            if os.path.exists(self.history_file):
                with open(self.history_file) as f:
                    self.history_store.items = [
                        ClipboardItem.from_dict(d) for d in json.load(f)
                    ]
            if os.path.exists(self.snippets_file):
                with open(self.snippets_file) as f:
                    for folder_name, items_data in json.load(f).items():
                        self.snippet_store.folders[folder_name] = [
                            ClipboardItem.from_dict(d) for d in items_data
                        ]
        except Exception as e:
            print(f"Error loading stores: {e}")

    def get_stats(self) -> Dict[str, Any]:
        return {
            "monitoring": True,
            "history_count": len(self.history_store),
            "snippet_count": len(self.snippet_store),
            "folder_count": len(self.snippet_store.folders),
            "max_history": self.history_store.max_items,
        }

    def get_status(self) -> Dict[str, Any]:
        return {k: v for k, v in self.get_stats().items()
                if k not in ("folder_count", "max_history")}

    def export_snippets(self) -> Dict[str, Any]:
        return {
            "version": "1.0",
            "export_date": datetime.now().isoformat(),
            "snippets": [item.to_dict() for items in self.snippet_store.folders.values()
                         for item in items],
            "metadata": {"folder_count": len(self.snippet_store.folders)},
        }

    def import_snippets(self, import_data: Dict[str, Any]) -> bool:
        try:
            snippets = import_data.get("snippets", [])
            for snippet_data in snippets:
                item = ClipboardItem.from_dict(snippet_data)
                folder = item.folder_path or "Imported"
                self.snippet_store.add_snippet(folder, item)
            self._persist_if_enabled()
            return True
        except Exception as e:
            print(f"Error importing snippets: {e}")
            return False
