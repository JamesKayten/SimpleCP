#!/usr/bin/env python3
"""
Test script for SimpleCP monitoring and crash reporting.

Tests:
1. Logging functionality
2. Performance tracking
3. Error capturing
4. Analytics tracking
5. Settings loading
"""

import sys
import time
from settings import settings
from logger import logger, log_api_request, log_clipboard_event, log_performance
from monitoring import (
    track_performance,
    capture_exception,
    capture_message,
    track_clipboard_event,
    track_api_request,
    get_monitoring_stats,
    performance_tracker,
    usage_analytics,
)


def test_settings():
    """Test settings configuration."""
    print("\n" + "=" * 60)
    print("TEST 1: Settings Configuration")
    print("=" * 60)

    print(f"✓ App Name: {settings.app_name}")
    print(f"✓ App Version: {settings.app_version}")
    print(f"✓ Environment: {settings.environment}")
    print(f"✓ API Host:Port: {settings.api_host}:{settings.api_port}")
    print(f"✓ Log Level: {settings.log_level}")
    print(f"✓ Log to File: {settings.log_to_file}")
    print(f"✓ Sentry Enabled: {settings.enable_sentry}")
    print(f"✓ Performance Tracking: {settings.enable_performance_tracking}")
    print(f"✓ Usage Analytics: {settings.enable_usage_analytics}")

    print("\n✅ Settings loaded successfully")


def test_logging():
    """Test logging functionality."""
    print("\n" + "=" * 60)
    print("TEST 2: Logging Functionality")
    print("=" * 60)

    logger.debug("Debug message - testing DEBUG level")
    print("✓ DEBUG level logged")

    logger.info("Info message - testing INFO level")
    print("✓ INFO level logged")

    logger.warning("Warning message - testing WARNING level")
    print("✓ WARNING level logged")

    logger.error("Error message - testing ERROR level")
    print("✓ ERROR level logged")

    # Test convenience functions
    log_api_request("GET", "/api/test", 200, 15.5)
    print("✓ API request logged")

    log_clipboard_event("test_event", item_id="test-123")
    print("✓ Clipboard event logged")

    log_performance("test_operation", 25.5)
    print("✓ Performance logged")

    print("\n✅ All log levels working")


def test_performance_tracking():
    """Test performance tracking."""
    print("\n" + "=" * 60)
    print("TEST 3: Performance Tracking")
    print("=" * 60)

    # Test context manager
    with track_performance("test_operation_1"):
        time.sleep(0.01)  # Simulate work
    print("✓ Context manager tracking works")

    with track_performance("test_operation_2"):
        time.sleep(0.02)
    print("✓ Second operation tracked")

    # Same operation multiple times
    for i in range(3):
        with track_performance("repeated_operation"):
            time.sleep(0.005)
    print("✓ Repeated operations tracked")

    # Get stats
    stats = performance_tracker.get_stats()
    print(f"\n📊 Performance Stats:")
    for operation, metrics in stats.items():
        print(
            f"  {operation}: {metrics['count']} calls, "
            f"avg {metrics['avg_ms']:.2f}ms, "
            f"min {metrics['min_ms']:.2f}ms, "
            f"max {metrics['max_ms']:.2f}ms"
        )

    print("\n✅ Performance tracking working")


def test_usage_analytics():
    """Test usage analytics tracking."""
    print("\n" + "=" * 60)
    print("TEST 4: Usage Analytics")
    print("=" * 60)

    # Track various events
    track_clipboard_event("new_item", item_id="test-1")
    track_clipboard_event("new_item", item_id="test-2")
    print("✓ Clipboard events tracked")

    track_api_request("GET", "/api/history", 200, 10.0)
    track_api_request("POST", "/api/snippets", 201, 15.0)
    track_api_request("DELETE", "/api/history/123", 200, 5.0)
    print("✓ API requests tracked")

    # Get stats
    stats = usage_analytics.get_stats()
    print(f"\n📊 Usage Analytics:")
    for event_type, count in stats.items():
        print(f"  {event_type}: {count}")

    print("\n✅ Usage analytics working")


