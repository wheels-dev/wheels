# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Start

### New to Wheels?
1. **Install Wheels**: `box install cfwheels`
2. **Generate an app**: `wheels g app myapp`
3. **Start developing**: `server start`

### Common Tasks
- **Create a model**: `wheels g model User name:string,email:string,active:boolean`
- **Create a controller**: `wheels g controller Users index,show,new,create,edit,update,delete`
- **Create full scaffold**: `wheels g scaffold Product name:string,price:decimal,inStock:boolean`
- **Run migrations**: `wheels dbmigrate latest`
- **Run tests**: `wheels test app` or `box testbox run`

### AI-Specific Documentation
- **Patterns**: See AI-PATTERNS.md for common code patterns
- **Testing**: See AI-TESTING.md for TestBox patterns
- **Errors**: See AI-ERRORS.md for troubleshooting
- **CLI**: See AI-CLI.md for complete command reference
- **Migrations**: See AI-MIGRATIONS.md for database migration patterns
- **Examples**: See AI-EXAMPLES.md and `/examples/` directory for working applications
- **Context**: See AI-CONTEXT.md for framework concepts
- **Troubleshooting**: See AI-TROUBLESHOOTING.md for common issues

## Framework Philosophy

Wheels is inspired by Ruby on Rails and follows these principles:

### Convention over Configuration
- Models are singular (User.cfc), tables are plural (users)
- Controllers are plural (Users.cfc)
- URLs follow RESTful patterns (/users, /users/1, /users/new)
- Database columns automatically map to model properties

### Don't Repeat Yourself (DRY)
- Reusable partials for views (`_form.cfm`)
- Model associations reduce code duplication
- Helpers and plugins for common functionality

### MVC Architecture
- **Models**: Business logic and data persistence
- **Views**: Presentation layer (HTML, JSON, XML)
- **Controllers**: Request handling and coordination

### ActiveRecord Pattern
- Models represent database tables
- Instance methods for CRUD operations
- Built-in validations and callbacks

### RESTful by Default
- Standard CRUD actions (index, show, new, create, edit, update, delete)
- HTTP verbs map to controller actions
- Resource-based routing

## Build/Test Commands

### Testing
- Run a single test: `wheels test app TestName`
- Run a test package: `wheels test app testBundles=controllers`
- Run a specific test spec: `wheels test app testBundles=controllers&testSpecs=testCaseOne`
- Run all tests: `box testbox run` or `box run-script test`
- Run specific directory: `box testbox run --directory=tests/specs/unit`
- Run tests with coverage: `box testbox run --coverage --coverageReporter=html`
- Watch mode for TDD: `box testbox watch`
- Run unit tests only: `box run-script test:unit`
- Run integration tests: `box run-script test:integration`
- Run tests for specific engine with Docker: `docker compose --profile lucee up -d`
- Available Docker profiles: `lucee`, `lucee6`, `lucee7`, `adobe2018`, `adobe2021`, `adobe2023`, `adobe2025`

### Advanced Testing (TestBox CLI)
- Install TestBox CLI: `box install commandbox-testbox-cli`
- Run all tests: `wheels test:all`
- Run unit tests: `wheels test:unit`
- Run integration tests: `wheels test:integration`
- Watch mode: `wheels test:watch`
- Coverage: `wheels test:coverage`

### Code Quality
- Format code: `box run-script format` (uses cfformat)
- Check formatting: `box run-script format:check`
- Watch mode formatting: `box run-script format:watch`

### Development
- Install dependencies: `box install`
- Install CFML modules on server: `cfpm install image,mail,zip,debugger,caching,mysql,postgresql,sqlserver`
- Reload application: `wheels reload [development|testing|maintenance|production]`
- Start server in workspace: `cd workspace && server start`
- Restart server: `server restart`
- Reload CommandBox after CLI changes: `box reload`

### Database Management
- Create database: `wheels db create`
- Setup database (create + migrate + seed): `wheels db setup`
- Reset database: `wheels db reset --force`
- Database shell: `wheels db shell` (CLI) or `wheels db shell --web` (H2 web console)
- Backup database: `wheels db dump --output=backup.sql`
- Restore database: `wheels db restore backup.sql`
- Check migration status: `wheels db status`
- Rollback migrations: `wheels db rollback --steps=3`

