"""
Background daemon for SimpleCP.

Runs clipboard monitoring and REST API server together.
"""

import threading
import time
import signal
import sys

from clipboard_manager import ClipboardManager
from api.server import run_server
from settings import settings
from logger import logger
from monitoring import capture_exception, track_clipboard_event


class SimpleCP_Daemon:
    """Background daemon managing clipboard monitoring and API server."""

    def __init__(
        self,
        host: str = None,
        port: int = None,
        check_interval: int = None,
    ):
        """
        Initialize daemon.

        Args:
            host: API server host (defaults to settings.api_host)
            port: API server port (defaults to settings.api_port)
            check_interval: Clipboard check interval in seconds (defaults to settings)
        """
        self.clipboard_manager = ClipboardManager()
        self.host = host or settings.api_host
        self.port = port or settings.api_port
        self.check_interval = check_interval or settings.clipboard_check_interval
        self.running = False
        self.clipboard_thread = None
        self.api_thread = None

    def clipboard_monitor_loop(self):
        """Background clipboard monitoring loop."""
        logger.info(
            f"Clipboard monitoring started (checking every {self.check_interval}s)"
        )
        while self.running:
            try:
                new_item = self.clipboard_manager.check_clipboard()
                if new_item:
                    logger.info(f"New clipboard item: {new_item.display_string}")
                    track_clipboard_event(
                        "new_item",
                        item_id=new_item.clip_id,
                        content_type=new_item.content_type,
                    )
            except Exception as e:
                logger.error(f"Error in clipboard monitor: {e}", exc_info=True)
                capture_exception(e, context={"component": "clipboard_monitor"})

            time.sleep(self.check_interval)

    def start_api_server(self):
        """Start API server in thread."""
        logger.info(f"Starting API server on {self.host}:{self.port}")
        try:
            run_server(self.host, self.port, self.clipboard_manager)
        except Exception as e:
            logger.error(f"Error in API server: {e}", exc_info=True)
            capture_exception(e, context={"component": "api_server"})

    def start(self):
        """Start daemon - both clipboard monitor and API server."""
        if self.running:
            logger.warning("Daemon already running")
            return

        self.running = True

        logger.info(f"Starting SimpleCP daemon (version: {settings.app_version})")

        # Start clipboard monitoring thread
        self.clipboard_thread = threading.Thread(
            target=self.clipboard_monitor_loop, daemon=True
        )
        self.clipboard_thread.start()

        # Start API server thread
        self.api_thread = threading.Thread(target=self.start_api_server, daemon=True)
        self.api_thread.start()

        # Display startup message
        startup_msg = f"""
╔══════════════════════════════════════════╗
║     SimpleCP Daemon Started              ║
╟──────────────────────────────────────────╢
║  Version: {settings.app_version}                        ║
║  Environment: {settings.environment}               ║
║  📋 Clipboard Monitor: Running           ║
║  🌐 API Server: http://{self.host}:{self.port}  ║
║  📊 History: {len(self.clipboard_manager.history_store)} items                   ║
║  📁 Snippets: {len(self.clipboard_manager.snippet_store)} snippets              ║
╚══════════════════════════════════════════╝
"""
        print(startup_msg)
        logger.info("SimpleCP daemon started successfully")

        # Keep main thread alive
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stop()

    def stop(self):
        """Stop daemon gracefully."""
        logger.info("Stopping SimpleCP daemon...")
        self.running = False

        # Wait for threads to finish
        if self.clipboard_thread and self.clipboard_thread.is_alive():
            self.clipboard_thread.join(timeout=2)

        logger.info("Saving data...")
        try:
            self.clipboard_manager.save_stores()
            logger.info("Data saved successfully")
        except Exception as e:
            logger.error(f"Error saving data: {e}", exc_info=True)
            capture_exception(e, context={"component": "shutdown"})

        logger.info("SimpleCP daemon stopped")
        sys.exit(0)


def signal_handler(sig, frame):
    """Handle termination signals."""
    logger.info("Received termination signal, shutting down...")
    sys.exit(0)


def main():
    """Main entry point for daemon."""
    import argparse

    parser = argparse.ArgumentParser(description="SimpleCP Background Daemon")
    parser.add_argument(
        "--host", default=None, help=f"API server host (default: {settings.api_host})"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=None,
        help=f"API server port (default: {settings.api_port})",
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=None,
        help=f"Clipboard check interval in seconds (default: {settings.clipboard_check_interval})",
    )

    args = parser.parse_args()

    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Create and start daemon
    daemon = SimpleCP_Daemon(
        host=args.host, port=args.port, check_interval=args.interval
    )

    daemon.start()


if __name__ == "__main__":
    main()
