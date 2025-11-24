---
description: Check board status, commit any changes, and push
aliases: ["Check the Board", "check the board", "check board", "board check", "status"]
---

**TCC's board check workflow:**

1. **Read status**
```bash
cat BOARD.md
cat TASKS.md
```

2. **Check for uncommitted changes**
```bash
git status
```

3. **If there are changes: COMMIT AND PUSH**
```bash
git add .
git commit -m "Update board status"
git push
```

**Always commit and push if there are changes. No exceptions.**

Report:
- Board status summary
- "✅ Changes committed and pushed" (if changes existed)
- "✅ Board is current" (if no changes)

**Don't just look - commit what you see.**
