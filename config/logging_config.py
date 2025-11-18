"""
Logging configuration for SimpleCP.

Provides structured logging with file and console handlers.
"""

import logging
import logging.handlers
from pathlib import Path
from typing import Optional
from config.settings import get_settings


def setup_logging(
    name: str = "simplecp",
    log_file: Optional[str] = None,
    log_level: Optional[str] = None
) -> logging.Logger:
    """
    Configure and return a logger with file and console handlers.

    Args:
        name: Logger name
        log_file: Path to log file (uses settings if not provided)
        log_level: Log level (uses settings if not provided)

    Returns:
        Configured logger instance
    """
    settings = get_settings()

    # Use provided values or fall back to settings
    log_file = log_file or settings.log_file
    log_level = log_level or settings.log_level

    # Create logger
    logger = logging.getLogger(name)
    logger.setLevel(getattr(logging, log_level.upper()))

    # Prevent duplicate handlers
    if logger.handlers:
        return logger

    # Create formatters
    formatter = logging.Formatter(settings.log_format)

    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(getattr(logging, log_level.upper()))
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    # File handler (if log file specified)
    if log_file:
        log_path = Path(log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)

        # Rotating file handler (10MB max, 5 backups)
        file_handler = logging.handlers.RotatingFileHandler(
            log_file,
            maxBytes=10 * 1024 * 1024,  # 10MB
            backupCount=5
        )
        file_handler.setLevel(getattr(logging, log_level.upper()))
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    return logger


def get_logger(name: str = "simplecp") -> logging.Logger:
    """Get a logger instance."""
    return logging.getLogger(name)
