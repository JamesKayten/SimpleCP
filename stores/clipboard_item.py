"""
ClipboardItem data model for SimpleCP.

Represents individual clipboard items with metadata.
Enhanced with Flycut patterns for robust clipboard management.
"""

from datetime import datetime
from typing import Optional, Dict, Any, List
import hashlib
import re

class ClipboardItem:
    """
    Represents a single clipboard item with metadata.
    Based on Flycut's FlycutClipping pattern with enhancements.

    Attributes:
        content: The text content of the clipboard item
        content_type: Type of content (text, url, email, code, etc.)
        timestamp: When the item was created/copied
        clip_id: Unique identifier for tracking
        display_length: Maximum length for display string
        display_string: Processed string for UI display
        source_app: Application that created this clipboard entry
        item_type: Type of item (history or snippet)

        Snippet properties (when converted from history):
        has_name: Whether this is a named snippet
        snippet_name: Name of the snippet
        folder_path: Folder containing this snippet
        tags: List of tags for organization
    """

    def __init__(
        self,
        content: str,
        timestamp: Optional[datetime] = None,
        source_app: Optional[str] = None,
        item_type: str = "history",
        content_type: Optional[str] = None,
        display_length: int = 50,
        clip_id: Optional[str] = None
    ):
        self.content = content
        self.timestamp = timestamp or datetime.now()
        self.source_app = source_app
        self.item_type = item_type

        # Display properties (from Flycut)
        self.display_length = display_length
        self.content_type = content_type or self._detect_content_type()
        self.display_string = self._create_display_string()

        # Unique ID for tracking
        self.clip_id = clip_id or self._generate_id()

        # Snippet properties (from Flycut's clipHasName pattern)
        self.has_name = False
        self.snippet_name: Optional[str] = None
        self.folder_path: Optional[str] = None
        self.tags: List[str] = []

    def _detect_content_type(self) -> str:
        """Detect content type based on patterns."""
        content = self.content.strip()

        # URL detection
        if re.match(r'^https?://', content):
            return "url"

        # Email detection
        if re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', content):
            return "email"

        # Code detection (simple heuristics)
        code_indicators = ['def ', 'class ', 'function ', 'import ', 'const ', 'var ', 'let ']
        if any(indicator in content for indicator in code_indicators):
            return "code"

        return "text"

    def _generate_id(self) -> str:
        """Generate unique ID from content and timestamp."""
        data = f"{self.content}{self.timestamp.isoformat()}"
        return hashlib.md5(data.encode()).hexdigest()[:16]

    def _create_display_string(self) -> str:
        """
        Create display string for UI.
        Flycut's display string logic adapted for Python.
        """
        clean_text = self.content.replace('\n', ' ').replace('\t', ' ').strip()

        if len(clean_text) <= self.display_length:
            return clean_text

        return clean_text[:self.display_length - 3] + "..."

    def make_snippet(
        self,
        name: str,
        folder: str,
        tags: Optional[List[str]] = None
    ) -> 'ClipboardItem':
        """
        Convert history item to named snippet.
        Based on Flycut's clipHasName pattern.

        Args:
            name: Name for the snippet
            folder: Folder path to store snippet
            tags: Optional list of tags

        Returns:
            Self (for chaining)
        """
        self.has_name = True
        self.snippet_name = name
        self.folder_path = folder
        self.tags = tags or []
        self.item_type = "snippet"
        return self

    def update_display_length(self, new_length: int):
        """Update display length and regenerate display string."""
        self.display_length = new_length
        self.display_string = self._create_display_string()

    def matches_search(self, query: str) -> bool:
        """Check if item matches search query."""
        query_lower = query.lower()

        # Search in content
        if query_lower in self.content.lower():
            return True

        # Search in snippet name if exists
        if self.snippet_name and query_lower in self.snippet_name.lower():
            return True

        # Search in tags
        if any(query_lower in tag.lower() for tag in self.tags):
            return True

        return False

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "content": self.content,
            "timestamp": self.timestamp.isoformat(),
            "clip_id": self.clip_id,
            "content_type": self.content_type,
            "display_length": self.display_length,
            "display_string": self.display_string,
            "source_app": self.source_app,
            "item_type": self.item_type,
            "has_name": self.has_name,
            "snippet_name": self.snippet_name,
            "folder_path": self.folder_path,
            "tags": self.tags
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ClipboardItem':
        """Create ClipboardItem from dictionary."""
        item = cls(
            content=data["content"],
            timestamp=datetime.fromisoformat(data["timestamp"]),
            source_app=data.get("source_app"),
            item_type=data.get("item_type", "history"),
            content_type=data.get("content_type"),
            display_length=data.get("display_length", 50),
            clip_id=data.get("clip_id")
        )

        # Restore snippet properties
        item.has_name = data.get("has_name", False)
        item.snippet_name = data.get("snippet_name")
        item.folder_path = data.get("folder_path")
        item.tags = data.get("tags", [])

        return item

    def __str__(self) -> str:
        if self.snippet_name:
            return self.snippet_name
        return self.display_string

    def __repr__(self) -> str:
        if self.has_name:
            return f"ClipboardItem(snippet='{self.snippet_name}', folder='{self.folder_path}')"
        return f"ClipboardItem(display='{self.display_string[:30]}...', type='{self.content_type}')"

    def __eq__(self, other) -> bool:
        """Check equality based on content."""
        if not isinstance(other, ClipboardItem):
            return False
        return self.content == other.content