# User Guide: Installing TCC Configuration on Your Local Machine

## 🎯 What This Does

This installs a configuration system that gives TCC (Terminal Control Center) automatic access to the AI Collaboration Management framework whenever you start a new terminal session.

**Benefits:**
- ✅ TCC knows where to find all AI collaboration rules
- ✅ "check the board" command works automatically
- ✅ No manual path lookup needed
- ✅ Persistent across terminal sessions
- ✅ Follows mandatory startup protocol

---

## 📋 What to Tell TCC

When you want to install the TCC configuration system on your local machine, tell TCC:

> "Please install the TCC configuration system on my local machine. Follow the instructions in INSTRUCTIONS_FOR_TCC.md"

TCC will then execute the installation process automatically.

---

## 🚀 What TCC Will Do

TCC will run these commands on your local machine:

### 1. Download and run the installation script

```bash
curl -sSL https://raw.githubusercontent.com/JamesKayten/SimpleCP/claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU/install-tcc.sh -o ~/install-tcc.sh
chmod +x ~/install-tcc.sh
~/install-tcc.sh
```

### 2. Reload shell configuration

```bash
source ~/.bashrc
```

### 3. Initialize TCC

```bash
source ~/tcc-init.sh
```

### 4. Verify installation

```bash
tcc-status
```

---

## ✅ What Gets Installed

After installation, you'll have:

### Configuration Files

- `~/.tccrc` - TCC configuration with environment variables and helper functions
- `~/tcc-init.sh` - Initialization script (TCC's first command each session)
- `~/.bashrc` - Updated to auto-load TCC configuration

### Framework Repository

- `~/AI-Collaboration-Management/` - Complete framework with all rules and templates
  - `rules/GENERAL_AI_RULES.md` - Universal AI behavioral standards
  - `rules/STARTUP_PROTOCOL.md` - Mandatory 5-step initialization
  - `rules/RULE_IMPROVEMENTS.md` - Continuous learning from failures

---

## 🎯 For TCC: First Command in Every Session

After installation, TCC should run this as the **first command** whenever you start a new terminal session:

```bash
source ~/tcc-init.sh
```

This gives TCC immediate access to:
- All framework rules and protocols
- Project BOARD.md files
- Environment variables for all paths
- Helper commands

---

## 📱 Available Commands

After installation, TCC can use these commands:

| Command | What It Does |
|---------|--------------|
| `tcc-status` | Display framework and project status |
| `tcc-board` | View current project's BOARD.md |
| `tcc-rules` | Display GENERAL_AI_RULES.md |
| `tcc-startup` | Display STARTUP_PROTOCOL.md |
| `tcc-setup` | Configure TCC for current project |
| `tcc-sync` | Update framework with latest changes |

---

## 🔍 How to Verify It Worked

After TCC completes the installation, you should see:

```
✅ TCC Installation Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Post-Installation Steps:

1. Reload your shell configuration:
   source ~/.bashrc

2. Run TCC initialization:
   source ~/tcc-init.sh

3. Verify installation:
   tcc-status
```

When TCC runs `tcc-status`, you should see:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 TCC Framework Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Framework: /home/user/AI-Collaboration-Management
Current Project: /home/user/[current-directory]

✅ AI Framework found

📋 Available Rules:
  ✅ General AI Rules
  ✅ Startup Protocol
  ✅ Rule Improvements
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🆘 Troubleshooting

### If installation fails:

**Option 1: Try again**
```
Tell TCC: "Try the installation again, and if it fails, use the manual installation method"
```

**Option 2: Manual installation**
```
Tell TCC: "Follow the manual installation method in INSTRUCTIONS_FOR_TCC.md"
```

### If commands don't work after installation:

**Reload configuration:**
```
Tell TCC: "Reload the shell configuration with: source ~/.bashrc"
```

**Reinitialize:**
```
Tell TCC: "Run the initialization script: source ~/tcc-init.sh"
```

---

## 📚 Documentation

Complete documentation is available in:

- **INSTRUCTIONS_FOR_TCC.md** - Detailed installation instructions for TCC
- **TCC_SETUP.md** - Overview of the configuration system
- **~/TCC_INITIALIZATION_GUIDE.md** - Complete guide (installed on your machine)
- **~/TCC_QUICK_START.md** - Quick reference (installed on your machine)

---

## 🎓 Example Session

**You:**
> "TCC, please install the TCC configuration system on my local machine. Follow the instructions in INSTRUCTIONS_FOR_TCC.md"

**TCC:**
```
I'll install the TCC configuration system on your local machine.

Downloading installation script...
Running installation...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 TCC Installation Script
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1: Downloading Configuration Files
✅ .tccrc downloaded
✅ tcc-init.sh downloaded

Step 2: Updating Shell Configuration
✅ .bashrc updated

Step 3: Setting Up AI Collaboration Management Framework
✅ Framework cloned successfully

Step 4: Verifying Installation
✅ .tccrc configuration file
✅ tcc-init.sh initialization script
✅ Shell configuration updated
✅ AI Collaboration Management framework

✅ TCC Installation Complete!

Reloading configuration...
Initializing TCC...
✅ TCC Initialization Complete
   Rules confirmed - holistic approach enabled

Verifying installation...
✅ All systems operational
```

**TCC's Next Steps:**

In every future session, TCC will start with:
```bash
source ~/tcc-init.sh
```

And will have access to all framework rules, project context, and helper commands.

---

## ✅ Summary

**To install:**
Tell TCC: *"Please install the TCC configuration system on my local machine. Follow the instructions in INSTRUCTIONS_FOR_TCC.md"*

**After installation:**
- TCC runs `source ~/tcc-init.sh` as first command in every new session
- TCC has automatic access to all AI Collaboration Management rules
- TCC can use helper commands like `tcc-status`, `tcc-board`, `tcc-rules`
- "Check the board" functionality works automatically

**Result:**
TCC always follows the holistic approach and startup protocol, preventing narrow-focused failures like the SimpleCP folder rename issue.

---

**Repository:** https://github.com/JamesKayten/SimpleCP
**Branch:** claude/hierarchical-rules-system-01YYBzzonDJDWBYvYcoW59GU
**Created:** 2025-11-22
