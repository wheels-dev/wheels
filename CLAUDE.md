# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Test Commands

- Run a single test: `wheels test app TestName`
- Run a test package: `wheels test app testBundles=controllers`
- Run a specific test spec: `wheels test app testBundles=controllers&testSpecs=testCaseOne`
- Format code: `box run-script format` (uses cfformat)
- Check formatting: `box run-script format:check`
- Reload application: `wheels reload [development|testing|maintenance|production]`
- Run all tests with Docker: `docker compose up` (runs on multiple CFML engines)
- Run specific engine tests: `docker compose --profile lucee up -d`

## Code Style Guidelines

- Use camelCase for variable/function names and CapitalizedCamelCase for CFC names
- Indent with tabs, 2 spaces per tab
- Max line length: 120 characters
- Function parameters use camelCase
- Scoped variables use lowercase.camelCase (e.g., application.myVar)
- Pascal case for built-in CF functions (e.g., IsNumeric(), Trim())
- Use `local` scope for function variables (not var-scoped)
- Prefix "private" methods with `$` (e.g., `$query()`) for internal use
- Follow Wheels validation/callback patterns in models
- Use transactions for database tests
- Use TestBox for writing tests with describe/it syntax

## CLI Commands

- Don't mix positional and named attributes when calling CLI commands
- Named attributes should use attribute=value syntax
- Boolean attributes can use --attribute as a shortcut instead of attribute=true
- Parameter syntax - CommandBox requires named attributes (name=value) instead of mixing positional and named parameters

## Testing the Framework and CLI

- The CLI is written in CFML and is packaged as a module for CommandBox
- Launch CommandBox with `box` shell command
- Use the `workspace` directory as a sandbox to test wheels cli commands
- First create an app with `wheels g app` command
- Then start the web server with `server start` commandbox command
- To restart the webserver use `server restart` or `server stop` followed by `server start`
- If changes are made to the CLI commands then reload Commandbox with `box reload` or `exit` followed by `box`

## High-Level Architecture

### Core Components
- **Controller.cfc**: Base controller providing MVC functionality, rendering, filters, and provides() for content negotiation
- **Model.cfc**: ActiveRecord-style ORM with associations, validations, callbacks, and database adapters
- **Dispatch.cfc**: Request routing and parameter handling
- **Global.cfc**: Framework-wide helper functions and utilities
- **Mapper.cfc**: RESTful routing configuration with resource mapping

### Directory Structure
- `/vendor/wheels/`: Core framework files (do not modify directly)
- `/app/`: Application code (controllers, models, views)
- `/config/`: Environment-specific configuration
- `/cli/`: CommandBox CLI module for code generation and tasks
- `/tests/`: Framework test suite
- `/docker/`: Docker configurations for multi-engine testing

### Key Patterns
- **Controller Initialization**: Use `config()` method, NOT `init()` for controller setup
- **Private Methods**: Prefix with `$` (e.g., `$callAction()`, `$performedRender()`)
- **Content Negotiation**: Use `provides()` or `onlyProvides()` in controller config()
- **View Rendering**: Automatic for HTML, skipped for JSON/XML when using renderText/renderWith

### Database Testing
- Create `wheelstestdb` database and datasource
- Supports H2, MySQL, PostgreSQL, SQL Server, Oracle
- Docker compose provides all database servers for testing
- Use `db={{database}}` URL parameter to switch datasources

### Development Workflow
1. Make changes to framework files in `/vendor/wheels/`
2. Test using workspace sandbox or Docker containers
3. Run tests: `wheels test app` or use Docker TestUI at localhost:3000
4. Ensure all CFML engines pass (Lucee 5/6/7, Adobe 2018/2021/2023/2025)

## Important Notes

- Framework uses `config()` method for controller initialization, not `init()`
- Always check `$performedRenderOrRedirect()` before automatic view rendering
- Use `$requestContentType()` and `$acceptableFormats()` for content negotiation
- Test on multiple CFML engines before submitting PRs
- Follow existing patterns when adding new functionality