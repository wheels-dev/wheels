# deploy status (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Check deployment status across all servers.

## Synopsis

```bash
wheels deploy:status [options]
```

## Description

The `wheels deploy:status` command checks the deployment status across all configured servers, including SSH connectivity, Docker status, container health, and optional database status. It provides a comprehensive view of your deployed application's health.

## Options

- `servers=<string>` - Check specific servers (comma-separated list)
- `--detailed` - Show detailed container information (default: false)
- `--logs` - Show recent container logs (default: false)

## Examples

### Basic status check
```bash
wheels deploy:status
```

### Check specific servers
```bash
wheels deploy:status servers=web1.example.com,web2.example.com
```

### Detailed status with container information
```bash
wheels deploy:status --detailed
```

### Status with recent logs
```bash
wheels deploy:status --logs
```

### Complete status check with all details
```bash
wheels deploy:status --detailed --logs
```

## Status Information

The command checks the following components for each server:

### Connection Status
- **SSH Connection**: Verifies SSH connectivity to the server
- **Docker Availability**: Checks if Docker is installed and running

### Container Status
- **Container Running**: Checks if the application container is running
- **Container Health**: Shows container status (Up/Down time)
- **Image Version**: Displays the current Docker image in use

### Health Checks
- **HTTP Health Check**: Tests the configured health endpoint
- **Response Code**: Verifies HTTP 200 response

### Database Status (if configured)
- **Database Container**: Checks if database container is running
- **Database Health**: Shows database container status

## Output Examples

### Basic status output
```
Wheels Deployment Status
==================================================
Checking 2 server(s)...

Server: web1.example.com
----------------------------------------
✓ SSH Connection OK
✓ Docker Running
✓ Container Running
  Status: Up 2 hours
  Image: registry.example.com/myuser/myapp:v2.1.0
✓ Health Check Passed

Server: web2.example.com
----------------------------------------
✓ SSH Connection OK
✓ Docker Running
✓ Container Running
  Status: Up 2 hours
  Image: registry.example.com/myuser/myapp:v2.1.0
✓ Health Check Passed

==================================================
Overall Status: ✓ All Systems Healthy
```

### Detailed status output with --detailed
```
Wheels Deployment Status
==================================================
Checking 2 server(s)...

Server: web1.example.com
----------------------------------------
✓ SSH Connection OK
✓ Docker Running
✓ Container Running
  Status: Up 2 hours
  Image: registry.example.com/myuser/myapp:v2.1.0
✓ Health Check Passed

Container Details:
Created: 2024-01-15T14:30:00Z
State: running
RestartCount: 0
Ports: 3000->3000/tcp
Disk Usage: 45% (120GB available)

Database Status:
✓ Database Running
  Status: Up 2 hours

==================================================
Overall Status: ✓ All Systems Healthy
```

## Status Output with Logs

When using the `--logs` flag:
```
Server: web1.example.com
----------------------------------------
✓ SSH Connection OK
✓ Docker Running
✓ Container Running
  Status: Up 2 hours
  Image: registry.example.com/myuser/myapp:v2.1.0
✓ Health Check Passed

Recent Logs:
----------------------------------------
[2024-01-15 14:30:00] INFO: Server started on port 3000
[2024-01-15 14:30:01] INFO: Database connection established
[2024-01-15 14:30:02] INFO: Health check endpoint ready
[2024-01-15 14:35:00] INFO: Request processed successfully
----------------------------------------
```

## Use Cases

### Pre-deployment check
```bash
# Verify all servers are healthy before deployment
wheels deploy:status
if [ $? -eq 0 ]; then
  wheels deploy:push
fi
```

### Post-deployment verification
```bash
# Check status after deployment
wheels deploy:push tag=v2.1.0
sleep 30
wheels deploy:status --detailed
```

### Health monitoring script
```bash
#!/bin/bash
# Regular health check
while true; do
  wheels deploy:status
  sleep 300  # Check every 5 minutes
done
```

### Troubleshooting specific server
```bash
# Check single problematic server
wheels deploy:status servers=web2.example.com --detailed --logs
```

## Configuration

The status command uses configuration from `config/deploy.yml`:

```yaml
service: myapp

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

accessories:
  db:
    image: mysql:8.0
    volumes:
      - db_data:/var/lib/mysql
```

## Error States

### SSH Connection Failed
```
Server: web1.example.com
----------------------------------------
✗ SSH Connection Failed
  Error: Unable to connect to server
```

### Container Not Running
```
Server: web1.example.com
----------------------------------------
✓ SSH Connection OK
✓ Docker Running
✗ Container Not Running
```

### Health Check Failed
```
Server: web1.example.com
----------------------------------------
✓ SSH Connection OK
✓ Docker Running
✓ Container Running
  Status: Up 5 minutes
  Image: registry.example.com/myuser/myapp:v2.1.0
✗ Health Check Failed
  HTTP Status: 503
```

## Best Practices

1. **Regular monitoring**: Run status checks after deployments
2. **Configure health endpoints**: Ensure `/health` endpoint is properly implemented
3. **Monitor all servers**: Don't assume all servers are in the same state
4. **Check before deployment**: Verify environment health before deploying
5. **Use detailed mode**: Use `--detailed` for troubleshooting
6. **Review logs**: Use `--logs` when investigating issues
7. **Automate checks**: Include status checks in deployment scripts

## Troubleshooting

### SSH Connection Issues
- Verify SSH key is configured correctly
- Check network connectivity to servers
- Ensure user has proper permissions

### Container Not Found
- Verify deployment was successful
- Check if container name matches service name
- Ensure Docker is running on the server

### Health Check Failures
- Verify health endpoint path is correct
- Check if application is fully started
- Review application logs for errors
- Ensure port is accessible

### Database Issues
- Verify database container is running
- Check database connection settings
- Review database logs

## See Also

- [wheels deploy:push](deploy-push.md) - Deploy application
- [wheels deploy:rollback](deploy-rollback.md) - Rollback deployment
- [wheels deploy:logs](deploy-logs.md) - View deployment logs