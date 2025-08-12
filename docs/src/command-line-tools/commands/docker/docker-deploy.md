# wheels docker deploy
*This command may not work with options as expected. A complete and stable version with fully functional options is **coming soon**.*

Deploy your Wheels application using Docker containers.

## Synopsis

```bash
wheels docker deploy [target] [options]
```

## Description

The `wheels docker deploy` command deploys your containerized Wheels application to various Docker environments including Docker Swarm, Kubernetes, or cloud container services.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `target` | Deployment target (local, swarm, kubernetes, ecs, gcp, azure) | `local` |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--tag` | Docker image tag | `latest` |
| `--registry` | Docker registry URL | Docker Hub |
| `--namespace` | Kubernetes namespace or project name | `default` |
| `--replicas` | Number of replicas | `1` |
| `--cpu` | CPU limit (e.g., "0.5", "2") | Platform default |
| `--memory` | Memory limit (e.g., "512Mi", "2Gi") | Platform default |
| `--env-file` | Environment file path | `.env` |
| `--config-file` | Deployment configuration file | Auto-detect |
| `--dry-run` | Preview deployment without applying | `false` |
| `--force` | Force deployment even if up-to-date | `false` |
| `--help` | Show help information |

## Examples

### Deploy locally
```bash
wheels docker deploy local
```

### Deploy to Docker Swarm
```bash
wheels docker deploy swarm --replicas=3
```

### Deploy to Kubernetes
```bash
wheels docker deploy kubernetes --namespace=production --tag=v1.2.3
```

### Deploy to AWS ECS
```bash
wheels docker deploy ecs --registry=123456789.dkr.ecr.us-east-1.amazonaws.com
```

### Dry run deployment
```bash
wheels docker deploy kubernetes --dry-run
```

### Deploy with resource limits
```bash
wheels docker deploy swarm --cpu=2 --memory=4Gi --replicas=5
```

## What It Does

1. **Build and Tag**:
   - Builds Docker image if needed
   - Tags with specified version
   - Validates image integrity

2. **Push to Registry**:
   - Authenticates with registry
   - Pushes image to registry
   - Verifies push success

3. **Deploy to Target**:
   - Generates deployment manifests
   - Applies configuration
   - Monitors deployment status
   - Performs health checks

4. **Post-Deployment**:
   - Runs database migrations
   - Clears caches
   - Sends notifications

## Deployment Targets

### Local
- Uses docker-compose
- Development/testing
- No registry required

### Docker Swarm
- Creates/updates services
- Load balancing
- Rolling updates
- Secrets management

### Kubernetes
- Creates deployments, services, ingress
- ConfigMaps and Secrets
- Horizontal pod autoscaling
- Rolling updates

### AWS ECS
- Task definitions
- Service updates
- Load balancer configuration
- Auto-scaling

### Google Cloud Run
- Serverless containers
- Automatic scaling
- HTTPS endpoints

### Azure Container Instances
- Container groups
- Managed instances
- Integration with Azure services

## Configuration Files

### Kubernetes Example (k8s.yml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wheels-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: wheels
  template:
    metadata:
      labels:
        app: wheels
    spec:
      containers:
      - name: app
        image: myregistry/wheels-app:latest
        ports:
        - containerPort: 8080
        env:
        - name: WHEELS_ENV
          value: production
```

### Docker Swarm Example (swarm.yml)
```yaml
version: '3.8'
services:
  app:
    image: myregistry/wheels-app:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    ports:
      - "80:8080"
    secrets:
      - db_password
```

## Environment Management

Environment variables can be provided via:
1. `--env-file` option
2. Platform-specific secrets
3. Configuration files
4. Command line overrides

## Health Checks

The deployment includes health checks:
- Readiness probes
- Liveness probes
- Startup probes
- Custom health endpoints

## Rollback

To rollback a deployment:
```bash
wheels docker deploy [target] --rollback
```

Or manually:
```bash
# Kubernetes
kubectl rollout undo deployment/wheels-app

# Docker Swarm
docker service rollback wheels-app
```

## Use Cases

1. **Staging Deployments**: Test production configurations
2. **Production Releases**: Deploy new versions with zero downtime
3. **Scaling**: Adjust replicas based on load
4. **Multi-Region**: Deploy to multiple regions/zones
5. **Blue-Green Deployments**: Switch between environments

## Notes

- Ensure Docker images are built before deployment
- Registry authentication must be configured
- Database migrations should be handled separately or via init containers
- Monitor deployment logs for troubleshooting
- Use `--dry-run` to preview changes before applying

## Troubleshooting

Common issues:
- **Image not found**: Ensure image is pushed to registry
- **Auth failures**: Check registry credentials
- **Resource limits**: Adjust CPU/memory settings
- **Port conflicts**: Check service port mappings

## See Also

- [wheels docker init](docker-init.md) - Initialize Docker configuration
- [wheels deploy](../deploy/deploy.md) - General deployment commands
- [wheels deploy push](../deploy/deploy-push.md) - Push deployments