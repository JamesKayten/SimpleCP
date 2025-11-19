# API Mode Setup Guide

**Upgrade from Manual to Automated OCC Activation**

This guide shows you how to enable fully automated OCC activation using the Anthropic API. With API mode, Claude automatically fixes violations with zero human interaction.

## Overview

### Manual Mode (Default - FREE)
- GitHub creates issues when TCC detects violations
- You click OCC Launcher bookmark (3 clicks)
- Uses your Claude Pro subscription ($20/month)
- **Cost:** $0 additional
- **Time:** 3-5 seconds

### API Mode (Automated - PAID)
- GitHub automatically sends prompt to Claude via API
- Claude responds and commits fixes automatically
- No human interaction required
- **Cost:** ~$3-15 per activation
- **Time:** Instant (zero clicks)

## When to Use API Mode

**Consider API mode if:**
- ✅ You're activating OCC 10+ times per day
- ✅ Budget allows $50-150/month for automation
- ✅ You want true CI/CD integration
- ✅ Team needs hands-off operation
- ✅ Time savings worth the cost

**Stick with manual mode if:**
- ✅ Budget is tight (manual is completely free)
- ✅ OCC activations are infrequent (< 5/day)
- ✅ 5 seconds per activation is acceptable
- ✅ You prefer review before fixes

## Step 1: Get Anthropic API Key

### Create Account
1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Sign up or log in (can use same account as Claude Pro)
3. Navigate to **API Keys** section

### Generate API Key
1. Click "Create Key"
2. Name it (e.g., "OCC Automation - MyProject")
3. Copy the key (starts with `sk-ant-api03-...`)
4. **Store securely** - you can't view it again!

### Add Credits
API usage is pay-as-you-go:
1. Go to **Billing** in console
2. Add payment method
3. Set up billing (no minimum, just pay for what you use)
4. Recommended: Set budget alerts (e.g., $50/month)

## Step 2: Add API Key to GitHub

### Repository Secrets
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `ANTHROPIC_API_KEY`
5. Value: Paste your API key
6. Click **Add secret**

### Verify Permissions
1. Settings → Actions → General
2. Under "Workflow permissions":
   - Select **"Read and write permissions"**
   - Check **"Allow GitHub Actions to create and approve pull requests"**
3. Click **Save**

## Step 3: Enable API Mode

### Edit Configuration
1. Open `tools/ai_collaboration_framework/config.yml`
2. Find the `activation_mode` setting (near top)
3. Change from:
   ```yaml
   activation_mode: "manual"
   ```
   To:
   ```yaml
   activation_mode: "api"
   ```
4. Save the file

### Customize Settings (Optional)
While you're in `config.yml`, you can also configure:

```yaml
api:
  model: "claude-sonnet-4-5-20250929"  # Recommended
  max_tokens: 16000  # Typical for most fixes
  temperature: 0.0  # Deterministic (best for code)

occ:
  auto_push: true  # Automatically push fixes
  create_pr_after_fix: false  # Or true for PRs

cost_controls:
  max_activations_per_day: 10  # Safety limit
  daily_cost_alert_threshold: 50  # Alert if exceeds $50/day
```

### Commit Changes
```bash
git add tools/ai_collaboration_framework/config.yml
git commit -m "Enable API mode for automated OCC activation"
git push
```

## Step 4: Test API Mode

### Trigger a Test
1. **Create a test violation** (or wait for TCC to find one)
2. **Push the violation** to a `claude/` branch
3. **Watch GitHub Actions** (Actions tab in GitHub)
4. **Check the results:**
   - Actions log shows "🤖 Automated mode: Activating OCC via API..."
   - New commit appears with OCC's fixes
   - GitHub issue created with success status (if enabled)

### Verify Success
After a successful activation:
- ✅ Check Actions logs for "✅ OCC activated successfully"
- ✅ Look for new commits with `[OCC]` prefix
- ✅ Find OCC response in `docs/ai_communication/`
- ✅ GitHub issue shows "✅ Successfully Activated" (if enabled)

### Troubleshooting

**Problem:** "ANTHROPIC_API_KEY secret not set"
- **Solution:** Re-check Step 2, ensure secret is named exactly `ANTHROPIC_API_KEY`

**Problem:** "activation_mode is set to 'manual', not 'api'"
- **Solution:** Re-check Step 3, ensure you changed and pushed config.yml

**Problem:** API call fails with 401/403 error
- **Solution:** API key invalid or expired, generate new key in console.anthropic.com

**Problem:** Workflow fails with permission error
- **Solution:** Check Step 2 "Verify Permissions", enable read/write

## Cost Estimation

### Pricing Breakdown
Anthropic API pricing (as of 2025):
- **Input tokens:** ~$3 per 1M tokens
- **Output tokens:** ~$15 per 1M tokens

