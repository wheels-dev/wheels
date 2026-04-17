---
title: Wheels CLI Command Reference
---
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
  [Documentation](/v3-1-0/command-line-tools/commands/core/init/)

- **`wheels info`** - Display version information
  [Documentation](/v3-1-0/command-line-tools/commands/core/info/)

- **`wheels reload`** - Reload application
  [Documentation](/v3-1-0/command-line-tools/commands/core/reload/)

- **`wheels deps`** - Manage dependencies
  [Documentation](/v3-1-0/command-line-tools/commands/core/deps/)

- **`wheels destroy [type] [name]`** - Remove generated code
  [Documentation](/v3-1-0/command-line-tools/commands/core/destroy/)

## Code Generation

Commands for generating application code and resources.

- **`wheels generate app`** (alias: `wheels new`) - Create new application
  [Documentation](/v3-1-0/command-line-tools/commands/generate/app/)

- **`wheels generate app-wizard`** - Interactive app creation
  [Documentation](/v3-1-0/command-line-tools/commands/generate/app-wizard/)

- **`wheels generate controller`** (alias: `wheels g controller`) - Generate controller
  [Documentation](/v3-1-0/command-line-tools/commands/generate/controller/)

- **`wheels generate model`** (alias: `wheels g model`) - Generate model
  [Documentation](/v3-1-0/command-line-tools/commands/generate/model/)

- **`wheels generate view`** (alias: `wheels g view`) - Generate view
  [Documentation](/v3-1-0/command-line-tools/commands/generate/view/)

- **`wheels generate helper`** (alias: `wheels g helper`) - Generate global helper functions
  [Documentation](/v3-1-0/command-line-tools/commands/generate/helper/)

- **`wheels generate migration`** (alias: `wheels g migration`) - Generate database migration
  [Documentation](/v3-1-0/command-line-tools/commands/generate/migration/)

- **`wheels generate property`** - Add model property
  [Documentation](/v3-1-0/command-line-tools/commands/generate/property/)

- **`wheels generate route`** - Generate route
  [Documentation](/v3-1-0/command-line-tools/commands/generate/route/)

- **`wheels generate test`** - Generate tests
  [Documentation](/v3-1-0/command-line-tools/commands/generate/test/)

- **`wheels generate code`** - Code snippets
  [Documentation](/v3-1-0/command-line-tools/commands/generate/code/)

- **`wheels generate snippets`** - Snippets Template
  [Documentation](/v3-1-0/command-line-tools/commands/generate/snippets/)

- **`wheels generate scaffold`** - Complete CRUD
  [Documentation](/v3-1-0/command-line-tools/commands/generate/scaffold/)

- **`wheels generate api-resource`** - Generate RESTful API resource
  [Documentation](/v3-1-0/command-line-tools/commands/generate/api-resource/)

### Generator Options

Common options across generators:
- `--force` - Overwrite existing files
- `--help` - Show command help

## Database Commands

Commands for managing database schema and migrations.

### Database Operations

- **`wheels db create`** - Create database
  [Documentation](/v3-1-0/command-line-tools/commands/database/db-create/)

- **`wheels db drop`** - Drop database
  [Documentation](/v3-1-0/command-line-tools/commands/database/db-drop/)

### Migration Management

- **`wheels dbmigrate info`** - Show migration status
  [Documentation](/v3-1-0/command-line-tools/commands/database/dbmigrate-info/)

- **`wheels dbmigrate latest`** - Run all pending migrations
  [Documentation](/v3-1-0/command-line-tools/commands/database/dbmigrate-latest/)

- **`wheels dbmigrate up`** - Run next migration
  [Documentation](/v3-1-0/command-line-tools/commands/database/dbmigrate-up/)

- **`wheels dbmigrate down`** - Rollback last migration
  [Documentation](/v3-1-0/command-line-tools/commands/database/dbmigrate-down/)

- **`wheels dbmigrate reset`** - Reset all migrations
  [Documentation](/v3-1-0/command-line-tools/commands/database/dbmigrate-reset/)

