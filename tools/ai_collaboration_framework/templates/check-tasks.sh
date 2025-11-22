#!/bin/bash
# Quick task detection for AI agents

# Source the status file
if [ -f ".ai/STATUS" ]; then
    source .ai/STATUS
else
    echo "❌ .ai/STATUS not found"
    exit 1
fi

# Check task state
case "$TASK_STATE" in
    IDLE)
        echo "✅ No pending tasks. Status: IDLE"
        exit 0
        ;;
    PENDING)
        echo "🎯 PENDING TASK DETECTED"
        echo "   Priority: $PRIORITY"
        echo "   Assigned to: $ASSIGNED_TO"
        echo "   Effort: ${EFFORT_HOURS}h"
        echo "   Summary: $SUMMARY"
        echo ""
        echo "📋 Read detailed instructions:"
        echo "   cat $TASK_FILE"
        [ -n "$TASK_SECTION" ] && echo "   Focus on: $TASK_SECTION"
        exit 2
        ;;
    IN_PROGRESS)
        echo "⚙️  Task currently IN_PROGRESS"
        echo "   Summary: $SUMMARY"
        exit 3
        ;;
    BLOCKED)
        echo "🚫 Task BLOCKED - check $TASK_FILE for details"
        exit 4
        ;;
    *)
        echo "❓ Unknown task state: $TASK_STATE"
        exit 5
        ;;
esac
