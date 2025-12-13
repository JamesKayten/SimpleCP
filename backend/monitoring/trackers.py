"""Performance and usage tracking classes."""
from logger import logger


class PerformanceTracker:
    """Track performance metrics for operations."""

    def __init__(self):
        self.metrics = {}

    def record(self, operation: str, duration_ms: float, **kwargs):
        """Record a performance metric."""
        if operation not in self.metrics:
            self.metrics[operation] = {"count": 0, "total_ms": 0, "min_ms": float("inf"), "max_ms": 0, "avg_ms": 0}
        m = self.metrics[operation]
        m["count"] += 1
        m["total_ms"] += duration_ms
        m["min_ms"] = min(m["min_ms"], duration_ms)
        m["max_ms"] = max(m["max_ms"], duration_ms)
        m["avg_ms"] = m["total_ms"] / m["count"]
        logger.debug(f"Performance: {operation} took {duration_ms:.2f}ms", extra={"operation": operation, "duration_ms": duration_ms, **kwargs})

    def get_stats(self) -> dict:
        return self.metrics.copy()

    def reset(self):
        self.metrics.clear()


class UsageAnalytics:
    """Track usage analytics for clipboard and API operations."""

    def __init__(self):
        self.events = {"clipboard_events": 0, "api_requests": 0, "history_operations": 0, "snippet_operations": 0, "search_queries": 0, "errors": 0}

    def track_event(self, event_type: str, **kwargs):
        """Track a usage event."""
        if event_type in self.events:
            self.events[event_type] += 1
        logger.debug(f"Usage Event: {event_type}", extra={"event_type": "usage", "usage_event_type": event_type, **kwargs})

    def get_stats(self) -> dict:
        return self.events.copy()

    def reset(self):
        for key in self.events:
            self.events[key] = 0
