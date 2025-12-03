"""
Version management for SimpleCP.

Centralized version information and update checking.
"""
from datetime import datetime
from typing import Optional
import requests


__version__ = "1.0.0"
__version_info__ = (1, 0, 0)


# Release information
RELEASE_DATE = "2025-01-15"
RELEASE_NAME = "Initial Production Release"
RELEASE_NOTES_URL = "https://github.com/JamesKayten/SimpleCP/releases/tag/v1.0.0"

# Update checking
UPDATE_CHECK_URL = "https://api.github.com/repos/JamesKayten/SimpleCP/releases/latest"
UPDATE_CHECK_INTERVAL = 86400  # 24 hours in seconds


def get_version() -> str:
    """Get current version string."""
    return __version__


def get_version_info() -> tuple:
    """Get version as tuple (major, minor, patch)."""
    return __version_info__


def get_release_info() -> dict:
    """Get release information."""
    return {
        "version": __version__,
        "release_date": RELEASE_DATE,
        "release_name": RELEASE_NAME,
        "release_notes_url": RELEASE_NOTES_URL,
    }


def check_for_updates(timeout: int = 5) -> Optional[dict]:
    """
    Check for available updates from GitHub releases.

    Args:
        timeout: Request timeout in seconds

    Returns:
        Dictionary with update info if available, None otherwise
        {
            "available": bool,
            "latest_version": str,
            "current_version": str,
            "download_url": str,
            "release_notes": str
        }
    """
    try:
        response = requests.get(UPDATE_CHECK_URL, timeout=timeout)
        response.raise_for_status()

        data = response.json()
        latest_version = data["tag_name"].lstrip("v")

        # Compare versions
        current = __version_info__
        latest = tuple(map(int, latest_version.split(".")))

        update_available = latest > current

        return {
            "available": update_available,
            "latest_version": latest_version,
            "current_version": __version__,
            "download_url": data.get("html_url", ""),
            "release_notes": data.get("body", ""),
            "published_at": data.get("published_at", ""),
        }
    except Exception:
        # Don't fail if update check fails
        return None


def format_version_info() -> str:
    """Format version information for display."""
    return f"""
SimpleCP Version {__version__}
Released: {RELEASE_DATE}
Release: {RELEASE_NAME}

For release notes, visit:
{RELEASE_NOTES_URL}
"""


if __name__ == "__main__":
    # Display version information
    print(format_version_info())

    # Check for updates
    print("Checking for updates...")
    update_info = check_for_updates()

    if update_info:
        if update_info["available"]:
            print(f"\n🎉 Update available: v{update_info['latest_version']}")
            print(f"Download: {update_info['download_url']}")
        else:
            print("\n✅ You're running the latest version!")
    else:
        print("\n⚠️  Could not check for updates")
