# CFWheels CLI Commands Master List

This document provides a comprehensive list of all available CLI commands in the CFWheels framework.

## Core Commands

| Command | Description |
|---------|-------------|
| `wheels init` | Initialize a new CFWheels application |
| `wheels info` | Display information about the CFWheels installation |
| `wheels deps` | Manage dependencies |
| `wheels destroy` | Destroy/remove CFWheels components |
| `wheels reload` | Reload the CFWheels application |
| `wheels watch` | Watch for file changes and auto-reload |
| `wheels scaffold` | Generate complete CRUD scaffolding |

## Analysis Commands

| Command | Description |
|---------|-------------|
| `wheels analyze` | Run code analysis (parent command) |
| `wheels analyze code` | Analyze code quality |
| `wheels analyze performance` | Analyze performance issues |
| `wheels analyze security` | Analyze security vulnerabilities |

## Configuration Commands

| Command | Description |
|---------|-------------|
| `wheels config env` | Manage environment configuration |
| `wheels config list` | List all configuration settings |
| `wheels config set` | Set configuration values |

## Database Commands

| Command | Description |
|---------|-------------|
| `wheels db schema` | Manage database schema |
| `wheels db seed` | Seed database with test/initial data |

## Database Migration Commands

| Command | Description |
|---------|-------------|
| `wheels dbmigrate up` | Run pending migrations |
| `wheels dbmigrate down` | Rollback migrations |
| `wheels dbmigrate exec` | Execute specific migrations |
| `wheels dbmigrate info` | Display migration information and status |
| `wheels dbmigrate latest` | Run all migrations to latest version |
| `wheels dbmigrate reset` | Reset all migrations |
| `wheels dbmigrate create blank` | Create a blank migration file |
| `wheels dbmigrate create column` | Create a migration to add column |
| `wheels dbmigrate create table` | Create a migration to add table |
| `wheels dbmigrate remove table` | Create a migration to remove table |

## Deployment Commands

| Command | Description |
|---------|-------------|
| `wheels deploy` | Main deployment command |
| `wheels deploy audit` | Audit deployment configuration |
| `wheels deploy exec` | Execute deployment tasks |
| `wheels deploy hooks` | Manage deployment hooks |
| `wheels deploy init` | Initialize deployment setup |
| `wheels deploy lock` | Lock deployment to prevent changes |
| `wheels deploy logs` | View deployment logs |
| `wheels deploy proxy` | Manage deployment proxy settings |
| `wheels deploy push` | Push deployment to server |
| `wheels deploy rollback` | Rollback to previous deployment |
| `wheels deploy secrets` | Manage deployment secrets |
| `wheels deploy setup` | Setup deployment environment |
| `wheels deploy status` | Check deployment status |
| `wheels deploy stop` | Stop current deployment |

## Docker Commands

| Command | Description | Status |
|---------|-------------|--------|
| `wheels docker init` | Initialize Docker configuration | ⚠️ Disabled |
| `wheels docker deploy` | Deploy using Docker | ⚠️ Disabled |

## Documentation Commands

| Command | Description |
|---------|-------------|
| `wheels docs` | Documentation management |
| `wheels docs generate` | Generate documentation from code |
| `wheels docs serve` | Serve documentation locally |

## Environment Commands

| Command | Description |
|---------|-------------|
| `wheels env` | Environment management |
| `wheels env list` | List available environments |
| `wheels env setup` | Setup new environment |
| `wheels env switch` | Switch between environments |

## Code Generation Commands

| Command | Description |
|---------|-------------|
| `wheels generate app` | Generate application structure |
| `wheels generate app-wizard` | Interactive application generator |
| `wheels generate controller` | Generate a controller |
| `wheels generate model` | Generate a model |
| `wheels generate property` | Generate model property |
| `wheels generate resource` | Generate complete resource (model, controller, views) |
| `wheels generate route` | Generate route configuration |
| `wheels generate snippets` | Generate code snippets |
| `wheels generate test` | Generate test files |
| `wheels generate view` | Generate view files |
| `wheels generate api-resource` | Generate API resource | ⚠️ Broken |
| `wheels generate frontend` | Generate frontend assets | ⚠️ Disabled |

## Optimization Commands

| Command | Description |
|---------|-------------|
| `wheels optimize` | Optimization tools |
| `wheels optimize performance` | Optimize application performance |

## Plugin Commands

| Command | Description |
|---------|-------------|
| `wheels plugins` | Plugin management |
| `wheels plugins install` | Install a plugin |
| `wheels plugins list` | List installed plugins |
| `wheels plugins remove` | Remove a plugin |

## Security Commands

| Command | Description |
|---------|-------------|
| `wheels security` | Security tools |
| `wheels security scan` | Scan for security vulnerabilities |

## Testing Commands

| Command | Description |
|---------|-------------|
| `wheels test` | Test execution |
| `wheels test run` | Run test suite |
| `wheels test coverage` | Generate test coverage report |
| `wheels test debug` | Debug tests with detailed output |

## CI/CD Commands

| Command | Description | Status |
|---------|-------------|--------|
| `wheels ci init` | Initialize CI/CD configuration | ⚠️ Disabled |

## Command Structure

The CLI follows a hierarchical structure:
- Base commands (e.g., `wheels init`)
- Category commands (e.g., `wheels generate`)
- Sub-commands (e.g., `wheels generate model`)

## Notes

- Commands marked with ⚠️ are currently disabled or have issues
- Some commands have `.disabled` or `.bak` versions indicating they're under development
- All commands extend from `base.cfc` which provides common functionality
- The CLI uses CommandBox for execution

## Usage Examples

```bash
# Initialize a new application
wheels init myapp

# Generate a model
wheels generate model User

# Run database migrations
wheels dbmigrate up

# Run tests
wheels test run

# Generate complete CRUD scaffolding
wheels scaffold Product name,price,description
```

## See Also

- [CLI Overview](../guides/command-line-tools/cli-overview.md)
- [Quick Start Guide](../guides/command-line-tools/quick-start.md)
- Individual command documentation in `/guides/command-line-tools/commands/`