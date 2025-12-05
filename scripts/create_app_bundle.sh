#!/bin/bash
# Create macOS application bundle for SimpleCP

set -e

echo "========================================="
echo "Creating macOS App Bundle"
echo "========================================="

APP_NAME="SimpleCP"
VERSION=${1:-"1.0.0"}
BUNDLE_ID="com.simplecp.macos"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "Creating bundle structure..."

# Create app bundle structure
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${APP_BUNDLE}/Contents/Frameworks"

# Create Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# Create launcher script
cat > "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" << 'EOF'
#!/bin/bash
# SimpleCP launcher script

# Get bundle directory
BUNDLE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
RESOURCES_DIR="${BUNDLE_DIR}/Contents/Resources"

# Start Python backend
cd "${RESOURCES_DIR}/backend"
python3 daemon.py --port 8080 &
BACKEND_PID=$!

# Launch Swift frontend (if built)
if [ -f "${BUNDLE_DIR}/Contents/MacOS/SimpleCP-Swift" ]; then
    "${BUNDLE_DIR}/Contents/MacOS/SimpleCP-Swift"
else
    echo "Swift frontend not found, running backend only"
    wait $BACKEND_PID
fi
EOF

chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy Python backend
echo "Copying Python backend..."
mkdir -p "${APP_BUNDLE}/Contents/Resources/backend"
cp -r api stores *.py "${APP_BUNDLE}/Contents/Resources/backend/"
cp requirements.txt "${APP_BUNDLE}/Contents/Resources/backend/"
cp config.json "${APP_BUNDLE}/Contents/Resources/backend/"

# Create version file
echo "${VERSION}" > "${APP_BUNDLE}/Contents/Resources/VERSION"

echo ""
echo "App bundle created: ${APP_BUNDLE}"
echo "Version: ${VERSION}"
echo ""
