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

### 📚 [Command Reference](commands/README.md)
Complete reference for all CLI commands organized by category:
- [Core Commands](commands/core/init.md) - Essential commands like init, reload, watch
- [Code Generation](commands/generate/app.md) - Generate applications, models, controllers, views
- [Database Commands](commands/database/database-management.md) - Complete database management and migrations
- [Testing Commands](commands/testing/test.md) - Run tests and generate coverage
- [Configuration](commands/config/config-list.md) - Manage application settings
- [And more...](commands/README.md)

### 🚀 [Quick Start Guide](guides/quick-start.md)
Get up and running with Wheels CLI in minutes. Learn how to:
- Install Wheels CLI
- Create your first application
- Generate CRUD scaffolding
- Run tests and migrations

### 📖 Guides

#### Development Guides
- [Service Architecture](guides/service-architecture.md) - Understand the CLI's architecture
- [Creating Custom Commands](guides/creating-commands.md) - Extend the CLI with your own commands
- [Template System](guides/template-system.md) - Customize code generation templates
- [Testing Guide](guides/testing.md) - Write and run tests effectively

#### Best Practices
- [Migration Guide](guides/migrations.md) - Database migration best practices
- [Security Guide](guides/security.md) - Security scanning and hardening
- [Performance Guide](guides/performance.md) - Optimization techniques

### 📋 Reference
- [Configuration Options](reference/configuration.md) - All available configuration settings
- [Template Variables](reference/templates.md) - Variables available in templates
- [Exit Codes](reference/exit-codes.md) - Understanding command exit codes
- [Environment Variables](reference/environment-variables.md) - Environment configuration

## Key Features

### 🛠️ Code Generation (Coming Soon)

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

### 🗄️ Database Management (Coming Soon)

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

### 🧪 Testing (Coming Soon)

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

### 👀 Development Tools

Enhance your development workflow:

```bash
# Watch for file changes
wheels watch

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

We welcome contributions! See our [Contributing Guide](CONTRIBUTING.md) for details on:
- Reporting issues
- Suggesting features
- Submitting pull requests
- Creating custom commands

## Recent Updates

### Version 3.0.0
- 🆕 Modernized service architecture
- 🆕 Enhanced testing capabilities with watch mode
- 🆕 Security scanning and performance optimization
- 🆕 Plugin and environment management
- 🆕 Improved code generation with more options
- 🔧 Better error handling and user feedback
- 📚 Comprehensive documentation

## Quick Links

- [All Commands](commands/README.md) - Complete command reference
- [Quick Start](guides/quick-start.md) - Get started in minutes
- [Creating Commands](guides/creating-commands.md) - Extend the CLI
- [Service Architecture](guides/service-architecture.md) - Technical deep dive
- [Testing Guide](guides/testing.md) - Testing best practices

## License

Wheels CLI is open source software licensed under the Apache License 2.0. See [LICENSE](../LICENSE) for details.

---

Ready to get started? Head to the [Quick Start Guide](guides/quick-start.md) or explore the [Command Reference](commands/README.md).
