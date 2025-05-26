# CLI Commands

The Wheels Command Line Interface (CLI) provides a comprehensive set of tools that streamline development, testing, deployment, and maintenance of Wheels applications. Built as a CommandBox module, the Wheels CLI brings modern development workflows to CFML developers, inspired by tools like Ruby on Rails' command line interface.

## Overview

The Wheels CLI transforms how you interact with your Wheels applications by providing powerful commands for:

- **Rapid Application Development** - Generate new applications, controllers, models, views, and complete scaffolds
- **Database Management** - Create and run migrations, manage schemas, and seed data
- **Testing and Quality** - Run tests, generate coverage reports, and analyze code quality
- **Deployment and DevOps** - Docker integration, CI/CD configuration, and environment management
- **Performance and Security** - Analyze performance bottlenecks and scan for vulnerabilities
- **Plugin Management** - Install, update, and manage Wheels plugins from ForgeBox

## Prerequisites

### Installing CommandBox

The Wheels CLI requires [CommandBox](https://www.ortussolutions.com/products/commandbox), a powerful CFML development tool that provides:

- CFML script execution at the command line
- Embedded servers (both Lucee and Adobe ColdFusion)
- Package management for CFML modules
- Task runners and automation tools

Install CommandBox using your operating system's package manager:

{% tabs %}
{% tab title="Windows (Chocolatey)" %}
```powershell
choco install commandbox
```
{% endtab %}

{% tab title="macOS (Homebrew)" %}
```bash
brew install commandbox
```
{% endtab %}

{% tab title="Linux (apt)" %}
```bash
curl -fsSL https://downloads.ortussolutions.com/debs/gpg | sudo apt-key add -
echo "deb https://downloads.ortussolutions.com/debs/noarch /" | sudo tee -a /etc/apt/sources.list.d/commandbox.list
sudo apt-get update && sudo apt-get install commandbox
```
{% endtab %}
{% endtabs %}

Verify your installation:

```bash
box version
```

### Installing the Wheels CLI

Once CommandBox is installed, add the Wheels CLI module:

```bash
box install wheels-cli
```

This adds all Wheels-specific commands to your CommandBox installation, prefixed with the `wheels` namespace.

## Command Structure

Wheels CLI commands follow a consistent structure:

```bash
wheels [command] [subcommand] [arguments] [flags]
```

### Command Namespaces

Commands are organized into logical namespaces:

- **Core Commands** - `wheels init`, `wheels info`, `wheels reload`, etc.
- **Generation** - `wheels generate` (aliased as `wheels g`)
- **Database** - `wheels dbmigrate` and `wheels db`
- **Testing** - `wheels test`
- **Analysis** - `wheels analyze`
- **Security** - `wheels security`
- **Deployment** - `wheels deploy`, `wheels docker`, `wheels ci`
- **Configuration** - `wheels config`, `wheels env`
- **Plugins** - `wheels plugins`

### Common Patterns

Most generation commands support these common flags:

- `--force` - Overwrite existing files
- `--dry-run` - Preview changes without applying them
- `--quiet` - Suppress output
- `--help` - Display command-specific help

### Environment Variables

The CLI respects these environment variables:

- `WHEELS_ENV` - Default environment (development, testing, production)
- `WHEELS_DATASOURCE` - Default database datasource name
- `WHEELS_RELOAD_PASSWORD` - Password for reloading applications

## Quick Start Examples

### Create a New Application

```bash
wheels new myapp
```

This launches an interactive wizard that guides you through creating a new Wheels application.

### Generate a Complete Resource

```bash
wheels scaffold Product name:string price:decimal description:text
```

This single command creates:
- Model with properties
- Database migration
- Controller with CRUD actions
- Views for all actions
- Routes configuration
- Test files

### Run Database Migrations

```bash
wheels dbmigrate latest
```

Migrates your database to the latest version.

### Run Tests

```bash
wheels test app
```

Runs all application tests and displays results.

## Command Categories

The Wheels CLI provides commands in these categories:

1. **[Core Commands](wheels-core-commands.md)** - Essential commands for application management
2. **[Generation Commands](wheels-generate-commands.md)** - Code generators for rapid development
3. **[Database Commands](wheels-dbmigrate-commands.md)** - Database migrations and management
4. **[Testing Commands](wheels-testing-commands.md)** - Test execution and coverage
5. **[Configuration Commands](wheels-configuration-commands.md)** - Environment and settings management
6. **[Analysis Commands](wheels-analysis-commands.md)** - Code quality and performance analysis
7. **[Deployment Commands](wheels-deployment-commands.md)** - Docker, CI/CD, and deployment tools
8. **[Plugin Commands](wheels-plugins-commands.md)** - Plugin installation and management

## Interactive vs Direct Execution

You can use Wheels CLI commands in two ways:

### Interactive CommandBox Shell

Launch the CommandBox shell and run commands directly:

```bash
box
CommandBox> wheels info
CommandBox> wheels g controller Products
CommandBox> exit
```

### Direct Execution

Run commands directly from your system terminal:

```bash
box wheels info
box wheels g controller Products
```

## Getting Help

Every command includes built-in help:

```bash
wheels help
wheels generate help
wheels g controller --help
```

## Best Practices

1. **Use Aliases** - Save time with command aliases like `g` for `generate`
2. **Leverage Tab Completion** - CommandBox provides tab completion for commands
3. **Create Scripts** - Combine commands in CommandBox task runners
4. **Check Status First** - Use `wheels info` to verify your environment
5. **Preview Changes** - Use `--dry-run` to preview destructive operations

## Troubleshooting

### Common Issues

**Port Detection Errors**: Some commands may fail to detect the server port. Ensure your server.json file contains the correct port configuration.

**Permission Errors**: On Unix-based systems, you may need to use `sudo` for certain operations or ensure proper file permissions.

**Module Not Found**: If commands aren't recognized, reinstall the wheels-cli module:
```bash
box uninstall wheels-cli
box install wheels-cli
```

### Debug Mode

Enable debug output for troubleshooting:
```bash
wheels [command] --debug
```

## Next Steps

Explore the detailed documentation for each command category:

* [Core Commands](wheels-core-commands.md) - Start here for essential commands
* [Generation Commands](wheels-generate-commands.md) - Learn about code generation
* [Database Commands](wheels-dbmigrate-commands.md) - Master database migrations
* [Testing Commands](wheels-testing-commands.md) - Set up your testing workflow