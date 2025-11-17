"""
Settings Store for SimpleCP
Manages application settings, preferences, and configuration
"""

import json
from pathlib import Path
from typing import Dict, Any, List, Optional
from datetime import datetime


class SettingsStore:
    """
    Manages all application settings and preferences
    """

    DEFAULT_SETTINGS = {
        # History Settings
        "history": {
            "max_items": 50,
            "max_text_items": 100,
            "max_image_items": 20,
            "max_url_items": 50,
            "display_count": 10,
        },

        # Auto-cleanup Settings
        "cleanup": {
            "enabled": False,
            "delete_after_days": 30,
            "keep_favorites": True,
            "auto_cleanup_time": "03:00",  # 3 AM
        },

        # Privacy Settings
        "privacy": {
            "enabled": True,
            "excluded_apps": [
                "1Password",
                "LastPass",
                "Bitwarden",
                "KeePassXC",
                "Terminal",
                "iTerm"
            ],
            "filter_passwords": True,
            "filter_credit_cards": True,
            "filter_ssn": True,
            "privacy_mode": False,  # When True, don't track anything
            "encrypt_storage": False,
        },

        # Keyboard Shortcuts
        "shortcuts": {
            "global_toggle": "cmd+shift+v",
            "quick_copy": "cmd+shift+c",
            "clear_history": "cmd+shift+x",
            "search": "cmd+f",
            "enabled": True,
        },

        # Search Settings
        "search": {
            "fuzzy_enabled": True,
            "fuzzy_threshold": 0.6,
            "regex_enabled": True,
            "case_sensitive": False,
            "search_content": True,
            "search_names": True,
            "search_tags": True,
        },

        # Display Settings
        "display": {
            "show_timestamps": True,
            "show_source_app": True,
            "preview_length": 50,
            "date_format": "%Y-%m-%d %H:%M:%S",
            "theme": "auto",  # auto, light, dark
        },

        # Menu Bar Settings
        "menubar": {
            "enabled": True,
            "show_icon": True,
            "show_count": True,
            "icon_style": "clipboard",  # clipboard, number, custom
            "click_action": "show_window",  # show_window, show_menu
        },

        # Startup Settings
        "startup": {
            "launch_at_login": False,
            "start_minimized": False,
            "check_for_updates": True,
        },

        # Backend Settings
        "backend": {
            "host": "127.0.0.1",
            "port": 8000,
            "clipboard_interval": 1.0,  # seconds
            "auto_save": True,
        },

        # Analytics Settings
        "analytics": {
            "enabled": True,
            "track_usage": True,
            "track_source_apps": True,
            "retention_days": 90,
        },

        # Export Settings
        "export": {
            "default_format": "json",  # json, csv, txt
            "include_metadata": True,
            "pretty_json": True,
        }
    }

    def __init__(self, data_dir: str = "./data"):
        """
        Initialize settings store

        Args:
            data_dir: Directory for data storage
        """
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.settings_file = self.data_dir / "settings.json"

        # Load or create settings
        self.settings = self._load_settings()

    def _load_settings(self) -> Dict[str, Any]:
        """Load settings from file or create defaults"""
        if self.settings_file.exists():
            try:
                with open(self.settings_file, 'r') as f:
                    loaded = json.load(f)
                    # Merge with defaults to ensure all keys exist
                    return self._merge_settings(self.DEFAULT_SETTINGS.copy(), loaded)
            except Exception as e:
                print(f"Error loading settings: {e}")
                return self.DEFAULT_SETTINGS.copy()
        else:
            # Create default settings file
            settings = self.DEFAULT_SETTINGS.copy()
            self._save_settings(settings)
            return settings

    def _merge_settings(self, defaults: Dict, loaded: Dict) -> Dict:
        """Recursively merge loaded settings with defaults"""
        for key, value in loaded.items():
            if key in defaults:
                if isinstance(value, dict) and isinstance(defaults[key], dict):
                    defaults[key] = self._merge_settings(defaults[key], value)
                else:
                    defaults[key] = value
        return defaults

    def _save_settings(self, settings: Optional[Dict] = None):
        """Save settings to file"""
        if settings is None:
            settings = self.settings

        try:
            with open(self.settings_file, 'w') as f:
                json.dump(settings, f, indent=2)
        except Exception as e:
            print(f"Error saving settings: {e}")

    def get(self, key_path: str, default: Any = None) -> Any:
        """
        Get setting value by dot-notation path

        Args:
            key_path: Dot-separated path (e.g., "history.max_items")
            default: Default value if not found

        Returns:
            Setting value or default
        """
        keys = key_path.split('.')
        value = self.settings

        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default

        return value

    def set(self, key_path: str, value: Any, save: bool = True):
        """
        Set setting value by dot-notation path

        Args:
            key_path: Dot-separated path (e.g., "history.max_items")
            value: Value to set
            save: Whether to save immediately
        """
        keys = key_path.split('.')
        settings = self.settings

        # Navigate to parent
        for key in keys[:-1]:
            if key not in settings:
                settings[key] = {}
            settings = settings[key]

        # Set value
        settings[keys[-1]] = value

        if save:
            self._save_settings()

    def get_section(self, section: str) -> Dict[str, Any]:
        """Get entire settings section"""
        return self.settings.get(section, {})

    def update_section(self, section: str, updates: Dict[str, Any], save: bool = True):
        """
        Update multiple settings in a section

        Args:
            section: Section name (e.g., "history")
            updates: Dictionary of updates
            save: Whether to save immediately
        """
        if section not in self.settings:
            self.settings[section] = {}

        self.settings[section].update(updates)

        if save:
            self._save_settings()

    def reset_section(self, section: str, save: bool = True):
        """Reset section to defaults"""
        if section in self.DEFAULT_SETTINGS:
            self.settings[section] = self.DEFAULT_SETTINGS[section].copy()

            if save:
                self._save_settings()

    def reset_all(self, save: bool = True):
        """Reset all settings to defaults"""
        self.settings = self.DEFAULT_SETTINGS.copy()

        if save:
            self._save_settings()

    def export_settings(self) -> Dict[str, Any]:
        """Export all settings"""
        return self.settings.copy()

    def import_settings(self, settings: Dict[str, Any], merge: bool = True, save: bool = True):
        """
        Import settings from dictionary

        Args:
            settings: Settings dictionary
            merge: If True, merge with existing; if False, replace
            save: Whether to save immediately
        """
        if merge:
            self.settings = self._merge_settings(self.settings.copy(), settings)
        else:
            # Ensure all required keys exist
            self.settings = self._merge_settings(self.DEFAULT_SETTINGS.copy(), settings)

        if save:
            self._save_settings()

    def get_excluded_apps(self) -> List[str]:
        """Get list of excluded applications"""
        return self.get("privacy.excluded_apps", [])

    def add_excluded_app(self, app_name: str, save: bool = True):
        """Add application to exclusion list"""
        excluded = self.get_excluded_apps()
        if app_name not in excluded:
            excluded.append(app_name)
            self.set("privacy.excluded_apps", excluded, save=save)

    def remove_excluded_app(self, app_name: str, save: bool = True):
        """Remove application from exclusion list"""
        excluded = self.get_excluded_apps()
        if app_name in excluded:
            excluded.remove(app_name)
            self.set("privacy.excluded_apps", excluded, save=save)

    def is_app_excluded(self, app_name: str) -> bool:
        """Check if application is excluded"""
        return app_name in self.get_excluded_apps()

    def is_privacy_mode_enabled(self) -> bool:
        """Check if privacy mode is enabled"""
        return self.get("privacy.privacy_mode", False)

    def should_filter_content(self) -> bool:
        """Check if content filtering is enabled"""
        return self.get("privacy.enabled", True)

    def get_max_history_items(self, content_type: Optional[str] = None) -> int:
        """
        Get maximum history items for content type

        Args:
            content_type: Type of content (text, image, url) or None for general

        Returns:
            Maximum items allowed
        """
        if content_type:
            key = f"history.max_{content_type}_items"
            return self.get(key, self.get("history.max_items", 50))
        else:
            return self.get("history.max_items", 50)

    def get_cleanup_settings(self) -> Dict[str, Any]:
        """Get auto-cleanup settings"""
        return self.get_section("cleanup")

    def should_auto_cleanup(self) -> bool:
        """Check if auto-cleanup is enabled"""
        return self.get("cleanup.enabled", False)

    def get_keyboard_shortcuts(self) -> Dict[str, str]:
        """Get all keyboard shortcuts"""
        return self.get_section("shortcuts")

    def get_shortcut(self, action: str) -> Optional[str]:
        """Get keyboard shortcut for action"""
        return self.get(f"shortcuts.{action}")

    def set_shortcut(self, action: str, shortcut: str, save: bool = True):
        """Set keyboard shortcut for action"""
        self.set(f"shortcuts.{action}", shortcut, save=save)

    def validate_settings(self) -> List[str]:
        """
        Validate current settings

        Returns:
            List of validation errors (empty if valid)
        """
        errors = []

        # Validate numeric ranges
        max_items = self.get("history.max_items")
        if max_items < 1 or max_items > 1000:
            errors.append("history.max_items must be between 1 and 1000")

        # Validate cleanup days
        cleanup_days = self.get("cleanup.delete_after_days")
        if cleanup_days < 1:
            errors.append("cleanup.delete_after_days must be at least 1")

        # Validate fuzzy threshold
        fuzzy_threshold = self.get("search.fuzzy_threshold")
        if fuzzy_threshold < 0 or fuzzy_threshold > 1:
            errors.append("search.fuzzy_threshold must be between 0 and 1")

        # Validate port
        port = self.get("backend.port")
        if port < 1024 or port > 65535:
            errors.append("backend.port must be between 1024 and 65535")

        return errors
