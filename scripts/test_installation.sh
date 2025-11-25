#!/bin/bash

# AI Collaboration Framework - Installation Test Script
# Tests that the framework installs correctly and all files are in place

set -e

echo "🧪 AI Collaboration Framework - Installation Test"
echo "================================================="

# Function to check if file exists and has content
check_file() {
    local file=$1
    local description=$2

    if [[ -f "$file" ]]; then
        if [[ -s "$file" ]]; then
            echo "✅ $description: $file"
            return 0
        else
            echo "⚠️  $description exists but is empty: $file"
            return 1
        fi
    else
        echo "❌ $description missing: $file"
        return 1
    fi
}

# Function to check if placeholder was replaced
check_placeholder() {
    local file=$1
    local description=$2

    if [[ -f "$file" ]]; then
        if grep -q "{{PROJECT_NAME}}" "$file"; then
            echo "❌ Placeholder not replaced in $description: $file"
            return 1
        else
            echo "✅ $description placeholders replaced: $file"
            return 0
        fi
    else
        echo "❌ $description file missing: $file"
        return 1
    fi
}

echo "📍 Testing in directory: $(pwd)"
echo "📍 Git repository: $(git rev-parse --show-toplevel 2>/dev/null || echo 'Not a git repo')"

# Test 1: Check framework structure
echo ""
echo "🏗️  Test 1: Framework Structure"
echo "------------------------------"

failed_tests=0

check_file "docs/AI_COLLABORATION_FRAMEWORK.md" "Framework Overview" || ((failed_tests++))
check_file "docs/AI_WORKFLOW.md" "Workflow Document" || ((failed_tests++))
check_file "docs/ai_communication/README.md" "Communication Guide" || ((failed_tests++))
check_file "docs/ai_communication/VALIDATION_RULES.md" "Validation Rules" || ((failed_tests++))

# Test 2: Check placeholders were replaced
echo ""
echo "🔧 Test 2: Placeholder Replacement"
echo "----------------------------------"

check_placeholder "docs/AI_WORKFLOW.md" "Workflow Document" || ((failed_tests++))
check_placeholder "docs/ai_communication/README.md" "Communication Guide" || ((failed_tests++))

# Test 3: Check content quality
echo ""
echo "📄 Test 3: Content Quality"
echo "--------------------------"

# Check that workflow has essential sections
if grep -q "Work Ready.*Command Workflow" docs/AI_WORKFLOW.md; then
    echo "✅ Workflow document has required sections"
else
    echo "❌ Workflow document missing required sections"
    ((failed_tests++))
fi

# Check that validation rules have examples
if grep -q "file_size_limits\|validation_requirements" docs/ai_communication/VALIDATION_RULES.md; then
    echo "✅ Validation rules have configuration examples"
else
    echo "❌ Validation rules missing configuration examples"
    ((failed_tests++))
fi

# Test 4: Check project integration
echo ""
echo "🔗 Test 4: Project Integration"
echo "------------------------------"

# Check project name detection
project_name=$(basename "$(pwd)")
if grep -q "$project_name" docs/AI_WORKFLOW.md; then
    echo "✅ Project name '$project_name' integrated into workflow"
else
    echo "❌ Project name '$project_name' not found in workflow"
    ((failed_tests++))
fi

# Test 5: File permissions and executability
echo ""
echo "🔐 Test 5: File Permissions"
echo "---------------------------"

# Check that documentation files are readable
if [[ -r "docs/AI_WORKFLOW.md" ]]; then
    echo "✅ Documentation files are readable"
else
    echo "❌ Documentation files have permission issues"
    ((failed_tests++))
fi

# Test 6: Git integration
echo ""
echo "📁 Test 6: Git Integration"
echo "--------------------------"

if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "✅ Framework installed in git repository"

    # Check git status
    if git status --porcelain | grep -q "docs/"; then
        echo "✅ Framework files detected by git (ready to commit)"
    else
        echo "⚠️  Framework files not detected by git (may be already committed)"
    fi
else
    echo "❌ Not in a git repository"
    ((failed_tests++))
fi

# Test 7: Validation command structure
echo ""
echo "⚙️  Test 7: Validation Setup"
echo "----------------------------"

if grep -q "validation_commands\|bash\|python\|npm" docs/ai_communication/VALIDATION_RULES.md; then
    echo "✅ Validation rules include command examples"
else
    echo "⚠️  Validation rules may need command examples"
fi

# Final results
echo ""
echo "📊 Test Results Summary"
echo "======================"

if [[ $failed_tests -eq 0 ]]; then
    echo "🎉 ALL TESTS PASSED! Framework installation successful."
    echo ""
    echo "✅ Ready to use AI collaboration commands:"
    echo "   - 'work ready' (for Local AI)"
    echo "   - 'Check docs/ai_communication/ for latest report and address the issues' (for Online AI)"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Customize docs/ai_communication/VALIDATION_RULES.md for your project"
    echo "   2. Commit framework files: git add docs/ && git commit -m 'Add AI collaboration framework'"
    echo "   3. Start using AI collaboration workflow"

    exit 0
else
    echo "❌ $failed_tests test(s) failed. Framework may not be properly installed."
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   - Re-run the installation script"
    echo "   - Check file permissions"
    echo "   - Verify you're in a git repository"
    echo "   - Check available disk space"

    exit 1
fi