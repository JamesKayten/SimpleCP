"""Folder management API routes."""

from fastapi import APIRouter, HTTPException
from api.models import (
    CreateFolderRequest,
    RenameFolderRequest,
    SuccessResponse,
)


def create_folder_router(clipboard_manager):
    """Create folder routes with clipboard manager dependency."""
    router = APIRouter()

    @router.post("/api/folders", response_model=SuccessResponse)
    async def create_folder(request: CreateFolderRequest):
        """Create new snippet folder."""
        success = clipboard_manager.create_snippet_folder(request.folder_name)
        if not success:
            raise HTTPException(status_code=409, detail="Folder already exists")
        return SuccessResponse(success=True, message="Folder created")

    @router.put("/api/folders/{folder_name}", response_model=SuccessResponse)
    async def rename_folder(folder_name: str, request: RenameFolderRequest):
        """Rename snippet folder."""
        success = clipboard_manager.rename_snippet_folder(folder_name, request.new_name)
        if not success:
            raise HTTPException(status_code=404, detail="Folder not found or new name exists")
        return SuccessResponse(success=True, message="Folder renamed")

    @router.delete("/api/folders/{folder_name}", response_model=SuccessResponse)
    async def delete_folder(folder_name: str):
        """Delete snippet folder and all its snippets."""
        success = clipboard_manager.delete_snippet_folder(folder_name)
        if not success:
            raise HTTPException(status_code=404, detail="Folder not found")
        return SuccessResponse(success=True, message="Folder deleted")

    return router
