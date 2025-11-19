# GitHub Actions Setup Guide

## 📋 Prerequisites

The GitHub Actions workflows are already created in `.github/workflows/`. They will activate automatically once pushed to GitHub.

## ✅ What's Already Configured

### Workflow 1: TCC Report Detector
**File:** `.github/workflows/tcc-report-detector.yml`

**Triggers when:**
- Any `AI_REPORT_*.md` file is pushed to `docs/ai_communication/`
- On any branch

**Actions:**
1. Detects the new report
2. Extracts report date and violation count
3. Checks if response already exists
4. Creates GitHub issue with OCC activation instructions
5. Adds comment to the commit

**Required Permissions:**
- ✅ Read repository contents
- ✅ Create issues
- ✅ Add commit comments
- ✅ Already configured in workflow

### Workflow 2: OCC Response Validator
**File:** `.github/workflows/occ-response-validator.yml`

**Triggers when:**
- Any `AI_RESPONSE_*.md` file is pushed to `docs/ai_communication/`
- On any branch

**Actions:**
1. Detects the new response
2. Finds matching OCC activation issue
3. Closes the issue with completion comment
4. Adds commit comment confirming response received

**Required Permissions:**
- ✅ Read repository contents
- ✅ Update issues
- ✅ Add commit comments
- ✅ Already configured in workflow

## 🚀 Activation Steps

### Step 1: Verify Workflow Files Exist

```bash
ls -la .github/workflows/
# Should show:
# - tcc-report-detector.yml
# - occ-response-validator.yml
```

### Step 2: Commit and Push

```bash
git add .github/workflows/
git commit -m "Add GitHub Actions for TCC/OCC automation"
git push
```

### Step 3: Enable Actions (If Not Already Enabled)

1. Go to your GitHub repository
2. Click "Actions" tab
3. If prompted, click "I understand my workflows, go ahead and enable them"

### Step 4: Verify Workflows Are Active

1. Go to **Settings** → **Actions** → **General**
2. Ensure these settings:
   - ✅ "Allow all actions and reusable workflows" is selected
   - ✅ "Read and write permissions" for GITHUB_TOKEN
   - ✅ "Allow GitHub Actions to create and approve pull requests" (optional)

### Step 5: Set GITHUB_TOKEN Permissions

The workflows use `github-script@v7` which needs:
- ✅ **Issues:** Read and write
- ✅ **Contents:** Read
- ✅ **Metadata:** Read

**To verify/set:**
1. Go to **Settings** → **Actions** → **General**
2. Under "Workflow permissions":
   - Select **"Read and write permissions"**
   - Check **"Allow GitHub Actions to create and approve pull requests"**
3. Click **Save**

## 🧪 Testing The Workflows

### Test 1: TCC Report Detection

```bash
# Create a test report
cat > docs/ai_communication/AI_REPORT_2025-11-20.md << 'EOF'
# Test Validation Report
**Date:** 2025-11-20
**Reporter:** TCC
**Status:** 🚨 TEST

## Summary
Test report for workflow validation.

## Violations Found
### 🔴 CRITICAL - Test Violation
- **File:** test.py
- **Issue:** Test issue
EOF

# Commit and push
git add docs/ai_communication/AI_REPORT_2025-11-20.md
git commit -m "Test: TCC report detection workflow"
git push

# Check GitHub:
# 1. Go to "Actions" tab - workflow should run
# 2. Go to "Issues" - new issue should be created
# 3. Check commit comments
```

### Test 2: OCC Response Detection

```bash
# Create a test response
cat > docs/ai_communication/AI_RESPONSE_2025-11-20.md << 'EOF'
# Response to Test Report
**Date:** 2025-11-20
**Reporter:** OCC
**Status:** ✅ COMPLETE

## Fixes Completed
Test response for workflow validation.
EOF

# Commit and push
git add docs/ai_communication/AI_RESPONSE_2025-11-20.md
git commit -m "Test: OCC response detection workflow"
git push

# Check GitHub:
# 1. Go to "Actions" tab - workflow should run
# 2. Previous issue should be closed
# 3. Check commit comments
```

## 📊 Monitoring Workflows

### View Workflow Runs
1. Go to **Actions** tab
2. See list of all workflow runs
3. Click any run to see detailed logs

### Debugging Failed Workflows
1. Click the failed workflow run
2. Click the failing job
3. Expand the failing step
4. Read error messages
5. Common issues:
   - Missing permissions (see Step 5 above)
   - File path mismatches
   - Branch restrictions

## 🔧 Customization Options

### Change Detection Paths

Edit `.github/workflows/tcc-report-detector.yml`:

```yaml
on:
  push:
    paths:
      - 'docs/ai_communication/AI_REPORT_*.md'  # Change this path
```

### Add Slack/Email Notifications

Add to workflow file after issue creation:

```yaml
- name: Send Slack notification
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "🤖 TCC Report: ${{ steps.detect.outputs.violation_count }} violations detected"
      }
```

### Add More Labels

Edit the `labels` array in workflow:

```yaml
labels: ['occ-activation', `report-${reportDate}`, 'automated', 'urgent']
```

## 🛡️ Security Considerations

### GITHUB_TOKEN
- ✅ Automatically provided by GitHub
- ✅ Scoped to repository only
- ✅ Expires after workflow completes
- ✅ No manual token management needed

### Repository Permissions
- Workflows only run on your repository
- Cannot access other repositories
- Only maintainers can edit workflows

### Branch Protection
If you have branch protection enabled:
- Workflows can still create issues
- Workflows cannot push to protected branches
- Consider exempting bot commits if needed

## 📈 Advanced Features

### Add to Other Repositories

1. Copy `.github/workflows/` folder
2. Copy `docs/ai_communication/` structure
3. Copy `docs/AI_WORKFLOW.md` and customize
4. Push to new repository
5. Enable Actions

### Multi-Repository Setup

Create a "dispatch" workflow that:
1. Monitors multiple repositories
2. Aggregates TCC reports
3. Creates central OCC activation dashboard

## ❓ Troubleshooting

### Issue: Workflows Not Running
**Solution:**
- Check Actions are enabled: Settings → Actions → General
- Verify workflow syntax: Use GitHub's workflow validator
- Check file paths match exactly

### Issue: No Issues Created
**Solution:**
- Verify "Read and write permissions" in Settings → Actions
- Check workflow logs for errors
- Ensure GITHUB_TOKEN has issue permissions

### Issue: Rate Limiting
**Solution:**
- GitHub Actions have generous rate limits
- If exceeded, workflows will fail with clear error
- Wait or upgrade to GitHub Enterprise

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [github-script Action](https://github.com/actions/github-script)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

---

**Framework Version:** AI Collaboration Framework v1.1
**Updated:** 2025-11-19
**Status:** Production Ready
