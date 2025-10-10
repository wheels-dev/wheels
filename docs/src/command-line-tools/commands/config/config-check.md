# Wheels config check

## Overview

The `wheels config check` command validates your Wheels application configuration settings across different environments. It performs comprehensive checks on security settings, database configuration, environment-specific settings, and more, helping you identify potential issues before deployment.

## Command Syntax

```bash
wheels config check [environment] [--verbose] [--fix]
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| environment | string | No | The environment to check (development, testing, production). If not specified, detects from current configuration |
| --verbose | flag | No | Show detailed validation information including fix suggestions |
| --fix | flag | No | Attempt to automatically fix certain issues |

## Basic Usage

### Check Current Environment
```bash
wheels config check
```

### Check Specific Environment
```bash
wheels config check production
```

### Check with Detailed Output
```bash
wheels config check --verbose
```

### Auto-fix Issues
```bash
wheels config check --fix
```

### Combined Options
```bash
wheels config check production --verbose --fix
```

## What Gets Checked

The command performs validation across multiple configuration areas:

### 1. Configuration Files
- Verifies existence of `config/settings.cfm`
- Checks for environment-specific settings files
- Validates file structure and syntax

### 2. Required Settings
- **Datasource Configuration**: Ensures a datasource is configured
- **Core Settings**: Validates essential Wheels configuration parameters

### 3. Security Configuration
- **Sensitive Values**: Detects hardcoded passwords, API keys, tokens
- **Debug Mode**: Ensures debug is disabled in production
- **Error Emails**: Checks error notification setup for production
- **Reload Password**: Validates reload password strength
- **SSL/HTTPS**: Verifies SSL enforcement in production
- **Session Security**: Checks session timeout settings
- **Error Information**: Ensures error details are hidden in production

### 4. Database Configuration
- **Datasource Validity**: Verifies datasource exists and is accessible
- **Migration Settings**: Checks auto-migration configuration
- **Connection Settings**: Validates database connection parameters

### 5. Environment Settings
- **Environment Directory**: Checks for environment-specific config directories
- **Caching Configuration**: Validates cache settings for production
- **Performance Settings**: Reviews optimization configurations

### 6. .env File Configuration
- **File Existence**: Checks for .env file presence
- **File Permissions**: Validates security permissions
- **Git Ignore**: Ensures .env is in .gitignore
- **Environment Variables**: Verifies WHEELS_ENV or Environment variable

### 7. Production-Specific (when checking production)
- **SSL Enforcement**: Validates forceSSL setting
- **Session Management**: Reviews session timeout configuration
- **Error Handling**: Ensures proper error information hiding
- **Cache Settings**: Verifies all caching is enabled

## Output Format

The command provides real-time status as it performs checks:

```
========================================
Configuration Validation
Environment: development
========================================

Checking configuration files... [OK]
Checking required settings... [OK]
Checking security configuration... [WARNING]
Checking database configuration... [OK]
Checking environment-specific settings... [WARNING]
Checking .env file configuration... [FAILED]

========================================
```

### Status Indicators

- **[OK]** - Check passed successfully
- **[WARNING]** - Non-critical issues found
- **[FAILED]** - Critical errors detected
- **[FIXED]** - Issue was automatically fixed

## Results Display

### Error Output
```
[ERRORS] (2):
   - Missing config/settings.cfm file
   - Datasource 'myapp_db' not found
```

### Warning Output
```
[WARNINGS] (3):
   - Possible hardcoded sensitive value in 'apiKey'
   - No environment-specific config directory for 'production'
   - Automatic database migration is enabled
```

### Fixed Issues Output
```
[FIXED] Issues:
   - Created sample .env file
   - Added .env to .gitignore
```

### Summary Output
```
[PASSED] Configuration validation successful!
  All checks completed successfully.
```

Or with issues:
```
[FAILED] Configuration check failed
  Found: 2 errors, 3 warnings
  
  Tip: Run with --verbose flag for detailed fix suggestions
```

## Verbose Mode

When using `--verbose`, each issue includes detailed fix suggestions:

```bash
wheels config check --verbose
```

Output:
```
[ERRORS] (1):
   - Debug mode is enabled in production
     --> Fix: Set showDebugInformation = false in config/production/settings.cfm
