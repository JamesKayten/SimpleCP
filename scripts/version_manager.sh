#!/bin/bash
# Version management script for SimpleCP

set -e

VERSION_FILE="VERSION"
CHANGELOG_FILE="CHANGELOG.md"

# Get current version
get_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "0.0.0"
    fi
}

# Set new version
set_version() {
    local new_version=$1
    echo "$new_version" > "$VERSION_FILE"
    echo "Version updated to: $new_version"
}

# Bump version
bump_version() {
    local bump_type=$1
    local current_version=$(get_version)

    IFS='.' read -r major minor patch <<< "$current_version"

    case $bump_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo "Invalid bump type. Use: major, minor, or patch"
            exit 1
            ;;
    esac

    local new_version="${major}.${minor}.${patch}"
    set_version "$new_version"
    echo "$new_version"
}

# Create release notes template
create_release_notes() {
    local version=$1
    local date=$(date +%Y-%m-%d)

    if [ ! -f "$CHANGELOG_FILE" ]; then
        echo "# Changelog" > "$CHANGELOG_FILE"
        echo "" >> "$CHANGELOG_FILE"
    fi

    # Add new version section at top
    temp_file=$(mktemp)
    echo "## [$version] - $date" > "$temp_file"
    echo "" >> "$temp_file"
    echo "### Added" >> "$temp_file"
    echo "- " >> "$temp_file"
    echo "" >> "$temp_file"
    echo "### Changed" >> "$temp_file"
    echo "- " >> "$temp_file"
    echo "" >> "$temp_file"
    echo "### Fixed" >> "$temp_file"
    echo "- " >> "$temp_file"
    echo "" >> "$temp_file"
    cat "$CHANGELOG_FILE" >> "$temp_file"
    mv "$temp_file" "$CHANGELOG_FILE"

    echo "Release notes template created in $CHANGELOG_FILE"
}

# Tag release
tag_release() {
    local version=$1

    if [ -z "$version" ]; then
        version=$(get_version)
    fi

    git tag -a "v${version}" -m "Release version ${version}"
    echo "Created git tag: v${version}"
    echo "Push with: git push origin v${version}"
}

# Main command handler
case ${1:-} in
    get)
        get_version
        ;;
    set)
        if [ -z "$2" ]; then
            echo "Usage: $0 set <version>"
            exit 1
        fi
        set_version "$2"
        ;;
    bump)
        if [ -z "$2" ]; then
            echo "Usage: $0 bump <major|minor|patch>"
            exit 1
        fi
        new_version=$(bump_version "$2")
        create_release_notes "$new_version"
        ;;
    release)
        version=${2:-$(get_version)}
        create_release_notes "$version"
        tag_release "$version"
        ;;
    *)
        echo "SimpleCP Version Manager"
        echo ""
        echo "Usage:"
        echo "  $0 get                    - Get current version"
        echo "  $0 set <version>          - Set version"
        echo "  $0 bump <major|minor|patch> - Bump version"
        echo "  $0 release [version]      - Create release"
        echo ""
        echo "Current version: $(get_version)"
        ;;
esac
