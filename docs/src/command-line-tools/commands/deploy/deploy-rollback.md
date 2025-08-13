# wheels deploy rollback (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Rollback to a previous deployment.

## Synopsis

```bash
wheels deploy:rollback [options]
```

## Description

The `wheels deploy:rollback` command reverts your application to a previous deployment by switching to an earlier Docker image version. It provides quick recovery from failed deployments or problematic releases by pulling and running a previous known-good image.

## Options

- `tag=<string>` - Specific tag to rollback to (if not provided, shows available versions)
- `servers=<string>` - Rollback specific servers (comma-separated list)
- `--force` - Skip confirmation prompt (default: false)

## Examples

### Interactive rollback (shows available versions)
```bash
wheels deploy:rollback
```

### Rollback to specific version
```bash
wheels deploy:rollback tag=v1.0.0
```

### Rollback specific servers
```bash
wheels deploy:rollback servers=web1.example.com,web2.example.com
```

### Force rollback without confirmation
```bash
wheels deploy:rollback tag=v1.0.0 --force
```

## Rollback Process

The rollback follows these steps:

1. **Image Discovery** (if no tag specified):
   - Connect to first server
   - List available Docker images
   - Display versions with creation dates
   - Allow user to select version

2. **Confirmation**:
   - Display selected version
   - Show target servers
   - Request confirmation (unless --force)

3. **Execution** (for each server):
   - Check if image exists locally
   - Pull image from registry if needed
   - Update docker-compose.yml with selected image
   - Stop current container
   - Start container with rollback image
   - Wait for health check

4. **Verification**:
   - Perform health checks
   - Report success/failure for each server

## Interactive Rollback Example

```
Wheels Deployment Rollback
==================================================
Fetching available images from servers...

Available versions:
--------------------------------------------------
1. Tag: v2.1.0 (Created: 2024-01-15 12:00:00)
2. Tag: v2.0.0 (Created: 2024-01-14 09:30:45)
3. Tag: v1.9.5 (Created: 2024-01-13 15:45:22)
4. Tag: v1.9.0 (Created: 2024-01-12 10:11:33)

Select version to rollback to (1-4): 2

WARNING: This will rollback to version: v2.0.0
Target servers: web1.example.com, web2.example.com

Are you sure you want to continue? (yes/no): yes

Rolling back to: registry.example.com/myuser/myapp:v2.0.0

Rolling back: web1.example.com
------------------------------
Checking for image...
Image not found locally, pulling from registry...
Updating configuration...
Performing rollback...
Waiting for health check...
✓ Rollback successful on web1.example.com

Rolling back: web2.example.com
------------------------------
Checking for image...
Updating configuration...
Performing rollback...
Waiting for health check...
✓ Rollback successful on web2.example.com

Rollback completed!
Rolled back to: registry.example.com/myuser/myapp:v2.0.0
```

## Configuration

The rollback uses the same configuration from `config/deploy.yml` as the deployment:

```yaml
service: myapp
image: myapp

registry:
  server: registry.example.com
  username: myuser

servers:
  web:
    - web1.example.com
    - web2.example.com

ssh:
  user: deploy

healthcheck:
  path: /health
  port: 3000
  interval: 30
```

## Health Checks

The rollback performs health checks after switching images:
- Uses the health check configuration from deploy.yml
- Timeout is hardcoded to 60 seconds for rollbacks
- If health check fails, the rollback is reported as failed

## Docker Image Management

The rollback command:
- Lists images matching the configured registry/username/image pattern
- Shows creation timestamps to help identify versions
- Pulls images from registry if not available locally
- Uses the same docker-compose.yml generation as deployments

## Emergency Rollback

For critical situations where interactive selection isn't feasible:

```bash
# Direct rollback to known version
wheels deploy:rollback tag=v1.9.5 --force

# Rollback specific problematic server
wheels deploy:rollback tag=v1.9.5 servers=web2.example.com --force
```

## Manual Rollback (Last Resort)

If the rollback command fails:

```bash
# SSH to server and manually switch images
ssh deploy@web1.example.com
cd /opt/myapp
docker-compose down
# Edit docker-compose.yml to use previous image
docker-compose up -d
```

## Best Practices

1. **Tag Releases Properly**: Use semantic versioning for easy identification
2. **Keep Images Available**: Don't prune old images too aggressively
3. **Test Rollbacks**: Practice rollback procedures in staging
4. **Monitor After Rollback**: Verify application functionality
5. **Document Issues**: Record why rollback was needed

## Limitations

- Requires Docker images to be available (locally or in registry)
- Database changes are not rolled back automatically
- Environment file changes persist
- Shared volumes (storage, logs) are not affected

## See Also

- [wheels deploy:push](deploy-push.md) - Deploy application
- [wheels deploy:status](deploy-status.md) - Check deployment status
- [wheels deploy:logs](deploy-logs.md) - View deployment logs
- [wheels dbmigrate down](../database/dbmigrate-down.md) - Rollback migrations