def test_error_capturing():
    """Test error capturing and exception handling."""
    print("\n" + "=" * 60)
    print("TEST 5: Error Capturing")
    print("=" * 60)

    # Test message capture
    capture_message("Test info message", level="info")
    print("✓ Info message captured")

    capture_message("Test warning message", level="warning")
    print("✓ Warning message captured")

    # Test exception capture without raising
    try:
        raise ValueError("Test error for monitoring")
    except Exception as e:
        capture_exception(e, context={"test": True, "operation": "test_monitoring"})
        print("✓ Exception captured with context")

    # Test different exception types
    try:
        result = 1 / 0
    except ZeroDivisionError as e:
        capture_exception(e, context={"operation": "division_test"})
        print("✓ ZeroDivisionError captured")

    try:
        missing_key = {}["nonexistent"]
    except KeyError as e:
        capture_exception(e, context={"operation": "dict_access_test"})
        print("✓ KeyError captured")

    print("\n✅ Error capturing working")
    print("⚠️  If Sentry is enabled, check your dashboard for these test errors")


def test_monitoring_stats():
    """Test monitoring statistics retrieval."""
    print("\n" + "=" * 60)
    print("TEST 6: Monitoring Statistics")
    print("=" * 60)

    stats = get_monitoring_stats()

    print("📊 Complete Monitoring Stats:")
    print(f"\n  Performance Metrics: {len(stats['performance'])} operations tracked")
    print(f"  Usage Events: {sum(stats['usage'].values())} total events")
    print(f"  Sentry Enabled: {stats['sentry_enabled']}")
    print(f"  Environment: {stats['environment']}")

    print("\n✅ Monitoring stats retrieval working")


def test_integration():
    """Test integrated monitoring scenario."""
    print("\n" + "=" * 60)
    print("TEST 7: Integration Test")
    print("=" * 60)

    print("Simulating realistic application workflow...")

    # Simulate API request handling
    with track_performance("api_get_history"):
        track_api_request("GET", "/api/history", 200, 12.5)
        time.sleep(0.01)

    # Simulate clipboard event
    track_clipboard_event("new_item", item_id="integration-test-1")

    # Simulate error during operation
    try:
        with track_performance("failing_operation"):
            raise RuntimeError("Simulated integration test error")
    except RuntimeError as e:
        capture_exception(e, context={"test": "integration", "expected": True})

    print("✓ Integrated workflow completed")
    print("\n✅ Integration test passed")


def main():
    """Run all monitoring tests."""
    print("\n" + "=" * 60)
    print("SimpleCP Monitoring & Crash Reporting Test Suite")
    print("=" * 60)

    try:
        test_settings()
        test_logging()
        test_performance_tracking()
        test_usage_analytics()
        test_error_capturing()
        test_monitoring_stats()
        test_integration()

        print("\n" + "=" * 60)
        print("✅ ALL TESTS PASSED")
        print("=" * 60)

        # Final stats
        final_stats = get_monitoring_stats()
        print("\n📊 Final Test Statistics:")
        print(f"  Total Performance Metrics: {len(final_stats['performance'])}")
        print(f"  Total Usage Events: {sum(final_stats['usage'].values())}")
        print(f"  Environment: {final_stats['environment']}")
        print(f"  Sentry Status: {'Enabled' if final_stats['sentry_enabled'] else 'Disabled'}")

        if settings.log_to_file:
            print(f"\n📝 Logs written to: {settings.log_file_path}")

        if settings.enable_sentry and settings.sentry_dsn:
            print("\n🔍 Check your Sentry dashboard for captured events")
        else:
            print("\n💡 Tip: Enable Sentry in .env to test crash reporting integration")

        return 0

    except Exception as e:
        print("\n" + "=" * 60)
        print("❌ TEST FAILED")
        print("=" * 60)
        logger.error(f"Test suite failed: {e}", exc_info=True)
        capture_exception(e, context={"test_suite": "monitoring"})
        return 1


if __name__ == "__main__":
    sys.exit(main())
