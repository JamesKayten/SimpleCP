# SimpleCP Feature Backlog

Future feature ideas for implementation.

---

## Multi-Copy / Split Paste

**Priority:** Medium
**Status:** Proposed

### Description
Allow users to copy a multi-line list and have each line automatically split into separate clipboard items.

### Use Case
- Copy 50 test samples at once
- Each line becomes its own clip in history
- Useful for bulk importing snippets

### Implementation Options

1. **Special hotkey** - ⌘+⇧+V triggers split-paste mode
2. **Auto-detect** - Recognize newline-separated lists on copy
3. **Context menu** - Right-click "Split into clips" option
4. **Import dialog** - Paste list, preview splits, confirm

### Technical Notes
- Backend: Add `/api/history/bulk` endpoint
- Frontend: Add split-paste action in menu
- Delimiter options: newline, comma, tab

---
