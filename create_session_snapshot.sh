#!/bin/bash
# SESSION EXIT SNAPSHOT CREATOR
# Purpose: Capture EXACT work state when session ends
# Usage: Run this when ending a session to capture exact state
# Project: SimpleCP
# Auto-deployed by Avery's AI Collaboration Framework

SNAPSHOT_FILE="SESSION_EXIT_SNAPSHOT.md"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")

echo "📸 CREATING SESSION EXIT SNAPSHOT..."
echo "📁 Project: SimpleCP"

cat > "$SNAPSHOT_FILE" << EOF
# 📸 SESSION EXIT SNAPSHOT
**Project:** SimpleCP
**Captured:** $TIMESTAMP
**Purpose:** Resume work at EXACT point where session ended

---

## ⚡ EXACT EXIT STATE

### **What I Was Working On:**
$(if [ -f ".ai-framework/session-recovery/CURRENT_SESSION_STATE.md" ]; then
    echo "Reading current session state..."
    grep -A 10 "What Claude Was ACTUALLY Doing" .ai-framework/session-recovery/CURRENT_SESSION_STATE.md || echo "Current task context not captured"
else
    echo "❌ No current session state found"
    echo "Last known activity: [MANUAL ENTRY REQUIRED]"
fi)

### **Immediate Next Action:**
$(if [ -f ".ai-framework/session-recovery/CURRENT_SESSION_STATE.md" ]; then
    grep -A 3 "NEXT ACTION:" .ai-framework/session-recovery/CURRENT_SESSION_STATE.md | tail -n 2 || echo "Next action not specified"
else
    echo "❓ Next action unknown - requires manual specification"
fi)

### **Work Progress:**
$(if [ -f ".ai-framework/session-recovery/CURRENT_SESSION_STATE.md" ]; then
    grep -A 20 "Current Todo List Status" .ai-framework/session-recovery/CURRENT_SESSION_STATE.md || echo "Progress unknown"
else
    echo "❓ Progress status unknown"
fi)

---

## 📂 EXACT WORKING STATE

### **Current Directory:**
\`$PWD\`

### **Project Type:**
Python Backend/API (black,flake8,pytest)

### **Modified Files This Session:**
$(git status --porcelain 2>/dev/null || echo "❓ Git status unavailable")

### **Uncommitted Changes:**
$(git diff --name-only 2>/dev/null | head -10 || echo "❓ No git repository or changes")

### **Recent File Activity:**
$(find . -name "*.py" -o -name "*.md" -o -name "*.sh" -newermt "2 hours ago" -type f | head -10)

---

## 🎯 RESTORATION INSTRUCTIONS

### **Instant Resume Command:**
\`\`\`bash
cd '$PWD'
./restore_session.sh
# Review exact exit state, then continue with specified next action
\`\`\`

### **Context Restoration:**
1. **Read this snapshot** - Get exact work state
2. **Review modified files** - Understand what was being changed
3. **Continue next action** - Resume at exact interruption point

---

## ⏰ SESSION METRICS
- **Project:** SimpleCP
- **Session End:** $TIMESTAMP
- **Working Directory:** $PWD
- **Snapshot Created:** Successfully

---

**CRITICAL:** This snapshot captures EXACT work state, not historical progress.
**Usage:** Read this file first when resuming to get immediate work context.
**Framework:** Avery's AI Collaboration Hack
EOF

echo "✅ SESSION EXIT SNAPSHOT CREATED: $SNAPSHOT_FILE"
echo
echo "📋 SNAPSHOT SUMMARY:"
echo "• Captured exact work state at session end"
echo "• Includes current tasks, progress, and immediate next actions"
echo "• Ready for instant session resumption"
echo
echo "🔄 NEXT SESSION RECOVERY:"
echo "1. cd '$PWD'"
echo "2. ./restore_session.sh"
echo "3. Continue with specified next action"
echo
echo "⚡ No more time wasted on figuring out where you left off!"
echo "📁 Project: SimpleCP | Framework: Avery's AI Collaboration Hack"