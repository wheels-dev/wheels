# AI CLI Reference for Wheels Framework

This guide provides AI assistants with comprehensive CLI command reference for the Wheels framework, including syntax, examples, and common patterns.

## Table of Contents
- [CommandBox Basics](#commandbox-basics)
- [Wheels CLI Commands](#wheels-cli-commands)
- [Generator Commands](#generator-commands)
- [Database Commands](#database-commands)
- [Testing Commands](#testing-commands)
- [Environment Commands](#environment-commands)
- [Development Commands](#development-commands)
- [Analysis and Optimization Commands](#analysis-and-optimization-commands)
- [Common Command Sequences](#common-command-sequences)
- [Parameter Inconsistencies](#parameter-inconsistencies)
- [Troubleshooting](#troubleshooting)

## CommandBox Basics

### Installation and Setup

```bash
# Install CommandBox (if not installed)
brew install commandbox  # macOS
# or
curl -fsSl https://downloads.ortussolutions.com/debs/gpg | sudo apt-key add -
echo "deb https://downloads.ortussolutions.com/debs/noarch /" | sudo tee -a /etc/apt/sources.list.d/commandbox.list
sudo apt-get update && sudo apt-get install commandbox  # Ubuntu/Debian

# Install Wheels dependencies
box install

# Start CommandBox shell
box

# Check to see if Commandbox is installed
box version

# Exit CommandBox shell
exit
```

### Key CommandBox Concepts

1. **Named Parameters**: CommandBox requires named parameters (key=value)
2. **Boolean Shortcuts**: Use `--flag` as shortcut for `flag=true`
3. **Working Directory**: Commands run in current directory
4. **Reload Requirement**: After modifying CLI code, run `box reload`

## Wheels CLI Commands

### Running Wheels CLI commands
The Wheels CLI commands need to be run in the bash/command shell. They can be run from the main OS shell by
prefixing the commands with the box command i.e. box wheels version from the os shell or you can launch
commandbox by entering box and then entering the Wheels CLI command in the box shell i.e. box followed by
wheels version.

### Installation

```bash
# Check to see if Wheels CLI module is installed
box wheels version

# Install Wheels CLI module (usually automatic with box install)
box install cfwheels-cli

# Verify installation
wheels version

# Get help
wheels help
wheels help [command]
```

## Generator Commands

### Generate Application

```bash
# Basic app generation
wheels g app myapp

# With template
wheels g app myapp template=wheels-base-template@BE

# In specific directory
wheels g app name=myapp directory=./projects/

# With datasource
wheels g app myapp datasourceName=mydb

# With Bootstrap and H2 database
wheels g app myapp --useBootstrap --setupH2

# With custom CFML engine
wheels g app myapp cfmlEngine=adobe@2023
```

### Generate Application Wizard

```bash
# Interactive wizard for creating new app (recommended for beginners)
wheels new

# Alternative commands (all call the same wizard)
wheels g app-wizard
wheels generate app-wizard

# Force installation in non-empty directory
wheels new --force
```

The wizard will interactively ask for:
- Application name
- Template to use
- Reload password
- Datasource name
- CFML engine preference
- H2 database setup (Lucee only)
- Bootstrap setup
- Package initialization

### Generate Controller

```bash
# Basic controller
wheels g controller Users

# With actions
wheels g controller Users index,show,new,create,edit,update,delete

# Namespaced controller
wheels g controller name=Admin/Users actions=index,show

# RESTful controller with CRUD actions
wheels g controller Users --rest

# API controller (no view actions)
wheels g controller Api/Users --api
```

### Generate Model

```bash
# Basic model
wheels g model User

# With properties
wheels g model User name:string,email:string,password:string

# With associations
wheels g model Post title:string,content:text,userId:integer

# Skip migration
wheels g model User --migration=false

# Force overwrite
wheels g model User --force

# With relationships
wheels g model Post --belongsTo=User --hasMany=Comments

# With custom table name
wheels g model User --tableName=app_users
```

### Generate Scaffold

```bash
# Complete CRUD scaffold
wheels g scaffold Product name:string,price:decimal,description:text

# With namespace
wheels g scaffold name=Admin/Product properties=name:string,price:decimal

# API scaffold (no views)
wheels g scaffold Product --properties="name:string,price:decimal" --api

# With relationships
wheels g scaffold Post --properties="title:string,content:text" --belongsTo=User --hasMany=Comments

# With migration auto-run
wheels g scaffold Product --properties="name:string,price:decimal" --migrate
```

### Generate View

```bash
# Single view
wheels g view users index

# Multiple views
wheels g view users index,show,edit,new

# With layout
wheels g view users index layout=admin

# Partial
wheels g view users _form
```

### Generate Migration

```bash
# Create table migration
wheels dbmigrate create table name=users

# Add column migration
wheels dbmigrate create column name=AddEmailToUsers

# Create blank migration
wheels dbmigrate create blank name=UpdateUserData

# Remove table migration
wheels dbmigrate remove table name=old_users
```

### Generate Test

```bash
# Model test
wheels g test model User

# Controller test
wheels g test controller Users

# Integration test
wheels g test integration UserRegistration

# Helper test
wheels g test helper Format
```

### Generate Snippets

```bash
# Copy template snippets to app/snippets/ directory
wheels g snippets

# Alternative command
wheels generate snippets
```

This command copies template snippets to your application that can be used as templates for generating code. The snippets are placed in the `app/snippets/` directory.

## Database Commands

### Migration Management

```bash
# Run all pending migrations
wheels dbmigrate latest

# Run next migration
wheels dbmigrate up

# Run specific migration version
wheels dbmigrate exec 001

# Show migration status
wheels dbmigrate info

# Show migration status
wheels dbmigrate info
```

### Rollback Migrations

```bash
# Rollback last migration
wheels dbmigrate down

# Reset all migrations (rollback all)
wheels dbmigrate reset
```

### Database Utilities

```bash
# Reset all migrations (rollback all)
wheels dbmigrate reset

# Export database schema
wheels db schema

# Seed database
wheels db seed
```

## Testing Commands

### Running Tests

```bash
# DEPRECATED: The 'wheels test' command is deprecated. Use 'wheels test run' instead.

# Run all tests (new command)
wheels test run

# Run all tests (deprecated)
wheels test app

# Run specific test file
wheels test run --filter=UserTest

# Run test group
wheels test run --group=models

# Run with coverage
wheels test run --coverage

# Run with different reporter
wheels test run --reporter=junit

# Watch mode
wheels test run --watch

# Stop on first failure
wheels test run --failFast
```

### TestBox Integration

```bash
# Run TestBox directly
box testbox run

# With coverage
box testbox run --coverage --coverageReporter=html

# Watch mode
box testbox watch

# Run specific directory
box testbox run --directory=tests/specs/unit

# Run specific bundles
box testbox run --bundles=tests.specs.models.UserTest

# Run with labels
box testbox run --labels=critical

# Exclude labels
box testbox run --excludeLabels=slow
```

## Environment Commands

### Environment Management

```bash
# Show current environment
wheels get environment

# Set environment
wheels set environment development
wheels set environment testing
wheels set environment production

# Reload application
wheels reload
wheels reload development
wheels reload force=true
```

### Configuration

```bash
# Show settings
wheels get settings

# Show specific setting
wheels get settings cacheQueries

# Set configuration value
wheels set settings cacheQueries false

# Show routes
wheels routes

# Show route details
wheels routes name=users
```

## Development Commands

### Server Management

```bash
# Start server
server start

# Start with specific port
server start port=3000

# Start with specific engine
server start cfengine=lucee@5.3.9

# Stop server
server stop

# Restart server
server restart

# Show server status
server status

# Open browser
server open
```

### Code Formatting

```bash
# Format code
box run-script format

# Check formatting
box run-script format:check

# Watch mode
box run-script format:watch

# Format specific file
box cfformat path/to/file.cfc

# Format directory
box cfformat app/**/*.cfc
```

### Package Management

```bash
# Install dependencies
box install

# Install specific package
box install cfwheels

# Install and save as dependency
box install cfwheels --save

# Install development dependency
box install testbox --saveDev

# Update packages
box update

# List installed packages
box list
```

## Analysis and Optimization Commands

### Application Analysis

```bash
# Analyze all aspects (performance, code quality, security)
wheels analyze

# Analyze specific aspect
wheels analyze performance
wheels analyze code
wheels analyze security

# With options
wheels analyze --type=all --report --format=html
wheels analyze --path=app/models --format=json
wheels analyze performance --report --format=console
```

The analyze command provides comprehensive analysis of your application:
- **Performance**: Identifies slow queries, N+1 problems, caching opportunities
- **Code Quality**: Detects code smells, complexity issues, best practice violations
- **Security**: Scans for common vulnerabilities like SQL injection, XSS

### Performance Optimization

```bash
# Show optimization help and available commands
wheels optimize

# Run performance optimization analysis
wheels optimize performance
wheels optimize performance --analysis
wheels optimize performance --cache --apply
```

**Note**: This feature is currently under development. It will provide:
- Cache configuration optimization
- Asset optimization (minification, bundling)
- Database query optimization
- Index recommendations

### Security Scanning

```bash
# Show security help and available commands
wheels security

# Run security scan
wheels security scan
wheels security scan --fix
wheels security scan --path=models --severity=high
wheels security scan --report=html --output=security-report.html
```

**Note**: This feature is currently under development. It will detect:
- SQL Injection vulnerabilities
- Cross-Site Scripting (XSS)
- Hardcoded credentials
- File upload vulnerabilities
- Directory traversal issues

### File Watching

```bash
# Basic file watching with auto-reload
wheels watch

# Watch with specific options
wheels watch --reload --tests
wheels watch --includeDirs=controllers,models --excludeFiles=*.txt,*.log
wheels watch --interval=2 --command="wheels test run"

# Watch and run tests on changes
wheels watch --tests

# Watch and run migrations on schema changes
wheels watch --migrations

# Custom command on file changes
wheels watch --command="box run-script build"
```

Options:
- `--includeDirs`: Directories to watch (default: controllers,models,views,config,migrator/migrations)
- `--excludeFiles`: File patterns to ignore
- `--interval`: Check interval in seconds (default: 1)
- `--reload`: Reload framework on changes (default: true)
- `--tests`: Run tests on changes
- `--migrations`: Run migrations on schema changes
- `--command`: Custom command to run on changes
- `--debounce`: Debounce delay in milliseconds (default: 500)

## Common Command Sequences

### New Project Setup

```bash
# 1. Create project directory
mkdir myproject && cd myproject

# 2. Initialize Wheels
wheels g app myproject

# 3. Install dependencies
box install

# 4. Setup database (H2 is setup by default)
# For other databases, configure datasource in Admin or .cfconfig.json

# 5. Run migrations
wheels dbmigrate latest

# 6. Start server
server start
```

### Adding New Feature

```bash
# 1. Generate model with migration
wheels g model Article title:string,content:text,authorId:integer

# 2. Run migration
wheels dbmigrate latest

# 3. Generate controller with views
wheels g controller Articles index,show,new,create,edit,update,delete

# 4. Generate tests
wheels g test model Article
wheels g test controller Articles

# 5. Run tests
wheels test app
```

### Testing Workflow

```bash
# 1. Start test watcher
box testbox watch

# 2. Make changes (in another terminal)
# Edit files...

# 3. Run specific test after changes
wheels test app ArticleTest

# 4. Run all tests before commit
box testbox run

# 5. Check code formatting
box run-script format:check
```

### Docker Testing

```bash
# 1. Start all test databases
docker compose up -d

# 2. Run tests against specific engine
docker compose --profile lucee up -d
wheels test app

# 3. Switch to Adobe CF
docker compose --profile adobe2023 up -d
wheels test app

# 4. Access TestUI
open http://localhost:3000
```

## Parameter Inconsistencies

### Known Inconsistencies

1. **Case Sensitivity**
   ```bash
   # Some commands use camelCase
   wheels g model userId:integer

   # Others use kebab-case
   wheels g migration add-index-to-users
   ```

2. **Boolean Parameters**
   ```bash
   # Some accept --flag
   wheels g model User --migration=false

   # Others require explicit
   wheels reload force=true
   ```

3. **Parameter Names**
   ```bash
   # 'name' vs direct argument
   wheels g controller Users  # Works
   wheels g controller name=Users  # Also works

   # But dbmigrate commands require name
   wheels dbmigrate create blank name=CreateUsers  # Required
   ```

### Best Practices

1. **Always use named parameters for consistency**
   ```bash
   wheels g model name=User properties=name:string,email:string
   ```

2. **Use --flag for boolean true**
   ```bash
   wheels g scaffold Product --force --tests=false
   ```

3. **Quote complex values**
   ```bash
   wheels g controller name=Users actions="index,show,new,create"
   ```

## Troubleshooting

### Command Not Found

```bash
# If 'wheels' command not found
box install cfwheels-cli --force
box reload

# Verify installation
which wheels
wheels version
```

### Parameter Errors

```bash
# Error: Missing required parameter
wheels g model
# Fix: Add required name
wheels g model name=User

# Error: Invalid parameter format
wheels g model User properties=name,email
# Fix: Specify types
wheels g model User properties=name:string,email:string
```

### Database Connection Issues

```bash
# Error: Datasource not found
# Fix: Configure datasource
wheels set datasource myapp

# Error: Database doesn't exist
# Fix: Create database
wheels db create

# Error: Migrations table missing
# Fix: Initialize migrations
wheels db migrate version=0
```

### Testing Issues

```bash
# Error: Test not found
# Fix: Use correct path or name
wheels test app tests/specs/models/UserTest.cfc

# Error: TestBox not found
# Fix: Install TestBox
box install testbox --saveDev

# Error: BaseSpec not found
# Fix: Ensure test extends correct path
# component extends="tests.BaseSpec"
```

### CLI Module Issues

```bash
# After modifying CLI code
box reload

# If changes don't take effect
box restart

# Complete reinstall
box uninstall cfwheels-cli
box install cfwheels-cli
```

## Advanced Usage

### Custom Templates

```bash
# Use custom template for generation
wheels g app myapp template=https://github.com/myrepo/template.git

# Local template
wheels g app myapp template=../my-template/
```

### Environment Variables

```bash
# Set environment variables
wheels set environment=production
wheels set datasource=productionDB

# Use in commands
WHEELS_ENV=testing wheels test app
```

### Scripting

```bash
# Create setup script
#!/bin/bash
wheels g app myapp
cd myapp
box install
wheels db create
wheels db migrate
server start
```

### Aliases

```bash
# Add to ~/.bashrc or ~/.zshrc
alias wt='wheels test app'
alias wm='wheels db migrate'
alias wr='wheels reload'
alias wdev='wheels set environment development && wheels reload'
alias wprod='wheels set environment production && wheels reload'
```

This comprehensive CLI reference should help AI assistants understand and use all available Wheels commands effectively.
