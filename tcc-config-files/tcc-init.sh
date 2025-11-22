#!/bin/bash

# ============================================================================
# TCC Initialization Script
# ============================================================================
# This script ensures the AI Collaboration Management framework is available
# and sets up TCC for the current session.
#
# Usage:
#   source ~/tcc-init.sh
#
# Or add to TCC's first command in each session:
#   "First, run: source ~/tcc-init.sh && tcc-status"
# ============================================================================

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 Initializing TCC Session"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Load TCC configuration
if [ -f ~/.tccrc ]; then
    echo "📋 Loading TCC configuration..."
    source ~/.tccrc
    echo "✅ Configuration loaded"
else
    echo "⚠️  No ~/.tccrc found - creating basic configuration..."
    cat > ~/.tccrc << 'TCCRC_EOF'
# TCC Configuration - Auto-generated
export AI_FRAMEWORK_REPO="$HOME/AI-Collaboration-Management"
export AI_RULES_DIR="$AI_FRAMEWORK_REPO/rules"
export AI_GENERAL_RULES="$AI_RULES_DIR/GENERAL_AI_RULES.md"
export AI_STARTUP_PROTOCOL="$AI_RULES_DIR/STARTUP_PROTOCOL.md"
export CURRENT_PROJECT_DIR="$(pwd)"
export PROJECT_AI_DIR="$CURRENT_PROJECT_DIR/.ai"
TCCRC_EOF
    source ~/.tccrc
    echo "✅ Basic configuration created"
fi

echo ""

# Step 2: Check for framework repository
if [ ! -d "$AI_FRAMEWORK_REPO" ]; then
    echo "📥 AI Collaboration Management framework not found"
    echo "   Expected location: $AI_FRAMEWORK_REPO"
    echo ""
    echo "   Attempting to clone framework..."

    # Try to clone the repository
    if git clone https://github.com/JamesKayten/AI-Collaboration-Management.git "$AI_FRAMEWORK_REPO" 2>/dev/null; then
        echo "✅ Framework cloned successfully"
    else
        echo "❌ Failed to clone framework"
        echo ""
        echo "   Manual setup required:"
        echo "   1. Clone the repository:"
        echo "      git clone https://github.com/JamesKayten/AI-Collaboration-Management.git $AI_FRAMEWORK_REPO"
        echo "   2. Or update AI_FRAMEWORK_REPO in ~/.tccrc to point to existing location"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 1
    fi
else
    echo "✅ Framework repository found: $AI_FRAMEWORK_REPO"

    # Optional: Check for updates
    echo "🔍 Checking for framework updates..."
    cd "$AI_FRAMEWORK_REPO"

    # Fetch latest without modifying working tree
    if git fetch origin main 2>/dev/null; then
        LOCAL=$(git rev-parse HEAD 2>/dev/null)
        REMOTE=$(git rev-parse origin/main 2>/dev/null)

        if [ "$LOCAL" != "$REMOTE" ]; then
            echo "📥 Framework updates available"
            echo "   Run 'tcc-sync' to update"
        else
            echo "✅ Framework is up to date"
        fi
    fi

    cd - > /dev/null
fi

echo ""

# Step 3: Verify framework structure
echo "🔍 Verifying framework structure..."

FRAMEWORK_VALID=true

if [ ! -f "$AI_GENERAL_RULES" ]; then
    echo "❌ GENERAL_AI_RULES.md not found"
    FRAMEWORK_VALID=false
else
    echo "✅ General AI Rules found"
fi

if [ ! -f "$AI_STARTUP_PROTOCOL" ]; then
    echo "❌ STARTUP_PROTOCOL.md not found"
    FRAMEWORK_VALID=false
else
    echo "✅ Startup Protocol found"
fi

if [ ! -d "$AI_RULES_DIR" ]; then
    echo "❌ Rules directory not found"
    FRAMEWORK_VALID=false
else
    echo "✅ Rules directory found"
fi

echo ""

# Step 4: Check current project context
echo "📁 Checking project context..."
echo "   Working directory: $CURRENT_PROJECT_DIR"

if [ -d "$PROJECT_AI_DIR" ]; then
    echo "✅ Project .ai directory found"

    if [ -f "$PROJECT_AI_DIR/BOARD.md" ]; then
        echo "✅ BOARD.md found - use 'tcc-board' to view"
    else
        echo "ℹ️  No BOARD.md in project"
    fi
else
    echo "ℹ️  No .ai directory in current project"
    echo "   This is normal for new projects or non-framework directories"
fi

echo ""

# Step 5: Display available commands
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 TCC Commands Available:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  tcc-status    - Display framework and project status"
echo "  tcc-board     - View current project BOARD.md"
echo "  tcc-rules     - Display General AI Rules"
echo "  tcc-startup   - Display Startup Protocol"
echo "  tcc-setup     - Configure TCC for current project"
echo "  tcc-sync      - Sync framework with latest updates"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 6: Final status
if [ "$FRAMEWORK_VALID" = true ]; then
    echo "✅ TCC Initialization Complete"
    echo "   Rules confirmed - holistic approach enabled"
    echo ""
    echo "   Run 'tcc-status' for detailed framework status"
    echo "   Run 'tcc-startup' to view the startup protocol"
else
    echo "⚠️  TCC Initialization Complete with Issues"
    echo "   Some framework files are missing"
    echo "   Run 'tcc-sync' to update the framework"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
