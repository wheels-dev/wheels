# Wheels CLI Command Reference

Complete reference for all Wheels CLI commands organized by category.

## Quick Reference

### Most Common Commands

| Command | Description |
|---------|-------------|
| `wheels generate app [name]` | Create new application |
| `wheels generate scaffold [name]` | Generate complete CRUD |
| `wheels dbmigrate latest` | Run database migrations |
| `wheels test run` | Run application tests |
| `wheels reload` | Reload application |

## Core Commands

Essential commands for managing your Wheels application.

- **`wheels init`** - Bootstrap existing app for CLI
  [Documentation](core/init.md)

- **`wheels info`** - Display version information
  [Documentation](core/info.md)

- **`wheels reload`** - Reload application
  [Documentation](core/reload.md)

- **`wheels deps`** - Manage dependencies
  [Documentation](core/deps.md)

- **`wheels destroy [type] [name]`** - Remove generated code
  [Documentation](core/destroy.md)

## Code Generation

Commands for generating application code and resources.

- **`wheels generate app`** (alias: `wheels new`) - Create new application
  [Documentation](generate/app.md)

- **`wheels generate app-wizard`** - Interactive app creation
  [Documentation](generate/app-wizard.md)

- **`wheels generate controller`** (alias: `wheels g controller`) - Generate controller
  [Documentation](generate/controller.md)

- **`wheels generate model`** (alias: `wheels g model`) - Generate model
  [Documentation](generate/model.md)

- **`wheels generate view`** (alias: `wheels g view`) - Generate view
  [Documentation](generate/view.md)

- **`wheels generate property`** - Add model property
  [Documentation](generate/property.md)

- **`wheels generate route`** - Generate route
  [Documentation](generate/route.md)

- **`wheels generate test`** - Generate tests
  [Documentation](generate/test.md)

- **`wheels generate snippets`** - Code snippets
  [Documentation](generate/snippets.md)

- **`wheels generate scaffold`** - Complete CRUD
  [Documentation](generate/scaffold.md)

### Generator Options

Common options across generators:
- `--force` - Overwrite existing files
- `--help` - Show command help

## Database Commands

Commands for managing database schema and migrations.

### Database Operations

- **`wheels db create`** - Create database
  [Documentation](database/db-create.md)

- **`wheels db drop`** - Drop database
  [Documentation](database/db-drop.md)

### Migration Management

- **`wheels dbmigrate info`** - Show migration status
  [Documentation](database/dbmigrate-info.md)

- **`wheels dbmigrate latest`** - Run all pending migrations
  [Documentation](database/dbmigrate-latest.md)

- **`wheels dbmigrate up`** - Run next migration
  [Documentation](database/dbmigrate-up.md)

- **`wheels dbmigrate down`** - Rollback last migration
  [Documentation](database/dbmigrate-down.md)

- **`wheels dbmigrate reset`** - Reset all migrations
  [Documentation](database/dbmigrate-reset.md)

- **`wheels dbmigrate exec [version]`** - Run specific migration
  [Documentation](database/dbmigrate-exec.md)

### Migration Creation

- **`wheels dbmigrate create blank [name]`** - Create empty migration
  [Documentation](database/dbmigrate-create-blank.md)

- **`wheels dbmigrate create table [name]`** - Create table migration
  [Documentation](database/dbmigrate-create-table.md)

- **`wheels dbmigrate create column [table] [column]`** - Add column migration
  [Documentation](database/dbmigrate-create-column.md)

- **`wheels dbmigrate remove table [name]`** - Drop table migration
  [Documentation](database/dbmigrate-remove-table.md)

## Testing Commands

Commands for running and managing tests.

- **`wheels test run`** - Run tests
  [Documentation](test/test-run.md)

- **`wheels test all`** - Run all tests
  [Documentation](test/test-advanced.md)

- **`wheels test coverage`** - Run coverage tests
  [Documentation](test/test-advanced.md)

- **`wheels test integration`** - Run integration tests
  [Documentation](test/test-advanced.md)

- **`wheels test unit`** - Run unit tests
  [Documentation](test/test-advanced.md)

- **`wheels test watch`** - Rerun tests on any change
  [Documentation](test/test-advanced.md)

## Environment Management

Commands for managing development environments and application context.

- **`wheels env setup [name]`** - Setup environment
  [Documentation](environment/env-setup.md)

- **`wheels env list`** - List environments
  [Documentation](environment/env-list.md)

- **`wheels env merge`** - Merge env files
  [Documentation](environment/env-merge.md)

- **`wheels env set`** - Set env variable
  [Documentation](environment/env-set.md)

- **`wheels env show`** - Show env variables
  [Documentation](environment/env-show.md)

## Code Analysis

Commands for analyzing code quality and patterns.

- **`wheels analyze code`** - Analyze code quality
  [Documentation](analysis/analyze-code.md)

- **`wheels analyze performance`** - Performance analysis
  [Documentation](analysis/analyze-performance.md)

- **`wheels analyze security`** - Security analysis
  [Documentation](analysis/analyze-security.md)


## Docker Commands

Commands for Docker container management and deployment.

- **`wheels docker init`** - Initialize Docker configuration
  [Documentation](docker/docker-init.md)

- **`wheels docker deploy`** - Deploy using Docker
  [Documentation](docker/docker-deploy.md)

## Command Patterns

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
wheels test run
```

**Starting development:**
```bash
wheels reload            # Reload the application
wheels test run          # Run tests
```

**Deployment preparation:**
```bash
wheels test run
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