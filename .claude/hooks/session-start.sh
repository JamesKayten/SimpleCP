#!/bin/bash
# SessionStart hook - forces context awareness and shows board status

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
REPO_NAME=$(basename "$REPO_ROOT" 2>/dev/null || echo "UNKNOWN")
BOARD_FILE="$REPO_ROOT/docs/BOARD.md"

cd "$REPO_ROOT" || exit 1

echo ""
echo -e "${BOLD}================================================================================${RESET}"
echo -e "${BOLD}SYNCING WITH GITHUB...${RESET}"
echo -e "${BOLD}================================================================================${RESET}"

# Fetch and pull latest from GitHub
git fetch origin main --quiet 2>/dev/null

LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null | cut -c1-7)
REMOTE_HASH=$(git rev-parse origin/main 2>/dev/null | cut -c1-7)

if [[ "$LOCAL_HASH" != "$REMOTE_HASH" ]]; then
    echo -e "${YELLOW}Local is behind remote. Pulling latest...${RESET}"
    git pull origin main --quiet 2>/dev/null
    LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null | cut -c1-7)
fi

# Display sync status prominently
echo ""
echo -e "${BOLD}┌─────────────────────────────────────┐${RESET}"
echo -e "${BOLD}│         ✅ SYNC STATUS              │${RESET}"
echo -e "${BOLD}├─────────────────────────────────────┤${RESET}"
echo -e "${BOLD}│${RESET}  Local main:  ${CYAN}${LOCAL_HASH}${RESET}                 ${BOLD}│${RESET}"
echo -e "${BOLD}│${RESET}  Remote main: ${CYAN}${REMOTE_HASH}${RESET}                 ${BOLD}│${RESET}"

if [[ "$LOCAL_HASH" == "$REMOTE_HASH" ]]; then
    echo -e "${BOLD}│${RESET}  Status: ${GREEN}${BOLD}IN SYNC ✓${RESET}                  ${BOLD}│${RESET}"
else
    echo -e "${BOLD}│${RESET}  Status: ${RED}${BOLD}OUT OF SYNC ✗${RESET}              ${BOLD}│${RESET}"
fi
echo -e "${BOLD}└─────────────────────────────────────┘${RESET}"
echo ""

# Get branch after pull
BRANCH=$(git branch --show-current 2>/dev/null || echo "UNKNOWN")

# Watcher scripts and PID files
BRANCH_WATCHER="$REPO_ROOT/scripts/watch-branches.sh"
BRANCH_PID_FILE="/tmp/branch-watcher-${REPO_NAME}.pid"
BOARD_WATCHER="$REPO_ROOT/scripts/watch-board.sh"
BOARD_PID_FILE="/tmp/board-watcher-${REPO_NAME}.pid"

# Start branch watcher (alerts TCC when OCC pushes branches)
# SOUND: Hero (triumphant fanfare)
if [ -f "$BRANCH_WATCHER" ]; then
    if [ -f "$BRANCH_PID_FILE" ] && kill -0 "$(cat "$BRANCH_PID_FILE")" 2>/dev/null; then
        echo -e "📡 Branch watcher ${GREEN}running${RESET} (PID: $(cat "$BRANCH_PID_FILE")) - ${CYAN}Hero sound${RESET} = OCC branch ready"
    else
        nohup "$BRANCH_WATCHER" > /tmp/branch-watcher.log 2>&1 &
        echo $! > "$BRANCH_PID_FILE"
        echo -e "📡 Branch watcher ${GREEN}started${RESET} (PID: $!) - ${CYAN}Hero sound${RESET} = OCC branch ready"
    fi
fi

# Start board watcher (alerts OCC when TCC posts tasks)
# SOUND: Glass (soft double-chime)
if [ -f "$BOARD_WATCHER" ]; then
    if [ -f "$BOARD_PID_FILE" ] && kill -0 "$(cat "$BOARD_PID_FILE")" 2>/dev/null; then
        echo -e "📋 Board watcher ${GREEN}running${RESET} (PID: $(cat "$BOARD_PID_FILE")) - ${YELLOW}Glass sound${RESET} = TCC posted task"
    else
        nohup "$BOARD_WATCHER" > /tmp/board-watcher.log 2>&1 &
        echo $! > "$BOARD_PID_FILE"
        echo -e "📋 Board watcher ${GREEN}started${RESET} (PID: $!) - ${YELLOW}Glass sound${RESET} = TCC posted task"
    fi
fi

echo ""
echo -e "${BOLD}================================================================================${RESET}"
echo -e "${BOLD}SESSION START - MANDATORY CONTEXT${RESET}"
echo -e "${BOLD}================================================================================${RESET}"
echo ""
echo -e "REPOSITORY: ${GREEN}${BOLD}$REPO_NAME${RESET}"
echo -e "BRANCH:     ${CYAN}${BOLD}$BRANCH${RESET}"
echo -e "ROLE:       Check if you are ${BLUE}OCC${RESET} (developer) or ${YELLOW}TCC${RESET} (project manager)"
echo ""
echo -e "${BOLD}CRITICAL RULES${RESET} (from CLAUDE.md):"
echo "1. ALWAYS specify repository name in every message"
echo "2. ALWAYS specify branch name when discussing git operations"
echo "3. ALWAYS give completion reports when finishing tasks"
echo "4. NEVER say vague things like \"two merges remain\" without context"
echo ""
echo -e "${BOLD}================================================================================${RESET}"
echo -e "${BOLD}CURRENT BOARD STATUS${RESET} ($REPO_NAME/docs/BOARD.md):"
echo -e "${BOLD}================================================================================${RESET}"

# Show board contents if it exists
if [ -f "$BOARD_FILE" ]; then
    cat "$BOARD_FILE"
else
    echo -e "${RED}No BOARD.md found at $BOARD_FILE${RESET}"
fi

echo ""
echo -e "${BOLD}================================================================================${RESET}"
echo -e "${BOLD}END OF BOARD${RESET} - Proceed with your role (OCC or TCC)"
echo -e "${BOLD}================================================================================${RESET}"

exit 0
