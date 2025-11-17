"""
SimpleCP REST API Server.

FastAPI-based REST API for clipboard management backend.
"""

import pyperclip
import time
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional, List
from datetime import datetime

from .models import (
    HistoryItemResponse, HistoryResponse, HistoryFolderResponse, CopyRequest,
    SnippetResponse, SnippetCreateRequest, SnippetUpdateRequest,
    FolderResponse, FolderCreateRequest,
    SearchResponse, SearchResultItem,
    SettingsResponse, SettingsUpdateRequest,
    StatusResponse, ErrorResponse
)
from stores.history_store import HistoryStore
from stores.snippet_store import SnippetStore
from stores.clipboard_item import ClipboardItem


# ========== FastAPI Application ==========

app = FastAPI(
    title="SimpleCP API",
    description="REST API for SimpleCP clipboard manager",
    version="1.0.0"
)

# Add CORS middleware for Swift frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify Swift app origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ========== Global State ==========

class AppState:
    """Global application state."""
    def __init__(self):
        self.history_store = HistoryStore(max_items=50)
        self.snippet_store = SnippetStore()
        self.start_time = time.time()
        self.clipboard_monitoring = False
        self.settings = {
            "max_history_items": 50,
            "clipboard_check_interval": 1.0,
            "show_timestamps": True,
            "menu_item_length": 50,
            "api_port": 8080
        }

state = AppState()


# ========== History Endpoints ==========

@app.get("/api/history", response_model=HistoryResponse)
async def get_history(limit: Optional[int] = Query(None, description="Limit number of items")):
    """
    Get recent clipboard history.

    Returns all history items, newest first.
    """
    items = state.history_store.get_all()

    if limit:
        items = items[:limit]

    response_items = [
        HistoryItemResponse(
            content=item.content,
            timestamp=item.timestamp.isoformat(),
            preview=item.preview,
            source_app=item.source_app,
            item_type=item.item_type,
            index=idx
        )
        for idx, item in enumerate(items)
    ]

    return HistoryResponse(
        items=response_items,
        total=len(state.history_store)
    )


@app.get("/api/history/folders", response_model=List[HistoryFolderResponse])
async def get_history_folders():
    """
    Get auto-generated history folders (1-10, 11-20, etc.).
    """
    folders = state.history_store.get_folders()
    return [
        HistoryFolderResponse(**folder)
        for folder in folders
    ]


@app.get("/api/history/{folder}", response_model=HistoryResponse)
async def get_history_folder(folder: str):
    """
    Get clips in a specific folder range (e.g., "1-10", "11-20").
    """
    items = state.history_store.get_folder_items(folder)

    if not items:
        raise HTTPException(status_code=404, detail="Folder not found or empty")

    # Get the start index for this folder
    try:
        start_idx = int(folder.split('-')[0]) - 1
    except:
        start_idx = 0

    response_items = [
        HistoryItemResponse(
            content=item.content,
            timestamp=item.timestamp.isoformat(),
            preview=item.preview,
            source_app=item.source_app,
            item_type=item.item_type,
            index=start_idx + idx
        )
        for idx, item in enumerate(items)
    ]

    return HistoryResponse(
        items=response_items,
        total=len(items)
    )


