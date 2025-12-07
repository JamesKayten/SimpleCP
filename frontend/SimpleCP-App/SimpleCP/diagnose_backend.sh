#!/bin/bash

# SimpleCP Backend Diagnostic and Fix Script
# Run this if your backend won't connect

echo "=============================================="
echo "SimpleCP Backend Diagnostics"
echo "=============================================="
echo ""

# Check if port 8000 is in use
echo "1. Checking if port 8000 is in use..."
PORT_PID=$(lsof -ti:8000 2>/dev/null)

if [ -z "$PORT_PID" ]; then
    echo "   ✅ Port 8000 is available"
else
    echo "   ⚠️  Port 8000 is in use by process: $PORT_PID"
    ps -p $PORT_PID -o pid,command
    echo ""
    echo "   Would you like to kill this process? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        kill -9 $PORT_PID
        echo "   ✅ Process killed"
        sleep 1
        # Verify it's gone
        if lsof -ti:8000 >/dev/null 2>&1; then
            echo "   ❌ Process still running, may need sudo:"
            echo "      sudo kill -9 $PORT_PID"
        fi
    fi
fi

echo ""
echo "2. Checking Python environment..."

# Check if venv exists
PROJECT_PATH="/Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP"
VENV_PYTHON="$PROJECT_PATH/.venv/bin/python3"
BACKEND_MAIN="$PROJECT_PATH/backend/main.py"

if [ -f "$VENV_PYTHON" ]; then
    echo "   ✅ Virtual environment found"
    $VENV_PYTHON --version
else
    echo "   ❌ Virtual environment not found at: $VENV_PYTHON"
    echo "      You may need to recreate it:"
    echo "      cd $PROJECT_PATH"
    echo "      python3 -m venv .venv"
    echo "      source .venv/bin/activate"
    echo "      pip install -r requirements.txt"
fi

echo ""
echo "3. Checking backend files..."

if [ -f "$BACKEND_MAIN" ]; then
    echo "   ✅ Backend main.py found"
else
    echo "   ❌ Backend main.py not found at: $BACKEND_MAIN"
fi

echo ""
echo "4. Testing backend manually..."

if [ -f "$VENV_PYTHON" ] && [ -f "$BACKEND_MAIN" ]; then
    echo "   Starting backend in test mode..."
    echo "   Press Ctrl+C to stop after testing"
    echo ""
    cd "$PROJECT_PATH/backend" || exit
    $VENV_PYTHON main.py
else
    echo "   ❌ Cannot test - missing files"
fi

echo ""
echo "=============================================="
echo "Diagnostics Complete"
echo "=============================================="
