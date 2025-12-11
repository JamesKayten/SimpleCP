#!/bin/bash

# Clear SimpleCP sandbox container
# Run this after disabling sandboxing in Xcode

echo "=============================================="
echo "SimpleCP Sandbox Container Cleanup"
echo "=============================================="
echo ""

CONTAINER_PATH="$HOME/Library/Containers/com.simplecp.SimpleCP"

if [ -d "$CONTAINER_PATH" ]; then
    echo "⚠️  Found sandbox container at:"
    echo "   $CONTAINER_PATH"
    echo ""
    echo "This needs to be removed for sandbox changes to take effect."
    echo ""
    echo "Remove container? (y/n)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "   Removing container..."
        rm -rf "$CONTAINER_PATH"
        echo "   ✅ Container removed"
        echo ""
        echo "Now:"
        echo "1. Quit the app completely if it's running"
        echo "2. Clean build folder in Xcode (Cmd+Shift+K)"
        echo "3. Rebuild and run"
    else
        echo "   Skipped removal"
    fi
else
    echo "✅ No sandbox container found"
    echo "   The app should run without sandboxing"
fi

echo ""
echo "=============================================="
