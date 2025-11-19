# AI Collaboration Framework - Quick Start Guide

**Get up and running in 5 minutes!**

## Prerequisites

- Git repository (GitHub, GitLab, Bitbucket, etc.)
- Local AI (Claude Code, GitHub Copilot, etc.)
- Online AI access (Claude.ai, ChatGPT, etc.)
- Browser for OCC Launcher

## Step 1: Install Framework (2 minutes)

```bash
# Navigate to your project repository
cd /path/to/your/project

# Run the framework installer
/path/to/ai_collaboration_framework/install.sh
```

**What this does:**
- Creates `docs/ai_communication/` directory
- Installs framework documentation
- Sets up validation rule templates
- Configures communication structure

## Step 2: Set Up OCC Launcher (1 minute)

```bash
# Open the OCC launcher HTML file in your browser
open /path/to/ai_collaboration_framework/occ-launcher.html

# Or on Linux:
xdg-open /path/to/ai_collaboration_framework/occ-launcher.html

# Or on Windows:
start /path/to/ai_collaboration_framework/occ-launcher.html
```

**Bookmark it:**
- Press `Cmd+D` (Mac) or `Ctrl+D` (Windows/Linux)
- Name it "OCC Launcher" or "AI Framework"
- Place in bookmark bar for quick access

## Step 3: Install GitHub Action (Optional, 2 minutes)

```bash
# Create workflows directory if it doesn't exist
mkdir -p .github/workflows

# Copy the TCC notification workflow
cp /path/to/ai_collaboration_framework/workflows/tcc-notification.yml .github/workflows/

# Commit and push
git add .github/workflows/tcc-notification.yml
git commit -m "Add TCC notification workflow for AI framework"
git push
```

**What this does:**
- Monitors communication directories for TCC reports
- Automatically creates GitHub issues when violations detected
- Includes OCC activation prompt in issues
- Provides quick links to reports and Claude.ai

## Step 4: Test the System (5 minutes)

### Test Local AI Validation

```bash
# Activate Local AI (Claude Code) and run:
"work ready"

# This will:
# - Check for communications from Online AI
# - Validate any pending code branches
# - Report status
```

### Test OCC Activation

1. **Click your OCC Launcher bookmark**
2. **Click "Copy OCC Activation Prompt"** (button turns green)
3. **Click "Open Claude.ai"** (opens in new tab)
4. **Paste** (`Cmd+V` / `Ctrl+V`) **and press Enter**
5. **OCC will check framework** and report status

### Test GitHub Workflow (if installed)

1. **Create a test violation** (e.g., overly large file)
2. **Let TCC detect it** and create report
3. **Push the report** to repository
4. **Check GitHub Issues** - automated issue should appear
5. **Click "Open Claude" link** in issue
6. **Use prompt from issue** to activate OCC

## Step 5: Customize for Your Project (5 minutes)

```bash
# Edit validation rules
edit docs/ai_communication/VALIDATION_RULES.md

# Customize for your project type:
# - Set file size limits
# - Define code complexity thresholds
# - Specify test coverage requirements
# - Add security scanning rules
# - Configure performance benchmarks
```

## Daily Workflow

### When Starting Work

```bash
# Local AI: Check for updates and validate
"work ready"
```

### When TCC Detects Violations

**Option A: OCC Launcher (Fastest - 3-5 seconds)**
1. Get GitHub notification (if workflow installed)
2. Click OCC Launcher bookmark
3. Copy prompt → Open Claude → Paste → Done

**Option B: Manual Activation**
```bash
# Tell Online AI:
"Check docs/ai_communication/ for latest report and address the issues"
```

### After OCC Fixes Issues

```bash
# Local AI: Re-validate
"work ready"

# If clean: TCC merges automatically
# If issues remain: Cycle repeats
```

## Troubleshooting

### OCC Launcher Not Working

