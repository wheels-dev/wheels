# wheels deploy init

Initialize deployment configuration for your Wheels application.

## Synopsis

```bash
wheels deploy init [target] [options]
```

## Description

The `wheels deploy init` command creates and configures deployment settings for your Wheels application. It generates deployment configuration files and sets up target environments.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `target` | Deployment target name (production, staging, dev) | Interactive prompt |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--type` | Deployment type (ssh, ftp, rsync, git, docker) | `ssh` |
| `--host` | Target host or server | Interactive prompt |
| `--port` | Connection port | `22` (SSH), `21` (FTP) |
| `--path` | Remote deployment path | `/var/www/html` |
| `--user` | Remote user | Current user |
| `--branch` | Git branch to deploy | `main` |
| `--strategy` | Deployment strategy (rolling, blue-green, canary) | `rolling` |
| `--keep-releases` | Number of releases to keep | `5` |
| `--force` | Overwrite existing configuration | `false` |
| `--help` | Show help information |

## Examples

### Interactive initialization
```bash
wheels deploy init
```

### Initialize production target
```bash
wheels deploy init production --host=prod.example.com --path=/var/www/app
```

### Initialize with Git deployment
```bash
wheels deploy init staging --type=git --branch=develop
```

### Initialize Docker deployment
```bash
wheels deploy init production --type=docker --host=swarm.example.com
```

### Initialize with specific strategy
```bash
wheels deploy init production --strategy=blue-green --keep-releases=3
```

## What It Does

1. **Creates deployment configuration**:
   - `.wheels-deploy.json` in project root
   - Target-specific settings
   - Deployment credentials (encrypted)

2. **Sets up deployment structure**:
   - Release directories
   - Shared directories (uploads, logs)
   - Symbolic links

3. **Configures deployment hooks**:
   - Pre-deployment tasks
   - Post-deployment tasks
   - Rollback procedures

4. **Validates configuration**:
   - Tests connection to target
   - Verifies permissions
   - Checks dependencies

## Configuration Structure

Generated `.wheels-deploy.json`:

```json
{
  "version": "1.0",
  "targets": {
    "production": {
      "type": "ssh",
      "host": "prod.example.com",
      "port": 22,
      "user": "deploy",
      "path": "/var/www/app",
      "branch": "main",
      "strategy": "rolling",
      "keepReleases": 5,
      "shared": {
        "dirs": ["logs", "uploads", "temp"],
        "files": [".env", "config/production.json"]
      },
      "hooks": {
        "pre-deploy": [
          "npm run build",
          "box install --production"
        ],
        "post-deploy": [
          "wheels dbmigrate latest",
          "wheels reload production",
          "npm run cache:clear"
        ],
        "rollback": [
          "wheels reload production"
        ]
      },
      "exclude": [
        ".git",
        ".gitignore",
        "node_modules",
        "tests",
        "*.log"
      ]
    }
  },
  "defaults": {
    "timeout": 300,
    "retries": 3,
    "notifications": {
      "slack": {
        "webhook": "https://hooks.slack.com/..."
      }
    }
  }
}
```

## Deployment Types

### SSH Deployment
- Secure shell access
- Rsync for file transfer
- Full control over deployment

### FTP Deployment
- Legacy support
- Simple file transfer
- Limited automation

### Git Deployment
- Git-based workflows
- Post-receive hooks
- Version control integration

### Docker Deployment
- Container orchestration
- Image-based deployment
- Scalable infrastructure

## Shared Resources

Shared directories and files persist across deployments:
- **Directories**: User uploads, logs, cache
- **Files**: Environment configs, secrets

## Deployment Hooks

### Pre-deployment
- Build assets
- Run tests
- Backup database

### Post-deployment
- Run migrations
- Clear caches
- Restart services
- Send notifications

### Rollback
- Restore previous release
- Revert database
- Clear caches

## Interactive Mode

When run without arguments, the command enters interactive mode:

```
? Select deployment target: (Use arrow keys)
❯ production
  staging
  development
  + Add new target

? Deployment type: (Use arrow keys)
❯ SSH (Recommended)
  Git
  Docker
  FTP

? Target host: prod.example.com
? Remote path: /var/www/app
? Remote user: deploy
```

## Security Considerations

1. **Credentials**: Stored encrypted in config
2. **SSH Keys**: Recommended over passwords
3. **Permissions**: Least privilege principle
4. **Secrets**: Use environment variables

## Use Cases

1. **New Project**: Set up deployment pipeline
2. **Migration**: Move from manual to automated deployment
3. **Multi-Environment**: Configure staging and production
4. **Team Setup**: Share deployment configuration

## Notes

- Run from project root directory
- Requires appropriate server access
- Test with staging environment first
- Back up existing configuration before overwriting

## See Also

- [wheels deploy](deploy.md) - Deployment overview
- [wheels deploy setup](deploy-setup.md) - Setup deployment environment
- [wheels deploy exec](deploy-exec.md) - Execute deployment
- [wheels deploy secrets](deploy-secrets.md) - Manage secrets