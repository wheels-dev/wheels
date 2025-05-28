# deploy push

Push deployment artifacts to target environment.

## Synopsis

```bash
wheels deploy push [options]
```

## Description

The `wheels deploy push` command transfers deployment artifacts, configuration files, and application code to the target deployment environment. It handles file synchronization, artifact validation, and ensures secure transfer of deployment packages.

## Options

- `--environment, -e` - Target environment (default: production)
- `--artifact` - Path to deployment artifact or directory
- `--config` - Configuration file to include
- `--exclude` - Files/patterns to exclude from deployment
- `--dry-run` - Simulate push without actual transfer
- `--force` - Force push even if validation fails
- `--parallel` - Number of parallel upload threads
- `--compress` - Compression method (gzip, bzip2, none)
- `--checksum` - Verify file integrity with checksums
- `--bandwidth` - Limit bandwidth usage (e.g., "1M", "500K")

## Examples

### Basic push
```bash
wheels deploy push --environment production
```

### Push specific artifact
```bash
wheels deploy push --artifact dist/app-v2.1.0.tar.gz
```

### Dry run to see what would be pushed
```bash
wheels deploy push --dry-run
```

### Push with exclusions
```bash
wheels deploy push --exclude "*.log,tmp/*,node_modules"
```

### Limited bandwidth push
```bash
wheels deploy push --bandwidth 1M
```

## Artifact Types

### Application bundles
```bash
# Push application bundle
wheels deploy push --artifact app-bundle.tar.gz
```

### Docker images
```bash
# Push Docker image
wheels deploy push --artifact myapp:v2.1.0 --type docker
```

### Static assets
```bash
# Push static files
wheels deploy push --artifact public/ --compress gzip
```

### Configuration files
```bash
# Push config separately
wheels deploy push --config production.env --encrypt
```

## Push Process

1. **Validation**: Verify artifacts and environment
2. **Compression**: Compress files if specified
3. **Checksum**: Generate integrity checksums
4. **Transfer**: Upload to target environment
5. **Verification**: Confirm successful transfer
6. **Notification**: Report push status

## Use Cases

### CI/CD pipeline push
```bash
# Build and push in CI/CD
npm run build
wheels deploy push --artifact dist/ --environment staging
```

### Multi-environment push
```bash
# Push to multiple environments
for env in staging production; do
  wheels deploy push --environment $env --artifact release.tar.gz
done
```

### Incremental push
```bash
# Push only changed files
wheels deploy push --incremental --since "1 hour ago"
```

### Secure push with encryption
```bash
# Encrypt sensitive files during push
wheels deploy push \
  --artifact app.tar.gz \
  --config secrets.env \
  --encrypt
```

## Transfer Methods

### Direct transfer
Default method for simple deployments:
```bash
wheels deploy push --method direct
```

### S3 bucket transfer
For AWS deployments:
```bash
wheels deploy push \
  --method s3 \
  --bucket my-deploy-bucket \
  --artifact app.tar.gz
```

### Registry push
For containerized applications:
```bash
wheels deploy push \
  --method registry \
  --registry hub.example.com \
  --artifact myapp:latest
```

## Validation

The push command performs several validations:

### Pre-push validation
- Artifact integrity check
- Environment accessibility
- Space availability
- Permission verification

### Post-push validation
- Transfer completion
- Checksum verification
- Artifact extraction test
- Configuration validation

## Progress Monitoring

```bash
# Show detailed progress
wheels deploy push --verbose

# Output example:
Uploading app-v2.1.0.tar.gz to production
[████████████████████████████████] 100% 45.2MB/45.2MB
✓ Upload complete
✓ Checksum verified
✓ Artifact validated
```

## Error Handling

### Retry failed pushes
```bash
# Auto-retry on failure
wheels deploy push --retry 3 --retry-delay 30
```

### Resume interrupted push
```bash
# Resume from last checkpoint
wheels deploy push --resume
```

### Rollback on failure
```bash
# Automatic rollback if push fails
wheels deploy push --rollback-on-failure
```

## Best Practices

1. **Always validate**: Use --dry-run before actual push
2. **Use checksums**: Enable checksum verification
3. **Compress large artifacts**: Reduce transfer time and bandwidth
4. **Exclude unnecessary files**: Use .deployignore file
5. **Monitor transfer**: Watch for errors during push
6. **Test in staging**: Always push to staging before production
7. **Keep artifacts versioned**: Use semantic versioning

## Configuration

### .deployignore file
```gitignore
# Files to exclude from deployment
*.log
*.tmp
.env.local
node_modules/
test/
docs/
```

### Push configuration
```yaml
# deploy.yml
push:
  compression: gzip
  checksum: sha256
  parallel: 4
  exclude:
    - "*.log"
    - "tmp/*"
  retry:
    attempts: 3
    delay: 30
```

## Integration

Push operations integrate with:
- CI/CD systems for automated deployments
- Artifact repositories (Nexus, Artifactory)
- Container registries (Docker Hub, ECR)
- CDN services for static assets
- Monitoring systems for transfer tracking

## See Also

- [deploy exec](deploy-exec.md) - Execute deployment after push
- [deploy status](deploy-status.md) - Check push status
- [deploy rollback](deploy-rollback.md) - Rollback pushed artifacts