"""
Pydantic models for SimpleCP REST API.

Defines request and response models for all API endpoints.
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


# ========== History Models ==========

class HistoryItemResponse(BaseModel):
    """Response model for a history item."""
    content: str
    timestamp: str
    preview: str
    source_app: Optional[str] = None
    item_type: str = "history"
    index: int  # Position in history (0 = most recent)


class HistoryResponse(BaseModel):
    """Response model for history list."""
    items: List[HistoryItemResponse]
    total: int


class HistoryFolderResponse(BaseModel):
    """Response model for a history folder."""
    name: str
    start: int
    end: int
    count: int


class CopyRequest(BaseModel):
    """Request model for copying item to clipboard."""
    index: int = Field(..., description="Index of item to copy (0 = most recent)")


# ========== Snippet Models ==========

class SnippetResponse(BaseModel):
    """Response model for a snippet."""
    id: str
    name: str
    content: str
    folder: str
    created_at: str


class SnippetCreateRequest(BaseModel):
    """Request model for creating a new snippet."""
    name: str = Field(..., min_length=1)
    content: str = Field(..., min_length=1)
    folder: str = Field(..., min_length=1)


class SnippetUpdateRequest(BaseModel):
    """Request model for updating a snippet."""
    name: Optional[str] = None
    content: Optional[str] = None
    folder: Optional[str] = None


class FolderResponse(BaseModel):
    """Response model for a folder."""
    name: str
    snippet_count: int


class FolderCreateRequest(BaseModel):
    """Request model for creating a new folder."""
    name: str = Field(..., min_length=1)


# ========== Search Models ==========

class SearchResultItem(BaseModel):
    """Single search result item."""
    type: str  # "history" or "snippet"
    content: str
    preview: str

    # History-specific fields
    timestamp: Optional[str] = None
    index: Optional[int] = None

    # Snippet-specific fields
    id: Optional[str] = None
    name: Optional[str] = None
    folder: Optional[str] = None


class SearchResponse(BaseModel):
    """Response model for search results."""
    query: str
    results: List[SearchResultItem]
    total: int


# ========== Settings Models ==========

class SettingsResponse(BaseModel):
    """Response model for app settings."""
    max_history_items: int
    clipboard_check_interval: float
    show_timestamps: bool
    menu_item_length: int
    api_port: int


class SettingsUpdateRequest(BaseModel):
    """Request model for updating settings."""
    max_history_items: Optional[int] = None
    clipboard_check_interval: Optional[float] = None
    show_timestamps: Optional[bool] = None
    menu_item_length: Optional[int] = None


# ========== Status Models ==========

class StatusResponse(BaseModel):
    """Response model for backend status."""
    status: str
    version: str
    uptime_seconds: float
    clipboard_monitoring: bool
    history_count: int
    snippet_count: int
    folders_count: int


# ========== Error Models ==========

class ErrorResponse(BaseModel):
    """Error response model."""
    error: str
    detail: Optional[str] = None
