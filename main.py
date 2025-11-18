#!/usr/bin/env python3
"""
SimpleCP - Simple macOS Clipboard Manager
Entry point for the application.

Run with: python3 main.py
"""

import sys
import os

# Add the project root to Python path
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_root)

from clipboard_manager import ClipboardManager


def main():
    """Main application entry point."""
    try:
        app = ClipboardManager()
        print("🚀 Starting SimpleCP...")
        print("📋 Clipboard manager running in menu bar")
        app.run()
    except KeyboardInterrupt:
        print("\n👋 SimpleCP stopped by user")
    except Exception as e:
        print(f"❌ Error starting SimpleCP: {e}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
