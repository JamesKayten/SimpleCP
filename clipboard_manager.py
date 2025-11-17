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
from stores.settings_store import SettingsStore
from stores.analytics_store import AnalyticsStore
from utils.advanced_search import AdvancedSearch
from utils.privacy_filter import PrivacyFilter
from utils.import_export import ImportExportManager


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
        self.data_dir = data_dir or os.path.join(os.path.dirname(__file__), "data")
        os.makedirs(self.data_dir, exist_ok=True)

        # Initialize settings store first (used by other components)
        self.settings = SettingsStore(self.data_dir)

        # Override max_history from settings if available
        max_history = self.settings.get("history.max_items", max_history)
        display_count = self.settings.get("history.display_count", display_count)

        # Initialize stores
        self.history_store = HistoryStore(max_items=max_history, display_count=display_count)
        self.snippet_store = SnippetStore()
        self.analytics = AnalyticsStore(self.data_dir)

        # Initialize utilities
        self.search = AdvancedSearch()
        self.privacy = PrivacyFilter(self.settings)
        self.import_export = ImportExportManager(self)

        # Internal state
        self._current_clipboard = ""
        self.history_file = os.path.join(self.data_dir, "history.json")
        self.snippets_file = os.path.join(self.data_dir, "snippets.json")
        self.auto_save_enabled = self.settings.get("backend.auto_save", True)

        # Load existing data
        self.load_stores()

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

    def add_clip(self, content: str, source_app: Optional[str] = None) -> Optional[ClipboardItem]:
        """Add clipboard item to history with automatic deduplication and privacy filtering."""
        # Check privacy mode
        if self.privacy.should_exclude_app(source_app):
            print(f"Excluded app: {source_app}")
            return None

        # Check for sensitive content
        if self.privacy.should_filter_content(content, source_app):
            print(f"Filtered sensitive content from {source_app}")
            return None

        # Create and add clip
        clip = ClipboardItem(content=content, source_app=source_app)
        self.history_store.insert(clip)

        # Track analytics
        if self.settings.get("analytics.enabled", True):
            self.analytics.track_copy_event(
                clip.clip_id,
                clip.content_type,
                source_app,
                action="copy"
            )

        if self.auto_save_enabled:
            self.save_stores()

        return clip

    def copy_to_clipboard(self, clip_id: str) -> bool:
        """Copy item to system clipboard by ID."""
        item = None
        item_type = None

        # Check history
        for hist_item in self.history_store.items:
            if hist_item.clip_id == clip_id:
                item = hist_item
                item_type = "history"
                break

        # Check snippets
        if not item:
            item = self.snippet_store.get_snippet_by_id(clip_id)
            if item:
                item_type = "snippet"

        if item:
            pyperclip.copy(item.content)
            self._current_clipboard = item.content

            # Track analytics
            if self.settings.get("analytics.enabled", True):
                self.analytics.track_copy_event(
                    clip_id,
                    item.content_type,
                    item.source_app,
                    action="paste"
                )

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
        """Delete specific history item by ID."""
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
        # Track search
        if self.settings.get("analytics.enabled", True):
            self.analytics.track_search(query)

        return {
            "history": self.history_store.search(query),
            "snippets": self.snippet_store.search(query)
        }

    def advanced_search(
        self,
        query: Optional[str] = None,
        search_type: str = "fuzzy",
        content_types: Optional[List[str]] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        source_apps: Optional[List[str]] = None,
        tags: Optional[List[str]] = None,
        include_history: bool = True,
        include_snippets: bool = True,
        sort_by: Optional[str] = None,
        reverse: bool = False
    ) -> Dict[str, List[ClipboardItem]]:
        """
        Perform advanced search with multiple filters

        Args:
            query: Search query
            search_type: "fuzzy", "regex", or "exact"
            content_types: Filter by content types
            start_date: Filter by start date
            end_date: Filter by end date
            source_apps: Filter by source apps
            tags: Filter by tags
            include_history: Include history items
            include_snippets: Include snippet items
            sort_by: Field to sort by
            reverse: Reverse sort order

        Returns:
            Dictionary with history and snippets results
        """
        results = {"history": [], "snippets": []}

        # Get fuzzy threshold from settings
        fuzzy_threshold = self.settings.get("search.fuzzy_threshold", 0.6)
        case_sensitive = self.settings.get("search.case_sensitive", False)

        # Search history
        if include_history:
            items = self.history_store.get_all_items()
            results["history"] = self.search.advanced_search(
                items,
                query=query,
                search_type=search_type,
                fuzzy_threshold=fuzzy_threshold,
                case_sensitive=case_sensitive,
                content_types=content_types,
                start_date=start_date,
                end_date=end_date,
                source_apps=source_apps,
                tags=tags,
                sort_by=sort_by,
                reverse=reverse
            )

        # Search snippets
        if include_snippets:
            items = []
            for folder_items in self.snippet_store.folders.values():
                items.extend(folder_items)

            results["snippets"] = self.search.advanced_search(
                items,
                query=query,
                search_type=search_type,
                fuzzy_threshold=fuzzy_threshold,
                case_sensitive=case_sensitive,
                content_types=content_types,
                start_date=start_date,
                end_date=end_date,
                source_apps=source_apps,
                tags=tags,
                sort_by=sort_by,
                reverse=reverse
            )

        # Track search
        if query and self.settings.get("analytics.enabled", True):
            self.analytics.track_search(query)

        return results

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
        """Load all stores from disk."""
        try:
            if os.path.exists(self.history_file):
                with open(self.history_file, 'r') as f:
                    data = json.load(f)
                self.history_store.items = [
                    ClipboardItem.from_dict(item_data) for item_data in data
                ]
            if os.path.exists(self.snippets_file):
                with open(self.snippets_file, 'r') as f:
                    data = json.load(f)
                for folder_name, items_data in data.items():
                    self.snippet_store.folders[folder_name] = [
                        ClipboardItem.from_dict(item_data) for item_data in items_data
                    ]
        except Exception as e:
            print(f"Error loading stores: {e}")

    def get_stats(self) -> Dict[str, Any]:
        """Get manager statistics."""
        stats = {
            "history_count": len(self.history_store),
            "snippet_count": len(self.snippet_store),
            "folder_count": len(self.snippet_store.folders),
            "max_history": self.history_store.max_items
        }

        # Add analytics insights if enabled
        if self.settings.get("analytics.enabled", True):
            insights = self.analytics.get_insights()
            stats["analytics"] = insights

        return stats

    # Analytics operations
    def get_analytics_summary(self, period: str = "week") -> Dict[str, Any]:
        """Get analytics summary for a period"""
        return self.analytics.get_usage_summary(period)

    def get_most_copied(self, limit: int = 10) -> List[Any]:
        """Get most copied items with full item data"""
        most_copied_ids = self.analytics.get_most_copied(limit)
        results = []

        for clip_id, count in most_copied_ids:
            # Find item in history or snippets
            item = None
            for hist_item in self.history_store.items:
                if hist_item.clip_id == clip_id:
                    item = hist_item
                    break

            if not item:
                item = self.snippet_store.get_snippet_by_id(clip_id)

            if item:
                results.append({
                    "item": item,
                    "copy_count": count
                })

        return results

    def cleanup_old_data(self):
        """Cleanup old data based on settings"""
        if not self.settings.should_auto_cleanup():
            return

        cleanup_settings = self.settings.get_cleanup_settings()
        retention_days = cleanup_settings.get("delete_after_days", 30)

        # Cleanup analytics
        analytics_retention = self.settings.get("analytics.retention_days", 90)
        self.analytics.cleanup_old_data(analytics_retention)

        # TODO: Cleanup old history items based on date
        # This would require adding timestamp-based cleanup to HistoryStore

        if self.auto_save_enabled:
            self.save_stores()
