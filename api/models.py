"""
API models for SimpleCP REST API.

Pydantic models for request/response validation.
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


class ClipboardItemResponse(BaseModel):
    """Response model for clipboard items."""
    clip_id: str
    content: str
    timestamp: str
    content_type: str
    display_string: str
    source_app: Optional[str] = None
    item_type: str
    has_name: bool = False
    snippet_name: Optional[str] = None
    folder_path: Optional[str] = None
    tags: List[str] = []

    class Config:
        from_attributes = True


class HistoryFolderResponse(BaseModel):
    """Response model for auto-generated history folders."""
    name: str
    start_index: int
    end_index: int
    count: int
    items: List[ClipboardItemResponse]


class CreateSnippetRequest(BaseModel):
    """Request to create snippet from history or directly."""
    clip_id: Optional[str] = None  # If converting from history
    content: Optional[str] = None  # If creating directly
    name: str
    folder: str
    tags: List[str] = []


class UpdateSnippetRequest(BaseModel):
    """Request to update snippet."""
    content: Optional[str] = None
    name: Optional[str] = None
    tags: Optional[List[str]] = None


class MoveSnippetRequest(BaseModel):
    """Request to move snippet to different folder."""
    to_folder: str


class CreateFolderRequest(BaseModel):
    """Request to create new folder."""
    folder_name: str


class RenameFolderRequest(BaseModel):
    """Request to rename folder."""
    new_name: str


class CopyRequest(BaseModel):
    """Request to copy item to clipboard."""
    clip_id: str


class SearchResponse(BaseModel):
    """Response for search queries."""
    history: List[ClipboardItemResponse]
    snippets: List[ClipboardItemResponse]


class StatsResponse(BaseModel):
    """Response for manager statistics."""
    history_count: int
    snippet_count: int
    folder_count: int
    max_history: int


class SnippetFolderResponse(BaseModel):
    """Response for snippet folder with items."""
    folder_name: str
    snippets: List[ClipboardItemResponse]


class ErrorResponse(BaseModel):
    """Error response model."""
    error: str
    detail: Optional[str] = None


class SuccessResponse(BaseModel):
    """Generic success response."""
    success: bool
    message: Optional[str] = None


def clipboard_item_to_response(item: Any) -> ClipboardItemResponse:
    """Convert ClipboardItem to response model."""
    return ClipboardItemResponse(
        clip_id=item.clip_id,
        content=item.content,
        timestamp=item.timestamp.isoformat(),
        content_type=item.content_type,
        display_string=item.display_string,
        source_app=item.source_app,
        item_type=item.item_type,
        has_name=item.has_name,
        snippet_name=item.snippet_name,
        folder_path=item.folder_path,
        tags=item.tags
    )
