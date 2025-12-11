#!/bin/bash

# Kill Backend Process on Port 49917
# Run this if SimpleCP shows "Port occupied" error

PORT=49917

echo "🔍 Checking port $PORT..."

# Check if port is in use
if lsof -ti:$PORT > /dev/null 2>&1; then
    echo "⚠️  Port $PORT is in use"
    
    # Show what's using it
    echo ""
    echo "Process using port $PORT:"
    lsof -i:$PORT
    
    echo ""
    echo "🔴 Killing process..."
    lsof -ti:$PORT | xargs kill -9
    
    sleep 1
    
    # Verify it's freed
    if lsof -ti:$PORT > /dev/null 2>&1; then
        echo "❌ Failed to kill process on port $PORT"
        echo "💡 Try with sudo: sudo lsof -ti:$PORT | xargs sudo kill -9"
        exit 1
    else
        echo "✅ Port $PORT is now free"
        echo ""
        echo "You can now restart SimpleCP"
        exit 0
    fi
else
    echo "✅ Port $PORT is already free"
    exit 0
fi
