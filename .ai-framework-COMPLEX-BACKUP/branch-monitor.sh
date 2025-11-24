#!/bin/bash
# BRANCH MONITORING SYSTEM - Fix Framework Blindspot
# Purpose: Monitor all claude/* branches for OCC activity and progress

echo "🔍 MULTI-BRANCH ACTIVITY MONITOR"
echo "================================="
echo

# Get current timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Fetch latest changes
echo "📡 Fetching latest changes..."
git fetch --all --quiet

echo "🌿 ACTIVE CLAUDE BRANCHES:"
echo

# Track all claude/* branches
claude_branches=$(git branch -r | grep -E "origin/claude/" | grep -v HEAD | sed 's/origin\///')

if [ -z "$claude_branches" ]; then
    echo "❌ No active Claude branches found"
    exit 1
fi

# Initialize activity summary
cat > .ai-framework/BRANCH_ACTIVITY.md << 'EOF'
# 🌿 BRANCH ACTIVITY MONITOR
**Last Updated:** TIMESTAMP_PLACEHOLDER

## 📊 ACTIVE DEVELOPMENT SUMMARY

EOF

# Replace timestamp
sed -i '' "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/g" .ai-framework/BRANCH_ACTIVITY.md

echo "| Branch | Last Commit | Age | Message |"
echo "|--------|-------------|-----|---------|"

# Process each claude branch
for branch in $claude_branches; do
    # Get last commit info
    last_commit=$(git log "origin/$branch" --format="%h %cr %s" -1 2>/dev/null)

    if [ ! -z "$last_commit" ]; then
        commit_hash=$(echo "$last_commit" | awk '{print $1}')
        commit_age=$(echo "$last_commit" | awk '{print $2, $3}')
        commit_message=$(echo "$last_commit" | cut -d' ' -f4-)

        echo "| \`$branch\` | \`$commit_hash\` | $commit_age | $commit_message |"

        # Add to activity report
        echo "### 🔄 \`$branch\`" >> .ai-framework/BRANCH_ACTIVITY.md
        echo "- **Last Commit:** \`$commit_hash\` ($commit_age)" >> .ai-framework/BRANCH_ACTIVITY.md
        echo "- **Message:** $commit_message" >> .ai-framework/BRANCH_ACTIVITY.md
        echo "" >> .ai-framework/BRANCH_ACTIVITY.md
    fi
done

echo
echo "🎯 RECENT COMMIT ANALYSIS:"
echo

# Get commits in last 24 hours across all claude branches
recent_commits=0
for branch in $claude_branches; do
    commit_count=$(git log "origin/$branch" --since="24 hours ago" --oneline 2>/dev/null | wc -l)
    recent_commits=$((recent_commits + commit_count))

    if [ $commit_count -gt 0 ]; then
        echo "📈 \`$branch\`: $commit_count commits (last 24h)"

        echo "#### Recent Activity on \`$branch\`:" >> .ai-framework/BRANCH_ACTIVITY.md
        git log "origin/$branch" --since="24 hours ago" --format="- \`%h\` %cr: %s" 2>/dev/null >> .ai-framework/BRANCH_ACTIVITY.md
        echo "" >> .ai-framework/BRANCH_ACTIVITY.md
    fi
done

echo
echo "📊 TOTAL RECENT ACTIVITY: $recent_commits commits (24h)"
echo

# Add summary to report
echo "## 📊 Activity Summary" >> .ai-framework/BRANCH_ACTIVITY.md
echo "- **Total Active Branches:** $(echo "$claude_branches" | wc -l | tr -d ' ')" >> .ai-framework/BRANCH_ACTIVITY.md
echo "- **Recent Commits (24h):** $recent_commits" >> .ai-framework/BRANCH_ACTIVITY.md
echo "- **Last Scan:** $TIMESTAMP" >> .ai-framework/BRANCH_ACTIVITY.md

echo "✅ Branch activity report generated: .ai-framework/BRANCH_ACTIVITY.md"
echo

# Check for specific OCC completion markers
echo "🔍 SCANNING FOR OCC COMPLETION MARKERS:"
completion_found=false

for branch in $claude_branches; do
    # Look for completion indicators in commit messages
    completion_commits=$(git log "origin/$branch" --since="48 hours ago" --grep="Complete\|Implement\|Finish\|Done" --oneline 2>/dev/null)

    if [ ! -z "$completion_commits" ]; then
        echo "✅ Completion markers found in \`$branch\`:"
        echo "$completion_commits" | sed 's/^/   /'
        completion_found=true
    fi
done

if [ "$completion_found" = true ]; then
    echo "🎉 OCC appears to be actively completing tasks!"
else
    echo "🔍 No obvious completion markers found in recent commits"
fi

echo
echo "🔄 Framework blindspot analysis complete."