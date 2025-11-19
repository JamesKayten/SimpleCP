"""History-related API routes."""

from fastapi import APIRouter, HTTPException
from typing import List, Optional
from api.models import (
    ClipboardItemResponse,
    HistoryFolderResponse,
    SuccessResponse,
    clipboard_item_to_response,
)


def create_history_router(clipboard_manager):
    """Create history routes with clipboard manager dependency."""
    router = APIRouter()

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
                    items=[clipboard_item_to_response(item) for item in folder["items"]],
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

    return router
