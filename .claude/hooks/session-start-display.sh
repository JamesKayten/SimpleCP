#!/bin/bash
# Session Start Display - Informative status for deployed AIM repos

# Colors for terminal output (to stderr)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
REPO_NAME=$(basename "$REPO_ROOT" 2>/dev/null || echo "UNKNOWN")
UNIFIED_WATCHER="$REPO_ROOT/scripts/watch-all.sh"
UNIFIED_PID_FILE="/tmp/aim-watcher-${REPO_NAME}.pid"
WATCHER_LOG="/tmp/aim-watcher-${REPO_NAME}.log"

cd "$REPO_ROOT" || exit 1

echo ""
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${CYAN}    AIM DEPLOYED REPOSITORY: $REPO_NAME${RESET}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${RESET}"

# Quick sync check
git fetch origin --quiet 2>/dev/null || true

# Check for OCC branches
OCC_BRANCHES=$(git branch -r 2>/dev/null | grep 'origin/claude/' | wc -l | xargs)

# Show branch status
if [ "$OCC_BRANCHES" -gt 0 ]; then
    echo -e "${YELLOW}📋 $OCC_BRANCHES OCC branch(es) found - use 'wr' to process${RESET}"
    echo "SessionStart:startup hook success: FOUND_BRANCHES"
    echo "Status: $OCC_BRANCHES OCC branch(es) found"
    echo "Action: Use 'wr' or '/works-ready' to process"
else
    echo -e "${GREEN}✓ No pending OCC branches${RESET}"
    echo "SessionStart:startup hook success: NO_BRANCHES"
    echo "Status: No pending OCC branches"
    echo "Action: Standing by"
fi

# Watcher management - detect by process name (more reliable than PID files)
WATCHER_RUNNING=false

# Check if watch-all.sh is already running (by process name)
if pgrep -f "watch-all.sh" > /dev/null 2>&1; then
    WATCHER_RUNNING=true
    echo -e "📡 AIM watcher ${GREEN}already running${RESET}"
    echo "Watcher: ALREADY RUNNING"
fi

# Start watcher if not running and script exists
if [ "$WATCHER_RUNNING" = false ]; then
    if [ -f "$UNIFIED_WATCHER" ]; then
        [ ! -x "$UNIFIED_WATCHER" ] && chmod +x "$UNIFIED_WATCHER"
        # Start watcher in background, fully detached
        nohup "$UNIFIED_WATCHER" > "$WATCHER_LOG" 2>&1 &
        NEW_PID=$!
        echo "$NEW_PID" > "$UNIFIED_PID_FILE"

        # Verify it actually started
        sleep 0.5
        if ps -p "$NEW_PID" > /dev/null 2>&1; then
            echo -e "📡 AIM watcher ${GREEN}started${RESET} (background PID: $NEW_PID)"
            echo "Watcher: STARTED (PID: $NEW_PID)"
            echo "Logs: $WATCHER_LOG"
        else
            echo -e "${RED}⚠️  Watcher failed to start - check $WATCHER_LOG${RESET}"
            echo "Watcher: FAILED TO START - check $WATCHER_LOG"
        fi
    else
        echo -e "${YELLOW}⚠️  No watcher script at: $UNIFIED_WATCHER${RESET}"
        echo "Watcher: NOT FOUND at $UNIFIED_WATCHER"
        echo "Fix: Run 'aim init --force' from AIM repo"
    fi
fi

echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${RESET}"
echo ""
