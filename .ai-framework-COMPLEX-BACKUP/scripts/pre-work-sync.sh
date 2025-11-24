#!/bin/bash
# Pre-Work Sync Protocol (MANDATORY)
# This script MUST be executed before starting any work on the repository
# Exit code 0 = Success, Exit code 1 = Failure (blocks work)

set -e  # Exit immediately on any error

echo "=========================================="
echo "PRE-WORK SYNC PROTOCOL"
echo "=========================================="
echo ""

# Step 1: Verify we're in a git repository
echo "Step 1: Verifying git repository..."
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ FAILURE: Not in a git repository"
    echo "REQUIRED ACTION: Navigate to project root"
    exit 1
fi
echo "✅ Git repository confirmed"
echo ""

# Step 2: Show current status
echo "Step 2: Checking current status..."
git status
echo ""

# Step 3: Check for uncommitted changes
echo "Step 3: Checking for uncommitted changes..."
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "⚠️  WARNING: Uncommitted changes detected"
    echo ""
    echo "Uncommitted files:"
    git status --short
    echo ""
    echo "❌ SYNC BLOCKED: Cannot sync with uncommitted changes"
    echo "REQUIRED ACTION: Either commit changes or stash them"
    echo ""
    echo "To commit:"
    echo "  git add -A"
    echo "  git commit -m 'Your message'"
    echo ""
    echo "To stash:"
    echo "  git stash save 'Work in progress'"
    exit 1
fi
echo "✅ No uncommitted changes"
echo ""

# Step 4: Fetch from remote
echo "Step 4: Fetching from remote..."
if ! git fetch origin; then
    echo "❌ FAILURE: Could not fetch from remote"
    echo "POSSIBLE CAUSES:"
    echo "  - No internet connection"
    echo "  - Remote repository not accessible"
    echo "  - Authentication issues"
    exit 1
fi
echo "✅ Fetch successful"
echo ""

# Step 5: Get current branch
BRANCH=$(git branch --show-current)
echo "Step 5: Current branch: $BRANCH"
echo ""

# Step 6: Pull latest changes
echo "Step 6: Pulling latest changes from origin/$BRANCH..."
if ! git pull origin "$BRANCH"; then
    echo "❌ FAILURE: Could not pull from origin/$BRANCH"
    echo "POSSIBLE CAUSES:"
    echo "  - Merge conflicts"
    echo "  - Remote branch doesn't exist"
    echo "  - Network issues"
    exit 1
fi
echo ""

# Step 7: Verify sync
echo "Step 7: Verifying sync status..."
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "no-upstream")

if [ "$REMOTE" = "no-upstream" ]; then
    echo "⚠️  WARNING: No upstream branch configured"
    echo "Local commit: $LOCAL"
    echo "This is acceptable for new branches"
    SYNC_STATUS="NEW_BRANCH"
elif [ "$LOCAL" = "$REMOTE" ]; then
    echo "✅ SYNC SUCCESS: Local matches remote"
    echo "Commit: $LOCAL"
    SYNC_STATUS="SYNCED"
else
    echo "❌ SYNC FAILED: Local does not match remote"
    echo "Local:  $LOCAL"
    echo "Remote: $REMOTE"
    echo "This should not happen after a successful pull"
    exit 1
fi
echo ""

# Step 8: Log sync completion
echo "Step 8: Logging sync completion..."
mkdir -p .ai-framework/logs
LOG_ENTRY="$(date '+%Y-%m-%d %H:%M:%S') - Pre-work sync successful - Branch: $BRANCH - Status: $SYNC_STATUS - Commit: $LOCAL"
echo "$LOG_ENTRY" >> .ai-framework/logs/sync.log
echo "✅ Logged to .ai-framework/logs/sync.log"
echo ""

# Step 9: Display summary
echo "=========================================="
echo "PRE-WORK SYNC COMPLETE"
echo "=========================================="
echo "Status: ✅ SUCCESS"
echo "Branch: $BRANCH"
echo "Commit: $LOCAL"
echo "Sync Status: $SYNC_STATUS"
echo ""
echo "Repository is ready for work."
echo "=========================================="

exit 0
