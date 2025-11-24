#!/bin/bash
# Post-Work Sync Protocol (MANDATORY)
# This script MUST be executed after completing work on the repository
# Usage: bash post-work-sync.sh "Commit message describing work"
# Exit code 0 = Success, Exit code 1 = Failure

set -e  # Exit immediately on any error

echo "=========================================="
echo "POST-WORK SYNC PROTOCOL"
echo "=========================================="
echo ""

# Validate commit message argument
if [ -z "$1" ]; then
    echo "❌ FAILURE: No commit message provided"
    echo "USAGE: bash post-work-sync.sh \"Your commit message\""
    echo "EXAMPLE: bash post-work-sync.sh \"Fixed validation issues in UserModel\""
    exit 1
fi

COMMIT_MESSAGE="$1"

# Step 1: Verify we're in a git repository
echo "Step 1: Verifying git repository..."
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ FAILURE: Not in a git repository"
    exit 1
fi
echo "✅ Git repository confirmed"
echo ""

# Step 2: Show current status
echo "Step 2: Checking current status..."
git status
echo ""

# Step 3: Stage all changes
echo "Step 3: Staging all changes..."
git add -A

# Show what was staged
STAGED_FILES=$(git diff --cached --name-only | wc -l)
echo "✅ Staged $STAGED_FILES file(s)"
if [ "$STAGED_FILES" -gt 0 ]; then
    echo ""
    echo "Staged files:"
    git diff --cached --name-status
fi
echo ""

# Step 4: Check if there are changes to commit
echo "Step 4: Checking for changes to commit..."
if git diff-index --quiet --cached HEAD -- 2>/dev/null; then
    echo "⚠️  No changes to commit"
    echo "All work may already be committed or no changes were made"
    CHANGES_COMMITTED=false
else
    # Step 5: Commit changes
    echo "Step 5: Committing changes..."
    echo "Commit message: $COMMIT_MESSAGE"
    if ! git commit -m "$COMMIT_MESSAGE"; then
        echo "❌ FAILURE: Commit failed"
        echo "Check commit hooks or repository configuration"
        exit 1
    fi
    echo "✅ Changes committed successfully"
    CHANGES_COMMITTED=true
fi
echo ""

# Step 6: Get current branch
BRANCH=$(git branch --show-current)
echo "Step 6: Current branch: $BRANCH"
echo ""

# Step 7: Push to remote
echo "Step 7: Pushing to origin/$BRANCH..."
if ! git push origin "$BRANCH"; then
    echo "❌ FAILURE: Push failed"
    echo "POSSIBLE CAUSES:"
    echo "  - No internet connection"
    echo "  - Remote repository not accessible"
    echo "  - Authentication issues"
    echo "  - Remote has changes you don't have locally"
    echo ""
    echo "If push was rejected, you may need to:"
    echo "  1. Pull latest changes: git pull origin $BRANCH"
    echo "  2. Resolve any conflicts"
    echo "  3. Try pushing again"
    exit 1
fi
echo "✅ Push successful"
echo ""

# Step 8: Verify push
echo "Step 8: Verifying push status..."
git status
echo ""

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "no-upstream")

if [ "$REMOTE" = "no-upstream" ]; then
    echo "⚠️  No upstream branch (this is a new branch)"
    PUSH_STATUS="NEW_BRANCH"
elif [ "$LOCAL" = "$REMOTE" ]; then
    echo "✅ VERIFICATION SUCCESS: Local matches remote"
    echo "Commit: $LOCAL"
    PUSH_STATUS="SYNCED"
else
    echo "⚠️  WARNING: Local and remote differ after push"
    echo "Local:  $LOCAL"
    echo "Remote: $REMOTE"
    PUSH_STATUS="DIVERGED"
fi
echo ""

# Step 9: Log sync completion
echo "Step 9: Logging sync completion..."
mkdir -p .ai-framework/logs
LOG_ENTRY="$(date '+%Y-%m-%d %H:%M:%S') - Post-work sync successful - Branch: $BRANCH - Status: $PUSH_STATUS - Commit: $LOCAL - Message: $COMMIT_MESSAGE"
echo "$LOG_ENTRY" >> .ai-framework/logs/sync.log
echo "✅ Logged to .ai-framework/logs/sync.log"
echo ""

# Step 10: Display summary
echo "=========================================="
echo "POST-WORK SYNC COMPLETE"
echo "=========================================="
echo "Status: ✅ SUCCESS"
echo "Branch: $BRANCH"
echo "Commit: $LOCAL"
echo "Changes Committed: $CHANGES_COMMITTED"
echo "Push Status: $PUSH_STATUS"
echo ""
echo "Work has been saved and pushed to remote."
echo "=========================================="

exit 0
