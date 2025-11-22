# INSTRUCTIONS FOR TCC: Installing TCC Configuration on User's Local Machine

## 🎯 Mission

Install the TCC configuration system on the user's local machine so that TCC has automatic access to the AI Collaboration Management framework in every terminal session.

---

## ⚡ Quick Install Method (Recommended)

TCC, when the user asks you to set this up on their local machine, follow these steps:

### Step 1: Download and Run the Installation Script

```bash
# Download the installation script
curl -sSL https://raw.githubusercontent.com/JamesKayten/SimpleCP/claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU/install-tcc.sh -o ~/install-tcc.sh

# Make it executable
chmod +x ~/install-tcc.sh

# Run the installation
~/install-tcc.sh
```

### Step 2: Reload Shell Configuration

```bash
# Reload bash configuration (or zsh if that's what they use)
source ~/.bashrc
# OR for zsh users:
# source ~/.zshrc
```

### Step 3: Initialize TCC

```bash
# Run TCC initialization
source ~/tcc-init.sh
```

### Step 4: Verify Installation

```bash
# Check that everything is working
tcc-status
```

**Expected Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 TCC Framework Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Framework Location: /home/user/AI-Collaboration-Management
Current Project:    /home/user/[current-directory]

✅ AI Framework found

📋 Available Rules:
  ✅ General AI Rules
  ✅ Startup Protocol
  ✅ Rule Improvements
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 📋 Manual Install Method (Alternative)

If the automatic installation fails, TCC can install manually:

### Step 1: Create Configuration File (~/.tccrc)

```bash
curl -sSL https://raw.githubusercontent.com/JamesKayten/SimpleCP/claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU/tcc-config-files/.tccrc -o ~/.tccrc
```

**Or create it manually:**

```bash
cat > ~/.tccrc << 'EOF'
# TCC Configuration
export AI_FRAMEWORK_REPO="$HOME/AI-Collaboration-Management"
export AI_RULES_DIR="$AI_FRAMEWORK_REPO/rules"
export AI_TEMPLATES_DIR="$AI_FRAMEWORK_REPO/templates"
export AI_GENERAL_RULES="$AI_RULES_DIR/GENERAL_AI_RULES.md"
export AI_STARTUP_PROTOCOL="$AI_RULES_DIR/STARTUP_PROTOCOL.md"
export AI_RULE_IMPROVEMENTS="$AI_RULES_DIR/RULE_IMPROVEMENTS.md"
export CURRENT_PROJECT_DIR="$(pwd)"
export PROJECT_AI_DIR="$CURRENT_PROJECT_DIR/.ai"

check_framework() {
    if [ ! -d "$AI_FRAMEWORK_REPO" ]; then
        echo "⚠️  AI Framework not found at: $AI_FRAMEWORK_REPO"
        return 1
    else
        echo "✅ AI Framework found at: $AI_FRAMEWORK_REPO"
        return 0
    fi
}

framework_status() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🤖 TCC Framework Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Framework: $AI_FRAMEWORK_REPO"
    echo "Project:   $CURRENT_PROJECT_DIR"
    check_framework && echo "✅ Framework ready" || echo "❌ Framework not found"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

check_board() {
    [ -f "$PROJECT_AI_DIR/BOARD.md" ] && cat "$PROJECT_AI_DIR/BOARD.md" || echo "❌ No BOARD.md found"
}

view_rules() {
    [ -f "$AI_GENERAL_RULES" ] && cat "$AI_GENERAL_RULES" || echo "❌ Rules not found"
}

view_startup() {
    [ -f "$AI_STARTUP_PROTOCOL" ] && cat "$AI_STARTUP_PROTOCOL" || echo "❌ Startup protocol not found"
}

setup_project() {
    export CURRENT_PROJECT_DIR="$(pwd)"
    export PROJECT_AI_DIR="$CURRENT_PROJECT_DIR/.ai"
    framework_status
}

sync_framework() {
    if [ -d "$AI_FRAMEWORK_REPO" ]; then
        cd "$AI_FRAMEWORK_REPO" && git pull origin main && cd - > /dev/null
    fi
}

alias tcc-status='framework_status'
alias tcc-board='check_board'
alias tcc-rules='view_rules'
alias tcc-startup='view_startup'
alias tcc-setup='setup_project'
alias tcc-sync='sync_framework'

echo "🤖 TCC Configuration Loaded"
EOF
```

