"""Monitoring and analytics for SimpleCP."""
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
from monitoring.trackers import PerformanceTracker, UsageAnalytics

performance_tracker = PerformanceTracker()
usage_analytics = UsageAnalytics()


def before_send_event(event, hint):
    """Filter events before sending to Sentry."""
    if settings.is_development and not settings.enable_sentry:
        return None
    event.setdefault("tags", {})
    event["tags"]["app_version"] = settings.app_version
    event["tags"]["environment"] = settings.environment
    return event


def before_breadcrumb(crumb, hint):
    return crumb


def initialize_sentry():
    """Initialize Sentry SDK."""
    sentry_config = settings.get_sentry_config()
    if not sentry_config:
        return
    try:
        sentry_sdk.init(
            integrations=[FastApiIntegration(transaction_style="endpoint"),
                          LoggingIntegration(level=logging.INFO, event_level=logging.ERROR)],
            **sentry_config, before_send=before_send_event, before_breadcrumb=before_breadcrumb)
    except Exception as e:
        logger.error(f"Failed to initialize Sentry: {e}", exc_info=True)


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
        if settings.enable_sentry:
            with sentry_sdk.start_transaction(op=operation, name=operation) as txn:
                txn.set_measurement("duration_ms", duration_ms)
                if error:
                    sentry_sdk.capture_exception(error)


def track_performance_decorator(operation: str):
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            with track_performance(operation):
                return func(*args, **kwargs)
        return wrapper
    return decorator


def track_api_request(method: str, path: str, status_code: int, duration_ms: float):
    if settings.enable_usage_analytics:
        usage_analytics.track_event("api_requests", method=method, path=path, status_code=status_code)
    if settings.enable_performance_tracking:
        performance_tracker.record(f"api_{method.lower()}_{path}", duration_ms, method=method, path=path, status_code=status_code)


def track_clipboard_event(event_type: str, **kwargs):
    if settings.enable_usage_analytics:
        usage_analytics.track_event("clipboard_events", clipboard_event_type=event_type, **kwargs)


def capture_exception(error: Exception, context: Optional[dict] = None):
    logger.error(f"Exception: {error}", exc_info=True, extra=context or {})
    if settings.enable_sentry:
        with sentry_sdk.push_scope() as scope:
            if context:
                for k, v in context.items():
                    scope.set_context(k, v)
            sentry_sdk.capture_exception(error)
    if settings.enable_usage_analytics:
        usage_analytics.track_event("errors", error_type=type(error).__name__)


def capture_message(message: str, level: str = "info", **kwargs):
    if settings.enable_sentry:
        sentry_sdk.capture_message(message, level=level)
    getattr(logger, level.lower(), logger.info)(message, extra=kwargs)


def add_breadcrumb(message: str, category: str = "default", level: str = "info", **data):
    if settings.enable_sentry:
        sentry_sdk.add_breadcrumb(message=message, category=category, level=level, data=data)


def get_monitoring_stats() -> dict:
    return {"performance": performance_tracker.get_stats(), "usage": usage_analytics.get_stats(),
            "sentry_enabled": settings.enable_sentry, "environment": settings.environment}


__all__ = ['MetricsCollector', 'HealthChecker', 'PerformanceTracker', 'UsageAnalytics', 'performance_tracker',
           'usage_analytics', 'initialize_sentry', 'track_performance', 'track_performance_decorator',
           'track_api_request', 'track_clipboard_event', 'capture_exception', 'capture_message',
           'add_breadcrumb', 'get_monitoring_stats']
