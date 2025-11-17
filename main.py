#!/usr/bin/env python3
"""
SimpleCP - Simple macOS Clipboard Manager
Entry point for the REST API backend daemon.

Run with: python3 main.py
"""

import sys
import os

# Add the project root to Python path
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_root)

from daemon import ClipboardDaemon

def main():
    """Main application entry point."""
    try:
        print("=" * 60)
        print("SimpleCP - Clipboard Manager REST API Backend")
        print("=" * 60)

        daemon = ClipboardDaemon(host="127.0.0.1", port=8080)
        daemon.start()

    except KeyboardInterrupt:
        print("\nSimpleCP stopped by user")
    except Exception as e:
        print(f"Error starting SimpleCP: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0

if __name__ == "__main__":
    sys.exit(main())