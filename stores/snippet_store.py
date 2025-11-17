"""
SnippetStore for SimpleCP.

Manages organized snippet folders for reusable text clips.
Based on Flycut's FavoritesStore architecture.
"""

import json
import uuid
from pathlib import Path
from typing import List, Dict, Optional, Any
from datetime import datetime


class Snippet:
    """
    Represents a single snippet with metadata.
    """

    def __init__(
        self,
        content: str,
        name: str,
        folder: str,
        snippet_id: Optional[str] = None,
        created_at: Optional[datetime] = None
    ):
        self.id = snippet_id or str(uuid.uuid4())
        self.content = content
        self.name = name
        self.folder = folder
        self.created_at = created_at or datetime.now()

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "id": self.id,
            "content": self.content,
            "name": self.name,
            "folder": self.folder,
            "created_at": self.created_at.isoformat()
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Snippet':
        """Create Snippet from dictionary."""
        return cls(
            content=data["content"],
            name=data["name"],
            folder=data["folder"],
            snippet_id=data.get("id"),
            created_at=datetime.fromisoformat(data["created_at"]) if "created_at" in data else None
        )

    def __repr__(self) -> str:
        return f"Snippet(name='{self.name}', folder='{self.folder}')"


class SnippetStore:
    """
    Manages snippet folders and snippets.

    Structure:
    - Folders contain multiple snippets
    - Each snippet has a unique ID for editing/deleting
    - Supports folder creation, renaming, deletion
    - Full CRUD operations on snippets
    """

    def __init__(self, data_file: str = "data/snippets.json"):
        """
        Initialize the SnippetStore.

        Args:
            data_file: Path to JSON file for persistence
        """
        self.data_file = Path(data_file)
        self.folders: Dict[str, List[Snippet]] = {}
        self._dirty = False

        # Ensure data directory exists
        self.data_file.parent.mkdir(parents=True, exist_ok=True)

        # Load existing data
        self.load()

    # ========== Folder Management ==========

    def create_folder(self, folder_name: str) -> bool:
        """
        Create a new folder.

        Args:
            folder_name: Name of the folder to create

        Returns:
            bool: True if created, False if already exists
        """
        if folder_name in self.folders:
            return False

        self.folders[folder_name] = []
        self._dirty = True
        self.save()
        return True

    def get_folders(self) -> List[str]:
        """
        Get list of all folder names.

        Returns:
            List of folder names
        """
        return sorted(self.folders.keys())

    def rename_folder(self, old_name: str, new_name: str) -> bool:
        """
        Rename a folder.

        Args:
            old_name: Current folder name
            new_name: New folder name

        Returns:
            bool: True if renamed successfully
        """
        if old_name not in self.folders or new_name in self.folders:
            return False

        # Move all snippets to new folder name
        snippets = self.folders.pop(old_name)
        for snippet in snippets:
            snippet.folder = new_name
        self.folders[new_name] = snippets

        self._dirty = True
        self.save()
        return True

    def delete_folder(self, folder_name: str) -> bool:
        """
        Delete a folder and all its snippets.

        Args:
            folder_name: Name of folder to delete

        Returns:
            bool: True if deleted successfully
        """
        if folder_name not in self.folders:
            return False

        del self.folders[folder_name]
        self._dirty = True
        self.save()
        return True

    def folder_exists(self, folder_name: str) -> bool:
        """Check if folder exists."""
        return folder_name in self.folders

    # ========== Snippet Management ==========

    def add_snippet(self, folder_name: str, name: str, content: str) -> Optional[Snippet]:
        """
        Add a new snippet to a folder.

        Args:
            folder_name: Folder to add snippet to
            name: Name of the snippet
            content: Content of the snippet

        Returns:
            Snippet if created, None if folder doesn't exist
        """
        if folder_name not in self.folders:
            # Auto-create folder if it doesn't exist
            self.create_folder(folder_name)

        # Create new snippet
        snippet = Snippet(content=content, name=name, folder=folder_name)
        self.folders[folder_name].append(snippet)

        self._dirty = True
        self.save()
        return snippet

    def get_snippets(self, folder_name: str) -> List[Snippet]:
        """
        Get all snippets in a folder.

        Args:
            folder_name: Name of the folder

        Returns:
            List of Snippets in the folder
        """
        return self.folders.get(folder_name, []).copy()

    def get_all_snippets(self) -> List[Snippet]:
        """
        Get all snippets from all folders.

        Returns:
            List of all Snippets
        """
        all_snippets = []
        for snippets in self.folders.values():
            all_snippets.extend(snippets)
        return all_snippets

    def get_snippet_by_id(self, snippet_id: str) -> Optional[Snippet]:
        """
        Get snippet by ID.

        Args:
            snippet_id: Unique ID of the snippet

        Returns:
            Snippet if found, None otherwise
        """
        for snippets in self.folders.values():
            for snippet in snippets:
                if snippet.id == snippet_id:
                    return snippet
        return None

    def update_snippet(self, snippet_id: str, name: Optional[str] = None,
                      content: Optional[str] = None, folder: Optional[str] = None) -> bool:
        """
        Update a snippet.

        Args:
            snippet_id: ID of snippet to update
            name: New name (optional)
            content: New content (optional)
            folder: New folder (optional, will move snippet)

        Returns:
            bool: True if updated successfully
        """
        snippet = self.get_snippet_by_id(snippet_id)
        if not snippet:
            return False

        # Update fields
        if name is not None:
            snippet.name = name
        if content is not None:
            snippet.content = content

        # Move to different folder if requested
        if folder is not None and folder != snippet.folder:
            # Remove from old folder
            old_folder = snippet.folder
            self.folders[old_folder].remove(snippet)

            # Add to new folder (create if doesn't exist)
            if folder not in self.folders:
                self.create_folder(folder)
            snippet.folder = folder
            self.folders[folder].append(snippet)

        self._dirty = True
        self.save()
        return True

    def delete_snippet(self, snippet_id: str) -> bool:
        """
        Delete a snippet by ID.

        Args:
            snippet_id: ID of snippet to delete

        Returns:
            bool: True if deleted successfully
        """
        for folder_name, snippets in self.folders.items():
            for snippet in snippets:
                if snippet.id == snippet_id:
                    snippets.remove(snippet)
                    self._dirty = True
                    self.save()
                    return True
        return False

    # ========== Search ==========

    def search(self, query: str) -> List[Snippet]:
        """
        Search snippets by name or content.

        Args:
            query: Search string (case-insensitive)

        Returns:
            List of matching Snippets
        """
        query_lower = query.lower()
        results = []

        for snippets in self.folders.values():
            for snippet in snippets:
                if (query_lower in snippet.name.lower() or
                    query_lower in snippet.content.lower()):
                    results.append(snippet)

        return results

    # ========== Persistence ==========

    def save(self):
        """Save snippets to JSON file if dirty."""
        if not self._dirty:
            return

        try:
            # Convert to the expected format
            data = {
                "folders": {}
            }

            # Also save with full metadata for API
            full_data = []

            for folder_name, snippets in self.folders.items():
                # Legacy format for compatibility
                data["folders"][folder_name] = {
                    snippet.name: snippet.content for snippet in snippets
                }

                # Full format with IDs
                for snippet in snippets:
                    full_data.append(snippet.to_dict())

            # Save both formats
            with open(self.data_file, 'w') as f:
                json.dump(data, f, indent=2)

            # Save full format to a separate file for API use
            full_file = self.data_file.parent / "snippets_full.json"
            with open(full_file, 'w') as f:
                json.dump(full_data, f, indent=2)

            self._dirty = False
        except Exception as e:
            print(f"Error saving snippets: {e}")

    def load(self):
        """Load snippets from JSON file."""
        # Try to load full format first
        full_file = self.data_file.parent / "snippets_full.json"
        if full_file.exists():
            try:
                with open(full_file, 'r') as f:
                    snippets_data = json.load(f)

                # Reconstruct folders from full format
                self.folders = {}
                for snippet_data in snippets_data:
                    snippet = Snippet.from_dict(snippet_data)
                    if snippet.folder not in self.folders:
                        self.folders[snippet.folder] = []
                    self.folders[snippet.folder].append(snippet)

                self._dirty = False
                return
            except Exception as e:
                print(f"Error loading full snippets: {e}")

        # Fall back to legacy format
        if not self.data_file.exists():
            return

        try:
            with open(self.data_file, 'r') as f:
                data = json.load(f)

            # Convert legacy format to new format
            self.folders = {}
            folders_data = data.get("folders", {})

            for folder_name, snippets_dict in folders_data.items():
                self.folders[folder_name] = []
                for snippet_name, snippet_content in snippets_dict.items():
                    snippet = Snippet(
                        content=snippet_content,
                        name=snippet_name,
                        folder=folder_name
                    )
                    self.folders[folder_name].append(snippet)

            self._dirty = False
        except Exception as e:
            print(f"Error loading snippets: {e}")
            self.folders = {}

    def get_stats(self) -> Dict[str, Any]:
        """
        Get statistics about the snippet store.

        Returns:
            Dictionary with stats
        """
        total_snippets = sum(len(snippets) for snippets in self.folders.values())
        return {
            "total_folders": len(self.folders),
            "total_snippets": total_snippets,
            "folders": [
                {
                    "name": folder,
                    "count": len(snippets)
                }
                for folder, snippets in sorted(self.folders.items())
            ]
        }

    def __repr__(self) -> str:
        total_snippets = sum(len(snippets) for snippets in self.folders.values())
        return f"SnippetStore(folders={len(self.folders)}, snippets={total_snippets})"
