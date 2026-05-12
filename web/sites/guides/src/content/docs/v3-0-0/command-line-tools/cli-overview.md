---
title: Wheels CLI Documentation
---
# Wheels CLI Documentation

Welcome to the comprehensive documentation for the Wheels CLI - a powerful command-line interface for the Wheels framework.

## What is Wheels CLI?

Wheels CLI is a CommandBox module that provides a comprehensive set of tools for developing Wheels applications. It offers:

- **Code Generation** - Quickly scaffold models, controllers, views, and complete CRUD operations
- **Database Migrations** - Manage database schema changes with version control
- **Testing Tools** - Run tests, generate coverage reports, and use watch mode
- **Development Tools** - File watching, automatic reloading, and development servers
- **Code Analysis** - Security scanning, performance analysis, and code quality checks
- **Plugin Management** - Install and manage Wheels plugins
- **Environment Management** - Switch between development, testing, and production

## Documentation Structure

### [Command Reference](/v3-0-0/command-line-tools/commands/)
Complete reference for all CLI commands organized by category:
- [Core Commands](/v3-0-0/command-line-tools/commands/core/init/) - Essential commands like init, reload.
- [Code Generation](/v3-0-0/command-line-tools/commands/generate/app/) - Generate applications, models, controllers, views
- [Database Commands](/v3-0-0/command-line-tools/commands/database/db-create/) - Complete database management and migrations
- [Testing Commands](/v3-0-0/command-line-tools/commands/test/test-run/) - Run tests and generate coverage
- [Configuration](/v3-0-0/command-line-tools/commands/config/config-dump/) - Manage application settings
- [And more...](/v3-0-0/command-line-tools/commands/)

### [Quick Start Guide](/v3-0-0/command-line-tools/guides/quick-start/)
Get up and running with Wheels CLI in minutes. Learn how to:
- Install Wheels CLI
- Create your first application
- Generate CRUD scaffolding
- Run tests and migrations

### Guides

#### Development Guides
- [Service Architecture](/v3-0-0/command-line-tools/guides/service-architecture/) - Understand the CLI's architecture
- [Creating Custom Commands](/v3-0-0/command-line-tools/guides/creating-commands/) - Extend the CLI with your own commands
- [Template System](/v3-0-0/command-line-tools/guides/template-system/) - Customize code generation templates
- [Testing Guide](/v3-0-0/command-line-tools/guides/testing/) - Write and run tests effectively

#### Best Practices
- [Migration Guide](/v3-0-0/command-line-tools/guides/migrations/) - Database migration best practices
- [Security Guide](/v3-0-0/command-line-tools/guides/security/) - Security scanning and hardening
- [Performance Guide](/v3-0-0/command-line-tools/guides/performance/) - Optimization techniques

### Reference
- [Configuration Options](/v3-0-0/command-line-tools/reference/configuration/) - All available configuration settings
- [Template Variables](/v3-0-0/command-line-tools/reference/templates/) - Variables available in templates
- [Exit Codes](/v3-0-0/command-line-tools/reference/exit-codes/) - Understanding command exit codes
- [Environment Variables](/v3-0-0/command-line-tools/reference/environment-variables/) - Environment configuration

## Key Features

### Code Generation

Generate complete applications or individual components:

```bash
# Create new application
wheels new blog

# Generate complete CRUD scaffolding
wheels scaffold name=post properties=title:string,content:text,published:boolean

# Generate individual components
wheels generate model user
wheels generate controller users --rest
wheels generate view users index
```

### Database Management

Complete database lifecycle management:

```bash
# Database operations
wheels db create              # Create database
wheels db setup              # Create + migrate + seed
wheels db reset              # Drop + recreate + migrate + seed
wheels db shell              # Interactive database shell
wheels db dump               # Backup database
wheels db restore backup.sql # Restore from backup

# Migrations
wheels dbmigrate create table posts
wheels dbmigrate latest
wheels db status            # Check migration status
wheels db rollback          # Rollback migrations
```

### Testing

Comprehensive testing support:

```bash
# Run all tests
wheels test run

# Advanced testing with TestBox CLI
wheels test:all              # Run all tests
wheels test:unit             # Run unit tests only
wheels test:integration      # Run integration tests only
wheels test:watch            # Watch mode
wheels test:coverage         # Generate coverage reports
```

### Development Tools

Enhance your development workflow:

```bash

# Reload application
wheels reload development

# Analyze code
wheels analyze code
wheels security scan
```

## Getting Started

1. **Install CommandBox** (if not already installed):
   ```bash
   # macOS/Linux
   curl -fsSl https://downloads.ortussolutions.com/debs/gpg | sudo apt-key add -
   or
	brew install commandbox

   # Windows
   choco install commandbox
   ```

2. **Install Wheels CLI**:
   ```bash
   box install wheels-cli
   ```

3. **Create Your First App**:
   ```bash
   wheels new myapp
   cd myapp
   box server start
   ```

4. **Explore Commands**:
   ```bash
   wheels --help
   wheels generate --help
   wheels dbmigrate --help
   ```

## Version Compatibility

| Wheels CLI | Wheels | CommandBox | CFML Engine |
|------------|----------|------------|-------------|
| 3.0.x | 2.5+ | 5.0+ | Lucee 5.3+, Adobe 2018+ |
| 2.0.x | 2.0-2.4 | 4.0+ | Lucee 5.2+, Adobe 2016+ |

## Community & Support

- **Documentation**: [https://wheels.dev/docs](https://wheels.dev/docs)
- **GitHub**: [https://github.com/wheels-dev/wheels](https://github.com/wheels-dev/wheels)
- **Slack**: [CFML Slack](https://cfml.slack.com) - #wheels channel
- **Forums**: [https://groups.google.com/forum/#!forum/wheels](https://groups.google.com/forum/#!forum/wheels)

## Contributing

We welcome contributions! See our [Contributing Guide](/v3-0-0/command-line-tools/CONTRIBUTING/) for details on:
- Reporting issues
- Suggesting features
- Submitting pull requests
- Creating custom commands

## Recent Updates

### Version 3.0.0
- Modernized service architecture
- Enhanced testing capabilities with watch mode
- Security scanning and performance optimization
- Plugin and environment management
- Improved code generation with more options
- Better error handling and user feedback
- Comprehensive documentation

## Quick Links

- [All Commands](/v3-0-0/command-line-tools/commands/) - Complete command reference
- [Quick Start](/v3-0-0/command-line-tools/guides/quick-start/) - Get started in minutes
- [Creating Commands](/v3-0-0/command-line-tools/guides/creating-commands/) - Extend the CLI
- [Service Architecture](/v3-0-0/command-line-tools/guides/service-architecture/) - Technical deep dive
- [Testing Guide](/v3-0-0/command-line-tools/guides/testing/) - Testing best practices

## License

Wheels CLI is open source software licensed under the Apache License 2.0. See [LICENSE](../LICENSE) for details.

---

Ready to get started? Head to the [Quick Start Guide](/v3-0-0/command-line-tools/guides/quick-start/) or explore the [Command Reference](/v3-0-0/command-line-tools/commands/).