**Problem:** Copy button doesn't work
**Solution:**
- Ensure browser allows clipboard access
- Try manually copying from "Preview Prompt" section
- Use `Cmd+K` keyboard shortcut

**Problem:** Can't open local HTML file
**Solution:**
- Save `occ-launcher.html` to your computer first
- Open directly in browser (File → Open)
- Some browsers block local file clipboard access - use Firefox or Chrome

### GitHub Action Not Triggering

**Problem:** No issues created when TCC reports violations
**Solution:**
- Verify workflow file is in `.github/workflows/`
- Check file is named `tcc-notification.yml`
- Ensure repository has Actions enabled (Settings → Actions)
- Verify permissions: Settings → Actions → General → Workflow permissions → "Read and write"

**Problem:** Workflow fails with permission error
**Solution:**
- Go to repo Settings → Actions → General
- Under "Workflow permissions", select "Read and write permissions"
- Save and re-run workflow

### Framework Installation Issues

**Problem:** Install script fails
**Solution:**
- Ensure you're in project root directory
- Check write permissions: `ls -la docs/`
- Run with proper permissions if needed

**Problem:** Validation not working
**Solution:**
- Verify `docs/ai_communication/VALIDATION_RULES.md` exists
- Check Local AI has access to repository
- Ensure Local AI knows the "work ready" command

## Advanced Usage

### Multiple Projects

Install the framework in each project:
```bash
cd /path/to/project1
/path/to/ai_collaboration_framework/install.sh

cd /path/to/project2
/path/to/ai_collaboration_framework/install.sh
```

**Use the same OCC Launcher** for all projects! The standard prompt works universally.

### Team Collaboration

Share the OCC Launcher with your team:
1. Host `occ-launcher.html` on internal web server, or
2. Commit it to repository: `git add tools/occ-launcher.html`
3. Team members bookmark their local copy

### Custom Validation Rules

```bash
# Copy example rules
cp examples/ai_communication/VALIDATION_RULES.md docs/ai_communication/

# Edit for your project
edit docs/ai_communication/VALIDATION_RULES.md

# Test with Local AI
"work ready"
```

### CI/CD Integration

The GitHub Action can trigger other workflows:
```yaml
# In tcc-notification.yml, add:
- name: Trigger tests
  run: |
    # Your test command
    npm test
```

## Getting Help

### Documentation

- **Framework Overview**: `docs/AI_COLLABORATION_FRAMEWORK.md`
- **Detailed Workflow**: `docs/AI_WORKFLOW.md`
- **OCC Prompt Details**: `docs/OCC_PROMPT.md`
- **Workflow Setup**: `workflows/README.md`
- **Deployment Guide**: `DEPLOYMENT_GUIDE.md`

### Common Questions

**Q: Do I need both Local and Online AI?**
A: For full collaboration, yes. But you can use just validation (Local AI only) or just fixes (Online AI only).

**Q: Can I use different AI combinations?**
A: Yes! Any Local AI ↔ Any Online AI. The framework is AI-agnostic.

**Q: How much does this cost?**
A: Framework is free. AI costs depend on your usage. With Claude Pro ($20/month), OCC activation is included.

**Q: Can I customize the OCC prompt?**
A: You can, but the standard prompt works for all projects! It tells Claude to check the framework, so it's universal.

**Q: What if I don't use GitHub?**
A: Framework works with any Git provider. GitHub Actions are optional - you can skip them and use OCC Launcher directly.

## Next Steps

1. **Run your first validation**: `"work ready"`
2. **Test OCC activation**: Use the launcher
3. **Customize rules**: Edit `VALIDATION_RULES.md`
4. **Explore examples**: Check `examples/ai_communication/`
5. **Share with team**: Show them the OCC Launcher

---

**🎉 You're ready!** Start using AI-to-AI collaboration in your development workflow.

**Need help?** Check the full [README](README.md) or [Deployment Guide](DEPLOYMENT_GUIDE.md).
