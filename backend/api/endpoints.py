"""
API endpoints for SimpleCP REST API.

FastAPI route definitions for clipboard manager operations.
"""

from fastapi import APIRouter, HTTPException
from typing import List, Optional
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
    SuccessResponse,
    StatusResponse,
    ExportData,
    ImportRequest,
    SearchRequest,
    clipboard_item_to_response,
)


def create_router(clipboard_manager):
    """Create API router with clipboard manager dependency."""
    router = APIRouter()

    # History endpoints
    @router.get("/api/history", response_model=List[ClipboardItemResponse])
    async def get_history(limit: Optional[int] = None):
        """Get clipboard history."""
        items = clipboard_manager.get_all_history(limit)
        return [clipboard_item_to_response(item) for item in items]

    @router.get("/api/history/recent", response_model=List[ClipboardItemResponse])
    async def get_recent_history():
        """Get recent clipboard items for direct display."""
        items = clipboard_manager.get_recent_history()
        return [clipboard_item_to_response(item) for item in items]

    @router.get("/api/history/folders", response_model=List[HistoryFolderResponse])
    async def get_history_folders():
        """Get auto-generated history folder ranges."""
        folders = clipboard_manager.get_history_folders()
        result = []
        for folder in folders:
            result.append(
                HistoryFolderResponse(
                    name=folder["name"],
                    start_index=folder["start_index"],
                    end_index=folder["end_index"],
                    count=folder["count"],
                    items=[
                        clipboard_item_to_response(item) for item in folder["items"]
                    ],
                )
            )
        return result

    @router.delete("/api/history/{clip_id}", response_model=SuccessResponse)
    async def delete_history_item(clip_id: str):
        """Delete specific history item."""
        success = clipboard_manager.delete_history_item(clip_id)
        if not success:
            raise HTTPException(status_code=404, detail="Item not found")
        return SuccessResponse(success=True, message="Item deleted")

    @router.delete("/api/history", response_model=SuccessResponse)
    async def clear_history():
        """Clear all clipboard history."""
        clipboard_manager.clear_history()
        return SuccessResponse(success=True, message="History cleared")

    # Snippet endpoints
    @router.get("/api/snippets", response_model=List[SnippetFolderResponse])
    async def get_all_snippets():
        """Get all snippets organized by folder."""
        snippets_by_folder = clipboard_manager.get_all_snippets()
        result = []
        for folder_name, items in snippets_by_folder.items():
            result.append(
                SnippetFolderResponse(
                    folder_name=folder_name,
                    snippets=[clipboard_item_to_response(item) for item in items],
                )
            )
        return result

    @router.get("/api/snippets/folders", response_model=List[str])
    async def get_snippet_folders():
        """Get all snippet folder names."""
        return clipboard_manager.get_snippet_folders()

    @router.get(
        "/api/snippets/{folder_name}",
        response_model=List[ClipboardItemResponse],
    )
    async def get_folder_snippets(folder_name: str):
        """Get all snippets in a specific folder."""
        items = clipboard_manager.get_folder_snippets(folder_name)
        return [clipboard_item_to_response(item) for item in items]

    @router.post("/api/snippets", response_model=ClipboardItemResponse)
    async def create_snippet(request: CreateSnippetRequest):
        """Create snippet from history or directly."""
        if request.clip_id:
            # Convert from history
            snippet = clipboard_manager.save_as_snippet(
                request.clip_id, request.name, request.folder, request.tags
            )
            if not snippet:
                raise HTTPException(status_code=404, detail="History item not found")
        elif request.content:
            # Create directly
            snippet = clipboard_manager.add_snippet_direct(
                request.content, request.name, request.folder, request.tags
            )
        else:
            raise HTTPException(
                status_code=400, detail="Either clip_id or content required"
            )
        return clipboard_item_to_response(snippet)

    @router.put("/api/snippets/{folder_name}/{clip_id}", response_model=SuccessResponse)
    async def update_snippet(
        folder_name: str, clip_id: str, request: UpdateSnippetRequest
    ):
        """Update snippet properties."""
        success = clipboard_manager.update_snippet(
            folder_name, clip_id, request.content, request.name, request.tags
        )
        if not success:
            raise HTTPException(status_code=404, detail="Snippet not found")
        return SuccessResponse(success=True, message="Snippet updated")

    @router.delete(
        "/api/snippets/{folder_name}/{clip_id}", response_model=SuccessResponse
    )
    async def delete_snippet(folder_name: str, clip_id: str):
        """Delete specific snippet."""
        success = clipboard_manager.delete_snippet(folder_name, clip_id)
        if not success:
            raise HTTPException(status_code=404, detail="Snippet not found")
        return SuccessResponse(success=True, message="Snippet deleted")

    @router.post(
        "/api/snippets/{folder_name}/{clip_id}/move",
        response_model=SuccessResponse,
    )
    async def move_snippet(folder_name: str, clip_id: str, request: MoveSnippetRequest):
        """Move snippet to different folder."""
        success = clipboard_manager.move_snippet(
            folder_name, request.to_folder, clip_id
        )
        if not success:
            raise HTTPException(status_code=404, detail="Snippet not found")
        return SuccessResponse(success=True, message="Snippet moved")

    # Folder endpoints
    @router.get("/api/folders", response_model=List[str])
    async def get_folders():
        """Get list of all snippet folders."""
        folders = clipboard_manager.get_snippet_folders()
        return folders

    @router.post("/api/folders", response_model=SuccessResponse)
    async def create_folder(request: CreateFolderRequest):
        """Create new snippet folder."""
        success = clipboard_manager.create_snippet_folder(request.folder_name)
        if not success:
            raise HTTPException(status_code=409, detail="Folder already exists")
        return SuccessResponse(success=True, message="Folder created")

    @router.put("/api/folders/{folder_name}", response_model=SuccessResponse)
    async def rename_folder(folder_name: str, request: RenameFolderRequest):
        """Rename snippet folder with detailed error handling."""
        result = clipboard_manager.rename_snippet_folder(folder_name, request.new_name)

        if not result["success"]:
            error_code = result.get("error", "UNKNOWN_ERROR")
            error_message = result.get("message", "Unknown error occurred")

            # Map specific errors to appropriate HTTP status codes
            if error_code == "SOURCE_NOT_FOUND":
                raise HTTPException(status_code=404, detail=error_message)
            elif error_code == "TARGET_EXISTS":
                raise HTTPException(status_code=409, detail=error_message)
            elif error_code in ["SOURCE_EMPTY", "TARGET_EMPTY", "SAME_NAME"]:
                raise HTTPException(status_code=400, detail=error_message)
            else:
                # Generic server error for unexpected failures
                raise HTTPException(status_code=500, detail=error_message)

        return SuccessResponse(
            success=True,
            message=result.get("message", "Folder renamed successfully")
        )

    @router.delete("/api/folders/{folder_name}", response_model=SuccessResponse)
    async def delete_folder(folder_name: str):
        """Delete snippet folder and all its snippets."""
        success = clipboard_manager.delete_snippet_folder(folder_name)
        if not success:
            raise HTTPException(status_code=404, detail="Folder not found")
        return SuccessResponse(success=True, message="Folder deleted")

    # Clipboard operations
    @router.post("/api/clipboard/copy", response_model=SuccessResponse)
    async def copy_to_clipboard(request: CopyRequest):
        """Copy item to system clipboard by ID."""
        success = clipboard_manager.copy_to_clipboard(request.clip_id)
        if not success:
            raise HTTPException(status_code=404, detail="Item not found")
        return SuccessResponse(success=True, message="Copied to clipboard")

    # Search endpoint
    @router.get("/api/search", response_model=SearchResponse)
    async def search(q: str):
        """Search across history and snippets."""
        results = clipboard_manager.search_all(q)
        return SearchResponse(
            history=[clipboard_item_to_response(item) for item in results["history"]],
            snippets=[clipboard_item_to_response(item) for item in results["snippets"]],
        )

    # Stats endpoint
    @router.get("/api/stats", response_model=StatsResponse)
    async def get_stats():
        """Get manager statistics."""
        stats = clipboard_manager.get_stats()
        return StatsResponse(**stats)

    # Status endpoint
    @router.get("/api/status", response_model=StatusResponse)
    async def get_status():
        """Get monitoring status."""
        status = clipboard_manager.get_status()
        return StatusResponse(**status)

    # Export endpoint
    @router.get("/api/export", response_model=ExportData)
    async def export_snippets():
        """Export all snippets."""
        export_data = clipboard_manager.export_snippets()
        return ExportData(**export_data)

    # Import endpoint
    @router.post("/api/import", response_model=SuccessResponse)
    async def import_snippets(request: ImportRequest):
        """Import snippets from export data."""
        success = clipboard_manager.import_snippets(request.model_dump())
        if not success:
            raise HTTPException(status_code=400, detail="Import failed")
        return SuccessResponse(success=True, message="Import successful")

    # POST search endpoint
    @router.post("/api/search", response_model=SearchResponse)
    async def search_post(request: SearchRequest):
        """Search across history and snippets (POST)."""
        results = clipboard_manager.search_all(request.query)
        history = results["history"] if request.include_history else []
        snippets = results["snippets"] if request.include_snippets else []
        return SearchResponse(
            history=[clipboard_item_to_response(item) for item in history],
            snippets=[clipboard_item_to_response(item) for item in snippets],
        )

    # Health endpoint for API route consistency
    @router.get("/api/health", response_model=dict)
    async def api_health():
        """Health check endpoint under /api/ path."""
        stats = clipboard_manager.get_stats()
        return {"status": "healthy", "stats": stats}

    return router
