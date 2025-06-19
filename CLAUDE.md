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
- **Run tests**: `wheels test run` or `box testbox run`

### AI-Specific Documentation
- **Patterns**: See AI-PATTERNS.md for common code patterns
- **Testing**: See AI-TESTING.md for TestBox patterns
- **Errors**: See AI-ERRORS.md for troubleshooting
- **CLI**: See AI-CLI.md for complete command reference
- **Migrations**: See AI-MIGRATIONS.md for database migration patterns
- **Examples**: See AI-EXAMPLES.md and `/examples/` directory for working applications
- **Context**: See AI-CONTEXT.md for framework concepts
- **Troubleshooting**: See AI-TROUBLESHOOTING.md for common issues

## Build/Test Commands

### Testing
- Run a single test: `box testbox run --testBundles=path.to.TestFile`
- Run tests by directory: `box testbox run --directory=tests/specs/unit`
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

## High-Level Architecture

### Request Lifecycle
1. **Application.cfc** initializes framework containers and loads configuration
2. **Dispatch.cfc** receives request, finds matching route, creates params struct
3. **Controller** instantiated and `processAction()` called
4. **Model** interactions through ActiveRecord pattern
5. **View** rendering (automatic or explicit)
6. Response sent with proper content type

### Core Components
- **Application.cfc**: Framework initialization and request lifecycle
- **Controller.cfc**: Base controller providing MVC functionality, rendering, filters, and provides() for content negotiation
- **Model.cfc**: ActiveRecord-style ORM with associations, validations, callbacks, and database adapters
- **Dispatch.cfc**: Request routing and parameter handling
- **Global.cfc**: Framework-wide helper functions and utilities
- **Mapper.cfc**: RESTful routing configuration with resource mapping
- **Migrator.cfc**: Database migration management
- **Wirebox.cfc**: Dependency injection container

### CLI Module Architecture
- **Commands**: Hierarchical structure under `/cli/commands/wheels/`, all extend `base.cfc`
- **Services**: Business logic in `/cli/models/` using WireBox dependency injection
- **Templates**: Sophisticated template system with `{{variable}}` syntax, checks `app/snippets/` first
- **SharedParameters.cfc**: Centralizes parameter definitions for consistency

### Key Framework Patterns

#### The $ Prefix Convention
- All internal framework methods prefixed with `$` (e.g., `$callAction()`, `$performedRenderOrRedirect()`)
- Clear boundary between framework and application code
- Never call $ methods directly from application code

#### Initialization Pattern
- **CRITICAL**: Both Controllers and Models use `config()` method for initialization, NOT `init()`
- The `config()` method is where associations, validations, filters are defined
- Framework uses `$init()` internally, application code uses `config()`

#### Component Integration
- Framework uses `$integrateComponents()` to mix functionality into base classes
- Avoids deep inheritance in favor of composition
- Allows modular architecture with clear separation of concerns

#### Content Negotiation
- Use `provides()` or `onlyProvides()` in controller config()
- Automatic format detection from URL or Accept headers
- Format-specific views (e.g., `show.json.cfm`)
- View rendering automatic for HTML, skipped for JSON/XML when using renderText/renderWith

#### Database Adapter System
- Base adapter provides common functionality
- Database-specific adapters (H2, MySQL, PostgreSQL, SQLServer) handle:
  - Type mapping and identity/auto-increment handling
  - Database-specific SQL generation
  - Migration SQL differences

#### Plugin System
- Plugins extracted from `/app/plugins/` directory
- Can extend any framework component via mixins
- Environment-specific plugin support
- Version compatibility checking

### Testing Architecture
- **BaseSpec.cfc** provides Wheels-aware test helpers
- Tests run in transactions that automatically roll back
- Create `wheelstestdb` database and datasource for testing
- Use factories for consistent test data generation
- Docker compose provides multi-engine testing environments

### Important Framework Specifics
- Always check `$performedRenderOrRedirect()` before automatic view rendering
- Use `$requestContentType()` and `$acceptableFormats()` for content negotiation
- View files use `.cfm` extension, not `.cfc`
- Partials start with underscore (e.g., `_form.cfm`)
- Routes are matched in order of definition
- Models derive structure from database schema (database-first approach)

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

## Repository Structure

### Key Directories
- `/vendor/wheels/` - Core framework code (do not modify directly)
- `/app/` - Application code (controllers, models, views, config)
- `/cli/` - CommandBox CLI module for Wheels commands
- `/tests/` - Framework test suite
- `/guides/` - Framework documentation
- `/examples/` - Example applications
- `/docker/` - Docker configurations for different CFML engines
- `/workspace/` - Sandbox for testing CLI commands

### Working with the CLI Module
- CLI commands are in `/cli/commands/wheels/`
- After modifying CLI code, reload CommandBox: `box reload`
- Test CLI commands in the `/workspace/` directory
- Use `.claude/commands/cli/test-next-group.md` for systematic CLI testing

## Commit Message Guidelines
- Use conventional commit format: `type: description`
- Types: feat, fix, docs, style, refactor, test, chore
- Keep subject line under 50 characters
- Don't add Claude signature to commits
- Don't add Claude signature to PR descriptions