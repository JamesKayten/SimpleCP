"""
Background daemon for SimpleCP.

Runs clipboard monitoring and REST API server together.
"""

import threading
import time
import signal
import sys
import logging
from clipboard_manager import ClipboardManager
from api.server import run_server

logger = logging.getLogger(__name__)


class SimpleCP_Daemon:
    """Background daemon managing clipboard monitoring and API server."""

    def __init__(self, host: str = "127.0.0.1", port: int = 8000, check_interval: int = 1, config=None):
        """
        Initialize daemon.

        Args:
            host: API server host
            port: API server port
            check_interval: Clipboard check interval in seconds
            config: SimpleCP_Config instance
        """
        self.config = config
        self.clipboard_manager = ClipboardManager(data_dir=config.data_dir if config else None)
        self.host = host
        self.port = port
        self.check_interval = check_interval
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
                    logger.debug(f"New clipboard item: {new_item.display_string}")
            except Exception as e:
                logger.error(f"Error in clipboard monitor: {e}", exc_info=True)

            time.sleep(self.check_interval)

    def start_api_server(self):
        """Start API server in thread."""
        logger.info(f"Starting API server on {self.host}:{self.port}")
        try:
            run_server(self.host, self.port, self.clipboard_manager, self.config)
        except Exception as e:
            logger.error(f"Error in API server: {e}", exc_info=True)

    def start(self):
        """Start daemon - both clipboard monitor and API server."""
        if self.running:
            logger.warning("Daemon already running")
            return

        self.running = True

        # Start clipboard monitoring thread
        self.clipboard_thread = threading.Thread(
            target=self.clipboard_monitor_loop,
            daemon=True
        )
        self.clipboard_thread.start()

        # Start API server thread
        self.api_thread = threading.Thread(
            target=self.start_api_server,
            daemon=True
        )
        self.api_thread.start()

        logger.info(f"""
╔══════════════════════════════════════════╗
║     SimpleCP Daemon Started              ║
╟──────────────────────────────────────────╢
║  📋 Clipboard Monitor: Running           ║
║  🌐 API Server: http://{self.host}:{self.port}  ║
║  📊 Stats: {len(self.clipboard_manager.history_store)} history items          ║
╚══════════════════════════════════════════╝
""")

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
        self.clipboard_manager.save_stores()

        logger.info("SimpleCP daemon stopped")
        sys.exit(0)


def signal_handler(sig, frame):
    """Handle termination signals."""
    logger.info("Received signal, shutting down...")
    sys.exit(0)


def main():
    """Main entry point for daemon."""
    import argparse
    from config import load_config, setup_logging, check_platform_compatibility

    parser = argparse.ArgumentParser(description="SimpleCP Background Daemon")
    parser.add_argument("--host", help="API server host")
    parser.add_argument("--port", type=int, help="API server port")
    parser.add_argument("--interval", type=int, help="Clipboard check interval (seconds)")
    parser.add_argument("--config", help="Path to configuration file")
    parser.add_argument("--log-level", help="Logging level (DEBUG, INFO, WARNING, ERROR)")

    args = parser.parse_args()

    # Load configuration
    config = load_config(args.config)

    # Override config with command-line arguments
    if args.host:
        config.host = args.host
    if args.port:
        config.port = args.port
    if args.interval:
        config.check_interval = args.interval
    if args.log_level:
        config.log_level = args.log_level

    # Setup logging
    setup_logging(config)

    # Check platform compatibility
    compat = check_platform_compatibility(config)
    if compat["errors"]:
        logger.error("Platform compatibility issues detected:")
        for error in compat["errors"]:
            logger.error(f"  - {error}")
        if not compat["clipboard_available"]:
            logger.warning("Clipboard monitoring may not work properly!")

    if compat["warnings"]:
        for warning in compat["warnings"]:
            logger.warning(warning)

    logger.info(f"SimpleCP starting on {config.host}:{config.port}")
    logger.info(f"Platform: {compat['platform']}")

    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Create and start daemon
    daemon = SimpleCP_Daemon(
        host=config.host,
        port=config.port,
        check_interval=config.check_interval,
        config=config
    )

    daemon.start()


if __name__ == "__main__":
    main()
