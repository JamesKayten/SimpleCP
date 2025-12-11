#!/bin/bash
# Git Status Validation

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$(dirname "$0")/common.sh"

header "Git Status Validation"

cd "$REPO_ROOT"

# Test 1: Git repository status
echo "Test 1: Repository Status"
if [ -d .git ]; then
    pass "Git repository initialized"
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    info "Current branch: $BRANCH"
else
    fail "Not a git repository"
fi
echo ""

# Test 2: Working tree status
echo "Test 2: Working Tree"
if git diff-index --quiet HEAD -- 2>/dev/null; then
    pass "No uncommitted changes"
else
    warn "Uncommitted changes detected"
fi

UNTRACKED=$(git ls-files --others --exclude-standard)
[ -z "$UNTRACKED" ] && pass "No untracked files" || warn "Untracked files detected"
echo ""

# Test 3: Remote configuration
echo "Test 3: Remote Configuration"
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null)
[ -n "$REMOTE_URL" ] && pass "Remote origin: $REMOTE_URL" || warn "No remote origin configured"
echo ""

print_summary "Git Status Validation"
exit $?