### Step 2: Create Initialization Script (~/tcc-init.sh)

```bash
curl -sSL https://raw.githubusercontent.com/JamesKayten/SimpleCP/claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU/tcc-config-files/tcc-init.sh -o ~/tcc-init.sh
chmod +x ~/tcc-init.sh
```

### Step 3: Update Shell Configuration

**For Bash users:**

```bash
cat >> ~/.bashrc << 'EOF'

# ============================================================================
# TCC (Terminal Control Center) Configuration
# ============================================================================
if [ -f ~/.tccrc ]; then
    source ~/.tccrc
fi
EOF
```

**For Zsh users:**

```bash
cat >> ~/.zshrc << 'EOF'

# ============================================================================
# TCC (Terminal Control Center) Configuration
# ============================================================================
if [ -f ~/.tccrc ]; then
    source ~/.tccrc
fi
EOF
```

### Step 4: Clone AI Collaboration Management Framework

```bash
git clone https://github.com/JamesKayten/AI-Collaboration-Management.git ~/AI-Collaboration-Management
```

### Step 5: Reload and Test

```bash
# Reload shell
source ~/.bashrc  # or source ~/.zshrc

# Initialize TCC
source ~/tcc-init.sh

# Verify
tcc-status
```

---

## 🔍 Verification Checklist

After installation, verify these items exist:

```bash
# Check configuration file
ls -la ~/.tccrc
# Expected: -rw-r--r-- ... /home/user/.tccrc

# Check initialization script
ls -la ~/tcc-init.sh
# Expected: -rwxr-xr-x ... /home/user/tcc-init.sh (executable)

# Check shell configuration
grep -n "tccrc" ~/.bashrc
# Expected: Line number with "source ~/.tccrc"

# Check framework repository
ls -la ~/AI-Collaboration-Management/rules/
# Expected: GENERAL_AI_RULES.md, STARTUP_PROTOCOL.md, RULE_IMPROVEMENTS.md

# Test commands
tcc-status
# Expected: Framework status display

# Test framework access
cat $AI_GENERAL_RULES | head -20
# Expected: Display first 20 lines of General AI Rules
```

---

## 🚀 TCC's First Command in Every New Session

After installation is complete, TCC should run this as the **first command** in every new terminal session:

```bash
source ~/tcc-init.sh
```

**This command will:**
1. Load all TCC configuration
2. Verify framework repository exists
3. Check for framework updates
4. Set environment variables
5. Display available commands
6. Confirm "Rules confirmed - holistic approach enabled"

---

## 📋 Available Commands After Installation

Once installed, TCC has access to these commands:

| Command | Description |
|---------|-------------|
| `tcc-status` | Display framework and project status |
| `tcc-board` | View current project's BOARD.md |
| `tcc-rules` | Display GENERAL_AI_RULES.md |
| `tcc-startup` | Display STARTUP_PROTOCOL.md |
| `tcc-setup` | Configure TCC for current project |
| `tcc-sync` | Sync framework with latest updates |

---

## 🎯 Environment Variables Available

After initialization, TCC has access to:

```bash
$AI_FRAMEWORK_REPO      # ~/AI-Collaboration-Management
$AI_RULES_DIR           # ~/AI-Collaboration-Management/rules
$AI_GENERAL_RULES       # Path to GENERAL_AI_RULES.md
$AI_STARTUP_PROTOCOL    # Path to STARTUP_PROTOCOL.md
$AI_RULE_IMPROVEMENTS   # Path to RULE_IMPROVEMENTS.md
$CURRENT_PROJECT_DIR    # Current working directory
$PROJECT_AI_DIR         # Current project's .ai directory
```

**Example usage:**

```bash
# View the general rules
cat $AI_GENERAL_RULES

# Check if project has a board
ls -la $PROJECT_AI_DIR/BOARD.md

# Navigate to framework
cd $AI_FRAMEWORK_REPO
```

---

## 🔧 Troubleshooting

### Issue: "Command not found: tcc-status"

**Diagnosis:**
```bash
# Check if configuration is loaded
echo $AI_FRAMEWORK_REPO
```

**Solution:**
```bash
# Reload configuration
source ~/.tccrc

# Or reload shell
source ~/.bashrc
```