- **`wheels dbmigrate exec [version]`** - Run specific migration
  [Documentation](/v3-1-0/command-line-tools/commands/database/dbmigrate-exec/)

### Migration Creation

- **`wheels dbmigrate create blank [name]`** - Create empty migration
  [Documentation](/v3-1-0/command-line-tools/commands/database/dbmigrate-create-blank/)

- **`wheels dbmigrate create table [name]`** - Create table migration
  [Documentation](/v3-1-0/command-line-tools/commands/database/dbmigrate-create-table/)

- **`wheels dbmigrate create column [table] [column]`** - Add column migration
  [Documentation](/v3-1-0/command-line-tools/commands/database/dbmigrate-create-column/)

- **`wheels dbmigrate remove table [name]`** - Drop table migration
  [Documentation](/v3-1-0/command-line-tools/commands/database/dbmigrate-remove-table/)

## Testing Commands

Commands for running and managing tests.

- **`wheels test run`** - Run tests
  [Documentation](/v3-1-0/command-line-tools/commands/test/test-run/)

- **`wheels test all`** - Run all tests
  [Documentation](/v3-1-0/command-line-tools/commands/test/test-advanced/)

- **`wheels test coverage`** - Run coverage tests
  [Documentation](/v3-1-0/command-line-tools/commands/test/test-advanced/)

- **`wheels test integration`** - Run integration tests
  [Documentation](/v3-1-0/command-line-tools/commands/test/test-advanced/)

- **`wheels test unit`** - Run unit tests
  [Documentation](/v3-1-0/command-line-tools/commands/test/test-advanced/)

- **`wheels test watch`** - Rerun tests on any change
  [Documentation](/v3-1-0/command-line-tools/commands/test/test-advanced/)

## Playwright Commands

Commands for end-to-end testing with Playwright.

- **`wheels playwright:init`** (alias: `wheels playwright init`) - Initialize Playwright project
  [Documentation](/v3-1-0/command-line-tools/commands/playwright/playwright-init/)

- **`wheels playwright:install`** (alias: `wheels playwright install`) - Install Playwright browsers
  [Documentation](/v3-1-0/command-line-tools/commands/playwright/playwright-install/)

## Environment Management

Commands for managing development environments and application context.

- **`wheels env setup [name]`** - Setup environment
  [Documentation](/v3-1-0/command-line-tools/commands/environment/env-setup/)

- **`wheels env list`** - List environments
  [Documentation](/v3-1-0/command-line-tools/commands/environment/env-list/)

- **`wheels env merge`** - Merge env files
  [Documentation](/v3-1-0/command-line-tools/commands/environment/env-merge/)

- **`wheels env set`** - Set env variable
  [Documentation](/v3-1-0/command-line-tools/commands/environment/env-set/)

- **`wheels env show`** - Show env variables
  [Documentation](/v3-1-0/command-line-tools/commands/environment/env-show/)

- **`wheels env switch`** - Switch between environments
  [Documentation](/v3-1-0/command-line-tools/commands/environment/env-switch/)

- **`wheels env validate`** - Validate environment configuration
  [Documentation](/v3-1-0/command-line-tools/commands/environment/env-validate/)

## Code Analysis

Commands for analyzing code quality and patterns.

- **`wheels analyze code`** - Analyze code quality
  [Documentation](/v3-1-0/command-line-tools/commands/analysis/analyze-code/)

- **`wheels analyze performance`** - Performance analysis
  [Documentation](/v3-1-0/command-line-tools/commands/analysis/analyze-performance/)

- **`wheels security scan`** - Security scanning
  [Documentation](/v3-1-0/command-line-tools/commands/security/security-scan/)

## Config Commands

Commands for managing application configuration.

- **`wheels config check`** - Check configuration validity
  [Documentation](/v3-1-0/command-line-tools/commands/config/config-check/)

