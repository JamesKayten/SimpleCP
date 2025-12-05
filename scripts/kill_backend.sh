#!/bin/bash
# kill_backend.sh
# Helper script to kill any process using port 8000

echo "🔍 Checking for processes on port 8000..."

# Check if lsof is available
if ! command -v lsof &> /dev/null; then
    echo "❌ Error: lsof command not found"
    echo "   Install it with: brew install lsof"
    exit 1
fi

# Find processes using port 8000
PIDS=$(lsof -t -i:8000 2>/dev/null)

if [ -z "$PIDS" ]; then
    echo "✅ No processes found on port 8000"
    exit 0
fi

echo "🛑 Found process(es) on port 8000:"
lsof -i:8000

# Kill the processes
echo ""
echo "🔨 Killing process(es)..."
for PID in $PIDS; do
    kill "$PID" 2>/dev/null && echo "  ✅ Killed process $PID" || echo "  ⚠️  Failed to kill process $PID"
done

# Wait a moment for processes to terminate
sleep 0.5

# Check if any are still running
REMAINING=$(lsof -t -i:8000 2>/dev/null)
if [ -n "$REMAINING" ]; then
    echo ""
    echo "⚠️  Some processes didn't terminate. Force killing..."
    for PID in $REMAINING; do
        kill -9 "$PID" 2>/dev/null && echo "  ✅ Force killed process $PID" || echo "  ❌ Failed to force kill process $PID"
    done
fi

# Final check
sleep 0.3
FINAL_CHECK=$(lsof -t -i:8000 2>/dev/null)
if [ -z "$FINAL_CHECK" ]; then
    echo ""
    echo "✅ Port 8000 is now free!"
    exit 0
else
    echo ""
    echo "❌ Failed to free port 8000. Manual intervention required."
    exit 1
fi
