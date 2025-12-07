#!/usr/bin/env python3
"""
SimpleCP - Simple macOS Clipboard Manager
Entry point for the application.

Run with: python3 main.py
"""

import sys
import os
import socket
import signal
import atexit

# Add the project root to Python path
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_root)

from api.server import run_server  # noqa: E402

# PID file location
PID_FILE = "/tmp/simplecp_backend.pid"


def is_port_in_use(port):
    """Check if a port is already in use."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(("127.0.0.1", port))
            return False
        except OSError:
            return True


def kill_existing_process(port):
    """Try to kill any existing process using the port."""
    try:
        import subprocess
        import time
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
                    print(f"🛑 Killing existing process {pid} on port {port}")
                    # Try SIGTERM first
                    os.kill(pid_int, signal.SIGTERM)
                except (ProcessLookupError, ValueError):
                    pass
            time.sleep(0.5)

            # If port still in use, force kill with SIGKILL
            if is_port_in_use(port):
                print(f"⚠️ Process didn't respond to SIGTERM, using SIGKILL...")
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
        print(f"⚠️ Failed to kill existing process: {e}")
    return False


def write_pid_file():
    """Write current process PID to file."""
    try:
        with open(PID_FILE, 'w') as f:
            f.write(str(os.getpid()))
        print(f"📝 PID file written: {PID_FILE}")
    except Exception as e:
        print(f"⚠️ Failed to write PID file: {e}")


def remove_pid_file():
    """Remove PID file on exit."""
    try:
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
            print(f"🗑️ PID file removed: {PID_FILE}")
    except Exception as e:
        print(f"⚠️ Failed to remove PID file: {e}")


def signal_handler(signum, frame):
    """Handle termination signals."""
    print(f"\n🛑 Received signal {signum}, shutting down gracefully...")
    remove_pid_file()
    sys.exit(0)


def main():
    """Main application entry point."""
    # Port 49917 derived from "SimpleCP" hash (private port range 49152-65535)
    port = 49917

    # Register cleanup handlers
    atexit.register(remove_pid_file)
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    try:
        # Check if port is in use
        if is_port_in_use(port):
            print(f"⚠️ Port {port} is already in use")
            print("🔄 Attempting to free the port...")
            if not kill_existing_process(port):
                print(f"❌ Could not free port {port}")
                print(f"💡 Run: ./kill_backend.sh or kill $(lsof -t -i:{port})")
                return 1
            print(f"✅ Port {port} freed successfully")

        # Write PID file
        write_pid_file()

        print("🚀 Starting SimpleCP API Server...")
        print(f"📋 Server running on http://localhost:{port}")
        print(f"📖 API docs available at http://localhost:{port}/docs")
        print("🛑 Press Ctrl+C to stop")

        run_server(host="127.0.0.1", port=port)

    except KeyboardInterrupt:
        print("\n👋 SimpleCP server stopped by user")
        remove_pid_file()
    except Exception as e:
        print(f"❌ Error starting SimpleCP server: {e}")
        import traceback
        traceback.print_exc()
        remove_pid_file()
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
