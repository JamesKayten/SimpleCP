"""Snippet-related API routes."""

from fastapi import APIRouter, HTTPException
from typing import List
from api.models import (
    ClipboardItemResponse,
    CreateSnippetRequest,
    UpdateSnippetRequest,
    MoveSnippetRequest,
    SnippetFolderResponse,
    SuccessResponse,
    clipboard_item_to_response,
)


def create_snippet_router(clipboard_manager):
    """Create snippet routes with clipboard manager dependency."""
    router = APIRouter()

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

    @router.get("/api/snippets/{folder_name}", response_model=List[ClipboardItemResponse])
    async def get_folder_snippets(folder_name: str):
        """Get all snippets in a specific folder."""
        items = clipboard_manager.get_folder_snippets(folder_name)
        return [clipboard_item_to_response(item) for item in items]

    @router.post("/api/snippets", response_model=ClipboardItemResponse)
    async def create_snippet(request: CreateSnippetRequest):
        """Create snippet from history or directly."""
        if request.clip_id:
            snippet = clipboard_manager.save_as_snippet(
                request.clip_id, request.name, request.folder, request.tags
            )
            if not snippet:
                raise HTTPException(status_code=404, detail="History item not found")
        elif request.content:
            snippet = clipboard_manager.add_snippet_direct(
                request.content, request.name, request.folder, request.tags
            )
        else:
            raise HTTPException(status_code=400, detail="Either clip_id or content required")
        return clipboard_item_to_response(snippet)

    @router.put("/api/snippets/{folder_name}/{clip_id}", response_model=SuccessResponse)
    async def update_snippet(folder_name: str, clip_id: str, request: UpdateSnippetRequest):
        """Update snippet properties."""
        success = clipboard_manager.update_snippet(
            folder_name, clip_id, request.content, request.name, request.tags
        )
        if not success:
            raise HTTPException(status_code=404, detail="Snippet not found")
        return SuccessResponse(success=True, message="Snippet updated")

    @router.delete("/api/snippets/{folder_name}/{clip_id}", response_model=SuccessResponse)
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
        success = clipboard_manager.move_snippet(folder_name, request.to_folder, clip_id)
        if not success:
            raise HTTPException(status_code=404, detail="Snippet not found")
        return SuccessResponse(success=True, message="Snippet moved")

    return router
