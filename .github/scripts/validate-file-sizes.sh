#!/bin/bash
# TCC File Size Validator

echo "# TCC Validation Report"
echo "**Date:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""
echo "## File Size Validation"
echo ""

MAX_LINES=250
VIOLATIONS=0

# Find all Python files and check line count
while IFS= read -r file; do
    lines=$(wc -l < "$file")
    if [ "$lines" -gt "$MAX_LINES" ]; then
        echo "🔴 VIOLATION: \`$file\` has $lines lines (limit: $MAX_LINES)"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
done < <(find . -name "*.py" -not -path "./.git/*" -not -path "./venv/*")

if [ "$VIOLATIONS" -eq 0 ]; then
    echo "✅ All files under $MAX_LINES line limit"
else
    echo ""
    echo "**Total violations:** $VIOLATIONS"
    echo ""
    echo "## Required Actions"
    echo "Refactor files exceeding $MAX_LINES lines into smaller modules."
fi

exit 0
