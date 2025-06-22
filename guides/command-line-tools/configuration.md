# Configuration Management Guide

This guide covers configuration management in Wheels, including working with environment variables, settings files, and the CLI tools for managing configuration.

## Overview

Wheels provides flexible configuration management through:
- Environment-specific settings files
- Environment variables (.env files)
- CLI commands for configuration management
- Security best practices

## Environment Variables

### .env File Format

Wheels supports two formats for .env files:

#### Properties Format (Recommended)
```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=myapp_development
DB_USER=wheels
DB_PASSWORD=secretpassword

# Application Settings
WHEELS_ENV=development
RELOAD_PASSWORD=myreloadpassword
SECRET_KEY=a1b2c3d4e5f6g7h8i9j0

# Feature Flags
DEBUG_MODE=true
CACHE_ENABLED=false
```

#### JSON Format
```json
{
  "DB_HOST": "localhost",
  "DB_PORT": 3306,
  "DB_NAME": "myapp_development",
  "DB_USER": "wheels",
  "DB_PASSWORD": "secretpassword",
  "WHEELS_ENV": "development",
  "DEBUG_MODE": true
}
```

### Environment-Specific Files

Wheels automatically loads environment-specific .env files:

1. `.env` - Base configuration (always loaded first)
2. `.env.{environment}` - Environment-specific overrides (loaded second)

Example structure:
```
myapp/
├── .env                 # Base configuration
├── .env.development     # Development overrides
├── .env.testing        # Testing overrides
├── .env.production     # Production settings
└── .gitignore          # MUST exclude .env files!
```

### Variable Interpolation

Use `${VAR}` syntax to reference other variables:

```bash
# .env
APP_NAME=MyWheelsApp
APP_ENV=development

# Database URLs with interpolation
DB_HOST=localhost
DB_PORT=3306
DB_NAME=${APP_NAME}_${APP_ENV}
DB_URL=mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}

# API endpoints
API_BASE_URL=https://api.example.com
API_USERS_URL=${API_BASE_URL}/users
API_ORDERS_URL=${API_BASE_URL}/orders
```

### Type Casting

Wheels automatically casts certain values:

```bash
# Booleans (cast to true/false)
DEBUG_MODE=true
CACHE_ENABLED=false

# Numbers (cast to numeric values)
MAX_CONNECTIONS=100
CACHE_TTL=3600
REQUEST_TIMEOUT=30

# Strings (remain as strings)
APP_NAME=MyApp
API_KEY=abc123def456
```

### Using Environment Variables in Settings

Access environment variables in your settings files:

```cfscript
// config/settings.cfm
// Using application.env struct
set(dataSourceName = application.env['DB_NAME']);
set(dataSourceUserName = application.env['DB_USER']);
set(dataSourcePassword = application.env['DB_PASSWORD']);

// With defaults
set(cacheQueries = application.env['CACHE_ENABLED'] ?: false);
set(reloadPassword = application.env['RELOAD_PASSWORD'] ?: 'defaultpassword');

// Environment-specific logic
if (application.env['WHEELS_ENV'] == 'production') {
    set(showDebugInformation = false);
    set(cacheFileChecking = true);
}
```

## Configuration Files

### Directory Structure

```
config/
├── settings.cfm           # Base configuration
├── development/
│   └── settings.cfm      # Development overrides
├── testing/
│   └── settings.cfm      # Testing overrides
├── production/
│   └── settings.cfm      # Production overrides
└── maintenance/
    └── settings.cfm      # Maintenance mode settings
```

### Settings Precedence

Settings are loaded in this order (later overrides earlier):
1. Framework defaults
2. `config/settings.cfm`
3. `config/{environment}/settings.cfm`
4. Plugin settings
5. Runtime `set()` calls

### Common Configuration Patterns

#### Database Configuration
```cfscript
// config/settings.cfm
set(dataSourceName = application.env['DB_NAME'] ?: 'wheelstutorial');
set(dataSourceUserName = application.env['DB_USER'] ?: 'root');
set(dataSourcePassword = application.env['DB_PASSWORD'] ?: '');
```

#### Environment-Specific Settings
```cfscript
// config/production/settings.cfm
// Production optimizations
set(cacheQueries = true);
set(cachePartials = true);
set(cachePages = true);
set(cacheActions = true);
set(cacheImages = true);
set(cacheModelConfig = true);
set(cacheControllerConfig = true);
set(cacheRoutes = true);
set(cacheDatabaseSchema = true);
set(cacheFileChecking = false);

// Security
set(showDebugInformation = false);
set(showErrorInformation = false);

// Error handling
set(sendEmailOnError = true);
set(errorEmailAddress = application.env['ERROR_EMAIL']);
```

## CLI Configuration Commands

### Dumping Configuration

Export current configuration:

```bash
# View current config (masked)
wheels config dump

# Export production config as JSON
wheels config dump production --format=json --output=prod-config.json

# Export as .env format
wheels config dump --format=env --output=config.env

# Export without masking (careful!)
wheels config dump --no-mask
```

### Checking Configuration

Validate configuration for issues:

```bash
# Basic check
wheels config check

# Check production with fixes
wheels config check production --fix

# Verbose output with suggestions
wheels config check --verbose
```