### Typical OCC Activation
- **Input:** 2,000-5,000 tokens (TCC report + prompt + context)
- **Output:** 2,000-8,000 tokens (OCC's analysis + fixes)
- **Total cost:** $3-15 per activation

### Monthly Estimates

| Activations/Day | Monthly Cost | Use Case |
|----------------|--------------|----------|
| 1-2 | $90-300 | Small team, occasional fixes |
| 5-10 | $450-1500 | Active development |
| 20+ | $1800+ | Enterprise / High volume |

**Compare to manual:**
- Manual mode: $0 additional (uses Claude Pro)
- 5 seconds per activation
- 10 activations/day = ~50 seconds total time

## Cost Controls

### Set Budget Limits
In `config.yml`:
```yaml
cost_controls:
  max_activations_per_day: 10  # Hard limit (prevents runaways)
  daily_cost_alert_threshold: 50  # Email alert at $50/day
```

### Monitor Usage
1. Check [console.anthropic.com/usage](https://console.anthropic.com/usage)
2. View daily/monthly spending
3. Set up billing alerts
4. Review activation logs in GitHub Actions

### Optimize Costs
- **Use Sonnet 4.5:** Best balance of cost/quality (not Opus)
- **Set max_tokens wisely:** Don't over-allocate (16000 is usually enough)
- **Enable audit issues sparingly:** Set `github.create_issues: false` to reduce overhead
- **Monitor and adjust:** Track actual costs, adjust limits accordingly

## Switching Back to Manual Mode

If you want to revert to manual mode:

1. Edit `tools/ai_collaboration_framework/config.yml`
2. Change:
   ```yaml
   activation_mode: "api"
   ```
   Back to:
   ```yaml
   activation_mode: "manual"
   ```
3. Commit and push:
   ```bash
   git add tools/ai_collaboration_framework/config.yml
   git commit -m "Revert to manual OCC activation mode"
   git push
   ```

Your OCC Launcher will work immediately again!

## Advanced Configuration

### Hybrid Mode
You can keep API mode enabled but also create issues:
```yaml
activation_mode: "api"
github:
  create_issues: true  # Create audit trail issues
```

This gives you:
- ✅ Automated fixes (API)
- ✅ Audit trail (GitHub issues)
- ⚠️ Slightly higher cost (issue creation uses API calls)

### Custom Notifications
Integrate with Slack/Discord/Email:
```yaml
notifications:
  slack:
    enabled: true
    webhook_url_secret: "SLACK_WEBHOOK_URL"
```

Add webhook URL to GitHub Secrets, get notified when OCC runs!

### Custom OCC Prompt
Override the standard prompt (advanced users only):
```yaml
advanced:
  custom_occ_prompt: "Your custom prompt here"
```

**Note:** The standard prompt works universally - only customize if you have specific needs.

## Best Practices

### Start Small
1. **Try manual mode first** (free, learn the system)
2. **Monitor activation frequency** (how often do you use OCC?)
3. **Calculate ROI** (is automation worth the cost?)
4. **Enable API mode** when ready

### Security
- 🔒 Never commit API keys to repository
- 🔒 Always use GitHub Secrets
- 🔒 Rotate keys periodically
- 🔒 Set spending limits in Anthropic console
- 🔒 Monitor usage logs for anomalies

### Monitoring
- 📊 Check GitHub Actions logs regularly
- 📊 Review Anthropic console usage dashboard
- 📊 Watch for failed activations
- 📊 Track cost trends over time

### Team Coordination
- 👥 Document which mode you're using
- 👥 Share cost expectations with team
- 👥 Set up budget alerts
- 👥 Review monthly spend together

## FAQ

**Q: Can I use both manual and API mode?**
A: No, pick one. But you can switch anytime by editing config.yml.

**Q: What if API fails? Can I fall back to manual?**
A: Yes! If API fails, GitHub issue includes manual fallback instructions.

**Q: Is my Claude Pro subscription used for API mode?**
A: No, API mode uses separate API billing. Pro is only for manual mode.

**Q: Can I test API mode without committing?**
A: Yes! Run the script locally:
```bash
export ANTHROPIC_API_KEY=your-key-here
./tools/ai_collaboration_framework/scripts/activate-occ-api.sh
```

**Q: What happens if I hit my daily activation limit?**
A: Workflow stops activating OCC, creates manual issues instead.

**Q: Can I use API mode for some repos, manual for others?**
A: Yes! Each repo has its own config.yml, configure independently.

**Q: Does API mode work with private repositories?**
A: Yes, no difference between public/private repos.

## Support

### Getting Help
- **Framework docs:** `README.md` in framework directory
- **Anthropic docs:** [docs.anthropic.com](https://docs.anthropic.com)
- **API status:** [status.anthropic.com](https://status.anthropic.com)

### Common Issues
- Check GitHub Actions logs for detailed error messages
- Verify API key is valid in Anthropic console
- Ensure config.yml syntax is correct (YAML is whitespace-sensitive)
- Confirm GitHub permissions are set correctly

---

**Ready to automate?** Follow Steps 1-4 above and enjoy zero-click OCC activation!

**Prefer free?** Stick with manual mode - it works great and costs nothing!
