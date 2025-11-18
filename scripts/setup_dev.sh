#!/bin/bash
# Development environment setup script

set -e

echo "=== SimpleCP Development Setup ==="
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install all dependencies
echo "Installing dependencies..."
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Install package in editable mode
echo "Installing SimpleCP in editable mode..."
pip install -e .

# Create necessary directories
echo "Creating directories..."
mkdir -p data logs

# Setup environment file
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env file from example"
fi

# Install pre-commit hooks
echo "Installing pre-commit hooks..."
pre-commit install

# Run initial tests
echo ""
read -p "Run tests to verify setup? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running tests..."
    pytest tests/ -v
fi

echo ""
echo "=== Development Setup Complete ==="
echo ""
echo "Development tools available:"
echo "  - make test       : Run tests"
echo "  - make lint       : Run linters"
echo "  - make format     : Format code"
echo "  - make run        : Run application"
echo ""
