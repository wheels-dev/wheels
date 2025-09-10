# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Start

### New to Wheels?
1. **Install Wheels CLI**: `box install wheels-cli`
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
- **Upgrading**: See `/guides/upgrading/3.0.0-config-migration.md` for config directory migration

## Build/Test Commands

### Testing
- Run a single test: `box testbox run --testBundles=path.to.TestFile`
- Run tests by directory: `box testbox run --directory=tests/specs/unit`
- Run tests with coverage: `box testbox run --coverage --coverageReporter=html`
- Watch mode for TDD: `box testbox watch`
- Run unit tests only: `box run-script test:unit`
- Run integration tests: `box run-script test:integration`
- Run tests for specific engine with Docker: `docker compose up lucee -d`
- Available Docker profiles: `lucee`, `lucee6`, `lucee7`, `adobe2018`, `adobe2021`, `adobe2023`, `adobe2025`, `boxlang`

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

### Deployment Commands (New)
- Initialize deployment: `wheels deploy:init --provider=digitalocean --domain=myapp.com`
- Setup servers: `wheels deploy:setup`
- Deploy application: `wheels deploy:push`
- Check status: `wheels deploy:status`
- View logs: `wheels deploy:logs --follow`
- Rollback: `wheels deploy:rollback`
- Manage secrets: `wheels deploy:secrets push`

### Security & Analysis (New)
- Security scan: `wheels security scan --fix`
- Performance optimization: `wheels optimize performance --analysis`
- Code analysis: `wheels analyze code --metrics`
- Dependency analysis: `wheels deps --tree`

### Environment Management (New)
- List environments: `wheels env list`
- Switch environment: `wheels env switch production`
- Setup environment: `wheels env setup --name=staging`
- Environment diff: `wheels config diff production staging`

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
- **Important**: After modifying CLI code, reload CommandBox: `box reload`

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
- Docker compose provides multi-engine testing environments (see `/tools/docker/`)

### Important Framework Specifics
- Always check `$performedRenderOrRedirect()` before automatic view rendering
- Use `$requestContentType()` and `$acceptableFormats()` for content negotiation
- View files use `.cfm` extension, not `.cfc`
- Partials start with underscore (e.g., `_form.cfm`)
- Routes are matched in order of definition
- Models derive structure from database schema (database-first approach)
- **Configuration location**: Config files are now in `/config` at root level (NOT `/app/config`)

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
- Local Docker testing: `docker compose up adobe2021 -d`
- Access Adobe CF instances: http://localhost:62018, http://localhost:62021, http://localhost:62023
- All Adobe versions must pass tests before PR submission
- Check compilation errors first, then runtime errors

## BoxLang Support

### Testing with BoxLang
- Local Docker testing: `docker compose up boxlang -d`
- Access BoxLang instance: http://localhost:60001
- BoxLang version support: 1

## Repository Structure

### Key Directories
- `/vendor/wheels/` - Core framework code (do not modify directly)
- `/app/` - Application code (controllers, models, views)
- `/config/` - Configuration files (routes, settings, environments) - **NOTE: Moved from /app/config in 3.0.0**
- `/cli/` - CommandBox CLI module for Wheels commands
- `/tests/` - Framework test suite
- `/guides/` - Framework documentation
- `/examples/` - Example applications
- `/tools/docker/` - Docker configurations for different CFML engines
- `/tools/build/` - Build artifacts and scripts
- `/workspace/` - Sandbox for testing CLI commands

### Working with the CLI Module
- CLI commands are in `/cli/commands/wheels/`
- After modifying CLI code, reload CommandBox: `box reload`
- Test CLI commands in the `/workspace/` directory
- Use `.claude/commands/cli/test-next-group.md` for systematic CLI testing

## Monorepo Architecture & Package Distribution

The Wheels framework uses a sophisticated monorepo structure that produces multiple ForgeBox packages working together to create the complete developer ecosystem. Understanding this architecture is crucial for framework development and maintenance.

### Component Overview

The monorepo contains four main distributable components plus documentation:

1. **Wheels CLI** (`wheels-cli`) - CommandBox module providing development tools
2. **Wheels Core** (`wheels-core`) - Framework runtime installed in `/vendor/wheels`  
3. **Base Template** (`wheels-base-template`) - Starting structure downloaded by CLI for new applications
4. **Starter App** (`wheels-starterapp`) - Complete example application
5. **Documentation** (`/docs`) - Comprehensive guides published to wheels.dev/guides

