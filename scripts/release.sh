#!/bin/bash
#
# SimpleCP Release Script
# Automates GitHub release creation and asset upload
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get version
VERSION=$(python3 -c "from version import __version__; print(__version__)")
TAG="v${VERSION}"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}SimpleCP Release Script${NC}"
echo -e "${BLUE}Version: ${VERSION}${NC}"
echo -e "${BLUE}================================${NC}\n"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) not installed${NC}"
    echo "Install with: brew install gh"
    exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not logged in to GitHub${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Tag $TAG already exists${NC}"
    echo -e "Delete it? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        git tag -d "$TAG"
        git push origin :"$TAG" 2>/dev/null || true
    else
        exit 1
    fi
fi

# Ensure we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}Warning: Not on main branch (currently on: $CURRENT_BRANCH)${NC}"
    echo -e "Continue? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}Error: Uncommitted changes detected${NC}"
    echo "Commit or stash changes before releasing"
    exit 1
fi

# Run build
echo -e "${YELLOW}Running build script...${NC}"
./scripts/build.sh
echo -e "${GREEN}✓ Build complete${NC}\n"

# Check if CHANGELOG exists and has entry for this version
if [ -f CHANGELOG.md ]; then
    if ! grep -q "## \[$VERSION\]" CHANGELOG.md; then
        echo -e "${YELLOW}Warning: No CHANGELOG entry for version $VERSION${NC}"
        echo -e "Continue anyway? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Extract release notes from CHANGELOG
RELEASE_NOTES=""
if [ -f CHANGELOG.md ]; then
    # Extract notes between this version and the next
    RELEASE_NOTES=$(sed -n "/## \[$VERSION\]/,/## \[/p" CHANGELOG.md | head -n -1 | tail -n +2)
fi

# If no release notes, use a template
if [ -z "$RELEASE_NOTES" ]; then
    RELEASE_NOTES="Release v${VERSION}

## What's New

- Production-ready clipboard manager
- Comprehensive monitoring and analytics
- Complete testing infrastructure
- Full documentation suite

## Installation

Download and extract the package, then follow QUICKSTART.md

## Documentation

- User Guide: docs/USER_GUIDE.md
- API Reference: docs/API.md
- Quick Start: QUICKSTART.md

For more information, see the README.md"
fi

# Create git tag
echo -e "${YELLOW}Creating git tag ${TAG}...${NC}"
git tag -a "$TAG" -m "Release $VERSION"
git push origin "$TAG"
echo -e "${GREEN}✓ Tag created and pushed${NC}\n"

# Create GitHub release
echo -e "${YELLOW}Creating GitHub release...${NC}"

# Save release notes to temp file
NOTES_FILE=$(mktemp)
echo "$RELEASE_NOTES" > "$NOTES_FILE"

gh release create "$TAG" \
    --title "SimpleCP v${VERSION}" \
    --notes-file "$NOTES_FILE" \
    dist/simplecp-${VERSION}.tar.gz \
    dist/simplecp-${VERSION}.tar.gz.sha256 \
    dist/simplecp-${VERSION}.zip \
    dist/simplecp-${VERSION}.zip.sha256

rm "$NOTES_FILE"

echo -e "${GREEN}✓ GitHub release created${NC}\n"

# Upload wheel if exists
if ls dist/*.whl 1> /dev/null 2>&1; then
    echo -e "${YELLOW}Uploading wheel package...${NC}"
    gh release upload "$TAG" dist/*.whl
    echo -e "${GREEN}✓ Wheel uploaded${NC}\n"
fi

# Display release info
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Release Complete!${NC}"
echo -e "${BLUE}================================${NC}\n"

echo -e "${GREEN}Release: ${NC}https://github.com/JamesKayten/SimpleCP/releases/tag/${TAG}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Verify release on GitHub"
echo "2. Test installation from release assets"
echo "3. Announce release (if public)"
echo "4. Update documentation if needed"

# Check for updates announcement
echo -e "\n${YELLOW}Want to create a discussion post? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Creating discussion..."
    gh discussion create \
        --title "SimpleCP v${VERSION} Released!" \
        --body "Version ${VERSION} is now available!

Download: https://github.com/JamesKayten/SimpleCP/releases/tag/${TAG}

${RELEASE_NOTES}" \
        --category "Announcements" || echo -e "${YELLOW}Could not create discussion${NC}"
fi

echo -e "\n${GREEN}🎉 Release ${TAG} published successfully!${NC}"
