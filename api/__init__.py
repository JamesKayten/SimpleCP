"""
API package for SimpleCP.

Contains REST API implementation:
- models: Pydantic models for request/response validation
- endpoints: API route handlers
- server: FastAPI application setup
"""

from api.models import (
    ClipboardItemResponse,
    SnippetCreate,
    SnippetUpdate,
    FolderCreate,
    FolderRename,
    MoveSnippetRequest,
    HistoryResponse,
    SnippetsResponse,
    SearchResponse,
    StatsResponse,
    HealthResponse
)

__all__ = [
    'ClipboardItemResponse',
    'SnippetCreate',
    'SnippetUpdate',
    'FolderCreate',
    'FolderRename',
    'MoveSnippetRequest',
    'HistoryResponse',
    'SnippetsResponse',
    'SearchResponse',
    'StatsResponse',
    'HealthResponse'
]
