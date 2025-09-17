---
description: >-
  Deployment commands for automating application deployment, managing
  environments, and handling production releases.
---

# Deployment Commands

Wheels provides comprehensive deployment automation tools to streamline the process of deploying your applications to various environments including staging, production, and cloud platforms.

## Available Commands

### Core Deployment Commands
- [`wheels deploy setup`](./deploy-setup.md) - Initialize deployment configuration
- [`wheels deploy push`](./deploy-push.md) - Deploy application to target environment
- [`wheels deploy rollback`](./deploy-rollback.md) - Rollback to previous deployment
- [`wheels deploy status`](./deploy-status.md) - Check deployment status

### Environment Management
- [`wheels deploy init`](./deploy-init.md) - Initialize new deployment environment
- [`wheels deploy audit`](./deploy-audit.md) - Audit deployment security and configuration
- [`wheels deploy logs`](./deploy-logs.md) - View deployment and application logs

### Advanced Operations
- [`wheels deploy lock`](./deploy-lock.md) - Lock/unlock deployments
- [`wheels deploy hooks`](./deploy-hooks.md) - Manage deployment hooks
- [`wheels deploy secrets`](./deploy-secrets.md) - Manage deployment secrets
- [`wheels deploy stop`](./deploy-stop.md) - Stop running deployment

## Quick Start

### Initial Deployment Setup
```bash
# Initialize deployment for your project
wheels deploy setup --environment=production

# Push initial deployment
wheels deploy push --environment=production --tag=v1.0.0

# Check deployment status
wheels deploy status --environment=production
```

## Deployment Architecture

### Supported Platforms
- **Traditional Servers** - Deploy to Linux/Windows servers
- **Cloud Platforms** - AWS, Azure, Google Cloud
- **Container Platforms** - Docker, Kubernetes
- **CFML Engines** - Adobe ColdFusion, Lucee, CommandBox

### Deployment Strategies
1. **Blue-Green Deployment** - Zero-downtime deployments
2. **Rolling Updates** - Gradual deployment across instances
3. **Canary Releases** - Gradual traffic shifting to new version
4. **Atomic Deployments** - All-or-nothing deployment approach

## Configuration

### Deployment Configuration File
Create `/config/deploy.cfm` for deployment settings:

```cfm
<cfscript>
// Deployment configuration
deployment = {
    // Environment definitions
    environments = {
        staging = {
            host = "staging.myapp.com",
            port = 22,
            user = "deploy",
            path = "/var/www/staging",
            database = {
                host = "db-staging.myapp.com",
                name = "myapp_staging"
            }
        },
        production = {
            host = "app.myapp.com",
            port = 22,
            user = "deploy",
            path = "/var/www/production",
            database = {
                host = "db-prod.myapp.com",
                name = "myapp_production"
            }
        }
    },

    // Deployment options
    options = {
        backupBeforeDeploy = true,
        runMigrations = true,
        clearCache = true,
        restartServices = true
    },

    // Build configuration
    build = {
        excludes = [
            "/tests",
            "/docs",
            "/.git",
            "/temp"
        ],
        includes = [
            "/app",
            "/config",
            "/public",
            "/vendor/wheels"
        ]
    }
};
</cfscript>
```

## Deployment Workflow

### Standard Deployment Process
1. **Pre-deployment Checks**
   - Verify application tests pass
   - Check database migration status
   - Validate configuration files
   - Security and compliance checks

2. **Build Process**
   - Compile assets
   - Run code optimization
   - Create deployment package
   - Generate version metadata

3. **Deployment Execution**
   - Upload deployment package
   - Create backup of current version
   - Deploy new version
   - Run database migrations
   - Update configuration

4. **Post-deployment Tasks**
   - Verify deployment success
   - Run smoke tests
   - Clear caches
   - Restart services
   - Monitor application health

### Example Deployment
```bash
# Full deployment workflow
wheels deploy setup --environment=production
wheels test run --all
wheels deploy push --environment=production --tag=v2.1.0
wheels deploy status --environment=production --wait
```

## Environment Management

### Multiple Environments
```bash
# Setup multiple environments
wheels deploy init --environment=development
wheels deploy init --environment=staging
wheels deploy init --environment=production

# Deploy to specific environment
wheels deploy push --environment=staging
```

