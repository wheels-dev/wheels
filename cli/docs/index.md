# Wheels CLI Documentation

Welcome to the comprehensive documentation for the Wheels CLI, a command-line tool that enhances your development experience when working with the Wheels framework.

## Documentation Sections

- [Overview](README.md) - Introduction and general information
- [Application Management](application-management.md) - Commands for managing application lifecycle
- [Development Tools](development-tools.md) - Code generation and development aids
- [Database Commands](database-commands.md) - Database migrations, seeds, and schema tools
- [Testing](testing.md) - Commands for testing and coverage analysis
- [Configuration](configuration.md) - Configuration management across environments
- [Frontend and API Development](frontend-and-api.md) - Modern frontend and API integration
- [DevOps Tools](devops.md) - CI/CD and Docker containerization
- [Performance Analysis](performance.md) - Tools to identify and fix performance issues
- [Dependency Management](dependency-management.md) - Managing plugins and dependencies

## Quick Start

Install the Wheels CLI:

```bash
box install wheels-cli
```

Create a new Wheels application:

```bash
wheels init myApp
```

Start development with automatic reloading:

```bash
wheels watch
```

## Command Reference Index

### Application Management
- [wheels init](application-management.md#init) - Create a new application
- [wheels reload](application-management.md#reload) - Reload the application
- [wheels info](application-management.md#info) - Display application information
- [wheels watch](application-management.md#watch) - Monitor file changes and auto-reload

### Development Tools
- [wheels generate controller](development-tools.md#generate-controller) - Generate a controller
- [wheels generate model](development-tools.md#generate-model) - Generate a model
- [wheels generate view](development-tools.md#generate-view) - Generate a view
- [wheels generate property](development-tools.md#generate-property) - Generate a property
- [wheels generate api-resource](development-tools.md#generate-api-resource) - Create API endpoints
- [wheels generate frontend](development-tools.md#generate-frontend) - Set up frontend framework
- [wheels scaffold](development-tools.md#scaffold) - Generate CRUD functionality

### Database Commands
- [wheels dbmigrate create](database-commands.md#dbmigrate-create) - Create migration
- [wheels dbmigrate up](database-commands.md#dbmigrate-up) - Run migrations
- [wheels dbmigrate down](database-commands.md#dbmigrate-down) - Revert migrations
- [wheels dbmigrate reset](database-commands.md#dbmigrate-reset) - Reset database
- [wheels dbmigrate latest](database-commands.md#dbmigrate-latest) - Migrate to latest
- [wheels dbmigrate info](database-commands.md#dbmigrate-info) - Show migration info
- [wheels db:seed](database-commands.md#db-seed) - Generate test data
- [wheels db:schema](database-commands.md#db-schema) - Visualize schema

### Testing
- [wheels test](testing.md#test) - Run tests
- [wheels test:coverage](testing.md#test-coverage) - Generate coverage reports
- [wheels test:debug](testing.md#test-debug) - Debug failing tests

### Configuration
- [wheels config:list](configuration.md#config-list) - List config settings
- [wheels config:set](configuration.md#config-set) - Set config values
- [wheels config:env](configuration.md#config-environment) - Manage environments

### DevOps
- [wheels ci:init](devops.md#ci-init) - Generate CI/CD configs
- [wheels docker:init](devops.md#docker-init) - Set up Docker for development
- [wheels docker:deploy](devops.md#docker-deploy) - Create production Docker configs

### Performance
- [wheels analyze](performance.md#analyze) - Analyze application performance

### Dependency Management
- [wheels deps](dependency-management.md#dependencies-command) - Manage dependencies and plugins