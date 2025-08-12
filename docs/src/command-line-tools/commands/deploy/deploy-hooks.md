# deploy hooks (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Manage deployment hooks for custom actions during the deployment lifecycle.

## Synopsis

```bash
wheels deploy hooks <action> [hook-name] [options]
```

## Description

The `wheels deploy hooks` command allows you to manage custom hooks that execute at specific points during the deployment process. These hooks enable you to run custom scripts, notifications, or integrations at key deployment stages.

## Actions

- `list` - List all configured deployment hooks
- `add` - Add a new deployment hook
- `remove` - Remove an existing hook
- `enable` - Enable a disabled hook
- `disable` - Disable a hook without removing it
- `test` - Test a hook execution
- `show` - Show details about a specific hook

## Options

- `--stage` - Deployment stage (pre-deploy, post-deploy, rollback, error)
- `--script` - Path to hook script or command
- `--timeout` - Hook execution timeout in seconds (default: 300)
- `--retry` - Number of retry attempts on failure (default: 0)
- `--async` - Run hook asynchronously
- `--environment, -e` - Target environment (default: all)
- `--priority` - Hook execution priority (1-100, lower runs first)

## Hook Stages

### pre-deploy
Executed before deployment starts:
- Backup creation
- Service notifications
- Resource validation
- Custom checks

### post-deploy
Executed after successful deployment:
- Cache warming
- Health checks
- Monitoring updates
- Success notifications

### rollback
Executed during rollback operations:
- Cleanup tasks
- State restoration
- Failure notifications
- Recovery actions

### error
Executed when deployment fails:
- Error logging
- Alert notifications
- Cleanup operations
- Incident creation

## Examples

### List all hooks
```bash
wheels deploy hooks list
```

### Add a pre-deploy hook
```bash
wheels deploy hooks add backup-database \
  --stage pre-deploy \
  --script ./scripts/backup-db.sh \
  --timeout 600
```

### Add notification hook
```bash
wheels deploy hooks add slack-notify \
  --stage post-deploy \
  --script "curl -X POST https://hooks.slack.com/services/..." \
  --async
```

### Test a hook
```bash
wheels deploy hooks test backup-database
```

### Disable a hook temporarily
```bash
wheels deploy hooks disable backup-database
```

### Show hook details
```bash
wheels deploy hooks show slack-notify
```

## Hook Script Requirements

Hook scripts should:
- Return exit code 0 for success
- Return non-zero exit code for failure
- Output status messages to stdout
- Output errors to stderr
- Handle timeouts gracefully

### Example hook script
```bash
#!/bin/bash
# pre-deploy-backup.sh

echo "Starting database backup..."
pg_dump myapp > backup-$(date +%Y%m%d-%H%M%S).sql

if [ $? -eq 0 ]; then
    echo "Backup completed successfully"
    exit 0
else
    echo "Backup failed" >&2
    exit 1
fi
```

## Environment Variables

Hooks receive these environment variables:
- `DEPLOY_STAGE` - Current deployment stage
- `DEPLOY_ENVIRONMENT` - Target environment
- `DEPLOY_VERSION` - Version being deployed
- `DEPLOY_USER` - User initiating deployment
- `DEPLOY_TIMESTAMP` - Deployment start time

## Use Cases

### Database backup hook
```bash
wheels deploy hooks add db-backup \
  --stage pre-deploy \
  --script ./hooks/backup-database.sh \
  --timeout 1800
```

### Notification hooks
```bash
# Slack notification
wheels deploy hooks add notify-slack \
  --stage post-deploy \
  --script ./hooks/notify-slack.sh \
  --async

# Email notification
wheels deploy hooks add notify-email \
  --stage error \
  --script ./hooks/send-error-email.sh
```

### Health check hook
```bash
wheels deploy hooks add health-check \
  --stage post-deploy \
  --script ./hooks/verify-health.sh \
  --retry 3
```

## Best Practices

1. **Keep hooks simple**: Each hook should do one thing well
2. **Handle failures**: Always include error handling in hook scripts
3. **Set timeouts**: Prevent hooks from blocking deployments
4. **Test thoroughly**: Test hooks in staging before production
5. **Log output**: Ensure hooks provide clear logging
6. **Use priorities**: Order hooks appropriately with priorities
7. **Document hooks**: Maintain documentation for all hooks

## See Also

- [deploy exec](deploy-exec.md) - Execute deployment
- [deploy rollback](deploy-rollback.md) - Rollback deployment
- [deploy logs](deploy-logs.md) - View deployment logs