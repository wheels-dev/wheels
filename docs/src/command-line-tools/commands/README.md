# Wheels CLI Command Reference

Complete reference for all Wheels CLI commands organized by category.

## Quick Reference

### Most Common Commands

| Command | Description |
|---------|-------------|
| `wheels generate app [name]` | Create new application |
| `wheels generate scaffold [name]` | Generate complete CRUD |
| `wheels dbmigrate latest` | Run database migrations |
| `wheels test` | Run application tests |
| `wheels reload` | Reload application |

## Core Commands

Essential commands for managing your Wheels application.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels init` | Bootstrap existing app for CLI | [Details](core/init.md) |
| `wheels info` | Display version information | [Details](core/info.md) |
| `wheels reload` | Reload application | [Details](core/reload.md) |
| `wheels deps` | Manage dependencies | [Details](core/deps.md) |
| `wheels destroy [type] [name]` | Remove generated code | [Details](core/destroy.md) |

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
| `wheels generate test` | | Generate tests | [Details](generate/test.md) |
| `wheels generate snippets` | | Code snippets | [Details](generate/snippets.md) |
| `wheels generate scaffold` | | Complete CRUD | [Details](generate/scaffold.md) |

### Generator Options

Common options across generators:
- `--force` - Overwrite existing files
- `--help` - Show command help

## Database Commands

Commands for managing database schema and migrations.

### Database Operations

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels db create` | Create database | [Details](database/db-create.md) |
| `wheels db drop` | Drop database | [Details](database/db-drop.md) |

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

## Testing Commands

Commands for running and managing tests.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels test` | Run framework tests | [Details](testing/test.md) |

## Environment Management

Commands for managing development environments and application context.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels env` | Environment base command | [Details](environment/env.md) |
| `wheels env setup [name]` | Setup environment | [Details](environment/env-setup.md) |
| `wheels env list` | List environments | [Details](environment/env-list.md) |

## Code Analysis

Commands for analyzing code quality and patterns.

| Command | Description | Documentation |
|---------|-------------|---------------|
| `wheels analyze` | Code analysis base command | [Details](analysis/analyze.md) |
| `wheels analyze code` | Analyze code quality | [Details](analysis/analyze-code.md) |
| `wheels analyze performance` | Performance analysis | [Details](analysis/analyze-performance.md) |
| `wheels analyze security` | Security analysis | [Details](analysis/analyze-security.md) |

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
wheels generate scaffold name=product properties=name:string,price:decimal
wheels dbmigrate latest
wheels test
```

**Starting development:**
```bash
wheels reload            # Reload the application
wheels test             # Run tests
```

**Deployment preparation:**
```bash
wheels test
wheels analyze security
wheels analyze performance
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

## See Also

- [Quick Start Guide](../quick-start.md)
- [CLI Development Guides](../cli-guides/creating-commands.md)
- [Service Architecture](../cli-guides/service-architecture.md)
- [Migrations Guide](../cli-guides/migrations.md)
- [Testing Guide](../cli-guides/testing.md)