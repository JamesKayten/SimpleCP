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

echo "⚙️  Configuring for your project..."

# Get project name
PROJECT_NAME=$(basename "$REPO_ROOT")
echo "📝 Project name detected: $PROJECT_NAME"

# Replace placeholders in templates
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed syntax
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/AI_WORKFLOW.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/ai_communication/README.md"
else
    # Linux sed syntax
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/AI_WORKFLOW.md"
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$REPO_ROOT/docs/ai_communication/README.md"
fi

echo "✅ Installation complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Edit docs/ai_communication/VALIDATION_RULES.md for your project"
echo "2. Customize docs/AI_WORKFLOW.md for your specific requirements"
echo "3. Commit the framework files to your repository"
echo "4. Start using AI collaboration with 'work ready' command"
echo ""
echo "📖 Documentation:"
echo "   - Framework overview: docs/AI_COLLABORATION_FRAMEWORK.md"
echo "   - Workflow setup: docs/AI_WORKFLOW.md"
echo "   - Communication guide: docs/ai_communication/README.md"
echo ""
echo "🎯 Ready for AI-to-AI collaboration!"