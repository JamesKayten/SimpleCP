"""
Configuration management for SimpleCP.

Provides a centralized configuration system with:
- JSON-based config files
- Environment variable overrides
- Type-safe configuration access
- Default values
"""

import json
import os
from pathlib import Path
from typing import Optional
from dataclasses import dataclass, asdict


@dataclass
class ServerConfig:
    """Server configuration."""

    host: str = "127.0.0.1"
    port: int = 49917  # Port derived from "SimpleCP" hash (private port range 49152-65535)
    cors_origins: list = None

    def __post_init__(self):
        if self.cors_origins is None:
            self.cors_origins = ["*"]


@dataclass
class ClipboardConfig:
    """Clipboard management configuration."""

    max_history: int = 50
    display_count: int = 10
    display_length: int = 50
    check_interval: int = 1
    auto_save: bool = True


@dataclass
class LoggingConfig:
    """Logging configuration."""

    level: str = "INFO"
    log_dir: str = "logs"
    max_file_size: int = 10485760  # 10MB
    backup_count: int = 5
    enable_console: bool = True


@dataclass
class KeyboardConfig:
    """Keyboard shortcuts configuration."""

    enabled: bool = True
    toggle_panel: str = "cmd+alt+v"
    quick_paste_prefix: str = "cmd+alt"


@dataclass
class SimpleCPConfig:
    """Main SimpleCP configuration."""

    server: ServerConfig
    clipboard: ClipboardConfig
    logging: LoggingConfig
    keyboard: KeyboardConfig
    data_dir: str = "data"

    @classmethod
    def default(cls) -> "SimpleCPConfig":
        """Create default configuration."""
        return cls(
            server=ServerConfig(),
            clipboard=ClipboardConfig(),
            logging=LoggingConfig(),
            keyboard=KeyboardConfig(),
        )

    @classmethod
    def from_file(cls, config_path: str) -> "SimpleCPConfig":
        """Load configuration from JSON file."""
        try:
            with open(config_path, "r") as f:
                data = json.load(f)

            return cls(
                server=ServerConfig(**data.get("server", {})),
                clipboard=ClipboardConfig(**data.get("clipboard", {})),
                logging=LoggingConfig(**data.get("logging", {})),
                keyboard=KeyboardConfig(**data.get("keyboard", {})),
                data_dir=data.get("data_dir", "data"),
            )
        except FileNotFoundError:
            print(f"Config file not found: {config_path}, using defaults")
            return cls.default()
        except Exception as e:
            print(f"Error loading config: {e}, using defaults")
            return cls.default()

    def to_file(self, config_path: str):
        """Save configuration to JSON file."""
        data = {
            "server": asdict(self.server),
            "clipboard": asdict(self.clipboard),
            "logging": asdict(self.logging),
            "keyboard": asdict(self.keyboard),
            "data_dir": self.data_dir,
        }

        Path(config_path).parent.mkdir(parents=True, exist_ok=True)
        with open(config_path, "w") as f:
            json.dump(data, f, indent=2)

    def apply_env_overrides(self):
        """Apply environment variable overrides."""
        # Server overrides
        if "SIMPLECP_HOST" in os.environ:
            self.server.host = os.environ["SIMPLECP_HOST"]
        if "SIMPLECP_PORT" in os.environ:
            self.server.port = int(os.environ["SIMPLECP_PORT"])

        # Clipboard overrides
        if "SIMPLECP_MAX_HISTORY" in os.environ:
            self.clipboard.max_history = int(os.environ["SIMPLECP_MAX_HISTORY"])

        # Logging overrides
        if "SIMPLECP_LOG_LEVEL" in os.environ:
            self.logging.level = os.environ["SIMPLECP_LOG_LEVEL"]

        # Data directory override
        if "SIMPLECP_DATA_DIR" in os.environ:
            self.data_dir = os.environ["SIMPLECP_DATA_DIR"]


# Global config instance
_global_config: Optional[SimpleCPConfig] = None


def get_config() -> SimpleCPConfig:
    """Get global configuration instance."""
    global _global_config
    if _global_config is None:
        _global_config = load_config()
    return _global_config


def load_config(config_path: Optional[str] = None) -> SimpleCPConfig:
    """
    Load configuration from file with environment overrides.

    Args:
        config_path: Path to config file (default: config.json in root)

    Returns:
        SimpleCPConfig instance
    """
    if config_path is None:
        config_path = os.path.join(os.path.dirname(__file__), "config.json")

    config = SimpleCPConfig.from_file(config_path)
    config.apply_env_overrides()
    return config


def save_default_config(config_path: Optional[str] = None):
    """Save default configuration to file."""
    if config_path is None:
        config_path = os.path.join(os.path.dirname(__file__), "config.json")

    config = SimpleCPConfig.default()
    config.to_file(config_path)
    print(f"Default configuration saved to: {config_path}")
