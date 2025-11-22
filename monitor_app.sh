#!/bin/bash

echo "🔍 SimpleCP Real-Time Monitoring Started"
echo "=========================================="
echo "Time: $(date)"
echo "SimpleCP PID: $(pgrep SimpleCP)"
echo ""

# Monitor network connections to our API
echo "🌐 API Connections:"
netstat -an | grep 127.0.0.1.8000
echo ""

# Monitor system logs for SimpleCP
echo "📋 Watching for SimpleCP logs..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Use a different log approach
tail -f /var/log/system.log | grep -i simplecp &
LOG_PID=$!

# Also monitor Console logs if available
log stream --level debug --predicate 'processImagePath ENDSWITH "SimpleCP"' 2>/dev/null &
STREAM_PID=$!

# Monitor for crashes
log show --last 1m --predicate 'eventType == "logEvent" AND processImagePath ENDSWITH "SimpleCP"' --style compact &
CRASH_PID=$!

# Cleanup function
cleanup() {
    echo ""
    echo "🛑 Stopping monitoring..."
    kill $LOG_PID $STREAM_PID $CRASH_PID 2>/dev/null
    exit 0
}

trap cleanup SIGINT

# Keep the script running
wait