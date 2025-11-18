"""
SnippetStore for SimpleCP.

Manages organized snippet folders for reusable text clips.
Based on Flycut's favorites store pattern with folder organization.
"""

from typing import Dict, List, Optional, Callable, Any
from stores.clipboard_item import ClipboardItem


class SnippetStore:
    """
    Manages snippet folders and items.
    Based on Flycut's favoritesStore with folder organization.

    Features:
    - Folder-based organization
    - Full CRUD operations for snippets
    - Folder management (create, rename, delete)
    - Search across all snippets
    - Delegate pattern for UI updates
    - Modified flag for persistence tracking
    """

    def __init__(self):
        """Initialize SnippetStore."""
        # Folder structure: folder_name -> list of ClipboardItem
        self.folders: Dict[str, List[ClipboardItem]] = {}

        # Dirty flag for persistence
        self.modified = False

        # Delegate callbacks for UI updates
        self._delegates: List[Callable] = []

    def create_folder(self, folder_name: str) -> bool:
        """Create new folder."""
        if folder_name in self.folders:
            return False
        self.folders[folder_name] = []
        self.modified = True
        self._notify_delegates("folder_created", folder_name)
        return True

    def rename_folder(self, old_name: str, new_name: str) -> bool:
        """Rename folder."""
        if old_name not in self.folders or new_name in self.folders:
            return False
        self.folders[new_name] = self.folders.pop(old_name)
        for item in self.folders[new_name]:
            item.folder_path = new_name
        self.modified = True
        self._notify_delegates("folder_renamed", old_name, new_name)
        return True

    def delete_folder(self, folder_name: str) -> bool:
        """Delete folder and all its snippets."""
        if folder_name not in self.folders:
            return False
        del self.folders[folder_name]
        self.modified = True
        self._notify_delegates("folder_deleted", folder_name)
        return True

    def add_snippet(self, folder_name: str, item: ClipboardItem) -> bool:
        """Add snippet to folder."""
        if folder_name not in self.folders:
            self.create_folder(folder_name)
        if not item.has_name:
            item.make_snippet(
                name=item.snippet_name or item.display_string, folder=folder_name
            )
        item.folder_path = folder_name
        self.folders[folder_name].append(item)
        self.modified = True
        self._notify_delegates("snippet_added", folder_name, item)
        return True

    def delete_snippet(self, folder_name: str, clip_id: str) -> bool:
        """Delete snippet by ID."""
        if folder_name not in self.folders:
            return False
        for i, item in enumerate(self.folders[folder_name]):
            if item.clip_id == clip_id:
                deleted_item = self.folders[folder_name].pop(i)
                self.modified = True
                self._notify_delegates("snippet_deleted", folder_name, deleted_item)
                return True
        return False

    def update_snippet(
        self,
        folder_name: str,
        clip_id: str,
        new_content: Optional[str] = None,
        new_name: Optional[str] = None,
        new_tags: Optional[List[str]] = None,
    ) -> bool:
        """Update snippet properties."""
        if folder_name not in self.folders:
            return False
        for item in self.folders[folder_name]:
            if item.clip_id == clip_id:
                if new_content is not None:
                    item.content = new_content
                    item.display_string = item._create_display_string()
                if new_name is not None:
                    item.snippet_name = new_name
                if new_tags is not None:
                    item.tags = new_tags
                self.modified = True
                self._notify_delegates("snippet_updated", folder_name, item)
                return True
        return False

    def move_snippet(self, from_folder: str, to_folder: str, clip_id: str) -> bool:
        """Move snippet between folders."""
        if from_folder not in self.folders:
            return False
        for i, item in enumerate(self.folders[from_folder]):
            if item.clip_id == clip_id:
                snippet = self.folders[from_folder].pop(i)
                snippet.folder_path = to_folder
                if to_folder not in self.folders:
                    self.create_folder(to_folder)
                self.folders[to_folder].append(snippet)
                self.modified = True
                self._notify_delegates("snippet_moved", from_folder, to_folder, snippet)
                return True
        return False

    def get_folder_names(self) -> List[str]:
        """Get list of all folder names."""
        return sorted(self.folders.keys())

    def get_folder_items(self, folder_name: str) -> List[ClipboardItem]:
        """Get all snippets in a folder."""
        return self.folders.get(folder_name, []).copy()

    def get_all_snippets(self) -> Dict[str, List[ClipboardItem]]:
        """Get all snippets organized by folder."""
        return {folder: items.copy() for folder, items in self.folders.items()}

    def search(self, query: str) -> List[ClipboardItem]:
        """Search all snippets matching query."""
        results = []
        for items in self.folders.values():
            results.extend([item for item in items if item.matches_search(query)])
        return results

    def get_snippet_by_id(self, clip_id: str) -> Optional[ClipboardItem]:
        """Find snippet by ID across all folders."""
        for items in self.folders.values():
            for item in items:
                if item.clip_id == clip_id:
                    return item
        return None

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
        """Return total number of snippets across all folders."""
        return sum(len(items) for items in self.folders.values())

    def __repr__(self) -> str:
        return f"SnippetStore(folders={len(self.folders)}, snippets={len(self)})"
