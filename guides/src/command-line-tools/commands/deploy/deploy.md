# wheels deploy

Base command for deployment operations in Wheels applications.

## Synopsis

```bash
wheels deploy [subcommand] [options]
```

## Description

The `wheels deploy` command provides a comprehensive deployment system for Wheels applications. It manages the entire deployment lifecycle including initialization, execution, monitoring, and rollback capabilities.

## Subcommands

| Command | Description |
|---------|-------------|
| `audit` | Audit deployment configuration and security |
| `exec` | Execute a deployment |
| `hooks` | Manage deployment hooks |
| `init` | Initialize deployment configuration |
| `lock` | Lock deployment state |
| `logs` | View deployment logs |
| `proxy` | Configure deployment proxy |
| `push` | Push deployment to target |
| `rollback` | Rollback to previous deployment |
| `secrets` | Manage deployment secrets |
| `setup` | Setup deployment environment |
| `status` | Check deployment status |
| `stop` | Stop active deployment |

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |
| `--version` | Show version information |

## Examples

### View deployment help
```bash
wheels deploy --help
```

### Initialize deployment
```bash
wheels deploy init
```

### Execute deployment
```bash
wheels deploy exec production
```

### Check deployment status
```bash
wheels deploy status
```

## Deployment Workflow

1. **Initialize**: Set up deployment configuration
   ```bash
   wheels deploy init
   ```

2. **Setup**: Prepare deployment environment
   ```bash
   wheels deploy setup production
   ```

3. **Configure**: Set secrets and proxy settings
   ```bash
   wheels deploy secrets set DB_PASSWORD
   wheels deploy proxy configure
   ```

4. **Deploy**: Push and execute deployment
   ```bash
   wheels deploy push
   wheels deploy exec
   ```

5. **Monitor**: Check status and logs
   ```bash
   wheels deploy status
   wheels deploy logs --follow
   ```

6. **Rollback** (if needed):
   ```bash
   wheels deploy rollback
   ```

## Configuration

Deployment configuration is stored in `.wheels-deploy.json`:

```json
{
  "targets": {
    "production": {
      "host": "prod.example.com",
      "path": "/var/www/app",
      "branch": "main",
      "hooks": {
        "pre-deploy": ["npm run build"],
        "post-deploy": ["wheels dbmigrate latest"]
      }
    },
    "staging": {
      "host": "staging.example.com",
      "path": "/var/www/staging",
      "branch": "develop"
    }
  },
  "defaults": {
    "strategy": "rolling",
    "keepReleases": 5
  }
}
```

## Deployment Strategies

### Rolling Deployment
- Zero-downtime deployment
- Gradual rollout
- Automatic rollback on failure

### Blue-Green Deployment
- Two identical environments
- Instant switching
- Easy rollback

### Canary Deployment
- Gradual traffic shifting
- Risk mitigation
- Performance monitoring

## Environment Variables

| Variable | Description |
|----------|-------------|
| `WHEELS_DEPLOY_TARGET` | Default deployment target |
| `WHEELS_DEPLOY_STRATEGY` | Default deployment strategy |
| `WHEELS_DEPLOY_TIMEOUT` | Deployment timeout in seconds |

## Use Cases

1. **Continuous Deployment**: Automated deployments from CI/CD
2. **Manual Releases**: Controlled production deployments
3. **Multi-Environment**: Deploy to staging, production, etc.
4. **Disaster Recovery**: Quick rollback capabilities
5. **Scheduled Deployments**: Deploy during maintenance windows

## Best Practices

1. Always run `deploy audit` before production deployments
2. Use `deploy lock` during critical operations
3. Configure proper hooks for migrations and cache clearing
4. Keep deployment logs for auditing
5. Test deployments in staging first
6. Use secrets management for sensitive data

## Notes

- Requires SSH access for remote deployments
- Git repository must be properly configured
- Database backups recommended before deployment
- Monitor application health after deployment

## See Also

- [wheels deploy init](deploy-init.md) - Initialize deployment
- [wheels deploy exec](deploy-exec.md) - Execute deployment
- [wheels deploy rollback](deploy-rollback.md) - Rollback deployment
- [wheels docker deploy](../docker/docker-deploy.md) - Docker deployments