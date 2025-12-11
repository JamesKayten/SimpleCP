#!/bin/bash

# Quick test script for port 49917 setup
# Run this to verify everything is configured correctly

echo "=============================================="
echo "SimpleCP Port 49917 Quick Test"
echo "=============================================="
echo ""

PORT=49917

# Step 1: Check port status
echo "1️⃣  Checking port $PORT status..."
if lsof -ti:$PORT > /dev/null 2>&1; then
    echo "   ⚠️  Port $PORT is in use"
    echo "   Process info:"
    lsof -i:$PORT
    echo ""
    echo "   Kill it? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        lsof -ti:$PORT | xargs kill -9
        sleep 1
        echo "   ✅ Process killed"
    else
        echo "   ⚠️  Skipping... backend may fail to start"
    fi
else
    echo "   ✅ Port $PORT is free"
fi

echo ""

# Step 2: Check backend file
echo "2️⃣  Checking backend files..."
PROJECT_PATH="/Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP"
BACKEND_MAIN="$PROJECT_PATH/backend/main.py"

if [ -f "$BACKEND_MAIN" ]; then
    echo "   ✅ Backend main.py found"
else
    echo "   ❌ Backend main.py not found at: $BACKEND_MAIN"
    exit 1
fi

echo ""

# Step 3: Check Python environment
echo "3️⃣  Checking Python environment..."
VENV_PYTHON="$PROJECT_PATH/.venv/bin/python3"

if [ -f "$VENV_PYTHON" ]; then
    echo "   ✅ Virtual environment found"
    PYTHON_VERSION=$($VENV_PYTHON --version 2>&1)
    echo "   📦 Python: $PYTHON_VERSION"
else
    echo "   ⚠️  Virtual environment not found"
    echo "   Will try system Python"
    VENV_PYTHON=$(which python3)
    if [ -z "$VENV_PYTHON" ]; then
        echo "   ❌ Python 3 not found"
        exit 1
    fi
fi

echo ""

# Step 4: Check backend configuration
echo "4️⃣  Checking backend port configuration..."
if grep -q "argparse\|--port\|SIMPLECP_PORT" "$BACKEND_MAIN"; then
    echo "   ✅ Backend appears to support port configuration"
else
    echo "   ⚠️  Backend may not support --port argument"
    echo "   💡 See PORT_49917_SETUP.md for configuration instructions"
fi

echo ""

# Step 5: Offer to test backend
echo "5️⃣  Would you like to test the backend? (y/n)"
read -r test_response

if [[ "$test_response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "   🚀 Starting backend on port $PORT..."
    echo "   (Press Ctrl+C to stop)"
    echo ""
    
    cd "$PROJECT_PATH/backend" || exit
    
    # Try to activate venv if it exists
    if [ -f "$PROJECT_PATH/.venv/bin/activate" ]; then
        source "$PROJECT_PATH/.venv/bin/activate"
    fi
    
    # Start backend with port argument
    SIMPLECP_PORT=$PORT python3 main.py --port $PORT
else
    echo ""
    echo "   ⏭️  Skipping backend test"
fi

echo ""
echo "=============================================="
echo "Test Complete"
echo "=============================================="
echo ""
echo "📚 For detailed setup instructions, see:"
echo "   PORT_49917_SETUP.md"
echo ""
