"""
FastAPI server for SimpleCP REST API.

Main server configuration and startup.
"""
import time
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

from clipboard_manager import ClipboardManager
from api.endpoints import create_router
from settings import settings
from logger import logger
from monitoring import (
    initialize_sentry,
    track_api_request,
    capture_exception,
    get_monitoring_stats,
)


def create_app(clipboard_manager: ClipboardManager = None) -> FastAPI:
    """
    Create FastAPI application instance.

    Args:
        clipboard_manager: ClipboardManager instance (creates new if None)

    Returns:
        Configured FastAPI app
    """
    # Initialize Sentry for crash reporting
    initialize_sentry()

    app = FastAPI(
        title="SimpleCP API",
        description="REST API for SimpleCP clipboard manager",
        version=settings.app_version,
    )

    # Request tracking middleware
    @app.middleware("http")
    async def track_requests(request: Request, call_next):
        """Track API requests and performance."""
        start_time = time.time()

        try:
            response = await call_next(request)
            duration_ms = (time.time() - start_time) * 1000

            # Track request metrics
            track_api_request(
                method=request.method,
                path=request.url.path,
                status_code=response.status_code,
                duration_ms=duration_ms,
            )

            # Add performance headers
            response.headers["X-Process-Time"] = f"{duration_ms:.2f}ms"

            return response
        except Exception as e:
            duration_ms = (time.time() - start_time) * 1000
            logger.error(
                f"Request failed: {request.method} {request.url.path}",
                exc_info=True,
                extra={
                    "method": request.method,
                    "path": str(request.url.path),
                    "duration_ms": duration_ms,
                },
            )
            capture_exception(
                e,
                context={
                    "request": {
                        "method": request.method,
                        "path": str(request.url.path),
                        "headers": dict(request.headers),
                    }
                },
            )
            raise

    # Global exception handler
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        """Handle uncaught exceptions."""
        logger.error(
            f"Unhandled exception: {str(exc)}",
            exc_info=True,
            extra={
                "method": request.method,
                "path": str(request.url.path),
            },
        )
        capture_exception(
            exc,
            context={
                "request": {
                    "method": request.method,
                    "path": str(request.url.path),
                }
            },
        )
        return JSONResponse(
            status_code=500,
            content={
                "error": "Internal server error",
                "detail": str(exc) if settings.is_development else "An error occurred",
            },
        )

    # CORS middleware for Swift frontend
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
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
            "name": settings.app_name,
            "version": settings.app_version,
            "status": "running",
            "environment": settings.environment,
        }

    @app.get("/health")
    async def health():
        """Health check endpoint with detailed metrics."""
        if not settings.health_check_enabled:
            return {"status": "disabled"}

        stats = clipboard_manager.get_stats()
        monitoring_stats = get_monitoring_stats()

        return {
            "status": "healthy",
            "version": settings.app_version,
            "environment": settings.environment,
            "clipboard_stats": stats,
            "monitoring": monitoring_stats,
        }

    @app.on_event("startup")
    async def startup_event():
        """Log startup event."""
        logger.info(
            f"SimpleCP API starting up (version: {settings.app_version}, "
            f"environment: {settings.environment})"
        )

    @app.on_event("shutdown")
    async def shutdown_event():
        """Log shutdown event."""
        logger.info("SimpleCP API shutting down")

    return app


def run_server(
    host: str = None,
    port: int = None,
    clipboard_manager: ClipboardManager = None,
):
    """
    Run the FastAPI server.

    Args:
        host: Server host (defaults to settings.api_host)
        port: Server port (defaults to settings.api_port)
        clipboard_manager: ClipboardManager instance
    """
    app = create_app(clipboard_manager)

    # Use settings if not specified
    host = host or settings.api_host
    port = port or settings.api_port

    logger.info(f"Starting FastAPI server on {host}:{port}")

    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level=settings.log_level.lower(),
        reload=settings.api_reload,
    )


if __name__ == "__main__":
    # Run server with settings
    run_server()
