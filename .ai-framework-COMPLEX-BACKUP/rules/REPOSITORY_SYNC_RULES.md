# Repository Synchronization Rules

**Framework:** Avery's AI Collaboration Hack v1.0
**Date:** November 18, 2025
**Scope:** Cross-Platform AI Collaboration

---

## 🔄 **MANDATORY SYNCHRONIZATION PROTOCOL**

### **Rule 1: Complete Repository Mirroring**
**All repository content MUST be copied to the local machine repository during AI collaboration workflow.**

#### **Synchronization Requirements:**
- ✅ **All source files** (`src/` directory)
- ✅ **All test files** (`tests/` directory)
- ✅ **All AI communication files** (`.ai-framework/communications/`)
- ✅ **All framework configuration** (`.ai-framework/` entire directory)
- ✅ **All project documentation** (`docs/` directory if present)
- ✅ **All configuration files** (`.gitignore`, `pyproject.toml`, etc.)

#### **Exclusions:**
- ❌ **Temporary files** (`__pycache__/`, `.pytest_cache/`)
- ❌ **Local environment files** (`.venv/`, `.env`)
- ❌ **IDE-specific files** (`.vscode/`, `.idea/`)
- ❌ **Large binary files** (unless specifically required)

---

## 📋 **SYNCHRONIZATION WORKFLOW**

### **Phase 1: Pre-Collaboration Setup**
1. **Local AI (TCC)** creates validation reports in `.ai-framework/communications/reports/`
2. **Repository state** synchronized to ensure Online AI has access to:
   - Latest source code
   - Current framework configuration
   - Historical AI communications
   - Project state documentation

### **Phase 2: Online AI Access**
**Method Selection (Choose appropriate method):**

#### **Method A: Direct Repository Access (Preferred)**
- Online AI connects directly to repository (GitHub, GitLab, etc.)
- Reads files directly from repository interface
- Creates commits with fixes and responses

#### **Method B: File Upload Protocol**
- User uploads required files to Online AI session:
  - Latest validation report from `.ai-framework/communications/reports/`
  - Source files requiring fixes from `src/`
  - Current validation rules from `.ai-framework/rules/`

#### **Method C: Copy-Paste Protocol**
- User copies content of validation reports
- User copies source code requiring fixes
- Online AI processes and provides corrected versions
- User manually creates response files

### **Phase 3: Response Integration**
1. **Online AI responses** MUST be copied back to local repository:
   - Fixed source files → `src/` directory
   - AI response documentation → `.ai-framework/communications/responses/`
   - Any new test files → `tests/` directory

2. **Local AI (TCC)** performs re-validation using complete repository state

---

## 🔧 **IMPLEMENTATION COMMANDS**

### **For Local AI (TCC) Validation:**
```bash
# Always run from repository root
cd /path/to/project

# Ensure all files are committed before validation
git add .
git status

# Run validation workflow
"work ready"
```

### **For Repository State Verification:**
```bash
# Check repository completeness
find . -name "*.py" -o -name "*.md" -o -name "*.json" -o -name "*.toml" | grep -v __pycache__ | sort

# Verify AI framework structure
ls -la .ai-framework/
tree .ai-framework/
```

### **For Online AI Integration:**
```bash
# After Online AI provides fixes, integrate immediately:
cp /path/to/fixed/files src/
cp /path/to/ai/response .ai-framework/communications/responses/

# Re-run validation
"work ready"
```

---

## 📊 **SYNCHRONIZATION VERIFICATION**

### **Pre-Validation Checklist:**
- [ ] All source files present in `src/`
- [ ] All tests present in `tests/`
- [ ] Framework configuration complete in `.ai-framework/`
- [ ] No uncommitted changes in working directory
- [ ] Project state documentation current

### **Post-Collaboration Checklist:**
- [ ] Online AI fixes integrated into `src/`
- [ ] Response documentation in `.ai-framework/communications/responses/`
- [ ] All files committed to repository
- [ ] Local AI re-validation completed successfully

---

## 🚨 **CRITICAL SYNCHRONIZATION RULES**

### **Rule 2: Version Control Integrity**
- **Every AI collaboration cycle** MUST result in clean git commits
- **All file changes** MUST be tracked in version control
- **Repository history** MUST clearly show AI collaboration workflow

### **Rule 3: Framework State Consistency**
- **Project state** MUST be updated after every collaboration cycle
- **Validation rules** MUST reflect current project standards
- **Communication logs** MUST be preserved for audit trail

### **Rule 4: Cross-Platform File Access**
- **File paths** MUST be consistent across Local and Online AI environments
- **File encoding** MUST be UTF-8 for all text files
- **Line endings** MUST be standardized (LF for Unix/Mac, CRLF for Windows)

---

## 🔄 **REPOSITORY SYNC COMMANDS**

### **Automated Sync Script Template:**
```bash
#!/bin/bash
# AI Collaboration Repository Sync

echo "🔄 Syncing repository for AI collaboration..."

# 1. Ensure clean working directory
git status --porcelain
if [ $? -ne 0 ]; then
    echo "❌ Working directory not clean. Commit changes first."
    exit 1
fi

# 2. Pull latest changes
git pull origin main

# 3. Verify framework structure
if [ ! -d ".ai-framework" ]; then
    echo "❌ AI Framework not installed. Run framework installer first."
    exit 1
fi

# 4. Update project state
echo "📝 Repository ready for AI collaboration"
echo "📍 Use: 'work ready' to start validation workflow"
echo "🌐 Use: 'Check .ai-framework/communications/ for latest report' for Online AI"
```

---

## 📈 **SYNC MONITORING**

### **Repository Health Metrics:**
- **Files in sync:** All source, test, and framework files present
- **Communication completeness:** Reports and responses properly filed
- **Version control status:** Clean working directory, committed changes
- **Framework integrity:** All required directories and files present

### **Failure Indicators:**
- Missing files in expected directories
- Uncommitted changes during collaboration
- Broken file paths or encoding issues
- Framework configuration inconsistencies

---

**Compliance with these synchronization rules ensures reliable cross-platform AI collaboration and maintains repository integrity throughout the workflow.**

**Last Updated:** November 18, 2025
**Version:** 1.0
**Framework:** Avery's AI Collaboration Hack