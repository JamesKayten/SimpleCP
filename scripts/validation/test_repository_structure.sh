#!/bin/bash
# Repository Structure Validation Tests
# Tests that the repository organization is correct and complete


REPO_ROOT="/home/user/AI-Collaboration-Management"
TEST_NAME="Repository Structure Validation (AICM)"
ERRORS=0
WARNINGS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "$TEST_NAME"
echo "=========================================="
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Test 1: Core directories exist
echo "Test 1: Core Directories"
echo "------------------------"
for dir in docs scripts templates tests examples framework .claude; do
    if [ -d "$REPO_ROOT/$dir" ]; then
        pass "Directory exists: $dir/"
    else
        fail "Missing directory: $dir/"
    fi
done
echo ""

# Test 2: Documentation organization
echo "Test 2: Documentation Organization"
echo "-----------------------------------"
for dir in docs/tcc docs/reports docs/framework; do
    if [ -d "$REPO_ROOT/$dir" ]; then
        pass "Documentation directory exists: $dir/"
    else
        warn "Documentation directory missing: $dir/"
    fi
done
echo ""

# Test 3: Scripts organization
echo "Test 3: Scripts Organization"
echo "----------------------------"
for dir in scripts/validation scripts/utilities; do
    if [ -d "$REPO_ROOT/$dir" ]; then
        pass "Scripts directory exists: $dir/"
    else
        fail "Missing scripts directory: $dir/"
    fi
done
echo ""

# Test 4: Required files in root
echo "Test 4: Required Root Files"
echo "---------------------------"
for file in README.md .gitignore LICENSE; do
    if [ -f "$REPO_ROOT/$file" ]; then
        pass "Required file exists: $file"
    else
        fail "Missing required file: $file"
    fi
done
echo ""

# Test 5: Old files should NOT exist in root
echo "Test 5: Root Directory Cleanliness"
echo "-----------------------------------"
OLD_FILES=(
    "BOARD.md"
    "TASKS.md"
    "TCC_WORKFLOW_GUIDE.md"
    "MASTER_FRAMEWORK_STATUS.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "ai"
    "SIP Enable.pages"
)

for file in "${OLD_FILES[@]}"; do
    if [ -f "$REPO_ROOT/$file" ]; then
        fail "File should be moved: $file (root directory should be clean)"
    else
        pass "File properly moved: $file"
    fi
done

# Check for moved directories
OLD_DIRS=(
    "rules"
    "tcc-setup"
)

for dir in "${OLD_DIRS[@]}"; do
    if [ -d "$REPO_ROOT/$dir" ]; then
        fail "Directory should be moved: $dir/ (should be in framework/)"
    else
        pass "Directory properly moved: $dir/"
    fi
done
echo ""

# Test 6: Scripts are executable
echo "Test 6: Script Executability"
echo "----------------------------"
SCRIPTS=(
    "scripts/utilities/ai"
    "scripts/validation/run_all_tests.sh"
    "scripts/validation/test_repository_structure.sh"
    "scripts/validation/test_documentation_integrity.sh"
    "scripts/validation/test_git_status.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$REPO_ROOT/$script" ]; then
        if [ -x "$REPO_ROOT/$script" ]; then
            pass "Script is executable: $script"
        else
            fail "Script is NOT executable: $script"
        fi
    else
        warn "Script missing: $script"
    fi
done
echo ""

# Test 7: Key documentation files moved correctly
echo "Test 7: Documentation File Migration"
echo "------------------------------------"
MOVED_DOCS=(
    "docs/BOARD.md"
    "docs/TASKS.md"
    "docs/MASTER_FRAMEWORK_STATUS.md"
    "docs/CHANGELOG.md"
    "docs/CONTRIBUTING.md"
    "docs/tcc/TCC_WORKFLOW_GUIDE.md"
)

for file in "${MOVED_DOCS[@]}"; do
    if [ -f "$REPO_ROOT/$file" ]; then
        pass "Documentation correctly moved: $file"
    else
        fail "Documentation NOT moved: $file"
    fi
done
echo ""

# Test 8: AI Framework structure
echo "Test 8: AI Framework Structure"
echo "-------------------------------"
AI_FRAMEWORK_DIRS=(
    "framework/rules"
    "framework/tcc-setup"
)

for dir in "${AI_FRAMEWORK_DIRS[@]}"; do
    if [ -d "$REPO_ROOT/$dir" ]; then
        pass "AI Framework directory exists: $dir/"
    else
        fail "AI Framework directory missing: $dir/"
    fi
done
echo ""

# Test 9: Validation framework
echo "Test 9: Validation Framework"
echo "-----------------------------"
if [ -d "$REPO_ROOT/scripts/validation" ]; then
    pass "Validation framework installed"

    # Check for validation scripts
    VAL_SCRIPTS=(
        "run_all_tests.sh"
        "test_repository_structure.sh"
        "test_documentation_integrity.sh"
        "test_git_status.sh"
    )

    for script in "${VAL_SCRIPTS[@]}"; do
        if [ -f "$REPO_ROOT/scripts/validation/$script" ]; then
            pass "Validation script exists: $script"
        else
            fail "Validation script missing: $script"
        fi
    done
else
    fail "Validation framework NOT installed"
fi
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Tests passed with warnings${NC}"
    exit 0
else
    echo -e "${RED}✗ Tests failed with $ERRORS errors${NC}"
    exit 1
fi
