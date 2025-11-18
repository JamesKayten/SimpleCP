#!/bin/bash
# Cleanup script for SimpleCP

echo "=== SimpleCP Cleanup Script ==="
echo ""

# Clean Python cache
echo "Cleaning Python cache..."
find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true

# Clean test artifacts
echo "Cleaning test artifacts..."
rm -rf .pytest_cache/ 2>/dev/null || true
rm -rf htmlcov/ 2>/dev/null || true
rm -f .coverage 2>/dev/null || true
rm -f coverage.xml 2>/dev/null || true

# Clean build artifacts
echo "Cleaning build artifacts..."
rm -rf build/ 2>/dev/null || true
rm -rf dist/ 2>/dev/null || true
rm -rf *.egg-info/ 2>/dev/null || true

# Clean type checker cache
echo "Cleaning type checker cache..."
rm -rf .mypy_cache/ 2>/dev/null || true

# Clean logs (optional)
read -p "Clean logs? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleaning logs..."
    rm -f logs/*.log 2>/dev/null || true
fi

echo ""
echo "Cleanup complete!"
