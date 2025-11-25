#!/bin/bash
# watch-board.sh - Polls GitHub for BOARD.md changes and plays audio alert
#
# Usage: ./scripts/watch-board.sh [interval_seconds]
# Default interval: 30 seconds

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

INTERVAL=${1:-30}
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
REPO_NAME=$(basename "$REPO_ROOT" 2>/dev/null || echo "UNKNOWN")
BOARD_FILE="docs/BOARD.md"

# Audio alert function (cross-platform)
# SOUND: Glass (soft chime) - TCC posted task, OCC has work to do
play_alert() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Glass sound = board updated (task waiting)
        afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
        sleep 0.3
        afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
    elif command -v paplay &>/dev/null; then
        paplay /usr/share/sounds/freedesktop/stereo/message.oga 2>/dev/null &
    elif command -v aplay &>/dev/null; then
        aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null &
    else
        echo -e "\a"
    fi
}

echo -e "${BOLD}==================================${RESET}"
echo -e "${BOLD}BOARD WATCHER${RESET} - ${GREEN}$REPO_NAME${RESET}"
echo -e "${BOLD}==================================${RESET}"
echo -e "Polling GitHub every ${INTERVAL}s for ${CYAN}BOARD.md${RESET} changes"
echo "Press Ctrl+C to stop"
echo ""

cd "$REPO_ROOT" || exit 1

# Get initial state
git fetch origin main --quiet 2>/dev/null
LAST_HASH=$(git rev-parse origin/main:$BOARD_FILE 2>/dev/null)

while true; do
    sleep "$INTERVAL"

    # Fetch latest from GitHub
    if ! git fetch origin main --quiet 2>/dev/null; then
        echo -e "[$(date +%H:%M:%S)] ${YELLOW}⚠️  Network error - retrying...${RESET}"
        continue
    fi

    # Check if board changed
    CURRENT_HASH=$(git rev-parse origin/main:$BOARD_FILE 2>/dev/null)

    if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
        echo ""
        echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${YELLOW}🔔 [$(date +%H:%M:%S)] BOARD.MD CHANGED!${RESET}"
        echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════════${RESET}"
        echo ""
        echo -e "${BOLD}Action:${RESET} git pull origin main"
        echo -e "${BOLD}Then:${RESET} Check ${CYAN}docs/BOARD.md${RESET} for new tasks"
        echo ""
        echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════════${RESET}"
        echo ""
        play_alert
        LAST_HASH="$CURRENT_HASH"
    else
        echo -n "."  # Heartbeat indicator
    fi
done
