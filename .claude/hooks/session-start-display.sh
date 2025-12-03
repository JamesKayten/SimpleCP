#!/bin/bash
# SessionStart display script - handles all startup display and processes
# Outputs everything to stderr so it doesn't interfere with hook JSON

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
PENDING_FILE="/tmp/branch-watcher-${REPO_NAME}.pending"

# Watcher scripts and PID files
UNIFIED_WATCHER="$REPO_ROOT/scripts/watch-all.sh"
UNIFIED_PID_FILE="/tmp/aim-watcher-${REPO_NAME}.pid"

cd "$REPO_ROOT" || exit 1

echo "" >&2
echo -e "${BOLD}================================================================================${RESET}" >&2
echo -e "${BOLD}SYNCING WITH GITHUB...${RESET}" >&2
echo -e "${BOLD}================================================================================${RESET}" >&2

# Fetch and pull latest from GitHub
git fetch origin main --quiet 2>/dev/null

LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null | cut -c1-7)
REMOTE_HASH=$(git rev-parse origin/main 2>/dev/null | cut -c1-7)

if [[ "$LOCAL_HASH" != "$REMOTE_HASH" ]]; then
    echo -e "${YELLOW}Local is behind remote. Pulling latest...${RESET}" >&2
    git pull origin main --quiet 2>/dev/null
    LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null | cut -c1-7)
fi

# Display sync status prominently
echo "" >&2
echo -e "${BOLD}┌─────────────────────────────────────┐${RESET}" >&2
echo -e "${BOLD}│         ✅ SYNC STATUS              │${RESET}" >&2
echo -e "${BOLD}├─────────────────────────────────────┤${RESET}" >&2
echo -e "${BOLD}│${RESET}  Local main:  ${CYAN}${LOCAL_HASH}${RESET}                 ${BOLD}│${RESET}" >&2
echo -e "${BOLD}│${RESET}  Remote main: ${CYAN}${REMOTE_HASH}${RESET}                 ${BOLD}│${RESET}" >&2

if [[ "$LOCAL_HASH" == "$REMOTE_HASH" ]]; then
    echo -e "${BOLD}│${RESET}  Status: ${GREEN}${BOLD}IN SYNC ✓${RESET}                  ${BOLD}│${RESET}" >&2
else
    echo -e "${BOLD}│${RESET}  Status: ${RED}${BOLD}OUT OF SYNC ✗${RESET}              ${BOLD}│${RESET}" >&2
fi
echo -e "${BOLD}└─────────────────────────────────────┘${RESET}" >&2
echo "" >&2

# Check for pending OCC branches (TCC alert)
if [ -f "$PENDING_FILE" ] && [ -s "$PENDING_FILE" ]; then
    echo -e "${BOLD}${YELLOW}┌─────────────────────────────────────────────────────────────┐${RESET}" >&2
    echo -e "${BOLD}${YELLOW}│  ⚠️  TCC ALERT: OCC BRANCHES WAITING FOR REVIEW            │${RESET}" >&2
    echo -e "${BOLD}${YELLOW}├─────────────────────────────────────────────────────────────┤${RESET}" >&2
    while read -r branch hash timestamp; do
        echo -e "${BOLD}${YELLOW}│${RESET}  Branch: ${CYAN}$branch${RESET}" >&2
        echo -e "${BOLD}${YELLOW}│${RESET}  Commit: ${YELLOW}$hash${RESET}  Time: $timestamp" >&2
    done < "$PENDING_FILE"
    echo -e "${BOLD}${YELLOW}├─────────────────────────────────────────────────────────────┤${RESET}" >&2
    echo -e "${BOLD}${YELLOW}│${RESET}  ${BOLD}AUTO-PROCESSING ENABLED - branches will be validated${RESET}" >&2
    echo -e "${BOLD}${YELLOW}└─────────────────────────────────────────────────────────────┘${RESET}" >&2
    echo "" >&2
fi

# Get branch after pull
BRANCH=$(git branch --show-current 2>/dev/null || echo "UNKNOWN")

# Watcher management - detect running watchers by process name (more reliable than PID files)
AIM_LAUNCHER="$REPO_ROOT/scripts/aim-launcher.sh"
WATCHER_LOG="/tmp/aim-watcher-${REPO_NAME}.log"
WATCHER_LOCK="/tmp/aim-watcher-${REPO_NAME}.lock"

