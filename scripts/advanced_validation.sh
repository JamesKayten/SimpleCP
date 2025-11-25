#!/bin/bash

# AI Collaboration Framework - Advanced Validation with Error Handling
# Enhanced validation script with comprehensive error handling and diagnostics

set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Framework configuration
FRAMEWORK_VERSION="2.0 Enhanced"
VALIDATION_DATE=$(date '+%Y-%m-%d %H:%M:%S')
PROJECT_NAME=$(basename "$(pwd)")
REPORT_DIR="docs/ai_communication"
REPORT_FILE="$REPORT_DIR/AI_REPORT_$(date +%Y-%m-%d_%H%M%S)_ADVANCED_VALIDATION.md"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
}

log_critical() {
    echo -e "${RED}🚨 CRITICAL:${NC} $1"
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_critical "Script failed at line $line_number with exit code $exit_code"
    log_error "Last command: ${BASH_COMMAND}"

    # Generate error report
    generate_error_report "$exit_code" "$line_number"
    exit $exit_code
}

# Set error trap
trap 'handle_error $LINENO' ERR

# Initialize validation tracking
VIOLATIONS_FOUND=0
CRITICAL_ISSUES=0
WARNINGS=0
ERRORS_LOG=()

# Function to add error to log
add_error() {
    local severity="$1"
    local message="$2"
    ERRORS_LOG+=("[$severity] $message")

    case $severity in
        "CRITICAL") ((CRITICAL_ISSUES++));;
        "ERROR") ((VIOLATIONS_FOUND++));;
        "WARNING") ((WARNINGS++));;
    esac
}

# Framework structure validation
validate_framework_structure() {
    log_info "Validating AI Collaboration Framework structure..."

    local required_files=(
        "docs/AI_WORKFLOW.md"
        "docs/ai_communication/README.md"
        "docs/ai_communication/VALIDATION_RULES.md"
    )

    local missing_files=0

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            add_error "CRITICAL" "Required framework file missing: $file"
            log_error "Missing framework file: $file"
            ((missing_files++))
        fi
    done

    if [[ $missing_files -eq 0 ]]; then
        log_success "Framework structure validation passed"
        return 0
    else
        log_critical "Framework structure validation failed ($missing_files missing files)"
        return 1
    fi
}

# Project type detection with enhanced logic
detect_project_type() {
    local project_type="unknown"
    local confidence=0

    # Python detection
    if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]] || [[ -f "Pipfile" ]]; then
        project_type="python"
        ((confidence += 30))
        [[ -f "manage.py" ]] && ((confidence += 20))  # Django
        [[ -f "app.py" ]] || [[ -f "main.py" ]] && ((confidence += 10))
    fi

    # JavaScript/TypeScript detection
    if [[ -f "package.json" ]]; then
        if grep -q '"react"' package.json 2>/dev/null; then
            project_type="react"
            ((confidence += 40))
        elif grep -q '"typescript"' package.json 2>/dev/null; then
            project_type="typescript"
            ((confidence += 35))
        else
            project_type="javascript"
            ((confidence += 30))
        fi
    fi

    # Java detection
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        project_type="java"
        ((confidence += 35))
        [[ -d "src/main/java" ]] && ((confidence += 20))
    fi

    # Go detection
    if [[ -f "go.mod" ]] || [[ -f "go.sum" ]]; then
        project_type="go"
        ((confidence += 35))
    fi

    log_info "Detected project type: $project_type (confidence: $confidence%)"
    echo "$project_type"
}

# Enhanced Python validation
validate_python_project() {
    log_info "Running enhanced Python validation..."

    # Check for Python files
    local python_files=$(find . -name "*.py" -not -path "./.git/*" -not -path "./venv/*" -not -path "./.venv/*" | wc -l)

    if [[ $python_files -eq 0 ]]; then
        add_error "WARNING" "No Python files found in project"
        return 0
    fi

    log_info "Found $python_files Python files to validate"

    # Black formatting validation
    if command -v black >/dev/null 2>&1; then
        log_info "Checking Black formatting..."
        if ! black --check . --quiet 2>/dev/null; then
            add_error "ERROR" "Black formatting violations detected"
            log_error "Black formatting issues found. Run 'black .' to fix."
        else
            log_success "Black formatting validation passed"
        fi
    else
        add_error "WARNING" "Black formatter not installed"
    fi

    # Flake8 style validation
    if command -v flake8 >/dev/null 2>&1; then
        log_info "Running Flake8 style checks..."
        local flake8_output
        if ! flake8_output=$(flake8 . --max-line-length=88 --extend-ignore=E203,W503 2>&1); then
            add_error "ERROR" "Flake8 style violations detected"
            log_error "Flake8 violations found:"
            echo "$flake8_output" | head -20  # Show first 20 violations
        else
            log_success "Flake8 style validation passed"
        fi
    else
        add_error "WARNING" "Flake8 linter not installed"
    fi

    # Security validation with Bandit
    if command -v bandit >/dev/null 2>&1; then
        log_info "Running security analysis with Bandit..."
        local bandit_output
        if ! bandit_output=$(bandit -r . -f txt -q 2>&1); then
            add_error "CRITICAL" "Security vulnerabilities detected by Bandit"
            log_critical "Security issues found:"
            echo "$bandit_output" | head -10
        else
            log_success "Security validation passed"
        fi
    else
        add_error "WARNING" "Bandit security scanner not installed"
    fi

    # Test coverage validation
    if command -v pytest >/dev/null 2>&1; then
        log_info "Running test coverage analysis..."
        if pytest --cov=. --cov-report=term-missing --cov-fail-under=85 --quiet >/dev/null 2>&1; then
            log_success "Test coverage meets requirements (≥85%)"
        else
            add_error "ERROR" "Test coverage below 85% threshold"
        fi
    else
        add_error "WARNING" "pytest not available for coverage analysis"
    fi
}

