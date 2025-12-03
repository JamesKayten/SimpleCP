"""
API package for SimpleCP.

Contains REST API implementation:
- models: Pydantic models for request/response validation
- endpoints: API route handlers
- server: FastAPI application setup
"""

from api.models import (
    ClipboardItemResponse,
    HistoryFolderResponse,
    CreateSnippetRequest,
    UpdateSnippetRequest,
    MoveSnippetRequest,
    CreateFolderRequest,
    RenameFolderRequest,
    CopyRequest,
    SearchResponse,
    StatsResponse,
    SnippetFolderResponse,
    ErrorResponse,
    SuccessResponse
)

__all__ = [
    'ClipboardItemResponse',
    'HistoryFolderResponse',
    'CreateSnippetRequest',
    'UpdateSnippetRequest',
    'MoveSnippetRequest',
    'CreateFolderRequest',
    'RenameFolderRequest',
    'CopyRequest',
    'SearchResponse',
    'StatsResponse',
    'SnippetFolderResponse',
    'ErrorResponse',
    'SuccessResponse'
]
