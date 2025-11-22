# TCC Quick Start

## For TCC: First Command in New Terminal Session

When you (TCC) start in a new terminal session, run this **first**:

```bash
source ~/tcc-init.sh
```

This will:
- Load configuration
- Clone/verify the AI Collaboration Management framework
- Set up environment variables
- Display available commands

---

## For User: One-Time Setup

Copy these files to your home directory:

```bash
# Files are located in /home/user/ on the development machine:
# - .tccrc (TCC configuration)
# - tcc-init.sh (initialization script)
# - TCC_INITIALIZATION_GUIDE.md (full documentation)
# - TCC_QUICK_START.md (this file)

# The .bashrc has been modified to auto-load .tccrc
```

**That's it!** TCC will now have framework access on every new session.

---

## Available Commands After Initialization

```bash
tcc-status   # Check framework status
tcc-board    # View project tasks
tcc-rules    # View AI rules
tcc-startup  # View startup protocol
tcc-setup    # Configure for current project
tcc-sync     # Update framework
```

---

## Framework Location

The AI-Collaboration-Management framework will be cloned to:
```
~/AI-Collaboration-Management
```

If you want it in a different location, edit `~/.tccrc` and update `AI_FRAMEWORK_REPO`

---

## Troubleshooting

**Problem:** Commands not found
**Solution:** Run `source ~/tcc-init.sh`

**Problem:** Framework not found
**Solution:** The init script will auto-clone it, or manually:
```bash
git clone https://github.com/JamesKayten/AI-Collaboration-Management.git ~/AI-Collaboration-Management
```

---

## Example First Session

```bash
$ source ~/tcc-init.sh
🤖 Initializing TCC Session
✅ Configuration loaded
✅ Framework repository found
✅ TCC Initialization Complete
   Rules confirmed - holistic approach enabled

$ tcc-status
✅ AI Framework found
✅ General AI Rules
✅ Startup Protocol
✅ Project .ai directory found

$ tcc-board
[Displays current project tasks from BOARD.md]
```

---

**See TCC_INITIALIZATION_GUIDE.md for complete documentation**
