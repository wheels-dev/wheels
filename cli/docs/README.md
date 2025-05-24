# Wheels CLI Documentation

Welcome to the comprehensive documentation for the Wheels CLI. This documentation covers all commands, options, and features available in the modernized Wheels CLI.

## Table of Contents

### Getting Started
- [Installation Guide](guides/installation.md)
- [Quick Start](guides/quick-start.md)
- [Configuration](guides/configuration.md)

### Command Reference

#### Core Commands
- [wheels init](commands/core/init.md) - Bootstrap existing Wheels app
- [wheels info](commands/core/info.md) - Display version information
- [wheels reload](commands/core/reload.md) - Reload Wheels application
- [wheels deps](commands/core/deps.md) - Manage dependencies
- [wheels destroy](commands/core/destroy.md) - Remove generated code
- [wheels watch](commands/core/watch.md) - Watch for file changes

#### Code Generation
- [wheels generate app](commands/generate/app.md) - Create new Wheels application
- [wheels generate app-wizard](commands/generate/app-wizard.md) - Interactive app creation
- [wheels generate controller](commands/generate/controller.md) - Generate controllers
- [wheels generate model](commands/generate/model.md) - Generate models
- [wheels generate view](commands/generate/view.md) - Generate views
- [wheels generate property](commands/generate/property.md) - Add model properties
- [wheels generate route](commands/generate/route.md) - Generate routes
- [wheels generate resource](commands/generate/resource.md) - Generate REST resources
- [wheels generate api-resource](commands/generate/api-resource.md) - Generate API resources
- [wheels generate frontend](commands/generate/frontend.md) - Generate frontend code
- [wheels generate test](commands/generate/test.md) - Generate tests
- [wheels generate snippets](commands/generate/snippets.md) - Generate code snippets
- [wheels scaffold](commands/generate/scaffold.md) - Generate complete CRUD scaffolding

#### Database Operations
- [wheels dbmigrate info](commands/database/dbmigrate-info.md) - Show migration status
- [wheels dbmigrate up](commands/database/dbmigrate-up.md) - Migrate up
- [wheels dbmigrate down](commands/database/dbmigrate-down.md) - Migrate down
- [wheels dbmigrate latest](commands/database/dbmigrate-latest.md) - Migrate to latest
- [wheels dbmigrate reset](commands/database/dbmigrate-reset.md) - Reset migrations
- [wheels dbmigrate exec](commands/database/dbmigrate-exec.md) - Execute specific migration
- [wheels dbmigrate create blank](commands/database/dbmigrate-create-blank.md) - Create blank migration
- [wheels dbmigrate create table](commands/database/dbmigrate-create-table.md) - Create table migration
- [wheels dbmigrate create column](commands/database/dbmigrate-create-column.md) - Add column migration
- [wheels dbmigrate remove table](commands/database/dbmigrate-remove-table.md) - Remove table migration
- [wheels db schema](commands/database/db-schema.md) - Export/import schema
- [wheels db seed](commands/database/db-seed.md) - Seed database

#### Testing
- [wheels test](commands/testing/test.md) - Run framework tests
- [wheels test run](commands/testing/test-run.md) - Run TestBox tests
- [wheels test coverage](commands/testing/test-coverage.md) - Generate coverage reports
- [wheels test debug](commands/testing/test-debug.md) - Debug test execution

#### Configuration
- [wheels config list](commands/config/config-list.md) - List configuration
- [wheels config set](commands/config/config-set.md) - Set configuration values
- [wheels config env](commands/config/config-env.md) - Environment configuration

#### Environment Management
- [wheels env setup](commands/environment/env-setup.md) - Setup environments
- [wheels env list](commands/environment/env-list.md) - List environments
- [wheels env switch](commands/environment/env-switch.md) - Switch environments

#### Plugin Management
- [wheels plugins list](commands/plugins/plugins-list.md) - List plugins
- [wheels plugins install](commands/plugins/plugins-install.md) - Install plugins
- [wheels plugins remove](commands/plugins/plugins-remove.md) - Remove plugins

#### Code Analysis
- [wheels analyze code](commands/analysis/analyze-code.md) - Analyze code quality
- [wheels analyze performance](commands/analysis/analyze-performance.md) - Analyze performance
- [wheels analyze security](commands/analysis/analyze-security.md) - Security analysis (deprecated)

#### Security
- [wheels security scan](commands/security/security-scan.md) - Scan for vulnerabilities

#### Performance
- [wheels optimize performance](commands/performance/optimize-performance.md) - Optimize application

#### Documentation
- [wheels docs generate](commands/documentation/docs-generate.md) - Generate documentation
- [wheels docs serve](commands/documentation/docs-serve.md) - Serve documentation

### Guides
- [Service Architecture](guides/service-architecture.md)
- [Creating Custom Commands](guides/creating-commands.md)
- [Template System](guides/template-system.md)
- [Testing Guide](guides/testing.md)
- [Migration Guide](guides/migrations.md)
- [Security Best Practices](guides/security.md)
- [Performance Optimization](guides/performance.md)

### Reference
- [Configuration Options](reference/configuration.md)
- [Template Variables](reference/templates.md)
- [Exit Codes](reference/exit-codes.md)
- [Environment Variables](reference/environment-variables.md)

## Getting Help

- Use `wheels [command] --help` for command-specific help
- Visit the [Wheels Documentation](https://docs.cfwheels.org)
- Report issues on [GitHub](https://github.com/cfwheels/cfwheels)