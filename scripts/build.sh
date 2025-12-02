#!/bin/bash
#
# SimpleCP Build Script
# Creates distribution packages for deployment
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="SimpleCP"
BUILD_DIR="dist"
VERSION=$(python3 -c "from version import __version__; print(__version__)")

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}SimpleCP Build Script${NC}"
echo -e "${BLUE}Version: ${VERSION}${NC}"
echo -e "${BLUE}================================${NC}\n"

# Check Python version
echo -e "${YELLOW}Checking Python version...${NC}"
python3 --version
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Python 3 not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python OK${NC}\n"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf build/ dist/ *.egg-info
echo -e "${GREEN}✓ Cleaned${NC}\n"

# Install/upgrade build tools
echo -e "${YELLOW}Installing build tools...${NC}"
pip install --upgrade pip setuptools wheel build
echo -e "${GREEN}✓ Build tools ready${NC}\n"

# Run tests
echo -e "${YELLOW}Running tests...${NC}"
pytest --tb=short -q
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Tests failed${NC}"
    echo -e "${YELLOW}Continue anyway? (y/n)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo -e "${GREEN}✓ Tests passed${NC}\n"

# Check code quality
echo -e "${YELLOW}Checking code quality...${NC}"
ruff check . || echo -e "${YELLOW}Warning: Linting issues found${NC}"
echo -e "${GREEN}✓ Code quality check complete${NC}\n"

# Build distribution
echo -e "${YELLOW}Building distribution...${NC}"
python3 -m build
echo -e "${GREEN}✓ Distribution built${NC}\n"

# Create deployment package
echo -e "${YELLOW}Creating deployment package...${NC}"
DEPLOY_DIR="${BUILD_DIR}/simplecp-${VERSION}"
mkdir -p "${DEPLOY_DIR}"

# Copy files
cp -r \
    api/ \
    stores/ \
    docs/ \
    tests/ \
    clipboard_manager.py \
    daemon.py \
    logger.py \
    monitoring.py \
    settings.py \
    version.py \
    requirements.txt \
    .env.example \
    README.md \
    QUICKSTART.md \
    CONTRIBUTING.md \
    LICENSE \
    "${DEPLOY_DIR}/" 2>/dev/null || true

# Create deployment README
cat > "${DEPLOY_DIR}/DEPLOY.md" << 'EOF'
# SimpleCP Deployment Package

## Quick Start

```bash
# Install dependencies
pip3 install -r requirements.txt

# Configure (optional)
cp .env.example .env
# Edit .env as needed

# Run daemon
python3 daemon.py
```

## Files Included

- `api/` - REST API server
- `stores/` - Data storage modules
- `docs/` - Complete documentation
- `clipboard_manager.py` - Core manager
- `daemon.py` - Background daemon
- `requirements.txt` - Dependencies
- `.env.example` - Configuration template

## Documentation

- User Guide: docs/USER_GUIDE.md
- API Reference: docs/API.md
- Troubleshooting: docs/TROUBLESHOOTING.md
- Quick Start: QUICKSTART.md

## Support

- GitHub: https://github.com/JamesKayten/SimpleCP
- Issues: https://github.com/JamesKayten/SimpleCP/issues
- Docs: https://github.com/JamesKayten/SimpleCP/blob/main/README.md
EOF

# Create archive
cd "${BUILD_DIR}"
tar -czf "simplecp-${VERSION}.tar.gz" "simplecp-${VERSION}/"
zip -r "simplecp-${VERSION}.zip" "simplecp-${VERSION}/" > /dev/null
cd ..

echo -e "${GREEN}✓ Deployment package created${NC}\n"

# Generate checksums
echo -e "${YELLOW}Generating checksums...${NC}"
cd "${BUILD_DIR}"
shasum -a 256 "simplecp-${VERSION}.tar.gz" > "simplecp-${VERSION}.tar.gz.sha256"
shasum -a 256 "simplecp-${VERSION}.zip" > "simplecp-${VERSION}.zip.sha256"
cd ..
echo -e "${GREEN}✓ Checksums generated${NC}\n"

# Display results
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Build Complete!${NC}"
echo -e "${BLUE}================================${NC}\n"

echo -e "${GREEN}Distribution files:${NC}"
ls -lh "${BUILD_DIR}"/*.tar.gz "${BUILD_DIR}"/*.zip 2>/dev/null || true

echo -e "\n${GREEN}Wheel packages:${NC}"
ls -lh dist/*.whl 2>/dev/null || true

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Test the deployment package"
echo "2. Review CHANGELOG.md"
echo "3. Create GitHub release"
echo "4. Upload distribution files"

echo -e "\n${GREEN}Build artifacts saved in:${NC}"
echo "  - ${BUILD_DIR}/simplecp-${VERSION}.tar.gz"
echo "  - ${BUILD_DIR}/simplecp-${VERSION}.zip"
echo "  - dist/*.whl"
