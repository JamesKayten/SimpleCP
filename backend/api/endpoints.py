"""
API endpoints for SimpleCP REST API.

FastAPI route definitions using modular router architecture.
"""

from fastapi import APIRouter
from api.history_routes import create_history_router
from api.snippet_routes import create_snippet_router
from api.folder_routes import create_folder_router
from api.misc_routes import create_misc_router


def create_router(clipboard_manager):
    """Create combined API router with all endpoint modules."""
    router = APIRouter()

    # Create sub-routers
    history_router = create_history_router(clipboard_manager)
    snippet_router = create_snippet_router(clipboard_manager)
    folder_router = create_folder_router(clipboard_manager)
    misc_router = create_misc_router(clipboard_manager)

    # Include all routers
    router.include_router(history_router, tags=["history"])
    router.include_router(snippet_router, tags=["snippets"])
    router.include_router(folder_router, tags=["folders"])
    router.include_router(misc_router, tags=["misc"])

    return router
