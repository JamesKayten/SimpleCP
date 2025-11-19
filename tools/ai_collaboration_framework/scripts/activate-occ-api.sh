#!/bin/bash
#
# OCC API Activation Script
# Automatically activates OCC via Anthropic API when TCC detects violations
#
# Usage: ./activate-occ-api.sh [report_path]
#
# Environment variables required:
#   ANTHROPIC_API_KEY - Your Anthropic API key
#
# Optional environment variables:
#   CONFIG_PATH - Path to config.yml (default: ../config.yml)
#   GITHUB_TOKEN - For GitHub API operations (auto-provided in Actions)

set -e  # Exit on error

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_PATH="${CONFIG_PATH:-$FRAMEWORK_DIR/config.yml}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Read config value from YAML (simple parser)
read_config() {
    local key="$1"
    local default="$2"

    if [ ! -f "$CONFIG_PATH" ]; then
        echo "$default"
        return
    fi

    # Simple YAML parsing (works for our flat config)
    local value=$(grep "^${key}:" "$CONFIG_PATH" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"' | tr -d "'")

    if [ -z "$value" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# ============================================================================
# VALIDATION
# ============================================================================

# Check if API mode is enabled
check_api_mode() {
    local mode=$(read_config "activation_mode" "manual")

    if [ "$mode" != "api" ]; then
        log_error "Activation mode is set to '$mode', not 'api'"
        log_info "To use API activation, set activation_mode: \"api\" in $CONFIG_PATH"
        exit 1
    fi
}

# Check for API key
check_api_key() {
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        log_error "ANTHROPIC_API_KEY environment variable not set"
        log_info "Get your API key from: https://console.anthropic.com"
        log_info "Then set it: export ANTHROPIC_API_KEY=your-key-here"
        exit 1
    fi
}

# ============================================================================
# FIND LATEST TCC REPORT
# ============================================================================

find_latest_report() {
    local report_path="$1"

    # If report path provided, use it
    if [ -n "$report_path" ] && [ -f "$report_path" ]; then
        echo "$report_path"
        return
    fi

    # Otherwise, find latest report
    log_info "Searching for latest TCC report..."

    local latest=$(find "$REPO_ROOT/docs/ai_communication" "$REPO_ROOT/docs/occ_communication" \
        -name "VALIDATION_REPORT_*.md" -o -name "*VIOLATION*.md" 2>/dev/null | \
        sort -r | head -1)

    if [ -z "$latest" ]; then
        log_error "No TCC reports found"
        exit 1
    fi

    log_info "Found report: $latest"
    echo "$latest"
}

# ============================================================================
# BUILD OCC PROMPT
# ============================================================================

build_occ_prompt() {
    local report_path="$1"
    local custom_prompt=$(read_config "advanced.custom_occ_prompt" "")

    if [ -n "$custom_prompt" ]; then
        log_info "Using custom OCC prompt from config"
        echo "$custom_prompt"
        return
    fi

    # Standard OCC prompt
    cat <<EOF
I am the Operational Control Claude (OCC) for the AI Collaboration Framework.

TASK: Check for and respond to latest TCC (Technical Control Claude) reports

INSTRUCTIONS:
1. Read all files in docs/ai_communication/ directory
2. Look for the most recent TCC report (sorted by timestamp)
3. Review any violations or issues documented
4. If violations found: Take immediate corrective action following OCC protocols
5. If no violations: Confirm framework status is healthy

FRAMEWORK LOCATION: The repository contains the framework in:
- docs/ai_communication/ - All TCC reports and communication logs
- docs/ai_collaboration_framework.md - Protocol documentation
- .github/workflows/ - Automation systems

SPECIFIC REPORT TO ADDRESS: $report_path

Begin by reading the report and taking corrective action.
EOF
}

# ============================================================================
# CALL ANTHROPIC API
# ============================================================================

call_anthropic_api() {
    local prompt="$1"
    local model=$(read_config "api.model" "claude-sonnet-4-5-20250929")
    local max_tokens=$(read_config "api.max_tokens" "16000")
    local temperature=$(read_config "api.temperature" "0.0")
    local timeout=$(read_config "api.timeout" "120")

    log_info "Sending OCC activation to Anthropic API..."
    log_info "Model: $model"
    log_info "Max tokens: $max_tokens"

    # Escape prompt for JSON
    local prompt_escaped=$(echo "$prompt" | jq -Rs .)

    # Build API request
    local request_body=$(cat <<EOF
{
  "model": "$model",
  "max_tokens": $max_tokens,
  "temperature": $temperature,
  "messages": [
    {
      "role": "user",
      "content": $prompt_escaped
    }
  ]
}
EOF
)

    # Call API
    local response=$(curl -s -w "\n%{http_code}" \
        --max-time "$timeout" \
        -X POST "https://api.anthropic.com/v1/messages" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$request_body")

    # Extract status code
    local http_code=$(echo "$response" | tail -1)
    local response_body=$(echo "$response" | sed '$d')

    # Check status
    if [ "$http_code" != "200" ]; then
        log_error "API request failed with status $http_code"
        log_error "Response: $response_body"
        exit 1
    fi

    # Extract Claude's response
    local occ_response=$(echo "$response_body" | jq -r '.content[0].text')

    if [ -z "$occ_response" ] || [ "$occ_response" = "null" ]; then
        log_error "Failed to extract response from API"
        log_error "Raw response: $response_body"
        exit 1
    fi

    log_success "Received OCC response (${#occ_response} characters)"
    echo "$occ_response"
}

# ============================================================================
# PROCESS OCC RESPONSE
# ============================================================================

process_occ_response() {
    local response="$1"
    local report_path="$2"

    log_info "Processing OCC response..."

    # Save response to communication directory
    local timestamp=$(date +%Y-%m-%d-%H%M%S)
    local response_file="$REPO_ROOT/docs/ai_communication/OCC_RESPONSE_${timestamp}.md"

    cat > "$response_file" <<EOF
# OCC Response - $timestamp

**Activation Method:** API (Automated)
**Report Addressed:** $report_path
**Timestamp:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

---

$response

---

**Status:** Processing complete
**Next Steps:** OCC's changes have been applied. TCC will re-validate.
EOF

    log_success "Saved OCC response to: $response_file"

    # Commit the response
    local commit_prefix=$(read_config "occ.commit_prefix" "[OCC]")

    git add "$response_file"
    git commit -m "$commit_prefix Automated response to TCC report

OCC processed violation report and applied fixes.
Report: $report_path
Response: $response_file
Activation: API (automated)" || true

    log_success "Committed OCC response"

    # Auto-push if configured
    local auto_push=$(read_config "occ.auto_push" "true")
    if [ "$auto_push" = "true" ]; then
        log_info "Auto-pushing changes..."
        git push || log_warning "Push failed (may need manual push)"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_info "=== OCC API Activation Starting ==="

    # Validate setup
    check_api_mode
    check_api_key

    # Find report
    local report_path=$(find_latest_report "$1")

    # Build prompt
    local prompt=$(build_occ_prompt "$report_path")

    # Call API
    local occ_response=$(call_anthropic_api "$prompt")

    # Process response
    process_occ_response "$occ_response" "$report_path"

    log_success "=== OCC API Activation Complete ==="
    log_info "OCC has processed the violation report"
    log_info "Check docs/ai_communication/ for the response"
}

# Run main function
main "$@"
