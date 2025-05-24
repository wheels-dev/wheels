# Wheels CLI Commands Master List

This document provides a comprehensive list of all Wheels CLI commands and their options for testing purposes.

## Core Commands

### wheels init
**Description**: Bootstrap an existing Wheels application for CLI usage
**Aliases**: None
**Parameters**:
- `name` - Application name (optional)
- `directory` - Target directory (optional)
- `reload` - Reload password (optional)
- `datasourceName` - Database name (optional)

### wheels info
**Description**: Display version information about Wheels CLI and framework
**Aliases**: None
**Parameters**: None

### wheels deps
**Description**: Install and manage dependencies
**Aliases**: None
**Parameters**: None

### wheels reload
**Description**: Reload the Wheels application
**Aliases**: None
**Parameters**:
- `environment` - Environment to reload (development|testing|maintenance|production)

### wheels destroy
**Description**: Remove generated scaffolding code
**Aliases**: None
**Parameters**:
- `name` - Name of resource to destroy
- `type` - Type of code to destroy (scaffold|controller|model)

### wheels watch
**Description**: Watch files for changes and auto-reload
**Aliases**: None
**Parameters**:
- `--paths` - Paths to watch
- `--extensions` - File extensions to watch
- `--reload` - Auto-reload on changes

## Generation Commands

### wheels generate app
**Description**: Generate a new Wheels application
**Aliases**: `wheels g app`
**Parameters**:
- `name` - Application name (required)
- `--template` - Template to use (Base|Rest|HelloWorld|Todos|UserManagement)
- `--directory` - Target directory
- `--datasourceName` - Database name
- `--setupH2` - Setup H2 database (boolean)
- `--useBootstrap` - Include Bootstrap CSS (boolean)

### wheels generate app-wizard
**Description**: Interactive application generator wizard
**Aliases**: `wheels g app-wizard`, `wheels new`
**Parameters**: None (interactive)

### wheels generate controller
**Description**: Generate a controller file
**Aliases**: `wheels g controller`
**Parameters**:
- `name` - Controller name (required)
- `--actions` - Comma-separated list of actions
- `--rest` - Generate RESTful actions (boolean)
- `--api` - Generate API controller (boolean)
- `--force` - Overwrite existing files (boolean)

### wheels generate model
**Description**: Generate a model file
**Aliases**: `wheels g model`
**Parameters**:
- `name` - Model name (required)
- `--properties` - Properties in format "name:type,name:type"
- `--migration` - Generate migration file (boolean)
- `--belongs-to` - Parent relationships
- `--has-many` - Child relationships
- `--force` - Overwrite existing files (boolean)

### wheels generate view
**Description**: Generate a view file
**Aliases**: `wheels g view`
**Parameters**:
- `name` - View name (required)
- `--action` - Action name
- `--controller` - Controller name
- `--template` - View template
- `--force` - Overwrite existing files (boolean)

### wheels generate property
**Description**: Add a property to an existing model
**Aliases**: `wheels g property`
**Parameters**:
- `model` - Model name (required)
- `name` - Property name (required)
- `type` - Property type (string|integer|boolean|date|datetime|time|text)
- `--default` - Default value
- `--null` - Allow null values (boolean)

### wheels generate route
**Description**: Add a route to config/routes.cfm
**Aliases**: `wheels g route`
**Parameters**:
- `name` - Route name (required)
- `pattern` - URL pattern
- `controller` - Controller name
- `action` - Action name
- `--methods` - HTTP methods (GET|POST|PUT|DELETE)

### wheels generate test
**Description**: Generate test files
**Aliases**: `wheels g test`
**Parameters**:
- `name` - Test name (required)
- `type` - Test type (model|controller|view)
- `--methods` - Test methods to generate

### wheels generate resource
**Description**: Generate a RESTful resource
**Aliases**: `wheels g resource`
**Parameters**:
- `name` - Resource name (required)
- `--properties` - Model properties
- `--api` - API-only resource (boolean)
- `--scaffold` - Full scaffolding (boolean)

### wheels generate api-resource
**Description**: Generate an API resource
**Aliases**: `wheels g api-resource`
**Parameters**:
- `name` - Resource name (required)
- `--properties` - Model properties
- `--version` - API version

### wheels generate frontend
**Description**: Generate frontend components
**Aliases**: `wheels g frontend`
**Parameters**:
- `name` - Component name (required)
- `--framework` - Frontend framework (vue|react|angular)
- `--template` - Component template

### wheels generate snippets
**Description**: Generate code snippets
**Aliases**: `wheels g snippets`
**Parameters**:
- `type` - Snippet type
- `--output` - Output directory

## Scaffolding

