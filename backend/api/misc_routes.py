"""Miscellaneous API routes (search, stats, import/export)."""

from fastapi import APIRouter, HTTPException
from api.models import (
    CopyRequest,
    SearchResponse,
    StatsResponse,
    StatusResponse,
    ExportData,
    ImportRequest,
    SearchRequest,
    SuccessResponse,
    clipboard_item_to_response,
)


def create_misc_router(clipboard_manager):
    """Create miscellaneous routes with clipboard manager dependency."""
    router = APIRouter()

    @router.post("/api/clipboard/copy", response_model=SuccessResponse)
    async def copy_to_clipboard(request: CopyRequest):
        """Copy item to system clipboard by ID."""
        success = clipboard_manager.copy_to_clipboard(request.clip_id)
        if not success:
            raise HTTPException(status_code=404, detail="Item not found")
        return SuccessResponse(success=True, message="Copied to clipboard")

    @router.get("/api/search", response_model=SearchResponse)
    async def search(q: str):
        """Search across history and snippets."""
        results = clipboard_manager.search_all(q)
        return SearchResponse(
            history=[clipboard_item_to_response(item) for item in results["history"]],
            snippets=[clipboard_item_to_response(item) for item in results["snippets"]],
        )

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

    @router.get("/api/stats", response_model=StatsResponse)
    async def get_stats():
        """Get manager statistics."""
        stats = clipboard_manager.get_stats()
        return StatsResponse(**stats)

    @router.get("/api/status", response_model=StatusResponse)
    async def get_status():
        """Get monitoring status."""
        status = clipboard_manager.get_status()
        return StatusResponse(**status)

    @router.get("/api/export", response_model=ExportData)
    async def export_snippets():
        """Export all snippets."""
        export_data = clipboard_manager.export_snippets()
        return ExportData(**export_data)

    @router.post("/api/import", response_model=SuccessResponse)
    async def import_snippets(request: ImportRequest):
        """Import snippets from export data."""
        success = clipboard_manager.import_snippets(request.model_dump())
        if not success:
            raise HTTPException(status_code=400, detail="Import failed")
        return SuccessResponse(success=True, message="Import successful")

    return router
