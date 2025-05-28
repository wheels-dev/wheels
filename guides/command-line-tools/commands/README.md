# Wheels CLI Command Reference

Complete reference for all Wheels CLI commands organized by category.

## Quick Reference

### Most Common Commands

| Command | Description |
|---------|-------------|
| `wheels generate app [name]` | Create new application |
| `wheels scaffold [name]` | Generate complete CRUD |
| `wheels dbmigrate latest` | Run database migrations |
| `wheels test run` | Run application tests |
| `wheels watch` | Watch files for changes |
| `wheels reload` | Reload application |

## Core Commands

Essential commands for managing your Wheels application.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels init` | Bootstrap existing app for CLI | [Details](core/init.md) |
| `wheels info` | Display version information | [Details](core/info.md) |
| `wheels reload [mode]` | Reload application | [Details](core/reload.md) |
| `wheels deps` | Manage dependencies | [Details](core/deps.md) |
| `wheels destroy [type] [name]` | Remove generated code | [Details](core/destroy.md) |
| `wheels watch` | Watch for file changes | [Details](core/watch.md) |

## Code Generation

Commands for generating application code and resources.

| Command | Alias | Description | Documentation |
|---------|-------|-------------|---------------|
| `wheels generate app` | `wheels new` | Create new application | [Details](generate/app.md) |
| `wheels generate app-wizard` | | Interactive app creation | [Details](generate/app-wizard.md) |
| `wheels generate controller` | `wheels g controller` | Generate controller | [Details](generate/controller.md) |
| `wheels generate model` | `wheels g model` | Generate model | [Details](generate/model.md) |
| `wheels generate view` | `wheels g view` | Generate view | [Details](generate/view.md) |
| `wheels generate property` | | Add model property | [Details](generate/property.md) |
| `wheels generate route` | | Generate route | [Details](generate/route.md) |
| `wheels generate resource` | | REST resource | [Details](generate/resource.md) |
| `wheels generate api-resource` | | API resource (**Currently broken**) | [Details](generate/api-resource.md) |
| `wheels generate frontend` | | Frontend code | [Details](generate/frontend.md) |
| `wheels generate test` | | Generate tests | [Details](generate/test.md) |
| `wheels generate snippets` | | Code snippets | [Details](generate/snippets.md) |
| `wheels scaffold` | | Complete CRUD | [Details](generate/scaffold.md) |

### Generator Options

Common options across generators:
- `--force` - Overwrite existing files
- `--help` - Show command help

## Database Commands

Commands for managing database schema and migrations.

### Migration Management

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels dbmigrate info` | Show migration status | [Details](database/dbmigrate-info.md) |
| `wheels dbmigrate latest` | Run all pending migrations | [Details](database/dbmigrate-latest.md) |
| `wheels dbmigrate up` | Run next migration | [Details](database/dbmigrate-up.md) |
| `wheels dbmigrate down` | Rollback last migration | [Details](database/dbmigrate-down.md) |
| `wheels dbmigrate reset` | Reset all migrations | [Details](database/dbmigrate-reset.md) |
| `wheels dbmigrate exec [version]` | Run specific migration | [Details](database/dbmigrate-exec.md) |

### Migration Creation

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels dbmigrate create blank [name]` | Create empty migration | [Details](database/dbmigrate-create-blank.md) |
| `wheels dbmigrate create table [name]` | Create table migration | [Details](database/dbmigrate-create-table.md) |
| `wheels dbmigrate create column [table] [column]` | Add column migration | [Details](database/dbmigrate-create-column.md) |
| `wheels dbmigrate remove table [name]` | Drop table migration | [Details](database/dbmigrate-remove-table.md) |

### Database Operations

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels db schema` | Export/import schema | [Details](database/db-schema.md) |
| `wheels db seed` | Seed database | [Details](database/db-seed.md) |

## Testing Commands

Commands for running and managing tests.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels test [type]` | Run framework tests | [Details](testing/test.md) |
| `wheels test run [spec]` | Run TestBox tests | [Details](testing/test-run.md) |
| `wheels test coverage` | Generate coverage report | [Details](testing/test-coverage.md) |
| `wheels test debug` | Debug test execution | [Details](testing/test-debug.md) |

### Test Options

- `--watch` - Auto-run on changes
- `--reporter` - Output format (simple, json, junit)
- `--bundles` - Specific test bundles
- `--labels` - Filter by labels

## Configuration Commands

Commands for managing application configuration.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels config list` | List configuration | [Details](config/config-list.md) |
| `wheels config set [key] [value]` | Set configuration | [Details](config/config-set.md) |
| `wheels config env` | Environment config | [Details](config/config-env.md) |

## Environment Management

Commands for managing development environments.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels env` | Environment management base command | [Details](environment/env.md) |
| `wheels env setup [name]` | Setup environment | [Details](environment/env-setup.md) |
| `wheels env list` | List environments | [Details](environment/env-list.md) |
| `wheels env switch [name]` | Switch environment | [Details](environment/env-switch.md) |

## Plugin Management

Commands for managing Wheels plugins.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels plugins` | Plugin management base command | [Details](plugins/plugins.md) |
| `wheels plugins list` | List plugins | [Details](plugins/plugins-list.md) |
| `wheels plugins install [name]` | Install plugin | [Details](plugins/plugins-install.md) |
| `wheels plugins remove [name]` | Remove plugin | [Details](plugins/plugins-remove.md) |

