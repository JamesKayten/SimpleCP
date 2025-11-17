"""
Performance monitoring middleware for menu bar optimization.

Tracks API response times and warns when menu bar requirements are exceeded.
"""

from fastapi import Request
import time
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("simplecp.performance")


async def performance_middleware(request: Request, call_next):
    """
    Log API performance metrics and warn on slow responses.

    Menu bar app requirement: <100ms API response time
    Dropdown open target: <50ms
    """
    start_time = time.perf_counter()
    response = await call_next(request)
    duration_ms = (time.perf_counter() - start_time) * 1000

    # Critical endpoints for menu bar dropdown
    critical_endpoints = [
        "/api/history/recent",
        "/api/snippets"
    ]

    # Determine performance target based on endpoint
    if request.url.path in critical_endpoints:
        target_ms = 50  # Critical endpoints should be <50ms
        is_critical = True
    else:
        target_ms = 100  # Standard endpoints should be <100ms
        is_critical = False

    # Log performance
    if duration_ms > target_ms:
        logger.warning(
            f"{'⚠️  CRITICAL' if is_critical else '⚠️  SLOW'} API: "
            f"{request.method} {request.url.path} "
            f"took {duration_ms:.2f}ms (target: <{target_ms}ms)"
        )
    elif duration_ms > target_ms * 0.8:
        # Warn when approaching limit (80% of target)
        logger.info(
            f"⚡ NEAR LIMIT: {request.method} {request.url.path} "
            f"took {duration_ms:.2f}ms (target: <{target_ms}ms)"
        )
    else:
        logger.debug(
            f"✅ {request.method} {request.url.path} "
            f"took {duration_ms:.2f}ms"
        )

    # Add performance header
    response.headers["X-Response-Time-Ms"] = f"{duration_ms:.2f}"
    response.headers["X-Performance-Target-Ms"] = str(target_ms)

    # Add warning header if slow
    if duration_ms > target_ms:
        response.headers["X-Performance-Warning"] = "SLOW"

    return response


def get_performance_summary():
    """
    Get summary of performance metrics.

    Returns dict with response time statistics.
    """
    # This is a simple implementation
    # Could be enhanced with actual metric collection
    return {
        "status": "monitoring_active",
        "targets": {
            "critical_endpoints_ms": 50,
            "standard_endpoints_ms": 100
        },
        "note": "Check logs for detailed performance metrics"
    }
