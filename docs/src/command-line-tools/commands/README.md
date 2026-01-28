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

- **`wheels generate helper`** (alias: `wheels g helper`) - Generate global helper functions
  [Documentation](generate/helper.md)

- **`wheels generate migration`** (alias: `wheels g migration`) - Generate database migration
  [Documentation](generate/migration.md)

- **`wheels generate property`** - Add model property
  [Documentation](generate/property.md)

- **`wheels generate route`** - Generate route
  [Documentation](generate/route.md)

- **`wheels generate test`** - Generate tests
  [Documentation](generate/test.md)

- **`wheels generate code`** - Code snippets
  [Documentation](generate/code.md)

- **`wheels generate snippets`** - Snippets Template
  [Documentation](generate/snippets.md)

- **`wheels generate scaffold`** - Complete CRUD
  [Documentation](generate/scaffold.md)

- **`wheels generate api-resource`** - Generate RESTful API resource
  [Documentation](generate/api-resource.md)

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

- **`wheels env switch`** - Switch between environments
  [Documentation](environment/env-switch.md)

- **`wheels env validate`** - Validate environment configuration
  [Documentation](environment/env-validate.md)

## Code Analysis

Commands for analyzing code quality and patterns.

- **`wheels analyze code`** - Analyze code quality
  [Documentation](analysis/analyze-code.md)

- **`wheels analyze performance`** - Performance analysis
  [Documentation](analysis/analyze-performance.md)

- **`wheels analyze security`** - Security analysis
  [Documentation](analysis/analyze-security.md)

## Config Commands

Commands for managing application configuration.

- **`wheels config check`** - Check configuration validity
  [Documentation](config/config-check.md)

- **`wheels config diff`** - Compare configuration differences
  [Documentation](config/config-diff.md)

- **`wheels config dump`** - Dump current configuration
  [Documentation](config/config-dump.md)

## Docker Commands

Commands for Docker container management and deployment.

- **`wheels docker init`** - Initialize Docker configuration files
  [Documentation](docker/docker-init.md)

- **`wheels docker build`** - Build Docker images
  [Documentation](docker/docker-build.md)

- **`wheels docker deploy`** - Build and deploy Docker containers
  [Documentation](docker/docker-deploy.md)

- **`wheels docker push`** - Push Docker images to registries
  [Documentation](docker/docker-push.md)

- **`wheels docker login`** - Authenticate with container registries
  [Documentation](docker/docker-login.md)

- **`wheels docker logs`** - View container logs
  [Documentation](docker/docker-logs.md)

- **`wheels docker exec`** - Execute commands in containers
  [Documentation](docker/docker-exec.md)

- **`wheels docker stop`** - Stop Docker containers
  [Documentation](docker/docker-stop.md)

## Get Commands

Commands for retrieving application information.

- **`wheels get environment`** - Get current environment details
  [Documentation](get/get-environment.md)

- **`wheels get settings`** - Get application settings
  [Documentation](get/get-settings.md)

## Documentation Commands

Commands for generating and serving project documentation.

- **`wheels docs generate`** - Generate project documentation
  [Documentation](docs/docs-generate.md)

- **`wheels docs serve`** - Serve documentation locally
  [Documentation](docs/docs-serve.md)

## Plugin Commands

Commands for managing Wheels plugins.

- **`wheels plugin install`** - Install a plugin
  [Documentation](plugins/plugins-install.md)

- **`wheels plugin list`** - List installed plugins
  [Documentation](plugins/plugins-list.md)

- **`wheels plugin search`** - Search for plugins
  [Documentation](plugins/plugins-search.md)

- **`wheels plugin info`** - Show plugin information
  [Documentation](plugins/plugins-info.md)

- **`wheels plugin outdated`** - Check for outdated plugins
  [Documentation](plugins/plugins-outdated.md)

- **`wheels plugin update`** - Update a plugin
  [Documentation](plugins/plugins-update.md)

- **`wheels plugin update:all`** - Update all plugins
  [Documentation](plugins/plugins-update-all.md)

- **`wheels plugin remove`** - Remove a plugin
  [Documentation](plugins/plugins-remove.md)

- **`wheels plugin init`** - Initialize new plugin
  [Documentation](plugins/plugins-init.md)

## Command Patterns

### Command Aliases

Many commands have shorter aliases:

```bash
wheels g controller users      # Same as: wheels generate controller users
wheels g model user           # Same as: wheels generate model user
wheels g helper format        # Same as: wheels generate helper format
wheels g migration CreateUsers # Same as: wheels generate migration CreateUsers
wheels new myapp              # Same as: wheels generate app myapp
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