# Enhanced JavaScript/TypeScript validation
validate_javascript_project() {
    log_info "Running enhanced JavaScript/TypeScript validation..."

    if [[ ! -f "package.json" ]]; then
        add_error "CRITICAL" "package.json not found in JavaScript project"
        return 1
    fi

    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        log_info "Installing npm dependencies..."
        if ! npm install --quiet >/dev/null 2>&1; then
            add_error "CRITICAL" "Failed to install npm dependencies"
            return 1
        fi
    fi

    # ESLint validation
    if npm list eslint >/dev/null 2>&1; then
        log_info "Running ESLint validation..."
        if ! npx eslint src/ --ext .js,.jsx,.ts,.tsx --max-warnings 0 >/dev/null 2>&1; then
            add_error "ERROR" "ESLint violations detected"
        else
            log_success "ESLint validation passed"
        fi
    else
        add_error "WARNING" "ESLint not configured"
    fi

    # Prettier formatting
    if npm list prettier >/dev/null 2>&1; then
        log_info "Checking Prettier formatting..."
        if ! npx prettier --check "src/**/*.{js,jsx,ts,tsx}" >/dev/null 2>&1; then
            add_error "ERROR" "Prettier formatting violations detected"
        else
            log_success "Prettier formatting validation passed"
        fi
    else
        add_error "WARNING" "Prettier not configured"
    fi

    # TypeScript validation
    if [[ -f "tsconfig.json" ]]; then
        log_info "Running TypeScript compilation check..."
        if ! npx tsc --noEmit --strict >/dev/null 2>&1; then
            add_error "ERROR" "TypeScript compilation errors detected"
        else
            log_success "TypeScript validation passed"
        fi
    fi
}

