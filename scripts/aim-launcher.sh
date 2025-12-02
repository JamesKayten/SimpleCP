#!/bin/bash
# aim-launcher.sh - AI Collaboration Management Launcher
#
# Opens iTerm2 with multiple tabs running watcher scripts:
# - Tab 1: Build Watcher (monitors Swift/Xcode builds)
# - Tab 2: Branch Watcher (monitors OCC branches)
# - Tab 3: Board Watcher (monitors BOARD.md for TCC tasks)
#
# Usage: ./scripts/aim-launcher.sh [project_path]

set -e

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${CYAN}   AIM LAUNCHER - AI Collaboration Management${RESET}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════${RESET}"
echo ""

# Determine project path
if [ -n "$1" ]; then
    PROJECT_PATH="$1"
else
    PROJECT_PATH=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo -e "${RED}ERROR: Not in a git repository${RESET}"
        echo "Usage: $0 [project_path]"
        exit 1
    }
fi

# Validate project path
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}ERROR: Project path does not exist: $PROJECT_PATH${RESET}"
    exit 1
fi

SCRIPTS_DIR="$PROJECT_PATH/scripts"
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo -e "${RED}ERROR: Scripts directory not found: $SCRIPTS_DIR${RESET}"
    exit 1
fi

PROJECT_NAME=$(basename "$PROJECT_PATH")

# Check if this is a Swift project
HAS_SWIFT=false
if [ -f "$PROJECT_PATH/Package.swift" ] || \
   ls "$PROJECT_PATH"/*.xcodeproj 1>/dev/null 2>&1 || \
   ls "$PROJECT_PATH"/*.xcworkspace 1>/dev/null 2>&1; then
    HAS_SWIFT=true
fi

echo -e "${GREEN}✓${RESET} Project: ${CYAN}$PROJECT_NAME${RESET}"
echo -e "${GREEN}✓${RESET} Path: ${CYAN}$PROJECT_PATH${RESET}"
if [ "$HAS_SWIFT" = true ]; then
    echo -e "${GREEN}✓${RESET} Swift project detected - build watcher will run"
else
    echo -e "${YELLOW}⚠${RESET}  No Swift project - build watcher will be skipped"
fi
echo ""

# Check if iTerm2 is available
if [ ! -d "/Applications/iTerm.app" ]; then
    echo -e "${RED}ERROR: iTerm2 not found${RESET}"
    echo "Install iTerm2 from https://iterm2.com/"
    exit 1
fi

# Check if required scripts exist
REQUIRED_SCRIPTS=(
    "watch-build.sh"
    "watch-all.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPTS_DIR/$script" ]; then
        echo -e "${YELLOW}⚠️  Warning: $script not found${RESET}"
    fi
done

echo -e "${CYAN}Launching iTerm2 with watchers...${RESET}"
echo ""

# Create iTerm2 AppleScript to open tabs without stealing focus
osascript <<EOF
-- Save the frontmost application before doing anything
tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
end tell

tell application "iTerm"
    -- Create new window (will temporarily take focus)
    set newWindow to (create window with default profile)

    tell current session of newWindow
        -- Tab 1: Build Watcher (only if Swift project exists)
        set name to "🔨 Build Watcher"
        write text "cd '$PROJECT_PATH' && clear"
        write text "'$SCRIPTS_DIR/watch-build.sh' '$PROJECT_PATH'"
    end tell

    -- Tab 2: Unified Watcher (Branch + Board combined)
    tell newWindow
        set newTab to (create tab with default profile)
        tell current session of newTab
            set name to "📡 AIM Watcher"
            write text "cd '$PROJECT_PATH' && clear"
            write text "'$SCRIPTS_DIR/watch-all.sh'"
        end tell
    end tell

    -- Focus the unified watcher tab
    tell newWindow
        select tab 2
    end tell

end tell

-- Restore focus to the original application (Claude terminal)
tell application frontApp to activate
EOF

echo ""
echo -e "${BOLD}${GREEN}✨ AIM LAUNCHER COMPLETE${RESET}"
echo ""
echo -e "${CYAN}iTerm2 tabs opened:${RESET}"
echo -e "  1. ${BOLD}🔨 Build Watcher${RESET} - Monitors builds (Basso = error, Blow = success)"
echo -e "  2. ${BOLD}📡 AIM Watcher${RESET} - Branch + Board unified (Hero/Glass sounds)"
echo ""
echo -e "${YELLOW}Audio Alert Legend:${RESET}"
echo -e "  • ${BOLD}Hero${RESET} = OCC finished work, branch ready"
echo -e "  • ${BOLD}Glass${RESET} = Board updated (TCC posted task or completed work)"
echo -e "  • ${BOLD}Basso${RESET} = Build error"
echo -e "  • ${BOLD}Blow${RESET} = Build success"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${RESET}"
echo -e "${CYAN}Watchers monitoring in background${RESET}"
echo -e "${CYAN}═══════════════════════════════════════════════════${RESET}"
