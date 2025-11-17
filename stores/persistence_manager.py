"""
PersistenceManager for SimpleCP.

Handles saving and loading of all stores to/from disk.
Adapted from Flycut's saveEngine/loadEngineFromPList architecture.
"""

import os
import json
from typing import Optional, Tuple
from .history_store import HistoryStore
from .snippet_store import SnippetStore


class PersistenceManager:
    """
    Manages persistence of clipboard history and snippets.

    Inspired by Flycut's save/load engine with JSON storage.

    Features:
    - Automatic save/load of history and snippets
    - Safe file operations with error handling
    - Backup creation before saving
    - Modified state tracking
    """

    def __init__(self, data_dir: str):
        """
        Initialize PersistenceManager.

        Args:
            data_dir: Directory for data storage
        """
        self.data_dir = data_dir
        self.history_file = os.path.join(data_dir, "history.json")
        self.snippets_file = os.path.join(data_dir, "snippets.json")

        # Ensure data directory exists
        os.makedirs(data_dir, exist_ok=True)

    def save_stores(
        self,
        history_store: HistoryStore,
        snippet_store: SnippetStore,
        create_backup: bool = True
    ) -> bool:
        """
        Save both stores to disk (Flycut's saveEngine pattern).

        Args:
            history_store: HistoryStore to save
            snippet_store: SnippetStore to save
            create_backup: Whether to create backup before saving

        Returns:
            True if successful, False otherwise
        """
        try:
            # Create backups if requested
            if create_backup:
                self._create_backup(self.history_file)
                self._create_backup(self.snippets_file)

            # Save history store
            history_data = history_store.to_dict()
            with open(self.history_file, 'w', encoding='utf-8') as f:
                json.dump(history_data, f, indent=2, ensure_ascii=False)

            # Save snippet store
            snippet_data = snippet_store.to_dict()
            with open(self.snippets_file, 'w', encoding='utf-8') as f:
                json.dump(snippet_data, f, indent=2, ensure_ascii=False)

            # Clear modified flags (Flycut pattern)
            history_store.modified = False
            snippet_store.modified = False

            print(f"💾 Saved {len(history_store)} history items and {len(snippet_store)} snippets")
            return True

        except Exception as e:
            print(f"❌ Error saving stores: {e}")
            return False

    def load_stores(self) -> Tuple[Optional[HistoryStore], Optional[SnippetStore]]:
        """
        Load both stores from disk (Flycut's loadEngineFromPList pattern).

        Returns:
            Tuple of (HistoryStore, SnippetStore) or (None, None) if error
        """
        history_store = None
        snippet_store = None

        try:
            # Load history store
            if os.path.exists(self.history_file):
                with open(self.history_file, 'r', encoding='utf-8') as f:
                    history_data = json.load(f)
                history_store = HistoryStore.from_dict(history_data)
                print(f"📂 Loaded {len(history_store)} history items")
            else:
                history_store = HistoryStore()
                print("📂 Created new history store")

            # Load snippet store
            if os.path.exists(self.snippets_file):
                with open(self.snippets_file, 'r', encoding='utf-8') as f:
                    snippet_data = json.load(f)
                snippet_store = SnippetStore.from_dict(snippet_data)
                print(f"📁 Loaded {len(snippet_store.folders)} snippet folders with {len(snippet_store)} snippets")
            else:
                snippet_store = SnippetStore()
                print("📁 Created new snippet store")

            return history_store, snippet_store

        except Exception as e:
            print(f"❌ Error loading stores: {e}")
            # Return new stores on error
            return HistoryStore(), SnippetStore()

    def save_history_only(self, history_store: HistoryStore) -> bool:
        """
        Save only the history store (for frequent updates).

        Args:
            history_store: HistoryStore to save

        Returns:
            True if successful, False otherwise
        """
        try:
            history_data = history_store.to_dict()
            with open(self.history_file, 'w', encoding='utf-8') as f:
                json.dump(history_data, f, indent=2, ensure_ascii=False)

            history_store.modified = False
            return True

        except Exception as e:
            print(f"❌ Error saving history: {e}")
            return False

    def save_snippets_only(self, snippet_store: SnippetStore) -> bool:
        """
        Save only the snippet store.

        Args:
            snippet_store: SnippetStore to save

        Returns:
            True if successful, False otherwise
        """
        try:
            snippet_data = snippet_store.to_dict()
            with open(self.snippets_file, 'w', encoding='utf-8') as f:
                json.dump(snippet_data, f, indent=2, ensure_ascii=False)

            snippet_store.modified = False
            return True

        except Exception as e:
            print(f"❌ Error saving snippets: {e}")
            return False

    def auto_save_if_modified(
        self,
        history_store: HistoryStore,
        snippet_store: SnippetStore
    ) -> bool:
        """
        Save stores only if they have been modified.

        Args:
            history_store: HistoryStore to check and save
            snippet_store: SnippetStore to check and save

        Returns:
            True if saved (or nothing to save), False if error
        """
        success = True

        if history_store.modified:
            success = success and self.save_history_only(history_store)

        if snippet_store.modified:
            success = success and self.save_snippets_only(snippet_store)

        return success

    def _create_backup(self, file_path: str) -> bool:
        """
        Create a backup of the file.

        Args:
            file_path: Path to file to backup

        Returns:
            True if backup created, False otherwise
        """
        if not os.path.exists(file_path):
            return False

        try:
            backup_path = file_path + ".backup"
            with open(file_path, 'r', encoding='utf-8') as src:
                with open(backup_path, 'w', encoding='utf-8') as dst:
                    dst.write(src.read())
            return True

        except Exception as e:
            print(f"⚠️ Warning: Could not create backup: {e}")
            return False

    def restore_from_backup(self) -> bool:
        """
        Restore stores from backup files.

        Returns:
            True if restored, False otherwise
        """
        try:
            history_backup = self.history_file + ".backup"
            snippets_backup = self.snippets_file + ".backup"

            restored = False

            if os.path.exists(history_backup):
                with open(history_backup, 'r', encoding='utf-8') as src:
                    with open(self.history_file, 'w', encoding='utf-8') as dst:
                        dst.write(src.read())
                print("📂 Restored history from backup")
                restored = True

            if os.path.exists(snippets_backup):
                with open(snippets_backup, 'r', encoding='utf-8') as src:
                    with open(self.snippets_file, 'w', encoding='utf-8') as dst:
                        dst.write(src.read())
                print("📁 Restored snippets from backup")
                restored = True

            return restored

        except Exception as e:
            print(f"❌ Error restoring from backup: {e}")
            return False

    def export_data(self, export_path: str) -> bool:
        """
        Export all data to a single JSON file.

        Args:
            export_path: Path to export file

        Returns:
            True if successful, False otherwise
        """
        try:
            # Read both stores
            history_data = {}
            snippet_data = {}

            if os.path.exists(self.history_file):
                with open(self.history_file, 'r', encoding='utf-8') as f:
                    history_data = json.load(f)

            if os.path.exists(self.snippets_file):
                with open(self.snippets_file, 'r', encoding='utf-8') as f:
                    snippet_data = json.load(f)

            # Combine into single export
            export_data = {
                "version": "1.0",
                "history": history_data,
                "snippets": snippet_data
            }

            # Write export file
            with open(export_path, 'w', encoding='utf-8') as f:
                json.dump(export_data, f, indent=2, ensure_ascii=False)

            print(f"📤 Exported data to {export_path}")
            return True

        except Exception as e:
            print(f"❌ Error exporting data: {e}")
            return False

    def import_data(self, import_path: str) -> Tuple[Optional[HistoryStore], Optional[SnippetStore]]:
        """
        Import data from an exported JSON file.

        Args:
            import_path: Path to import file

        Returns:
            Tuple of (HistoryStore, SnippetStore) or (None, None) if error
        """
        try:
            with open(import_path, 'r', encoding='utf-8') as f:
                import_data = json.load(f)

            # Extract history and snippets
            history_data = import_data.get("history", {})
            snippet_data = import_data.get("snippets", {})

            # Create stores
            history_store = HistoryStore.from_dict(history_data) if history_data else HistoryStore()
            snippet_store = SnippetStore.from_dict(snippet_data) if snippet_data else SnippetStore()

            print(f"📥 Imported data from {import_path}")
            return history_store, snippet_store

        except Exception as e:
            print(f"❌ Error importing data: {e}")
            return None, None

    def get_data_statistics(self) -> dict:
        """
        Get statistics about stored data files.

        Returns:
            Dictionary with file statistics
        """
        stats = {
            "data_dir": self.data_dir,
            "history_file_exists": os.path.exists(self.history_file),
            "snippets_file_exists": os.path.exists(self.snippets_file),
            "history_backup_exists": os.path.exists(self.history_file + ".backup"),
            "snippets_backup_exists": os.path.exists(self.snippets_file + ".backup")
        }

        # Add file sizes if they exist
        if stats["history_file_exists"]:
            stats["history_file_size"] = os.path.getsize(self.history_file)

        if stats["snippets_file_exists"]:
            stats["snippets_file_size"] = os.path.getsize(self.snippets_file)

        return stats

    def __repr__(self) -> str:
        """Developer-friendly representation."""
        return f"PersistenceManager(data_dir='{self.data_dir}')"
