#!/bin/bash

# TCC File Size Compliance Checker
# Usage: ./tcc-file-compliance.sh [target_branch]
# Purpose: Check all files against size limits before merge, create violation reports

set -e

# Detect repo root and ensure we're working from there
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
cd "$REPO_ROOT"

TARGET_BRANCH="${1:-main}"
CURRENT_BRANCH=$(git branch --show-current)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
VIOLATION_REPORT="reports/TCC_FILE_VIOLATIONS_${TIMESTAMP}.md"
TEMP_VIOLATIONS="/tmp/violations_${TIMESTAMP}.txt"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# File size limits (lines per file type)
declare -A SIZE_LIMITS=(
    ["py"]=250
    ["js"]=150
    ["jsx"]=150
    ["ts"]=150
    ["tsx"]=150
    ["java"]=400
    ["go"]=300
    ["swift"]=300
    ["rs"]=300
    ["cpp"]=400
    ["c"]=300
    ["h"]=200
    ["hpp"]=200
    ["md"]=500
    ["sh"]=200
    ["yaml"]=300
    ["yml"]=300
    ["json"]=300
    ["xml"]=300
    ["html"]=200
    ["css"]=200
    ["scss"]=200
    ["vue"]=200
    ["rb"]=250
    ["php"]=250
    ["dart"]=200
)

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔍 TCC COMPLIANCE CHECK (Size + Patterns)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${BLUE}📋 Current Branch:${NC} $CURRENT_BRANCH"
echo -e "${BLUE}🎯 Target Branch:${NC} $TARGET_BRANCH"
echo -e "${BLUE}📅 Check Time:${NC} $(date)"

# Create reports directory if it doesn't exist
mkdir -p reports

# ═══════════════════════════════════════════════════════════════════════════════
# PATTERN PROPAGATION CHECK (MANDATORY)
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}🔍 Checking for hardcoded patterns...${NC}"

PATTERN_VIOLATIONS=0
PATTERN_REPORT="/tmp/pattern_violations_${TIMESTAMP}.txt"
> "$PATTERN_REPORT"

# Patterns to check (add more as needed)
FORBIDDEN_PATTERNS=(
    "/Users/"
    "/home/user"
    "/Volumes/"
    "SimpleCP"
)

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    # Search in code files (exclude .git, reports, logs)
    matches=$(grep -rn "$pattern" --include="*.sh" --include="*.py" --include="*.swift" --include="*.js" --include="*.ts" --include="*.go" . 2>/dev/null | grep -v "\.git" | grep -v "reports/" | grep -v "PATTERN" | head -20)

    if [[ -n "$matches" ]]; then
        count=$(echo "$matches" | wc -l)
        echo -e "${RED}⚠️  Found '$pattern' in $count location(s):${NC}"
        echo "$matches" | while read -r line; do
            echo -e "   ${YELLOW}$line${NC}"
            echo "$line" >> "$PATTERN_REPORT"
        done
        ((PATTERN_VIOLATIONS += count))
    fi
done

if [[ $PATTERN_VIOLATIONS -gt 0 ]]; then
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ PATTERN CHECK: FAILED ($PATTERN_VIOLATIONS hardcoded patterns)${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Use /fix-pattern command to fix ALL instances systematically.${NC}"
    echo -e "${YELLOW}RULE: Fix the pattern completely or don't fix it at all.${NC}"
    echo ""
    rm -f "$PATTERN_REPORT"
    exit 1
else
    echo -e "${GREEN}✅ Pattern check: PASSED (no hardcoded paths/names)${NC}"
fi

rm -f "$PATTERN_REPORT"

echo ""
echo -e "${YELLOW}🔍 Scanning files for size violations...${NC}"

# Initialize violation counter and file
VIOLATION_COUNT=0
> "$TEMP_VIOLATIONS"

# Get list of files that differ from target branch
if git rev-parse --verify "$TARGET_BRANCH" >/dev/null 2>&1; then
    FILES_TO_CHECK=$(git diff --name-only "$TARGET_BRANCH"...HEAD 2>/dev/null || git ls-files)
else
    FILES_TO_CHECK=$(git ls-files)
fi

# Check each file
while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        # Get file extension
        extension="${file##*.}"

        # Skip if no size limit defined for this extension
        if [[ -z "${SIZE_LIMITS[$extension]}" ]]; then
            continue
        fi

        # Count lines in file
        line_count=$(wc -l < "$file" 2>/dev/null || echo 0)
        max_lines="${SIZE_LIMITS[$extension]}"

        # Check if violation
        if [[ $line_count -gt $max_lines ]]; then
            ((VIOLATION_COUNT++))
            echo -e "${RED}❌ VIOLATION:${NC} $file ($line_count lines > $max_lines limit)"
            echo "VIOLATION|$file|$extension|$line_count|$max_lines" >> "$TEMP_VIOLATIONS"
        else
            echo -e "${GREEN}✅${NC} $file ($line_count lines ≤ $max_lines limit)"
        fi
    fi
done <<< "$FILES_TO_CHECK"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $VIOLATION_COUNT -eq 0 ]]; then
    echo -e "${GREEN}✅ FILE SIZE COMPLIANCE: PASSED${NC}"
    echo -e "${GREEN}All files meet size requirements${NC}"
    echo -e "${BLUE}🚀 Ready for merge to $TARGET_BRANCH${NC}"

    # Clean up temp file
    rm -f "$TEMP_VIOLATIONS"

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
fi

