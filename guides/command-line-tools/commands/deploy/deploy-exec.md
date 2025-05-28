# wheels deploy exec

Execute a deployment to the specified target environment.

## Synopsis

```bash
wheels deploy exec [target] [options]
```

## Description

The `wheels deploy exec` command performs the actual deployment of your Wheels application to a configured target environment. It handles file synchronization, runs deployment hooks, and manages the deployment lifecycle.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `target` | Deployment target (production, staging, etc.) | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--tag` | Git tag or commit to deploy | Latest commit |
| `--branch` | Git branch to deploy | Configured branch |
| `--force` | Force deployment even with uncommitted changes | `false` |
| `--skip-hooks` | Skip pre/post deployment hooks | `false` |
| `--skip-tests` | Skip test execution | `false` |
| `--skip-assets` | Skip asset compilation | `false` |
| `--dry-run` | Preview deployment without executing | `false` |
| `--verbose` | Show detailed output | `false` |
| `--timeout` | Deployment timeout in seconds | `300` |
| `--help` | Show help information |

## Examples

### Deploy to production
```bash
wheels deploy exec production
```

### Deploy specific tag
```bash
wheels deploy exec production --tag=v1.2.3
```

### Deploy with dry run
```bash
wheels deploy exec staging --dry-run
```

### Force deployment
```bash
wheels deploy exec production --force
```

### Deploy without hooks
```bash
wheels deploy exec staging --skip-hooks
```

### Verbose deployment
```bash
wheels deploy exec production --verbose
```

## Deployment Process

1. **Pre-flight Checks**:
   - Verify target configuration
   - Check Git status
   - Validate dependencies
   - Test connectivity

2. **Preparation**:
   - Create release directory
   - Export code from repository
   - Install dependencies
   - Compile assets

3. **Synchronization**:
   - Upload files to target
   - Exclude ignored files
   - Preserve shared resources

4. **Activation**:
   - Update symbolic links
   - Run database migrations
   - Clear caches
   - Reload application

5. **Cleanup**:
   - Remove old releases
   - Clean temporary files
   - Update deployment log

## Output Example

```
Deploying to production...
✓ Pre-flight checks passed
✓ Creating release 20240115120000
✓ Exporting code from main branch
✓ Installing dependencies
✓ Compiling assets
✓ Uploading files to prod.example.com
  → Transferred 1,234 files (45.6 MB)
✓ Running pre-deployment hooks
  → npm run build
  → box install --production
✓ Activating release
✓ Running post-deployment hooks
  → wheels dbmigrate latest
  → wheels reload production
✓ Cleaning up old releases
✓ Deployment completed successfully!

Deployment Summary:
- Target: production
- Release: 20240115120000
- Duration: 2m 34s
- Status: SUCCESS
```

## Deployment Strategies

### Rolling Deployment
```bash
wheels deploy exec production
```
- Gradual rollout
- Zero downtime
- Automatic rollback on failure

### Blue-Green Deployment
```bash
wheels deploy exec production --strategy=blue-green
```
- Instant switching
- Full rollback capability
- Requires double resources

### Canary Deployment
```bash
wheels deploy exec production --strategy=canary --percentage=10
```
- Gradual traffic shift
- Risk mitigation
- Performance monitoring

## Hook Execution

### Pre-deployment Hooks
Executed before deployment:
```json
"pre-deploy": [
  "npm test",
  "npm run build",
  "box install --production"
]
```

### Post-deployment Hooks
Executed after activation:
```json
"post-deploy": [
  "wheels dbmigrate latest",
  "wheels reload production",
  "npm run cache:clear",
  "curl -X POST https://api.example.com/deploy-notification"
]
```

## Rollback Handling

If deployment fails:
1. Automatic rollback triggered
2. Previous release restored
3. Rollback hooks executed
4. Notifications sent

Manual rollback:
```bash
wheels deploy rollback production
```

## Environment Variables

Available during deployment:

| Variable | Description |
|----------|-------------|
| `WHEELS_DEPLOY_TARGET` | Target environment name |
| `WHEELS_DEPLOY_RELEASE` | Release timestamp |
| `WHEELS_DEPLOY_BRANCH` | Git branch |
| `WHEELS_DEPLOY_TAG` | Git tag (if specified) |
| `WHEELS_DEPLOY_USER` | User executing deployment |

## Dry Run Mode

Preview deployment without changes:
```bash
wheels deploy exec production --dry-run
```

Shows:
- Files to be transferred
- Hooks to be executed
- Resources to be created
- Estimated deployment time

## Error Handling

Common errors and solutions:

1. **Connection Failed**
   - Check SSH keys/credentials
   - Verify network connectivity
   - Confirm server accessibility

2. **Permission Denied**
   - Check user permissions
   - Verify directory ownership
   - Review deployment path

3. **Hook Failed**
   - Check hook commands
   - Verify dependencies
   - Review error logs

4. **Disk Space**
   - Check available space
   - Clean old releases
   - Review keep-releases setting

## Performance Optimization

- Use `--skip-assets` if assets pre-built
- Enable compression for transfers
- Parallelize hook execution
- Use incremental deployments

## Monitoring

Track deployment metrics:
- Deployment duration
- Transfer size
- Success/failure rate
- Rollback frequency

## Use Cases

1. **Automated Deployment**: CI/CD pipeline integration
2. **Scheduled Releases**: Deploy during maintenance windows
3. **Emergency Hotfix**: Quick production patches
4. **Feature Deployment**: Deploy specific features
5. **A/B Testing**: Deploy variants for testing

## Notes

- Always test in staging first
- Monitor application after deployment
- Keep deployment logs for auditing
- Have rollback plan ready
- Coordinate with team for production deployments

## See Also

- [wheels deploy](deploy.md) - Deployment overview
- [wheels deploy status](deploy-status.md) - Check deployment status
- [wheels deploy rollback](deploy-rollback.md) - Rollback deployment
- [wheels deploy logs](deploy-logs.md) - View deployment logs