### CLI Component Architecture

**Source Location**: `/cli/src/`
- `ModuleConfig.cfc` - CommandBox module configuration
- `commands/wheels/` - Hierarchical command structure (all extend `base.cfc`)
- `models/` - Business logic with WireBox dependency injection
- `templates/` - Code generation templates using `{{variable}}` syntax
- `box.json` - Package metadata with `type: "commandbox-modules"`

**Build Process** (`tools/build/scripts/build-cli.sh`):
1. Copies `/cli/src/` content to `build-wheels-cli/wheels-cli/`
2. Replaces version placeholders (`@build.version@`, `@build.number@`)
3. Creates ZIP package with checksums
4. Publishes to ForgeBox as `wheels-cli` package

**Distribution & Usage**:
- Install: `box install wheels-cli`
- CommandBox recognizes the module type and registers `wheels` namespace
- Commands become available: `wheels g app`, `wheels g model`, etc.
- After CLI modifications: `box reload` to reload CommandBox

### Base Template Architecture

**Source Location**: `/templates/base/src/`
- Complete starter application structure (`app/`, `config/`, `views/`, etc.)
- Code generation snippets in `app/snippets/` (used by CLI generators)
- `box.json` with dependency on `wheels-core`
- Bootstrap-ready layouts and configuration examples

**Build Process** (`tools/build/scripts/build-base.sh`):
1. Copies `/templates/base/src/` content to `build-wheels-base/`
2. Includes AI documentation, VS Code snippets, and test framework
3. Replaces version placeholders (`@build.version@`, `@build.number@`)
4. Creates ZIP package with checksums
5. Publishes to ForgeBox as `wheels-base-template` package with `type: "cfwheels-templates"`

**Distribution & Usage**:
- Published to ForgeBox as `wheels-base-template` package
- CLI's `wheels g app myapp` command downloads from ForgeBox and extracts structure
- Provides consistent MVC directory layout and development server setup
- Includes proper dependency configuration for `wheels-core`, `wirebox`, `testbox`
- Snippets ensure generated code follows framework patterns

### Core Framework Architecture

**Source Location**: `/core/src/wheels/`
- Complete framework implementation (Controller.cfc, Model.cfc, etc.)
- Database adapters for H2, MySQL, PostgreSQL, SQLServer, Oracle
- Migration system with database-specific implementations
- Testing framework and utilities
- All internal methods use `$` prefix convention

**Build Process** (`tools/build/scripts/build-core.sh`):
1. Copies `/core/src/wheels/` content to `build-wheels-core/wheels/`
2. Includes documentation from `/docs/` directory
3. Replaces version placeholders
4. Creates ZIP package with checksums
5. Publishes to ForgeBox as `wheels-core` package

**Distribution**:
- New applications include `wheels-core` dependency in `box.json`
- `box install` places framework in `/vendor/wheels/` directory
- Application.cfc includes framework mapping for access

### Documentation Architecture

**Source Location**: `/docs/src/`
- Comprehensive framework guides covering all major topics
- Organized into logical sections (controllers, models, views, CLI, etc.)
- Written in Markdown with GitBook-style formatting
- MkDocs configuration for static site generation

**Build Process** (`docs/mkdocs.yml` + GitHub Actions):
1. MkDocs processes Markdown files from `/docs/src/`
2. Applies Material theme with custom styling (`docs/stylesheets/gitbook.css`)
3. Generates static HTML site with navigation, search, and responsive design
4. GitHub Actions workflow (`docs-sync.yml`) syncs content to shared hosting

**Publication**:
- Documentation published to `wheels.dev/guides` (and `guides.cfwheels.org`)
- Automated deployment via rsync to shared hosting directory
- Version-specific paths (e.g., `/3.0.0/guides`) for different framework versions
- Assets and images synchronized to public directories

### Build & Release Pipeline

**GitHub Actions Workflows**:
- `release.yml` - Handles main branch releases
- `snapshot.yml` - Creates development snapshots
- `pr.yml` - Tests pull requests across all CFML engines
- `docs-sync.yml` - Syncs documentation to wheels.dev/guides

