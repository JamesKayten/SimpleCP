#!/bin/bash
# Build and install SimpleCP to /Applications
# This creates a stable binary that retains Accessibility permissions across rebuilds

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$PROJECT_DIR/frontend/SimpleCP-App"
APP_NAME="SimpleCP"
INSTALL_PATH="/Applications/$APP_NAME.app"

echo "🔨 Building $APP_NAME..."

# Kill any running instance
pkill -x "$APP_NAME" 2>/dev/null || true

# Build release version
cd "$FRONTEND_DIR"
xcodebuild -scheme "$APP_NAME" -configuration Release -derivedDataPath build clean build 2>&1 | grep -E "^(Build|error:|warning:|\*\*)" || true

BUILD_PATH="$FRONTEND_DIR/build/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$BUILD_PATH" ]; then
    echo "❌ Build failed - app not found at $BUILD_PATH"
    exit 1
fi

echo "📦 Installing to $INSTALL_PATH..."

# Remove old version
if [ -d "$INSTALL_PATH" ]; then
    rm -rf "$INSTALL_PATH"
fi

# Copy new version
cp -R "$BUILD_PATH" "$INSTALL_PATH"

echo "✅ Installed $APP_NAME to /Applications"
echo ""
echo "⚠️  First time setup:"
echo "   1. Open System Settings → Privacy & Security → Accessibility"
echo "   2. Add /Applications/$APP_NAME.app and enable it"
echo "   3. This only needs to be done once"
echo ""
echo "🚀 Launching $APP_NAME..."
open "$INSTALL_PATH"
