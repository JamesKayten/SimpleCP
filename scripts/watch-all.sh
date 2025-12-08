#!/bin/bash
# watch-all.sh - Combined Branch and Board watcher in single terminal
#
# Usage: ./scripts/watch-all.sh [interval_seconds]
# Default interval: 30 seconds

# Load common watcher functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/watcher-common.sh"

INTERVAL=${1:-30}
REPO_ROOT=$(get_repo_root)
REPO_NAME=$(get_repo_name)
BRANCH_PATTERN="claude/*"
BOARD_FILE="docs/BOARD.md"
STATE_FILE="/tmp/branch-watcher-${REPO_NAME}.state"
PENDING_FILE="/tmp/branch-watcher-${REPO_NAME}.pending"

# Audio alerts - use common library functions
play_branch_alert() {
    play_hero_sound
}

play_board_alert() {
    play_glass_sound
}

clear
echo -e "${BOLD}${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              AIM UNIFIED WATCHER                          ║"
echo "║         Branch + Board Monitoring                         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "Repository: ${GREEN}${BOLD}$REPO_NAME${RESET}"
echo -e "Polling:    Every ${INTERVAL}s"
echo ""
echo -e "${BOLD}Monitoring:${RESET}"
echo -e "  🌿 OCC pushes new branch  → ${GREEN}Hero${RESET} sound (work ready for TCC)"
echo -e "  📋 TCC merges/updates     → ${YELLOW}Glass${RESET} sound (board + branch cleanup)"
echo ""
echo -e "Press ${BOLD}Ctrl+C${RESET} to stop"
echo ""
echo -e "${BOLD}════════════════════════════════════════════════════════════${RESET}"

cd "$REPO_ROOT" || exit 1

# Initialize states
git fetch origin --quiet 2>/dev/null
git for-each-ref --format='%(refname:short) %(objectname:short)' refs/remotes/origin/$BRANCH_PATTERN 2>/dev/null > "$STATE_FILE"
LAST_BOARD_HASH=$(git rev-parse origin/main:$BOARD_FILE 2>/dev/null)

# Clear pending file at start
rm -f "$PENDING_FILE"

# TCC activity buffer - deletions wait for board update
TCC_PENDING_DELETIONS=""

