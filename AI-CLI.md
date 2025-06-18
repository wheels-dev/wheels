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

# Exit CommandBox shell
exit
```

### Key CommandBox Concepts

1. **Named Parameters**: CommandBox requires named parameters (key=value)
2. **Boolean Shortcuts**: Use `--flag` as shortcut for `flag=true`
3. **Working Directory**: Commands run in current directory
4. **Reload Requirement**: After modifying CLI code, run `box reload`

## Wheels CLI Commands

### Installation

```bash
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
wheels g app myapp template=default

# In specific directory
wheels g app name=myapp directory=./projects/

# With datasource
wheels g app myapp datasource=mydb
```

### Generate Controller

```bash
# Basic controller
wheels g controller Users

# With actions
wheels g controller Users index,show,new,create,edit,update,delete

# Namespaced controller
wheels g controller name=Admin/Users actions=index,show

# With custom format
wheels g controller name=Api/Users format=json
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
wheels g model User --skip-migration

# Force overwrite
wheels g model User --force
```

### Generate Scaffold

```bash
# Complete CRUD scaffold
wheels g scaffold Product name:string,price:decimal,description:text

# With namespace
wheels g scaffold name=Admin/Product properties=name:string,price:decimal

# API scaffold
wheels g scaffold name=Api/Product properties=name:string format=json
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
wheels g migration CreateUsers

# Add column migration
wheels g migration AddEmailToUsers

# Remove column migration
wheels g migration RemovePasswordFromUsers

# Index migration
wheels g migration AddIndexToUsersEmail

# Custom migration
wheels g migration UpdateUserData
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

# Create database
wheels db create
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
# Drop database
wheels db drop

# Reset database migrations
wheels dbmigrate reset

# Seed database
wheels db seed

# Open database console
wheels db console
```

## Testing Commands

### Running Tests

```bash
# Run all tests
wheels test app

# Run specific test file
wheels test app UserTest

# Run test bundle
wheels test app testBundles=models

# Run specific test spec
wheels test app testBundles=models&testSpecs=shouldValidateEmail

# Run with reporter
wheels test app reporter=simple

# Run tests in directory
wheels test app directory=tests/specs/unit
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

## Common Command Sequences

### New Project Setup

```bash
# 1. Create project directory
mkdir myproject && cd myproject

# 2. Initialize Wheels
wheels g app myproject

# 3. Install dependencies
box install

# 4. Create database
wheels db create

# 5. Run migrations
wheels db migrate

# 6. Start server
server start
```

### Adding New Feature

```bash
# 1. Generate model with migration
wheels g model Article title:string,content:text,authorId:integer

# 2. Run migration
wheels db migrate

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
   wheels g model User --skip-migration
   
   # Others require explicit
   wheels reload force=true
   ```

3. **Parameter Names**
   ```bash
   # 'name' vs direct argument
   wheels g controller Users  # Works
   wheels g controller name=Users  # Also works
   
   # But migrations require name
   wheels g migration name=CreateUsers  # Required
   ```

### Best Practices

1. **Always use named parameters for consistency**
   ```bash
   wheels g model name=User properties=name:string,email:string
   ```

2. **Use --flag for boolean true**
   ```bash
   wheels g scaffold Product --force --skip-tests
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