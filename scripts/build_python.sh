#!/bin/bash
# Build script for SimpleCP Python backend

set -e  # Exit on error

echo "========================================="
echo "SimpleCP Python Backend Build"
echo "========================================="

# Version
VERSION=${1:-"1.0.0"}
echo "Version: $VERSION"

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build/ dist/ *.egg-info

# Create virtual environment if not exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt

# Run tests
echo "Running tests..."
python -m pytest tests/ -v --cov=api --cov=clipboard_manager --cov-report=term

# Check code quality
echo "Running flake8..."
flake8 --max-line-length=88 *.py api/ stores/ || true

# Create distribution package
echo "Creating distribution package..."
cat > setup.py << EOF
from setuptools import setup, find_packages

setup(
    name="simplecp",
    version="$VERSION",
    packages=find_packages(),
    install_requires=[
        "fastapi",
        "uvicorn",
        "pydantic",
        "pyperclip",
    ],
    entry_points={
        "console_scripts": [
            "simplecp=daemon:main",
        ],
    },
)
EOF

python setup.py sdist bdist_wheel

echo ""
echo "Build complete!"
echo "Distribution: dist/simplecp-$VERSION.tar.gz"
echo ""
