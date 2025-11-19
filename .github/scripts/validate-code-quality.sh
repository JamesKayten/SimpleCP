#!/bin/bash
# TCC Code Quality Validator

echo ""
echo "## Code Quality Validation"
echo ""

# Install tools
pip install -q black flake8 2>/dev/null

# Black formatting check
echo "### Black Formatting"
if black --check . 2>&1 | grep -q "would reformat"; then
    echo "🔴 VIOLATION: Code needs Black formatting"
    echo "\`\`\`"
    black --check . 2>&1 | head -10
    echo "\`\`\`"
else
    echo "✅ Black formatting compliant"
fi

# Flake8 check
echo ""
echo "### Flake8 Style Check"
if flake8 --max-line-length=88 . 2>&1 | grep -q "\.py:"; then
    echo "🔴 VIOLATION: Flake8 issues found"
    echo "\`\`\`"
    flake8 --max-line-length=88 . 2>&1 | head -10
    echo "\`\`\`"
else
    echo "✅ Flake8 compliant"
fi

exit 0
