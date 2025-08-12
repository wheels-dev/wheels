# deploy push (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Deploy your Wheels application to configured servers.

## Synopsis

```bash
wheels deploy:push [options]
```

## Description

The `wheels deploy:push` command builds and deploys your Wheels application to configured servers using Docker. It handles Docker image building, pushing to registry, and deploying to target servers with optional rolling deployments for zero-downtime updates.

## Options

- `tag=<string>` - Docker image tag (defaults to timestamp format: yyyymmddHHmmss)
- `--build` - Build Docker image locally (default: true, use --no-build to skip)
- `--push` - Push image to registry (default: true, use --no-push to skip)
- `--rolling` - Use rolling deployment for zero-downtime updates (default: true, use --no-rolling to disable)
- `servers=<string>` - Deploy to specific servers (comma-separated list)
- `destination=<string>` - Deployment destination/environment
- `timeout=<number>` - Deployment timeout in seconds (default: 600)
- `health-timeout=<number>` - Health check timeout in seconds (default: 300)

## Examples

### Basic deployment
```bash
wheels deploy:push
```

### Deploy with specific tag
```bash
wheels deploy:push tag=v1.0.0
```

### Skip building and just deploy existing image
```bash
wheels deploy:push tag=v1.0.0 --no-build
```

### Deploy to specific servers
```bash
wheels deploy:push servers=web1.example.com,web2.example.com
```

### Deploy without rolling updates (with downtime)
```bash
wheels deploy:push --no-rolling
```

### Deploy with custom timeouts
```bash
wheels deploy:push timeout=900 health-timeout=600
```

## Deployment Process

The deployment follows these steps:

1. **Lock Acquisition**: Acquire deployment lock to prevent concurrent deployments
2. **Pre-connect Hook**: Execute pre-connect lifecycle hook
3. **Tag Generation**: Generate timestamp-based tag if not provided
4. **Pre-build Hook**: Execute pre-build lifecycle hook
5. **Docker Build**: Build Docker image (if --build is enabled)
6. **Registry Push**: Push image to configured registry (if --push is enabled)
7. **Pre-deploy Hook**: Execute pre-deploy lifecycle hook
8. **Server Deployment**: Deploy to each target server
   - Copy environment configuration
   - Generate docker-compose.yml
   - Pull new image
   - Perform rolling deployment or restart
   - Clean up old images
9. **Post-deploy Hook**: Execute post-deploy lifecycle hook
10. **Lock Release**: Release deployment lock

## Rolling Deployment

When `--rolling` is enabled (default), the deployment:
- Scales up the service to run old and new containers simultaneously
- Waits for health checks to pass on new containers
- Removes old containers only after successful health checks
- Rolls back automatically if health checks fail

## Health Checks

The deployment uses health checks defined in your deploy.yml configuration:
```yaml
healthcheck:
  path: /health
  port: 3000
  interval: 30
  timeout: 10
  retries: 3
```

## Deployment Hooks

Lifecycle hooks are executed at various stages:
- `pre-connect`: Before connecting to servers
- `pre-build`: Before building Docker image
- `pre-deploy`: Before deploying to servers
- `post-deploy`: After successful deployment

## Configuration

The deployment uses configuration from `config/deploy.yml`:
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

env:
  clear:
    WHEELS_ENV: production
    PORT: 3000

healthcheck:
  path: /health
  port: 3000
  interval: 30

traefik:
  enabled: true
  labels:
    traefik.http.routers.myapp.rule: Host(`myapp.example.com`)
```

## Environment Variables

Environment variables are loaded from `.env.deploy` file and copied to target servers.

## Docker Compose Generation

The command generates a docker-compose.yml file on target servers with:
- Service configuration
- Environment variables
- Port mappings
- Volume mounts
- Health checks
- Traefik labels (if enabled)
- Database services (if configured)

## Use Cases

### Production deployment with specific version
```bash
wheels deploy:push tag=v2.0.0
```

### Deploy pre-built image from CI/CD
```bash
# Image already built and pushed by CI
wheels deploy:push tag=build-123 --no-build --no-push
```

### Deploy to staging servers only
```bash
wheels deploy:push servers=staging1.example.com destination=staging
```

### Emergency deployment without health checks
```bash
wheels deploy:push --no-rolling health-timeout=0
```

## Best Practices

1. **Use semantic versioning**: Tag releases with version numbers
2. **Test in staging first**: Deploy to staging before production
3. **Monitor deployments**: Check logs and health status
4. **Use rolling deployments**: Minimize downtime with --rolling
5. **Configure health checks**: Ensure proper health check endpoints
6. **Set appropriate timeouts**: Adjust timeouts based on app startup time
7. **Use deployment locks**: Prevent concurrent deployments

## See Also

- [deploy exec](deploy-exec.md) - Execute deployment after push
- [deploy status](deploy-status.md) - Check push status
- [deploy rollback](deploy-rollback.md) - Rollback pushed artifacts