# Check if watch-all.sh is already running for this repo (by process name, not PID file)
WATCHER_RUNNING=false
if pgrep -f "watch-all.sh.*${REPO_NAME}" > /dev/null 2>&1 || pgrep -f "watch-all.sh" > /dev/null 2>&1; then
    WATCHER_RUNNING=true
    echo -e "📡 AIM watcher ${GREEN}already running${RESET}" >&2
elif [ -f "$WATCHER_LOCK" ]; then
    # Lock file exists - check if it's stale (older than 5 minutes = watcher crashed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        LOCK_AGE=$(( $(date +%s) - $(stat -f %m "$WATCHER_LOCK") ))
    else
        LOCK_AGE=$(( $(date +%s) - $(stat -c %Y "$WATCHER_LOCK") ))
    fi
    if [ "$LOCK_AGE" -lt 300 ]; then
        WATCHER_RUNNING=true
        echo -e "📡 AIM watcher ${GREEN}running${RESET} (lock file present)" >&2
    else
        rm -f "$WATCHER_LOCK"
    fi
fi

if [ "$WATCHER_RUNNING" = false ]; then
    # No watcher running - start one
    if [[ "$OSTYPE" == "darwin"* ]] && [ -d "/Applications/iTerm.app" ] && [ -f "$AIM_LAUNCHER" ]; then
        # macOS with iTerm - use launcher (opens visible iTerm tabs)
        touch "$WATCHER_LOCK"
        "$AIM_LAUNCHER" "$REPO_ROOT" &
        sleep 1  # Give iTerm time to open
        echo -e "📺 ${GREEN}Launched iTerm2 watchers${RESET}" >&2
    elif [ -f "$UNIFIED_WATCHER" ]; then
        # Fallback to background unified watcher
        touch "$WATCHER_LOCK"
        nohup "$UNIFIED_WATCHER" > "$WATCHER_LOG" 2>&1 &
        echo $! > "$UNIFIED_PID_FILE"
        echo -e "📡 AIM watcher ${GREEN}started${RESET} (background PID: $!)" >&2
        echo -e "   📋 Logs: tail -f $WATCHER_LOG" >&2
    else
        echo -e "${YELLOW}⚠️  No watcher scripts found${RESET}" >&2
    fi
fi

echo "" >&2
echo -e "${BOLD}================================================================================${RESET}" >&2
echo -e "${BOLD}SESSION START - MANDATORY CONTEXT${RESET}" >&2
echo -e "${BOLD}================================================================================${RESET}" >&2
echo "" >&2
echo -e "REPOSITORY: ${GREEN}${BOLD}$REPO_NAME${RESET}" >&2
echo -e "BRANCH:     ${CYAN}${BOLD}$BRANCH${RESET}" >&2
echo -e "ROLE:       Check if you are ${BLUE}OCC${RESET} (developer) or ${YELLOW}TCC${RESET} (project manager)" >&2
echo "" >&2
echo -e "${BOLD}CRITICAL RULES${RESET} (from CLAUDE.md):" >&2
echo "1. ALWAYS specify repository name in every message" >&2
echo "2. ALWAYS specify branch name when discussing git operations" >&2
echo "3. ALWAYS give completion reports when finishing tasks" >&2
echo "4. NEVER say vague things like \"two merges remain\" without context" >&2
echo "" >&2
echo -e "${BOLD}================================================================================${RESET}" >&2
echo -e "${BOLD}CURRENT BOARD STATUS${RESET} ($REPO_NAME/docs/BOARD.md):" >&2
echo -e "${BOLD}================================================================================${RESET}" >&2

# Show board contents if it exists
if [ -f "$BOARD_FILE" ]; then
    cat "$BOARD_FILE" >&2
else
    echo -e "${RED}No BOARD.md found at $BOARD_FILE${RESET}" >&2
fi

# Count pending OCC branches for TCC directive
PENDING_COUNT=0
if [ -f "$PENDING_FILE" ] && [ -s "$PENDING_FILE" ]; then
    PENDING_COUNT=$(wc -l < "$PENDING_FILE" | tr -d ' ')
