# deploy proxy

Configure and manage deployment proxy settings for routing traffic during deployments.

## Synopsis

```bash
wheels deploy proxy <action> [options]
```

## Description

The `wheels deploy proxy` command manages proxy configurations for zero-downtime deployments, traffic routing, and load balancing during deployment operations. It handles blue-green deployments, canary releases, and traffic splitting strategies.

## Actions

- `config` - View or update proxy configuration
- `route` - Manage traffic routing rules
- `health` - Check proxy and backend health
- `switch` - Switch traffic between deployments
- `rollback` - Revert proxy to previous configuration
- `status` - Show current proxy status

## Options

- `--environment, -e` - Target environment (default: production)
- `--strategy` - Deployment strategy (blue-green, canary, rolling)
- `--weight` - Traffic weight percentage for canary deployments
- `--backend` - Backend server or service identifier
- `--health-check` - Health check endpoint
- `--timeout` - Proxy timeout in seconds
- `--sticky-sessions` - Enable session affinity
- `--ssl-redirect` - Force SSL redirect

## Deployment Strategies

### Blue-Green Deployment
```bash
# Configure blue-green proxy
wheels deploy proxy config --strategy blue-green

# Switch traffic to green
wheels deploy proxy switch --to green

# Rollback to blue if needed
wheels deploy proxy rollback
```

### Canary Deployment
```bash
# Start canary with 10% traffic
wheels deploy proxy route --strategy canary --weight 10

# Increase to 50%
wheels deploy proxy route --weight 50

# Full deployment
wheels deploy proxy route --weight 100
```

### Rolling Deployment
```bash
# Configure rolling updates
wheels deploy proxy config --strategy rolling --batch-size 25
```

## Examples

### Configure proxy settings
```bash
wheels deploy proxy config \
  --health-check /health \
  --timeout 30 \
  --ssl-redirect
```

### View proxy status
```bash
wheels deploy proxy status
```

### Set up canary deployment
```bash
# Deploy new version to canary
wheels deploy proxy route \
  --strategy canary \
  --backend app-v2 \
  --weight 5

# Monitor metrics...

# Gradually increase traffic
wheels deploy proxy route --weight 25
wheels deploy proxy route --weight 50
wheels deploy proxy route --weight 100
```

### Health check configuration
```bash
wheels deploy proxy health \
  --health-check /api/health \
  --interval 10 \
  --timeout 5 \
  --retries 3
```

## Traffic Routing Rules

### Weight-based routing
```bash
# Split traffic 80/20
wheels deploy proxy route \
  --backend app-v1 --weight 80 \
  --backend app-v2 --weight 20
```

### Header-based routing
```bash
# Route beta users to new version
wheels deploy proxy route \
  --rule "header:X-Beta-User=true" \
  --backend app-v2
```

### Geographic routing
```bash
# Route by region
wheels deploy proxy route \
  --rule "geo:region=us-west" \
  --backend app-us-west
```

## Proxy Configuration

### Load balancing
```bash
# Configure load balancing algorithm
wheels deploy proxy config \
  --load-balancer round-robin \
  --health-check /health
```

### Session affinity
```bash
# Enable sticky sessions
wheels deploy proxy config \
  --sticky-sessions \
  --session-cookie "app_session"
```

### SSL/TLS settings
```bash
# Configure SSL
wheels deploy proxy config \
  --ssl-redirect \
  --ssl-protocols "TLSv1.2,TLSv1.3" \
  --ssl-ciphers "HIGH:!aNULL"
```

## Use Cases

### Zero-downtime deployment
```bash
# Deploy new version alongside current
wheels deploy exec --target green

# Verify new deployment
wheels deploy proxy health --backend green

# Switch traffic
wheels deploy proxy switch --to green

# Remove old version
wheels deploy stop --target blue
```

### A/B testing
```bash
# Set up A/B test
wheels deploy proxy route \
  --backend feature-a --weight 50 \
  --backend feature-b --weight 50 \
  --cookie "ab_test"
```

### Gradual rollout
```bash
# Start with internal users
wheels deploy proxy route \
  --rule "ip:10.0.0.0/8" \
  --backend app-v2

# Expand to beta users
wheels deploy proxy route \
  --rule "header:X-Beta=true" \
  --backend app-v2

# Full rollout
wheels deploy proxy switch --to app-v2
```

## Monitoring

The proxy provides metrics for:
- Request count and latency
- Error rates
- Backend health status
- Traffic distribution
- Connection pool status

### View metrics
```bash
wheels deploy proxy status --metrics
```

### Export metrics
```bash
wheels deploy proxy status --format prometheus > metrics.txt
```

## Best Practices

1. **Always health check**: Configure health checks for all backends
2. **Gradual rollouts**: Start with small traffic percentages
3. **Monitor metrics**: Watch error rates during transitions
4. **Test rollback**: Ensure rollback procedures work
5. **Document rules**: Keep routing rules well-documented
6. **Use sticky sessions carefully**: They can affect load distribution
7. **SSL everywhere**: Always use SSL in production

## Troubleshooting

### Backend not receiving traffic
```bash
# Check health status
wheels deploy proxy health --backend app-v2

# Verify routing rules
wheels deploy proxy status --rules

# Check proxy logs
wheels deploy logs --component proxy
```

### High error rates
```bash
# Check backend health
wheels deploy proxy health --all

# Reduce traffic to problematic backend
wheels deploy proxy route --backend app-v2 --weight 0

# Investigate logs
wheels deploy logs --grep "proxy error"
```

## See Also

- [deploy exec](deploy-exec.md) - Execute deployment
- [deploy rollback](deploy-rollback.md) - Rollback deployment
- [deploy status](deploy-status.md) - Check deployment status