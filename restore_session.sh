#!/bin/bash
# EXACT SESSION RESTORATION
# Purpose: Instantly restore exact work state from session snapshot
# Usage: ./restore_session.sh
# Project: SimpleCP
# Auto-deployed by Avery's AI Collaboration Framework

echo "🔄 EXACT SESSION RESTORATION"
echo "============================="
echo "📁 Project: SimpleCP"
echo

# Show Claude behavior rules (always use central copy)
if [ -f "/Volumes/User_Smallfavor/Users/Smallfavor/Documents/AI-Collaboration-Management/CLAUDE_BEHAVIOR_RULES.md" ]; then
    echo "🤖 CLAUDE BEHAVIOR RULES (READ FIRST):"
    echo "======================================"
    cat "/Volumes/User_Smallfavor/Users/Smallfavor/Documents/AI-Collaboration-Management/CLAUDE_BEHAVIOR_RULES.md"
    echo
fi

# Check for session snapshots
if [ -f "SESSION_EXIT_SNAPSHOT.md" ]; then
    echo "✅ FOUND SESSION EXIT SNAPSHOT"
    echo "📸 Restoring exact work state..."
    echo

    # Display exact work context
    echo "🎯 EXACT WORK STATE AT INTERRUPTION:"
    echo "======================================"
    cat SESSION_EXIT_SNAPSHOT.md
    echo
    echo "✅ SESSION CONTEXT RESTORED"
    echo "💡 Continue with the specified 'Immediate Next Action' above"

elif [ -f ".ai-framework/session-recovery/CURRENT_SESSION_STATE.md" ]; then
    echo "⚠️ FOUND PARTIAL SESSION STATE"
    echo "📋 Restoring available work context..."
    echo

    echo "🔄 CURRENT WORK STATE:"
    echo "======================"
    cat .ai-framework/session-recovery/CURRENT_SESSION_STATE.md
    echo
    echo "⚡ PARTIAL RESTORATION COMPLETE"
    echo "💡 Continue with current work or create new snapshot for better tracking"

elif [ -f ".ai-framework/session-recovery/REBOOT_QUICK_START.md" ]; then
    echo "📋 FOUND QUICK START GUIDE"
    echo "🚀 Using general project status..."
    echo

    echo "⚡ PROJECT QUICK START:"
    echo "======================="
    cat .ai-framework/session-recovery/REBOOT_QUICK_START.md
    echo
    echo "🎯 GENERAL RESTORATION COMPLETE"
    echo "💡 Use this as starting point, but may not reflect exact session state"

else
    echo "❌ NO SESSION SNAPSHOTS FOUND"
    echo "🔍 Searching for any project state..."

    if [ -f "PROJECT_STATE.md" ]; then
        echo "📚 Found historical project state (not current session)"
        echo "⚠️ This may not reflect exact work state when session ended"
        echo
        echo "📖 HISTORICAL PROJECT STATE:"
        echo "============================"
        head -50 PROJECT_STATE.md
        echo
        echo "💡 RECOMMENDATION: Create session snapshot next time using ./create_session_snapshot.sh"
    elif [ -f ".ai-framework/project-state/PROJECT_STATE.md" ]; then
        echo "📚 Found project state in framework structure"
        echo "⚠️ This may not reflect exact work state when session ended"
        echo
        head -50 .ai-framework/project-state/PROJECT_STATE.md
    else
        echo "❌ No project information found"
        echo "🆘 EMERGENCY RECOVERY:"
        echo "• Run: find . -name '*.md' -type f"
        echo "• Look for any project documentation"
        echo "• Check: ls -la for project structure"
    fi
fi

echo
echo "🛠️ RECOVERY TOOLS AVAILABLE:"
echo "• ./session_recovery.sh                      # Auto-detect project type and status"
echo "• ./create_session_snapshot.sh               # Create snapshot for next session"
echo "• cat .ai-framework/session-recovery/REBOOT_QUICK_START.md  # General project quick start"
echo "• cat .ai-framework/session-recovery/CURRENT_SESSION_STATE.md  # Real-time session state (if exists)"
echo
echo "✅ RESTORATION COMPLETE - Ready to continue work immediately!"
echo "📁 Project: SimpleCP | Framework: Avery's AI Collaboration Hack"