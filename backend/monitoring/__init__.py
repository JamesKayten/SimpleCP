"""
Monitoring and analytics for SimpleCP.

Provides crash reporting, performance monitoring, and usage analytics.
"""
import logging
import time
from contextlib import contextmanager
from functools import wraps
from typing import Callable, Optional
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.logging import LoggingIntegration

from settings import settings
from logger import logger

from monitoring.metrics import MetricsCollector
from monitoring.health import HealthChecker


class PerformanceTracker:
    """Track performance metrics for operations."""

    def __init__(self):
        self.metrics = {}

    def record(self, operation: str, duration_ms: float, **kwargs):
        """Record a performance metric."""
        if operation not in self.metrics:
            self.metrics[operation] = {
                "count": 0,
                "total_ms": 0,
                "min_ms": float("inf"),
                "max_ms": 0,
                "avg_ms": 0,
            }

        metric = self.metrics[operation]
        metric["count"] += 1
        metric["total_ms"] += duration_ms
        metric["min_ms"] = min(metric["min_ms"], duration_ms)
        metric["max_ms"] = max(metric["max_ms"], duration_ms)
        metric["avg_ms"] = metric["total_ms"] / metric["count"]

        logger.debug(
            f"Performance: {operation} took {duration_ms:.2f}ms",
            extra={"operation": operation, "duration_ms": duration_ms, **kwargs},
        )

    def get_stats(self) -> dict:
        """Get all performance statistics."""
        return self.metrics.copy()

    def reset(self):
        """Reset all metrics."""
        self.metrics.clear()


class UsageAnalytics:
    """Track usage analytics for clipboard and API operations."""

    def __init__(self):
        self.events = {
            "clipboard_events": 0,
            "api_requests": 0,
            "history_operations": 0,
            "snippet_operations": 0,
            "search_queries": 0,
            "errors": 0,
        }

    def track_event(self, event_type: str, **kwargs):
        """Track a usage event."""
        if event_type in self.events:
            self.events[event_type] += 1

        logger.debug(
            f"Usage Event: {event_type}",
            extra={"event_type": "usage", "usage_event_type": event_type, **kwargs},
        )

    def get_stats(self) -> dict:
        """Get all usage statistics."""
        return self.events.copy()

    def reset(self):
        """Reset all events."""
        for key in self.events:
            self.events[key] = 0


# Global instances
performance_tracker = PerformanceTracker()
usage_analytics = UsageAnalytics()


def initialize_sentry():
    """Initialize Sentry SDK for crash reporting and performance monitoring."""
    sentry_config = settings.get_sentry_config()

    if not sentry_config:
        logger.info("Sentry is disabled (no DSN configured)")
        return

    try:
        # Configure logging integration
        logging_integration = LoggingIntegration(
            level=logging.INFO,  # Capture info and above as breadcrumbs
            event_level=logging.ERROR,  # Send errors as events
        )

        # Initialize Sentry
        sentry_sdk.init(
            integrations=[
                FastApiIntegration(transaction_style="endpoint"),
                logging_integration,
            ],
            **sentry_config,
            # Additional configuration
            before_send=before_send_event,
            before_breadcrumb=before_breadcrumb,
        )

        logger.info(
            f"Sentry initialized successfully (environment: {settings.sentry_environment})"
        )
    except Exception as e:
        logger.error(f"Failed to initialize Sentry: {e}", exc_info=True)


def before_send_event(event, hint):
    """
    Filter and modify events before sending to Sentry.

    This allows us to:
    - Filter out sensitive data
    - Add custom context
    - Skip certain events
    """
    # Skip events from development if needed
    if settings.is_development and not settings.enable_sentry:
        return None

    # Add custom tags
    event.setdefault("tags", {})
    event["tags"]["app_version"] = settings.app_version
    event["tags"]["environment"] = settings.environment

    return event


def before_breadcrumb(crumb, hint):
    """Filter and modify breadcrumbs before adding to Sentry."""
    # Filter out sensitive breadcrumbs if needed
    return crumb


@contextmanager
def track_performance(operation: str, **kwargs):
    """Context manager to track operation performance."""
    start_time = time.time()
    error = None

    try:
        yield
    except Exception as e:
        error = e
        raise
    finally:
        duration_ms = (time.time() - start_time) * 1000

        if settings.enable_performance_tracking:
            performance_tracker.record(operation, duration_ms, **kwargs)

        # Log to Sentry if enabled
        if settings.enable_sentry:
            with sentry_sdk.start_transaction(op=operation, name=operation) as transaction:
                transaction.set_measurement("duration_ms", duration_ms)
                if error:
                    sentry_sdk.capture_exception(error)


def track_performance_decorator(operation: str):
    """Decorator to track function performance."""

    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            with track_performance(operation):
                return func(*args, **kwargs)

        return wrapper

    return decorator


def track_api_request(method: str, path: str, status_code: int, duration_ms: float):
    """Track API request metrics."""
    if settings.enable_usage_analytics:
        usage_analytics.track_event(
            "api_requests",
            method=method,
            path=path,
            status_code=status_code,
        )

    if settings.enable_performance_tracking:
        performance_tracker.record(
            f"api_{method.lower()}_{path}",
            duration_ms,
            method=method,
            path=path,
            status_code=status_code,
        )


def track_clipboard_event(event_type: str, **kwargs):
    """Track clipboard event."""
    if settings.enable_usage_analytics:
        usage_analytics.track_event("clipboard_events", clipboard_event_type=event_type, **kwargs)


def capture_exception(error: Exception, context: Optional[dict] = None):
    """Capture exception to Sentry and logs."""
    logger.error(f"Exception captured: {str(error)}", exc_info=True, extra=context or {})

    if settings.enable_sentry:
        with sentry_sdk.push_scope() as scope:
            if context:
                for key, value in context.items():
                    scope.set_context(key, value)
            sentry_sdk.capture_exception(error)

    if settings.enable_usage_analytics:
        usage_analytics.track_event("errors", error_type=type(error).__name__)


def capture_message(message: str, level: str = "info", **kwargs):
    """Capture a message to Sentry."""
    if settings.enable_sentry:
        sentry_sdk.capture_message(message, level=level)

    log_level = getattr(logger, level.lower(), logger.info)
    log_level(message, extra=kwargs)


def add_breadcrumb(message: str, category: str = "default", level: str = "info", **data):
    """Add a breadcrumb for debugging context."""
    if settings.enable_sentry:
        sentry_sdk.add_breadcrumb(
            message=message,
            category=category,
            level=level,
            data=data,
        )


def get_monitoring_stats() -> dict:
    """Get all monitoring statistics."""
    return {
        "performance": performance_tracker.get_stats(),
        "usage": usage_analytics.get_stats(),
        "sentry_enabled": settings.enable_sentry,
        "environment": settings.environment,
    }


__all__ = [
    'MetricsCollector',
    'HealthChecker',
    'PerformanceTracker',
    'UsageAnalytics',
    'performance_tracker',
    'usage_analytics',
    'initialize_sentry',
    'track_performance',
    'track_performance_decorator',
    'track_api_request',
    'track_clipboard_event',
    'capture_exception',
    'capture_message',
    'add_breadcrumb',
    'get_monitoring_stats',
]
