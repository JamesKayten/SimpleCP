# Claude Code Command Workarounds

## SlashCommand Tool Permission Issue

### Problem
When using the `SlashCommand` tool (e.g., `/check-the-board`), you may encounter:
```
Tool permission request failed: Error: canUseTool callback is not provided.
```

### Root Cause
The SlashCommand tool requires a `canUseTool` callback that isn't properly configured in the current Claude Code SDK setup. This is a framework-level configuration issue, not a repository-level issue.

### Workaround
Instead of using the SlashCommand tool, manually execute the command logic directly:

#### For `/check-the-board`:
```bash
# 1. Read status files
cat BOARD.md
cat TASKS.md

# 2. Check for uncommitted changes
git status

# 3. If there are changes, commit and push
git add .
git commit -m "Update board status"
git push -u origin <branch-name>
```

#### For other commands:
Open the command file in `.claude/commands/<command-name>.md` and follow the instructions manually.

### Status
This is a known issue with the Claude Code SlashCommand tool integration. The workaround is reliable and will work until the framework-level issue is resolved.

---

**Last Updated:** 2025-11-24
