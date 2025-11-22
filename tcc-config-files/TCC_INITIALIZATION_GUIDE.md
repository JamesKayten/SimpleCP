# TCC (Terminal Control Center) Initialization Guide

## Overview

This guide explains how TCC can access the AI Collaboration Management framework when starting a new terminal session. The system provides automatic access to rules, protocols, and project context.

---

## 🚀 Quick Start for TCC

When TCC starts in a new terminal session, run this command first:

```bash
source /home/user/tcc-init.sh
```

This single command will:
- ✅ Load TCC configuration
- ✅ Verify framework repository access
- ✅ Check for framework updates
- ✅ Set up environment variables
- ✅ Display available commands
- ✅ Confirm project context

---

## 📋 System Architecture

### 1. Configuration File: `~/.tccrc`

**Location:** `/home/user/.tccrc`

**Purpose:** Provides environment variables and helper functions for TCC

**Key Environment Variables:**
- `AI_FRAMEWORK_REPO` - Path to AI-Collaboration-Management repository
- `AI_RULES_DIR` - Path to rules directory
- `AI_GENERAL_RULES` - Path to GENERAL_AI_RULES.md
- `AI_STARTUP_PROTOCOL` - Path to STARTUP_PROTOCOL.md
- `CURRENT_PROJECT_DIR` - Current working project directory
- `PROJECT_AI_DIR` - Path to project's .ai directory

**Auto-loaded:** Yes, via `~/.bashrc` on every terminal session

### 2. Initialization Script: `~/tcc-init.sh`

**Location:** `/home/user/tcc-init.sh`

**Purpose:** Comprehensive session initialization with framework verification

**What it does:**
1. Sources `~/.tccrc` configuration
2. Checks for framework repository (clones if missing)
3. Verifies framework structure integrity
4. Checks for framework updates
5. Validates project context
6. Displays available TCC commands

### 3. Shell Integration: `~/.bashrc`

**Modification:** Added at the end of `~/.bashrc`:

```bash
# Source TCC configuration for AI Collaboration Management framework access
if [ -f ~/.tccrc ]; then
    source ~/.tccrc
fi
```

**Effect:** Every new terminal session automatically loads TCC configuration

---

## 🎯 TCC Session Startup Protocol

### Recommended First Command

```bash
source /home/user/tcc-init.sh
```

### Expected Output

```
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
   Working directory: /home/user/SimpleCP
✅ Project .ai directory found
✅ BOARD.md found - use 'tcc-board' to view

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 TCC Commands Available:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  tcc-status    - Display framework and project status
  tcc-board     - View current project BOARD.md
  tcc-rules     - Display General AI Rules
  tcc-startup   - Display Startup Protocol
  tcc-setup     - Configure TCC for current project
  tcc-sync      - Sync framework with latest updates
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ TCC Initialization Complete
   Rules confirmed - holistic approach enabled

   Run 'tcc-status' for detailed framework status
   Run 'tcc-startup' to view the startup protocol
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 📦 Available Commands

After initialization, TCC has access to these commands:

### `tcc-status`
Displays comprehensive framework and project status

**Example Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 TCC Framework Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Framework Location: /home/user/AI-Collaboration-Management
Current Project:    /home/user/SimpleCP

✅ AI Framework found

📋 Available Rules:
  ✅ General AI Rules
  ✅ Startup Protocol
  ✅ Rule Improvements

📁 Project Context:
  ✅ .ai directory found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### `tcc-board`
Displays the current project's BOARD.md (task tracking)

**Usage:**
```bash
tcc-board
```

### `tcc-rules`
Displays the complete GENERAL_AI_RULES.md content

**Usage:**
```bash
tcc-rules
```

### `tcc-startup`
Displays the complete STARTUP_PROTOCOL.md content

**Usage:**
```bash
tcc-startup
```

### `tcc-setup`
Reconfigures TCC for the current project directory

**Usage:**
```bash
cd /path/to/new/project
tcc-setup
```

### `tcc-sync`
Syncs the framework repository with latest updates from GitHub

**Usage:**
```bash
tcc-sync
```

---

## 🔧 Troubleshooting

### Issue: "AI Framework not found"

**Cause:** AI-Collaboration-Management repository not cloned

**Solution 1 (Automatic):**
```bash
source /home/user/tcc-init.sh
```
The init script will attempt to clone the repository automatically.

**Solution 2 (Manual):**
```bash
git clone https://github.com/JamesKayten/AI-Collaboration-Management.git /home/user/AI-Collaboration-Management
source /home/user/tcc-init.sh
```

### Issue: "No BOARD.md found"

**Cause:** Not in a project directory with .ai framework

**Solution:**
Navigate to a project directory that uses the AI Collaboration Management framework:
```bash
cd /home/user/SimpleCP
tcc-setup
```

### Issue: Commands not available

**Cause:** Configuration not loaded in current session

**Solution:**
```bash
source ~/.tccrc
```

Or start a new terminal session (configuration auto-loads).

---

## 📝 Framework File Paths Reference

For direct access to framework files:

```bash
# General AI Rules
cat $AI_GENERAL_RULES
# or
cat /home/user/AI-Collaboration-Management/rules/GENERAL_AI_RULES.md

