"""
Settings management for SimpleCP.

Handles configuration, preferences, and data persistence.
Environment variables can be set in .env file or system environment.
"""
import os
from pathlib import Path
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings with environment variable support."""

    # Application Info
    app_name: str = "SimpleCP"
    app_version: str = "1.0.0"
    environment: str = "development"  # development, staging, production

    # API Server Configuration
    api_host: str = "127.0.0.1"
    api_port: int = 8000
    api_reload: bool = False  # Auto-reload for development

    # Clipboard Configuration
    clipboard_check_interval: int = 1  # seconds
    max_history_items: int = 50
    display_count: int = 10
    display_length: int = 50

    # Data Storage
    data_dir: str = "./data"

    # Monitoring & Error Tracking
    sentry_dsn: Optional[str] = None  # Set via SENTRY_DSN env var
    sentry_traces_sample_rate: float = 1.0  # 100% in dev, lower in prod
    sentry_profiles_sample_rate: float = 1.0
    sentry_environment: Optional[str] = None  # Auto-set from environment
    enable_sentry: bool = False  # Explicitly enable Sentry

    # Logging Configuration
    log_level: str = "INFO"  # DEBUG, INFO, WARNING, ERROR, CRITICAL
    log_to_file: bool = True
    log_file_path: str = "./logs/simplecp.log"
    log_max_bytes: int = 10 * 1024 * 1024  # 10MB
    log_backup_count: int = 5
    log_json_format: bool = False  # JSON logs for production

    # Performance Monitoring
    enable_performance_tracking: bool = True
    enable_usage_analytics: bool = True

    # Health Check
    health_check_enabled: bool = True

    # CORS Settings
    cors_origins: list[str] = ["*"]  # Allow all origins by default

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Auto-set Sentry environment if not specified
        if self.sentry_environment is None:
            self.sentry_environment = self.environment
        # Ensure data and log directories exist
        Path(self.data_dir).mkdir(parents=True, exist_ok=True)
        if self.log_to_file:
            Path(self.log_file_path).parent.mkdir(parents=True, exist_ok=True)

    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.environment.lower() == "production"

    @property
    def is_development(self) -> bool:
        """Check if running in development environment."""
        return self.environment.lower() == "development"

    def get_sentry_config(self) -> dict:
        """Get Sentry configuration dictionary."""
        if not self.enable_sentry or not self.sentry_dsn:
            return {}

        return {
            "dsn": self.sentry_dsn,
            "environment": self.sentry_environment,
            "traces_sample_rate": self.sentry_traces_sample_rate,
            "profiles_sample_rate": self.sentry_profiles_sample_rate,
            "send_default_pii": False,  # Don't send PII
            "attach_stacktrace": True,
            "max_breadcrumbs": 50,
        }


# Global settings instance
settings = Settings()