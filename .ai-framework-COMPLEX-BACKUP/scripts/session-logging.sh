#!/bin/bash
# Session Logging Functions
# Provides continuous progress tracking for session recovery after disconnections
# Source this file to use the functions: source .ai-framework/scripts/session-logging.sh

SESSION_LOG_DIR=".ai-framework/session-logs"
SESSION_LOG_FILE="$SESSION_LOG_DIR/SESSION_LOG_$(date +%Y%m%d).md"

# Initialize a new session log
# Usage: init_session_log "AGENT_NAME" "TASK_DESCRIPTION"
init_session_log() {
    local agent="$1"
    local task="$2"

    mkdir -p "$SESSION_LOG_DIR"

    cat > "$SESSION_LOG_FILE" << EOF
# Session Log - $(date '+%Y-%m-%d %H:%M:%S')

## Session Information
- **Agent:** $agent
- **Task:** $task
- **Start Time:** $(date '+%Y-%m-%d %H:%M:%S')
- **Branch:** $(git branch --show-current 2>/dev/null || echo "N/A")

---

## Progress Log

EOF

    echo "✅ Session log initialized: $SESSION_LOG_FILE"
}

# Log a progress update
# Usage: log_progress "ACTION_TITLE" "DETAILS"
log_progress() {
    local title="$1"
    local details="$2"

    if [ ! -f "$SESSION_LOG_FILE" ]; then
        echo "⚠️  Warning: Session log not initialized. Initializing now..."
        init_session_log "Unknown" "Unknown task"
    fi

    cat >> "$SESSION_LOG_FILE" << EOF
### $(date '+%H:%M:%S') - $title
$details

EOF

    echo "📝 Logged: $title"
}

# Create a checkpoint (logs + git commit)
# Usage: checkpoint "CHECKPOINT_DESCRIPTION"
checkpoint() {
    local description="$1"

    # Log the checkpoint
    log_progress "Checkpoint" "**Status:** $description"

    # Stage and commit the session log
    git add .ai-framework/session-logs/ 2>/dev/null || true

    # Commit with --no-verify to skip hooks for checkpoints
    if git diff --cached --quiet 2>/dev/null; then
        echo "⚠️  No changes to checkpoint"
    else
        git commit -m "checkpoint: $description" --no-verify --quiet 2>/dev/null || true
        echo "✅ Checkpoint created: $description"
    fi
}

# Get the last session state (useful for recovery)
# Usage: get_last_state [NUM_LINES]
get_last_state() {
    local lines="${1:-20}"

    if [ ! -f "$SESSION_LOG_FILE" ]; then
        echo "No session log found for today"
        return 1
    fi

    echo "Last $lines lines of session log:"
    echo "-----------------------------------"
    tail -n "$lines" "$SESSION_LOG_FILE"
}

# Check if there's an incomplete session from today
# Usage: check_incomplete_session
check_incomplete_session() {
    if [ -f "$SESSION_LOG_FILE" ]; then
        echo "🔄 Detected session log from today: $(date +%Y-%m-%d)"
        echo ""
        echo "Last 10 actions:"
        tail -n 30 "$SESSION_LOG_FILE" | head -n 25
        echo ""
        echo "Options:"
        echo "1. Resume from last checkpoint"
        echo "2. View full session log: cat $SESSION_LOG_FILE"
        echo "3. Start fresh (will archive old log)"
        echo ""
        return 0
    else
        echo "No incomplete session detected"
        return 1
    fi
}

# Archive current session log and start fresh
# Usage: archive_session_log
archive_session_log() {
    if [ -f "$SESSION_LOG_FILE" ]; then
        local archive_name="$SESSION_LOG_DIR/ARCHIVED_SESSION_$(date +%Y%m%d_%H%M%S).md"
        mv "$SESSION_LOG_FILE" "$archive_name"
        echo "✅ Previous session archived to: $archive_name"
    fi
}

# Display help for session logging functions
session_logging_help() {
    cat << 'EOF'
Session Logging Functions
========================

These functions help track progress continuously during work sessions,
enabling accurate recovery after unexpected disconnections.

Available Functions:
-------------------

init_session_log "AGENT" "TASK"
  Initialize a new session log
  Example: init_session_log "TCC" "Validate feature/auth branch"

log_progress "TITLE" "DETAILS"
  Log a progress update
  Example: log_progress "Validated File" "LoginForm.tsx - PASS"

checkpoint "DESCRIPTION"
  Create a checkpoint (log + git commit)
  Example: checkpoint "Validated 3 files, found 2 violations"

get_last_state [NUM_LINES]
  Show last N lines of session log (default: 20)
  Example: get_last_state 50

check_incomplete_session
  Check for incomplete session from today
  Example: check_incomplete_session

archive_session_log
  Archive current log and start fresh
  Example: archive_session_log

Usage Pattern:
-------------

# At start of work
source .ai-framework/scripts/session-logging.sh
init_session_log "TCC" "Repository cleanup task"

# During work
log_progress "Starting Task" "Moving FAQ.md to docs/guides/"
# ... do work ...
checkpoint "Moved FAQ.md successfully"

log_progress "Next Task" "Moving GETTING_STARTED.md to docs/guides/"
# ... do work ...
checkpoint "Moved GETTING_STARTED.md successfully"

# On recovery after disconnection
source .ai-framework/scripts/session-logging.sh
check_incomplete_session
get_last_state

EOF
}

# Export functions for use in other scripts
export -f init_session_log
export -f log_progress
export -f checkpoint
export -f get_last_state
export -f check_incomplete_session
export -f archive_session_log
export -f session_logging_help

echo "✅ Session logging functions loaded"
echo "   Type 'session_logging_help' for usage information"
