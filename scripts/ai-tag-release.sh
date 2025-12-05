#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== AI-Powered Release Tagger ===${NC}\n"

call_ollama() {
    local prompt="$1"
    if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        return 1
    fi

    RESPONSE=$(curl -s http://localhost:11434/api/generate -d "{\"model\":\"llama3.2\",\"prompt\":\"$prompt\",\"stream\":false}")
    echo "$RESPONSE" | jq -r '.response' 2>/dev/null
}

detect_project_type() {
    local project_type="general software project"
    local project_emoji="🔧"

    # Check for specific project types based on file presence (most specific first)
    if find . -name "*.swift" -type f | head -1 | grep -q "Sources\|SimpleCP" 2>/dev/null; then
        project_type="macOS clipboard manager"
        project_emoji="📋"
    elif [ -f "backend/main.py" -o -f "frontend/package.json" ]; then
        project_type="full-stack application"
        project_emoji="🔄"
    elif [ -f "package.json" ]; then
        if [ -d "src" ] && [ -f "src/App.js" -o -f "src/App.tsx" ]; then
            project_type="React web application"
            project_emoji="⚛️"
        elif grep -q "\"@types/node\"" package.json 2>/dev/null; then
            project_type="Node.js application"
            project_emoji="🟢"
        else
            project_type="JavaScript/web application"
            project_emoji="🌐"
        fi
    elif [ -f "*.xcodeproj" -o -f "Package.swift" ] 2>/dev/null; then
        if ls *.xcodeproj >/dev/null 2>&1; then
            project_type="iOS/macOS application"
            project_emoji="🍎"
        else
            project_type="Swift package"
            project_emoji="🔶"
        fi
    elif [ -f "requirements.txt" -o -f "pyproject.toml" -o -f "setup.py" ]; then
        if [ -f "manage.py" ]; then
            project_type="Django web application"
            project_emoji="🐍"
        elif [ -f "app.py" -o -f "main.py" ]; then
            project_type="Python application"
            project_emoji="🐍"
        else
            project_type="Python library"
            project_emoji="📚"
        fi
    elif [ -f "Cargo.toml" ]; then
        project_type="Rust application"
        project_emoji="🦀"
    elif [ -f "go.mod" ]; then
        project_type="Go application"
        project_emoji="🐹"
    elif [ -f "pom.xml" -o -f "build.gradle" ]; then
        project_type="Java application"
        project_emoji="☕"
    elif [ -f "Dockerfile" ]; then
        project_type="containerized application"
        project_emoji="🐳"
    fi

    echo "${project_type}|${project_emoji}"
}

# Detect project type
PROJECT_INFO=$(detect_project_type)
PROJECT_TYPE=$(echo "$PROJECT_INFO" | cut -d'|' -f1)
PROJECT_EMOJI=$(echo "$PROJECT_INFO" | cut -d'|' -f2)

echo -e "${BLUE}${PROJECT_EMOJI} Project type: ${GREEN}${PROJECT_TYPE}${NC}\n"

CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.2.0")
echo -e "Current version: ${GREEN}${CURRENT_VERSION}${NC}"

if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
    UNCOMMITTED_FILES=$(git diff --name-only | head -5 | tr '\n' ', ')
    
    echo -e "${BLUE}🤖 Generating commit message...${NC}"
    AI_COMMIT_MSG=$(call_ollama "Generate a single-line git commit message (max 72 chars) for a $PROJECT_TYPE with changes to: $UNCOMMITTED_FILES. Reply with only the message.")
    
    if [ ! -z "$AI_COMMIT_MSG" ]; then
        AI_COMMIT_MSG=$(echo "$AI_COMMIT_MSG" | head -1 | sed 's/^["'"'"']//;s/["'"'"']$//')
        echo -e "${GREEN}AI commit message:${NC} ${YELLOW}${AI_COMMIT_MSG}${NC}\n"
        read -p "Use this? (y/n) [y]: " USE_IT
        USE_IT=${USE_IT:-y}
        if [[ $USE_IT == "y" ]]; then
            git add -A
            git commit -m "$AI_COMMIT_MSG"
        fi
    fi
fi

CURRENT_VERSION_NO_V=${CURRENT_VERSION#v}
MAJOR=$(echo $CURRENT_VERSION_NO_V | cut -d. -f1)
MINOR=$(echo $CURRENT_VERSION_NO_V | cut -d. -f2)
NEW_VERSION="v${MAJOR}.$((MINOR + 1)).0"

DIFF=$(git log ${CURRENT_VERSION}..HEAD --pretty=format:"%s" --no-merges | head -5 | tr '\n' ' ')

if [ -z "$DIFF" ]; then
    echo "No changes since last tag"
    exit 1
fi

echo -e "\n${BLUE}New version: ${GREEN}${NEW_VERSION}${NC}"
echo -e "${BLUE}🤖 Generating release notes...${NC}\n"

AI_NOTES=$(call_ollama "For a $PROJECT_TYPE, analyze these commits: $DIFF. Generate: 1) A 4-word release title, 2) 3 bullet points of user-facing changes. Format: TITLE: [title] NOTES: - [point1] - [point2] - [point3]")

RELEASE_TITLE=$(echo "$AI_NOTES" | grep "TITLE:" | sed 's/TITLE: //' | head -1)
RELEASE_NOTES=$(echo "$AI_NOTES" | sed -n '/NOTES:/,$p' | tail -n +2)

if [ -z "$RELEASE_TITLE" ]; then
    RELEASE_TITLE=$(echo "$AI_NOTES" | head -1)
    RELEASE_NOTES="- $AI_NOTES"
fi

echo -e "${GREEN}Title:${NC} ${YELLOW}${RELEASE_TITLE}${NC}"
echo -e "${GREEN}Notes:${NC}\n${RELEASE_NOTES}\n"

read -p "Proceed? (y/n) [y]: " CONFIRM
CONFIRM=${CONFIRM:-y}

if [[ $CONFIRM == "y" ]]; then
    git tag -a $NEW_VERSION -m "Feature Release ${NEW_VERSION} - ${RELEASE_TITLE}

${RELEASE_NOTES}"
    git push origin main --tags
    echo -e "\n${GREEN}✅ Released ${NEW_VERSION}${NC}"
fi
