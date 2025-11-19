# OCC Session Start Prompt

## Quick Copy-Paste Prompt for Activating OCC

When you start a new web Claude session (OCC), **paste this immediately**:

```
I am OCC (Online Claude Component) for the AI Collaboration Framework.

ROLE: Heavy coding workhorse that implements fixes from TCC validation reports.

IMMEDIATE AUTO-CHECK PROTOCOL:
1. Check docs/ai_communication/ for AI_REPORT_*.md files
2. Identify the most recent TCC report
3. Check if a matching AI_RESPONSE_*.md already exists
4. Execute decision tree:
   - IF report exists WITHOUT response → Start implementing fixes immediately
   - IF all reports have responses → Report "No pending work"
   - IF no reports exist → Report "No TCC reports found"

COST OPTIMIZATION:
- TCC (local) is lightweight validator - minimal tokens
- I am expensive heavy implementer - activated only when needed
- This maximizes user's subscription value

EXECUTION:
- Begin work immediately if pending report found
- Create comprehensive AI_RESPONSE_*.md when complete
- Commit and push all changes with clear messages
- Never create validation reports (that's TCC's job)

Repository context is loaded. Execute auto-check protocol now.
```

---

## Alternative: Natural Language Version

If you prefer a more conversational activation:

```
Check docs/ai_communication/ for any pending TCC reports and automatically start working on them if you find any unresolved violations. You're OCC - the heavy coding component that implements fixes from TCC's validation reports.
```

---

## How the Automation Works

### Full Flow:

1. **TCC creates report** → `AI_REPORT_2025-11-19.md`
2. **GitHub Action triggers** → Detects new report file
3. **Action creates issue** → "🤖 OCC Activation Required"
4. **You get notified** → GitHub notification
5. **You open web Claude** → With repository context
6. **You paste start prompt** → (From above)
7. **OCC auto-detects** → Reads report, starts work
8. **OCC creates response** → `AI_RESPONSE_2025-11-19.md`
9. **GitHub Action triggers** → Detects response file
10. **Action closes issue** → Adds comment about next steps
11. **You run TCC** → `work ready` to validate and merge

### What Gets Automated:

✅ **Automated:**
- Detection of new TCC reports
- Creation of GitHub issues with instructions
- Closure of issues when OCC completes work
- Commit comments on both report and response
- Issue labels for tracking

❌ **Not Automated (Impossible with Web Claude):**
- Actually starting the web Claude session
- Pasting the prompt into Claude

### Why This Is The Best Possible:

Web Claude (claude.ai) doesn't have:
- Webhook support
- API triggers for sessions
- Integration with Anthropic API

The Anthropic API is separate and would require:
- Different API key setup
- Different code interface
- Additional cost beyond Claude Pro subscription

**This workflow gives you 90% automation** with just one manual step: pasting the start prompt.

---

## Usage Examples

### Example 1: TCC Found Violations

```bash
# TCC detects violations and creates report
TCC: "Created AI_REPORT_2025-11-19.md with 3 violations"

# GitHub Action runs (automatic)
# ✅ Issue created: "🤖 OCC Activation Required - 3 Violations Detected"
# ✅ You receive notification

# You open web Claude and paste:
Paste → OCC session start prompt (from above)

# OCC responds:
OCC: "Found TCC report from 2025-11-19 with 3 violations. Starting work..."
OCC: [Implements all fixes]
OCC: "All violations resolved. Created AI_RESPONSE_2025-11-19.md. Ready for TCC re-validation."

# GitHub Action runs (automatic)
# ✅ Issue closed with completion message

# Run TCC validation
You: "work ready" → TCC
TCC: "OCC completed fixes. Validating... All checks pass ✅ Merging to main."
```

### Example 2: No Pending Work

```bash
# You open web Claude and paste start prompt

# OCC responds:
OCC: "Checked docs/ai_communication/ - all TCC reports have responses. No pending work. What would you like me to work on?"
```

---

## Tips for Maximum Efficiency

1. **Bookmark this file** - Quick access to the prompt
2. **Keep web Claude tab open** - Faster response to notifications
3. **GitHub notifications** - Enable desktop notifications for issues
4. **Template response** - GitHub mobile app supports notifications too

---

## Framework Version
**AI Collaboration Framework v1.1**
**Updated:** 2025-11-19
**Maximum achievable automation for web Claude interface**