```

## Auto-Fix Feature

The `--fix` flag attempts to automatically resolve certain issues:

### What Can Be Auto-Fixed
- Create sample .env file if missing
- Add .env to .gitignore
- Create basic configuration templates
- Set default secure values

### Example
```bash
wheels config check --fix
```

Output:
```
[FIXED] Issues:
   - Created sample .env file
   - Added .env to .gitignore
```

## Environment Detection

The command detects the current environment in the following priority:

1. Command parameter (if specified)
2. WHEELS_ENV in .env file
3. Environment in .env file
4. WHEELS_ENV system environment variable
5. Environment system environment variable
6. Default to 'development'

## Common Use Cases

### Pre-Deployment Check
```bash
# Check production configuration before deployment
wheels config check production --verbose
```

### Development Setup Validation
```bash
# Ensure development environment is properly configured
wheels config check development --fix
```

### CI/CD Pipeline Integration
```bash
# In your CI/CD script
wheels config check production
if [ $? -ne 0 ]; then
    echo "Configuration validation failed!"
    exit 1
fi
```

### Security Audit
```bash
# Check for security issues across all environments
wheels config check development --verbose
wheels config check testing --verbose
wheels config check production --verbose
```

## Exit Codes

The command returns different exit codes for scripting:

- **0** - All checks passed (may have warnings)
- **1** - One or more errors found

## Best Practices

1. **Run Before Deployment** - Always validate production configuration before deploying

2. **Use in CI/CD** - Include configuration checks in your automated pipelines

3. **Regular Audits** - Periodically check all environments for security issues

4. **Fix Warnings** - While warnings don't fail the check, addressing them improves security and performance

5. **Version Control** - After using `--fix`, review and commit the changes

6. **Environment-Specific Configs** - Create separate configuration directories for each environment

## Troubleshooting

### Command Not Found
```
Error: This command must be run from a Wheels application directory
```
**Solution**: Run the command from your Wheels application root directory

### Cannot Read Configuration
```
Error reading configuration: [error message]
```
**Solution**: Check file permissions and ensure configuration files are valid CFML

### Datasource Not Found
```
Datasource 'myapp_db' not found
```
**Solution**: Configure the datasource in your CFML administrator or Application.cfc

### Permission Issues with .env
```
.env file has overly permissive permissions
```
**Solution**: Run `chmod 600 .env` to restrict file permissions

## Configuration File Examples

### Basic config/settings.cfm
```cfm
<cfscript>
// Application settings
set(dataSourceName = application.env["DB_NAME"]);
set(reloadPassword = application.env["RELOAD_PASSWORD"]);

// Security settings
set(showDebugInformation = false);
set(showErrorInformation = false);

// Performance settings
set(cacheQueries = true);
set(cachePartials = true);
</cfscript>
```

### Environment-specific config/production/settings.cfm
```cfm
<cfscript>
// Production overrides
set(showDebugInformation = false);
set(sendEmailOnError = true);
set(errorEmailAddress = "admin@example.com");
set(forceSSL = true);

// Enable all caching
set(cacheControllerConfig = true);
set(cacheDatabaseSchema = true);
set(cacheFileChecking = true);
set(cacheImages = true);
set(cacheModelConfig = true);
set(cachePartials = true);
set(cacheQueries = true);
set(cacheRoutes = true);
</cfscript>
```

### Sample .env file
```bash
# Wheels Environment Configuration
WHEELS_ENV=development

# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=myapp_development
DB_USER=dbuser
DB_PASSWORD=secure_password

# Application Settings
RELOAD_PASSWORD=change_this_password
SECRET_KEY=your_secret_key_here
API_KEY=your_api_key
```

## Related Commands

- `wheels get environment` - Display current environment setting
- `wheels env merge` - Merge environment configurations
- `wheels db create` - Create database for current environment
- `wheels test` - Run tests in current environment

## Security Considerations

1. **Never commit .env files** - Always keep .env in .gitignore
2. **Use environment variables** - Don't hardcode sensitive values
3. **Restrict file permissions** - Set appropriate permissions on configuration files
4. **Different passwords per environment** - Use unique credentials for each environment
5. **Enable SSL in production** - Always force SSL for production environments
6. **Hide error details** - Never show debug information in production

## Tips

- Run with `--verbose` first to understand all issues before using `--fix`
- Create environment-specific directories even if empty for better organization
- Use the command as part of your deployment checklist
- Keep configuration files well-commented for team members
- Regularly update and review security settings
- Use strong, unique reload passwords for each environment
- Document any custom configuration requirements for your team