fi

# Check for OCC tasks on the board (tasks TCC posted for OCC to fix)
OCC_TASKS=""
if [ -f "$BOARD_FILE" ]; then
    # Extract content between "## Tasks FOR OCC" and "## Tasks FOR TCC"
    OCC_SECTION=$(sed -n '/## Tasks FOR OCC/,/## Tasks FOR TCC/p' "$BOARD_FILE" | tail -n +2 | head -n -1)
    # Strip empty lines and check if there's content OTHER than the placeholder
    OCC_CONTENT=$(echo "$OCC_SECTION" | grep -v "^$" | grep -v "^\*No pending OCC tasks\*$")
    if [ -n "$OCC_CONTENT" ]; then
        OCC_TASKS="$OCC_CONTENT"
    fi
fi

# Alert OCC if there are tasks waiting
if [ -n "$OCC_TASKS" ]; then
    echo "" >&2
    echo -e "${BOLD}${RED}┌─────────────────────────────────────────────────────────────┐${RESET}" >&2
    echo -e "${BOLD}${RED}│  🔧 OCC ALERT: TASKS WAITING FOR YOU                        │${RESET}" >&2
    echo -e "${BOLD}${RED}├─────────────────────────────────────────────────────────────┤${RESET}" >&2
    echo "$OCC_TASKS" | while IFS= read -r line; do
        echo -e "${BOLD}${RED}│${RESET}  $line" >&2
    done
    echo -e "${BOLD}${RED}├─────────────────────────────────────────────────────────────┤${RESET}" >&2
    echo -e "${BOLD}${RED}│${RESET}  ${BOLD}Action: Review and fix the issues above${RESET}" >&2
    echo -e "${BOLD}${RED}└─────────────────────────────────────────────────────────────┘${RESET}" >&2

    # Output for Claude to see (stdout) - directive for OCC to proceed automatically
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "OCC AUTO-TASK: TCC has posted diagnostic tasks for you to fix"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "TASKS FROM TCC:"
    echo "$OCC_TASKS"
    echo ""
    echo "ACTION REQUIRED: Proceed with these fixes immediately."
    echo "1. Address each issue listed above"
    echo "2. Make the necessary code changes"
    echo "3. Commit and push to your feature branch"
    echo "4. TCC will validate and merge when complete"
    echo "═══════════════════════════════════════════════════════════════════════════════"
fi

echo "" >&2
echo -e "${BOLD}================================================================================${RESET}" >&2
echo -e "${BOLD}END OF BOARD${RESET}" >&2
echo -e "${BOLD}================================================================================${RESET}" >&2

echo "" >&2
echo -e "${BOLD}${GREEN}  ████████╗ ██████╗ ██████╗     ██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗${RESET}" >&2
echo -e "${BOLD}${GREEN}  ╚══██╔══╝██╔════╝██╔════╝     ██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝${RESET}" >&2
echo -e "${BOLD}${GREEN}     ██║   ██║     ██║          ██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝ ${RESET}" >&2
echo -e "${BOLD}${GREEN}     ██║   ██║     ██║          ██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝  ${RESET}" >&2
echo -e "${BOLD}${GREEN}     ██║   ╚██████╗╚██████╗     ██║  ██║███████╗██║  ██║██████╔╝   ██║   ${RESET}" >&2
echo -e "${BOLD}${GREEN}     ╚═╝    ╚═════╝ ╚═════╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝   ${RESET}" >&2
echo -e "${BOLD}================================================================================${RESET}" >&2

echo "" >&2
echo -e "${BOLD}${GREEN}TCC AUTO-INITIALIZED${RESET}" >&2
echo "" >&2

