"""
FastAPI server for SimpleCP REST API.

Main server configuration and startup.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import logging
from clipboard_manager import ClipboardManager
from api.endpoints import create_router
from config import get_config

logger = logging.getLogger(__name__)


def create_app(clipboard_manager: ClipboardManager = None, config=None) -> FastAPI:
    """
    Create FastAPI application instance.

    Args:
        clipboard_manager: ClipboardManager instance (creates new if None)
        config: SimpleCP_Config instance (loads default if None)

    Returns:
        Configured FastAPI app
    """
    if config is None:
        config = get_config()

    app = FastAPI(
        title="SimpleCP API",
        description="REST API for SimpleCP clipboard manager",
        version="1.0.0"
    )

    # CORS middleware with configurable origins
    app.add_middleware(
        CORSMiddleware,
        allow_origins=config.cors_origins,
        allow_credentials=config.cors_allow_credentials,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    logger.info(f"CORS configured: origins={config.cors_origins}")

    # Create clipboard manager if not provided
    if clipboard_manager is None:
        clipboard_manager = ClipboardManager(data_dir=config.data_dir)

    # Store manager and config in app state
    app.state.clipboard_manager = clipboard_manager
    app.state.config = config

    # Include API routes with /api/v1 prefix
    router = create_router(clipboard_manager)
    app.include_router(router, prefix="/api/v1")

    @app.get("/")
    async def root():
        """Root endpoint."""
        return {
            "name": "SimpleCP API",
            "version": "1.0.0",
            "status": "running",
            "api_version": "v1",
            "endpoints": {
                "api": "/api/v1",
                "docs": "/docs",
                "health": "/health",
                "config": "/config"
            }
        }

    @app.get("/health")
    async def health():
        """Health check endpoint."""
        stats = clipboard_manager.get_stats()
        return {
            "status": "healthy",
            "stats": stats
        }

    @app.get("/config")
    async def get_config_endpoint():
        """Get API configuration for client discovery."""
        return {
            "api_base_url": f"http://{config.host}:{config.port}/api/v1",
            "host": config.host,
            "port": config.port,
            "api_version": "v1",
            "endpoints": {
                "history": "/api/v1/history",
                "snippets": "/api/v1/snippets",
                "search": "/api/v1/search"
            }
        }

    return app


def run_server(
    host: str = "127.0.0.1",
    port: int = 8000,
    clipboard_manager: ClipboardManager = None,
    config=None
):
    """
    Run the FastAPI server.

    Args:
        host: Server host
        port: Server port
        clipboard_manager: ClipboardManager instance
        config: SimpleCP_Config instance
    """
    app = create_app(clipboard_manager, config)

    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info",
        access_log=True
    )


if __name__ == "__main__":
    # Run server with default settings
    run_server()
