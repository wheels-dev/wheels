# Core Commands

Core commands provide essential functionality for managing Wheels applications, from initialization to monitoring and maintenance. These commands form the foundation of your Wheels CLI workflow.

## wheels init

Bootstrap an existing Wheels application for CLI usage or add CommandBox configuration to a legacy project.

### Syntax

```bash
wheels init [name] [directory] [reload] [datasourceName]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | No | Current directory name | Application name |
| directory | string | No | Current directory | Target directory |
| reload | string | No | - | Reload password for the application |
| datasourceName | string | No | - | Database datasource name |

### Description

The `init` command prepares an existing Wheels application for CommandBox usage by creating:
- `box.json` - CommandBox package descriptor
- `server.json` - Server configuration with port and CF engine settings

This is particularly useful for:
- Legacy Wheels applications without CommandBox support
- Setting up consistent development environments
- Preparing applications for CI/CD pipelines

### Examples

Initialize current directory:
```bash
wheels init
```

Initialize with specific settings:
```bash
wheels init myapp --reload=secret123 --datasourceName=myapp_db
```

Initialize a specific directory:
```bash
wheels init --directory=/path/to/legacy/app
```

### Notes

- Creates configuration files without modifying existing application code
- Detects existing Wheels version and configures appropriately
- Sets up H2 embedded database by default for development

---

## wheels info

Display comprehensive information about the Wheels CLI and framework installation.

### Syntax

```bash
wheels info
```

### Parameters

None

### Description

Provides essential debugging information including:
- Wheels CLI module version
- Wheels framework version (if in a Wheels project)
- CommandBox version
- Current working directory
- Server configuration status

### Examples

```bash
wheels info
```

Output example:
```
=================================
Wheels CLI Information
=================================
CLI Version:      1.0.0
Wheels Version:   3.0.0
CommandBox:       5.9.0
Working Dir:      /path/to/myapp
Server Status:    Running on port 3000
=================================
```

### Notes

- Use before reporting issues or seeking support
- Helpful for verifying installation and environment setup
- Automatically detects Wheels version from vendor/wheels directory

---

## wheels reload

Reload the Wheels application without restarting the server.

### Syntax

```bash
wheels reload [environment]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| environment | string | No | development | Environment to reload |

### Options

- `development` - Development environment
- `testing` - Testing environment  
- `maintenance` - Maintenance mode
- `production` - Production environment

### Description

Forces a reload of the Wheels application, clearing caches and reinitializing the framework. This is useful when:
- Configuration changes don't take effect
- Cached data needs to be cleared
- Switching between environments

### Examples

Reload default environment:
```bash
wheels reload
```

Reload specific environment:
```bash
wheels reload production
```

### Notes

- Requires reload password to be set in configuration
- Does not restart the underlying server process
- Clears all application caches
- Environment-specific settings are loaded on reload

---

## wheels destroy

Remove generated scaffolding code with confirmation prompts.

### Syntax

```bash
wheels destroy [name] [type]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name | string | Yes | - | Name of resource to destroy |
| type | string | No | scaffold | Type of code to destroy |

### Types

- `scaffold` - Remove complete scaffold (model, controller, views, migration)
- `controller` - Remove only controller and views
- `model` - Remove only model and migration

### Description

Reverses code generation by removing files created by generation commands. Always prompts for confirmation before deleting files.

### Examples

Remove complete scaffold:
```bash
wheels destroy Product
```

Remove only controller:
```bash
wheels destroy Product controller
```

### Notes

- Always prompts for confirmation (no --force flag)
- Cannot be undone - deleted files are not recoverable
- Does not reverse database migrations (run separately)
- Lists all files to be deleted before confirmation

---

## wheels watch

Monitor files for changes and automatically reload the application.

### Syntax

```bash
wheels watch [--paths] [--extensions] [--reload]
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| --paths | string | No | app/,config/ | Comma-separated paths to watch |
| --extensions | string | No | cfc,cfm | File extensions to monitor |
| --reload | boolean | No | true | Auto-reload on changes |

### Description

Starts a file watcher that monitors your application for changes and can automatically:
- Reload the application when files change
- Run tests when test files are modified
- Clear caches when configuration changes

### Examples

Watch with defaults:
```bash
wheels watch
```

Watch specific directories:
```bash
wheels watch --paths=app/models,app/controllers
```

Watch without auto-reload:
```bash
wheels watch --reload=false
```

### Notes

- Improves development workflow by eliminating manual reloads
- Excludes common directories like node_modules, .git
- Can be combined with testing workflows
- Press Ctrl+C to stop watching

---

## wheels deps

Install and manage application dependencies.

### Syntax

```bash
wheels deps [list|install|update]
```

### Subcommands

### deps list

List all installed dependencies:
```bash
wheels deps list
```

Shows:
- Installed Wheels plugins
- CommandBox modules
- Version information
- Update availability

### deps install

Install dependencies from box.json:
```bash
wheels deps install
```

### deps update

Update all dependencies to latest versions:
```bash
wheels deps update
```

### Examples

```bash
# List current dependencies
wheels deps list

# Install missing dependencies
wheels deps install

# Update all dependencies
wheels deps update
```

### Notes

- Reads dependencies from box.json
- Manages both Wheels plugins and CommandBox modules
- Respects version constraints in configuration
- Creates lock file for reproducible installs

---

## wheels env

Manage application environments (delegates to subcommands).

### Syntax

```bash
wheels env [subcommand]
```

### Description

Parent command for environment management. Use subcommands for specific operations:
- `wheels env list` - List available environments
- `wheels env switch` - Switch active environment
- `wheels env setup` - Setup new environment

See [Configuration Commands](wheels-configuration-commands.md) for detailed environment management.

---

## Command Workflows

### Initial Setup Workflow

1. Clone existing project
2. Initialize CommandBox support:
   ```bash
   wheels init
   ```
3. Install dependencies:
   ```bash
   wheels deps install
   ```
4. Start development:
   ```bash
   wheels watch
   ```

### Daily Development Workflow

1. Check environment:
   ```bash
   wheels info
   ```
2. Start file watcher:
   ```bash
   wheels watch
   ```
3. Reload when needed:
   ```bash
   wheels reload
   ```

### Cleanup Workflow

1. List generated code:
   ```bash
   ls app/controllers
   ls app/models
   ```
2. Remove unwanted scaffolds:
   ```bash
   wheels destroy UnwantedResource
   ```

## Best Practices

1. **Always run `wheels info` first** when troubleshooting issues
2. **Use `wheels init` on legacy projects** to add modern tooling
3. **Keep dependencies updated** with regular `wheels deps update`
4. **Use `wheels watch` during development** for automatic reloading
5. **Confirm before destroying** - the destroy command cannot be undone

## Troubleshooting

### Reload Not Working

- Check reload password is set correctly
- Verify server is running
- Check application logs for errors

### Watch Command Issues

- Ensure watched paths exist
- Check file permissions
- Verify extensions are correct

### Dependency Conflicts

- Run `wheels deps list` to check versions
- Clear CommandBox cache if needed
- Check box.json for version constraints