**Build Orchestration**:
1. Version calculation from `templates/base/src/box.json` + build number
2. Parallel execution of build scripts for all components
3. Version placeholder replacement throughout all packages
4. ZIP creation with MD5 and SHA512 checksums
5. ForgeBox publication with package verification

**Publication Script** (`tools/build/scripts/publish-to-forgebox.sh`):
- Verifies package contents and structure
- Authenticates with ForgeBox API
- Publishes all packages atomically
- Handles force updates and error recovery
- Creates "bleeding edge" versions for continuous deployment

### Package Dependencies & Integration

**ForgeBox Package Flow**:
```
Developer Workflow:
1. box install wheels-cli           # Downloads CLI CommandBox module
2. wheels g app myapp              # CLI downloads wheels-base-template from ForgeBox
3. box install                     # App downloads wheels-core from ForgeBox to /vendor/wheels

ForgeBox Packages:
├── wheels-cli (CommandBox module)
├── wheels-base-template (app structure)
├── wheels-core (framework runtime)
└── wheels-starterapp (example app)

Documentation:
└── wheels.dev/guides (comprehensive framework guides)
```

**Integration Points**:
- CLI downloads `wheels-base-template` package from ForgeBox during `wheels g app`
- Base template's `box.json` specifies `wheels-core` dependency
- `box install` in new app downloads `wheels-core` to `/vendor/wheels/`
- Generated code follows core framework conventions (`$` prefix, `config()` methods)
- All packages share synchronized version numbers through build process

### Development Workflow

**For CLI Development**:
1. Modify files in `/cli/src/`
2. Test in `/workspace/` directory
3. Run `box reload` after changes
4. Use `.claude/commands/cli/test-next-group.md` for systematic testing

**For Core Development**:
1. Modify files in `/core/src/wheels/`
2. Run framework tests: `wheels test run` or `box testbox run`
3. Test across engines: `docker compose up adobe2021 -d` etc.

**For Build System**:
1. Build scripts in `/tools/build/scripts/`
2. Package templates in `/tools/build/{cli,core,base}/`
3. GitHub Actions coordinate the entire release process

**For Documentation**:
1. Edit Markdown files in `/docs/src/`
2. Test locally with `mkdocs serve` (requires MkDocs and Material theme)
3. GitHub Actions automatically syncs changes to wheels.dev/guides

### Key Architecture Principles

**Separation of Concerns**:
- CLI handles development-time operations
- Core provides runtime functionality
- Base template ensures consistency
- Build system manages distribution

**Version Synchronization**:
- All packages share the same version number
- Build process ensures atomic updates across ecosystem
- Dependency resolution prevents version conflicts

**Template-Driven Code Generation**:
- CLI uses sophisticated template system with `{{variable}}` syntax
- Templates check `app/snippets/` first, then fall back to CLI templates
- Ensures generated code matches application patterns

This architecture allows independent development of each component while maintaining a cohesive developer experience through shared patterns, synchronized versioning, and coordinated distribution via ForgeBox.

## Recent Changes (2025-06-21)

### Configuration Directory Move
- **BREAKING CHANGE**: Configuration moved from `/app/config` to `/config` at root level
- This affects: routes.cfm, settings.cfm, environment.cfm, and all environment-specific settings
- Mapping added to Application.cfc for compatibility

### Recent CLI Enhancements (2025-06-20)

#### Fixed Issues
- Database and server command namespaces now properly route to subcommands
- Test commands now detect actual server port instead of hardcoded 8080
- Scaffold generator supports non-interactive mode
- Plugin and console commands have proper dependency injection
- Get/set commands now route to their subcommands correctly
- Model generator now creates foreign key columns for relationships
- View generator now respects layout parameter
- App wizard includes application name validation

#### New Features
- **Deploy System**: Full production deployment with zero-downtime support
- **Security Scanner**: Vulnerability detection and automated fixes
- **Performance Optimizer**: Caching, asset optimization, query analysis
- **Environment Management**: Multi-environment configuration and switching
- **Advanced Generators**: API resources, frontend scaffolding, job scheduling

## Commit Message Guidelines
- Use conventional commit format: `type: description`
- Types: feat, fix, docs, style, refactor, test, chore
- Keep subject line under 50 characters
- Don't add Claude signature to commits
- Don't add Claude signature to PR descriptions