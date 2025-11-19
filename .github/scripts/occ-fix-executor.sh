#!/bin/bash
# OCC Violation Fixer - Calls Claude API to fix violations

VIOLATION_FILE=".ai/VIOLATIONS_FOR_OCC.md"

if [ ! -f "$VIOLATION_FILE" ]; then
    echo "No violation file found"
    exit 0
fi

# Read the violations
VIOLATIONS=$(cat "$VIOLATION_FILE")

# Call Claude API
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 4096,
    "system": "You are OCC (Online Claude Code). Fix the violations reported by TCC. Use appropriate tools to refactor files that are too large or fix code quality issues.",
    "messages": [{
      "role": "user",
      "content": "'"$VIOLATIONS"'\n\nFix all these violations now."
    }]
  }' > /tmp/claude_fix_response.json

echo "OCC fixed violations via Claude API"
