#!/bin/bash
# AICM Framework Validation - Master Test Runner
# Runs all validation tests and generates comprehensive report

REPO_ROOT="/home/user/AI-Collaboration-Management"
SCRIPT_DIR="$REPO_ROOT/scripts/validation"
REPORT_FILE="$REPO_ROOT/VALIDATION_REPORT.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}=========================================="
echo "AICM Framework Validation Suite"
echo "=========================================="
echo -e "Repository: SimpleCP"
echo -e "Timestamp:  $TIMESTAMP"
echo -e "==========================================${NC}"
echo ""

# Initialize report
cat > "$REPORT_FILE" << EOF
# AICM Framework Validation Report

**Repository:** SimpleCP
**Date:** $TIMESTAMP
**Location:** $REPO_ROOT

---

## Executive Summary

This report validates that the AI Collaboration Management (AICM) framework is functioning correctly and that repository organization meets professional standards.

---

## Test Results

EOF

TOTAL_ERRORS=0
TOTAL_WARNINGS=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test and capture results
run_test() {
    local test_script=$1
    local test_name=$2

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Running: $test_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Run the test and capture output
    if OUTPUT=$($test_script 2>&1); then
        EXIT_CODE=0
    else
        EXIT_CODE=$?
    fi

    # Display output
    echo "$OUTPUT"

    # Parse results
    ERRORS=$(echo "$OUTPUT" | grep "^Errors:" | awk '{print $2}' || echo "0")
    WARNINGS=$(echo "$OUTPUT" | grep "^Warnings:" | awk '{print $2}' || echo "0")

    TOTAL_ERRORS=$((TOTAL_ERRORS + ERRORS))
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + WARNINGS))

    # Update report
    echo "### $test_name" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [ $EXIT_CODE -eq 0 ]; then
        if [ "$WARNINGS" -eq 0 ]; then
            echo -e "${GREEN}✓ PASSED${NC}"
            echo "**Status:** ✅ PASSED" >> "$REPORT_FILE"
            ((TESTS_PASSED++))
        else
            echo -e "${YELLOW}⚠ PASSED WITH WARNINGS${NC}"
            echo "**Status:** ⚠️ PASSED WITH WARNINGS" >> "$REPORT_FILE"
            ((TESTS_PASSED++))
        fi
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "**Status:** ❌ FAILED" >> "$REPORT_FILE"
        ((TESTS_FAILED++))
    fi

    echo "**Errors:** $ERRORS  " >> "$REPORT_FILE"
    echo "**Warnings:** $WARNINGS  " >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Add detailed output to report
    echo "<details>" >> "$REPORT_FILE"
    echo "<summary>Detailed Output</summary>" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo "$OUTPUT" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "</details>" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    return $EXIT_CODE
}

# Run all tests
echo -e "${CYAN}Starting validation tests...${NC}"

run_test "$SCRIPT_DIR/test_repository_structure.sh" "Test Suite 1: Repository Structure"
run_test "$SCRIPT_DIR/test_documentation_integrity.sh" "Test Suite 2: Documentation Integrity"
run_test "$SCRIPT_DIR/test_git_status.sh" "Test Suite 3: Git Status & Sync"

# Generate summary
echo ""
echo -e "${CYAN}=========================================="
echo "Validation Summary"
echo "==========================================${NC}"
echo -e "Tests Passed:    ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed:    ${RED}$TESTS_FAILED${NC}"
echo -e "Total Errors:    ${RED}$TOTAL_ERRORS${NC}"
echo -e "Total Warnings:  ${YELLOW}$TOTAL_WARNINGS${NC}"
echo ""

# Add summary to report
cat >> "$REPORT_FILE" << EOF

## Overall Summary

| Metric | Count |
|--------|-------|
| Tests Passed | $TESTS_PASSED |
| Tests Failed | $TESTS_FAILED |
| Total Errors | $TOTAL_ERRORS |
| Total Warnings | $TOTAL_WARNINGS |

EOF

# Final verdict
if [ $TESTS_FAILED -eq 0 ] && [ $TOTAL_ERRORS -eq 0 ]; then
    if [ $TOTAL_WARNINGS -eq 0 ]; then
        echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  ✓ ALL VALIDATION TESTS PASSED!          ║${NC}"
        echo -e "${GREEN}║    AICM Framework functioning correctly  ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"

        cat >> "$REPORT_FILE" << EOF

## Verdict

### ✅ **ALL TESTS PASSED**

The AICM framework is functioning correctly. The repository is properly organized, documentation is accurate, and all validation checks have passed.

**Status:** 🟢 **PRODUCTION READY**

EOF
        FINAL_EXIT=0
    else
        echo -e "${YELLOW}╔═══════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  ⚠ TESTS PASSED WITH WARNINGS            ║${NC}"
        echo -e "${YELLOW}║    Review warnings for minor issues      ║${NC}"
        echo -e "${YELLOW}╚═══════════════════════════════════════════╝${NC}"

        cat >> "$REPORT_FILE" << EOF

## Verdict

### ⚠️ **PASSED WITH WARNINGS**

All critical tests passed, but some warnings were detected. Review the warnings above to address minor issues.

**Status:** 🟡 **READY WITH MINOR ISSUES**

EOF
        FINAL_EXIT=0
    fi
else
    echo -e "${RED}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ VALIDATION TESTS FAILED                ║${NC}"
    echo -e "${RED}║    Critical issues detected!             ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════╝${NC}"

    cat >> "$REPORT_FILE" << EOF

## Verdict

### ❌ **TESTS FAILED**

Critical issues detected! Review the errors above and fix them before proceeding.

**Status:** 🔴 **NOT READY - REQUIRES FIXES**

### Action Items

1. Review all failed tests above
2. Fix critical errors
3. Address warnings
4. Re-run validation: \`./scripts/validation/run_all_tests.sh\`

EOF
    FINAL_EXIT=1
fi

echo ""
echo -e "${CYAN}Report saved to: ${YELLOW}$REPORT_FILE${NC}"
echo ""

# Add footer to report
cat >> "$REPORT_FILE" << EOF

---

## About This Report

This validation report was generated automatically by the AICM Framework Validation Suite. It verifies:

1. **Repository Structure** - Ensures proper organization and file placement
2. **Documentation Integrity** - Validates links, references, and content accuracy
3. **Git & Sync Status** - Checks version control and AICM integration

To re-run validation:
\`\`\`bash
cd $REPO_ROOT
./scripts/validation/run_all_tests.sh
\`\`\`

**Generated:** $TIMESTAMP
**Framework:** AI Collaboration Management (AICM)
**Purpose:** Quality assurance for AI-managed repositories

EOF

exit $FINAL_EXIT
