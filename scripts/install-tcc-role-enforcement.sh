#!/bin/bash

# Install TCC Role Enforcement Hook
# Prevents TCC from implementing code - forces task assignment workflow

set -e

TARGET_REPO="${1:-.}"

if [[ ! -d "$TARGET_REPO/.git" ]]; then
    echo "❌ Error: $TARGET_REPO is not a git repository"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SOURCE="$SCRIPT_DIR/pre-commit-tcc-role-check"

if [[ ! -f "$HOOK_SOURCE" ]]; then
    echo "❌ Error: Hook script not found at $HOOK_SOURCE"
    exit 1
fi

echo "🔧 Installing TCC role enforcement hook in $TARGET_REPO"

# Copy the pre-commit hook
cp "$HOOK_SOURCE" "$TARGET_REPO/.git/hooks/pre-commit"
chmod +x "$TARGET_REPO/.git/hooks/pre-commit"

# Create .tcc-active marker to identify TCC sessions
touch "$TARGET_REPO/.tcc-active"

echo "✅ TCC role enforcement installed"
echo ""
echo "This hook will:"
echo "  - Block TCC from committing code changes"
echo "  - Force TCC to post tasks to BOARD.md instead"
echo "  - Enforce OCC = Developer, TCC = Project Manager"
echo ""
echo "TCC can still commit:"
echo "  - BOARD.md, TASKS.md, STATUS files"
echo "  - Documentation (README, CHANGELOG, etc.)"
echo "  - Communication logs and reports"
echo ""
echo "TCC CANNOT commit:"
echo "  - .swift, .py, .js, .ts files"
echo "  - Any code implementation"
echo ""
echo "See rules/OCC_TCC_ROLES.md for complete role definitions"
