#!/bin/bash

# ============================================================================
# TCC INSTALLATION SCRIPT FOR LOCAL MACHINE
# ============================================================================
# This script installs the TCC configuration system on your local machine.
#
# INSTRUCTIONS FOR TCC:
# 1. Save this script to ~/install-tcc.sh on the user's local machine
# 2. Make it executable: chmod +x ~/install-tcc.sh
# 3. Run it: ~/install-tcc.sh
# 4. Follow the post-installation instructions
#
# This script will:
# - Download all configuration files from the SimpleCP repository
# - Set up environment configuration
# - Update .bashrc
# - Clone the AI Collaboration Management framework
# - Verify the installation
# ============================================================================

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 TCC Installation Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect home directory
HOME_DIR="$HOME"
echo "📁 Installation directory: $HOME_DIR"
echo ""

# ============================================================================
# Step 1: Download Configuration Files
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Downloading Configuration Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Download .tccrc
echo "📥 Downloading .tccrc..."
if curl -sSL https://raw.githubusercontent.com/JamesKayten/SimpleCP/claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU/.tccrc -o "$HOME_DIR/.tccrc.tmp" 2>/dev/null; then
    mv "$HOME_DIR/.tccrc.tmp" "$HOME_DIR/.tccrc"
    echo "✅ .tccrc downloaded"
else
    echo "⚠️  Could not download .tccrc from repository"
    echo "   Using embedded fallback configuration..."

    # Embedded fallback configuration
    cat > "$HOME_DIR/.tccrc" << 'TCCRC_EOF'
# TCC Configuration
export AI_FRAMEWORK_REPO="$HOME/AI-Collaboration-Management"
export AI_RULES_DIR="$AI_FRAMEWORK_REPO/rules"
export AI_TEMPLATES_DIR="$AI_FRAMEWORK_REPO/templates"
export AI_GENERAL_RULES="$AI_RULES_DIR/GENERAL_AI_RULES.md"
export AI_STARTUP_PROTOCOL="$AI_RULES_DIR/STARTUP_PROTOCOL.md"
export AI_RULE_IMPROVEMENTS="$AI_RULES_DIR/RULE_IMPROVEMENTS.md"
export CURRENT_PROJECT_DIR="$(pwd)"
export PROJECT_AI_DIR="$CURRENT_PROJECT_DIR/.ai"

check_framework() {
    if [ ! -d "$AI_FRAMEWORK_REPO" ]; then
        echo "⚠️  AI Framework not found at: $AI_FRAMEWORK_REPO"
        return 1
    else
        echo "✅ AI Framework found at: $AI_FRAMEWORK_REPO"
        return 0
    fi
}

framework_status() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🤖 TCC Framework Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Framework: $AI_FRAMEWORK_REPO"
    echo "Project:   $CURRENT_PROJECT_DIR"
    check_framework && echo "✅ Framework ready" || echo "❌ Framework not found"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

check_board() {
    [ -f "$PROJECT_AI_DIR/BOARD.md" ] && cat "$PROJECT_AI_DIR/BOARD.md" || echo "❌ No BOARD.md found"
}

view_rules() {
    [ -f "$AI_GENERAL_RULES" ] && cat "$AI_GENERAL_RULES" || echo "❌ Rules not found"
}

view_startup() {
    [ -f "$AI_STARTUP_PROTOCOL" ] && cat "$AI_STARTUP_PROTOCOL" || echo "❌ Startup protocol not found"
}

setup_project() {
    export CURRENT_PROJECT_DIR="$(pwd)"
    export PROJECT_AI_DIR="$CURRENT_PROJECT_DIR/.ai"
    framework_status
}

sync_framework() {
    if [ -d "$AI_FRAMEWORK_REPO" ]; then
        cd "$AI_FRAMEWORK_REPO" && git pull origin main && cd - > /dev/null
    fi
}

alias tcc-status='framework_status'
alias tcc-board='check_board'
alias tcc-rules='view_rules'
alias tcc-startup='view_startup'
alias tcc-setup='setup_project'
alias tcc-sync='sync_framework'

echo "🤖 TCC Configuration Loaded"
TCCRC_EOF
    echo "✅ Fallback .tccrc created"
fi
echo ""

# Download tcc-init.sh
echo "📥 Downloading tcc-init.sh..."
if curl -sSL https://raw.githubusercontent.com/JamesKayten/SimpleCP/claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU/tcc-init.sh -o "$HOME_DIR/tcc-init.sh.tmp" 2>/dev/null; then
    mv "$HOME_DIR/tcc-init.sh.tmp" "$HOME_DIR/tcc-init.sh"
    chmod +x "$HOME_DIR/tcc-init.sh"
    echo "✅ tcc-init.sh downloaded and made executable"
else
    echo "⚠️  Could not download tcc-init.sh from repository"
    echo "   Creating basic initialization script..."

    cat > "$HOME_DIR/tcc-init.sh" << 'INIT_EOF'
#!/bin/bash
echo "🤖 Initializing TCC Session"
[ -f ~/.tccrc ] && source ~/.tccrc || echo "❌ .tccrc not found"
if [ ! -d "$AI_FRAMEWORK_REPO" ]; then
    echo "📥 Cloning AI Collaboration Management framework..."
    git clone https://github.com/JamesKayten/AI-Collaboration-Management.git "$AI_FRAMEWORK_REPO"
fi
framework_status
echo "✅ TCC Initialization Complete"
echo "   Rules confirmed - holistic approach enabled"
INIT_EOF
    chmod +x "$HOME_DIR/tcc-init.sh"
    echo "✅ Basic tcc-init.sh created"
