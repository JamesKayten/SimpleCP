#!/bin/bash

# AI Collaboration Framework Installer
# Deploys framework to any repository for Local ↔ Online AI collaboration

set -e

echo "🚀 AI Collaboration Framework Installer"
echo "======================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository. Please run from your project root."
    exit 1
fi

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
echo "📍 Repository: $REPO_ROOT"

# Create framework structure
echo "📁 Creating framework structure..."
mkdir -p "$REPO_ROOT/docs/ai_communication"
mkdir -p "$REPO_ROOT/.ai"
mkdir -p "$REPO_ROOT/.ai-framework"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Copy template files
echo "📄 Installing framework files..."

# Copy communication folder template
cp "$SCRIPT_DIR/templates/ai_communication_README.md" "$REPO_ROOT/docs/ai_communication/README.md"

# Copy workflow template
cp "$SCRIPT_DIR/templates/AI_WORKFLOW_TEMPLATE.md" "$REPO_ROOT/docs/AI_WORKFLOW.md"

# Copy configuration templates
cp "$SCRIPT_DIR/templates/VALIDATION_RULES_TEMPLATE.md" "$REPO_ROOT/docs/ai_communication/VALIDATION_RULES.md"

# Copy framework documentation
cp "$SCRIPT_DIR/templates/FRAMEWORK_OVERVIEW.md" "$REPO_ROOT/docs/AI_COLLABORATION_FRAMEWORK.md"

# Install task assignment system
echo "📋 Installing task assignment system..."
cp "$SCRIPT_DIR/templates/STATUS_TEMPLATE" "$REPO_ROOT/.ai/STATUS"
cp "$SCRIPT_DIR/templates/CURRENT_TASK_TEMPLATE.md" "$REPO_ROOT/.ai/CURRENT_TASK.md"
cp "$SCRIPT_DIR/templates/README_TEMPLATE.md" "$REPO_ROOT/.ai/README.md"
cp "$SCRIPT_DIR/templates/FRAMEWORK_USAGE.md" "$REPO_ROOT/.ai/FRAMEWORK_USAGE.md"
cp "$SCRIPT_DIR/templates/TCC_QUICK_REFERENCE.md" "$REPO_ROOT/.ai/TCC_QUICK_REFERENCE.md"

# Install automation scripts
echo "🤖 Installing automation scripts..."
cp "$SCRIPT_DIR/scripts/check-tasks.sh" "$REPO_ROOT/.ai/check-tasks.sh"
cp "$SCRIPT_DIR/scripts/auto-communication-monitor.sh" "$REPO_ROOT/.ai-framework/auto-communication-monitor.sh"
cp "$SCRIPT_DIR/scripts/start-comm-monitor.sh" "$REPO_ROOT/.ai-framework/start-comm-monitor.sh"
cp "$SCRIPT_DIR/scripts/comm-status.sh" "$REPO_ROOT/.ai-framework/comm-status.sh"

# Make scripts executable
chmod +x "$REPO_ROOT/.ai/check-tasks.sh"
chmod +x "$REPO_ROOT/.ai-framework/auto-communication-monitor.sh"
chmod +x "$REPO_ROOT/.ai-framework/start-comm-monitor.sh"
chmod +x "$REPO_ROOT/.ai-framework/comm-status.sh"

echo "⚙️  Configuring for your project..."

# Get project name
PROJECT_NAME=$(basename "$REPO_ROOT")
echo "📝 Project name detected: $PROJECT_NAME"

# Replace placeholders in templates
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed syntax
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/AI_WORKFLOW.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/ai_communication/README.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/STATUS"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/CURRENT_TASK.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/README.md"
else
    # Linux sed syntax
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/AI_WORKFLOW.md"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/ai_communication/README.md"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/STATUS"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/CURRENT_TASK.md"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/README.md"
fi

echo "✅ Installation complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Customize .ai/README.md with your project details (language, tools, etc.)"
echo "2. Edit docs/ai_communication/VALIDATION_RULES.md for your project"
echo "3. Customize docs/AI_WORKFLOW.md for your specific requirements"
echo "4. Commit the framework files to your repository"
echo "5. Start using AI collaboration!"
echo ""
echo "📖 Documentation:"
echo "   - Framework overview: docs/AI_COLLABORATION_FRAMEWORK.md"
echo "   - Workflow setup: docs/AI_WORKFLOW.md"
echo "   - Communication guide: docs/ai_communication/README.md"
echo "   - Task assignment guide: .ai/TCC_QUICK_REFERENCE.md"
echo "   - Framework usage: .ai/FRAMEWORK_USAGE.md"
echo ""
echo "🤖 AI Task Assignment:"
echo "   - Quick reference: .ai/TCC_QUICK_REFERENCE.md"
echo "   - Check for tasks: ./.ai/check-tasks.sh"
echo ""
echo "📡 Communication Monitoring:"
echo "   - Start monitor: ./.ai-framework/start-comm-monitor.sh"
echo "   - Check status: ./.ai-framework/comm-status.sh"
echo ""
echo "🎯 Ready for AI-to-AI collaboration!"