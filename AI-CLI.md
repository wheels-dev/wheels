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
- [Asset and Cache Management Commands](#asset-and-cache-management-commands)
- [Plugin Management](#plugin-management)
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

### Generate Migration (Enhanced)

```bash
# Create table migration
wheels g migration CreateUsersTable
wheels g migration CreateUsersTable --create=users
wheels g migration CreateProductsTable --attributes="name:string,price:decimal,inStock:boolean"

# Add column migration
wheels g migration AddEmailToUsers
wheels g migration AddEmailToUsers --table=users --attributes="email:string:index,verified:boolean"

# Remove column migration
wheels g migration RemoveAgeFromUsers
wheels g migration RemoveAgeFromUsers --table=users

# Change column migration
wheels g migration ChangeNameInUsers --table=users

# Add index migration
wheels g migration CreateIndexOnUsersEmail --table=users

# Custom migration
wheels g migration CustomDataMigration --up="/* custom up code */" --down="/* custom down code */"
```

### Generate Mailer

```bash
# Basic mailer
wheels g mailer Welcome

# With multiple methods
wheels g mailer UserNotifications --methods="accountCreated,passwordReset,orderConfirmation"

# With configuration
wheels g mailer OrderMailer --from="orders@example.com" --layout="email"

# Skip view creation
wheels g mailer NotificationMailer --createViews=false
```

### Generate Service

```bash
# Basic service object
wheels g service Payment

# With methods
wheels g service UserAuthentication --methods="login,logout,register,verify"

# With dependencies
wheels g service OrderProcessing --dependencies="PaymentService,EmailService"

# As singleton
wheels g service CacheManager --type=singleton

# With description
wheels g service DataExport --description="Handles CSV and Excel exports"
```

### Generate Helper

```bash
# Basic helper
wheels g helper Format

# With specific functions
wheels g helper StringUtils --functions="truncate,highlight,slugify"

# Global helper
wheels g helper DateHelpers --global=true

# View-specific helper
wheels g helper ViewHelpers --type=view

# Controller-specific helper
wheels g helper AuthHelpers --type=controller
```

### Generate Job

```bash
# Basic background job
wheels g job ProcessOrders

# With queue configuration
wheels g job SendNewsletters --queue=emails --priority=high

# Scheduled job (cron expression)
wheels g job CleanupOldRecords --schedule="0 0 * * *"

# With delay
wheels g job DataSync --delay=3600

# With retries and timeout
wheels g job ImportData --retries=5 --timeout=600
```

### Generate Plugin

```bash
# Basic plugin scaffold
wheels g plugin Authentication

# With version and author
wheels g plugin ImageProcessor --version="1.0.0" --author="John Doe"

# With methods
wheels g plugin CacheManager --methods="init,configure,process"

# With dependencies
wheels g plugin APIConnector --dependencies="wheels-http-client"

# With mixin types
wheels g plugin FormValidation --mixin="controller,model"
```

## Database Commands

### Database Management

```bash
# Create database
wheels db create
wheels db create --datasource=myapp_dev
wheels db create --environment=production

# Drop database (with confirmation)
wheels db drop
wheels db drop --datasource=myapp_dev
wheels db drop --force  # Skip confirmation

# Setup database (create + migrate + seed)
wheels db setup
wheels db setup --skip-seed
wheels db setup --seed-count=10

# Reset database (drop + create + migrate + seed)
wheels db reset
wheels db reset --force  # Skip confirmation
wheels db reset --skip-seed
wheels db reset --environment=production

# Seed database with test data
wheels db seed
wheels db seed --count=10  # Records per model
wheels db seed --models=user,post  # Specific models
wheels db seed --dataFile=seeds.json  # From file

# Show migration status
wheels db status
wheels db status --format=json
wheels db status --pending  # Only pending migrations

# Show current database version
wheels db version
wheels db version --detailed

# Rollback migrations
wheels db rollback  # Rollback one migration
wheels db rollback --steps=3  # Rollback 3 migrations
wheels db rollback --target=20231201120000  # To specific version

# Export database
wheels db dump
wheels db dump --output=backup.sql
wheels db dump --schema-only  # Structure only
wheels db dump --data-only  # Data only
wheels db dump --tables=users,posts  # Specific tables
wheels db dump --compress  # Gzip compression

# Restore database
wheels db restore backup.sql
wheels db restore backup.sql.gz --compressed
wheels db restore backup.sql --clean  # Drop existing objects
wheels db restore backup.sql --force  # Skip confirmation

# Launch interactive database shell
wheels db shell  # CLI shell
wheels db shell --web  # Web console (H2 only)
wheels db shell --datasource=myapp_dev
wheels db shell --command="SELECT COUNT(*) FROM users"  # Execute single command
```

### Database Shell Details

The `wheels db shell` command provides direct database access:

**H2 Database (Lucee default):**
```bash
# CLI shell - uses java -cp org.lucee.h2-*.jar org.h2.tools.Shell
wheels db shell

# Web console - launches browser interface
wheels db shell --web

# The H2 JAR is typically found in Lucee bundles as org.lucee.h2-*.jar
```

**MySQL/MariaDB:**
```bash
# Launches mysql client
wheels db shell
# Equivalent to: mysql -h host -P port -u user -p database
```

**PostgreSQL:**
```bash
# Launches psql client  
wheels db shell
# Equivalent to: psql -h host -p port -U user -d database
```

**SQL Server:**
```bash
# Launches sqlcmd client
wheels db shell  
# Equivalent to: sqlcmd -S server -d database -U user
```

**Requirements:**
- H2: No additional installation (included with Lucee)
- MySQL: Requires `mysql` client installed
- PostgreSQL: Requires `psql` client installed
- SQL Server: Requires `sqlcmd` client installed

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
```

### Rollback Migrations

```bash
# Rollback last migration
wheels dbmigrate down

# Reset all migrations (rollback all)
wheels dbmigrate reset
```

### Database Schema Utilities

```bash
# Export database schema
wheels db schema
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

### Advanced Testing (TestBox CLI Wrappers)

These commands require TestBox CLI to be installed: `box install commandbox-testbox-cli`

#### Run All Tests
```bash
# Run all tests with TestBox CLI
wheels test:all

# With specific reporter
wheels test:all --reporter=spec

# With coverage
wheels test:all --coverage --coverageReporter=html

# With filters
wheels test:all --filter=UserTest --verbose
```

#### Run Unit Tests
```bash
# Run only unit tests
wheels test:unit

# With specific reporter
wheels test:unit --reporter=spec

# Filter specific tests
wheels test:unit --filter=UserModelTest
```

#### Run Integration Tests
```bash
# Run only integration tests  
wheels test:integration

# With verbose output
wheels test:integration --verbose

# Filter specific tests
wheels test:integration --filter=UserWorkflowTest
```

#### Watch Mode
```bash
# Watch for changes and rerun tests
wheels test:watch

# Watch specific directory
wheels test:watch --directory=tests/unit

# With custom delay
wheels test:watch --delay=500

# Watch additional paths
wheels test:watch --watchPaths=models,controllers
```

#### Code Coverage
```bash
# Run tests with code coverage
wheels test:coverage

# With HTML reporter (default)
wheels test:coverage --reporter=html

# With JSON reporter
wheels test:coverage --reporter=json

# Set coverage threshold
wheels test:coverage --threshold=80

# Coverage for specific directory
wheels test:coverage --directory=tests/unit

# Specify paths to capture
wheels test:coverage --pathsToCapture=models,controllers
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

#### Legacy Commands (for backward compatibility)
```bash
# Show current environment
wheels get environment

# Set environment
wheels set environment development
wheels set environment testing
wheels set environment production
```

#### New Environment Command (Recommended)

The enhanced `wheels environment` command provides better environment management:

```bash
# Show current environment with detailed info
wheels environment

# Set environment (with automatic reload)
wheels environment set development
wheels environment set testing
wheels environment set production
wheels environment set maintenance

# Set environment without reload
wheels environment set production --reload=false

# List all available environments
wheels environment list

# Quick environment switching
wheels environment development    # Shortcut for set development
wheels environment production     # Shortcut for set production

# Reload application
wheels reload
wheels reload development
wheels reload force=true
```

### Interactive Console (REPL)

The `wheels console` command starts an interactive REPL with full Wheels application context:

```bash
# Start interactive console
wheels console

# Start console in specific environment
wheels console environment=testing

# Execute single command
wheels console execute="model('User').count()"

# Start in tag mode (default is script mode)
wheels console script=false
```

**Console Features:**
- Access to all Wheels models via `model()` function
- Direct database queries via `query()` function
- All Wheels helper functions available
- Persistent variable state between commands
- Command history
- Script and tag mode support

**Example Console Session:**
```cfscript
wheels:script> user = model("User").findByKey(1)
wheels:script> user.name = "Updated Name"
wheels:script> user.save()
wheels:script> users = model("User").findAll(where="active=1", order="createdAt DESC")
wheels:script> pluralize("person")
people
wheels:script> query("SELECT COUNT(*) as total FROM users").total
42
```

### Script Runner

The `wheels runner` command executes script files in the Wheels application context:

```bash
# Run a script file
wheels runner scripts/data-migration.cfm

# Run with specific environment
wheels runner scripts/cleanup.cfm environment=production

# Run with parameters
wheels runner scripts/import.cfm params='{"source":"data.csv","dryRun":true}'

# Run with verbose output
wheels runner scripts/process.cfm --verbose
```

**Script Features:**
- Full access to Wheels application context
- Pass parameters via JSON
- Scripts can access `request.scriptParams`
- Model and query functions available
- Execution time reporting

**Example Script:**
```cfm
<!--- scripts/cleanup-users.cfm --->
<cfscript>
// Access passed parameters
var dryRun = structKeyExists(request.scriptParams, "dryRun") ? request.scriptParams.dryRun : false;

// Use Wheels models
var inactiveUsers = request.model("User").findAll(
    where="lastLoginAt < '#dateAdd('m', -6, now())#'"
);

writeOutput("Found #inactiveUsers.recordCount# inactive users<br>");

if (!dryRun) {
    for (var user in inactiveUsers) {
        request.model("User").deleteByKey(user.id);
        writeOutput("Deleted user: #user.email#<br>");
    }
} else {
    writeOutput("Dry run - no users deleted");
}
</cfscript>
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

#### CommandBox Native Server Commands

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

#### Wheels Server Commands (Enhanced Wrappers)

The Wheels CLI provides enhanced server management commands that wrap CommandBox's native functionality with Wheels-specific checks and enhancements.

```bash
# Start Wheels development server
wheels server start

# Start with specific port
wheels server start port=8080

# Start with URL rewriting enabled
wheels server start --rewritesEnable

# Start without opening browser
wheels server start openbrowser=false

# Start with specific host
wheels server start host=0.0.0.0

# Force start even if already running
wheels server start --force

# Stop the server
wheels server stop

# Stop specific named server
wheels server stop name=myapp

# Force stop all servers
wheels server stop --force

# Restart the server (also reloads Wheels app)
wheels server restart

# Force restart
wheels server restart --force

# Show server status with Wheels info
wheels server status

# Show status in JSON format
wheels server status --json

# Show verbose status
wheels server status --verbose

# Tail server logs
wheels server log

# Show last 100 lines of logs
wheels server log lines=100

# Follow logs (default behavior)
wheels server log --follow

# Show debug-level logs
wheels server log --debug

# Open application in browser
wheels server open

# Open specific path
wheels server open /admin

# Open in specific browser
wheels server open --browser=firefox

# Display server help
wheels server
```

**Key Differences from CommandBox Native Commands:**
- Checks if current directory is a Wheels application
- Shows Wheels-specific information (version, paths)
- Automatically reloads Wheels application on restart
- Provides helpful error messages and suggestions
- Integrates with Wheels application context

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

## Asset and Cache Management Commands

### Asset Management

```bash
# Precompile assets for production
wheels assets:precompile
wheels assets:precompile --force              # Force recompilation
wheels assets:precompile --environment=staging # Target specific environment

# Clean old compiled assets
wheels assets:clean
wheels assets:clean --keep=5                  # Keep 5 versions of each asset
wheels assets:clean --dryRun                  # Preview what would be deleted

# Remove all compiled assets
wheels assets:clobber
wheels assets:clobber --force                 # Skip confirmation
```

### Cache Management

```bash
# Clear all caches
wheels cache:clear
wheels cache:clear --force                    # Skip confirmation

# Clear specific cache
wheels cache:clear query                      # Clear query cache
wheels cache:clear page                       # Clear page cache
wheels cache:clear partial                    # Clear partial/fragment cache
wheels cache:clear action                     # Clear action cache
wheels cache:clear sql                        # Clear SQL file cache

# Clear multiple caches
wheels cache:clear all                        # Clear all caches (default)
```

### Log Management

```bash
# Clear log files
wheels log:clear
wheels log:clear --environment=production     # Clear specific environment logs
wheels log:clear --days=30                    # Clear logs older than 30 days
wheels log:clear --force                      # Skip confirmation

# Tail log files
wheels log:tail
wheels log:tail --environment=production      # Tail specific environment log
wheels log:tail --lines=50                    # Show last 50 lines
wheels log:tail --follow                      # Follow log in real-time (default)
wheels log:tail --file=custom.log            # Tail specific log file
```

### Temporary Files Management

```bash
# Clear all temporary files
wheels tmp:clear
wheels tmp:clear --force                      # Skip confirmation

# Clear specific temp file types
wheels tmp:clear cache                        # Clear cache files only
wheels tmp:clear sessions                     # Clear session files only
wheels tmp:clear uploads                      # Clear upload files only

# Clear old temporary files
wheels tmp:clear --days=7                     # Clear files older than 7 days
wheels tmp:clear --type=cache --days=30      # Clear cache files older than 30 days
```

### Asset Precompilation Details

The `wheels assets:precompile` command:
- Minifies JavaScript and CSS files
- Generates cache-busted filenames with MD5 hashes
- Creates a manifest.json for asset mapping
- Optimizes images (copies with cache-busted names)
- Stores compiled assets in `/public/assets/compiled/`

**Example manifest.json:**
```json
{
  "application.js": "application-a1b2c3d4.min.js",
  "styles.css": "styles-e5f6g7h8.min.css",
  "logo.png": "logo-i9j0k1l2.png"
}
```

### Cache Types Explained

- **Query Cache**: Stores database query results
- **Page Cache**: Stores complete rendered pages
- **Partial Cache**: Stores rendered view fragments
- **Action Cache**: Stores controller action results
- **SQL Cache**: Stores parsed SQL files

### Log File Color Coding

The `wheels log:tail` command color-codes log entries:
- **Red**: ERROR level messages
- **Yellow**: WARN/WARNING level messages
- **Cyan**: INFO level messages
- **Grey**: DEBUG level messages

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

## Plugin Management

### Plugin Commands Overview

Wheels provides comprehensive plugin management through the CLI:

```bash
# Search for plugins on ForgeBox
wheels plugin search
wheels plugin search auth
wheels plugin search --format=json --orderBy=downloads

# Get detailed plugin information
wheels plugin info wheels-auth
wheels plugin info wheels-api-builder

# List installed plugins
wheels plugin list
wheels plugin list --global
wheels plugin list --format=json
wheels plugin list --available    # Show all ForgeBox plugins

# Install plugins
wheels plugin install wheels-auth
wheels plugin install wheels-vue-cli --dev
wheels plugin install https://github.com/user/wheels-plugin
wheels plugin install wheels-api@2.0.0 --global

# Update plugins
wheels plugin update wheels-auth
wheels plugin update wheels-api --version=2.1.0 --force
wheels plugin update:all
wheels plugin update:all --dry-run

# Check for outdated plugins
wheels plugin outdated
wheels plugin outdated --format=json

# Remove plugins
wheels plugin remove wheels-auth
wheels plugin remove wheels-docker --global --force

# Create new plugin
wheels plugin init my-awesome-plugin
wheels plugin init wheels-payment-gateway --author="John Doe" --license=MIT
```

### Plugin Search

Search ForgeBox for available Wheels plugins:

```bash
# Search all plugins
wheels plugin search

# Search with query
wheels plugin search authentication
wheels plugin search "api builder"

# Sort results
wheels plugin search --orderBy=downloads    # Most popular first (default)
wheels plugin search --orderBy=updated      # Recently updated first
wheels plugin search --orderBy=name         # Alphabetical

# JSON output for scripting
wheels plugin search auth --format=json
```

### Plugin Information

Get detailed information about a plugin:

```bash
# Show plugin details
wheels plugin info wheels-auth

# Information includes:
# - Installation status
# - Latest version
# - Description and author
# - Download statistics
# - Dependencies
# - Available versions
# - Repository and homepage URLs
```

### Plugin Installation

Install plugins from ForgeBox or GitHub:

```bash
# Install from ForgeBox
wheels plugin install wheels-auth
wheels plugin install wheels-api-builder

# Install specific version
wheels plugin install wheels-auth@2.0.0

# Install as development dependency
wheels plugin install wheels-test-helpers --dev

# Install globally (available to all projects)
wheels plugin install wheels-docker --global

# Install from GitHub
wheels plugin install https://github.com/username/wheels-custom-plugin
```

### Plugin Updates

Keep plugins up to date:

```bash
# Update single plugin
wheels plugin update wheels-auth
wheels plugin update wheels-api --version=2.1.0

# Force update (reinstall even if up to date)
wheels plugin update wheels-auth --force

# Update all plugins
wheels plugin update:all

# Preview updates without installing
wheels plugin update:all --dry-run

# Force update all
wheels plugin update:all --force
```

### Outdated Plugins

Check which plugins have available updates:

```bash
# List outdated plugins
wheels plugin outdated

# JSON format for automation
wheels plugin outdated --format=json

# Output includes:
# - Current version
# - Latest available version
# - Last update date
# - Plugin type (dev/prod)
```

### Plugin Development

Create new Wheels plugins:

```bash
# Basic plugin initialization
wheels plugin init my-plugin

# With metadata
wheels plugin init payment-gateway \
  --author="Jane Smith" \
  --description="Payment processing for Wheels" \
  --version="0.1.0" \
  --license=MIT

# Generated structure:
# my-plugin/
# ├── box.json          # Package configuration
# ├── ModuleConfig.cfc  # Module configuration
# ├── README.md         # Documentation
# ├── commands/         # CLI commands
# ├── models/           # Service components
# ├── templates/        # File templates
# └── tests/            # Test suite
```

### Plugin Publishing

Publish plugins to ForgeBox:

```bash
# Login to ForgeBox
box login

# From plugin directory
cd my-plugin

# Publish to ForgeBox
box package publish

# Update version and publish
box bump --major
box package publish
```

### Plugin Best Practices

1. **Naming Convention**: Prefix with `wheels-` (e.g., `wheels-auth`)
2. **Type Declaration**: Set type as `commandbox-modules,cfwheels-plugins`
3. **Documentation**: Include comprehensive README.md
4. **Testing**: Include test suite in `/tests/`
5. **Versioning**: Follow semantic versioning (major.minor.patch)

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