### Migration Commands
- **ALWAYS use CLI to generate migrations**: `wheels g migration MigrationName`
- Create table: `wheels g migration CreateUsers`
- Add column: `wheels g migration AddEmailToUsers`
- Remove column: `wheels g migration RemovePasswordFromUsers`
- Add index: `wheels g migration AddIndexToUsersEmail`
- Run migrations: `wheels dbmigrate latest`
- Rollback: `wheels dbmigrate down`

### Enhanced Generators
- Migration: `wheels g migration CreateUsersTable --attributes="name:string,email:string:index"`
- Mailer: `wheels g mailer UserNotifications --methods="welcome,passwordReset"`
- Service: `wheels g service PaymentProcessor --type=singleton`
- Helper: `wheels g helper StringUtils --functions="truncate,slugify"`
- Job: `wheels g job ProcessOrders --queue=high --schedule="0 0 * * *"`
- Plugin: `wheels g plugin Authentication --version="1.0.0"`

## Code Style Guidelines

### Naming Conventions
- camelCase for variable/function names
- CapitalizedCamelCase for CFC names
- Scoped variables use lowercase.camelCase (e.g., `application.myVar`)
- Pascal case for built-in CF functions (e.g., `IsNumeric()`, `Trim()`)
- Prefix "private" framework methods with `$` (e.g., `$query()`)

### Formatting (cfformat rules)
- Indent with tabs, 2 spaces per tab
- Max line length: 120 characters
- Array spacing: `[1, 2, 3]` not `[ 1,2,3 ]`
- Struct spacing: `{key: value}` not `{ key : value }`
- Binary operators spaced: `1 + 2` not `1+2`
- Function declaration spacing: no space before parentheses
- Built-in functions use PascalCase: `ArrayLen()`, `StructKeyExists()`
- User-defined functions use camelCase: `myFunction()`, `getUserById()`

### Testing Patterns
- Use TestBox BDD syntax with describe/it blocks
- Use `local` scope for function variables (not var-scoped)
- Follow Wheels validation/callback patterns in models
- Use transactions for database tests (automatic with BaseSpec)
- Use factories for test data generation

### Model Patterns
- Use associations (hasMany, belongsTo, hasOne)
- Use callbacks (beforeValidation, afterCreate, etc.)
- Use calculated properties for derived data
- Follow ActiveRecord pattern conventions

## CLI Commands

### Parameter Syntax
- CommandBox requires named attributes (name=value) not positional parameters
- Boolean attributes can use `--attribute` as shortcut for `attribute=true`
- Don't mix positional and named attributes
- Note: Some CLI commands have parameter naming inconsistencies (camelCase vs kebab-case)

### Testing CLI Commands
1. Navigate to workspace: `cd workspace`
2. Create test app: `wheels g app myapp`
3. Start server: `server start`
4. Test your CLI changes
5. If modifying CLI code, reload CommandBox: `box reload`

### CLI Module Architecture
- Commands in `/cli/commands/wheels/` directory
- Base command class: `/cli/commands/wheels/base.cfc`
- Service architecture in `/cli/services/`
- Templates in `/cli/templates/`
- Tests in `/cli/tests/`

## High-Level Architecture

### Core Components
- **Application.cfc**: Framework initialization and request lifecycle
- **Controller.cfc**: Base controller providing MVC functionality, rendering, filters, and provides() for content negotiation
- **Model.cfc**: ActiveRecord-style ORM with associations, validations, callbacks, and database adapters
- **Dispatch.cfc**: Request routing and parameter handling
- **Global.cfc**: Framework-wide helper functions and utilities
- **Mapper.cfc**: RESTful routing configuration with resource mapping
- **Migrator.cfc**: Database migration management
- **Wirebox.cfc**: Dependency injection container