# Auto-process if branches are pending - ACTUALLY EXECUTE, don't just instruct
if [[ $PENDING_COUNT -gt 0 ]]; then
    FIRST_BRANCH=$(head -1 "$PENDING_FILE" | cut -d' ' -f1)

    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}" >&2
    echo -e "${BOLD}${CYAN}AUTO-EXECUTING: Processing $FIRST_BRANCH${RESET}" >&2
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}" >&2
    echo "" >&2

    # Run validation
    echo -e "${YELLOW}Running validation...${RESET}" >&2
    VALIDATION_OUTPUT=$("$REPO_ROOT/scripts/tcc-validate-branch.sh" "$FIRST_BRANCH" 2>&1)
    VALIDATION_EXIT=$?

    echo "$VALIDATION_OUTPUT" >&2

    if [[ $VALIDATION_EXIT -eq 0 ]] && echo "$VALIDATION_OUTPUT" | grep -q "RESULT: NOTHING TO MERGE\|already merged"; then
        # Already merged - just clean up
        echo "" >&2
        echo -e "${GREEN}✓ Branch already merged or no new commits${RESET}" >&2

        # Remove from pending file
        if [[ -f "$PENDING_FILE" ]]; then
            grep -v "$FIRST_BRANCH" "$PENDING_FILE" > "${PENDING_FILE}.tmp" 2>/dev/null || true
            mv "${PENDING_FILE}.tmp" "$PENDING_FILE" 2>/dev/null || true
        fi

        # Output for Claude to report (stdout, not stderr)
        echo ""
        echo "AUTO-PROCESS RESULT: ALREADY_MERGED"
        echo "Branch: $FIRST_BRANCH"
        echo "Status: Branch was already merged or has no new commits"
        echo "Action: Cleaned up pending list"
        echo "Report this to the user."

    elif [[ $VALIDATION_EXIT -eq 0 ]]; then
        # Validation passed - do the merge
        echo "" >&2
        echo -e "${GREEN}✓ Validation passed - merging...${RESET}" >&2

        # Ensure on main
        git checkout main >&2 2>&1
        git pull origin main >&2 2>&1

        # Merge
        MERGE_OUTPUT=$(git merge --no-ff "origin/$FIRST_BRANCH" -m "Auto-merge: $FIRST_BRANCH" 2>&1)
        MERGE_EXIT=$?

        if [[ $MERGE_EXIT -eq 0 ]]; then
            # Push
            git push origin main >&2 2>&1
            MERGE_HASH=$(git rev-parse --short HEAD)

            # Delete remote branch
            git push origin --delete "$FIRST_BRANCH" >&2 2>&1 || true

            # Remove from pending file
            if [[ -f "$PENDING_FILE" ]]; then
                grep -v "$FIRST_BRANCH" "$PENDING_FILE" > "${PENDING_FILE}.tmp" 2>/dev/null || true
                mv "${PENDING_FILE}.tmp" "$PENDING_FILE" 2>/dev/null || true
            fi

            echo "" >&2
            echo -e "${GREEN}✓ AUTO-MERGE COMPLETE: $FIRST_BRANCH → main (${MERGE_HASH})${RESET}" >&2

            # Output for Claude to report (stdout)
            echo ""
            echo "AUTO-PROCESS RESULT: SUCCESS"
            echo "Branch: $FIRST_BRANCH"
            echo "Merged: commit $MERGE_HASH"
            echo "Action: Validated, merged to main, deleted branch"
            echo "Report this completion to the user and update BOARD.md."
        else
            echo "" >&2
            echo -e "${RED}✗ Merge failed${RESET}" >&2
            echo "$MERGE_OUTPUT" >&2

            # Output for Claude
            echo ""
            echo "AUTO-PROCESS RESULT: MERGE_FAILED"
            echo "Branch: $FIRST_BRANCH"
            echo "Error: $MERGE_OUTPUT"
            echo "Report this failure to the user."
        fi
    else
        # Validation failed
        echo "" >&2
        echo -e "${RED}✗ Validation failed${RESET}" >&2

        # Output for Claude
        echo ""
        echo "AUTO-PROCESS RESULT: VALIDATION_FAILED"
        echo "Branch: $FIRST_BRANCH"
        echo "Reason: Validation script returned non-zero exit"
        echo "Report this failure to the user."
    fi
else
    echo -e "${GREEN}✓${RESET} No pending branches - standing by" >&2

    # Output for Claude
    echo ""
    echo "AUTO-PROCESS RESULT: NO_BRANCHES"
    echo "Status: No pending OCC branches to process"
    echo "Action: Standing by for user requests"
fi

echo "" >&2
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}" >&2
echo -e "${BOLD}${CYAN}SESSION READY${RESET}" >&2
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════════════════${RESET}" >&2
