#!/bin/bash
# build-and-run.sh - Clean build and launch SimpleCP
# One command. No bullshit.

set -e

echo "=== SimpleCP Build & Run ==="

PROJECT_DIR="$HOME/Code/ACTIVE/SimpleCP"

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

# 3. Build
echo "3. Building..."
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

# 4. Check accessibility permission
echo ""
echo "4. Checking accessibility permission..."
echo "   Make sure SimpleCP is enabled in:"
echo "   System Settings → Privacy & Security → Accessibility"

# 5. Launch
echo ""
echo "5. Launching SimpleCP..."
open "$APP_PATH"

echo ""
echo "=== Done ==="
echo "App: $APP_PATH"