CYCLE=0
while true; do
    sleep "$INTERVAL"
    CYCLE=$((CYCLE + 1))

    # Fetch from GitHub
    if ! git fetch origin --quiet 2>/dev/null; then
        echo -e "\n[$(date +%H:%M:%S)] ${YELLOW}⚠️  Network error - retrying...${RESET}"
        continue
    fi

    CHANGES_FOUND=false
    NEW_BRANCH_FOUND=false

    # ═══════════════════════════════════════════════════════════
    # CHECK BRANCHES
    # ═══════════════════════════════════════════════════════════
    CURRENT_STATE=$(git for-each-ref --format='%(refname:short) %(objectname:short)' refs/remotes/origin/$BRANCH_PATTERN 2>/dev/null)
    PREVIOUS_STATE=$(cat "$STATE_FILE" 2>/dev/null)

    if [[ "$CURRENT_STATE" != "$PREVIOUS_STATE" ]]; then
        # Check if there are NEW branches (not just deletions)
        NEW_BRANCHES=""
        while read branch hash; do
            if [[ -n "$branch" ]] && ! grep -q "$hash" "$STATE_FILE" 2>/dev/null; then
                NEW_BRANCHES="$NEW_BRANCHES$branch $hash\n"
                NEW_BRANCH_FOUND=true
            fi
        done <<< "$CURRENT_STATE"

        if [[ "$NEW_BRANCH_FOUND" == true ]]; then
            CHANGES_FOUND=true
            echo ""
            echo -e "${BOLD}${GREEN}┌─────────────────────────────────────────────────────────────┐${RESET}"
            echo -e "${BOLD}${GREEN}│  🌿 [$(date +%H:%M:%S)] OCC BRANCH READY FOR REVIEW                 │${RESET}"
            echo -e "${BOLD}${GREEN}└─────────────────────────────────────────────────────────────┘${RESET}"

            # Show new branches
            echo "$CURRENT_STATE" | while read branch hash; do
                branch_short=$(echo "$branch" | sed 's|origin/||')
                if [[ -n "$branch" ]] && ! grep -q "$hash" "$STATE_FILE" 2>/dev/null; then
                    echo -e "  ${BOLD}${GREEN}⭐ NEW:${RESET} ${CYAN}$branch_short${RESET} (${YELLOW}$hash${RESET})"
                    echo "$branch_short $hash $(date +%Y-%m-%d_%H:%M:%S)" >> "$PENDING_FILE"
                    show_notification "🌿 OCC Branch Ready" "$branch_short"
                fi
            done

            echo -e "  ${BOLD}Action:${RESET} Start TCC session or run ${CYAN}/works-ready${RESET}"
            echo ""
            play_branch_alert
        fi
        # Branch deletions handled silently - TCC merge triggers board update

        # Always update state
        echo "$CURRENT_STATE" > "$STATE_FILE"
    fi

    # ═══════════════════════════════════════════════════════════
    # CHECK TCC ACTIVITY (Board update triggers combined alert)
    # ═══════════════════════════════════════════════════════════
    CURRENT_BOARD_HASH=$(git rev-parse origin/main:$BOARD_FILE 2>/dev/null)

    # Buffer deleted branches (TCC merged them) - don't alert yet
    if [[ -n "$PREVIOUS_STATE" ]]; then
        while read branch hash; do
            if [[ -n "$branch" ]] && ! echo "$CURRENT_STATE" | grep -q "$branch"; then
                branch_short=$(echo "$branch" | sed 's|origin/||')
                # Only add if not already in buffer
                if [[ ! "$TCC_PENDING_DELETIONS" =~ "$branch_short" ]]; then
                    TCC_PENDING_DELETIONS="$TCC_PENDING_DELETIONS$branch_short "
                fi
            fi
        done <<< "$PREVIOUS_STATE"
    fi

    # Board update detected - show combined alert NOW (board update always comes last)
    if [[ "$CURRENT_BOARD_HASH" != "$LAST_BOARD_HASH" ]]; then
        CHANGES_FOUND=true
        LAST_BOARD_HASH="$CURRENT_BOARD_HASH"

        echo ""
        echo -e "${BOLD}${YELLOW}┌─────────────────────────────────────────────────────────────┐${RESET}"
        echo -e "${BOLD}${YELLOW}│  📋 [$(date +%H:%M:%S)] TCC ACTIVITY                                │${RESET}"
        echo -e "${BOLD}${YELLOW}└─────────────────────────────────────────────────────────────┘${RESET}"

        # Show any buffered branch deletions
        if [[ -n "$TCC_PENDING_DELETIONS" ]]; then
            echo -e "  ${BOLD}Merged & Deleted:${RESET}"
            for branch in $TCC_PENDING_DELETIONS; do
                echo -e "    ✅ ${CYAN}$branch${RESET}"
            done
        fi

        echo -e "  ${BOLD}Board Updated:${RESET} Check ${CYAN}docs/BOARD.md${RESET} for details"
        echo -e "  ${BOLD}Action:${RESET} git pull origin main"
        echo ""
        play_board_alert

        # Clear the deletion buffer
        TCC_PENDING_DELETIONS=""
    fi

    # Show heartbeat if no changes
    if [[ "$CHANGES_FOUND" == false ]]; then
        # Show status every 10 cycles (5 min at 30s interval)
        if [[ $((CYCLE % 10)) -eq 0 ]]; then
            PENDING_COUNT=$(cat "$PENDING_FILE" 2>/dev/null | wc -l | tr -d ' ')
            BRANCH_COUNT=$(echo "$CURRENT_STATE" | grep -c "claude/" 2>/dev/null || echo "0")
            echo -e "\n[$(date +%H:%M:%S)] ${BOLD}Status:${RESET} ${GREEN}$BRANCH_COUNT${RESET} branches, ${YELLOW}$PENDING_COUNT${RESET} pending"
        else
            echo -n "."
        fi
    fi
done