# Startup Protocol
cat $AI_STARTUP_PROTOCOL
# or
cat /home/user/AI-Collaboration-Management/rules/STARTUP_PROTOCOL.md

# Rule Improvements (case studies)
cat $AI_RULE_IMPROVEMENTS
# or
cat /home/user/AI-Collaboration-Management/rules/RULE_IMPROVEMENTS.md

# Project Templates
ls /home/user/AI-Collaboration-Management/templates/

# Current Project Board
cat $PROJECT_AI_DIR/BOARD.md
# or
cat /home/user/SimpleCP/.ai/BOARD.md
```

---

## 🎯 Integration with Startup Protocol

The TCC initialization system integrates with the mandatory 5-step startup protocol:

### Step 1: Rules Acknowledgment
```bash
source /home/user/tcc-init.sh
tcc-rules
```
Confirm: "Rules confirmed - holistic approach enabled"

### Step 2: Project Context Discovery
```bash
tcc-status
tcc-board
```

### Step 3: Repository Sync Verification
```bash
cd $CURRENT_PROJECT_DIR
git status
```

### Step 4: Process Environment Check
```bash
ps aux | grep -E 'node|python|ruby'
netstat -tulpn 2>/dev/null | grep LISTEN
```

### Step 5: Project-Specific Rules Integration
```bash
# Check for PROJECT_RULES.md in current project
ls -la $CURRENT_PROJECT_DIR/PROJECT_RULES.md 2>/dev/null
```

---

## 💡 Best Practices for TCC

1. **Always run initialization first:**
   ```bash
   source /home/user/tcc-init.sh
   ```

2. **Check status before starting work:**
   ```bash
   tcc-status
   ```

3. **Review the board for current tasks:**
   ```bash
   tcc-board
   ```

4. **Keep framework updated:**
   ```bash
   tcc-sync
   ```

5. **When changing projects:**
   ```bash
   cd /path/to/new/project
   tcc-setup
   ```

---

## 📊 Session Checklist for TCC

**At Session Start:**
- [ ] Run `source /home/user/tcc-init.sh`
- [ ] Verify framework access with `tcc-status`
- [ ] Review rules with `tcc-rules`
- [ ] Check project tasks with `tcc-board`
- [ ] Confirm git status

**During Session:**
- [ ] Use `tcc-setup` when changing projects
- [ ] Reference rules when needed with `tcc-rules`
- [ ] Check protocol compliance with `tcc-startup`

**Session End:**
- [ ] Update BOARD.md with task status
- [ ] Sync framework if needed with `tcc-sync`

---

## 🔗 Related Resources

- **Framework Repository:** https://github.com/JamesKayten/AI-Collaboration-Management
- **Configuration File:** `/home/user/.tccrc`
- **Initialization Script:** `/home/user/tcc-init.sh`
- **Shell Config:** `/home/user/.bashrc`

---

## 🆘 Quick Reference Card

```
╔════════════════════════════════════════════════════════════╗
║              TCC QUICK REFERENCE                           ║
╠════════════════════════════════════════════════════════════╣
║ FIRST COMMAND:  source /home/user/tcc-init.sh             ║
╠════════════════════════════════════════════════════════════╣
║ tcc-status   → Framework & project status                 ║
║ tcc-board    → View current tasks                         ║
║ tcc-rules    → Display AI rules                           ║
║ tcc-startup  → Display startup protocol                   ║
║ tcc-setup    → Configure for current project              ║
║ tcc-sync     → Update framework                           ║
╠════════════════════════════════════════════════════════════╣
║ Framework:  /home/user/AI-Collaboration-Management        ║
║ Config:     /home/user/.tccrc                             ║
║ Init:       /home/user/tcc-init.sh                        ║
╚════════════════════════════════════════════════════════════╝
```

---

**Last Updated:** 2025-11-22
**Version:** 1.0
**Maintained by:** JamesKayten (Pilate) & Claude
