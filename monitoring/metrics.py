"""
Metrics collection and reporting for SimpleCP.

Tracks application performance and usage statistics.
"""

import time
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass, field
from collections import defaultdict


@dataclass
class Metric:
    """Represents a single metric data point."""

    name: str
    value: float
    timestamp: datetime = field(default_factory=datetime.now)
    tags: Dict[str, str] = field(default_factory=dict)


class MetricsCollector:
    """
    Collects and aggregates application metrics.

    Usage:
        collector = MetricsCollector()
        collector.increment('clipboard.add')
        collector.gauge('clipboard.size', 42)
        collector.timing('api.request', 0.123)
    """

    def __init__(self):
        """Initialize metrics collector."""
        self._counters: Dict[str, int] = defaultdict(int)
        self._gauges: Dict[str, float] = {}
        self._timings: Dict[str, List[float]] = defaultdict(list)
        self._metrics_history: List[Metric] = []

    def increment(self, name: str, value: int = 1, tags: Optional[Dict[str, str]] = None):
        """
        Increment a counter metric.

        Args:
            name: Metric name
            value: Amount to increment by
            tags: Optional tags for the metric
        """
        self._counters[name] += value
        self._record_metric(name, self._counters[name], tags or {})

    def decrement(self, name: str, value: int = 1, tags: Optional[Dict[str, str]] = None):
        """
        Decrement a counter metric.

        Args:
            name: Metric name
            value: Amount to decrement by
            tags: Optional tags for the metric
        """
        self._counters[name] -= value
        self._record_metric(name, self._counters[name], tags or {})

    def gauge(self, name: str, value: float, tags: Optional[Dict[str, str]] = None):
        """
        Set a gauge metric to a specific value.

        Args:
            name: Metric name
            value: Gauge value
            tags: Optional tags for the metric
        """
        self._gauges[name] = value
        self._record_metric(name, value, tags or {})

    def timing(self, name: str, duration: float, tags: Optional[Dict[str, str]] = None):
        """
        Record a timing metric.

        Args:
            name: Metric name
            duration: Duration in seconds
            tags: Optional tags for the metric
        """
        self._timings[name].append(duration)
        self._record_metric(name, duration, tags or {})

    def get_counter(self, name: str) -> int:
        """Get counter value."""
        return self._counters.get(name, 0)

    def get_gauge(self, name: str) -> Optional[float]:
        """Get gauge value."""
        return self._gauges.get(name)

    def get_timing_stats(self, name: str) -> Dict[str, float]:
        """
        Get timing statistics.

        Returns:
            Dictionary with min, max, avg, count
        """
        timings = self._timings.get(name, [])
        if not timings:
            return {"min": 0, "max": 0, "avg": 0, "count": 0}

        return {
            "min": min(timings),
            "max": max(timings),
            "avg": sum(timings) / len(timings),
            "count": len(timings),
        }

    def get_all_metrics(self) -> Dict[str, any]:
        """Get all current metrics."""
        return {
            "counters": dict(self._counters),
            "gauges": dict(self._gauges),
            "timings": {
                name: self.get_timing_stats(name)
                for name in self._timings.keys()
            },
        }

    def reset(self):
        """Reset all metrics."""
        self._counters.clear()
        self._gauges.clear()
        self._timings.clear()
        self._metrics_history.clear()

    def _record_metric(self, name: str, value: float, tags: Dict[str, str]):
        """Record metric to history."""
        metric = Metric(name=name, value=value, tags=tags)
        self._metrics_history.append(metric)

        # Keep only last 1000 metrics
        if len(self._metrics_history) > 1000:
            self._metrics_history = self._metrics_history[-1000:]


class Timer:
    """
    Context manager for timing code blocks.

    Usage:
        collector = MetricsCollector()
        with Timer(collector, 'operation.duration'):
            # Code to time
            pass
    """

    def __init__(self, collector: MetricsCollector, name: str, tags: Optional[Dict[str, str]] = None):
        """Initialize timer."""
        self.collector = collector
        self.name = name
        self.tags = tags or {}
        self.start_time = None

    def __enter__(self):
        """Start timer."""
        self.start_time = time.time()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Stop timer and record metric."""
        duration = time.time() - self.start_time
        self.collector.timing(self.name, duration, self.tags)


# Global metrics collector instance
_metrics_collector: Optional[MetricsCollector] = None


def get_metrics_collector() -> MetricsCollector:
    """Get global metrics collector instance."""
    global _metrics_collector
    if _metrics_collector is None:
        _metrics_collector = MetricsCollector()
    return _metrics_collector
