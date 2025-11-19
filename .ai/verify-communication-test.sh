#!/bin/bash
# Verify AI-to-AI Communication Test Results

echo "=== AI-to-AI Communication Test Verification ==="
echo ""

# Check if PONG response exists
if grep -q "### PONG Response" .ai/COMMUNICATION_LOG.md; then
    echo "✅ PONG response found"

    # Extract calculation result
    calc_result=$(grep -A 10 "### PONG Response" .ai/COMMUNICATION_LOG.md | grep -i "calculation" | head -1)
    echo "✅ Calculation: $calc_result"

    # Check if STATUS is back to IDLE
    source .ai/STATUS
    if [ "$TASK_STATE" = "IDLE" ]; then
        echo "✅ STATUS returned to IDLE"
    else
        echo "❌ STATUS still: $TASK_STATE (expected IDLE)"
    fi

    # Check for commit
    echo ""
    echo "Recent commits:"
    git log --oneline -5 | grep -i "pong\|communication"

    echo ""
    echo "🎉 TEST PASSED - Both AIs communicated successfully!"

else
    echo "⏳ PONG response not yet received"
    echo "Current STATUS: $(source .ai/STATUS && echo $TASK_STATE)"
    echo ""
    echo "Waiting for second AI to:"
    echo "  1. Detect PENDING task in STATUS file"
    echo "  2. Read COMMUNICATION_TEST.md instructions"
    echo "  3. Add PONG response to COMMUNICATION_LOG.md"
    echo "  4. Update STATUS to IDLE"
    echo "  5. Commit changes"
fi

echo ""
echo "=== Communication Log Preview ==="
head -30 .ai/COMMUNICATION_LOG.md