fi
echo ""

# Download documentation
echo "📥 Downloading documentation..."
if curl -sSL https://raw.githubusercontent.com/JamesKayten/SimpleCP/claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU/TCC_SETUP.md -o "$HOME_DIR/TCC_INSTALLATION_GUIDE.md" 2>/dev/null; then
    echo "✅ Documentation downloaded"
else
    echo "ℹ️  Documentation download skipped (optional)"
fi
echo ""

# ============================================================================
# Step 2: Update .bashrc
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Updating Shell Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BASHRC="$HOME_DIR/.bashrc"
ZSHRC="$HOME_DIR/.zshrc"

# Detect shell
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$BASHRC"
    SHELL_NAME="bash"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$ZSHRC"
    SHELL_NAME="zsh"
else
    # Default to bashrc
    SHELL_RC="$BASHRC"
    SHELL_NAME="bash (detected)"
fi

echo "🐚 Detected shell: $SHELL_NAME"
echo "📝 Updating: $SHELL_RC"
echo ""

# Check if already configured
if grep -q "\.tccrc" "$SHELL_RC" 2>/dev/null; then
    echo "ℹ️  TCC configuration already present in $SHELL_RC"
else
    echo "📝 Adding TCC configuration to $SHELL_RC..."
    cat >> "$SHELL_RC" << 'BASHRC_EOF'

# ============================================================================
# TCC (Terminal Control Center) Configuration
# ============================================================================
# Source TCC configuration for AI Collaboration Management framework access
if [ -f ~/.tccrc ]; then
    source ~/.tccrc
fi
BASHRC_EOF
    echo "✅ $SHELL_RC updated"
fi
echo ""

# ============================================================================
# Step 3: Clone AI Collaboration Management Framework
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Setting Up AI Collaboration Management Framework"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

FRAMEWORK_DIR="$HOME_DIR/AI-Collaboration-Management"

if [ -d "$FRAMEWORK_DIR" ]; then
    echo "✅ Framework already exists at: $FRAMEWORK_DIR"
    echo "🔄 Checking for updates..."

    cd "$FRAMEWORK_DIR"
    if git pull origin main 2>/dev/null; then
        echo "✅ Framework updated"
    else
        echo "ℹ️  Could not update framework (may be offline)"
    fi
    cd - > /dev/null
else
    echo "📥 Cloning AI Collaboration Management framework..."

    if git clone https://github.com/JamesKayten/AI-Collaboration-Management.git "$FRAMEWORK_DIR"; then
        echo "✅ Framework cloned successfully"
    else
        echo "❌ Failed to clone framework"
        echo "   You can clone it manually later:"
        echo "   git clone https://github.com/JamesKayten/AI-Collaboration-Management.git $FRAMEWORK_DIR"
    fi
fi
echo ""

# ============================================================================
# Step 4: Verify Installation
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Verifying Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

INSTALL_SUCCESS=true

# Check configuration file
if [ -f "$HOME_DIR/.tccrc" ]; then
    echo "✅ .tccrc configuration file"
else
    echo "❌ .tccrc configuration file missing"
    INSTALL_SUCCESS=false
fi

# Check initialization script
if [ -f "$HOME_DIR/tcc-init.sh" ] && [ -x "$HOME_DIR/tcc-init.sh" ]; then
    echo "✅ tcc-init.sh initialization script"
else
    echo "❌ tcc-init.sh initialization script missing or not executable"
    INSTALL_SUCCESS=false
fi

# Check shell configuration
if grep -q "\.tccrc" "$SHELL_RC" 2>/dev/null; then
    echo "✅ Shell configuration updated"
else
    echo "❌ Shell configuration not updated"
    INSTALL_SUCCESS=false
fi

# Check framework
if [ -d "$FRAMEWORK_DIR/rules" ]; then
    echo "✅ AI Collaboration Management framework"

    # Check key files
    [ -f "$FRAMEWORK_DIR/rules/GENERAL_AI_RULES.md" ] && echo "  ✅ GENERAL_AI_RULES.md" || echo "  ⚠️  GENERAL_AI_RULES.md missing"
    [ -f "$FRAMEWORK_DIR/rules/STARTUP_PROTOCOL.md" ] && echo "  ✅ STARTUP_PROTOCOL.md" || echo "  ⚠️  STARTUP_PROTOCOL.md missing"
    [ -f "$FRAMEWORK_DIR/rules/RULE_IMPROVEMENTS.md" ] && echo "  ✅ RULE_IMPROVEMENTS.md" || echo "  ⚠️  RULE_IMPROVEMENTS.md missing"
else
    echo "⚠️  AI Collaboration Management framework incomplete"
fi

echo ""

# ============================================================================
# Installation Complete
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$INSTALL_SUCCESS" = true ]; then
    echo "✅ TCC Installation Complete!"
else
    echo "⚠️  TCC Installation Complete with Warnings"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Post-Installation Steps:"
echo ""
echo "1. Reload your shell configuration:"
echo "   source $SHELL_RC"
echo ""
echo "2. Run TCC initialization:"
echo "   source ~/tcc-init.sh"
echo ""
echo "3. Verify installation:"
echo "   tcc-status"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 For TCC: Your First Command in Every New Session"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  source ~/tcc-init.sh"
echo ""
echo "This gives you immediate access to:"
echo "  • tcc-status   - Framework status"
echo "  • tcc-board    - View BOARD.md"
echo "  • tcc-rules    - View AI rules"
echo "  • tcc-startup  - View startup protocol"
echo "  • tcc-setup    - Configure for current project"
echo "  • tcc-sync     - Update framework"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