### Issue: "AI Framework not found"

**Diagnosis:**
```bash
# Check if framework exists
ls -la ~/AI-Collaboration-Management
```

**Solution:**
```bash
# Clone the framework
git clone https://github.com/JamesKayten/AI-Collaboration-Management.git ~/AI-Collaboration-Management

# Then reinitialize
source ~/tcc-init.sh
```

### Issue: "No BOARD.md found"

**Diagnosis:**
```bash
# Check current project
echo $PROJECT_AI_DIR
ls -la $PROJECT_AI_DIR
```

**Solution:**
This is normal if you're not in a project directory that uses the AI Collaboration Management framework. Navigate to a project directory:

```bash
cd ~/SimpleCP
tcc-setup
tcc-board
```

### Issue: Installation script fails to download

**Solution:**
Use the manual installation method (see section above) or download files directly from the repository.

---

## 📂 File Locations Reference

After installation, these files will exist:

```
~/.tccrc                              # TCC configuration
~/tcc-init.sh                         # Initialization script
~/.bashrc or ~/.zshrc                 # Shell config (modified)
~/AI-Collaboration-Management/        # Framework repository
  ├── rules/
  │   ├── GENERAL_AI_RULES.md
  │   ├── STARTUP_PROTOCOL.md
  │   └── RULE_IMPROVEMENTS.md
  └── templates/
      └── project_rules_template.md
```

---

## 🎓 Example: TCC's First Session After Installation

```bash
# User opens a new terminal and invokes TCC

# TCC's first command:
source ~/tcc-init.sh

# Output:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 Initializing TCC Session
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Loading TCC configuration...
✅ Configuration loaded

✅ Framework repository found: /home/user/AI-Collaboration-Management
🔍 Checking for framework updates...
✅ Framework is up to date

🔍 Verifying framework structure...
✅ General AI Rules found
✅ Startup Protocol found
✅ Rules directory found

📁 Checking project context...
   Working directory: /home/user/current-directory

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 TCC Commands Available:
  tcc-status    - Display framework and project status
  tcc-board     - View current project BOARD.md
  tcc-rules     - Display General AI Rules
  tcc-startup   - Display Startup Protocol
  tcc-setup     - Configure TCC for current project
  tcc-sync      - Sync framework with latest updates
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ TCC Initialization Complete
   Rules confirmed - holistic approach enabled

# TCC can now check status:
tcc-status

# TCC can view rules:
tcc-rules

# TCC can check for tasks:
tcc-board

# TCC has all environment variables:
echo $AI_GENERAL_RULES
# Output: /home/user/AI-Collaboration-Management/rules/GENERAL_AI_RULES.md
```

---

## ✅ Success Criteria

Installation is successful when:

1. ✅ `~/.tccrc` exists and contains configuration
2. ✅ `~/tcc-init.sh` exists and is executable
3. ✅ Shell configuration sources `~/.tccrc`
4. ✅ Framework repository exists at `~/AI-Collaboration-Management`
5. ✅ All rule files exist in framework
6. ✅ `tcc-status` command works
7. ✅ `source ~/tcc-init.sh` runs without errors
8. ✅ Environment variables are set (`echo $AI_FRAMEWORK_REPO` returns path)

---

## 🎯 Summary for TCC

**Your installation task is:**

1. Run the quick install command:
   ```bash
   curl -sSL https://raw.githubusercontent.com/JamesKayten/SimpleCP/claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU/install-tcc.sh -o ~/install-tcc.sh && chmod +x ~/install-tcc.sh && ~/install-tcc.sh
   ```

2. Reload shell configuration:
   ```bash
   source ~/.bashrc
   ```

3. Initialize TCC:
   ```bash
   source ~/tcc-init.sh
   ```

4. Verify installation:
   ```bash
   tcc-status
   ```

**After installation, your first command in every new session:**

```bash
source ~/tcc-init.sh
```

This gives you instant access to the AI Collaboration Management framework, ensuring you always follow the holistic approach and startup protocol.

---

**Questions or Issues?**

If installation fails, report the specific error message and TCC can troubleshoot or use the manual installation method.

**Repository:** https://github.com/JamesKayten/SimpleCP
**Branch:** claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU
**Installation Script:** https://raw.githubusercontent.com/JamesKayten/SimpleCP/claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU/install-tcc.sh
