"""API endpoints for SimpleCP REST API."""
from fastapi import APIRouter, HTTPException
from typing import List, Optional
from api.models import (ClipboardItemResponse, HistoryFolderResponse, CreateSnippetRequest,
    UpdateSnippetRequest, MoveSnippetRequest, CreateFolderRequest, RenameFolderRequest,
    CopyRequest, SearchResponse, StatsResponse, SnippetFolderResponse, SuccessResponse,
    StatusResponse, ExportData, ImportRequest, SearchRequest, clipboard_item_to_response)


def create_router(clipboard_manager):
    router = APIRouter()

    @router.get("/api/history", response_model=List[ClipboardItemResponse])
    async def get_history(limit: Optional[int] = None):
        return [clipboard_item_to_response(item) for item in clipboard_manager.get_all_history(limit)]

    @router.get("/api/history/recent", response_model=List[ClipboardItemResponse])
    async def get_recent_history():
        return [clipboard_item_to_response(item) for item in clipboard_manager.get_recent_history()]

    @router.get("/api/history/folders", response_model=List[HistoryFolderResponse])
    async def get_history_folders():
        return [HistoryFolderResponse(
            name=f["name"], start_index=f["start_index"], end_index=f["end_index"],
            count=f["count"], items=[clipboard_item_to_response(i) for i in f["items"]]
        ) for f in clipboard_manager.get_history_folders()]

    @router.delete("/api/history/{clip_id}", response_model=SuccessResponse)
    async def delete_history_item(clip_id: str):
        success = clipboard_manager.delete_history_item(clip_id)
        if not success:
            raise HTTPException(status_code=404, detail="Item not found")
        return SuccessResponse(success=True, message="Item deleted")

    @router.delete("/api/history", response_model=SuccessResponse)
    async def clear_history():
        clipboard_manager.clear_history()
        return SuccessResponse(success=True, message="History cleared")

    @router.get("/api/snippets", response_model=List[SnippetFolderResponse])
    async def get_all_snippets():
        return [SnippetFolderResponse(folder_name=name, snippets=[clipboard_item_to_response(i) for i in items])
                for name, items in clipboard_manager.get_all_snippets().items()]

    @router.get("/api/snippets/folders", response_model=List[str])
    async def get_snippet_folders():
        return clipboard_manager.get_snippet_folders()

    @router.get("/api/snippets/{folder_name}", response_model=List[ClipboardItemResponse])
    async def get_folder_snippets(folder_name: str):
        return [clipboard_item_to_response(item) for item in clipboard_manager.get_folder_snippets(folder_name)]

    @router.post("/api/snippets", response_model=ClipboardItemResponse)
    async def create_snippet(request: CreateSnippetRequest):
        if request.clip_id:
            if not request.clip_id.strip():
                raise HTTPException(status_code=400, detail="clip_id cannot be empty")
            snippet = clipboard_manager.save_as_snippet(request.clip_id, request.name, request.folder, request.tags)
            if not snippet:
                raise HTTPException(status_code=404, detail="History item not found")
        elif request.content:
            if not request.content.strip():
                raise HTTPException(status_code=400, detail="content cannot be empty")
            try:
                snippet = clipboard_manager.add_snippet_direct(request.content, request.name, request.folder, request.tags)
            except ValueError as e:
                raise HTTPException(status_code=400, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail="Either clip_id or content required")
        return clipboard_item_to_response(snippet)

    @router.put("/api/snippets/{folder_name}/{clip_id}", response_model=SuccessResponse)
    async def update_snippet(folder_name: str, clip_id: str, request: UpdateSnippetRequest):
        success = clipboard_manager.update_snippet(folder_name, clip_id, request.content, request.name, request.tags)
        if not success:
            raise HTTPException(status_code=404, detail="Snippet not found")
        return SuccessResponse(success=True, message="Snippet updated")

    @router.delete("/api/snippets/{folder_name}/{clip_id}", response_model=SuccessResponse)
    async def delete_snippet(folder_name: str, clip_id: str):
        success = clipboard_manager.delete_snippet(folder_name, clip_id)
        if not success:
            raise HTTPException(status_code=404, detail="Snippet not found")
        return SuccessResponse(success=True, message="Snippet deleted")

    @router.post("/api/snippets/{folder_name}/{clip_id}/move", response_model=SuccessResponse)
    async def move_snippet(folder_name: str, clip_id: str, request: MoveSnippetRequest):
        success = clipboard_manager.move_snippet(folder_name, request.to_folder, clip_id)
        if not success:
            raise HTTPException(status_code=404, detail="Snippet not found")
        return SuccessResponse(success=True, message="Snippet moved")

    @router.get("/api/folders", response_model=List[str])
    async def get_folders():
        return clipboard_manager.get_snippet_folders()

    @router.post("/api/folders", response_model=SuccessResponse)
    async def create_folder(request: CreateFolderRequest):
        success = clipboard_manager.create_snippet_folder(request.folder_name)
        if not success:
            raise HTTPException(status_code=409, detail="Folder already exists")
        return SuccessResponse(success=True, message="Folder created")

    @router.put("/api/folders/{folder_name}", response_model=SuccessResponse)
    async def rename_folder(folder_name: str, request: RenameFolderRequest):
        result = clipboard_manager.rename_snippet_folder(folder_name, request.new_name)
        if not result["success"]:
            code, msg = result.get("error", "UNKNOWN"), result.get("message", "Unknown error")
            status = {"SOURCE_NOT_FOUND": 404, "TARGET_EXISTS": 409}.get(code, 400 if code in ["SOURCE_EMPTY", "TARGET_EMPTY", "SAME_NAME"] else 500)
            raise HTTPException(status_code=status, detail=msg)
        return SuccessResponse(success=True, message=result.get("message", "Folder renamed"))

    @router.delete("/api/folders/{folder_name}", response_model=SuccessResponse)
    async def delete_folder(folder_name: str):
        success = clipboard_manager.delete_snippet_folder(folder_name)
        if not success:
            raise HTTPException(status_code=404, detail="Folder not found")
        return SuccessResponse(success=True, message="Folder deleted")

    @router.post("/api/clipboard/copy", response_model=SuccessResponse)
    async def copy_to_clipboard(request: CopyRequest):
        success = clipboard_manager.copy_to_clipboard(request.clip_id)
        if not success:
            raise HTTPException(status_code=404, detail="Item not found")
        return SuccessResponse(success=True, message="Copied to clipboard")

    @router.get("/api/search", response_model=SearchResponse)
    async def search(q: str):
        results = clipboard_manager.search_all(q)
        return SearchResponse(history=[clipboard_item_to_response(i) for i in results["history"]],
                              snippets=[clipboard_item_to_response(i) for i in results["snippets"]])

    @router.get("/api/stats", response_model=StatsResponse)
    async def get_stats():
        return StatsResponse(**clipboard_manager.get_stats())

    @router.get("/api/status", response_model=StatusResponse)
    async def get_status():
        return StatusResponse(**clipboard_manager.get_status())

    @router.get("/api/export", response_model=ExportData)
    async def export_snippets():
        return ExportData(**clipboard_manager.export_snippets())

    @router.post("/api/import", response_model=SuccessResponse)
    async def import_snippets(request: ImportRequest):
        success = clipboard_manager.import_snippets(request.model_dump())
        if not success:
            raise HTTPException(status_code=400, detail="Import failed")
        return SuccessResponse(success=True, message="Import successful")

    @router.post("/api/search", response_model=SearchResponse)
    async def search_post(request: SearchRequest):
        results = clipboard_manager.search_all(request.query)
        history = results["history"] if request.include_history else []
        snippets = results["snippets"] if request.include_snippets else []
        return SearchResponse(history=[clipboard_item_to_response(i) for i in history],
                              snippets=[clipboard_item_to_response(i) for i in snippets])

    @router.get("/api/health", response_model=dict)
    async def api_health():
        return {"status": "healthy", "stats": clipboard_manager.get_stats()}

    return router