### Directory Structure
- `/vendor/wheels/`: Core framework files (do not modify directly)
  - `/controller/`: Controller functionality (filters, rendering, caching)
  - `/model/`: Model functionality (CRUD, associations, validations)
  - `/view/`: View helpers and form builders
  - `/global/`: Global helper functions
  - `/public/`: Request lifecycle and bootstrapping
  - `/migrator/`: Database migration system
  - `/events/`: Event handling system
  - `/plugins/`: Plugin architecture
- `/app/`: Application code (controllers, models, views)
- `/config/`: Environment-specific configuration
- `/cli/`: CommandBox CLI module for code generation and tasks
- `/tests/`: Framework and application test suites
- `/docker/`: Docker configurations for multi-engine testing
- `/workspace/`: Sandbox for testing CLI commands

### Key Patterns
- **Initialization**: Both Controllers and Models use `config()` method for initialization, NOT `init()`
- **Private Methods**: Prefix with `$` indicates framework internals (e.g., `$callAction()`, `$performedRenderOrRedirect()`)
- **Content Negotiation**: Use `provides()` or `onlyProvides()` in controller config()
- **View Rendering**: Automatic for HTML, skipped for JSON/XML when using renderText/renderWith
- **Component Integration**: Framework uses `$integrateComponents()` to mix functionality into base classes
- **Request Flow**: Application.cfc → Dispatch.cfc → Controller → Model → View

### Database Testing
- Create `wheelstestdb` database and datasource
- Supports H2 (recommended for speed), MySQL, PostgreSQL, SQL Server, Oracle
- Docker compose provides all database servers for testing
- Use `db={{database}}` URL parameter to switch datasources
- Tests run in transactions that automatically roll back

### Development Workflow
1. Make changes to framework files in `/vendor/wheels/`
2. Test using workspace sandbox: `cd workspace && wheels g app testapp && server start`
3. Run tests: `wheels test app` or `box testbox run`
4. Use Docker TestUI at localhost:3000 for multi-engine testing
5. Ensure all CFML engines pass (Lucee 5/6/7, Adobe 2018/2021/2023/2025)

## Creating Pull Requests
Use the gh command via the Bash tool for ALL GitHub-related tasks including working with issues, pull requests, checks, and releases.

## Important Notes

### Framework Specifics
- Framework uses `config()` method for initialization in BOTH controllers and models
- Always check `$performedRenderOrRedirect()` before automatic view rendering
- Use `$requestContentType()` and `$acceptableFormats()` for content negotiation
- The `$` prefix indicates framework internal methods - do not call these directly from application code
- View files use `.cfm` extension, not `.cfc`

### Testing Requirements
- Test on multiple CFML engines before submitting PRs
- Use BaseSpec.cfc for all tests to get Wheels integration helpers
- Tests automatically run in transactions for isolation
- Use factories for consistent test data generation
- Run formatting check before committing: `box run-script format:check`

### Development Best Practices
- Follow existing patterns when adding new functionality
- Don't modify files in `/vendor/wheels/` unless contributing to framework
- Use the `/workspace/` directory for testing CLI commands
- Check for existing helpers before creating new ones
- Use TestBox BDD syntax for all new tests

### Known Issues
- Some CLI commands have inconsistent parameter naming (camelCase vs kebab-case)
- Direct CFM file access may not work due to Wheels routing (use defined routes instead)

### Database Shell Specifics
- H2 databases use Lucee's bundled JAR: `org.lucee.h2-*.jar`
- H2 web console: `wheels db shell --web`
- Database shells require native clients: mysql, psql, sqlcmd
- Shell commands auto-detect database type from datasource configuration

## Adobe ColdFusion Compatibility

### Key Differences from Lucee
- **Function calls require parentheses**: Use `abort()` not `abort`
- **Dynamic method invocation**: Use `invoke(object=component, methodname=method)` instead of `component[method]()`
- **Variable scoping**: Be explicit with scopes in includes and view contexts
- **Built-in functions**: Some functions like `cfheader()` don't exist as script functions in Adobe CF

