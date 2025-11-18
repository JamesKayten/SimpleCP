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


class SimpleCP_Daemon:
    """Background daemon managing clipboard monitoring and API server."""

    def __init__(
        self,
        host: str = "127.0.0.1",
        port: int = 8000,
        check_interval: int = 1,
    ):
        """
        Initialize daemon.

        Args:
            host: API server host
            port: API server port
            check_interval: Clipboard check interval in seconds
        """
        self.clipboard_manager = ClipboardManager()
        self.host = host
        self.port = port
        self.check_interval = check_interval
        self.running = False
        self.clipboard_thread = None
        self.api_thread = None

    def clipboard_monitor_loop(self):
        """Background clipboard monitoring loop."""
        print(
            f"📋 Clipboard monitoring started (checking every {self.check_interval}s)"
        )
        while self.running:
            try:
                new_item = self.clipboard_manager.check_clipboard()
                if new_item:
                    print(f"📎 New clipboard item: {new_item.display_string}")
            except Exception as e:
                print(f"Error in clipboard monitor: {e}")

            time.sleep(self.check_interval)

    def start_api_server(self):
        """Start API server in thread."""
        print(f"🚀 Starting API server on {self.host}:{self.port}")
        try:
            run_server(self.host, self.port, self.clipboard_manager)
        except Exception as e:
            print(f"Error in API server: {e}")

    def start(self):
        """Start daemon - both clipboard monitor and API server."""
        if self.running:
            print("⚠️  Daemon already running")
            return

        self.running = True

        # Start clipboard monitoring thread
        self.clipboard_thread = threading.Thread(
            target=self.clipboard_monitor_loop, daemon=True
        )
        self.clipboard_thread.start()

        # Start API server thread
        self.api_thread = threading.Thread(
            target=self.start_api_server, daemon=True
        )
        self.api_thread.start()

        print(
            f"""
╔══════════════════════════════════════════╗
║     SimpleCP Daemon Started              ║
╟──────────────────────────────────────────╢
║  📋 Clipboard Monitor: Running           ║
║  🌐 API Server: http://{self.host}:{self.port}  ║
║  📊 Stats: {len(self.clipboard_manager.history_store)} history items          ║
╚══════════════════════════════════════════╝
"""
        )

        # Keep main thread alive
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stop()

    def stop(self):
        """Stop daemon gracefully."""
        print("\n🛑 Stopping SimpleCP daemon...")
        self.running = False

        # Wait for threads to finish
        if self.clipboard_thread and self.clipboard_thread.is_alive():
            self.clipboard_thread.join(timeout=2)

        print("💾 Saving data...")
        self.clipboard_manager.save_stores()

        print("👋 SimpleCP daemon stopped")
        sys.exit(0)


def signal_handler(sig, frame):
    """Handle termination signals."""
    print("\n🛑 Received signal, shutting down...")
    sys.exit(0)


def main():
    """Main entry point for daemon."""
    import argparse

    parser = argparse.ArgumentParser(description="SimpleCP Background Daemon")
    parser.add_argument("--host", default="127.0.0.1", help="API server host")
    parser.add_argument(
        "--port", type=int, default=8000, help="API server port"
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=1,
        help="Clipboard check interval (seconds)",
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
