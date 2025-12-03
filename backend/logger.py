"""
Structured logging configuration for SimpleCP.

Provides consistent logging across the application with support for:
- File rotation
- JSON formatting for production
- Different log levels
- Contextual information
"""
import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Optional

from pythonjsonlogger import jsonlogger

from settings import settings


class ContextFilter(logging.Filter):
    """Add contextual information to log records."""

    def __init__(self, app_name: str, version: str):
        super().__init__()
        self.app_name = app_name
        self.version = version

    def filter(self, record):
        record.app_name = self.app_name
        record.app_version = self.version
        return True


def setup_logging(name: Optional[str] = None) -> logging.Logger:
    """
    Set up logging with file rotation and optional JSON formatting.

    Args:
        name: Logger name (defaults to 'simplecp')

    Returns:
        Configured logger instance
    """
    logger_name = name or "simplecp"
    logger = logging.getLogger(logger_name)

    # Avoid duplicate handlers
    if logger.handlers:
        return logger

    logger.setLevel(getattr(logging, settings.log_level.upper()))

    # Console handler (always enabled)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.DEBUG)

    if settings.log_json_format:
        # JSON format for production
        json_formatter = jsonlogger.JsonFormatter(
            "%(timestamp)s %(level)s %(name)s %(message)s %(pathname)s %(lineno)d",
            rename_fields={
                "levelname": "level",
                "asctime": "timestamp",
            },
        )
        console_handler.setFormatter(json_formatter)
    else:
        # Human-readable format for development
        console_formatter = logging.Formatter(
            "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        console_handler.setFormatter(console_formatter)

    logger.addHandler(console_handler)

    # File handler with rotation (if enabled)
    if settings.log_to_file:
        log_path = Path(settings.log_file_path)
        log_path.parent.mkdir(parents=True, exist_ok=True)

        file_handler = RotatingFileHandler(
            filename=str(log_path),
            maxBytes=settings.log_max_bytes,
            backupCount=settings.log_backup_count,
            encoding="utf-8",
        )
        file_handler.setLevel(logging.DEBUG)

        if settings.log_json_format:
            file_handler.setFormatter(json_formatter)
        else:
            file_formatter = logging.Formatter(
                "%(asctime)s [%(levelname)s] %(name)s (%(filename)s:%(lineno)d): %(message)s",
                datefmt="%Y-%m-%d %H:%M:%S",
            )
            file_handler.setFormatter(file_formatter)

        logger.addHandler(file_handler)

    # Add context filter
    context_filter = ContextFilter(settings.app_name, settings.app_version)
    logger.addFilter(context_filter)

    # Prevent propagation to root logger
    logger.propagate = False

    return logger


# Global logger instance
logger = setup_logging()


# Convenience functions for common operations
def log_api_request(method: str, path: str, status_code: int, duration_ms: float):
    """Log API request with structured data."""
    logger.info(
        "API Request",
        extra={
            "http_method": method,
            "http_path": path,
            "http_status": status_code,
            "duration_ms": duration_ms,
            "event_type": "api_request",
        },
    )


def log_clipboard_event(event_type: str, item_id: Optional[str] = None, **kwargs):
    """Log clipboard event with structured data."""
    logger.info(
        f"Clipboard Event: {event_type}",
        extra={
            "event_type": "clipboard_event",
            "clipboard_event_type": event_type,
            "item_id": item_id,
            **kwargs,
        },
    )


def log_error(error: Exception, context: Optional[dict] = None):
    """Log error with context and stack trace."""
    logger.error(
        f"Error: {str(error)}",
        exc_info=True,
        extra={
            "event_type": "error",
            "error_type": type(error).__name__,
            "error_message": str(error),
            **(context or {}),
        },
    )


def log_performance(operation: str, duration_ms: float, **kwargs):
    """Log performance metrics."""
    logger.info(
        f"Performance: {operation}",
        extra={
            "event_type": "performance",
            "operation": operation,
            "duration_ms": duration_ms,
            **kwargs,
        },
    )
