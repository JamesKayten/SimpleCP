#!/bin/bash
# Start Background Communication Monitor
# Launches the automatic PING/PONG monitor as a background process

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITOR_SCRIPT="$SCRIPT_DIR/auto-communication-monitor.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if already running
if pgrep -f "auto-communication-monitor.sh" > /dev/null; then
    echo -e "${YELLOW}⚠️  Communication monitor is already running${NC}"
    echo ""
    echo "To check status: ./.ai-framework/comm-status.sh"
    echo "To stop monitor: pkill -f auto-communication-monitor.sh"
    exit 1
fi

# Check if monitor script exists
if [[ ! -f "$MONITOR_SCRIPT" ]]; then
    echo -e "${RED}❌ Monitor script not found: $MONITOR_SCRIPT${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Starting Automatic Communication Monitor${NC}"
echo ""

# Start monitor in background
nohup "$MONITOR_SCRIPT" > /dev/null 2>&1 &
MONITOR_PID=$!

# Verify it started
sleep 2
if kill -0 $MONITOR_PID 2>/dev/null; then
    echo -e "${GREEN}✅ Monitor started successfully (PID: $MONITOR_PID)${NC}"
    echo ""
    echo -e "${BLUE}📋 What it monitors:${NC}"
    echo "   • PING_TEST.md changes (new requests from other AIs)"
    echo "   • PONG_RESPONSE.md changes (responses to your PINGs)"
    echo "   • Remote repository updates"
    echo "   • Check interval: 30 seconds"
    echo "   • Max runtime: 1 hour"
    echo ""
    echo -e "${BLUE}📁 Status & Logs:${NC}"
    echo "   • Status: .ai/AUTO_COMM_STATUS.md"
    echo "   • Logs: .ai/communication.log"
    echo ""
    echo -e "${BLUE}🎛️  Commands:${NC}"
    echo "   • Check status: ./.ai-framework/comm-status.sh"
    echo "   • Stop monitor: pkill -f auto-communication-monitor.sh"
    echo "   • View logs: tail -f .ai/communication.log"
    echo ""
    echo -e "${GREEN}🎯 Monitor is now running in background!${NC}"
else
    echo -e "${RED}❌ Failed to start monitor${NC}"
    exit 1
fi