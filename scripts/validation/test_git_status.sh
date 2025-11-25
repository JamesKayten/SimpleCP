#!/bin/bash
# Git Status and Sync Validation Tests
# Verifies git status, commits, and AICM sync functionality


REPO_ROOT="/home/user/AI-Collaboration-Management"
SIMPLECP_ROOT="/home/user/SimpleCP"
TEST_NAME="Git Status & Sync Validation"
ERRORS=0
WARNINGS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "$TEST_NAME"
echo "=========================================="
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Test 1: Git repository status
echo "Test 1: Git Repository Status"
echo "------------------------------"
cd "$REPO_ROOT"

if [ -d .git ]; then
    pass "Git repository initialized"

    # Check current branch
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    info "Current branch: $BRANCH"

    # Check for uncommitted changes
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        pass "No uncommitted changes (working tree clean)"
    else
        warn "Uncommitted changes detected"
        git status --short
    fi

    # Check for untracked files
    UNTRACKED=$(git ls-files --others --exclude-standard)
    if [ -z "$UNTRACKED" ]; then
        pass "No untracked files"
    else
        warn "Untracked files detected:"
        echo "$UNTRACKED" | sed 's/^/  /'
    fi
else
    fail "Not a git repository"
fi
echo ""

# Test 2: Recent commit verification
echo "Test 2: Recent Commit Verification"
echo "-----------------------------------"
cd "$REPO_ROOT"

# Check if reorganization commit exists
if git log --oneline -20 | grep -i "reorganize\|organization" > /dev/null; then
    pass "Reorganization commit found in recent history"

    LAST_COMMIT=$(git log -1 --pretty=format:"%h - %s" 2>/dev/null)
    info "Latest commit: $LAST_COMMIT"
else
    warn "Recent reorganization commit not found"
fi

# Check commit author
AUTHOR=$(git log -1 --pretty=format:"%an" 2>/dev/null)
if [ -n "$AUTHOR" ]; then
    info "Last commit author: $AUTHOR"
fi
echo ""

# Test 3: Sync script existence and validity
echo "Test 3: AICM Sync Scripts"
echo "-------------------------"

SYNC_FROM="$REPO_ROOT/scripts/sync/sync-from-aicm.sh"
SYNC_TO="$REPO_ROOT/scripts/sync/sync-to-aicm.sh"

if [ -f "$SYNC_FROM" ]; then
    pass "Sync-from script exists"
    if [ -x "$SYNC_FROM" ]; then
        pass "Sync-from script is executable"
    else
        fail "Sync-from script is NOT executable"
    fi

    # Check if it references AICM correctly
    if grep -q "AI-Collaboration-Management" "$SYNC_FROM"; then
        pass "Sync-from script references AICM repo"
    else
        warn "Sync-from script may not reference AICM correctly"
    fi
else
    fail "Sync-from script missing: $SYNC_FROM"
fi

if [ -f "$SYNC_TO" ]; then
    pass "Sync-to script exists"
    if [ -x "$SYNC_TO" ]; then
        pass "Sync-to script is executable"
    else
        fail "Sync-to script is NOT executable"
    fi

    # Check if it references AICM correctly
    if grep -q "AI-Collaboration-Management" "$SYNC_TO"; then
        pass "Sync-to script references AICM repo"
    else
        warn "Sync-to script may not reference AICM correctly"
    fi
else
    fail "Sync-to script missing: $SYNC_TO"
fi
echo ""

# Test 4: AICM repository check
echo "Test 4: AICM Repository Integration"
echo "------------------------------------"

if [ -d "$AICM_ROOT" ]; then
    pass "AICM repository exists at: $AICM_ROOT"

    cd "$AICM_ROOT"
    if [ -d .git ]; then
        pass "AICM is a git repository"

        AICM_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        info "AICM branch: $AICM_BRANCH"
    else
        warn "AICM directory exists but is not a git repository"
    fi
else
    warn "AICM repository not found at: $AICM_ROOT"
    info "This is expected if repositories are not set up for syncing"
fi
echo ""

# Test 5: Check for required git configuration
echo "Test 5: Git Configuration"
echo "-------------------------"
cd "$REPO_ROOT"

# Check user name
USER_NAME=$(git config user.name 2>/dev/null || echo "")
if [ -n "$USER_NAME" ]; then
    info "Git user.name: $USER_NAME"
else
    warn "Git user.name not configured"
fi

# Check user email
USER_EMAIL=$(git config user.email 2>/dev/null || echo "")
if [ -n "$USER_EMAIL" ]; then
    info "Git user.email: $USER_EMAIL"
else
    warn "Git user.email not configured"
fi

# Check remote
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
if [ -n "$REMOTE_URL" ]; then
    pass "Remote origin configured"
    info "Remote URL: $REMOTE_URL"
else
    warn "No remote origin configured"
fi
echo ""

# Test 6: File permissions check
echo "Test 6: File Permissions"
echo "------------------------"

# Check that moved files maintained their permissions
EXEC_SCRIPTS=(
    "scripts/backend/kill_backend.sh"
    "scripts/sync/sync-from-aicm.sh"
    "scripts/sync/sync-to-aicm.sh"
    "scripts/tcc/install-tcc.sh"
)

for script in "${EXEC_SCRIPTS[@]}"; do
    if [ -f "$REPO_ROOT/$script" ]; then
        if [ -x "$REPO_ROOT/$script" ]; then
            pass "Executable permission maintained: $script"
        else
            fail "Lost executable permission: $script"
        fi
    fi
done
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All git and sync tests passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Git tests passed with warnings${NC}"
    exit 0
else
    echo -e "${RED}✗ Git tests failed with $ERRORS errors${NC}"
    exit 1
fi