- **`wheels config diff`** - Compare configuration differences
  [Documentation](/v3-1-0/command-line-tools/commands/config/config-diff/)

- **`wheels config dump`** - Dump current configuration
  [Documentation](/v3-1-0/command-line-tools/commands/config/config-dump/)

## Docker Commands

Commands for Docker container management and deployment.

- **`wheels docker init`** - Initialize Docker configuration files
  [Documentation](/v3-1-0/command-line-tools/commands/docker/docker-init/)

- **`wheels docker build`** - Build Docker images
  [Documentation](/v3-1-0/command-line-tools/commands/docker/docker-build/)

- **`wheels docker deploy`** - Build and deploy Docker containers
  [Documentation](/v3-1-0/command-line-tools/commands/docker/docker-deploy/)

- **`wheels docker push`** - Push Docker images to registries
  [Documentation](/v3-1-0/command-line-tools/commands/docker/docker-push/)

- **`wheels docker login`** - Authenticate with container registries
  [Documentation](/v3-1-0/command-line-tools/commands/docker/docker-login/)

- **`wheels docker logs`** - View container logs
  [Documentation](/v3-1-0/command-line-tools/commands/docker/docker-logs/)

- **`wheels docker exec`** - Execute commands in containers
  [Documentation](/v3-1-0/command-line-tools/commands/docker/docker-exec/)

- **`wheels docker stop`** - Stop Docker containers
  [Documentation](/v3-1-0/command-line-tools/commands/docker/docker-stop/)

## Get Commands

Commands for retrieving application information.

- **`wheels get environment`** - Get current environment details
  [Documentation](/v3-1-0/command-line-tools/commands/get/get-environment/)

- **`wheels get settings`** - Get application settings
  [Documentation](/v3-1-0/command-line-tools/commands/get/get-settings/)

## Documentation Commands

Commands for generating and serving project documentation.

- **`wheels docs generate`** - Generate project documentation
  [Documentation](/v3-1-0/command-line-tools/commands/docs/docs-generate/)

- **`wheels docs serve`** - Serve documentation locally
  [Documentation](/v3-1-0/command-line-tools/commands/docs/docs-serve/)

## Plugin Commands

Commands for managing Wheels plugins.

- **`wheels plugin install`** - Install a plugin
  [Documentation](/v3-1-0/command-line-tools/commands/plugins/plugins-install/)

- **`wheels plugin list`** - List installed plugins
  [Documentation](/v3-1-0/command-line-tools/commands/plugins/plugins-list/)

- **`wheels plugin search`** - Search for plugins
  [Documentation](/v3-1-0/command-line-tools/commands/plugins/plugins-search/)

- **`wheels plugin info`** - Show plugin information
  [Documentation](/v3-1-0/command-line-tools/commands/plugins/plugins-info/)

- **`wheels plugin outdated`** - Check for outdated plugins
  [Documentation](/v3-1-0/command-line-tools/commands/plugins/plugins-outdated/)

- **`wheels plugin update`** - Update a plugin
  [Documentation](/v3-1-0/command-line-tools/commands/plugins/plugins-update/)

- **`wheels plugin update:all`** - Update all plugins
  [Documentation](/v3-1-0/command-line-tools/commands/plugins/plugins-update-all/)

- **`wheels plugin remove`** - Remove a plugin
  [Documentation](/v3-1-0/command-line-tools/commands/plugins/plugins-remove/)

- **`wheels plugin init`** - Initialize new plugin
  [Documentation](/v3-1-0/command-line-tools/commands/plugins/plugins-init/)

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

- [Quick Start Guide](/v3-1-0/command-line-tools/quick-start/)
- [CLI Development Guides](/v3-1-0/command-line-tools/cli-guides/creating-commands/)
- [Service Architecture](/v3-1-0/command-line-tools/cli-guides/service-architecture/)
- [Migrations Guide](/v3-1-0/command-line-tools/cli-guides/migrations/)
- [Testing Guide](/v3-1-0/command-line-tools/cli-guides/testing/)