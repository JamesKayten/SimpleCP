#!/bin/bash
# OCC Task Executor - Calls Claude API to implement task

TASK_FILE=".ai/TASK_FOR_OCC.md"

if [ ! -f "$TASK_FILE" ]; then
    echo "No task file found"
    exit 0
fi

# Read the task
TASK_CONTENT=$(cat "$TASK_FILE")

# Call Claude API
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 4096,
    "system": "You are OCC (Online Claude Code). Read the task and implement it. Use the appropriate tools to edit/create files. Follow all file size constraints (250 lines max per file).",
    "messages": [{
      "role": "user",
      "content": "'"$TASK_CONTENT"'\n\nImplement this task now. Make all necessary code changes."
    }]
  }' > /tmp/claude_response.json

# Parse response and execute tool calls
# (This would need proper JSON parsing and tool execution logic)
# For now, this is a placeholder showing the structure

echo "OCC executed task via Claude API"