@app.post("/api/history/copy")
async def copy_to_clipboard(request: CopyRequest):
    """
    Copy a history item to the clipboard.
    """
    item = state.history_store.get_by_index(request.index)

    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    try:
        pyperclip.copy(item.content)
        return {"success": True, "message": "Copied to clipboard"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to copy: {str(e)}")


@app.delete("/api/history")
async def clear_history():
    """
    Clear all clipboard history.
    """
    state.history_store.clear()
    return {"success": True, "message": "History cleared"}


# ========== Snippet Endpoints ==========

@app.get("/api/snippets", response_model=List[FolderResponse])
async def get_snippet_folders():
    """
    Get all snippet folders with counts.
    """
    folders = state.snippet_store.get_folders()

    return [
        FolderResponse(
            name=folder,
            snippet_count=len(state.snippet_store.get_snippets(folder))
        )
        for folder in folders
    ]


@app.get("/api/snippets/{folder}", response_model=List[SnippetResponse])
async def get_snippets_in_folder(folder: str):
    """
    Get all snippets in a specific folder.
    """
    if not state.snippet_store.folder_exists(folder):
        raise HTTPException(status_code=404, detail="Folder not found")

    snippets = state.snippet_store.get_snippets(folder)

    return [
        SnippetResponse(
            id=snippet.id,
            name=snippet.name,
            content=snippet.content,
            folder=snippet.folder,
            created_at=snippet.created_at.isoformat()
        )
        for snippet in snippets
    ]


@app.post("/api/snippets", response_model=SnippetResponse)
async def create_snippet(request: SnippetCreateRequest):
    """
    Create a new snippet.
    """
    snippet = state.snippet_store.add_snippet(
        folder_name=request.folder,
        name=request.name,
        content=request.content
    )

    return SnippetResponse(
        id=snippet.id,
        name=snippet.name,
        content=snippet.content,
        folder=snippet.folder,
        created_at=snippet.created_at.isoformat()
    )


@app.put("/api/snippets/{snippet_id}", response_model=SnippetResponse)
async def update_snippet(snippet_id: str, request: SnippetUpdateRequest):
    """
    Update an existing snippet.
    """
    success = state.snippet_store.update_snippet(
        snippet_id=snippet_id,
        name=request.name,
        content=request.content,
        folder=request.folder
    )

    if not success:
        raise HTTPException(status_code=404, detail="Snippet not found")

    # Get updated snippet
    snippet = state.snippet_store.get_snippet_by_id(snippet_id)

    return SnippetResponse(
        id=snippet.id,
        name=snippet.name,
        content=snippet.content,
        folder=snippet.folder,
        created_at=snippet.created_at.isoformat()
    )


@app.delete("/api/snippets/{snippet_id}")
async def delete_snippet(snippet_id: str):
    """
    Delete a snippet.
    """
    success = state.snippet_store.delete_snippet(snippet_id)

    if not success:
        raise HTTPException(status_code=404, detail="Snippet not found")

    return {"success": True, "message": "Snippet deleted"}


@app.post("/api/folders", response_model=FolderResponse)
async def create_folder(request: FolderCreateRequest):
    """
    Create a new snippet folder.
    """
    success = state.snippet_store.create_folder(request.name)

    if not success:
        raise HTTPException(status_code=400, detail="Folder already exists")

    return FolderResponse(
        name=request.name,
        snippet_count=0
    )


# ========== Search & Utilities ==========

@app.get("/api/search", response_model=SearchResponse)
async def search(q: str = Query(..., description="Search query")):
    """
    Search both clipboard history and snippets.
    """
    results = []

    # Search history
    history_results = state.history_store.search(q)
    for idx, item in enumerate(history_results):
        # Find the actual index in full history
        all_items = state.history_store.get_all()
        actual_index = all_items.index(item) if item in all_items else idx

        results.append(SearchResultItem(
            type="history",
            content=item.content,
            preview=item.preview,
            timestamp=item.timestamp.isoformat(),
            index=actual_index
        ))

    # Search snippets
    snippet_results = state.snippet_store.search(q)
    for snippet in snippet_results:
        preview = snippet.content[:50] + "..." if len(snippet.content) > 50 else snippet.content
        results.append(SearchResultItem(
            type="snippet",
            content=snippet.content,
            preview=preview,
            id=snippet.id,
            name=snippet.name,
            folder=snippet.folder
        ))

    return SearchResponse(
        query=q,
        results=results,
        total=len(results)
    )


@app.get("/api/settings", response_model=SettingsResponse)
async def get_settings():
    """
    Get application settings.
    """
    return SettingsResponse(**state.settings)


@app.put("/api/settings", response_model=SettingsResponse)
async def update_settings(request: SettingsUpdateRequest):
    """
    Update application settings.
    """
    if request.max_history_items is not None:
        state.settings["max_history_items"] = request.max_history_items
        state.history_store.max_items = request.max_history_items

    if request.clipboard_check_interval is not None:
        state.settings["clipboard_check_interval"] = request.clipboard_check_interval

    if request.show_timestamps is not None:
        state.settings["show_timestamps"] = request.show_timestamps

    if request.menu_item_length is not None:
        state.settings["menu_item_length"] = request.menu_item_length

    return SettingsResponse(**state.settings)


@app.get("/api/status", response_model=StatusResponse)
async def get_status():
    """
    Get backend health and status information.
    """
    uptime = time.time() - state.start_time
    snippet_count = sum(len(snippets) for snippets in state.snippet_store.folders.values())

    return StatusResponse(
        status="running",
        version="1.0.0",
        uptime_seconds=uptime,
        clipboard_monitoring=state.clipboard_monitoring,
        history_count=len(state.history_store),
        snippet_count=snippet_count,
        folders_count=len(state.snippet_store.get_folders())
    )


# ========== Root Endpoint ==========

@app.get("/")
async def root():
    """
    Root endpoint - API information.
    """
    return {
        "name": "SimpleCP API",
        "version": "1.0.0",
        "description": "REST API for SimpleCP clipboard manager",
        "docs": "/docs",
        "status": "running"
    }


# ========== Helper Functions ==========

def get_app_state():
    """Get the current application state (for daemon integration)."""
    return state
