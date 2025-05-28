# wheels deploy rollback

Rollback a deployment to a previous release.

## Synopsis

```bash
wheels deploy rollback [target] [options]
```

## Description

The `wheels deploy rollback` command reverts your application to a previous deployment release. It provides quick recovery from failed deployments or problematic releases by switching back to a known-good state.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `target` | Deployment target to rollback | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--release` | Specific release to rollback to | Previous release |
| `--steps` | Number of releases to rollback | `1` |
| `--skip-hooks` | Skip rollback hooks | `false` |
| `--force` | Force rollback without confirmation | `false` |
| `--dry-run` | Preview rollback without executing | `false` |
| `--verbose` | Show detailed output | `false` |
| `--help` | Show help information |

## Examples

### Rollback to previous release
```bash
wheels deploy rollback production
```

### Rollback multiple releases
```bash
wheels deploy rollback production --steps=2
```

### Rollback to specific release
```bash
wheels deploy rollback production --release=20240114093045
```

### Preview rollback
```bash
wheels deploy rollback production --dry-run
```

### Force rollback without confirmation
```bash
wheels deploy rollback production --force
```

## Rollback Process

1. **Validation**:
   - Verify target configuration
   - Check available releases
   - Validate rollback target

2. **Confirmation**:
   - Display current release
   - Show target release
   - Request confirmation (unless --force)

3. **Execution**:
   - Switch symbolic links
   - Run rollback hooks
   - Restore shared resources
   - Clear caches

4. **Verification**:
   - Test application health
   - Verify services running
   - Check error logs

## Output Example

```
Rolling back production deployment...

Current Release: 20240115120000
Target Release:  20240114093045

Changes to be reverted:
- 45 files modified
- 3 database migrations
- 2 configuration changes

? Proceed with rollback? (y/N) y

✓ Switching to release 20240114093045
✓ Running rollback hooks
  → Reverting database migrations
  → Clearing application cache
  → Restarting services
✓ Verifying application health
✓ Rollback completed successfully!

Rollback Summary:
- From: 20240115120000
- To:   20240114093045
- Duration: 45s
- Status: SUCCESS
```

## Available Releases

List available releases:
```bash
wheels deploy status production --releases
```

Output:
```
Available releases for production:
1. 20240115120000 (current)
2. 20240114093045
3. 20240113154522
4. 20240112101133
5. 20240111163421
```

## Rollback Hooks

Configure rollback-specific hooks:

```json
{
  "hooks": {
    "rollback": [
      "wheels dbmigrate down --steps=1",
      "wheels reload production",
      "npm run cache:clear",
      "curl -X POST https://api.example.com/rollback-notification"
    ]
  }
}
```

## Database Rollback

Handling database changes during rollback:

1. **Automatic Migration Rollback**:
   ```bash
   wheels dbmigrate down --to=20240114093045
   ```

2. **Manual Intervention**:
   - Some changes may require manual rollback
   - Data migrations might not be reversible
   - Always backup before deployment

## Rollback Strategies

### Immediate Rollback
Quick switch to previous release:
```bash
wheels deploy rollback production
```

### Staged Rollback
Gradual rollback with canary:
```bash
wheels deploy rollback production --strategy=canary --percentage=10
```

### Blue-Green Rollback
Instant switch between environments:
```bash
wheels deploy rollback production --strategy=blue-green
```

## Emergency Rollback

For critical situations:

```bash
# Skip all checks and hooks
wheels deploy rollback production --force --skip-hooks

# Direct symbolic link switch (last resort)
ssh deploy@prod.example.com "cd /var/www/app && ln -sfn releases/20240114093045 current"
```

## Rollback Validation

After rollback, verify:

1. **Application Health**:
   ```bash
   wheels deploy status production --health
   ```

2. **Service Status**:
   ```bash
   ssh deploy@prod.example.com "systemctl status cfml-app"
   ```

3. **Error Logs**:
   ```bash
   wheels deploy logs production --tail=100 --filter=error
   ```

## Preventing Rollback Issues

1. **Keep Sufficient Releases**:
   - Configure `keepReleases` appropriately
   - Don't set too low (minimum 3-5)

2. **Test Rollback Procedures**:
   - Practice in staging environment
   - Document manual procedures
   - Automate where possible

3. **Database Considerations**:
   - Design reversible migrations
   - Backup before deployment
   - Test rollback scenarios

## Rollback Limitations

- Shared files/directories not rolled back
- User-uploaded content preserved
- External service changes not reverted
- Some database changes irreversible

## Use Cases

1. **Failed Deployment**: Immediate recovery from deployment failure
2. **Performance Issues**: Revert problematic release
3. **Critical Bugs**: Quick fix by reverting
4. **Testing Rollback**: Verify rollback procedures work
5. **Compliance**: Revert unauthorized changes

## Monitoring After Rollback

- Check application performance
- Monitor error rates
- Verify user functionality
- Review system resources
- Analyze root cause

## Notes

- Always investigate why rollback was needed
- Document rollback incidents
- Update deployment procedures based on learnings
- Consider implementing better pre-deployment testing
- Communicate rollback to stakeholders

## See Also

- [wheels deploy exec](deploy-exec.md) - Execute deployment
- [wheels deploy status](deploy-status.md) - Check deployment status
- [wheels deploy logs](deploy-logs.md) - View deployment logs
- [wheels dbmigrate down](../database/dbmigrate-down.md) - Rollback migrations