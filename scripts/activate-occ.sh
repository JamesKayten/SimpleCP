#!/bin/bash

# OCC ACTIVATION SCRIPT
# Purpose: Generate standard prompt to activate Online Claude Code (browser) for addressing validation reports
# Usage: Run this script to get the command to paste into browser Claude

set -e

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}    🌐 ONLINE CLAUDE (OCC) ACTIVATION HELPER${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Not in a git repository${NC}"
    exit 1
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel)
PROJECT_NAME=$(basename "$PROJECT_ROOT")

# Check if framework is installed
if [ ! -d "$PROJECT_ROOT/framework" ]; then
    echo -e "${YELLOW}⚠️  AI Framework not installed in this project${NC}"
    echo -e "   Run the installer first: setup-ai-collaboration.sh"
    exit 1
fi

echo -e "${BLUE}📁 Project:${NC} $PROJECT_NAME"
echo -e "${BLUE}📍 Location:${NC} $PROJECT_ROOT"
echo ""

# Check for validation reports
REPORTS_DIR="$PROJECT_ROOT/framework/communications/reports"
if [ ! -d "$REPORTS_DIR" ]; then
    echo -e "${YELLOW}⚠️  Reports directory not found${NC}"
    exit 1
fi

# Find latest report
LATEST_REPORT=$(find "$REPORTS_DIR" -name "AI_REPORT_*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

if [ -z "$LATEST_REPORT" ]; then
    # Get current branch and remote
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    GIT_REMOTE=$(git config --get remote.origin.url 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' || echo "repository")

    echo -e "${GREEN}✅ No validation reports found${NC}"
    echo -e "   Everything appears to be clean!"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}   OCC Activation Code (if you want status check):${NC}"
    echo ""
    echo -e "${GREEN}   framework check${NC}"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}📍 Repository:${NC} ${GIT_REMOTE}"
    echo -e "${BLUE}🌿 Branch:${NC} ${CURRENT_BRANCH}"
    echo ""
else
    # Report found
    REPORT_NAME=$(basename "$LATEST_REPORT")
    REPORT_AGE=$(stat -c %y "$LATEST_REPORT" 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$LATEST_REPORT")

    echo -e "${YELLOW}📋 Validation Report Found:${NC}"
    echo -e "   ${REPORT_NAME}"
    echo -e "   Created: ${REPORT_AGE}"
    echo ""

    # Show report preview
    echo -e "${BLUE}📄 Report Preview:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    head -20 "$LATEST_REPORT" | sed 's/^/   /'
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Get current branch and remote
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    GIT_REMOTE=$(git config --get remote.origin.url 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' || echo "repository")

    echo -e "${YELLOW}⚠️  ACTION REQUIRED ⚠️${NC}"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}   OCC Activation Code (copy and paste):${NC}"
    echo ""
    echo -e "${GREEN}   framework check${NC}"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}💡 First time? Set up custom instructions in Claude:${NC}"
    echo -e "${CYAN}   See: OCC_ACTIVATION_CODE.md for setup guide${NC}"
    echo ""
    echo -e "${BLUE}📍 Repository:${NC} ${GIT_REMOTE}"
    echo -e "${BLUE}🌿 Branch:${NC} ${CURRENT_BRANCH}"
    echo -e "${BLUE}📋 Latest Report:${NC} ${REPORT_NAME}"
    echo ""
fi

echo -e "${BLUE}🔄 After OCC completes fixes:${NC}"
echo -e "   1. OCC will create response in framework/communications/responses/"
echo -e "   2. OCC will commit and push changes to GitHub"
echo -e "   3. Run 'work ready' in terminal (after pulling) to re-validate"
echo -e "   4. If clean, Local AI will merge automatically"
echo ""

# Check for existing responses
RESPONSES_DIR="$PROJECT_ROOT/framework/communications/responses"
RESPONSE_COUNT=$(find "$RESPONSES_DIR" -name "AI_RESPONSE_*.md" -type f 2>/dev/null | wc -l)

if [ "$RESPONSE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}📬 Found $RESPONSE_COUNT existing response(s)${NC}"
    echo -e "   Latest responses:"
    find "$RESPONSES_DIR" -name "AI_RESPONSE_*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -3 | while read -r line; do
        response_file=$(echo "$line" | cut -d' ' -f2-)
        response_name=$(basename "$response_file")
        echo -e "   • ${response_name}"
    done
    echo ""
fi

# Show quick stats
echo -e "${BLUE}📊 Communication Stats:${NC}"
TOTAL_REPORTS=$(find "$REPORTS_DIR" -name "AI_REPORT_*.md" -type f 2>/dev/null | wc -l)
TOTAL_RESPONSES=$(find "$RESPONSES_DIR" -name "AI_RESPONSE_*.md" -type f 2>/dev/null | wc -l)
echo -e "   Reports created: $TOTAL_REPORTS"
echo -e "   Responses received: $TOTAL_RESPONSES"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ OCC Activation Helper Complete${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
