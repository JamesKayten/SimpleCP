#!/bin/bash

# Configure Backend to Use Port 49917
# This script helps ensure your backend is configured correctly

echo "=============================================="
echo "SimpleCP Backend Port Configuration"
echo "=============================================="
echo ""

PROJECT_PATH="/Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP"
BACKEND_MAIN="$PROJECT_PATH/backend/main.py"

echo "🔍 Checking backend configuration..."
echo ""

if [ ! -f "$BACKEND_MAIN" ]; then
    echo "❌ Backend main.py not found at: $BACKEND_MAIN"
    exit 1
fi

echo "📝 Checking main.py for port configuration..."
echo ""

# Check if main.py uses uvicorn.run with a port parameter
if grep -q "uvicorn.run" "$BACKEND_MAIN"; then
    echo "✅ Found uvicorn.run in main.py"
    echo ""
    echo "Current port configuration:"
    grep -A 2 "uvicorn.run" "$BACKEND_MAIN" | grep -E "(port|--port)"
    echo ""
    
    # Check if it uses argparse or click for CLI arguments
    if grep -q "argparse\|click\|sys.argv" "$BACKEND_MAIN"; then
        echo "✅ Backend appears to support command-line arguments"
    else
        echo "⚠️  Backend may not support --port argument"
        echo ""
        echo "💡 Your backend needs to accept a --port argument."
        echo "   The Swift app passes: python3 main.py --port 49917"
        echo ""
        echo "Add this to your main.py:"
        echo ""
        cat << 'EOF'
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=49917, help="Port to run server on")
    args = parser.parse_args()
    
    uvicorn.run(app, host="0.0.0.0", port=args.port)
EOF
        echo ""
    fi
else
    echo "⚠️  Could not find uvicorn.run in main.py"
    echo "   Please check your backend startup code"
fi

echo ""
echo "=============================================="
echo "Next Steps:"
echo "=============================================="
echo ""
echo "1. Ensure your backend main.py accepts --port argument"
echo "2. Make sure it defaults to port 49917"
echo "3. Test manually:"
echo "   cd $PROJECT_PATH/backend"
echo "   source ../.venv/bin/activate"
echo "   python3 main.py --port 49917"
echo ""
echo "4. Verify it's listening:"
echo "   curl http://localhost:49917/health"
echo ""
echo "5. Kill any existing backend processes:"
echo "   lsof -ti:49917 | xargs kill -9"
echo ""
