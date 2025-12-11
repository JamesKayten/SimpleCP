#!/bin/bash
# SimpleCP Validation Suite

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_DIR="$REPO_ROOT/scripts/validation"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

source "$(dirname "$0")/common.sh"

echo -e "${CYAN}==========================================
SimpleCP Validation Suite
==========================================
Repository: SimpleCP
Timestamp:  $TIMESTAMP
==========================================${NC}
"

TOTAL_ERRORS=0
TOTAL_WARNINGS=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_script=$1
    local test_name=$2

    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Running: $test_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    OUTPUT=$($test_script 2>&1)
    EXIT_CODE=$?
    echo "$OUTPUT"

    ERRORS=$(echo "$OUTPUT" | grep "^Errors:" | awk '{print $2}' || echo "0")
    WARNINGS=$(echo "$OUTPUT" | grep "^Warnings:" | awk '{print $2}' || echo "0")
    TOTAL_ERRORS=$((TOTAL_ERRORS + ERRORS))
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + WARNINGS))

    if [ $EXIT_CODE -eq 0 ]; then
        if [ "$WARNINGS" -eq 0 ]; then
            echo -e "${GREEN}✓ PASSED${NC}"
        else
            echo -e "${YELLOW}⚠ PASSED WITH WARNINGS${NC}"
        fi
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
    fi

    return $EXIT_CODE
}

# Run available tests
run_test "$SCRIPT_DIR/test_git_status.sh" "Git Status"

echo -e "\n${CYAN}==========================================
Validation Summary
==========================================${NC}"
echo -e "Tests Passed:    ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed:    ${RED}$TESTS_FAILED${NC}"
echo -e "Total Errors:    ${RED}$TOTAL_ERRORS${NC}"
echo -e "Total Warnings:  ${YELLOW}$TOTAL_WARNINGS${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ] && [ $TOTAL_ERRORS -eq 0 ]; then
    if [ $TOTAL_WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ ALL VALIDATION TESTS PASSED${NC}"
    else
        echo -e "${YELLOW}⚠ TESTS PASSED WITH WARNINGS${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ VALIDATION TESTS FAILED${NC}"
    exit 1
fi
