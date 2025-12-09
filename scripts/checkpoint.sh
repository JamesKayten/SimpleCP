#!/bin/bash
#
# SimpleCP Checkpoint Script
# Quick local tagging for feature milestones
#

set -e

# Change to repo directory
REPO_DIR="$(dirname "$0")/.."
cd "$REPO_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get description from argument or prompt
if [ -n "$1" ]; then
    DESC="$*"
else
    echo -e "${BLUE}What did you accomplish?${NC}"
    read -r DESC
fi

if [ -z "$DESC" ]; then
    echo -e "${RED}Error: Description required${NC}"
    exit 1
fi

# Get latest tag and increment
LATEST=$(git tag -l 'v*' --sort=-v:refname | head -1)
if [ -z "$LATEST" ]; then
    NEXT="v1.0.0"
else
    # Extract version numbers
    VERSION=${LATEST#v}
    MAJOR=$(echo "$VERSION" | cut -d. -f1)
    MINOR=$(echo "$VERSION" | cut -d. -f2)
    PATCH=$(echo "$VERSION" | cut -d. -f3)

    # Increment patch
    PATCH=$((PATCH + 1))
    NEXT="v${MAJOR}.${MINOR}.${PATCH}"
fi

# Check for changes
if git diff-index --quiet HEAD -- 2>/dev/null; then
    HAS_CHANGES=false
else
    HAS_CHANGES=true
fi

# Check for untracked files
UNTRACKED=$(git ls-files --others --exclude-standard)
if [ -n "$UNTRACKED" ]; then
    HAS_UNTRACKED=true
else
    HAS_UNTRACKED=false
fi

# Commit if there are changes
if [ "$HAS_CHANGES" = true ] || [ "$HAS_UNTRACKED" = true ]; then
    echo -e "${YELLOW}Staging changes...${NC}"
    git add -A
    git commit -m "$DESC"
    echo -e "${GREEN}✓ Committed${NC}"
else
    echo -e "${YELLOW}No changes to commit, tagging current HEAD${NC}"
fi

# Create tag
git tag -a "$NEXT" -m "$DESC"
echo -e "${GREEN}✓ Tagged ${NEXT}: ${DESC}${NC}"

# Summary
echo ""
echo -e "${BLUE}Checkpoint saved!${NC}"
echo -e "  Tag:    ${GREEN}${NEXT}${NC}"
echo -e "  Desc:   ${DESC}"
echo ""
echo -e "${YELLOW}To push later:${NC} git push origin ${NEXT}"
