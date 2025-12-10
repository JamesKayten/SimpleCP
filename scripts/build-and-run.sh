#!/bin/bash
# build-and-run.sh - Clean build and launch SimpleCP
# One command. No bullshit.

set -e

echo "=== SimpleCP Build & Run ==="

# Find the right directory (worktree or main)
if [ -d "/Volumes/User_Smallfavor/Users/Smallfavor/.claude-worktrees/SimpleCP" ]; then
    # Use most recent worktree if it exists
    WORKTREE=$(ls -td /Volumes/User_Smallfavor/Users/Smallfavor/.claude-worktrees/SimpleCP/*/ 2>/dev/null | head -1)
    if [ -n "$WORKTREE" ] && [ -d "$WORKTREE/frontend/SimpleCP-App" ]; then
        PROJECT_DIR="$WORKTREE"
        echo "Using worktree: $(basename $WORKTREE)"
    else
        PROJECT_DIR="$HOME/Code/ACTIVE/SimpleCP"
        echo "Using main repo"
    fi
else
    PROJECT_DIR="$HOME/Code/ACTIVE/SimpleCP"
    echo "Using main repo"
fi

APP_DIR="$PROJECT_DIR/frontend/SimpleCP-App"
DERIVED="$APP_DIR/DerivedData"
APP_PATH="$DERIVED/SimpleCP/Build/Products/Debug/SimpleCP.app"

# 1. Kill any running SimpleCP
echo ""
echo "1. Stopping SimpleCP..."
pkill -x SimpleCP 2>/dev/null || true
sleep 0.5

# 2. Clean derived data
echo "2. Cleaning build artifacts..."
rm -rf "$DERIVED"

# 3. Prune stale worktrees
echo "3. Pruning stale worktrees..."
cd "$HOME/Code/ACTIVE/SimpleCP" && git worktree prune 2>/dev/null || true

# 4. Build
echo "4. Building..."
cd "$APP_DIR"
xcodebuild -project SimpleCP.xcodeproj \
    -scheme SimpleCP \
    -configuration Debug \
    -derivedDataPath DerivedData \
    build 2>&1 | grep -E "(error:|warning:|BUILD|Compiling)" || true

# Check build succeeded
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "✅ Build succeeded"

# 5. Check accessibility permission
echo ""
echo "5. Checking accessibility permission..."
echo "   Make sure SimpleCP is enabled in:"
echo "   System Settings → Privacy & Security → Accessibility"

# 6. Launch
echo ""
echo "6. Launching SimpleCP..."
open "$APP_PATH"

echo ""
echo "=== Done ==="
echo "App: $APP_PATH"
