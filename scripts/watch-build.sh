#!/bin/bash
# watch-build.sh - Monitors Swift/Xcode build output for errors
#
# Usage: ./scripts/watch-build.sh [project_path] [interval_seconds]
# Default interval: 10 seconds

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

PROJECT_PATH="${1:-.}"
INTERVAL=${2:-10}
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
REPO_NAME=$(basename "$REPO_ROOT" 2>/dev/null || echo "UNKNOWN")
BUILD_LOG="/tmp/build-watcher-${REPO_NAME}.log"
LAST_BUILD_HASH="/tmp/build-watcher-${REPO_NAME}.hash"

# Audio alert function - Error sound
play_error_alert() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Basso sound = build error (low, serious tone)
        afplay /System/Library/Sounds/Basso.aiff 2>/dev/null &
        sleep 0.3
        afplay /System/Library/Sounds/Basso.aiff 2>/dev/null &
    elif command -v paplay &>/dev/null; then
        paplay /usr/share/sounds/freedesktop/stereo/dialog-error.oga 2>/dev/null &
    else
        echo -e "\a"
    fi
}

# Audio alert function - Success sound
play_success_alert() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Blow sound = build success
        afplay /System/Library/Sounds/Blow.aiff 2>/dev/null &
    elif command -v paplay &>/dev/null; then
        paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
    else
        echo -e "\a"
    fi
}

# Find Xcode project or Swift package
find_project() {
    if [ -f "$PROJECT_PATH/Package.swift" ]; then
        echo "swift_package"
    elif ls "$PROJECT_PATH"/*.xcodeproj 1>/dev/null 2>&1; then
        echo "xcode_project"
    elif ls "$PROJECT_PATH"/*.xcworkspace 1>/dev/null 2>&1; then
        echo "xcode_workspace"
    else
        echo "unknown"
    fi
}

# Run build and capture output
run_build() {
    local project_type=$(find_project)

    case $project_type in
        swift_package)
            cd "$PROJECT_PATH" && swift build 2>&1
            ;;
        xcode_project)
            local proj=$(ls "$PROJECT_PATH"/*.xcodeproj | head -1)
            xcodebuild -project "$proj" -scheme "$(basename "$proj" .xcodeproj)" build 2>&1
            ;;
        xcode_workspace)
            local ws=$(ls "$PROJECT_PATH"/*.xcworkspace | head -1)
            xcodebuild -workspace "$ws" -scheme "$(basename "$ws" .xcworkspace)" build 2>&1
            ;;
        *)
            echo "No Swift package or Xcode project found in $PROJECT_PATH"
            return 1
            ;;
    esac
}

# Parse build output for errors and warnings
parse_build_output() {
    local output="$1"
    local errors=$(echo "$output" | grep -E "error:|fatal error:" | head -20)
    local warnings=$(echo "$output" | grep -E "warning:" | head -10)
    local error_count=$(echo "$output" | grep -cE "error:|fatal error:")
    local warning_count=$(echo "$output" | grep -cE "warning:")

    if [ $error_count -gt 0 ]; then
        echo ""
        echo -e "${BOLD}${RED}════════════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${RED}🔴 BUILD FAILED - $error_count error(s), $warning_count warning(s)${RESET}"
        echo -e "${BOLD}${RED}════════════════════════════════════════════════════════════${RESET}"
        echo ""
        echo -e "${BOLD}Errors:${RESET}"
        echo -e "${RED}$errors${RESET}"
        if [ $warning_count -gt 0 ]; then
            echo ""
            echo -e "${BOLD}Warnings:${RESET}"
            echo -e "${YELLOW}$warnings${RESET}"
        fi
        echo ""
        echo -e "${BOLD}${RED}════════════════════════════════════════════════════════════${RESET}"
        play_error_alert
        return 1
    elif [ $warning_count -gt 0 ]; then
        echo ""
        echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${YELLOW}⚠️  BUILD SUCCEEDED with $warning_count warning(s)${RESET}"
        echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════════${RESET}"
        echo ""
        echo -e "${BOLD}Warnings:${RESET}"
        echo -e "${YELLOW}$warnings${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════════════${RESET}"
        return 0
    else
        echo ""
        echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${GREEN}✅ BUILD SUCCEEDED - No errors or warnings${RESET}"
        echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════${RESET}"
        play_success_alert
        return 0
    fi
}

echo -e "${BOLD}==================================${RESET}"
echo -e "${BOLD}BUILD WATCHER${RESET} - ${GREEN}$REPO_NAME${RESET}"
echo -e "${BOLD}==================================${RESET}"
echo -e "Project path: ${CYAN}$PROJECT_PATH${RESET}"
echo -e "Project type: ${CYAN}$(find_project)${RESET}"
echo "Checking build every ${INTERVAL}s"
echo "Press Ctrl+C to stop"
echo ""

# Initial build check
echo -e "${YELLOW}Running initial build check...${RESET}"
BUILD_OUTPUT=$(run_build)
echo "$BUILD_OUTPUT" > "$BUILD_LOG"
CURRENT_HASH=$(echo "$BUILD_OUTPUT" | md5sum | cut -d' ' -f1)
echo "$CURRENT_HASH" > "$LAST_BUILD_HASH"
parse_build_output "$BUILD_OUTPUT"

while true; do
    sleep "$INTERVAL"

    # Check if source files changed (simple check via git status)
    if ! git diff --quiet HEAD 2>/dev/null; then
        echo -e "\n${CYAN}[$(date +%H:%M:%S)] Source files changed, rebuilding...${RESET}"

        BUILD_OUTPUT=$(run_build)
        echo "$BUILD_OUTPUT" > "$BUILD_LOG"
        CURRENT_HASH=$(echo "$BUILD_OUTPUT" | md5sum | cut -d' ' -f1)
        LAST_HASH=$(cat "$LAST_BUILD_HASH" 2>/dev/null)

        if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
            parse_build_output "$BUILD_OUTPUT"
            echo "$CURRENT_HASH" > "$LAST_BUILD_HASH"
        fi
    else
        echo -n "."  # Heartbeat
    fi
done
