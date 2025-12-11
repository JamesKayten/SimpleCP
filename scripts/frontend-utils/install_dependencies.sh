#!/bin/bash
# 
# SimpleCP - Install Python Dependencies
#
# This script installs all required Python packages for the SimpleCP backend
#

set -e  # Exit on any error

echo "============================================================"
echo "🔧 Installing SimpleCP Python Dependencies"
echo "============================================================"
echo ""

# Detect project root (assuming script is in project root)
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
VENV_PATH="$PROJECT_ROOT/.venv"
BACKEND_PATH="$PROJECT_ROOT/backend"
REQUIREMENTS_FILE="$BACKEND_PATH/requirements.txt"

echo "📁 Project root: $PROJECT_ROOT"
echo "🐍 Virtual environment: $VENV_PATH"
echo ""

# Check if venv exists
if [ ! -d "$VENV_PATH" ]; then
    echo "❌ Virtual environment not found at: $VENV_PATH"
    echo ""
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_PATH"
    echo "✅ Virtual environment created"
    echo ""
fi

# Activate venv
echo "🔌 Activating virtual environment..."
source "$VENV_PATH/bin/activate"

# Upgrade pip
echo "📦 Upgrading pip..."
pip install --upgrade pip

echo ""
echo "============================================================"
echo "📥 Installing Python packages"
echo "============================================================"
echo ""

# Install from requirements.txt if it exists
if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "Installing from requirements.txt..."
    pip install -r "$REQUIREMENTS_FILE"
else
    echo "⚠️  requirements.txt not found, installing common dependencies..."
    echo ""
    
    # Install common dependencies for FastAPI backend
    pip install fastapi>=0.104.0
    pip install uvicorn[standard]>=0.24.0
    pip install python-multipart
    pip install psutil  # For process management
    pip install pydantic>=2.0.0
    
    echo ""
    echo "💡 Consider creating a requirements.txt file with:"
    echo "   pip freeze > backend/requirements.txt"
fi

echo ""
echo "============================================================"
echo "✅ Installation complete!"
echo "============================================================"
echo ""
echo "📋 Installed packages:"
pip list | grep -E "(fastapi|uvicorn|psutil|pydantic)"

echo ""
echo "🚀 You can now run SimpleCP"
echo ""
