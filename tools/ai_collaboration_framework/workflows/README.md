# GitHub Action Workflow Templates

This directory contains GitHub Action workflows for automating the AI Collaboration Framework.

## Available Workflows

### 1. TCC Notification Workflow
**File:** `tcc-notification.yml`

Automatically creates GitHub issues when TCC (Technical Control Claude) detects violations.

#### Features:
- Monitors `docs/ai_communication/` and `docs/occ_communication/` for new reports
- Creates labeled issues with OCC activation instructions
- Includes both OCC Launcher and manual activation options
- Links directly to Claude.ai for quick activation
- Adds commit comments for visibility

#### Installation:

```bash
# Copy to your repository's workflows directory
cp tools/ai_collaboration_framework/workflows/tcc-notification.yml .github/workflows/

# Commit and push
git add .github/workflows/tcc-notification.yml
git commit -m "Add TCC notification workflow"
git push
```

#### Triggers:
- Push to any `claude/**` branch
- Changes to `docs/ai_communication/**` or `docs/occ_communication/**`
- Manual trigger via GitHub Actions UI

#### Required Permissions:
The workflow needs the following permissions (automatically granted by default):
- `issues: write` - To create notification issues
- `contents: read` - To read TCC reports
- `pull-requests: write` - To comment on commits

#### Configuration:
Edit the workflow file to customize:
- Branch patterns that trigger the workflow
- Paths to monitor for TCC reports
- Issue labels
- Issue title format
- Report summary length

## Usage

### Automatic Mode
Once installed, the workflow runs automatically when:
1. TCC creates a violation report in `docs/ai_communication/` or `docs/occ_communication/`
2. Changes are pushed to a `claude/` branch

### Manual Trigger
You can also manually trigger the workflow:
1. Go to Actions tab in GitHub
2. Select "TCC Violation Notification" workflow
3. Click "Run workflow"
4. Select branch and click "Run workflow"

## Integration with OCC Launcher

This workflow works seamlessly with the OCC Launcher:

1. **TCC detects violations** → Pushes report to repository
2. **GitHub Action triggers** → Creates issue with OCC prompt
3. **You receive notification** → GitHub email/notification
4. **Open OCC Launcher** → Local HTML file (bookmark)
5. **Click 2 buttons** → Copy prompt + Open Claude
6. **Paste and go** → OCC reads report and fixes issues

**Total time: 3-5 seconds from notification to OCC activation**

## Customization

### Adding Custom Checks
You can extend the workflow to perform additional checks:

```yaml
- name: Custom validation
  run: |
    # Your custom validation logic here
    ./scripts/custom-check.sh
```

### Integrating with Other Tools
Connect to Slack, Discord, email, etc:

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "TCC violation detected! Check GitHub issues."
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### Changing Issue Format
Modify the `issueBody` in the workflow to customize the issue content.

## Troubleshooting

### Workflow not triggering
- Check that the workflow file is in `.github/workflows/`
- Verify branch name matches the trigger pattern (`claude/**`)
- Ensure changes are in monitored paths

### Permission errors
- Check repository Settings → Actions → General → Workflow permissions
- Ensure "Read and write permissions" is enabled

### Issues not created
- Verify the `actions/github-script@v7` action has access
- Check Actions logs for error messages
- Ensure TCC reports exist in expected locations

## Best Practices

1. **Keep workflow updated**: Regularly sync with the latest template
2. **Test with manual trigger**: Verify workflow works before relying on automatic triggers
3. **Monitor Actions tab**: Check for failed runs
4. **Close resolved issues**: Keep issue tracker clean
5. **Use labels**: Filter issues with `tcc-report` label

## Support

For issues or questions about these workflows:
1. Check the main [Framework Documentation](../docs/AI_COLLABORATION_FRAMEWORK.md)
2. Review [example communication files](../examples/)
3. See [Deployment Guide](../DEPLOYMENT_GUIDE.md)

---

**Framework Version:** 1.0
**Last Updated:** 2025-11-19
