# deploy status

Check the current status of deployments and deployment infrastructure.

## Synopsis

```bash
wheels deploy status [options]
```

## Description

The `wheels deploy status` command provides comprehensive information about deployment status, including active deployments, environment health, recent deployment history, and system readiness. It's essential for monitoring deployment progress and troubleshooting issues.

## Options

- `--environment, -e` - Target environment (default: all)
- `--deployment-id, -d` - Check specific deployment status
- `--detailed` - Show detailed status information
- `--health` - Include health check results
- `--history` - Show deployment history
- `--limit` - Number of historical deployments to show
- `--format` - Output format (text, json, yaml) (default: text)
- `--watch` - Continuously monitor status
- `--interval` - Update interval in seconds for watch mode

## Examples

### Basic status check
```bash
wheels deploy status
```

### Check specific environment
```bash
wheels deploy status --environment production
```

### Monitor active deployment
```bash
wheels deploy status --deployment-id dep-123456 --watch
```

### View deployment history
```bash
wheels deploy status --history --limit 10
```

### Detailed status with health checks
```bash
wheels deploy status --detailed --health
```

### Export status as JSON
```bash
wheels deploy status --format json > status.json
```

## Status Information

The command displays various status components:

### Deployment Status
- **Active**: Currently deploying
- **Completed**: Successfully deployed
- **Failed**: Deployment failed
- **Rolled Back**: Deployment was rolled back
- **Pending**: Waiting to start
- **Cancelled**: Deployment was cancelled

### Environment Health
- **Healthy**: All services operational
- **Degraded**: Some services experiencing issues
- **Unhealthy**: Critical services down
- **Unknown**: Unable to determine status

### Service Status
- Application servers
- Database connections
- Cache services
- Queue workers
- Background jobs
- External integrations

## Output Examples

### Basic status output
```
Deployment Status for Production
================================
Current Version: v2.1.0
Last Deployment: 2023-12-01 14:30:00
Status: Healthy
Uptime: 5d 12h 45m

Active Deployments:
  None

Recent Deployments:
  dep-123456 | v2.1.0 | 2023-12-01 14:30:00 | Completed
  dep-123455 | v2.0.9 | 2023-11-30 10:15:00 | Completed
  dep-123454 | v2.0.8 | 2023-11-29 16:45:00 | Rolled Back
```

### Detailed status output
```
Environment: Production
=======================
Infrastructure:
  Provider: AWS
  Region: us-east-1
  Instances: 4/4 healthy
  Load Balancer: Active
  SSL Certificate: Valid (expires in 45 days)

Services:
  ✓ Web Server: Running (4 instances)
  ✓ Database: Connected (Primary + 1 Replica)
  ✓ Cache: Connected (Redis 6.2)
  ✓ Queue: Processing (245 jobs/min)
  ⚠ Email Service: Degraded (high latency)

Resources:
  CPU Usage: 45% average
  Memory Usage: 62% average
  Disk Usage: 38% (152GB free)
  Network I/O: Normal

Recent Errors: 0
Recent Warnings: 3
```

## Use Cases

### Pre-deployment check
```bash
# Verify environment is ready for deployment
wheels deploy status --environment production --health
if [ $? -eq 0 ]; then
  wheels deploy exec
fi
```

### Monitoring deployment progress
```bash
# Watch active deployment
wheels deploy exec &
DEPLOY_ID=$!
wheels deploy status --deployment-id $DEPLOY_ID --watch --interval 5
```

### Health monitoring script
```bash
#!/bin/bash
# Check all environments
for env in production staging development; do
  echo "Checking $env..."
  wheels deploy status --environment $env --health --format json > status-$env.json
done
```

### CI/CD integration
```bash
# Wait for deployment to complete
wheels deploy status --deployment-id $DEPLOY_ID --watch
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "Deployment failed"
  exit 1
fi
```

## Health Checks

The status command performs various health checks:

### Application health
- HTTP endpoint availability
- Response time verification
- Error rate monitoring

### Database health
- Connection pool status
- Query performance
- Replication lag

### Infrastructure health
- Server availability
- Resource utilization
- Network connectivity

### Integration health
- External API connectivity
- Third-party service status
- CDN availability

## Deployment History

View historical deployment information:

```bash
# Last 20 deployments
wheels deploy status --history --limit 20

# Filter by date range
wheels deploy status --history --since "2023-11-01" --until "2023-12-01"

# Failed deployments only
wheels deploy status --history --filter failed
```

## Best Practices

1. **Regular monitoring**: Check status before and after deployments
2. **Automate checks**: Include status checks in deployment scripts
3. **Set up alerts**: Configure alerts for status changes
4. **Document issues**: Keep records of status anomalies
5. **Monitor trends**: Track status patterns over time
6. **Health endpoints**: Ensure proper health check endpoints
7. **Quick response**: Address issues promptly

## Integration

Status monitoring integrates with:
- Monitoring dashboards (Grafana, Datadog)
- Alerting systems (PagerDuty, Opsgenie)
- CI/CD pipelines for deployment validation
- Slack/Teams for status notifications

### Slack notification example
```bash
# Send status to Slack
STATUS=$(wheels deploy status --format json)
curl -X POST $SLACK_WEBHOOK -d "{
  \"text\": \"Deployment Status\",
  \"attachments\": [{
    \"color\": \"good\",
    \"text\": \"$STATUS\"
  }]
}"
```

## Troubleshooting

### Status check failures
```bash
# Verbose output for debugging
wheels deploy status --verbose --debug

# Check specific component
wheels deploy status --component database

# Force refresh
wheels deploy status --force-refresh
```

### Incomplete status data
```bash
# Increase timeout
wheels deploy status --timeout 60

# Check individual services
wheels deploy status --service web
wheels deploy status --service database
```

## See Also

- [deploy logs](deploy-logs.md) - View deployment logs
- [deploy audit](deploy-audit.md) - Audit deployment configuration
- [deploy exec](deploy-exec.md) - Execute deployment