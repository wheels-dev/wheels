# CLI Documentation Update Summary

## Changes Made

### AI-CLI.md Updates
1. **Fixed parameter naming**: Changed from kebab-case to camelCase to match actual CLI implementation
   - `reload-password` → `reloadPassword`
   - `datasource-name` → `datasourceName` 
   - `cfml-engine` → `cfmlEngine`
   - `--use-bootstrap` → `--useBootstrap`
   - `--setup-h2` → `--setupH2`

2. **Updated default values**:
   - Template default: `'wheels-base-template@BE'` (not `'Base'`)
   - `setupH2` default: `true` (not `false`)
   - `init` default: `false` (not `true`)
   - Test format default: `"json"` (not `"simple"`)

3. **Added deprecation warning** for `wheels test` command (use `wheels test run` instead)

4. **Removed non-existent commands**:
   - `wheels db create`
   - `wheels db drop` 
   - `wheels db console`

5. **Added missing command sections**:
   - Analysis commands (`wheels analyze`)
   - Deployment commands (`wheels deploy`)
   - Optimization commands (`wheels optimize`)
   - Security commands (`wheels security`)
   - Documentation commands (`wheels docs`)
   - Plugin commands (`wheels plugins`)
   - Environment commands (`wheels env`)
   - Configuration commands (`wheels config`)

6. **Fixed migration commands** to use actual syntax:
   - `wheels g migration` → `wheels dbmigrate create table/column/blank`
   - `wheels db migrate` → `wheels dbmigrate latest`

### guides/command-line-tools Updates

1. **Updated generate/app.md**:
   - Fixed all parameter names to camelCase
   - Updated default template name
   - Corrected default values (setupH2=true)
   - Fixed command examples to use named parameters

2. **Updated testing/test.md**:
   - Added prominent deprecation warning
   - Fixed parameter names (serverName not servername)
   - Updated default values to match actual implementation
   - Added migration guide to new `wheels test run` command

## Commands Documented in AI-CLI.md

### Core Commands
- `wheels init` - Initialize existing app
- `wheels info` - Show version info
- `wheels reload` - Reload application
- `wheels destroy` - Remove components
- `wheels watch` - Watch for changes
- `wheels deps` - Manage dependencies

### Generator Commands
- `wheels generate app` (g app) - Create new application
- `wheels generate controller` (g controller) - Generate controller
- `wheels generate model` (g model) - Generate model
- `wheels generate scaffold` - Generate CRUD scaffold
- `wheels generate view` (g view) - Generate views
- `wheels generate test` (g test) - Generate tests
- `wheels generate route` - Generate routes
- `wheels generate property` - Add model properties

### Database Commands
- `wheels dbmigrate latest` - Run all migrations
- `wheels dbmigrate up` - Run next migration
- `wheels dbmigrate down` - Rollback last migration
- `wheels dbmigrate exec` - Execute specific migration
- `wheels dbmigrate info` - Show migration status
- `wheels dbmigrate reset` - Reset all migrations
- `wheels dbmigrate create table` - Create table migration
- `wheels dbmigrate create column` - Add column migration
- `wheels dbmigrate create blank` - Blank migration
- `wheels dbmigrate remove table` - Remove table migration
- `wheels db schema` - Export database schema
- `wheels db seed` - Seed database

### Testing Commands
- `wheels test` (DEPRECATED) - Old test command
- `wheels test run` - Run TestBox tests
- `wheels test coverage` - Generate coverage report
- `wheels test debug` - Debug test execution
- `wheels test migrate` - Test migration helper

### Analysis Commands
- `wheels analyze` - Run all analyses
- `wheels analyze code` - Code quality analysis
- `wheels analyze performance` - Performance analysis
- `wheels analyze security` - Security analysis

### Deployment Commands
- `wheels deploy init` - Initialize deployment
- `wheels deploy push` - Deploy application
- `wheels deploy status` - Check deployment status
- `wheels deploy rollback` - Rollback deployment
- `wheels deploy logs` - View deployment logs
- `wheels deploy hooks` - Execute deployment hooks
- `wheels deploy secrets` - Manage secrets
- `wheels deploy audit` - Deployment audit

### Other Commands
- `wheels optimize` - Run optimizations
- `wheels optimize performance` - Performance optimization
- `wheels security scan` - Security scanning
- `wheels docs generate` - Generate documentation
- `wheels docs serve` - Serve docs locally
- `wheels plugins list` - List plugins
- `wheels plugins install` - Install plugin
- `wheels plugins remove` - Remove plugin
- `wheels env` - Show current environment
- `wheels env list` - List environments
- `wheels env setup` - Setup environment
- `wheels env switch` - Switch environment
- `wheels config list` - List configuration
- `wheels config set` - Set configuration value
- `wheels config env` - Environment config

## Commands Still Missing Documentation
Based on the actual CLI files found:
- `wheels generate api-resource` (disabled)
- `wheels generate app-wizard` - Interactive app creation
- `wheels generate frontend` (disabled)
- `wheels generate snippets` - Generate code snippets
- `wheels ci init` - CI/CD initialization
- `wheels docker init` - Docker initialization
- `wheels docker deploy` - Docker deployment

## Next Steps

1. Review all guides/command-line-tools documentation files for parameter inconsistencies
2. Add documentation for missing commands listed above
3. Update any examples that use incorrect parameter syntax
4. Consider adding a migration guide for users familiar with old syntax
5. Add notes about CommandBox parameter requirements (named parameters)

## Final Updates Completed

### Missing Commands Added to AI-CLI.md:

1. **wheels generate app-wizard** (alias: `wheels new`)
   - Added documentation for interactive app creation wizard
   - Listed all prompts the wizard asks for
   - Noted it's an alternative to `wheels g app`

2. **wheels generate snippets**
   - Added documentation for copying code snippet templates
   - Explained it creates app/snippets/ directory
   - Noted it provides reusable code patterns

3. **Analysis and Optimization Commands Section**
   - Added complete new section with all analysis commands
   - Documented `wheels analyze` with all subcommands
   - Documented `wheels optimize` (noted as under development)
   - Documented `wheels security` (noted as under development)
   - Documented `wheels watch` with all parameters and options

### Additional Fixes:
- Fixed remaining instances of non-existent commands in examples
- Updated test commands from deprecated `wheels test app` to `wheels test run`
- Fixed parameter inconsistencies in examples
- Corrected migration command examples

### Commands NOT Added (Disabled/Non-functional):
- wheels generate api-resource (broken)
- wheels generate frontend (disabled)
- wheels ci init (unclear status)
- wheels docker init/deploy (unclear status)

The AI-CLI.md documentation now accurately reflects all functional CLI commands with correct syntax and parameters.