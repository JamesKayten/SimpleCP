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

# Copy .ai task framework files
cp "$SCRIPT_DIR/templates/AI_README_TEMPLATE.md" "$REPO_ROOT/.ai/README.md"
cp "$SCRIPT_DIR/templates/OCC_COMMANDS_TEMPLATE.md" "$REPO_ROOT/.ai/OCC_COMMANDS.md"
cp "$SCRIPT_DIR/templates/BEHAVIOR_RULES_TEMPLATE.md" "$REPO_ROOT/.ai/BEHAVIOR_RULES.md"
cp "$SCRIPT_DIR/templates/FRAMEWORK_USAGE_TEMPLATE.md" "$REPO_ROOT/.ai/FRAMEWORK_USAGE.md"
cp "$SCRIPT_DIR/templates/TCC_QUICK_REFERENCE_TEMPLATE.md" "$REPO_ROOT/.ai/TCC_QUICK_REFERENCE.md"
cp "$SCRIPT_DIR/templates/STATUS_TEMPLATE" "$REPO_ROOT/.ai/STATUS"
cp "$SCRIPT_DIR/templates/CURRENT_TASK_TEMPLATE.md" "$REPO_ROOT/.ai/CURRENT_TASK.md"
cp "$SCRIPT_DIR/templates/check-tasks.sh" "$REPO_ROOT/.ai/check-tasks.sh"
chmod +x "$REPO_ROOT/.ai/check-tasks.sh"

echo "⚙️  Configuring for your project..."

# Get project name
PROJECT_NAME=$(basename "$REPO_ROOT")
echo "📝 Project name detected: $PROJECT_NAME"

# Replace placeholders in templates
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed syntax
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/AI_WORKFLOW.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/ai_communication/README.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/README.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/OCC_COMMANDS.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/BEHAVIOR_RULES.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/CURRENT_TASK.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/STATUS"
else
    # Linux sed syntax
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/AI_WORKFLOW.md"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/ai_communication/README.md"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/README.md"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/OCC_COMMANDS.md"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/BEHAVIOR_RULES.md"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/CURRENT_TASK.md"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/.ai/STATUS"
fi

echo "✅ Installation complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Edit docs/ai_communication/VALIDATION_RULES.md for your project"
echo "2. Customize .ai/BEHAVIOR_RULES.md with project-specific requirements"
echo "3. Commit the framework files to your repository"
echo "4. AI agents: Use 'check the board' to detect tasks immediately"
echo ""
echo "📖 Documentation:"
echo "   - Framework overview: docs/AI_COLLABORATION_FRAMEWORK.md"
echo "   - Task framework: .ai/FRAMEWORK_USAGE.md"
echo "   - OCC commands: .ai/OCC_COMMANDS.md (NEW!)"
echo "   - TCC quick start: .ai/TCC_QUICK_REFERENCE.md"
echo "   - Communication guide: docs/ai_communication/README.md"
echo ""
echo "🎯 Ready for AI-to-AI collaboration!"
echo "   💡 OCC agents can now respond to 'check the board' immediately!"