# Generate comprehensive validation report
generate_validation_report() {
    log_info "Generating comprehensive validation report..."

    mkdir -p "$REPORT_DIR"

    cat > "$REPORT_FILE" << EOF
# 🤖 AI Collaboration Framework - Advanced Validation Report

**Date:** $VALIDATION_DATE
**Project:** $PROJECT_NAME
**Framework Version:** $FRAMEWORK_VERSION
**Validation Type:** Advanced Multi-Language Analysis

---

## 📊 **VALIDATION SUMMARY**

| Metric | Count | Status |
|--------|-------|--------|
| **Critical Issues** | $CRITICAL_ISSUES | $([ $CRITICAL_ISSUES -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL") |
| **Errors Found** | $VIOLATIONS_FOUND | $([ $VIOLATIONS_FOUND -eq 0 ] && echo "✅ PASS" || echo "⚠️ REVIEW") |
| **Warnings** | $WARNINGS | $([ $WARNINGS -eq 0 ] && echo "✅ CLEAN" || echo "⚠️ REVIEW") |

$([ $CRITICAL_ISSUES -eq 0 ] && [ $VIOLATIONS_FOUND -eq 0 ] && echo "## ✅ **MERGE APPROVED**" || echo "## ❌ **MERGE BLOCKED**")

---

## 🔍 **DETAILED FINDINGS**

EOF

    # Add detailed errors if any exist
    if [[ ${#ERRORS_LOG[@]} -gt 0 ]]; then
        echo "" >> "$REPORT_FILE"
        echo "### **Issues Detected:**" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"

        for error in "${ERRORS_LOG[@]}"; do
            echo "- $error" >> "$REPORT_FILE"
        done
    else
        echo "" >> "$REPORT_FILE"
        echo "### ✅ **No Issues Detected**" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "All validation checks passed successfully." >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

---

## 🎯 **NEXT STEPS FOR BROWSER CLAUDE**

EOF

    if [[ $CRITICAL_ISSUES -gt 0 ]] || [[ $VIOLATIONS_FOUND -gt 0 ]]; then
        cat >> "$REPORT_FILE" << EOF
### **Required Actions:**
1. Address all critical issues and errors listed above
2. Run appropriate fix commands for your project type
3. Re-run validation to ensure all issues resolved
4. Create response file documenting fixes made

### **Fix Commands:**
\`\`\`bash
# For Python projects
black .
flake8 . --max-line-length=88

# For JavaScript/TypeScript projects
npx prettier --write "src/**/*.{js,jsx,ts,tsx}"
npx eslint src/ --fix
\`\`\`
EOF
    else
        cat >> "$REPORT_FILE" << EOF
### **Status: Ready for Deployment** ✅

All validation checks passed. Code quality meets framework standards.
No action required from Browser Claude.
EOF
    fi

    cat >> "$REPORT_FILE" << EOF

---

**Framework:** Avery's AI Collaboration Hack v$FRAMEWORK_VERSION
**Report ID:** ADVANCED_VALIDATION_$(date +%Y%m%d_%H%M%S)
**Ready for:** Cross-Platform AI Collaboration
EOF

    log_success "Validation report generated: $REPORT_FILE"
}

# Generate error report for script failures
generate_error_report() {
    local exit_code="$1"
    local line_number="$2"

    mkdir -p "$REPORT_DIR"
    local error_report="$REPORT_DIR/AI_ERROR_REPORT_$(date +%Y-%m-%d_%H%M%S).md"

    cat > "$error_report" << EOF
# 🚨 AI Framework Validation Error Report

**Date:** $VALIDATION_DATE
**Project:** $PROJECT_NAME
**Error Code:** $exit_code
**Failed Line:** $line_number
**Command:** ${BASH_COMMAND}

---

## ❌ **VALIDATION SCRIPT FAILURE**

The AI Collaboration Framework validation script encountered an unexpected error.

### **Error Details:**
- **Exit Code**: $exit_code
- **Failed At**: Line $line_number
- **Command**: \`${BASH_COMMAND}\`
- **Timestamp**: $VALIDATION_DATE

### **Possible Causes:**
1. **Missing Dependencies**: Required validation tools not installed
2. **Permission Issues**: Script lacks necessary file permissions
3. **Project Structure**: Unexpected project layout or file locations
4. **Environment Issues**: System environment not properly configured

### **Troubleshooting Steps:**
1. Verify all validation tools are installed (black, flake8, eslint, etc.)
2. Check file permissions in project directory
3. Review project structure against framework requirements
4. Re-run validation with debug mode: \`bash -x scripts/advanced_validation.sh\`

---

**Framework:** Avery's AI Collaboration Hack v$FRAMEWORK_VERSION
**Report Type:** Error Diagnostic
**Action Required:** Manual intervention needed
EOF

    log_error "Error report generated: $error_report"
}

# Main validation workflow
main() {
    log_info "🤖 Starting AI Collaboration Framework Advanced Validation"
    log_info "Framework Version: $FRAMEWORK_VERSION"
    log_info "Project: $PROJECT_NAME"
    log_info "Timestamp: $VALIDATION_DATE"
    echo ""

    # Validate framework structure
    if ! validate_framework_structure; then
        log_critical "Framework structure validation failed. Cannot proceed."
        generate_validation_report
        exit 1
    fi

    # Detect project type and run appropriate validation
    local project_type
    project_type=$(detect_project_type)

    case $project_type in
        "python"|"django"|"flask")
            validate_python_project
            ;;
        "javascript"|"typescript"|"react")
            validate_javascript_project
            ;;
        *)
            log_warning "Unknown project type. Running basic validation only."
            add_error "WARNING" "Project type could not be determined automatically"
            ;;
    esac

    # Generate comprehensive report
    generate_validation_report

    # Summary
    echo ""
    log_info "🎯 Validation Summary:"
    log_info "   Critical Issues: $CRITICAL_ISSUES"
    log_info "   Errors: $VIOLATIONS_FOUND"
    log_info "   Warnings: $WARNINGS"
    echo ""

    if [[ $CRITICAL_ISSUES -eq 0 ]] && [[ $VIOLATIONS_FOUND -eq 0 ]]; then
        log_success "🎉 Advanced validation completed successfully!"
        log_success "✅ Ready for AI collaboration workflow"
        exit 0
    else
        log_error "❌ Validation failed. Issues must be resolved before proceeding."
        log_info "📋 Review report: $REPORT_FILE"
        exit 1
    fi
}

# Execute main function
main "$@"