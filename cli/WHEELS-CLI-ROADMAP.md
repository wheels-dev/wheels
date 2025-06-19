# Wheels CLI Roadmap - Modern Framework Commands

This document outlines the CLI commands that a modern Wheels framework should implement, inspired by Rails, Laravel, and leveraging CommandBox's native capabilities and the ForgeBox ecosystem.

## Philosophy: Embrace the Ecosystem

Rather than building everything from scratch, we should leverage existing CommandBox modules from ForgeBox where possible, focusing our development efforts on Wheels-specific functionality.

## Current State Analysis

### What We Have
- Basic generators (model, controller, view, resource, app)
- Database migration tools (dbmigrate namespace)
- Testing commands (basic test runner)
- Plugin management (install, list, remove)
- Extensive aliasing system (g → generate, db → dbmigrate, etc.)

### What We're Missing
Based on analysis comparing to Rails and Laravel, we're missing several categories of commands that modern frameworks provide.

## Proposed Command Structure

### 1. Server & Environment Management
Leverage CommandBox's native server capabilities with Wheels-specific wrappers:

```bash
wheels server start      # Start development server (wraps box server start)
wheels server stop       # Stop server (wraps box server stop)
wheels server restart    # Restart server
wheels server status     # Show server status
wheels server log        # Tail server logs
wheels server open       # Open app in browser
wheels console           # Interactive REPL with app context loaded
wheels runner <script>   # Execute arbitrary script in app context
wheels environment       # Display/switch current environment
```

### 2. Enhanced Generators

#### New Generators Needed
```bash
wheels g migration <name> [attributes]    # Generate database migration
wheels g mailer <name> [methods]         # Generate mailer component
wheels g job <name>                      # Generate background job
wheels g channel <name>                  # Generate WebSocket channel
wheels g serializer <name>               # Generate JSON/XML serializer
wheels g helper <name>                   # Generate helper functions
wheels g plugin <name>                   # Generate plugin scaffold
wheels g validator <name>                # Generate custom validator
wheels g middleware <name>               # Generate middleware component
wheels g service <name>                  # Generate service object
```

#### Destroy Commands (Inverse Operations)
```bash
wheels destroy model <name>              # Remove model and tests
wheels destroy controller <name>         # Remove controller and tests
wheels destroy view <name>               # Remove view files
wheels destroy resource <name>           # Remove full resource
wheels destroy scaffold <name>           # Remove scaffolded code
wheels destroy migration <name>          # Remove migration file
wheels destroy mailer <name>             # Remove mailer
wheels destroy job <name>                # Remove job
```

### 3. Database Management

```bash
wheels db create                         # Create database
wheels db drop                           # Drop database
wheels db seed                           # Run database seeders
wheels db rollback [steps]               # Rollback migrations
wheels db status                         # Show migration status
wheels db version                        # Show current schema version
wheels db setup                          # create + migrate + seed
wheels db reset                          # drop + create + migrate + seed
wheels db dump                           # Export database schema
wheels db restore <file>                 # Restore from dump
```

### 4. Advanced Testing (via TestBox CLI Module)

**Strategy**: Install and integrate `commandbox-testbox-cli` module instead of building custom test runners.

```bash
# First, install TestBox CLI module
box install commandbox-testbox-cli

# Then use these commands (provided by TestBox CLI)
wheels test:all                          # Wrapper for testbox run
wheels test:unit                         # Wrapper for testbox run --directory=tests/unit
wheels test:integration                  # Wrapper for testbox run --directory=tests/integration
wheels test:watch                        # Wrapper for testbox watch
wheels test:coverage                     # Wrapper for testbox run --coverage
```

### 5. Asset & Cache Management

```bash
wheels assets:precompile                 # Compile assets for production
wheels assets:clean                      # Remove old compiled assets
wheels assets:clobber                    # Remove all compiled assets
wheels cache:clear [name]                # Clear specific or all caches
wheels log:clear                         # Clear log files
wheels log:tail [env]                    # Tail log files
wheels tmp:clear                         # Clear temporary files
```

### 6. Enhanced Plugin Management

```bash
wheels plugin search <term>              # Search ForgeBox for plugins
wheels plugin info <name>                # Show plugin details
wheels plugin update <name>              # Update specific plugin
wheels plugin update:all                 # Update all plugins
wheels plugin outdated                   # List outdated plugins
wheels plugin init                       # Initialize new plugin
```

### 7. Application Utilities

```bash
wheels routes [--format=table|json]      # Display all routes
wheels routes:match <url>                # Find matching route
wheels about                             # Show framework/env info
wheels stats                             # Code statistics
wheels notes [TODO|FIXME|OPTIMIZE]       # Extract annotations
wheels doctor                            # Health check
wheels dependencies                      # Show dependency tree
wheels version                           # Show Wheels version
```

### 8. Configuration & Security

**Strategy**: Use `commandbox-dotenv` for environment management.

```bash
# First, install dotenv module
box install commandbox-dotenv

# Custom Wheels commands
wheels config:dump [env]                 # Export configuration
wheels config:check                      # Validate configuration
wheels config:diff <env1> <env2>         # Compare environments
wheels secret                            # Generate secret key

# Environment management via dotenv
# .env files are automatically loaded by CommandBox
```

### 9. Development Workflow