echo -e "${RED}❌ FILE SIZE COMPLIANCE: FAILED${NC}"
echo -e "${RED}$VIOLATION_COUNT violations found${NC}"
echo ""

# Create detailed violation report for OCC
cat > "$VIOLATION_REPORT" << EOF
# TCC File Size Compliance Report

**Date:** $(date)
**Branch:** $CURRENT_BRANCH → $TARGET_BRANCH
**Status:** ❌ **COMPLIANCE FAILED**
**Violations:** $VIOLATION_COUNT

---

## 🚨 **MERGE BLOCKED - ACTION REQUIRED**

The following files exceed the maximum size limits and **MUST be refactored before merge:**

EOF

# Add violation details
while IFS='|' read -r status file ext current max; do
    if [[ "$status" == "VIOLATION" ]]; then
        overage=$((current - max))
        percentage=$(( (current * 100) / max ))

        cat >> "$VIOLATION_REPORT" << EOF
### ❌ \`$file\`
- **File Type:** .$ext
- **Current Size:** $current lines
- **Max Allowed:** $max lines
- **Overage:** +$overage lines ($percentage% of limit)
- **Action:** Refactor to reduce by $overage+ lines

EOF
    fi
done < "$TEMP_VIOLATIONS"

cat >> "$VIOLATION_REPORT" << EOF

---

## 🔧 **OCC REFACTORING INSTRUCTIONS**

### **Immediate Actions Required:**

1. **Review each violation** listed above
2. **Refactor oversized files** using these strategies:
   - Split large functions into smaller ones
   - Extract utility functions to separate files
   - Break large components into smaller modules
   - Move constants/configs to dedicated files
   - Use composition over large inheritance

3. **File Size Limits Reference:**
EOF

# Add size limits reference
for ext in "${!SIZE_LIMITS[@]}"; do
    echo "   - **.$ext files:** ${SIZE_LIMITS[$ext]} lines maximum" >> "$VIOLATION_REPORT"
done

cat >> "$VIOLATION_REPORT" << EOF

### **Testing Your Changes:**
\`\`\`bash
# Run compliance check again
./scripts/tcc-file-compliance.sh $TARGET_BRANCH

# Should show: ✅ FILE SIZE COMPLIANCE: PASSED
\`\`\`

### **After All Violations Fixed:**
\`\`\`bash
# Commit your refactoring
git add .
git commit -m "refactor: Fix file size compliance violations

- Split oversized files to meet line limits
- Extracted utility functions to separate modules
- Improved code organization and modularity

Resolves: TCC_FILE_VIOLATIONS_${TIMESTAMP}
"

# Push changes
git push
\`\`\`

---

## 📋 **TCC Validation Results**

- **Files Scanned:** $(echo "$FILES_TO_CHECK" | wc -l)
- **Violations Found:** $VIOLATION_COUNT
- **Compliance Status:** ❌ FAILED
- **Merge Status:** 🚫 BLOCKED until violations resolved

---

**📞 TCC Contact:** This report was auto-generated by TCC file compliance checker.
**🔄 Re-run Check:** \`./scripts/tcc-file-compliance.sh $TARGET_BRANCH\`
**✅ Success Criteria:** All files must be ≤ their type's line limit

---

**⚠️  IMPORTANT:** This branch cannot be merged until all file size violations are resolved.

EOF

echo -e "${YELLOW}📝 Violation report created:${NC} $VIOLATION_REPORT"

# Display summary of violations for immediate feedback
echo ""
echo -e "${RED}🚨 VIOLATIONS SUMMARY:${NC}"
while IFS='|' read -r status file ext current max; do
    if [[ "$status" == "VIOLATION" ]]; then
        overage=$((current - max))
        echo -e "${RED}   $file${NC} ($current lines, needs -$overage)"
    fi
done < "$TEMP_VIOLATIONS"

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Review violation report: $VIOLATION_REPORT"
echo "2. Refactor oversized files"
echo "3. Re-run: ./scripts/tcc-file-compliance.sh $TARGET_BRANCH"
echo "4. Merge only after: ✅ FILE SIZE COMPLIANCE: PASSED"

# Clean up temp file
rm -f "$TEMP_VIOLATIONS"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}❌ MERGE BLOCKED - COMPLIANCE VIOLATIONS MUST BE FIXED${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 1