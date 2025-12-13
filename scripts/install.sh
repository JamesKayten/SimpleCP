#!/bin/bash
# Installation script for SimpleCP

set -e

echo "=== SimpleCP Installation Script ==="
echo ""

# Check Python version
echo "Checking Python version..."
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "Found Python $python_version"

# Create virtual environment
echo ""
echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
echo ""
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo ""
echo "Installing dependencies..."
pip install -r requirements.txt

# Install development dependencies (optional)
read -p "Install development dependencies? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing development dependencies..."
    pip install -r requirements-dev.txt
fi

# Create data directory
echo ""
echo "Creating data directory..."
mkdir -p data logs

# Copy environment file
if [ ! -f .env ]; then
    echo ""
    echo "Creating .env file from example..."
    cp .env.example .env
    echo "Please edit .env file to configure your settings"
fi

# Install pre-commit hooks (if dev dependencies installed)
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Installing pre-commit hooks..."
    pre-commit install
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "To get started:"
echo "  1. Activate virtual environment: source venv/bin/activate"
echo "  2. Edit configuration: nano .env"
echo "  3. Run the daemon: python daemon.py"
echo "  4. Access API: http://localhost:49917/docs"
echo ""
