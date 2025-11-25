#!/bin/bash
# Documentation Integrity Validation Tests
# Verifies all documentation links, references, and content accuracy


REPO_ROOT="/home/user/AI-Collaboration-Management"
TEST_NAME="Documentation Integrity Validation"
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

# Test 1: README.md references are accurate
echo "Test 1: README.md Internal References"
echo "--------------------------------------"
cd "$REPO_ROOT"

# Check that README mentions correct port
if grep -q "localhost:8000" README.md; then
    pass "README uses correct port (8000)"
else
    if grep -q "localhost:8080" README.md; then
        fail "README uses WRONG port (8080) - should be 8000"
    else
        warn "Port reference not found in README"
    fi
fi

# Check documentation links in README
DOC_LINKS=(
    "docs/API.md"
    "docs/UI_UX_SPECIFICATION_v3.md"
    "docs/USER_GUIDE.md"
    "docs/BOARD.md"
    "docs/AI_COLLABORATION_FRAMEWORK.md"
    "docs/tcc/TCC_WORKFLOW_GUIDE.md"
    "docs/tcc/README_TCC_INSTALLATION.md"
    "docs/reports/INTEGRATION_TEST_REPORT.md"
    "docs/reports/PORT_8000_FIX_IMPLEMENTATION.md"
)

for link in "${DOC_LINKS[@]}"; do
    if grep -q "$link" README.md; then
        if [ -f "$REPO_ROOT/$link" ]; then
            pass "README link valid: $link"
        else
            fail "README link broken: $link (file doesn't exist)"
        fi
    else
        warn "README missing link: $link"
    fi
done
echo ""

# Test 2: Check for broken internal links
echo "Test 2: Documentation Cross-References"
echo "---------------------------------------"

# Find all markdown files
MD_FILES=$(find "$REPO_ROOT/docs" -name "*.md" -type f)

for md_file in $MD_FILES; do
    # Extract markdown links [text](path)
    LINKS=$(grep -oP '\[([^\]]+)\]\(([^)]+)\)' "$md_file" | grep -oP '\(([^)]+)\)' | tr -d '()' || true)

    for link in $LINKS; do
        # Skip external URLs
        if [[ "$link" =~ ^https?:// ]]; then
            continue
        fi

        # Skip anchor links
        if [[ "$link" =~ ^# ]]; then
            continue
        fi

        # Check if file exists (relative to docs/)
        LINK_PATH="$REPO_ROOT/docs/$link"
        if [ ! -f "$LINK_PATH" ]; then
            # Try relative to repo root
            LINK_PATH="$REPO_ROOT/$link"
            if [ ! -f "$LINK_PATH" ]; then
                warn "Broken link in $(basename $md_file): $link"
            fi
        fi
    done
done
pass "Documentation cross-reference check completed"
echo ""

# Test 3: Verify navigation guide exists
echo "Test 3: Navigation Guide"
echo "------------------------"
if [ -f "$REPO_ROOT/docs/README_ORGANIZATION.md" ]; then
    pass "Navigation guide exists: docs/README_ORGANIZATION.md"

    # Check it references key directories
    if grep -q "/tcc/" "$REPO_ROOT/docs/README_ORGANIZATION.md"; then
        pass "Navigation guide references TCC directory"
    else
        warn "Navigation guide missing TCC directory reference"
    fi

    if grep -q "/reports/" "$REPO_ROOT/docs/README_ORGANIZATION.md"; then
        pass "Navigation guide references reports directory"
    else
        warn "Navigation guide missing reports directory reference"
    fi
else
    fail "Navigation guide missing: docs/README_ORGANIZATION.md"
fi
echo ""

# Test 4: Script paths in documentation
echo "Test 4: Script Path References"
echo "-------------------------------"

# Check if README references scripts in correct locations
SCRIPT_REFS=(
    "scripts/backend/kill_backend.sh"
    "scripts/sync/sync-from-aicm.sh"
    "scripts/sync/sync-to-aicm.sh"
    "scripts/tcc/install-tcc.sh"
)

for script in "${SCRIPT_REFS[@]}"; do
    if grep -q "$script" README.md; then
        pass "README references script correctly: $script"
    else
        # Check for old paths
        OLD_PATH=$(basename "$script")
        if grep -q "$OLD_PATH" README.md && ! grep -q "$script" README.md; then
            fail "README uses old script path: $OLD_PATH (should be $script)"
        else
            warn "README doesn't reference: $script"
        fi
    fi
done
echo ""

# Test 5: Check for outdated content
echo "Test 5: Outdated Content Detection"
echo "-----------------------------------"

# Check for references to old structure
OUTDATED_PATTERNS=(
    "rules/"
    "tcc-config-files/"
)

cd "$REPO_ROOT"
for pattern in "${OUTDATED_PATTERNS[@]}"; do
    if grep -r "$pattern" README.md 2>/dev/null | grep -v "framework/$pattern" > /dev/null; then
        warn "README may reference old structure: $pattern (should be framework/$pattern)"
    fi
done

pass "Outdated content check completed"
echo ""

# Test 6: Key information accuracy
echo "Test 6: Technical Accuracy"
echo "--------------------------"

# Check backend entry point is documented
if grep -q "main.py" README.md; then
    pass "Backend entry point documented: main.py"
else
    warn "Backend entry point not mentioned in README"
fi

# Check frontend entry point is documented
if grep -q "Package.swift" README.md || grep -q "swift run" README.md; then
    pass "Frontend build process documented"
else
    warn "Frontend build process not clear in README"
fi

# Check architecture section exists
if grep -q "## 🔧 Architecture" README.md || grep -q "## Architecture" README.md; then
    pass "Architecture section exists in README"
else
    warn "Architecture section missing from README"
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
    echo -e "${GREEN}✓ All documentation integrity tests passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Documentation tests passed with warnings${NC}"
    exit 0
else
    echo -e "${RED}✗ Documentation tests failed with $ERRORS errors${NC}"
    exit 1
fi
