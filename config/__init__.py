"""
Configuration management for SimpleCP.

Provides centralized configuration loading from environment variables,
config files, and defaults.
"""

from config.settings import Settings, get_settings

__all__ = ['Settings', 'get_settings']
