# Frontend Testing Rules - Process Management Protocol

**Last Updated:** 2025-11-24 (v2.0 - Streamlined)
**Problem Solved:** Testing old builds while thinking you're testing new code
**Applies To:** TCC frontend testing

---

## 🚨 MANDATORY PROTOCOL (Execute Before Every Test)

### Step 1: Kill All Processes
```bash
pkill -f [AppName]
ps aux | grep [AppName] | grep -v grep
# MUST return empty before proceeding
```

### Step 2: Wait for Shutdown
```bash
sleep 2  # Allow cleanup
```

### Step 3: Verify Clean State
```bash
ps aux | grep -i [appname]
# MUST show only grep process, nothing else
```

### Step 4: Build (if needed)
```bash
[build command]  # swift build, npm build, etc.
stat .build/release/[AppName]  # Check timestamp
```

### Step 5: Launch Fresh Build
```bash
[launch command]  # open .build/release/[AppName], npm start, etc.
sleep 3
ps aux | grep [AppName] | grep -v grep
# Note new PID
```

---

## 🚫 VIOLATIONS = IMMEDIATE RESTART

**Violations:**
- Testing without killing processes
- Launching while old process runs
- Claiming "fixes don't work" without process verification

**Action:** STOP. Kill all. Restart from Step 1.

---

## 📋 APPLICATION-SPECIFIC COMMANDS

### SimpleCP (macOS Swift)
```bash
pkill -f SimpleCP && sleep 2
ps aux | grep -i simplecp | grep -v grep  # Empty?
swift build -c release
open ./.build/release/SimpleCP
```

### Web Apps (Node/React)
```bash
pkill -f node && sleep 2
lsof -ti:3000 | xargs kill -9  # Clear port
rm -rf node_modules/.cache     # Optional: clear cache
npm start
```

### Browser-Based Testing
```bash
pkill -f "Chrome.*localhost"   # Kill browser tabs
[restart server]
[open fresh browser]
```

---

## ✅ TESTING CHECKLIST

Before claiming "fix doesn't work":

- [ ] Killed all existing processes
- [ ] Verified clean state (ps aux check)
- [ ] Built new version
- [ ] Checked build timestamp
- [ ] Launched fresh build
- [ ] Verified new PID
- [ ] Tested actual new version

**If any box unchecked: You're testing the wrong version.**

---

## 🚨 EMERGENCY: Multiple Versions Running

```bash
ps aux | grep [AppName]      # Find all
pkill -f [AppName]           # Kill all
sleep 5                      # Wait
ps aux | grep [AppName]      # Verify empty
[launch command]             # Start fresh
```

---

**Enforcement:** This protocol is MANDATORY for all frontend testing. Violations require testing restart.