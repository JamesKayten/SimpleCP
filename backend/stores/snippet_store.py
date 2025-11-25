"""
SnippetStore for SimpleCP.

Manages organized snippet folders for reusable text clips.
Based on Flycut's favorites store pattern with folder organization.
"""

import logging
import re
import sys
import traceback
from typing import Dict, List, Optional, Callable
from stores.clipboard_item import ClipboardItem

# Configure logger for this module
logger = logging.getLogger(__name__)


def _log_resource_state(operation: str, context: dict = None):
    """Log memory and resource state for debugging crashes."""
    try:
        import resource
        usage = resource.getrusage(resource.RUSAGE_SELF)
        mem_mb = usage.ru_maxrss / 1024 / 1024  # Convert to MB (macOS reports bytes)
        logger.debug(f"[RESOURCE] {operation}: max_rss={mem_mb:.2f}MB, user_time={usage.ru_utime:.3f}s")
    except ImportError:
        pass  # resource module not available on all platforms

    # Log Python memory info
    logger.debug(f"[RESOURCE] {operation}: ref_count={len(sys.modules)} modules loaded")

    if context:
        logger.debug(f"[RESOURCE] {operation}: context={context}")


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

    def _sanitize_folder_name(self, name: str) -> str:
        """Sanitize folder name to prevent issues with special characters."""
        if not name:
            return name
        # Strip whitespace
        name = name.strip()
        # Remove control characters
        name = re.sub(r'[\x00-\x1f\x7f]', '', name)
        # Replace problematic characters for filesystem/API
        name = re.sub(r'[<>:"/\\|?*]', '_', name)
        return name

    def rename_folder(self, old_name: str, new_name: str) -> dict:
        """Rename folder. Returns success status and specific error details."""
        logger.info(f"rename_folder called: '{old_name}' -> '{new_name}'")
        logger.debug(f"  old_name repr: {repr(old_name)}")
        logger.debug(f"  new_name repr: {repr(new_name)}")

        # Log resource state at start
        _log_resource_state("rename_folder:START", {
            "old_name": old_name,
            "new_name": new_name,
            "folder_count": len(self.folders),
            "total_snippets": len(self)
        })

        # Validate input
        if not old_name or not old_name.strip():
            logger.warning("rename_folder failed: SOURCE_EMPTY")
            return {"success": False, "error": "SOURCE_EMPTY", "message": "Source folder name cannot be empty"}

        if not new_name or not new_name.strip():
            logger.warning("rename_folder failed: TARGET_EMPTY")
            return {"success": False, "error": "TARGET_EMPTY", "message": "New folder name cannot be empty"}

        # Sanitize names
        old_name = self._sanitize_folder_name(old_name)
        new_name = self._sanitize_folder_name(new_name)
        logger.debug(f"  After sanitization: '{old_name}' -> '{new_name}'")

        # Check if source folder exists
        if old_name not in self.folders:
            logger.warning(f"rename_folder failed: SOURCE_NOT_FOUND - '{old_name}'")
            logger.debug(f"  Available folders: {list(self.folders.keys())}")
            return {
                "success": False,
                "error": "SOURCE_NOT_FOUND",
                "message": f"Folder '{old_name}' does not exist"
            }

        # Check if target name is the same as source
        if old_name == new_name:
            logger.info(f"rename_folder: SAME_NAME - no change needed")
            return {
                "success": False,
                "error": "SAME_NAME",
                "message": "New folder name must be different from the current name"
            }

        # Check if target folder already exists
        if new_name in self.folders:
            logger.warning(f"rename_folder failed: TARGET_EXISTS - '{new_name}'")
            return {
                "success": False,
                "error": "TARGET_EXISTS",
                "message": f"A folder named '{new_name}' already exists"
            }

        # Perform the rename
        try:
            logger.info(f"rename_folder: performing rename '{old_name}' -> '{new_name}'")
            _log_resource_state("rename_folder:BEFORE_POP")

            self.folders[new_name] = self.folders.pop(old_name)
            _log_resource_state("rename_folder:AFTER_POP")

            snippet_count = len(self.folders[new_name])
            for i, item in enumerate(self.folders[new_name]):
                item.folder_path = new_name
                if i % 100 == 0 and snippet_count > 100:
                    _log_resource_state(f"rename_folder:UPDATE_ITEM_{i}/{snippet_count}")

            self.modified = True
            _log_resource_state("rename_folder:BEFORE_NOTIFY")
            self._notify_delegates("folder_renamed", old_name, new_name)
            _log_resource_state("rename_folder:AFTER_NOTIFY")

            logger.info(f"rename_folder: SUCCESS - '{old_name}' -> '{new_name}'")
            return {
                "success": True,
                "message": f"Folder renamed from '{old_name}' to '{new_name}' successfully"
            }
        except Exception as e:
            _log_resource_state("rename_folder:EXCEPTION", {
                "exception_type": type(e).__name__,
                "exception_msg": str(e)
            })
            logger.error(f"rename_folder EXCEPTION: {type(e).__name__}: {str(e)}", exc_info=True)
            return {
                "success": False,
                "error": "RENAME_FAILED",
                "message": f"Failed to rename folder: {str(e)}"
            }

    def rename_folder_legacy(self, old_name: str, new_name: str) -> bool:
        """Legacy rename method for backward compatibility."""
        result = self.rename_folder(old_name, new_name)
        return result["success"]

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
                name=item.snippet_name or item.display_string,
                folder=folder_name,
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
        logger.debug(f"_notify_delegates: event='{event}', args={args}, delegates={len(self._delegates)}")
        for delegate in self._delegates:
            try:
                delegate(event, *args)
            except Exception as e:
                # Log delegate errors instead of silently ignoring them
                logger.error(
                    f"Delegate error during '{event}' event: {type(e).__name__}: {str(e)}",
                    exc_info=True
                )
                # Continue notifying other delegates, but don't silently fail

    def __len__(self) -> int:
        """Return total number of snippets across all folders."""
        return sum(len(items) for items in self.folders.values())

    def __repr__(self) -> str:
        return f"SnippetStore(folders={len(self.folders)}, snippets={len(self)})"
