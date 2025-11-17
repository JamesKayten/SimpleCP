"""
Configuration management for SimpleCP.

Handles application configuration and logging setup.
"""

import os
import json
import logging
import logging.handlers
from pathlib import Path
from typing import Dict, Any, Optional
from dataclasses import dataclass, asdict


@dataclass
class SimpleCP_Config:
    """SimpleCP configuration."""

    # Server settings
    host: str = "127.0.0.1"
    port: int = 8000

    # Clipboard settings
    check_interval: int = 1
    max_history: int = 50
    display_count: int = 10

    # CORS settings
    cors_origins: list = None  # None means ["*"], or specify ["http://localhost:3000"]
    cors_allow_credentials: bool = True

    # Logging settings
    log_level: str = "INFO"
    log_file: Optional[str] = None  # None means logs/simplecp.log
    log_max_bytes: int = 10485760  # 10MB
    log_backup_count: int = 5

    # Data directory
    data_dir: Optional[str] = None  # None means ./data

    # Platform compatibility
    pyperclip_check_enabled: bool = True

    def __post_init__(self):
        """Set defaults for None values."""
        if self.cors_origins is None:
            self.cors_origins = ["*"]
        if self.log_file is None:
            self.log_file = "logs/simplecp.log"
        if self.data_dir is None:
            self.data_dir = "data"

    def to_dict(self) -> Dict[str, Any]:
        """Convert config to dictionary."""
        return asdict(self)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'SimpleCP_Config':
        """Create config from dictionary."""
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})


def get_config_path() -> Path:
    """Get configuration file path."""
    # Try multiple locations in order of preference
    locations = [
        Path.home() / ".simplecp" / "config.json",
        Path.cwd() / "config.json",
        Path.cwd() / ".simplecp" / "config.json",
    ]

    for path in locations:
        if path.exists():
            return path

    # Default to user home directory
    return Path.home() / ".simplecp" / "config.json"


def load_config(config_path: Optional[str] = None) -> SimpleCP_Config:
    """
    Load configuration from file.

    Args:
        config_path: Optional path to config file

    Returns:
        SimpleCP_Config instance
    """
    if config_path:
        path = Path(config_path)
    else:
        path = get_config_path()

    if path.exists():
        try:
            with open(path, 'r') as f:
                data = json.load(f)
            return SimpleCP_Config.from_dict(data)
        except Exception as e:
            logging.error(f"Error loading config from {path}: {e}")
            return SimpleCP_Config()
    else:
        return SimpleCP_Config()


def save_config(config: SimpleCP_Config, config_path: Optional[str] = None):
    """
    Save configuration to file.

    Args:
        config: SimpleCP_Config instance
        config_path: Optional path to config file
    """
    if config_path:
        path = Path(config_path)
    else:
        path = get_config_path()

    # Create directory if needed
    path.parent.mkdir(parents=True, exist_ok=True)

    try:
        with open(path, 'w') as f:
            json.dump(config.to_dict(), f, indent=2)
    except Exception as e:
        logging.error(f"Error saving config to {path}: {e}")


def setup_logging(config: SimpleCP_Config):
    """
    Setup logging based on configuration.

    Args:
        config: SimpleCP_Config instance
    """
    # Parse log level
    numeric_level = getattr(logging, config.log_level.upper(), logging.INFO)

    # Create logs directory if needed
    log_path = Path(config.log_file)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(numeric_level)

    # Remove existing handlers
    root_logger.handlers.clear()

    # Console handler with colored output support
    console_handler = logging.StreamHandler()
    console_handler.setLevel(numeric_level)
    console_formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    console_handler.setFormatter(console_formatter)
    root_logger.addHandler(console_handler)

    # File handler with rotation
    file_handler = logging.handlers.RotatingFileHandler(
        config.log_file,
        maxBytes=config.log_max_bytes,
        backupCount=config.log_backup_count
    )
    file_handler.setLevel(numeric_level)
    file_formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(filename)s:%(lineno)d - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    file_handler.setFormatter(file_formatter)
    root_logger.addHandler(file_handler)

    logging.info(f"Logging configured: level={config.log_level}, file={config.log_file}")


def check_platform_compatibility(config: SimpleCP_Config) -> Dict[str, Any]:
    """
    Check platform compatibility for clipboard operations.

    Args:
        config: SimpleCP_Config instance

    Returns:
        Dictionary with compatibility status
    """
    import sys
    import platform

    result = {
        "platform": platform.system(),
        "python_version": sys.version,
        "clipboard_available": False,
        "clipboard_backend": None,
        "warnings": [],
        "errors": []
    }

    if not config.pyperclip_check_enabled:
        result["warnings"].append("Platform compatibility check disabled")
        result["clipboard_available"] = True  # Assume available
        return result

    try:
        import pyperclip

        # Test clipboard
        try:
            test_content = "SimpleCP platform check"
            pyperclip.copy(test_content)
            retrieved = pyperclip.paste()

            if retrieved == test_content:
                result["clipboard_available"] = True
                result["clipboard_backend"] = getattr(pyperclip, '_functions', {})
            else:
                result["warnings"].append("Clipboard test failed: content mismatch")

        except Exception as e:
            result["errors"].append(f"Clipboard operation failed: {e}")

            # Check platform-specific requirements
            if platform.system() == "Linux":
                result["errors"].append(
                    "Linux requires one of: xclip, xsel, or wl-clipboard. "
                    "Install with: sudo apt-get install xclip"
                )

    except ImportError as e:
        result["errors"].append(f"pyperclip not available: {e}")

    return result


# Global config instance
_config: Optional[SimpleCP_Config] = None


def get_config() -> SimpleCP_Config:
    """Get global config instance."""
    global _config
    if _config is None:
        _config = load_config()
    return _config


def set_config(config: SimpleCP_Config):
    """Set global config instance."""
    global _config
    _config = config
