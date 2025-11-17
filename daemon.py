"""
SimpleCP Background Daemon.

Runs clipboard monitoring and REST API server in the background.
"""

import threading
import time
import pyperclip
import uvicorn
from datetime import datetime

from stores.clipboard_item import ClipboardItem
from api.server import app, get_app_state


class ClipboardDaemon:
    """
    Background daemon for clipboard monitoring and API server.

    Features:
    - Clipboard monitoring with configurable interval
    - Automatic history storage with deduplication
    - REST API server on localhost:8080
    - Thread-safe operation
    """

    def __init__(self, host: str = "127.0.0.1", port: int = 8080):
        """
        Initialize the daemon.

        Args:
            host: API server host (default: localhost)
            port: API server port (default: 8080)
        """
        self.host = host
        self.port = port
        self.state = get_app_state()
        self.running = False
        self.last_clipboard_content = ""

        # Threads
        self.clipboard_thread = None
        self.api_thread = None

    def start(self):
        """
        Start the daemon.

        Launches two threads:
        1. Clipboard monitoring thread
        2. API server thread
        """
        print("Starting SimpleCP Background Daemon...")
        self.running = True

        # Mark clipboard monitoring as active
        self.state.clipboard_monitoring = True

        # Start clipboard monitoring thread
        self.clipboard_thread = threading.Thread(
            target=self._clipboard_monitor_loop,
            daemon=True
        )
        self.clipboard_thread.start()
        print(f"  - Clipboard monitoring started (interval: {self.state.settings['clipboard_check_interval']}s)")

        # Start API server thread
        self.api_thread = threading.Thread(
            target=self._run_api_server,
            daemon=True
        )
        self.api_thread.start()
        print(f"  - API server started on http://{self.host}:{self.port}")
        print(f"  - API documentation: http://{self.host}:{self.port}/docs")
        print("\nSimpleCP is running! Press Ctrl+C to stop.")

        # Keep main thread alive
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stop()

    def stop(self):
        """Stop the daemon."""
        print("\nStopping SimpleCP Background Daemon...")
        self.running = False
        self.state.clipboard_monitoring = False
        print("SimpleCP stopped.")

    def _clipboard_monitor_loop(self):
        """
        Clipboard monitoring loop.

        Runs in a separate thread, checking clipboard at configured interval.
        """
        print("Clipboard monitor thread started")

        while self.running:
            try:
                # Get current clipboard content
                current_content = pyperclip.paste()

                # Check if content has changed
                if current_content and current_content != self.last_clipboard_content:
                    # Avoid adding empty strings
                    if current_content.strip():
                        self._on_clipboard_change(current_content)
                        self.last_clipboard_content = current_content

            except Exception as e:
                print(f"Error in clipboard monitor: {e}")

            # Sleep for configured interval
            time.sleep(self.state.settings['clipboard_check_interval'])

    def _on_clipboard_change(self, content: str):
        """
        Handle clipboard content change.

        Args:
            content: New clipboard content
        """
        # Create ClipboardItem
        item = ClipboardItem(
            content=content,
            timestamp=datetime.now(),
            source_app=None,  # Could use AppKit on macOS to detect source
            item_type="history"
        )

        # Add to history store (with auto-deduplication)
        was_new = self.state.history_store.add(item)

        if was_new:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] New clipboard item: {item.preview}")
        else:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Duplicate moved to top: {item.preview}")

    def _run_api_server(self):
        """
        Run the FastAPI server.

        Runs in a separate thread using uvicorn.
        """
        uvicorn.run(
            app,
            host=self.host,
            port=self.port,
            log_level="info"
        )


def main():
    """Main entry point for the daemon."""
    daemon = ClipboardDaemon(host="127.0.0.1", port=8080)
    daemon.start()


if __name__ == "__main__":
    main()
