#!/bin/bash
# cleanup-worktree.sh - Remove worktree and switch main to dev
# Run this AFTER closing Claude Code session

set -e

REPO="/Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP"
WORKTREE_DIR="/Volumes/User_Smallfavor/Users/Smallfavor/.claude-worktrees/SimpleCP"

echo "=== Worktree Cleanup ==="

# 1. Remove git worktree
echo "1. Removing worktree from git..."
cd "$REPO"
git worktree remove bold-matsumoto --force 2>/dev/null || git worktree prune

# 2. Delete worktree directory
echo "2. Deleting worktree directory..."
rm -rf "$WORKTREE_DIR"

# 3. Switch to dev branch
echo "3. Switching to dev branch..."
git checkout dev

# 4. Verify
echo ""
echo "=== Done ==="
echo "Current branch: $(git branch --show-current)"
echo ""
echo "Now:"
echo "  1. Open Xcode project in: $REPO/frontend/SimpleCP-App/"
echo "  2. Start Claude Code in: $REPO"
