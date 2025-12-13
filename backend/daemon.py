"""SimpleCP Background Daemon - clipboard monitoring and REST API server."""
import threading
import time
import signal
import sys
import atexit

from clipboard_manager import ClipboardManager
from api.server import run_server
from settings import settings
from logger import logger
from monitoring import capture_exception, track_clipboard_event
from utils.process import is_port_in_use, kill_existing_process, write_pid_file, remove_pid_file


class SimpleCPDaemon:
    """Background daemon managing clipboard monitoring and API server."""

    def __init__(self, host: str = None, port: int = None, check_interval: int = None, api_only: bool = False):
        self.clipboard_manager = ClipboardManager()
        self.host = host or settings.api_host
        self.port = port or settings.api_port
        self.check_interval = check_interval or settings.clipboard_check_interval
        self.api_only = api_only
        self.running = False
        self.clipboard_thread = None
        self.api_thread = None

    def clipboard_monitor_loop(self):
        """Background clipboard monitoring loop."""
        logger.info(f"Clipboard monitoring started (checking every {self.check_interval}s)")
        while self.running:
            try:
                new_item = self.clipboard_manager.check_clipboard()
                if new_item:
                    logger.info(f"New clipboard item: {new_item.display_string}")
                    track_clipboard_event("new_item", item_id=new_item.clip_id, content_type=new_item.content_type)
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
            return
        if is_port_in_use(self.port):
            logger.warning(f"Port {self.port} in use, attempting to free...")
            if not kill_existing_process(self.port):
                print(f"Could not free port {self.port}. Try: kill $(lsof -t -i:{self.port})")
                sys.exit(1)

        write_pid_file()
        atexit.register(remove_pid_file)
        self.running = True

        if not self.api_only:
            self.clipboard_thread = threading.Thread(target=self.clipboard_monitor_loop, daemon=True)
            self.clipboard_thread.start()

        self.api_thread = threading.Thread(target=self.start_api_server, daemon=True)
        self.api_thread.start()

        mode, clip_status = ("API Only", "Disabled") if self.api_only else ("Full", "Running")
        print(f"\n  SimpleCP Daemon Started | v{settings.app_version} | {mode}")
        print(f"  API: http://{self.host}:{self.port} | Clipboard: {clip_status}")
        print(f"  History: {len(self.clipboard_manager.history_store)} | Snippets: {len(self.clipboard_manager.snippet_store)}\n")

        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stop()

    def stop(self):
        """Stop daemon gracefully."""
        logger.info("Stopping SimpleCP daemon...")
        self.running = False
        if self.clipboard_thread and self.clipboard_thread.is_alive():
            self.clipboard_thread.join(timeout=2)
        try:
            self.clipboard_manager.save_stores()
        except Exception as e:
            capture_exception(e, context={"component": "shutdown"})
        remove_pid_file()
        sys.exit(0)


def signal_handler(sig, frame):
    """Handle termination signals."""
    remove_pid_file()
    sys.exit(0)


def main():
    """Main entry point for daemon."""
    import argparse
    parser = argparse.ArgumentParser(description="SimpleCP Background Daemon")
    parser.add_argument("--host", default=None, help=f"API host (default: {settings.api_host})")
    parser.add_argument("--port", type=int, default=None, help=f"API port (default: {settings.api_port})")
    parser.add_argument("--interval", type=int, default=None, help="Clipboard check interval")
    parser.add_argument("--api-only", action="store_true", help="API server only, no clipboard monitoring")
    args = parser.parse_args()

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    SimpleCPDaemon(host=args.host, port=args.port, check_interval=args.interval, api_only=args.api_only).start()


if __name__ == "__main__":
    main()
