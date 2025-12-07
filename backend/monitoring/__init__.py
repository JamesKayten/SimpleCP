"""
Monitoring and metrics collection for SimpleCP.
"""

from monitoring.metrics import MetricsCollector
from monitoring.health import HealthChecker

# Import functions from the main monitoring_core.py file
import sys
from pathlib import Path

# Add parent directory to path to import monitoring_core.py
parent_dir = Path(__file__).parent.parent
if str(parent_dir) not in sys.path:
    sys.path.insert(0, str(parent_dir))

from monitoring_core import (
    initialize_sentry,
    track_api_request,
    capture_exception,
    get_monitoring_stats,
    track_clipboard_event,
)

__all__ = [
    'MetricsCollector',
    'HealthChecker',
    'initialize_sentry',
    'track_api_request',
    'capture_exception',
    'get_monitoring_stats',
    'track_clipboard_event',
]
