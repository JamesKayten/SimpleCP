"""
ClipboardItem data model for SimpleCP.

Represents individual clipboard items with metadata.
Adapted from Flycut's FlycutClipping architecture.
"""

from datetime import datetime
from typing import Optional, Dict, Any, List
import uuid
import re


class ClipboardItem:
    """
    Represents a single clipboard item with rich metadata.

    Inspired by Flycut's FlycutClipping with enhancements:
    - Display properties (display_length, display_string)
    - Snippet properties (has_name, snippet_name, folder_path, tags)
    - Content analysis (content_type detection)
    - Source tracking (source_app)
    - Unique identification (clip_id)

    Attributes:
        content: The text content of the clipboard item
        content_type: Type of content (text, url, email, code, etc.)
        timestamp: When the item was created/copied
        clip_id: Unique identifier for this clip

        # Display properties (from Flycut)
        display_length: Maximum length for display (configurable)
        display_string: Processed string for menu/UI display

        # Snippet properties (from Flycut's clipHasName)
        has_name: Whether this is a named snippet
        snippet_name: Name given to snippet (if has_name=True)
        folder_path: Folder location for snippet organization
        tags: List of tags for organization

        # Source tracking (from Flycut)
        source_app: Application that created this clipboard entry
    """

    def __init__(
        self,
        content: str,
        content_type: Optional[str] = None,
        timestamp: Optional[datetime] = None,
        clip_id: Optional[str] = None,
        display_length: int = 50,
        has_name: bool = False,
        snippet_name: Optional[str] = None,
        folder_path: Optional[str] = None,
        tags: Optional[List[str]] = None,
        source_app: Optional[str] = None
    ):
        # Core content
        self.content = content
        self.content_type = content_type or self._detect_content_type(content)
        self.timestamp = timestamp or datetime.now()
        self.clip_id = clip_id or self._generate_id()

        # Display properties (Flycut pattern)
        self.display_length = display_length
        self.display_string = self._create_display_string()

        # Snippet properties (Flycut's clipHasName pattern)
        self.has_name = has_name
        self.snippet_name = snippet_name
        self.folder_path = folder_path
        self.tags = tags or []

        # Source tracking (Flycut pattern)
        self.source_app = source_app or self._detect_source_app()

    def _generate_id(self) -> str:
        """Generate unique identifier for this clip."""
        return str(uuid.uuid4())

    def _detect_content_type(self, text: str) -> str:
        """
        Auto-detect content type from text content.
        Helps with smart organization and naming suggestions.
        """
        text_lower = text.lower().strip()

        # URL detection
        if re.match(r'https?://', text_lower):
            return "url"

        # Email detection
        if re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', text_lower):
            return "email"

        # Code detection (common patterns)
        code_indicators = [
            'def ', 'function ', 'class ', 'import ', 'const ', 'let ', 'var ',
            'public ', 'private ', '#!/', '<?php', '<?xml'
        ]
        if any(indicator in text_lower for indicator in code_indicators):
            return "code"

        # Phone number detection
        if re.match(r'^\+?[\d\s\-\(\)]{10,}$', text.strip()):
            return "phone"

        # Default to text
        return "text"

    def _detect_source_app(self) -> Optional[str]:
        """
        Detect source application (Flycut's appLocalizedName pattern).
        Currently returns None - requires platform-specific implementation.
        On macOS, this could use NSWorkspace to get the frontmost app.
        """
        # TODO: Implement platform-specific source app detection
        # On macOS: Use AppKit/NSWorkspace to get frontmost application
        return None

    def _create_display_string(self) -> str:
        """
        Create display string for menu/UI (Flycut's clipDisplayString pattern).
        Cleans whitespace and truncates to display_length.
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
        Convert history item to named snippet (Flycut's clipHasName pattern).

        Args:
            name: Name for the snippet
            folder: Folder path for organization
            tags: Optional list of tags

        Returns:
            Self for method chaining
        """
        self.has_name = True
        self.snippet_name = name
        self.folder_path = folder
        if tags:
            self.tags = tags
        return self

    def update_display_length(self, new_length: int) -> None:
        """
        Update display length and regenerate display string.
        Useful when user changes display preferences.
        """
        self.display_length = new_length
        self.display_string = self._create_display_string()

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "content": self.content,
            "content_type": self.content_type,
            "timestamp": self.timestamp.isoformat(),
            "clip_id": self.clip_id,
            "display_length": self.display_length,
            "display_string": self.display_string,
            "has_name": self.has_name,
            "snippet_name": self.snippet_name,
            "folder_path": self.folder_path,
            "tags": self.tags,
            "source_app": self.source_app
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ClipboardItem':
        """Create ClipboardItem from dictionary."""
        item = cls(
            content=data["content"],
            content_type=data.get("content_type"),
            timestamp=datetime.fromisoformat(data["timestamp"]),
            clip_id=data.get("clip_id"),
            display_length=data.get("display_length", 50),
            has_name=data.get("has_name", False),
            snippet_name=data.get("snippet_name"),
            folder_path=data.get("folder_path"),
            tags=data.get("tags", []),
            source_app=data.get("source_app")
        )
        return item

    def __str__(self) -> str:
        """String representation using display string."""
        return self.display_string

    def __repr__(self) -> str:
        """Developer-friendly representation."""
        name_info = f", name='{self.snippet_name}'" if self.has_name else ""
        return f"ClipboardItem(type='{self.content_type}'{name_info}, id='{self.clip_id[:8]}...')"

    def __eq__(self, other) -> bool:
        """Compare based on content for duplicate detection."""
        if not isinstance(other, ClipboardItem):
            return False
        return self.content == other.content

    def __hash__(self) -> int:
        """Hash based on clip_id for use in sets/dicts."""
        return hash(self.clip_id)