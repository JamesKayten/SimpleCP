"""Process and port management utilities."""
import os
import signal
import socket
import time
from logger import logger

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
