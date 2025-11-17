"""
SnippetStore for SimpleCP.

Manages organized snippet folders for reusable text clips.
Adapted from Flycut's favorites/snippets architecture.
"""

from typing import List, Dict, Any, Callable, Optional, Tuple
from .clipboard_item import ClipboardItem


class SnippetFolder:
    """
    Represents a folder containing organized snippets.

    Attributes:
        name: Folder display name
        icon: Emoji or icon for the folder
        snippets: List of ClipboardItem snippets
        collapsed: Whether folder is collapsed in UI
        order: Display order index
    """

    def __init__(
        self,
        name: str,
        icon: str = "📁",
        collapsed: bool = False,
        order: int = 0
    ):
        self.name = name
        self.icon = icon
        self.snippets: List[ClipboardItem] = []
        self.collapsed = collapsed
        self.order = order

    def add_snippet(self, snippet: ClipboardItem) -> None:
        """Add snippet to folder."""
        snippet.folder_path = self.name
        snippet.has_name = True
        self.snippets.append(snippet)

    def remove_snippet(self, snippet_name: str) -> Optional[ClipboardItem]:
        """Remove snippet by name."""
        for i, snippet in enumerate(self.snippets):
            if snippet.snippet_name == snippet_name:
                return self.snippets.pop(i)
        return None

    def find_snippet(self, snippet_name: str) -> Optional[ClipboardItem]:
        """Find snippet by name."""
        for snippet in self.snippets:
            if snippet.snippet_name == snippet_name:
                return snippet
        return None

    def to_dict(self) -> Dict[str, Any]:
        """Serialize folder to dictionary."""
        return {
            "name": self.name,
            "icon": self.icon,
            "collapsed": self.collapsed,
            "order": self.order,
            "snippets": [snippet.to_dict() for snippet in self.snippets]
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'SnippetFolder':
        """Deserialize folder from dictionary."""
        folder = cls(
            name=data["name"],
            icon=data.get("icon", "📁"),
            collapsed=data.get("collapsed", False),
            order=data.get("order", 0)
        )

        # Load snippets
        snippets_data = data.get("snippets", [])
        for snippet_data in snippets_data:
            snippet = ClipboardItem.from_dict(snippet_data)
            folder.snippets.append(snippet)

        return folder

    def __len__(self) -> int:
        """Return number of snippets in folder."""
        return len(self.snippets)

    def __repr__(self) -> str:
        """Developer-friendly representation."""
        return f"SnippetFolder(name='{self.name}', snippets={len(self.snippets)})"


class SnippetStore:
    """
    Manages organized snippet folders (Flycut's favorites pattern).

    Key features:
    - Folder-based organization
    - Custom folder icons
    - Folder ordering and management
    - Snippet CRUD operations
    - Delegate pattern for UI updates
    - Modified state tracking
    - Search across all snippets
    """

    def __init__(self):
        """Initialize SnippetStore."""
        # Storage: folder_name -> SnippetFolder
        self.folders: Dict[str, SnippetFolder] = {}
        self.folder_order: List[str] = []  # Maintain display order

        # Delegate pattern for UI updates
        self.delegates: List[Callable] = []

        # Modified state tracking
        self.modified = False

    def add_delegate(self, delegate: Callable) -> None:
        """
        Add a delegate to receive update notifications.

        Delegate will be called with: delegate(event_type, *args)
        Event types: 'folder_created', 'folder_deleted', 'folder_renamed',
                    'folder_reordered', 'snippet_added', 'snippet_removed',
                    'snippet_updated'
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

    def create_folder(
        self,
        folder_name: str,
        icon: str = "📁",
        order: Optional[int] = None
    ) -> SnippetFolder:
        """
        Create a new snippet folder.

        Args:
            folder_name: Name for the folder
            icon: Emoji icon for the folder
            order: Display order (default: append to end)

        Returns:
            Created SnippetFolder

        Raises:
            ValueError: If folder already exists
        """
        if folder_name in self.folders:
            raise ValueError(f"Folder '{folder_name}' already exists")

        # Determine order
        if order is None:
            order = len(self.folder_order)

        # Create folder
        folder = SnippetFolder(name=folder_name, icon=icon, order=order)
        self.folders[folder_name] = folder
        self.folder_order.append(folder_name)

        self.modified = True
        self.notify_delegates('folder_created', folder)

        return folder

    def delete_folder(self, folder_name: str) -> Optional[SnippetFolder]:
        """
        Delete a snippet folder.

        Args:
            folder_name: Name of folder to delete

        Returns:
            Deleted SnippetFolder, or None if not found
        """
        if folder_name not in self.folders:
            return None

        folder = self.folders.pop(folder_name)
        self.folder_order.remove(folder_name)

        self.modified = True
        self.notify_delegates('folder_deleted', folder)

        return folder

    def rename_folder(self, old_name: str, new_name: str) -> bool:
        """
        Rename a folder.

        Args:
            old_name: Current folder name
            new_name: New folder name

        Returns:
            True if successful, False otherwise
        """
        if old_name not in self.folders or new_name in self.folders:
            return False

        # Update folder
        folder = self.folders.pop(old_name)
        folder.name = new_name

        # Update all snippets in folder
        for snippet in folder.snippets:
            snippet.folder_path = new_name

        # Update storage
        self.folders[new_name] = folder

        # Update order list
        index = self.folder_order.index(old_name)
        self.folder_order[index] = new_name

        self.modified = True
        self.notify_delegates('folder_renamed', old_name, new_name)

        return True

    def reorder_folders(self, folder_names: List[str]) -> bool:
        """
        Reorder folders.

        Args:
            folder_names: List of folder names in desired order

        Returns:
            True if successful, False otherwise
        """
        # Validate all folders exist
        if set(folder_names) != set(self.folder_order):
            return False

        # Update order
        self.folder_order = folder_names.copy()

        # Update order index in each folder
        for i, folder_name in enumerate(self.folder_order):
            self.folders[folder_name].order = i

        self.modified = True
        self.notify_delegates('folder_reordered', folder_names)

        return True

    def change_folder_icon(self, folder_name: str, icon: str) -> bool:
        """
        Change folder icon.

        Args:
            folder_name: Name of folder
            icon: New icon emoji

        Returns:
            True if successful, False otherwise
        """
        if folder_name not in self.folders:
            return False

        self.folders[folder_name].icon = icon
        self.modified = True
        self.notify_delegates('folder_updated', folder_name)

        return True

    def get_folder(self, folder_name: str) -> Optional[SnippetFolder]:
        """Get folder by name."""
        return self.folders.get(folder_name)

    def get_all_folders(self, ordered: bool = True) -> List[SnippetFolder]:
        """
        Get all folders.

        Args:
            ordered: Return folders in display order

        Returns:
            List of SnippetFolder objects
        """
        if ordered:
            return [self.folders[name] for name in self.folder_order if name in self.folders]
        return list(self.folders.values())

    def add_snippet(
        self,
        folder_name: str,
        snippet: ClipboardItem,
        snippet_name: str,
        tags: Optional[List[str]] = None
    ) -> bool:
        """
        Add snippet to folder.

        Args:
            folder_name: Target folder name
            snippet: ClipboardItem to add
            snippet_name: Name for the snippet
            tags: Optional tags

        Returns:
            True if successful, False otherwise
        """
        if folder_name not in self.folders:
            return False

        # Convert to snippet
        snippet.make_snippet(snippet_name, folder_name, tags)

        # Add to folder
        self.folders[folder_name].add_snippet(snippet)

        self.modified = True
        self.notify_delegates('snippet_added', folder_name, snippet)

        return True

    def remove_snippet(self, folder_name: str, snippet_name: str) -> Optional[ClipboardItem]:
        """
        Remove snippet from folder.

        Args:
            folder_name: Folder containing snippet
            snippet_name: Name of snippet to remove

        Returns:
            Removed ClipboardItem, or None if not found
        """
        if folder_name not in self.folders:
            return None

        snippet = self.folders[folder_name].remove_snippet(snippet_name)

        if snippet:
            self.modified = True
            self.notify_delegates('snippet_removed', folder_name, snippet)

        return snippet

    def move_snippet(
        self,
        from_folder: str,
        to_folder: str,
        snippet_name: str
    ) -> bool:
        """
        Move snippet between folders.

        Args:
            from_folder: Source folder name
            to_folder: Destination folder name
            snippet_name: Name of snippet to move

        Returns:
            True if successful, False otherwise
        """
        if from_folder not in self.folders or to_folder not in self.folders:
            return False

        # Remove from source
        snippet = self.folders[from_folder].remove_snippet(snippet_name)
        if not snippet:
            return False

        # Update folder path
        snippet.folder_path = to_folder

        # Add to destination
        self.folders[to_folder].add_snippet(snippet)

        self.modified = True
        self.notify_delegates('snippet_moved', from_folder, to_folder, snippet)

        return True

    def find_snippet(self, snippet_name: str) -> Optional[Tuple[str, ClipboardItem]]:
        """
        Find snippet by name across all folders.

        Args:
            snippet_name: Name of snippet to find

        Returns:
            Tuple of (folder_name, ClipboardItem) or None if not found
        """
        for folder_name, folder in self.folders.items():
            snippet = folder.find_snippet(snippet_name)
            if snippet:
                return (folder_name, snippet)
        return None

    def search(self, query: str) -> List[Tuple[str, ClipboardItem]]:
        """
        Search for snippets matching query.

        Args:
            query: Search string (case-insensitive)

        Returns:
            List of (folder_name, ClipboardItem) tuples matching query
        """
        query_lower = query.lower()
        results = []

        for folder_name, folder in self.folders.items():
            for snippet in folder.snippets:
                # Search in name, content, and tags
                if (query_lower in snippet.snippet_name.lower() or
                    query_lower in snippet.content.lower() or
                    any(query_lower in tag.lower() for tag in snippet.tags)):
                    results.append((folder_name, snippet))

        return results

    def get_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about the snippet store.

        Returns:
            Dictionary with statistics
        """
        total_snippets = sum(len(folder) for folder in self.folders.values())
        total_folders = len(self.folders)

        folder_sizes = {
            name: len(folder)
            for name, folder in self.folders.items()
        }

        return {
            "total_folders": total_folders,
            "total_snippets": total_snippets,
            "folder_sizes": folder_sizes,
            "modified": self.modified
        }

    def to_dict(self) -> Dict[str, Any]:
        """
        Serialize store to dictionary for persistence.

        Returns:
            Dictionary representation of store
        """
        return {
            "folders": {
                name: folder.to_dict()
                for name, folder in self.folders.items()
            },
            "folder_order": self.folder_order
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'SnippetStore':
        """
        Deserialize store from dictionary.

        Args:
            data: Dictionary containing store data

        Returns:
            Reconstructed SnippetStore
        """
        store = cls()

        # Load folders
        folders_data = data.get("folders", {})
        for folder_name, folder_data in folders_data.items():
            folder = SnippetFolder.from_dict(folder_data)
            store.folders[folder_name] = folder

        # Load folder order
        store.folder_order = data.get("folder_order", list(store.folders.keys()))

        store.modified = False  # Just loaded, so not modified
        return store

    def __len__(self) -> int:
        """Return total number of snippets across all folders."""
        return sum(len(folder) for folder in self.folders.values())

    def __repr__(self) -> str:
        """Developer-friendly representation."""
        return f"SnippetStore(folders={len(self.folders)}, snippets={len(self)}, modified={self.modified})"