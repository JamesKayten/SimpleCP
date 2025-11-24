#!/bin/bash
# Automatic Framework Communication Monitor
# Continuously monitors for PING/PONG communications between AI instances

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AI_DIR="$PROJECT_ROOT/.ai"
PING_FILE="$AI_DIR/PING_TEST.md"
PONG_FILE="$AI_DIR/PONG_RESPONSE.md"
STATUS_FILE="$AI_DIR/AUTO_COMM_STATUS.md"
LOG_FILE="$AI_DIR/communication.log"

# Configuration
CHECK_INTERVAL=30  # seconds between checks
MAX_CHECKS=120     # maximum checks (1 hour at 30-second intervals)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🤖 Starting Automatic Communication Monitor${NC}"
echo "Monitoring: $PING_FILE and $PONG_FILE"
echo "Check interval: ${CHECK_INTERVAL}s | Max duration: $((MAX_CHECKS * CHECK_INTERVAL / 60)) minutes"
echo "---"

# Initialize status tracking
LAST_PING_HASH=""
LAST_PONG_HASH=""
CHECK_COUNT=0

# Get initial file hashes if files exist
if [[ -f "$PING_FILE" ]]; then
    LAST_PING_HASH=$(md5 -q "$PING_FILE" 2>/dev/null || echo "")
fi
if [[ -f "$PONG_FILE" ]]; then
    LAST_PONG_HASH=$(md5 -q "$PONG_FILE" 2>/dev/null || echo "")
fi

# Function to log with timestamp
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Function to update status file
update_status() {
    cat > "$STATUS_FILE" << EOF
# 🤖 Automatic Communication Monitor Status

**Last Updated:** $(date '+%Y-%m-%d %H:%M:%S')
**Status:** $1
**Check Count:** $CHECK_COUNT / $MAX_CHECKS
**Runtime:** $((CHECK_COUNT * CHECK_INTERVAL / 60)) minutes

## Latest Activity
$2

## Configuration
- **Check Interval:** ${CHECK_INTERVAL} seconds
- **Max Runtime:** $((MAX_CHECKS * CHECK_INTERVAL / 60)) minutes
- **Monitoring Files:**
  - PING: \`$PING_FILE\`
  - PONG: \`$PONG_FILE\`

## Log File
Real-time log: \`$LOG_FILE\`
EOF
}

# Function to check for PING updates
check_ping_updates() {
    if [[ -f "$PING_FILE" ]]; then
        local current_hash=$(md5 -q "$PING_FILE" 2>/dev/null || echo "")
        if [[ "$current_hash" != "$LAST_PING_HASH" && -n "$current_hash" ]]; then
            echo -e "${YELLOW}🏓 NEW PING DETECTED!${NC}"
            log_message "🏓 NEW PING detected - file changed"

            # Extract test ID and content preview
            local test_id=$(grep -o "Test ID: PING-[0-9]*" "$PING_FILE" 2>/dev/null || echo "Unknown")
            local math_problem=$(grep -E "[0-9]+ [×x*+\-] [0-9]+ = \?" "$PING_FILE" 2>/dev/null | head -1 || echo "No calculation found")

            echo "  Test ID: $test_id"
            echo "  Math Problem: $math_problem"

            update_status "🏓 NEW PING DETECTED" "**PING Update:** $test_id detected\\n**Math Problem:** $math_problem\\n**Action Required:** OCC should respond with PONG"

            LAST_PING_HASH="$current_hash"
            return 0
        fi
    fi
    return 1
}

# Function to check for PONG updates
check_pong_updates() {
    if [[ -f "$PONG_FILE" ]]; then
        local current_hash=$(md5 -q "$PONG_FILE" 2>/dev/null || echo "")
        if [[ "$current_hash" != "$LAST_PONG_HASH" && -n "$current_hash" ]]; then
            echo -e "${GREEN}🎾 NEW PONG RECEIVED!${NC}"
            log_message "🎾 NEW PONG received - response detected"

            # Extract response details
            local test_id=$(grep -o "Test ID: PONG-[0-9]*\|PONG-[0-9]*" "$PONG_FILE" 2>/dev/null || echo "Unknown")
            local calculation=$(grep -E "[0-9,]+ = [0-9,]+" "$PONG_FILE" 2>/dev/null | head -1 || echo "No calculation found")
            local from_ai=$(grep -o "From:** [A-Z]*" "$PONG_FILE" 2>/dev/null || echo "Unknown AI")

            echo "  Response ID: $test_id"
            echo "  Calculation: $calculation"
            echo "  From: $from_ai"

            update_status "🎾 NEW PONG RECEIVED" "**PONG Response:** $test_id\\n**Calculation:** $calculation\\n**From:** $from_ai\\n**Status:** Communication successful!"

            LAST_PONG_HASH="$current_hash"
            return 0
        fi
    fi
    return 1
}

# Function to check for remote updates
check_remote_updates() {
    cd "$PROJECT_ROOT" 2>/dev/null || return 1

    # Fetch remote changes quietly
    if git fetch origin >/dev/null 2>&1; then
        # Check if main branch has new commits
        local behind=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
        if [[ "$behind" -gt 0 ]]; then
            echo -e "${BLUE}📡 Remote updates detected: $behind new commits${NC}"
            log_message "📡 Remote updates detected: $behind commits behind origin/main"
            return 0
        fi
    fi
    return 1
}

# Main monitoring loop
log_message "🚀 Starting automatic communication monitor"
update_status "🟢 MONITORING ACTIVE" "**Monitor Started:** $(date '+%Y-%m-%d %H:%M:%S')\\n**Status:** Actively checking for PING/PONG updates"

while [[ $CHECK_COUNT -lt $MAX_CHECKS ]]; do
    CHECK_COUNT=$((CHECK_COUNT + 1))

    echo -e "${BLUE}Check $CHECK_COUNT/$MAX_CHECKS${NC} ($(date '+%H:%M:%S'))"

    # Check for file changes
    ping_updated=$(check_ping_updates && echo "1" || echo "0")
    pong_updated=$(check_pong_updates && echo "1" || echo "0")
    remote_updated=$(check_remote_updates && echo "1" || echo "0")

    if [[ "$ping_updated" == "1" || "$pong_updated" == "1" || "$remote_updated" == "1" ]]; then
        echo -e "${GREEN}✨ Activity detected! Continuing monitoring...${NC}"
        log_message "✨ Communication activity detected - continuing monitoring"
    else
        echo "   No changes detected"
    fi

    # Update status periodically
    if [[ $((CHECK_COUNT % 10)) == 0 ]]; then
        update_status "🟢 MONITORING ACTIVE" "**Check:** $CHECK_COUNT/$MAX_CHECKS\\n**Last Check:** $(date '+%H:%M:%S')\\n**Status:** No new activity in last $((10 * CHECK_INTERVAL / 60)) minutes"
    fi

    sleep $CHECK_INTERVAL
done

# Monitoring complete
echo -e "${YELLOW}⏰ Monitoring period complete (${MAX_CHECKS} checks)${NC}"
log_message "⏰ Automatic monitoring period complete after $CHECK_COUNT checks"
update_status "⏰ MONITORING COMPLETE" "**Completed:** $(date '+%Y-%m-%d %H:%M:%S')\\n**Total Checks:** $CHECK_COUNT\\n**Duration:** $((CHECK_COUNT * CHECK_INTERVAL / 60)) minutes\\n**Status:** Monitoring period finished"

echo "Monitor logs saved to: $LOG_FILE"
echo "Status file updated: $STATUS_FILE"