### Common Adobe CF Fixes
1. Replace `abort;` with `abort();`
2. Replace `component[method]()` with `invoke(object=component, methodname=method)`
3. For Adobe CF 2018/2021: Use `object` and `methodname` parameters for invoke()
4. Ensure all included files exist (Adobe CF validates includes during compilation)
5. Use proper CF tag syntax (`<cfheader>`) instead of script functions where needed

### Testing with Adobe CF
- Local Docker testing: `docker compose --profile adobe2021 up -d`
- Access Adobe CF instances: http://localhost:62018, http://localhost:62021, http://localhost:62023
- All Adobe versions must pass tests before PR submission
- Check compilation errors first, then runtime errors

## Server & Environment Management

### CLI Console (REPL)
- Start interactive console: `wheels console`
- Execute single command: `wheels console execute="model('User').count()"`
- Access models via `model()` function
- Direct database queries via `query()` function
- Switch environments: `wheels console environment=testing`

### Script Runner
- Execute scripts in app context: `wheels runner script.cfm`
- Pass parameters: `wheels runner script.cfm --params='{"userId":123}'`
- Useful for maintenance tasks and data migrations

### Environment Management
- Show current environment: `wheels environment`
- Switch environment: `wheels environment set production`
- List available environments: `wheels environment list`
- Automatic reload after environment change

### Server Management
- Enhanced server commands: `wheels server start/stop/restart/status/log/open`
- All commands validate Wheels application directory
- Show Wheels-specific information (version, paths)
- Integrated with CommandBox server functionality

## Repository Structure

### Framework Core
- Main Wheels framework repository
- Located in `/vendor/wheels/` when installed
- Core MVC functionality and database ORM
- Plugin system and event architecture

### CLI Module
- Separate module in `/cli/` directory
- CommandBox integration for code generation
- Service-based architecture with DI
- Extensive template system for scaffolding

### Testing Infrastructure
- Framework tests in `/vendor/wheels/tests_testbox/`
- CLI tests in `/cli/tests/`
- Application tests in `/tests/`
- Docker configurations for multi-engine testing

## Package Management

### Dependencies (box.json)
- **wirebox**: ^7 - Dependency injection
- **testbox**: ^5 - Testing framework

### Dev Dependencies
- **commandbox-dotenv**: Environment variables
- **commandbox-cfconfig**: CF engine configuration
- **commandbox-cfformat**: Code formatting

### Scripts
- `format`: Run code formatter
- `format:check`: Check code formatting
- `test`: Run all tests
- `test:unit`: Run unit tests only
- `test:integration`: Run integration tests
- `test:coverage`: Generate coverage report

## Wheels-Specific Gotchas

### Router Priority
- Routes are matched in order of definition
- More specific routes should be defined before generic ones
- Resource routes generate multiple route patterns

### Model Initialization
- Use `config()` not `init()` for model initialization
- Properties defined in `config()` are available throughout the model
- Associations must be defined in `config()`

### View Context
- Views have access to all controller variables
- Use `includePartial()` for reusable view components
- Partials start with underscore (e.g., `_form.cfm`)

### Migration Best Practices
- **NEVER create migration files manually** - always use CLI
- Migration files are timestamped and run in order
- Use descriptive names that explain the change
- Test migrations on all supported databases

### Testing Database Setup
- The `wheelstestdb` datasource must be configured
- Tests create and destroy data - never run on production
- Use factories for consistent test data
- Each test runs in a transaction that rolls back

## Configuration & Security

### Environment Variables (.env files)
- Framework automatically loads `.env` files on startup
- Supports environment-specific files: `.env.{environment}`
- Variable interpolation: `${VAR}` syntax
- Type casting for booleans and numbers
- Access via `application.env['KEY_NAME']`

### Configuration Management Commands
- `wheels config dump` - Export settings (JSON, env, CFML formats)
- `wheels config check` - Validate security and best practices
- `wheels config diff` - Compare environments
- `wheels secret` - Generate secure secrets
- `wheels env set/validate/merge` - Manage .env files

### Security Best Practices
- Never commit .env files to version control
- Use `wheels secret` for generating secure keys
- Run `wheels config check production` before deployment
- Mask sensitive values in logs and output
- Use environment-specific secrets