### Environment-Specific Configuration
```cfm
// /config/deploy/production.cfm
<cfscript>
set(
    dataSourceName = "myapp_production",
    mailServer = "smtp.production.com",
    cacheSettings = {
        enabled = true,
        timeouts = 3600
    }
);
</cfscript>
```

## Security and Compliance

### Secure Deployments
- **Encrypted Connections** - All deployment communications encrypted
- **Access Control** - Role-based deployment permissions
- **Audit Logging** - Complete deployment activity logs
- **Secret Management** - Secure handling of credentials and API keys

### Compliance Features
- **Deployment Approval** - Required approvals for production deployments
- **Change Tracking** - Full audit trail of all changes
- **Rollback Capability** - Quick rollback to previous versions
- **Environment Segregation** - Isolated deployment environments

## Monitoring and Logging

### Deployment Monitoring
```bash
# Monitor deployment progress
wheels deploy status --environment=production --follow

# View deployment logs
wheels deploy logs --environment=production --lines=100

# Health check after deployment
wheels deploy audit --environment=production
```

### Integration with Monitoring Tools
- **Application Performance Monitoring** - New Relic, DataDog integration
- **Error Tracking** - Sentry, Rollbar integration
- **Infrastructure Monitoring** - Prometheus, Grafana integration
- **Log Aggregation** - ELK Stack, Splunk integration

## Advanced Features

### Blue-Green Deployments
```bash
# Deploy to green environment
wheels deploy push --environment=production --slot=green

# Verify green deployment
wheels deploy audit --environment=production --slot=green

# Switch traffic to green
wheels deploy switch --environment=production --from=blue --to=green
```

### Canary Releases
```bash
# Deploy canary version to 10% of traffic
wheels deploy push --environment=production --canary=10 --tag=v2.1.0

# Increase canary traffic gradually
wheels deploy canary --environment=production --increase=25

# Promote canary to full deployment
wheels deploy promote --environment=production
```

### Database Migrations
```bash
# Deploy with database migrations
wheels deploy push --environment=production --migrate

# Rollback with database rollback
wheels deploy rollback --environment=production --migrate-rollback
```

## CI/CD Integration

### GitHub Actions
```yaml
name: Deploy to Production
on:
  push:
    tags: ['v*']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Production
        run: |
          wheels deploy push --environment=production --tag=${{ github.ref_name }}
          wheels deploy status --environment=production --wait
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any

    stages {
        stage('Test') {
            steps {
                sh 'wheels test run --all'
            }
        }

        stage('Deploy Staging') {
            steps {
                sh 'wheels deploy push --environment=staging'
                sh 'wheels deploy audit --environment=staging'
            }
        }

        stage('Deploy Production') {
            when {
                tag 'v*'
            }
            steps {
                sh 'wheels deploy push --environment=production --tag=${TAG_NAME}'
                sh 'wheels deploy status --environment=production --wait'
            }
        }
    }
}
```

## Best Practices

### Deployment Safety
1. **Always Test First** - Deploy to staging before production
2. **Backup Before Deploy** - Create backups before any deployment
3. **Monitor After Deploy** - Watch application metrics post-deployment
4. **Rollback Plan** - Have tested rollback procedures ready
5. **Gradual Rollouts** - Use canary or blue-green deployments for safety

### Automation Principles
1. **Repeatable Process** - Same deployment process across environments
2. **Version Everything** - Track versions of code, config, and dependencies
3. **Fail Fast** - Stop deployment immediately on any failures
4. **Observable Deployments** - Full visibility into deployment process
5. **Recovery Procedures** - Automated rollback and disaster recovery

## Troubleshooting

### Common Issues
1. **Connection Failures** - Check network connectivity and credentials
2. **Permission Errors** - Verify deployment user has required permissions
3. **Migration Failures** - Review database migration logs and rollback
4. **Service Startup Issues** - Check application logs and configuration
5. **Asset Problems** - Verify static asset deployment and CDN updates

### Debugging Commands
```bash
# Verbose deployment output
wheels deploy push --environment=production --verbose

# Check deployment prerequisites
wheels deploy audit --environment=production --pre-check

# View detailed logs
wheels deploy logs --environment=production --verbose --lines=500
```

## Related Documentation

- [Configuration Management](../../working-with-wheels/configuration-and-defaults.md)
- [Database Migrations](../../database-interaction-through-models/database-migrations/README.md)
- [Testing](../../working-with-wheels/testing-your-application.md)
- [Security](../security/README.md)