Common checks performed:
- Missing required settings
- Hardcoded sensitive values
- Production security settings
- Database configuration
- Caching optimizations

### Comparing Environments

Find differences between environments:

```bash
# Full comparison
wheels config diff development production

# Show only differences
wheels config diff development production --changes-only

# Export as JSON
wheels config diff testing production --format=json > diff.json
```

### Managing Secrets

Generate secure secrets:

```bash
# Generate and display
wheels secret
wheels secret --type=base64 --length=48

# Save to .env
wheels secret --save-to-env=SECRET_KEY
wheels secret --type=uuid --save-to-env=API_KEY

# Multiple secrets
wheels secret --save-to-env=SESSION_SECRET
wheels secret --save-to-env=CSRF_TOKEN
wheels secret --save-to-env=ENCRYPTION_KEY
```

### Environment Variable Management

#### Setting Variables
```bash
# Set single variable
wheels env set DB_HOST=localhost

# Set multiple
wheels env set DB_HOST=localhost DB_PORT=3306 DB_NAME=myapp

# Update production file
wheels env set --file=.env.production API_URL=https://api.example.com
```

#### Validating Files
```bash
# Basic validation
wheels env validate

# Check required variables
wheels env validate --required=DB_HOST,DB_USER,DB_PASSWORD

# Validate production
wheels env validate --file=.env.production --verbose
```

#### Merging Files
```bash
# Merge for deployment
wheels env merge .env .env.production --output=.env.deployed

# Preview merge
wheels env merge .env.defaults .env.local --dry-run
```

## Security Best Practices

### 1. Never Commit Secrets

Always add .env files to .gitignore:

```gitignore
# Environment files
.env
.env.*
!.env.example
!.env.defaults
```

### 2. Use Strong Secrets

Generate cryptographically secure values:

```bash
# For session secrets
wheels secret --type=hex --length=64 --save-to-env=SESSION_SECRET

# For API keys
wheels secret --type=base64 --length=48 --save-to-env=API_SECRET

# For passwords
wheels secret --type=alphanumeric --length=32
```

### 3. Validate Production Config

Run checks before deployment:

```bash
# Full production check
wheels config check production --verbose

# Required checks
wheels env validate --file=.env.production \
  --required=DB_HOST,DB_USER,DB_PASSWORD,SECRET_KEY,RELOAD_PASSWORD
```

### 4. Mask Sensitive Output

Always use masking in logs/output:

```cfscript
// In your code
writeOutput("Database: #application.env['DB_NAME']#");
writeOutput("Password: ***MASKED***"); // Never output passwords
```

### 5. Environment-Specific Secrets

Use different secrets per environment:

```bash
# .env.development
SECRET_KEY=dev_secret_key_only_for_local

# .env.production
SECRET_KEY=prod_0a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
```

## Common Patterns

### Multi-Environment Setup

```bash
# 1. Create base config
wheels env set WHEELS_ENV=development DB_NAME=myapp_dev

# 2. Create production config
wheels env set --file=.env.production \
  WHEELS_ENV=production \
  DB_NAME=myapp_prod \
  DB_HOST=prod.database.com

# 3. Create testing config
wheels env set --file=.env.testing \
  WHEELS_ENV=testing \
  DB_NAME=myapp_test

# 4. Validate all
wheels env validate
wheels env validate --file=.env.production
wheels env validate --file=.env.testing
```

### Deployment Configuration

```bash
# 1. Merge configs for deployment
wheels env merge .env.defaults .env.production --output=.env.deploy

# 2. Validate merged config
wheels env validate --file=.env.deploy \
  --required=DB_HOST,DB_USER,DB_PASSWORD,SECRET_KEY

# 3. Check security
wheels config check production --verbose
```

### Local Development

```bash
# 1. Copy example file
cp .env.example .env

# 2. Set local values
wheels env set DB_HOST=localhost DB_USER=root DB_PASSWORD=

# 3. Generate secrets
wheels secret --save-to-env=SECRET_KEY
wheels secret --save-to-env=RELOAD_PASSWORD

# 4. Validate
wheels env validate
```

## Troubleshooting

### Environment Variables Not Loading

1. Check file exists and is readable
2. Verify format (properties vs JSON)
3. Check for syntax errors:
   ```bash
   wheels env validate
   ```

### Wrong Environment Loading

1. Check WHEELS_ENV variable:
   ```bash
   wheels env show --key=WHEELS_ENV
   ```
2. Verify environment detection order:
   - `.env` file WHEELS_ENV
   - System environment WHEELS_ENV
   - Default to 'development'

### Interpolation Not Working

1. Ensure variables are defined before use
2. Check syntax: `${VAR_NAME}`
3. Maximum 10 interpolation passes (prevent loops)

### Sensitive Values Exposed

1. Run security check:
   ```bash
   wheels config check --verbose
   ```
2. Move hardcoded values to .env
3. Use `application.env` references

## Best Practices Summary

1. **Use .env files** for all environment-specific values
2. **Never commit secrets** - use .gitignore
3. **Generate strong secrets** with `wheels secret`
4. **Validate configuration** before deployment
5. **Use interpolation** to reduce duplication
6. **Environment-specific files** for overrides
7. **Check security** regularly with CLI tools
8. **Document required variables** in .env.example
9. **Mask sensitive values** in output
10. **Test configuration changes** in development first