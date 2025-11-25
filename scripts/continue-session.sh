#!/bin/bash
# SESSION CONTINUATION SCRIPT
# Purpose: Continue sessions after connection interruptions
# Usage: ./scripts/continue-session.sh
# Prevents "interrupted by user" errors by restoring session state

echo "🔄 SESSION CONTINUATION HANDLER"
echo "================================"
echo

# Function to check for session state
check_session_state() {
    if [ -f "SESSION_EXIT_SNAPSHOT.md" ]; then
        echo "✅ Found session exit snapshot (most recent)"
        return 0
    elif [ -f "framework/session-recovery/CURRENT_SESSION_STATE.md" ]; then
        echo "✅ Found current session state"
        return 1
    elif [ -f "framework/session-recovery/REBOOT_QUICK_START.md" ]; then
        echo "⚠️  Found quick start guide (general state)"
        return 2
    else
        echo "❌ No session state found"
        return 3
    fi
}

# Function to restore from snapshot
restore_from_snapshot() {
    echo "📸 RESTORING FROM SESSION SNAPSHOT"
    echo "===================================="
    cat SESSION_EXIT_SNAPSHOT.md
    echo
    echo "✅ Session restored from exact exit point"
    echo "💡 Continue with 'Immediate Next Action' specified above"
}

# Function to restore from current state
restore_from_current() {
    echo "📋 RESTORING FROM CURRENT SESSION STATE"
    echo "========================================"
    cat framework/session-recovery/CURRENT_SESSION_STATE.md
    echo
    echo "✅ Session state restored"
    echo "💡 Continue with next action specified above"
}

# Function to restore from quick start
restore_from_quickstart() {
    echo "🚀 LOADING PROJECT QUICK START"
    echo "==============================="
    cat framework/session-recovery/REBOOT_QUICK_START.md
    echo
    echo "⚠️  Loaded general project state (not specific session)"
    echo "💡 Use this as context but may need to determine current task"
}

# Function to emergency recovery
emergency_recovery() {
    echo "🆘 EMERGENCY RECOVERY MODE"
    echo "=========================="
    echo
    echo "📊 Analyzing project state..."
    echo

    # Git status
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "📂 GIT STATUS:"
        git status --short
        echo

        echo "📝 RECENT COMMITS:"
        git log --oneline -5
        echo

        echo "🔍 UNCOMMITTED CHANGES:"
        git diff --name-only
        echo
    fi

    # Recent files
    echo "📁 RECENTLY MODIFIED FILES:"
    find . -type f -name "*.md" -o -name "*.sh" -o -name "*.py" -o -name "*.js" | \
        xargs ls -lt 2>/dev/null | head -10
    echo

    echo "⚠️  Manual context reconstruction required"
    echo "💡 Review git status and recent files to determine next action"
}

# Main execution
echo "🔍 Checking for session state..."
echo

check_session_state
RESULT=$?

case $RESULT in
    0)
        restore_from_snapshot
        ;;
    1)
        restore_from_current
        ;;
    2)
        restore_from_quickstart
        ;;
    3)
        emergency_recovery
        ;;
esac

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 SESSION CONTINUATION COMPLETE"
echo
echo "📋 NEXT STEPS:"
echo "1. Review the restored session state above"
echo "2. Identify your immediate next action"
echo "3. Continue work from exact interruption point"
echo
echo "💡 TIP: To prevent future interruptions:"
echo "   • Update framework/session-recovery/CURRENT_SESSION_STATE.md during work"
echo "   • Run ./create_session_snapshot.sh before ending sessions"
echo "   • Use this script (./scripts/continue-session.sh) when reconnecting"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "✅ Ready to continue work!"
