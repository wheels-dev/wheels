# wheels env setup

Setup a new environment configuration for your Wheels application.

## Synopsis

```bash
wheels env setup [name] [options]
```

## Description

The `wheels env setup` command creates and configures new environments for your Wheels application. It generates environment-specific configuration files, database settings, and initializes the environment structure.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Environment name (e.g., staging, qa, production) | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--base` | Base environment to copy from | `development` |
| `--database` | Database name | `wheels_[name]` |
| `--datasource` | CF datasource name | `wheels_[name]` |
| `--debug` | Enable debug mode | `false` |
| `--cache` | Enable caching | Based on name |
| `--reload-password` | Password for reload | Random |
| `--skip-database` | Skip database creation | `false` |
| `--force` | Overwrite existing environment | `false` |
| `--help` | Show help information |

## Examples

### Setup basic environment
```bash
wheels env setup staging
```

### Setup with custom database
```bash
wheels env setup qa --database=wheels_qa_db --datasource=qa_datasource
```

### Copy from production settings
```bash
wheels env setup staging --base=production
```

### Setup with specific options
```bash
wheels env setup production --debug=false --cache=true --reload-password=secret123
```

### Skip database setup
```bash
wheels env setup testing --skip-database
```

## What It Does

1. **Creates Configuration Directory**:
   ```
   /config/[environment]/
   └── settings.cfm
   ```

2. **Generates Settings File**:
   - Database configuration
   - Environment-specific settings
   - Debug and cache options
   - Security settings

3. **Sets Up Database** (unless skipped):
   - Creates database
   - Configures datasource
   - Tests connection

4. **Updates Environment Registry**:
   - Adds to available environments
   - Sets up environment detection

## Generated Configuration

Example `config/staging/settings.cfm`:

```cfml
<cfscript>
// Environment: staging
// Generated: 2024-01-15 10:30:45

// Database settings
set(dataSourceName="wheels_staging");

// Environment settings
set(environment="staging");
set(showDebugInformation=true);
set(showErrorInformation=true);

// Caching
set(cacheFileChecking=false);
set(cacheImages=false);
set(cacheModelInitialization=false);
set(cacheControllerInitialization=false);
set(cacheRoutes=false);
set(cacheActions=false);
set(cachePages=false);
set(cachePartials=false);
set(cacheQueries=false);

// Security
set(reloadPassword="generated_secure_password");

// URLs
set(urlRewriting="partial");

// Custom settings for staging
set(sendEmailOnError=true);
set(errorEmailAddress="dev-team@example.com");
</cfscript>
```

## Environment Types

### Development
- Full debugging
- No caching
- Detailed errors
- Hot reload

### Testing
- Test database
- Debug enabled
- Isolated data
- Fast cleanup

### Staging
- Production-like
- Some debugging
- Performance testing
- Pre-production validation

### Production
- No debugging
- Full caching
- Error handling
- Optimized performance

### Custom
Create specialized environments:
```bash
wheels env setup performance-testing --base=production --cache=false
```

## Database Configuration

### Automatic Setup
```bash
wheels env setup staging
# Creates: wheels_staging database
# Datasource: wheels_staging
```

### Custom Database
```bash
wheels env setup staging \
  --database=staging_db \
  --datasource=myapp_staging
```

### Database URL
```bash
wheels env setup production \
  --database-url="mysql://user:pass@host:3306/db"
```

## Environment Variables

The command sets up support for:

```bash
# .env.staging
WHEELS_ENV=staging
WHEELS_DATASOURCE=wheels_staging
WHEELS_DEBUG=true
WHEELS_CACHE=false
DATABASE_URL=mysql://localhost/wheels_staging
```

## Configuration Inheritance

Environments can inherit settings:

```cfml
// config/staging/settings.cfm
<cfinclude template="../production/settings.cfm">

// Override specific settings
set(showDebugInformation=true);
set(cacheQueries=false);
```

## Validation

After setup, the command validates:

1. Configuration file syntax
2. Database connectivity
3. Directory permissions
4. Environment detection

## Environment Detection

Configure how environment is detected:

```cfml
// config/environment.cfm
if (cgi.server_name contains "staging") {
    set(environment="staging");
} else if (cgi.server_name contains "qa") {
    set(environment="qa");
} else {
    set(environment="production");
}
```

## Best Practices

1. **Naming Convention**: Use clear, consistent names
2. **Base Selection**: Choose appropriate base environment
3. **Security**: Use strong reload passwords
4. **Documentation**: Document environment purposes
5. **Testing**: Test configuration before use

## Advanced Configuration

### Multiple Databases
```bash
wheels env setup reporting \
  --database=wheels_reporting \
  --read-database=wheels_replica
```

### Load Balancing
```bash
wheels env setup production \
  --servers=web1,web2,web3 \
  --load-balancer=nginx
```

### Feature Flags
```cfml
// In settings.cfm
set(features={
    newCheckout: true,
    betaAPI: false,
    debugToolbar: true
});
```

## Troubleshooting

### Database Creation Failed
- Check database permissions
- Verify connection settings
- Use `--skip-database` and create manually

### Configuration Errors
- Check syntax in settings.cfm
- Verify file permissions
- Review error logs

### Environment Not Detected
- Check environment.cfm logic
- Verify server variables
- Test detection rules

## Migration

### From Existing Environment
```bash
# Export existing config
wheels env export production > prod-config.json

# Import to new environment
wheels env setup staging --from-config=prod-config.json
```

## Use Cases

1. **Multi-Stage Pipeline**: dev → staging → production
2. **Feature Testing**: Isolated feature environments
3. **Performance Testing**: Dedicated performance environment
4. **Client Demos**: Separate demo environments
5. **A/B Testing**: Multiple production variants

## Notes

- Environment names should be lowercase
- Avoid spaces in environment names
- Each environment needs unique database
- Restart application after setup
- Test thoroughly before using

## See Also

- [wheels env](env.md) - Environment management overview
- [wheels env list](env-list.md) - List environments
- [wheels env switch](env-switch.md) - Switch environments
- [wheels config](../config/config-env.md) - Configuration management