### Plugin Options

- `--global` - Install/list globally
- `--dev` - Development dependency

## Code Analysis

Commands for analyzing code quality and patterns.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels analyze` | Code analysis base command | [Details](analysis/analyze.md) |
| `wheels analyze code` | Analyze code quality | [Details](analysis/analyze-code.md) |
| `wheels analyze performance` | Performance analysis | [Details](analysis/analyze-performance.md) |
| `wheels analyze security` | Security analysis (deprecated) | [Details](analysis/analyze-security.md) |

## Security Commands

Commands for security scanning and hardening.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels security` | Security management base command | [Details](security/security.md) |
| `wheels security scan` | Scan for vulnerabilities | [Details](security/security-scan.md) |

### Security Options

- `--fix` - Auto-fix issues
- `--path` - Specific path to scan

## Performance Commands

Commands for optimizing application performance.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels optimize` | Optimization base command | [Details](performance/optimize.md) |
| `wheels optimize performance` | Optimize application | [Details](performance/optimize-performance.md) |

## Documentation Commands

Commands for generating and serving documentation.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels docs` | Documentation base command (**Currently broken**) | [Details](documentation/docs.md) |
| `wheels docs generate` | Generate documentation | [Details](documentation/docs-generate.md) |
| `wheels docs serve` | Serve documentation | [Details](documentation/docs-serve.md) |

### Documentation Options

- `--format` - Output format (html, markdown)
- `--output` - Output directory
- `--port` - Server port

## CI/CD Commands

Commands for continuous integration and deployment workflows.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels ci init` | Initialize CI/CD configuration | [Details](ci/ci-init.md) |

## Docker Commands

Commands for Docker container management and deployment.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels docker init` | Initialize Docker configuration | [Details](docker/docker-init.md) |
| `wheels docker deploy` | Deploy using Docker | [Details](docker/docker-deploy.md) |

## Deployment Commands

Commands for managing application deployments.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels deploy` | Deployment base command | [Details](deploy/deploy.md) |
| `wheels deploy audit` | Audit deployment configuration | [Details](deploy/deploy-audit.md) |
| `wheels deploy exec` | Execute deployment | [Details](deploy/deploy-exec.md) |
| `wheels deploy hooks` | Manage deployment hooks | [Details](deploy/deploy-hooks.md) |
| `wheels deploy init` | Initialize deployment | [Details](deploy/deploy-init.md) |
| `wheels deploy lock` | Lock deployment state | [Details](deploy/deploy-lock.md) |
| `wheels deploy logs` | View deployment logs | [Details](deploy/deploy-logs.md) |
| `wheels deploy proxy` | Configure deployment proxy | [Details](deploy/deploy-proxy.md) |
| `wheels deploy push` | Push deployment | [Details](deploy/deploy-push.md) |
| `wheels deploy rollback` | Rollback deployment | [Details](deploy/deploy-rollback.md) |
| `wheels deploy secrets` | Manage deployment secrets | [Details](deploy/deploy-secrets.md) |
| `wheels deploy setup` | Setup deployment environment | [Details](deploy/deploy-setup.md) |
| `wheels deploy status` | Check deployment status | [Details](deploy/deploy-status.md) |
| `wheels deploy stop` | Stop deployment | [Details](deploy/deploy-stop.md) |

### Deployment Options

- `--environment` - Target environment
- `--force` - Force deployment
- `--dry-run` - Preview changes without deploying

## Command Patterns

### Getting Help

Every command supports `--help`:

```bash
wheels [command] --help
wheels generate controller --help
wheels dbmigrate create table --help
```

### Command Aliases

Many commands have shorter aliases:

```bash
wheels g controller users  # Same as: wheels generate controller users
wheels g model user       # Same as: wheels generate model user
wheels new myapp         # Same as: wheels generate app myapp
```

### Common Workflows

**Creating a new feature:**
```bash
wheels scaffold product --properties="name:string,price:decimal"
wheels dbmigrate latest
wheels test run
```

**Starting development:**
```bash
wheels watch              # Terminal 1
box server start         # Terminal 2
wheels test run --watch  # Terminal 3
```

**Deployment preparation:**
```bash
wheels test run
wheels security scan
wheels optimize performance
wheels dbmigrate info
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WHEELS_ENV` | Environment mode | `development` |
| `WHEELS_DATASOURCE` | Database name | From config |
| `WHEELS_RELOAD_PASSWORD` | Reload password | From config |

## Exit Codes

| Code | Description |
|------|-------------|
| `0` | Success |
| `1` | General error |
| `2` | Invalid arguments |
| `3` | File not found |
| `4` | Permission denied |
| `5` | Database error |

## Command Status Notes

Some commands in the Wheels CLI are currently in various states of development or maintenance:

### Broken Commands
- `wheels docs` - Base documentation command is currently broken
- `wheels generate api-resource` - API resource generation is currently broken

### Disabled Commands
The following commands exist in the codebase but are currently disabled:
- Some CI and Docker commands have disabled variants in the codebase

These commands may be re-enabled in future versions of Wheels.

## See Also

- [Installation Guide](../guides/installation.md)
- [Quick Start Guide](../guides/quick-start.md)
- [Creating Custom Commands](../guides/creating-commands.md)
- [CLI Architecture](../guides/service-architecture.md)