#!/bin/bash

# Show current backend main.py relevant to port configuration
# Helps verify if backend is properly configured

PROJECT_PATH="/Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP"
BACKEND_MAIN="$PROJECT_PATH/backend/main.py"

echo "=============================================="
echo "Backend Port Configuration Check"
echo "=============================================="
echo ""

if [ ! -f "$BACKEND_MAIN" ]; then
    echo "❌ Backend main.py not found at: $BACKEND_MAIN"
    exit 1
fi

echo "📄 File: $BACKEND_MAIN"
echo ""

# Check for argparse
echo "🔍 Checking for argparse..."
if grep -q "import argparse" "$BACKEND_MAIN"; then
    echo "   ✅ Found: import argparse"
else
    echo "   ❌ Not found: import argparse"
fi

# Check for port argument parsing
echo ""
echo "🔍 Checking for port argument parsing..."
if grep -q "add_argument.*--port\|ArgumentParser.*port" "$BACKEND_MAIN"; then
    echo "   ✅ Found port argument configuration:"
    grep -n "port" "$BACKEND_MAIN" | grep -v "^#" | head -5
else
    echo "   ❌ No port argument found"
fi

# Check for environment variable usage
echo ""
echo "🔍 Checking for SIMPLECP_PORT environment variable..."
if grep -q "SIMPLECP_PORT" "$BACKEND_MAIN"; then
    echo "   ✅ Found SIMPLECP_PORT usage:"
    grep -n "SIMPLECP_PORT" "$BACKEND_MAIN"
else
    echo "   ❌ SIMPLECP_PORT not found"
fi

# Check uvicorn.run
echo ""
echo "🔍 Checking uvicorn configuration..."
if grep -q "uvicorn.run" "$BACKEND_MAIN"; then
    echo "   ✅ Found uvicorn.run:"
    grep -A 5 "uvicorn.run" "$BACKEND_MAIN" | head -10
else
    echo "   ⚠️  uvicorn.run not found in expected format"
fi

# Check if __name__ == "__main__" block exists
echo ""
echo "🔍 Checking for main block..."
if grep -q 'if __name__ == "__main__"' "$BACKEND_MAIN"; then
    echo "   ✅ Found main block"
else
    echo "   ⚠️  Main block not found"
fi

echo ""
echo "=============================================="
echo "Summary"
echo "=============================================="
echo ""

# Determine configuration status
has_argparse=$(grep -q "import argparse" "$BACKEND_MAIN" && echo "yes" || echo "no")
has_port_arg=$(grep -q "add_argument.*--port" "$BACKEND_MAIN" && echo "yes" || echo "no")
has_env_var=$(grep -q "SIMPLECP_PORT" "$BACKEND_MAIN" && echo "yes" || echo "no")
has_uvicorn=$(grep -q "uvicorn.run" "$BACKEND_MAIN" && echo "yes" || echo "no")

if [ "$has_argparse" = "yes" ] && [ "$has_port_arg" = "yes" ]; then
    echo "✅ Backend is configured to accept --port argument"
elif [ "$has_env_var" = "yes" ]; then
    echo "✅ Backend is configured to use SIMPLECP_PORT env variable"
else
    echo "❌ Backend needs port configuration"
    echo ""
    echo "💡 Add this to your backend/main.py:"
    echo ""
    cat << 'EOF'
import argparse
import os

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.getenv("SIMPLECP_PORT", "49917")),
        help="Port to run server on"
    )
    args = parser.parse_args()
    
    uvicorn.run(app, host="0.0.0.0", port=args.port)
EOF
    echo ""
fi

echo ""
echo "📚 For full setup guide, see: PORT_49917_SETUP.md"
echo ""
