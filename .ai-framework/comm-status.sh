#!/bin/bash
# Quick Communication Status Checker
# Instantly checks current PING/PONG status without starting full monitor

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AI_DIR="$PROJECT_ROOT/.ai"
PING_FILE="$AI_DIR/PING_TEST.md"
PONG_FILE="$AI_DIR/PONG_RESPONSE.md"
STATUS_FILE="$AI_DIR/AUTO_COMM_STATUS.md"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Framework Communication Status Check${NC}"
echo "---"

# Check if monitoring is active
if pgrep -f "auto-communication-monitor.sh" > /dev/null; then
    echo -e "${GREEN}✅ Automatic Monitor: ACTIVE${NC}"
else
    echo -e "${YELLOW}⏸️  Automatic Monitor: INACTIVE${NC}"
fi

echo ""

# Check PING status
if [[ -f "$PING_FILE" ]]; then
    echo -e "${BLUE}🏓 PING Status:${NC}"
    ping_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$PING_FILE" 2>/dev/null || echo "Unknown")
    test_id=$(grep -o "Test ID: PING-[0-9]*" "$PING_FILE" 2>/dev/null || echo "Unknown")
    math_problem=$(grep -E "[0-9]+ [×x*+\-] [0-9]+ = \?" "$PING_FILE" 2>/dev/null | head -1 || echo "No calculation")

    echo "   ✅ File exists"
    echo "   📅 Last modified: $ping_date"
    echo "   🎯 $test_id"
    echo "   🧮 Math: $math_problem"
else
    echo -e "${RED}🏓 PING Status: No PING file found${NC}"
fi

echo ""

# Check PONG status
if [[ -f "$PONG_FILE" ]]; then
    echo -e "${BLUE}🎾 PONG Status:${NC}"
    pong_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$PONG_FILE" 2>/dev/null || echo "Unknown")
    test_id=$(grep -o "Test ID: PONG-[0-9]*\|PONG-[0-9]*" "$PONG_FILE" 2>/dev/null | head -1 || echo "Unknown")
    from_ai=$(grep -o "From:** [A-Z]*" "$PONG_FILE" 2>/dev/null || echo "Unknown AI")
    calculation=$(grep -E "[0-9,]+ = [0-9,]+" "$PONG_FILE" 2>/dev/null | head -1 || echo "No calculation")

    echo "   ✅ File exists"
    echo "   📅 Last modified: $pong_date"
    echo "   🎯 Response: $test_id"
    echo "   🤖 $from_ai"
    echo "   🧮 Result: $calculation"
else
    echo -e "${YELLOW}🎾 PONG Status: No PONG response found${NC}"
fi

echo ""

# Check monitor status file
if [[ -f "$STATUS_FILE" ]]; then
    echo -e "${BLUE}📊 Auto-Monitor Status:${NC}"
    status_line=$(head -5 "$STATUS_FILE" | grep "Status:" | cut -d: -f2- | xargs)
    last_updated=$(head -5 "$STATUS_FILE" | grep "Last Updated:" | cut -d: -f2- | xargs)
    echo "   📋 $status_line"
    echo "   ⏰ $last_updated"
else
    echo -e "${YELLOW}📊 Auto-Monitor: No status file (never started)${NC}"
fi

echo ""

# Check for pending remote updates
cd "$PROJECT_ROOT" 2>/dev/null
if git fetch origin >/dev/null 2>&1; then
    behind=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
    if [[ "$behind" -gt 0 ]]; then
        echo -e "${YELLOW}📡 Remote Updates: $behind new commits available${NC}"
    else
        echo -e "${GREEN}📡 Remote Updates: Up to date${NC}"
    fi
else
    echo -e "${RED}📡 Remote Updates: Unable to check${NC}"
fi

echo ""
echo -e "${BLUE}Commands:${NC}"
echo "  Start Monitor:  ./.ai-framework/start-comm-monitor.sh"
echo "  Stop Monitor:   pkill -f auto-communication-monitor.sh"
echo "  View Logs:      tail -f .ai/communication.log"