### wheels scaffold
**Description**: Generate complete CRUD scaffolding
**Aliases**: None
**Parameters**:
- `name` - Resource name (required)
- `--properties` - Model properties in format "name:type,name:type"
- `--api` - Generate API-only scaffold (boolean)
- `--tests` - Generate test files (boolean)
- `--migrate` - Run migrations after generation (boolean)
- `--force` - Overwrite existing files (boolean)

## Database Migration Commands

### wheels dbmigrate create table
**Description**: Create a new table migration
**Aliases**: None
**Parameters**:
- `name` - Table name (required)
- `--id` - Include id column (boolean, default: true)
- `--timestamps` - Include timestamps (boolean, default: true)
- `--force` - Overwrite existing migration (boolean)

### wheels dbmigrate create column
**Description**: Create an add column migration
**Aliases**: None
**Parameters**:
- `table` - Table name (required)
- `columnName` - Column name (required)
- `columnType` - Column type (required)
- `--default` - Default value
- `--null` - Allow null (boolean)
- `--limit` - Column length limit
- `--precision` - Numeric precision
- `--scale` - Numeric scale

### wheels dbmigrate create blank
**Description**: Create a blank migration file
**Aliases**: None
**Parameters**:
- `migrationName` - Migration name (required)

### wheels dbmigrate remove table
**Description**: Create a drop table migration
**Aliases**: None
**Parameters**:
- `name` - Table name (required)

### wheels dbmigrate up
**Description**: Migrate database one version up
**Aliases**: None
**Parameters**:
- `--version` - Target version number

### wheels dbmigrate down
**Description**: Migrate database one version down
**Aliases**: None
**Parameters**:
- `--version` - Target version number

### wheels dbmigrate latest
**Description**: Migrate database to latest version
**Aliases**: None
**Parameters**: None

### wheels dbmigrate reset
**Description**: Reset database (rollback all migrations)
**Aliases**: None
**Parameters**: None

### wheels dbmigrate exec
**Description**: Execute a specific migration
**Aliases**: None
**Parameters**:
- `version` - Migration version (required)
- `--direction` - Migration direction (up|down)

### wheels dbmigrate info
**Description**: Display migration status information
**Aliases**: None
**Parameters**: None

### wheels db schema
**Description**: Database schema operations
**Aliases**: None
**Parameters**:
- `--dump` - Dump schema to file
- `--load` - Load schema from file
- `--format` - Output format (sql|json)

### wheels db seed
**Description**: Seed database with data
**Aliases**: None
**Parameters**:
- `--file` - Seed file to run
- `--environment` - Target environment

## Testing Commands

### wheels test
**Description**: Run application tests
**Aliases**: None
**Parameters**:
- `type` - Test type (app|core|plugin) (default: app)
- `--servername` - Server name
- `--reload` - Force reload (boolean)
- `--debug` - Show debug output (boolean)
- `--reporter` - Test reporter format
- `--testBundles` - Specific test bundles
- `--testSpecs` - Specific test specs

### wheels test run
**Description**: Run specific test files or methods
**Aliases**: None
**Parameters**:
- `path` - Test file path or pattern
- `--method` - Specific test method
- `--bundle` - Test bundle name

### wheels test coverage
**Description**: Generate test coverage report
**Aliases**: None
**Parameters**:
- `--format` - Report format (html|json|lcov)
- `--output` - Output directory
- `--threshold` - Coverage threshold percentage

### wheels test debug
**Description**: Debug test execution
**Aliases**: None
**Parameters**:
- `test` - Test to debug
- `--breakpoint` - Set breakpoint line

## Configuration Commands

### wheels config list
**Description**: List all configuration settings
**Aliases**: None
**Parameters**:
- `--environment` - Target environment
- `--format` - Output format (table|json)

### wheels config set
**Description**: Set configuration value
**Aliases**: None
**Parameters**:
- `key` - Configuration key (required)
- `value` - Configuration value (required)
- `--environment` - Target environment
- `--global` - Set globally (boolean)

### wheels config env
**Description**: Environment-specific configuration
**Aliases**: None
**Parameters**:
- `--list` - List environments
- `--create` - Create new environment
- `--copy` - Copy environment settings

## Environment Commands

### wheels env
**Description**: Environment management (delegates to subcommands)
**Aliases**: None
**Parameters**: None

### wheels env setup
**Description**: Setup development environment
**Aliases**: None
**Parameters**:
- `--template` - Environment template (local|docker|vagrant)
- `--database` - Database type (mysql|postgresql|sqlserver|h2)
- `--force` - Overwrite existing setup (boolean)

### wheels env list
**Description**: List available environments
**Aliases**: None
**Parameters**: None

### wheels env switch
**Description**: Switch active environment
**Aliases**: None
**Parameters**:
- `environment` - Target environment (required)

## Analysis Commands

