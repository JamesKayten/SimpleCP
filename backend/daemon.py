"""
SimpleCP Background Daemon.

Runs clipboard monitoring and REST API server together.

Usage:
    python daemon.py                    # Full daemon mode (default)
    python daemon.py --api-only         # API server only, no clipboard monitoring
    python daemon.py --port 8080        # Custom port
"""

import threading
import time
import signal
import sys
import os
import socket
import atexit

from clipboard_manager import ClipboardManager
from api.server import run_server
from settings import settings
from logger import logger
from monitoring import capture_exception, track_clipboard_event

# PID file location
PID_FILE = "/tmp/simplecp_backend.pid"


def is_port_in_use(port: int) -> bool:
    """Check if a port is already in use."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(("127.0.0.1", port))
            return False
        except OSError:
            return True


def kill_existing_process(port: int) -> bool:
    """Try to kill any existing process using the port."""
    try:
        import subprocess
        result = subprocess.run(
            ["lsof", "-t", f"-i:{port}"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0 and result.stdout.strip():
            pids = result.stdout.strip().split('\n')
            for pid in pids:
                try:
                    pid_int = int(pid)
                    logger.info(f"Killing existing process {pid} on port {port}")
                    os.kill(pid_int, signal.SIGTERM)
                except (ProcessLookupError, ValueError):
                    pass
            time.sleep(0.5)

            # If port still in use, force kill with SIGKILL
            if is_port_in_use(port):
                logger.warning("Process didn't respond to SIGTERM, using SIGKILL...")
                result = subprocess.run(
                    ["lsof", "-t", f"-i:{port}"],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0 and result.stdout.strip():
                    pids = result.stdout.strip().split('\n')
                    for pid in pids:
                        try:
                            os.kill(int(pid), signal.SIGKILL)
                        except (ProcessLookupError, ValueError):
                            pass
                    time.sleep(0.3)

            return not is_port_in_use(port)
    except Exception as e:
        logger.warning(f"Failed to kill existing process: {e}")
    return False


def write_pid_file():
    """Write current process PID to file."""
    try:
        with open(PID_FILE, 'w') as f:
            f.write(str(os.getpid()))
        logger.debug(f"PID file written: {PID_FILE}")
    except Exception as e:
        logger.warning(f"Failed to write PID file: {e}")


def remove_pid_file():
    """Remove PID file on exit."""
    try:
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
            logger.debug(f"PID file removed: {PID_FILE}")
    except Exception as e:
        logger.warning(f"Failed to remove PID file: {e}")


class SimpleCPDaemon:
    """Background daemon managing clipboard monitoring and API server."""

    def __init__(
        self,
        host: str = None,
        port: int = None,
        check_interval: int = None,
        api_only: bool = False,
    ):
        """
        Initialize daemon.

        Args:
            host: API server host (defaults to settings.api_host)
            port: API server port (defaults to settings.api_port)
            check_interval: Clipboard check interval in seconds
            api_only: If True, only run API server without clipboard monitoring
        """
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

        # Check if port is in use
        if is_port_in_use(self.port):
            logger.warning(f"Port {self.port} is already in use, attempting to free...")
            if not kill_existing_process(self.port):
                logger.error(f"Could not free port {self.port}")
                print(f"Could not free port {self.port}. Try: kill $(lsof -t -i:{self.port})")
                sys.exit(1)
            logger.info(f"Port {self.port} freed successfully")

        # Write PID file
        write_pid_file()
        atexit.register(remove_pid_file)

        self.running = True
        logger.info(f"Starting SimpleCP daemon (version: {settings.app_version})")

        # Start clipboard monitoring thread (unless api_only mode)
        if not self.api_only:
            self.clipboard_thread = threading.Thread(
                target=self.clipboard_monitor_loop, daemon=True
            )
            self.clipboard_thread.start()

        # Start API server thread
        self.api_thread = threading.Thread(target=self.start_api_server, daemon=True)
        self.api_thread.start()

        # Display startup message
        mode = "API Only" if self.api_only else "Full"
        clipboard_status = "Disabled" if self.api_only else "Running"
        startup_msg = f"""
╔══════════════════════════════════════════╗
║     SimpleCP Daemon Started              ║
╟──────────────────────────────────────────╢
║  Version: {settings.app_version:<28} ║
║  Mode: {mode:<31} ║
║  Environment: {settings.environment:<24} ║
║  📋 Clipboard Monitor: {clipboard_status:<17} ║
║  🌐 API Server: http://{self.host}:{self.port:<10} ║
║  📊 History: {len(self.clipboard_manager.history_store)} items{' ' * 20}║
║  📁 Snippets: {len(self.clipboard_manager.snippet_store)} snippets{' ' * 16}║
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

        remove_pid_file()
        logger.info("SimpleCP daemon stopped")
        sys.exit(0)


def signal_handler(sig, frame):
    """Handle termination signals."""
    logger.info("Received termination signal, shutting down...")
    remove_pid_file()
    sys.exit(0)


def main():
    """Main entry point for daemon."""
    import argparse

    parser = argparse.ArgumentParser(
        description="SimpleCP Background Daemon",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python daemon.py                    # Full daemon with clipboard monitoring
  python daemon.py --api-only         # API server only
  python daemon.py --port 8080        # Custom port
  python daemon.py --host 0.0.0.0     # Listen on all interfaces
"""
    )
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
    parser.add_argument(
        "--api-only",
        action="store_true",
        help="Run only the API server without clipboard monitoring",
    )

    args = parser.parse_args()

    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Create and start daemon
    daemon = SimpleCPDaemon(
        host=args.host,
        port=args.port,
        check_interval=args.interval,
        api_only=args.api_only,
    )

    daemon.start()


if __name__ == "__main__":
    main()
