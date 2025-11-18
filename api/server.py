"""
FastAPI server for SimpleCP REST API.

Main server configuration and startup.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from clipboard_manager import ClipboardManager
from api.endpoints import create_router


def create_app(clipboard_manager: ClipboardManager = None) -> FastAPI:
    """
    Create FastAPI application instance.

    Args:
        clipboard_manager: ClipboardManager instance (creates new if None)

    Returns:
        Configured FastAPI app
    """
    app = FastAPI(
        title="SimpleCP API",
        description="REST API for SimpleCP clipboard manager",
        version="1.0.0",
    )

    # CORS middleware for Swift frontend
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Configure appropriately for production
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Create clipboard manager if not provided
    if clipboard_manager is None:
        clipboard_manager = ClipboardManager()

    # Store manager in app state
    app.state.clipboard_manager = clipboard_manager

    # Include API routes
    router = create_router(clipboard_manager)
    app.include_router(router)

    @app.get("/")
    async def root():
        """Root endpoint."""
        return {
            "name": "SimpleCP API",
            "version": "1.0.0",
            "status": "running",
        }

    @app.get("/health")
    async def health():
        """Health check endpoint."""
        stats = clipboard_manager.get_stats()
        return {"status": "healthy", "stats": stats}

    return app


def run_server(
    host: str = "127.0.0.1",
    port: int = 8000,
    clipboard_manager: ClipboardManager = None,
):
    """
    Run the FastAPI server.

    Args:
        host: Server host
        port: Server port
        clipboard_manager: ClipboardManager instance
    """
    app = create_app(clipboard_manager)

    uvicorn.run(app, host=host, port=port, log_level="info")


if __name__ == "__main__":
    # Run server with default settings
    run_server()