### wheels analyze
**Description**: Analyze application code
**Aliases**: None
**Parameters**:
- `--type` - Analysis type (all|performance|code|security)
- `--report` - Generate HTML report (boolean)
- `--output` - Output directory
- `--verbose` - Verbose output (boolean)

### wheels analyze code
**Description**: Perform code quality analysis
**Aliases**: None
**Parameters**:
- `--path` - Path to analyze
- `--rules` - Rules configuration file
- `--fix` - Auto-fix issues (boolean)

### wheels analyze performance
**Description**: Analyze performance issues
**Aliases**: None
**Parameters**:
- `--profile` - Enable profiling (boolean)
- `--duration` - Profile duration in seconds
- `--threshold` - Performance threshold

### wheels analyze security
**Description**: Security vulnerability analysis
**Aliases**: None
**Parameters**:
- `--scan-type` - Scan type (full|quick|custom)
- `--ignore` - Patterns to ignore
- `--severity` - Minimum severity level

## Optimization Commands

### wheels optimize
**Description**: Optimize application performance
**Aliases**: None
**Parameters**:
- `--target` - Optimization target (all|database|assets|code)
- `--aggressive` - Aggressive optimization (boolean)
- `--backup` - Create backup (boolean)

### wheels optimize performance
**Description**: Performance-specific optimizations
**Aliases**: None
**Parameters**:
- `--cache` - Optimize caching
- `--queries` - Optimize database queries
- `--assets` - Optimize assets

## Security Commands

### wheels security
**Description**: Security management (delegates to subcommands)
**Aliases**: None
**Parameters**: None

### wheels security scan
**Description**: Perform security scan
**Aliases**: None
**Parameters**:
- `--type` - Scan type (vulnerabilities|dependencies|code)
- `--report` - Generate report (boolean)
- `--fix` - Attempt to fix issues (boolean)

## Documentation Commands

### wheels docs
**Description**: Documentation management (delegates to subcommands)
**Aliases**: None
**Parameters**: None

### wheels docs generate
**Description**: Generate API documentation
**Aliases**: None
**Parameters**:
- `--format` - Output format (html|json|markdown)
- `--template` - Documentation template
- `--output` - Output directory
- `--serve` - Start local server (boolean)
- `--port` - Server port

### wheels docs serve
**Description**: Serve documentation locally
**Aliases**: None
**Parameters**:
- `--port` - Server port (default: 8080)
- `--open` - Open in browser (boolean)

## Plugin Commands

### wheels plugins
**Description**: Plugin management (delegates to subcommands)
**Aliases**: None
**Parameters**: None

### wheels plugins list
**Description**: List installed plugins
**Aliases**: None
**Parameters**:
- `--format` - Output format (table|json)
- `--outdated` - Show only outdated plugins (boolean)

### wheels plugins install
**Description**: Install a plugin
**Aliases**: None
**Parameters**:
- `name` - Plugin name (required)
- `--version` - Plugin version
- `--dev` - Development dependency (boolean)
- `--global` - Install globally (boolean)
- `--force` - Force install (boolean)

### wheels plugins remove
**Description**: Remove a plugin
**Aliases**: None
**Parameters**:
- `name` - Plugin name (required)
- `--global` - Remove global plugin (boolean)

## CI/CD Commands

### wheels ci init
**Description**: Initialize CI/CD configuration
**Aliases**: None
**Parameters**:
- `--provider` - CI provider (github|gitlab|jenkins|circleci)
- `--template` - CI template
- `--force` - Overwrite existing (boolean)

### wheels docker init
**Description**: Initialize Docker configuration
**Aliases**: None
**Parameters**:
- `--type` - Docker setup type (development|production)
- `--compose` - Include docker-compose (boolean)
- `--force` - Overwrite existing (boolean)

### wheels docker deploy
**Description**: Deploy application using Docker
**Aliases**: None
**Parameters**:
- `--environment` - Target environment
- `--tag` - Docker image tag
- `--registry` - Docker registry

---

## Notes for Testing

1. **Common Flags**: Most generation commands support:
   - `--force` - Overwrite existing files
   - `--dry-run` - Preview changes without applying
   - `--quiet` - Suppress output

2. **Environment Variables**: Commands respect:
   - `WHEELS_ENV` - Default environment
   - `WHEELS_DATASOURCE` - Default datasource

3. **Interactive Mode**: Some commands like `app-wizard` run in interactive mode

4. **Validation**: All commands should validate:
   - Required parameters
   - Parameter types and formats
   - File/directory existence
   - Permissions

5. **Error Handling**: Test error scenarios:
   - Missing required parameters
   - Invalid parameter values
   - Permission errors
   - Network failures (for plugin commands)
   - Database connection issues

6. **Command Aliases**: Test both primary command and aliases work identically
