#!/bin/bash
# Prepare macOS app for code signing and notarization
set -e
echo "=== macOS App Signing & Notarization Prep ==="

APP_BUNDLE=${1:-"build/SimpleCP.app"}; BUNDLE_ID="com.simplecp.macos"; TEAM_ID=${APPLE_TEAM_ID:-"YOUR_TEAM_ID"}
[ ! -d "$APP_BUNDLE" ] && { echo "Error: App bundle not found at $APP_BUNDLE"; exit 1; }
echo "App: $APP_BUNDLE | Bundle ID: $BUNDLE_ID | Team ID: $TEAM_ID"

# Create entitlements
ENTITLEMENTS="build/SimpleCP.entitlements"
cat > "$ENTITLEMENTS" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>com.apple.security.app-sandbox</key><true/>
    <key>com.apple.security.files.user-selected.read-write</key><true/>
    <key>com.apple.security.network.client</key><true/>
    <key>com.apple.security.automation.apple-events</key><true/>
</dict></plist>
EOF
echo "Created: $ENTITLEMENTS"

# Create signing script
cat > "build/sign_app.sh" << 'EOF'
#!/bin/bash
APP_BUNDLE=$1; IDENTITY=${SIGNING_IDENTITY:-"Developer ID Application"}
echo "Signing with: $IDENTITY"
find "$APP_BUNDLE/Contents/Frameworks" -name "*.framework" -o -name "*.dylib" | while read f; do
    codesign --force --sign "$IDENTITY" --timestamp --options runtime "$f"
done
codesign --force --sign "$IDENTITY" --entitlements "build/SimpleCP.entitlements" --timestamp --options runtime --deep "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
echo "Signing complete!"
EOF
chmod +x "build/sign_app.sh"; echo "Created: build/sign_app.sh"

# Create notarization script
cat > "build/notarize_app.sh" << 'EOF'
#!/bin/bash
APP_BUNDLE=$1; BUNDLE_ID=${2:-"com.simplecp.macos"}
APPLE_ID=${APPLE_ID:-"your@email.com"}; TEAM_ID=${APPLE_TEAM_ID:-"YOUR_TEAM_ID"}
DIST_ZIP="build/SimpleCP.zip"
ditto -c -k --keepParent "$APP_BUNDLE" "$DIST_ZIP"
xcrun notarytool submit "$DIST_ZIP" --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "@keychain:AC_PASSWORD" --wait
xcrun stapler staple "$APP_BUNDLE"
echo "Notarization complete!"
EOF
chmod +x "build/notarize_app.sh"; echo "Created: build/notarize_app.sh"

# Create DMG script
cat > "build/create_dmg.sh" << 'EOF'
#!/bin/bash
APP_BUNDLE=$1; VERSION=${2:-"1.0.0"}; DMG_NAME="SimpleCP-${VERSION}.dmg"
DMG_DIR="build/dmg_temp"; rm -rf "$DMG_DIR"; mkdir -p "$DMG_DIR"
cp -R "$APP_BUNDLE" "$DMG_DIR/"; ln -s /Applications "$DMG_DIR/Applications"
hdiutil create -volname "SimpleCP" -srcfolder "$DMG_DIR" -ov -format UDZO "build/$DMG_NAME"
rm -rf "$DMG_DIR"; echo "Created: build/$DMG_NAME"
EOF
chmod +x "build/create_dmg.sh"; echo "Created: build/create_dmg.sh"

# Create signing README
cat > "build/SIGNING_README.md" << EOF
# Code Signing & Notarization

## Setup
\`\`\`bash
export SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
xcrun notarytool store-credentials "AC_PASSWORD" --apple-id "\$APPLE_ID" --team-id "\$APPLE_TEAM_ID"
\`\`\`

## Process
1. Sign: \`./build/sign_app.sh $APP_BUNDLE\`
2. Notarize: \`./build/notarize_app.sh $APP_BUNDLE\`
3. Create DMG: \`./build/create_dmg.sh $APP_BUNDLE 1.0.0\`

## Verify
\`spctl -a -t exec -vv $APP_BUNDLE\`
\`xcrun stapler validate $APP_BUNDLE\`
EOF

echo -e "\nSigning prep complete! See build/SIGNING_README.md"
