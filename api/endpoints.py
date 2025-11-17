"""
API endpoints for SimpleCP REST API.

FastAPI route definitions for clipboard manager operations.
"""

from fastapi import APIRouter, HTTPException
from typing import List, Optional
from api.models import (
    ClipboardItemResponse, HistoryFolderResponse, CreateSnippetRequest,
    UpdateSnippetRequest, MoveSnippetRequest, CreateFolderRequest,
    RenameFolderRequest, CopyRequest, SearchResponse, StatsResponse,
    SnippetFolderResponse, ErrorResponse, SuccessResponse,
    clipboard_item_to_response
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
            result.append(HistoryFolderResponse(
                name=folder["name"],
                start_index=folder["start_index"],
                end_index=folder["end_index"],
                count=folder["count"],
                items=[clipboard_item_to_response(item) for item in folder["items"]]
            ))
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
            result.append(SnippetFolderResponse(
                folder_name=folder_name,
                snippets=[clipboard_item_to_response(item) for item in items]
            ))
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

    @router.post("/api/snippets/{folder_name}/{clip_id}/move", response_model=SuccessResponse)
    async def move_snippet(folder_name: str, clip_id: str, request: MoveSnippetRequest):
        """Move snippet to different folder."""
        success = clipboard_manager.move_snippet(folder_name, request.to_folder, clip_id)
        if not success:
            raise HTTPException(status_code=404, detail="Snippet not found")
        return SuccessResponse(success=True, message="Snippet moved")

    # Folder endpoints
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
            snippets=[clipboard_item_to_response(item) for item in results["snippets"]]
        )

    # Stats endpoint
    @router.get("/api/stats", response_model=StatsResponse)
    async def get_stats():
        """Get manager statistics."""
        stats = clipboard_manager.get_stats()
        return StatsResponse(**stats)

    # Advanced Search endpoints
    @router.get("/api/search/advanced", response_model=SearchResponse)
    async def advanced_search(
        q: Optional[str] = None,
        search_type: str = "fuzzy",
        content_types: Optional[str] = None,
        source_apps: Optional[str] = None,
        tags: Optional[str] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        sort_by: Optional[str] = None,
        reverse: bool = False
    ):
        """Advanced search with filters."""
        from datetime import datetime

        # Parse comma-separated lists
        types_list = content_types.split(',') if content_types else None
        apps_list = source_apps.split(',') if source_apps else None
        tags_list = tags.split(',') if tags else None

        # Parse dates
        start = datetime.fromisoformat(start_date) if start_date else None
        end = datetime.fromisoformat(end_date) if end_date else None

        results = clipboard_manager.advanced_search(
            query=q,
            search_type=search_type,
            content_types=types_list,
            source_apps=apps_list,
            tags=tags_list,
            start_date=start,
            end_date=end,
            sort_by=sort_by,
            reverse=reverse
        )

        return SearchResponse(
            history=[clipboard_item_to_response(item) for item in results["history"]],
            snippets=[clipboard_item_to_response(item) for item in results["snippets"]]
        )

    # Settings endpoints
    @router.get("/api/settings")
    async def get_all_settings():
        """Get all settings."""
        return clipboard_manager.settings.export_settings()

    @router.get("/api/settings/{section}")
    async def get_settings_section(section: str):
        """Get specific settings section."""
        settings = clipboard_manager.settings.get_section(section)
        if not settings:
            raise HTTPException(status_code=404, detail="Section not found")
        return settings

    @router.put("/api/settings/{section}")
    async def update_settings_section(section: str, updates: dict):
        """Update settings section."""
        clipboard_manager.settings.update_section(section, updates)
        return SuccessResponse(success=True, message="Settings updated")

    @router.post("/api/settings/import")
    async def import_settings(settings: dict, merge: bool = True):
        """Import settings."""
        clipboard_manager.settings.import_settings(settings, merge=merge)
        return SuccessResponse(success=True, message="Settings imported")

    @router.post("/api/settings/reset/{section}")
    async def reset_settings_section(section: str):
        """Reset settings section to defaults."""
        clipboard_manager.settings.reset_section(section)
        return SuccessResponse(success=True, message="Settings reset")

    # Analytics endpoints
    @router.get("/api/analytics/summary")
    async def get_analytics_summary(period: str = "week"):
        """Get analytics summary for period (day/week/month/all)."""
        return clipboard_manager.get_analytics_summary(period)

    @router.get("/api/analytics/most-copied")
    async def get_most_copied(limit: int = 10):
        """Get most copied items."""
        return clipboard_manager.get_most_copied(limit)

    @router.get("/api/analytics/apps")
    async def get_app_statistics():
        """Get statistics by source application."""
        return clipboard_manager.analytics.get_app_statistics()

    @router.get("/api/analytics/types")
    async def get_type_statistics():
        """Get statistics by content type."""
        return clipboard_manager.analytics.get_type_statistics()

    @router.get("/api/analytics/daily")
    async def get_daily_statistics(days: int = 30):
        """Get daily statistics."""
        return clipboard_manager.analytics.get_daily_statistics(days)

    @router.get("/api/analytics/hourly")
    async def get_hourly_distribution():
        """Get hourly usage distribution."""
        return clipboard_manager.analytics.get_hourly_distribution()

    @router.get("/api/analytics/insights")
    async def get_insights():
        """Get analytics insights."""
        return clipboard_manager.analytics.get_insights()

    @router.post("/api/analytics/cleanup")
    async def cleanup_analytics(retention_days: int = 90):
        """Cleanup old analytics data."""
        clipboard_manager.analytics.cleanup_old_data(retention_days)
        return SuccessResponse(success=True, message="Analytics cleaned up")

    # Import/Export endpoints
    @router.get("/api/export/history")
    async def export_history(format: str = "json", limit: Optional[int] = None):
        """Export clipboard history."""
        from fastapi.responses import Response

        if format not in ["json", "csv", "txt"]:
            raise HTTPException(status_code=400, detail="Invalid format")

        data = clipboard_manager.import_export.export_history(format=format, limit=limit)

        media_types = {
            "json": "application/json",
            "csv": "text/csv",
            "txt": "text/plain"
        }

        return Response(content=data, media_type=media_types[format])

    @router.get("/api/export/snippets")
    async def export_snippets(format: str = "json", folder: Optional[str] = None):
        """Export snippets."""
        from fastapi.responses import Response

        if format not in ["json", "csv", "txt"]:
            raise HTTPException(status_code=400, detail="Invalid format")

        data = clipboard_manager.import_export.export_snippets(format=format, folder=folder)

        media_types = {
            "json": "application/json",
            "csv": "text/csv",
            "txt": "text/plain"
        }

        return Response(content=data, media_type=media_types[format])

    @router.post("/api/export/selected")
    async def export_selected(clip_ids: List[str], format: str = "json"):
        """Export selected items."""
        from fastapi.responses import Response

        if format not in ["json", "csv", "txt"]:
            raise HTTPException(status_code=400, detail="Invalid format")

        data = clipboard_manager.import_export.export_selected(clip_ids, format=format)

        media_types = {
            "json": "application/json",
            "csv": "text/csv",
            "txt": "text/plain"
        }

        return Response(content=data, media_type=media_types[format])

    @router.post("/api/backup/create")
    async def create_backup():
        """Create full backup."""
        import tempfile
        import os
        from datetime import datetime

        # Create backup in temp directory
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = os.path.join(tempfile.gettempdir(), f"simplecp_backup_{timestamp}.zip")

        filepath = clipboard_manager.import_export.create_backup(backup_file)

        return {
            "success": True,
            "backup_file": filepath,
            "message": "Backup created"
        }

    @router.post("/api/backup/restore")
    async def restore_backup(filepath: str):
        """Restore from backup."""
        import os

        if not os.path.exists(filepath):
            raise HTTPException(status_code=404, detail="Backup file not found")

        result = clipboard_manager.import_export.restore_backup(filepath)
        return result

    @router.post("/api/import/json")
    async def import_from_json(filepath: str, merge: bool = True):
        """Import from JSON file."""
        import os

        if not os.path.exists(filepath):
            raise HTTPException(status_code=404, detail="File not found")

        result = clipboard_manager.import_export.import_from_json(filepath, merge=merge)
        return result

    @router.post("/api/import/csv")
    async def import_from_csv(filepath: str, merge: bool = True):
        """Import from CSV file."""
        import os

        if not os.path.exists(filepath):
            raise HTTPException(status_code=404, detail="File not found")

        result = clipboard_manager.import_export.import_from_csv(filepath, merge=merge)
        return result

    # Bulk operations
    @router.post("/api/bulk/delete")
    async def bulk_delete(clip_ids: List[str]):
        """Delete multiple items."""
        deleted_count = 0

        for clip_id in clip_ids:
            # Try to delete from history
            if clipboard_manager.delete_history_item(clip_id):
                deleted_count += 1
                continue

            # Try to delete from snippets
            for folder_name in clipboard_manager.get_snippet_folders():
                if clipboard_manager.delete_snippet(folder_name, clip_id):
                    deleted_count += 1
                    break

        return {
            "success": True,
            "deleted_count": deleted_count,
            "total_requested": len(clip_ids)
        }

    @router.post("/api/bulk/copy")
    async def bulk_copy_to_folder(clip_ids: List[str], folder: str):
        """Copy multiple history items to snippets folder."""
        copied_count = 0

        for clip_id in clip_ids:
            # Find item in history
            for item in clipboard_manager.history_store.items:
                if item.clip_id == clip_id:
                    # Create snippet name from content preview
                    name = item.display_string
                    clipboard_manager.save_as_snippet(clip_id, name, folder)
                    copied_count += 1
                    break

        return {
            "success": True,
            "copied_count": copied_count,
            "total_requested": len(clip_ids),
            "folder": folder
        }

    # Pagination support
    @router.get("/api/history/paginated", response_model=dict)
    async def get_history_paginated(
        page: int = 1,
        page_size: int = 20,
        sort_by: Optional[str] = None,
        reverse: bool = False
    ):
        """Get paginated clipboard history."""
        items = clipboard_manager.get_all_history()

        # Sort if requested
        if sort_by:
            items = clipboard_manager.search.sort_items(items, sort_by, reverse)

        # Calculate pagination
        total_items = len(items)
        total_pages = (total_items + page_size - 1) // page_size
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size

        paginated_items = items[start_idx:end_idx]

        return {
            "items": [clipboard_item_to_response(item) for item in paginated_items],
            "pagination": {
                "page": page,
                "page_size": page_size,
                "total_items": total_items,
                "total_pages": total_pages,
                "has_next": page < total_pages,
                "has_previous": page > 1
            }
        }

    @router.get("/api/snippets/paginated", response_model=dict)
    async def get_snippets_paginated(
        folder: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
        sort_by: Optional[str] = None,
        reverse: bool = False
    ):
        """Get paginated snippets."""
        if folder:
            items = clipboard_manager.get_folder_snippets(folder)
        else:
            items = []
            for folder_items in clipboard_manager.snippet_store.folders.values():
                items.extend(folder_items)

        # Sort if requested
        if sort_by:
            items = clipboard_manager.search.sort_items(items, sort_by, reverse)

        # Calculate pagination
        total_items = len(items)
        total_pages = (total_items + page_size - 1) // page_size
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size

        paginated_items = items[start_idx:end_idx]

        return {
            "items": [clipboard_item_to_response(item) for item in paginated_items],
            "pagination": {
                "page": page,
                "page_size": page_size,
                "total_items": total_items,
                "total_pages": total_pages,
                "has_next": page < total_pages,
                "has_previous": page > 1
            }
        }

    # Privacy endpoints
    @router.get("/api/privacy/excluded-apps")
    async def get_excluded_apps():
        """Get list of excluded applications."""
        return clipboard_manager.settings.get_excluded_apps()

    @router.post("/api/privacy/exclude-app")
    async def add_excluded_app(app_name: str):
        """Add application to exclusion list."""
        clipboard_manager.settings.add_excluded_app(app_name)
        return SuccessResponse(success=True, message="App added to exclusion list")

    @router.delete("/api/privacy/exclude-app")
    async def remove_excluded_app(app_name: str):
        """Remove application from exclusion list."""
        clipboard_manager.settings.remove_excluded_app(app_name)
        return SuccessResponse(success=True, message="App removed from exclusion list")

    @router.post("/api/privacy/mode")
    async def toggle_privacy_mode(enabled: bool):
        """Toggle privacy mode."""
        clipboard_manager.settings.set("privacy.privacy_mode", enabled)
        return SuccessResponse(
            success=True,
            message=f"Privacy mode {'enabled' if enabled else 'disabled'}"
        )

    @router.get("/api/privacy/validate")
    async def validate_content(content: str):
        """Validate content for sensitive data."""
        return clipboard_manager.privacy.validate_content_safety(content)

    return router