```bash
wheels init [--skip-bundle]              # Initialize in existing project
wheels upgrade                           # Interactive upgrade wizard
wheels benchmark <url>                   # Simple benchmarking
wheels profile <url>                     # Profile request
wheels docs                              # Open documentation
wheels docs:generate                     # Generate API docs
```

### 10. Maintenance Commands

```bash
wheels maintenance:on                    # Enable maintenance mode
wheels maintenance:off                   # Disable maintenance mode
wheels cleanup:logs [days]               # Clean old log files
wheels cleanup:tmp [days]                # Clean old temp files
wheels cleanup:sessions                  # Clean expired sessions
```

## Implementation Strategy - Ecosystem First Approach

### Leverage Existing Modules

1. **Testing**: Use `commandbox-testbox-cli` (14,663 installs, actively maintained)
   - Provides test running, reporting, and generation
   - Has watch mode and coverage built-in
   - No need to build custom test infrastructure

2. **Environment Configuration**: Use `commandbox-dotenv` (641,266 installs)
   - Industry-standard .env file support
   - Automatic environment variable loading
   - Simplifies configuration management

3. **Code Formatting**: Continue using `commandbox-cfformat` (511,650 installs)
   - Already integrated in Wheels workflow
   - Consistent code formatting across projects

4. **Documentation**: Consider `commandbox-docbox` (150,514 installs)
   - For generating API documentation
   - Could document both framework and applications

5. **Database Migrations**: Evaluate `commandbox-migrations` (60,198 installs)
   - Study implementation for inspiration
   - Consider if it can complement Wheels migrations

### Focus Custom Development On

### Phase 1: Foundation (Priority: High)
1. **Module Integration**
   - Install and configure TestBox CLI
   - Install and configure dotenv
   - Create thin wrappers for Wheels-specific usage
   - Document module dependencies

2. **Essential Generators** (Custom Development)
   - `wheels g migration`
   - `wheels g mailer`
   - `wheels g service`
   - Complete destroy namespace

3. **Database Commands** (Custom Development)
   - Wrap existing dbmigrate with cleaner interface
   - Add create/drop/seed functionality
   - Improve status reporting

### Phase 2: Developer Experience (Priority: Medium)
1. **Testing Enhancements**
   - Organize test runners by type
   - Add coverage integration
   - Implement watch mode

2. **Utilities**
   - `wheels routes` command
   - `wheels about` information
   - `wheels stats` code metrics

3. **Asset Management**
   - Basic asset compilation
   - Cache clearing commands
   - Log management

### Phase 3: Advanced Features (Priority: Low)
1. **Console & REPL**
   - Interactive console with app context
   - Script runner functionality

2. **Security & Config**
   - Credentials management
   - Configuration validation

3. **Advanced Tooling**
   - Profiling and benchmarking
   - Documentation generation
   - Health checks

## CommandBox Integration Points

### Leverage Existing Features
- **Server Management**: Wrap `box server` commands
- **Package Management**: Integrate with ForgeBox
- **Testing**: Use TestBox CLI module directly
- **Environment**: Use dotenv module
- **Code Quality**: Use cfformat module
- **Documentation**: Consider DocBox module
- **REPL**: Build on CommandBox REPL
- **Task Runners**: Use CommandBox task runners

### Custom Extensions (Wheels-Specific)
- Model/Controller/View generators with Wheels patterns
- Database commands for Wheels ORM
- Route inspection for Wheels routing
- Plugin management for Wheels plugins
- Console/REPL with Wheels application context

### Module Dependencies
Add to box.json:
```json
{
  "dependencies": {
    "commandbox-testbox-cli": "^1.0.0",
    "commandbox-dotenv": "^1.0.0",
    "commandbox-cfformat": "^1.0.0"
  },
  "devDependencies": {
    "commandbox-docbox": "^1.0.0"
  }
}
```

## Migration Path

1. **Maintain Backward Compatibility**
   - Keep existing commands working
   - Preserve current aliases
   - Deprecate gradually with warnings

2. **Progressive Enhancement**
   - Add new commands without breaking old ones
   - Provide migration guides
   - Update documentation incrementally

3. **Community Feedback**
   - Beta test new commands
   - Gather usage analytics
   - Iterate based on feedback

## Success Metrics

- **Developer Productivity**: Reduced time to complete common tasks
- **Feature Parity**: Match 80% of Rails/Laravel CLI capabilities
- **Adoption Rate**: Track usage of new vs old commands
- **Community Satisfaction**: Survey results and GitHub issues

## Conclusion

This roadmap positions Wheels as a modern framework with comprehensive CLI tooling. By embracing the ForgeBox ecosystem and leveraging existing CommandBox modules, we can:

1. **Reduce Development Time**: Use battle-tested modules for common functionality
2. **Improve Reliability**: Leverage modules with thousands of users and active maintenance
3. **Focus on Wheels-Specific Features**: Concentrate efforts on what makes Wheels unique
4. **Benefit from Community**: Updates and improvements to modules benefit all users

The "ecosystem first" approach combined with targeted custom development for Wheels-specific features provides the best balance of functionality, maintainability, and development efficiency.

## Recommended Module Installation

```bash
# Essential modules for modern Wheels development
box install commandbox-testbox-cli
box install commandbox-dotenv
box install commandbox-cfformat

# Optional but recommended
box install commandbox-docbox
```