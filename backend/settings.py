"""
Centralized settings management using pydantic.

Loads configuration from:
1. Environment variables
2. .env file
3. Default values
"""

import os
from pathlib import Path
from typing import Optional
from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings with environment variable support."""

    # Application Info
    app_name: str = Field(default="SimpleCP", env="APP_NAME")
    app_version: str = Field(default="1.0.0", env="APP_VERSION")
    debug: bool = Field(default=False, env="DEBUG")
    environment: str = Field(default="development", env="ENVIRONMENT")

    # Server Configuration
    # Port 49917 derived from "SimpleCP" hash - in private port range (49152-65535)
    api_host: str = Field(default="127.0.0.1", env="API_HOST")
    api_port: int = Field(default=49917, env="API_PORT")
    api_reload: bool = Field(default=False, env="API_RELOAD")
    api_workers: int = Field(default=1, env="API_WORKERS")

    # Storage Configuration
    data_dir: Path = Field(default=Path("data"), env="DATA_DIR")
    history_file: str = Field(default="data/history.json", env="HISTORY_FILE")
    snippets_file: str = Field(default="data/snippets.json", env="SNIPPETS_FILE")

    # Clipboard Configuration
    clipboard_check_interval: float = Field(default=1.0, env="CLIPBOARD_CHECK_INTERVAL")
    max_history_size: int = Field(default=100, env="MAX_HISTORY_SIZE")
    max_content_length: int = Field(default=10000, env="MAX_CONTENT_LENGTH")

    # Logging Configuration
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    log_file: Optional[str] = Field(default="logs/simplecp.log", env="LOG_FILE")
    log_format: str = Field(
        default="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        env="LOG_FORMAT"
    )
    log_json_format: bool = Field(default=False, env="LOG_JSON_FORMAT")
    log_to_file: bool = Field(default=True, env="LOG_TO_FILE")
    log_file_path: str = Field(default="logs/simplecp.log", env="LOG_FILE_PATH")
    log_max_bytes: int = Field(default=10485760, env="LOG_MAX_BYTES")  # 10MB
    log_backup_count: int = Field(default=5, env="LOG_BACKUP_COUNT")

    # Security Configuration
    cors_origins: list = Field(
        default=["http://localhost:49917", "http://127.0.0.1:49917"],
        env="CORS_ORIGINS"
    )
    api_key: Optional[str] = Field(default=None, env="API_KEY")

    # Feature Flags
    enable_monitoring: bool = Field(default=True, env="ENABLE_MONITORING")
    enable_api: bool = Field(default=True, env="ENABLE_API")
    enable_sentry: bool = Field(default=False, env="ENABLE_SENTRY")
    enable_usage_analytics: bool = Field(default=True, env="ENABLE_USAGE_ANALYTICS")
    health_check_enabled: bool = Field(default=True, env="HEALTH_CHECK_ENABLED")
    enable_performance_tracking: bool = Field(default=True, env="ENABLE_PERFORMANCE_TRACKING")

    @property
    def is_development(self) -> bool:
        """Check if running in development environment."""
        return self.environment.lower() in ("development", "dev", "local")

    class Config:
        """Pydantic config."""
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False

    def ensure_directories(self):
        """Ensure all required directories exist."""
        self.data_dir.mkdir(parents=True, exist_ok=True)

        if self.log_file:
            log_dir = Path(self.log_file).parent
            log_dir.mkdir(parents=True, exist_ok=True)

    def get_sentry_config(self):
        """Get Sentry configuration."""
        return {
            "enabled": self.enable_sentry,
            "dsn": os.getenv("SENTRY_DSN"),
            "environment": self.environment,
            "release": self.app_version,
        }


# Global settings instance
_settings: Optional[Settings] = None


def get_settings() -> Settings:
    """Get the global settings instance."""
    global _settings
    if _settings is None:
        _settings = Settings()
        _settings.ensure_directories()
    return _settings


def reload_settings():
    """Reload settings from environment/file."""
    global _settings
    _settings = None
    return get_settings()


# Create global settings instance for direct import
settings = get_settings()
